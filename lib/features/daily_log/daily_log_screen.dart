import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/daily_log_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
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

/// One pond-day (SPEC F3): the worker's screen, also used by members.
/// Opening a day already logged edits it.
class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key, required this.pondId, required this.date});

  final String pondId;

  /// Date only.
  final DateTime date;

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
          ),
        );
    ref.invalidate(dailyLogForDayProvider((widget.pondId, widget.date)));
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
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
