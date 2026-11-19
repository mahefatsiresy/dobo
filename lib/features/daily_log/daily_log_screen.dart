import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/feed_lots.dart';
import '../feed/feed_providers.dart';
import '../alerts/alert_providers.dart';
import 'stop_feeding_sign.dart';

import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/daily_log_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../l10n/formatting.dart';
import '../common/big_number_field.dart';
import '../common/colour_swatches.dart';
import '../common/leftover_picker.dart';
import '../common/option_button.dart';
import '../common/picker_screen.dart';
import '../common/pictograms.dart';
import '../common/notice.dart';
import '../common/pond_colour.dart';
import '../common/save_once.dart';
import '../common/sign_grid.dart';
import '../ponds/pond_overview.dart';
import 'daily_log_providers.dart';
import '../../theme/tokens.dart';

/// One pond-day (SPEC F3): the worker's screen, also used by members.
/// Opening a day already logged edits it.
class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({
    super.key,
    required this.pondId,
    required this.date,
    this.showLot = false,
  });

  final String pondId;

  /// Date only.
  final DateTime date;

  /// A member may pick the feed lot; the worker never sees it (plan M7
  /// Decision 5).
  final bool showLot;

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _feed = TextEditingController();
  final _deaths = TextEditingController(text: '0');
  final _note = TextEditingController();
  int? _feedings;
  Leftover? _leftover;
  var _ateFast = false;
  var _deathSigns = <WarningSign>{};
  var _signs = <WarningSign>{};
  WaterColour? _colour;
  var _showNote = false;

  /// Whose paper sheet the day came from: kept when it is corrected.
  String? _observedBy;

  /// The feed lot; null lets the repository take the oldest usable one.
  String? _lotId;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    // The last save's confirmation belongs to the tiles; here it would
    // cover Save.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar(),
    );
  }

  @override
  void dispose() {
    _feed.dispose();
    _deaths.dispose();
    _note.dispose();
    super.dispose();
  }

  void _load(DailyLog? log) {
    _loaded = true;
    if (log == null) return;
    _observedBy = log.observedBy;
    _lotId = log.feedLotId;
    _feed.text = formatForInput(log.feedGivenG / 1000);
    _deaths.text = '${log.deaths}';
    _note.text = log.note ?? '';
    _showNote = log.note != null;
    _feedings = log.feedings;
    _leftover = log.leftover;
    _ateFast = log.ateFast;
    _deathSigns = {...log.deathSigns};
    _signs = {...log.warningSigns};
    _colour = log.waterColour;
  }

  double? get _feedKg {
    final v = parseDecimal(_feed.text);
    return v != null && v >= 0 ? v : null;
  }

  int get _deathCount {
    final v = parseDecimal(_deaths.text);
    return v != null && v >= 0 ? v.round() : 0;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final saved = context.dobo.ok;
    final deaths = _deathCount;
    final note = _note.text.trim();
    await ref
        .read(dailyLogRepositoryProvider)
        .save(
          DailyLogInput(
            pondId: widget.pondId,
            date: widget.date,
            feedGivenG: (_feedKg! * 1000).round(),
            feedings: _feedings,
            leftover: _leftover,
            ateFast: _leftover == Leftover.none && _ateFast,
            deaths: deaths,
            deathSigns: deaths > 0 ? _deathSigns : const {},
            warningSigns: _signs,
            waterColour: _colour,
            note: note.isEmpty ? null : note,
            observedBy: _observedBy,
            feedLotId: _lotId,
          ),
        );
    ref.invalidate(dailyLogForDayProvider((widget.pondId, widget.date)));
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: saved,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(l10n.saved),
          ],
        ),
      ),
    );
    if (mounted) context.pop();
  }

  /// Opens a pictogram screen; back keeps what was picked before.
  Future<T?> _picker<T>(
    String title,
    T initial,
    Widget Function(BuildContext, T, ValueChanged<T>) builder,
  ) => Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (context) => PickerScreen<T>(
        title: title,
        doneLabel: AppLocalizations.of(context).pickDone,
        initial: initial,
        builder: builder,
      ),
    ),
  );

  Future<void> _pickSigns(
    String title,
    Set<WarningSign> options,
    bool death,
  ) async {
    final picked = await _picker<Set<WarningSign>>(
      title,
      death ? _deathSigns : _signs,
      (context, value, onChanged) =>
          SignGrid(options: options, selected: value, onChanged: onChanged),
    );
    if (picked == null) return;
    setState(() => death ? _deathSigns = picked : _signs = picked);
  }

  Future<void> _pickColour(String title) async {
    // A record, so "cleared" (null inside) differs from back (null).
    final picked = await _picker<(WaterColour?,)>(
      title,
      (_colour,),
      (context, value, onChanged) =>
          ColourSwatches(value: value.$1, onChanged: (c) => onChanged((c,))),
    );
    if (picked != null) setState(() => _colour = picked.$1);
  }

  Future<void> _pickFeedings(String title) async {
    final picked = await _picker<(int?,)>(
      title,
      (_feedings,),
      (context, value, onChanged) =>
          _FeedingsGrid(value: value.$1, onChanged: (n) => onChanged((n,))),
    );
    if (picked != null) setState(() => _feedings = picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overview = ref
        .watch(pondOverviewsProvider)
        .value
        ?.where((o) => o.pond.id == widget.pondId)
        .firstOrNull;
    final existing = ref.watch(
      dailyLogForDayProvider((widget.pondId, widget.date)),
    );
    if (overview == null || !existing.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_loaded) _load(existing.value);
    final pond = overview.pond;
    final isWorker = ref.watch(sessionProvider).value?.isWorker ?? false;
    final stop = ref.watch(stopFeedingProvider(widget.pondId));
    const gap = SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            PondTag(code: pond.code, colour: pond.colour),
            const SizedBox(width: 12),
            Text(formatDate(widget.date)),
          ],
        ),
        toolbarHeight: 72,
      ),
      // A normal day fits one screen: feed, leftovers, deaths, save
      // (docs/design.md §Step 3). The rest opens on its own screen.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            key: const ValueKey('saveLog'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: saving ? null : () => saveOnce(_save),
            icon: const Icon(Icons.check),
            label: Text(l10n.save),
          ),
        ),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          key: const ValueKey('logBody'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (overview.status == PondStatus.isolated)
                Notice(l10n.pondIsolatedBanner, danger: true),
              if (stop.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: StopFeedingSign(reasons: stop),
                )
              else if (overview.rationG > 0)
                _AimFor(rationG: overview.rationG),
              gap,
              BigNumberField(
                key: const ValueKey('feedField'),
                label: l10n.feedGiven,
                controller: _feed,
                decimal: true,
                suffix: 'kg',
                validator: (_) => _feedKg == null ? l10n.fieldRequired : null,
              ),
              gap,
              LeftoverPicker(
                value: _leftover,
                ateFast: _ateFast,
                onChanged: (l, fast) => setState(() {
                  _leftover = l;
                  _ateFast = fast;
                }),
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BigNumberField(
                      key: const ValueKey('deathsField'),
                      label: l10n.deaths,
                      controller: _deaths,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (_deathCount > 0) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: OptionButton(
                        key: const ValueKey('optDeathLook'),
                        title: l10n.deathAppearanceButton,
                        picked: _signsPreview(_deathSigns),
                        onTap: () =>
                            _pickSigns(l10n.deathAppearance, deathSigns, true),
                      ),
                    ),
                  ],
                ],
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OptionButton(
                      key: const ValueKey('optSigns'),
                      title: l10n.signsSeen,
                      picked: _signsPreview(_signs),
                      onTap: () => _pickSigns(
                        l10n.signsSeen,
                        WarningSign.values.toSet(),
                        false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OptionButton(
                      key: const ValueKey('optColour'),
                      title: l10n.waterColourLabel,
                      picked: _colour == null
                          ? null
                          : Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: waterColourValue(_colour!),
                                shape: BoxShape.circle,
                                border: Border.all(color: context.dobo.line),
                              ),
                            ),
                      onTap: () => _pickColour(l10n.waterColourLabel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OptionButton(
                      key: const ValueKey('optFeedings'),
                      title: l10n.feedingsButton,
                      picked: _feedings == null
                          ? null
                          : Text(
                              '$_feedings',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                      onTap: () => _pickFeedings(l10n.feedings),
                    ),
                  ),
                ],
              ),
              if (widget.showLot) ...[
                gap,
                _LotPicker(
                  day: widget.date,
                  value: _lotId,
                  onChanged: (id) => setState(() => _lotId = id),
                ),
              ],
              // Workers never meet a text field (CLAUDE.md, rule 3).
              if (!isWorker) ...[
                gap,
                if (_showNote)
                  TextFormField(
                    controller: _note,
                    decoration: InputDecoration(labelText: l10n.noteLabel),
                    maxLines: 3,
                  )
                else
                  TextButton.icon(
                    onPressed: () => setState(() => _showNote = true),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addNote),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Up to three of the picked signs, then how many more.
  Widget? _signsPreview(Set<WarningSign> signs) {
    if (signs.isEmpty) return null;
    final shown = [
      for (final s in WarningSign.values)
        if (signs.contains(s)) s,
    ];
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final s in shown.take(3)) Icon(warningSignIcon(s), size: 20),
        if (shown.length > 3) Text('+${shown.length - 3}'),
      ],
    );
  }
}

/// The ration to aim for on worker screens: the feed bowl and plain kg, an
/// instruction rather than an estimate (docs/design.md §Step 3).
class _AimFor extends StatelessWidget {
  const _AimFor({required this.rationG});

  final int rationG;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final kg = formatKg(rationG, Localizations.localeOf(context));
    return Semantics(
      label: l10n.labelValue(l10n.rationToday, kg),
      excludeSemantics: true,
      child: Row(
        children: [
          const Icon(feedIcon, size: 36),
          const SizedBox(width: 12),
          Text(kg, style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }
}

/// How many times the fish were fed, 1 to 6; tapping the picked one clears
/// it.
class _FeedingsGrid extends StatelessWidget {
  const _FeedingsGrid({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var n = 1; n <= 6; n++)
          SizedBox(
            key: ValueKey('feedings-$n'),
            width: (box.maxWidth - 16) / 3,
            height: 72,
            child: n == value
                ? FilledButton(
                    onPressed: () => onChanged(null),
                    child: Text('$n', style: const TextStyle(fontSize: 28)),
                  )
                : OutlinedButton(
                    onPressed: () => onChanged(n),
                    child: Text('$n', style: const TextStyle(fontSize: 28)),
                  ),
          ),
      ],
    ),
  );
}

/// The feed lot of a member's log: the oldest usable one unless picked.
class _LotPicker extends ConsumerWidget {
  const _LotPicker({
    required this.day,
    required this.value,
    required this.onChanged,
  });

  /// The log's day: lots delivered later can't have fed it.
  final DateTime day;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stock = ref.watch(feedStockProvider).value;
    final usable = stock == null
        ? const <FeedLotBalance>[]
        : usableLots(stock, day);
    final shown = [
      for (final b in stock?.lots ?? const <FeedLotBalance>[])
        if (b.lot.id == value || usable.contains(b)) b.lot,
    ];
    return DropdownButtonFormField<String?>(
      key: const ValueKey('feed-lot'),
      initialValue: shown.any((l) => l.id == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.feedLot),
      items: [
        DropdownMenuItem(child: Text(l10n.feedLotAuto)),
        for (final l in shown)
          DropdownMenuItem(
            value: l.id,
            child: Text(
              [
                if (l.label != null) l.label!,
                l10n.phase(l.phase),
                formatDate(l.manufacturedOn),
              ].join(' · '),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
