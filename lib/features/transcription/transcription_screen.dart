import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';
import '../common/attention_band.dart';
import '../common/colour_swatches.dart';
import '../common/farm_today.dart';
import '../common/form_menu.dart';
import '../common/leftover_picker.dart';
import '../common/picker_screen.dart';
import '../common/pinned_action.dart';
import '../common/pond_choice.dart';
import '../common/save_once.dart';
import '../common/sign_grid.dart';
import '../people/people_providers.dart';
import '../people/person_picker.dart';
import '../ponds/pond_overview.dart';
import 'transcription_sheet.dart';
import 'week.dart';

/// Logs of a week's days, current ones only.
final _weekLogsProvider = StreamProvider.autoDispose
    .family<List<DailyLog>, DateTime>(
      (ref, monday) => ref
          .watch(dailyLogRepositoryProvider)
          .watchRange(monday, monday.add(const Duration(days: 6))),
    );

/// The day column: "sam. 14/03" in large Malagasy text still fits.
const _dayWidth = 96.0;

/// A day's leftovers, signs and water colour, as the + page picks them.
typedef _Details = ({
  Set<WarningSign> signs,
  Leftover? leftover,
  bool ateFast,
  WaterColour? colour,
});

/// One day of one sheet as typed: the fields' controllers and the details.
class _Cell {
  final kg = TextEditingController();
  final deaths = TextEditingController();
  final entry = DayEntry();

  DayEntry get typed => entry
    ..kg = kg.text
    ..deaths = deaths.text;

  void dispose() {
    kg.dispose();
    deaths.dispose();
  }
}

/// A worker's paper sheet, one pond's week, copied line by line (SPEC F4,
/// docs/design.md §Step 7b). Days already logged show as read-only lines
/// that open their log.
class TranscriptionScreen extends ConsumerStatefulWidget {
  const TranscriptionScreen({super.key, this.week});

  /// Any day of the week to open; this week when null.
  final DateTime? week;

  @override
  ConsumerState<TranscriptionScreen> createState() =>
      _TranscriptionScreenState();
}

class _TranscriptionScreenState extends ConsumerState<TranscriptionScreen>
    with SaveOnce {
  late List<DateTime> _days = weekOf(
    widget.week ?? ref.read(farmTodayProvider),
  );
  String? _personId;
  var _personMissing = false;
  String? _pondId;
  var _missing = <DateTime>[];
  var _leaving = false;

  /// Typing per (pond, day), kept across switching pond or week.
  final _cells = <(String, DateTime), _Cell>{};

  /// Sheets saved in this session, as (pond, Monday).
  final _saved = <(String, DateTime)>{};

  @override
  void dispose() {
    for (final c in _cells.values) {
      c.dispose();
    }
    super.dispose();
  }

  _Cell _cell(String pondId, DateTime day) =>
      _cells.putIfAbsent((pondId, day), _Cell.new);

  bool _typed(String pondId, List<DateTime> days) =>
      days.any((d) => _cells[(pondId, d)]?.typed.isEmpty == false);

  /// Ponds with typing not saved, over every week typed in.
  List<String> _unsavedPonds(Map<String, Pond> ponds) => {
    for (final MapEntry(key: (pondId, _), value: cell) in _cells.entries)
      if (!cell.typed.isEmpty) pondId,
  }.map((id) => ponds[id]?.code ?? '?').toList()..sort();

  void _moveWeek(int by) => setState(() {
    _days = weekOf(_days.first.add(Duration(days: 7 * by)));
    _missing = [];
  });

  Future<void> _pickPerson() async {
    final id = await pickPerson(context, current: _personId);
    if (id != null && mounted) {
      setState(() {
        _personId = id;
        _personMissing = false;
      });
    }
  }

  Future<void> _pickDetails(_Cell cell) async {
    final l10n = AppLocalizations.of(context);
    final e = cell.entry;
    final picked = await Navigator.of(context).push<_Details>(
      MaterialPageRoute(
        builder: (context) => PickerScreen<_Details>(
          title: l10n.transcriptionCellDetails,
          doneLabel: l10n.pickDone,
          initial: (
            signs: e.signs,
            leftover: e.leftover,
            ateFast: e.ateFast,
            colour: e.colour,
          ),
          builder: (context, v, onChanged) {
            final text = Theme.of(context).textTheme;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.leftovers, style: text.titleMedium),
                const SizedBox(height: 8),
                LeftoverPicker(
                  value: v.leftover,
                  ateFast: v.ateFast,
                  onChanged: (leftover, ateFast) => onChanged((
                    signs: v.signs,
                    leftover: leftover,
                    ateFast: ateFast,
                    colour: v.colour,
                  )),
                ),
                const SizedBox(height: 24),
                Text(l10n.signsSeen, style: text.titleMedium),
                const SizedBox(height: 8),
                SignGrid(
                  options: WarningSign.values.toSet(),
                  selected: v.signs,
                  onChanged: (s) => onChanged((
                    signs: s,
                    leftover: v.leftover,
                    ateFast: v.ateFast,
                    colour: v.colour,
                  )),
                ),
                const SizedBox(height: 24),
                Text(l10n.waterColourLabel, style: text.titleMedium),
                const SizedBox(height: 8),
                ColourSwatches(
                  value: v.colour,
                  onChanged: (c) => onChanged((
                    signs: v.signs,
                    leftover: v.leftover,
                    ateFast: v.ateFast,
                    colour: c,
                  )),
                ),
              ],
            );
          },
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      e.signs = picked.signs;
      e.leftover = picked.leftover;
      e.ateFast = picked.ateFast;
      e.colour = picked.colour;
      _missing = [];
    });
  }

  Future<void> _save(List<Pond> ponds, Set<DateTime> logged) async {
    final l10n = AppLocalizations.of(context);
    final pondId = _pondId;
    if (pondId == null) return;
    final open = [
      for (final d in _days)
        if (!logged.contains(d)) d,
    ];
    final r = sheetInputs(
      pondId: pondId,
      personId: _personId ?? '',
      typed: {for (final d in open) d: _cell(pondId, d).typed},
    );
    setState(() {
      _personMissing = _personId == null;
      _missing = r.missingFeed;
    });
    if (_personId == null || r.missingFeed.isNotEmpty || r.inputs.isEmpty) {
      return;
    }
    await ref.read(dailyLogRepositoryProvider).saveWeek(r.inputs);
    if (!mounted) return;
    final code = ponds.firstWhere((p) => p.id == pondId).code;
    setState(() {
      for (final d in _days) {
        _cells.remove((pondId, d))?.dispose();
      }
      _saved.add((pondId, _days.first));
      // The next pond whose sheet is neither done nor started.
      _pondId = ponds
          .where(
            (p) =>
                p.id != pondId &&
                !_saved.contains((p.id, _days.first)) &&
                !_typed(p.id, _days),
          )
          .map((p) => p.id)
          .firstOrNull;
    });
    showDone(context, l10n.transcriptionSavedPond(code));
  }

  Future<void> _askLeave(List<String> unsaved) async {
    final l10n = AppLocalizations.of(context);
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.transcriptionLeave(unsaved.join(', '))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.transcriptionStay),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.transcriptionQuit),
          ),
        ],
      ),
    );
    if (quit != true || !mounted) return;
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final pondList = ref.watch(pondsProvider).value;
    final people = ref.watch(peopleProvider).value;
    final roles = ref.watch(personRolesProvider);
    final logs = ref.watch(_weekLogsProvider(_days.first)).value;
    if (pondList == null || people == null || logs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ponds = [...pondList]..sort((a, b) => a.code.compareTo(b.code));
    final byId = {for (final p in ponds) p.id: p};
    _pondId ??= ponds.firstOrNull?.id;
    final logged = {
      for (final l in logs) (l.pondId, farmDate(l.recordedAt)): l,
    };
    final person = people.where((p) => p.id == _personId).firstOrNull;
    // The paper sheet's weekday names: the date library has no Malagasy.
    final dayMonth = DateFormat('dd/MM');
    String dayName(DateTime d) =>
        '${l10n.weekday(d.weekday)} ${dayMonth.format(d)}';
    String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    final pond = byId[_pondId];
    final unsaved = _unsavedPonds(byId);
    bool done(String id) =>
        _saved.contains((id, _days.first)) ||
        _days.every((d) => logged.containsKey((id, d)));

    Widget dayRow(Pond pond, DateTime day) {
      final log = logged[(pond.id, day)];
      final label = Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SizedBox(
          width: _dayWidth - 8,
          child: Text(dayName(day), style: text.bodyMedium),
        ),
      );
      if (log != null) {
        return InkWell(
          key: ValueKey('logged-${iso(day)}'),
          onTap: () => context.push('/log/${pond.id}?date=${iso(day)}&lot=1'),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                label,
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        [
                          formatKg(log.feedGivenG, locale),
                          if (log.deaths > 0) '† ${log.deaths}',
                        ].join(', '),
                      ),
                      Text(l10n.transcriptionLogged, style: text.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.ink),
              ],
            ),
          ),
        );
      }
      final cell = _cell(pond.id, day);
      final e = cell.entry;
      final noFeed = _missing.contains(day);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            label,
            Expanded(
              flex: 3,
              child: TextField(
                key: ValueKey('kg-${iso(day)}'),
                controller: cell.kg,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'kg',
                  suffixText: 'kg',
                  errorText: noFeed ? '' : null,
                ),
                onChanged: (_) => setState(() => _missing = []),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                key: ValueKey('deaths-${iso(day)}'),
                controller: cell.deaths,
                keyboardType: TextInputType.number,
                // Empty means none died.
                decoration: const InputDecoration(
                  hintText: '0',
                  suffixText: '†',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            InkWell(
              key: ValueKey('details-${iso(day)}'),
              onTap: () => _pickDetails(cell),
              child: SizedBox(
                width: 56,
                height: 56,
                child: e.hasDetails
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (e.leftover != null || e.ateFast)
                            const Icon(
                              Icons.rice_bowl_outlined,
                              key: ValueKey('picked-leftover'),
                              size: 18,
                            ),
                          if (e.signs.isNotEmpty)
                            Icon(
                              Icons.warning_amber,
                              key: const ValueKey('picked-signs'),
                              size: 18,
                              color: c.warning,
                            ),
                          if (e.colour != null)
                            const Icon(
                              Icons.water_drop_outlined,
                              key: ValueKey('picked-colour'),
                              size: 18,
                            ),
                        ],
                      )
                    : Icon(Icons.add, color: c.ink),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: _leaving || unsaved.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askLeave(unsaved);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.transcription)),
        bottomNavigationBar: pond == null
            ? null
            : PinnedAction(
                icon: Icons.check,
                label: l10n.transcriptionSave(pond.code),
                onPressed: saving
                    ? null
                    : () => saveOnce(
                        () => _save(ponds, {
                          for (final d in _days)
                            if (logged.containsKey((pond.id, d))) d,
                        }),
                      ),
              ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              key: const ValueKey('sheet-of'),
              onTap: _pickPerson,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.sheetOf,
                  errorText: _personMissing ? l10n.fieldRequired : null,
                  suffixIcon: const Icon(Icons.chevron_right),
                ),
                child: Text(
                  person == null
                      ? ''
                      : personLabel(l10n, person, roles[person.id]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.previousWeek,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _moveWeek(-1),
                ),
                Expanded(
                  child: Text(
                    l10n.weekOfLabel(formatDate(_days.first)),
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.nextWeek,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _moveWeek(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PondChoice(
              options: [
                for (final p in ponds)
                  PondOption(
                    pond: p,
                    caption: done(p.id)
                        ? '✓'
                        : _typed(p.id, _days)
                        ? '•'
                        : null,
                  ),
              ],
              value: _pondId,
              onChanged: (v) => setState(() {
                if (v != null) _pondId = v;
                _missing = [];
              }),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: c.line),
            // The paper sheet's own column heads.
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: _dayWidth,
                    child: Text(l10n.paperDay, style: text.bodySmall),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(l10n.paperFeedKg, style: text.bodySmall),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.deaths, style: text.bodySmall),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
            if (pond != null)
              for (final day in _days) dayRow(pond, day),
            if (_missing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AttentionBand(
                  severity: BandSeverity.danger,
                  text: l10n.transcriptionFeedMissing(
                    _missing.map(dayName).join(', '),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
