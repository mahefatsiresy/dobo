import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../db/database.dart';
import '../../db/repositories/daily_log_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../common/colour_swatches.dart';
import '../common/leftover_picker.dart';
import '../common/notice.dart';
import '../common/pond_colour.dart';
import '../common/save_once.dart';
import '../common/sign_grid.dart';
import '../people/people_providers.dart';
import '../ponds/pond_overview.dart';
import 'week.dart';

/// Logs of a week's days, current ones only.
final _weekLogsProvider = StreamProvider.autoDispose
    .family<List<DailyLog>, DateTime>(
      (ref, monday) => ref
          .watch(dailyLogRepositoryProvider)
          .watchRange(monday, monday.add(const Duration(days: 6))),
    );

/// One week of a worker's paper sheet (SPEC F4): rows are days, columns are
/// ponds, each cell feed in kg and deaths. Days already logged show greyed
/// and open their log when tapped.
class TranscriptionScreen extends ConsumerStatefulWidget {
  const TranscriptionScreen({super.key, this.week});

  /// Any day of the week to open; this week when null.
  final DateTime? week;

  @override
  ConsumerState<TranscriptionScreen> createState() =>
      _TranscriptionScreenState();
}

class _Cell {
  final kg = TextEditingController();
  final deaths = TextEditingController();
  var signs = <WarningSign>{};
  Leftover? leftover;
  var ateFast = false;
  WaterColour? waterColour;

  /// Anything picked in the cell's sheet (signs, leftover, colour).
  bool get hasDetails =>
      signs.isNotEmpty || leftover != null || ateFast || waterColour != null;

  bool get isEmpty =>
      kg.text.trim().isEmpty && deaths.text.trim().isEmpty && !hasDetails;

  void clear() {
    kg.clear();
    deaths.clear();
    signs = {};
    leftover = null;
    ateFast = false;
    waterColour = null;
  }

  void dispose() {
    kg.dispose();
    deaths.dispose();
  }
}

class _TranscriptionScreenState extends ConsumerState<TranscriptionScreen>
    with SaveOnce {
  final _scroll = ScrollController();
  late List<DateTime> _days;
  String? _personId;
  var _personMissing = false;
  var _feedMissing = false;
  final _cells = <(String, DateTime), _Cell>{};

  @override
  void initState() {
    super.initState();
    _days = weekOf(widget.week ?? farmToday());
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in _cells.values) {
      c.dispose();
    }
    super.dispose();
  }

  _Cell _cell(String pondId, DateTime day) =>
      _cells.putIfAbsent((pondId, day), _Cell.new);

  void _moveWeek(int by) => setState(() {
    _days = weekOf(_days.first.add(Duration(days: 7 * by)));
    _feedMissing = false;
  });

  Future<void> _save() async {
    final filled = [
      for (final MapEntry(key: (pondId, day), value: cell) in _cells.entries)
        // Every week's cells: input typed before changing week is kept.
        if (!cell.isEmpty) (pondId, day, cell),
    ];
    final missingFeed = filled.any((f) => parseDecimal(f.$3.kg.text) == null);
    setState(() {
      _personMissing = _personId == null;
      _feedMissing = missingFeed;
    });
    if (_personId == null || missingFeed) {
      // The worker picker and the notice are at the top; Save is below.
      await _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    if (filled.isEmpty) return;
    await ref.read(dailyLogRepositoryProvider).saveWeek([
      for (final (pondId, day, cell) in filled)
        DailyLogInput(
          pondId: pondId,
          date: day,
          feedGivenG: (parseDecimal(cell.kg.text)! * 1000).round(),
          deaths: parseDecimal(cell.deaths.text)?.round() ?? 0,
          warningSigns: cell.signs,
          leftover: cell.leftover,
          ateFast: cell.ateFast,
          waterColour: cell.waterColour,
          observedBy: _personId,
        ),
    ]);
    for (final (_, _, cell) in filled) {
      cell.clear();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saved)),
      );
    }
  }

  /// Everything else the paper sheet has for the day: leftover, signs and
  /// water colour (plan M8 Decision 4).
  Future<void> _pickDetails(_Cell cell) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          final l10n = AppLocalizations.of(context);
          void update(void Function() change) {
            setSheet(change);
            setState(() {});
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.transcriptionCellDetails,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.leftovers),
                  const SizedBox(height: 8),
                  LeftoverPicker(
                    value: cell.leftover,
                    ateFast: cell.ateFast,
                    onChanged: (leftover, ateFast) => update(() {
                      cell.leftover = leftover;
                      cell.ateFast = ateFast;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.signsSeen),
                  const SizedBox(height: 8),
                  SignGrid(
                    options: WarningSign.values.toSet(),
                    selected: cell.signs,
                    onChanged: (s) => update(() => cell.signs = s),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.waterColourLabel),
                  const SizedBox(height: 8),
                  ColourSwatches(
                    value: cell.waterColour,
                    onChanged: (c) => update(() => cell.waterColour = c),
                  ),
                  const SizedBox(height: 24),
                  // The sheet can fill a small phone, leaving nothing
                  // outside it to tap.
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final ponds = ref.watch(pondsProvider).value;
    final people = ref.watch(peopleProvider).value;
    final roles = ref.watch(personRolesProvider);
    final logs = ref.watch(_weekLogsProvider(_days.first)).value;
    if (ponds == null || people == null || logs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final logged = {
      for (final l in logs) (l.pondId, farmDate(l.recordedAt)): l,
    };
    final dayLabel = DateFormat('EEE dd/MM', intlLocaleFor(locale));
    String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    const cellWidth = 150.0;

    Widget cellFor(Pond pond, DateTime day) {
      final log = logged[(pond.id, day)];
      if (log != null) {
        return InkWell(
          onTap: () => context.push('/log/${pond.id}?date=${iso(day)}&lot=1'),
          child: Container(
            width: cellWidth,
            height: 56,
            alignment: Alignment.center,
            color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
            child: Text(
              [
                formatKg(log.feedGivenG, locale),
                if (log.deaths > 0) '† ${log.deaths}',
              ].join(' · '),
            ),
          ),
        );
      }
      final cell = _cell(pond.id, day);
      final noFeed =
          _feedMissing && !cell.isEmpty && parseDecimal(cell.kg.text) == null;
      return SizedBox(
        width: cellWidth,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: ValueKey('kg-${pond.id}-${iso(day)}'),
                controller: cell.kg,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'kg',
                  isDense: true,
                  errorText: noFeed ? '' : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 44,
              child: TextField(
                key: ValueKey('deaths-${pond.id}-${iso(day)}'),
                controller: cell.deaths,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '†', isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            IconButton(
              key: ValueKey('signs-${pond.id}-${iso(day)}'),
              tooltip: l10n.transcriptionCellDetails,
              icon: Icon(
                cell.hasDetails
                    ? Icons.notification_important
                    : Icons.add_alert_outlined,
              ),
              onPressed: () => _pickDetails(cell),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.transcription)),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        children: [
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
                  style: Theme.of(context).textTheme.titleMedium,
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
          DropdownButtonFormField<String>(
            key: const ValueKey('sheetOf'),
            initialValue: _personId,
            decoration: InputDecoration(
              labelText: l10n.sheetOf,
              errorText: _personMissing ? l10n.fieldRequired : null,
            ),
            items: [
              for (final p in people)
                if (p.active)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(personLabel(l10n, p, roles[p.id])),
                  ),
            ],
            onChanged: (v) => setState(() {
              _personId = v;
              _personMissing = false;
            }),
          ),
          if (_feedMissing) Notice(l10n.feedMissing, danger: true),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 88),
                    for (final pond in ponds)
                      SizedBox(
                        width: cellWidth + 8,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PondTag(code: pond.code, colour: pond.colour),
                        ),
                      ),
                  ],
                ),
                for (final day in _days)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 88, child: Text(dayLabel.format(day))),
                        for (final pond in ponds)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: cellFor(pond, day),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: saving ? null : () => saveOnce(_save),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
