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
import '../common/notice.dart';
import '../common/pond_colour.dart';
import '../common/save_once.dart';
import '../common/sign_grid.dart';
import '../ponds/pond_overview.dart';
import 'daily_log_providers.dart';
import '../common/form_body.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
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
    const gap = SizedBox(height: 20);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            PondBadge(code: pond.code, colour: pond.colour),
            const SizedBox(width: 12),
            Text(formatDate(widget.date)),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            if (overview.status == PondStatus.isolated)
              Notice(l10n.pondIsolatedBanner, danger: true),
            if (ref.watch(stopFeedingProvider(widget.pondId)) case final reasons
                when reasons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StopFeedingSign(reasons: reasons),
              ),
            BigNumberField(
              label: l10n.feedGiven,
              controller: _feed,
              decimal: true,
              suffix: 'kg',
              hint: overview.rationG > 0
                  ? l10n.rationHint(formatKg(overview.rationG, locale))
                  : null,
              validator: (_) => _feedKg == null ? l10n.fieldRequired : null,
            ),
            if (widget.showLot) ...[
              gap,
              _LotPicker(
                day: widget.date,
                value: _lotId,
                onChanged: (id) => setState(() => _lotId = id),
              ),
            ],
            gap,
            heading(l10n.feedings),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var n = 1; n <= 6; n++)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: n == _feedings
                        ? FilledButton(
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => setState(() => _feedings = null),
                            child: Text('$n'),
                          )
                        : OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => setState(() => _feedings = n),
                            child: Text('$n'),
                          ),
                  ),
              ],
            ),
            gap,
            heading(l10n.leftovers),
            LeftoverPicker(
              value: _leftover,
              ateFast: _ateFast,
              onChanged: (l, fast) => setState(() {
                _leftover = l;
                _ateFast = fast;
              }),
            ),
            gap,
            BigNumberField(
              label: l10n.deaths,
              controller: _deaths,
              onChanged: (_) => setState(() {}),
            ),
            if (_deathCount > 0) ...[
              gap,
              heading(l10n.deathAppearance),
              SignGrid(
                options: deathSigns,
                selected: _deathSigns,
                onChanged: (s) => setState(() => _deathSigns = s),
              ),
            ],
            gap,
            heading(l10n.signsSeen),
            SignGrid(
              options: WarningSign.values.toSet(),
              selected: _signs,
              onChanged: (s) => setState(() => _signs = s),
            ),
            gap,
            heading(l10n.waterColourLabel),
            ColourSwatches(
              value: _colour,
              onChanged: (c) => setState(() => _colour = c),
            ),
            gap,
            if (_showNote)
              TextFormField(
                controller: _note,
                decoration: InputDecoration(labelText: l10n.noteLabel),
                maxLines: 3,
              )
            else
              TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
                onPressed: () => setState(() => _showNote = true),
                icon: const Icon(Icons.add),
                label: Text(l10n.addNote),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(64),
              ),
              onPressed: saving ? null : () => saveOnce(_save),
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
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
