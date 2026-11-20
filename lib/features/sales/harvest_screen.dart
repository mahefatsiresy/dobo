import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/errors.dart';
import '../../db/repositories/harvest_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../batches/batch_providers.dart';
import '../common/date_field.dart';
import '../common/estimated.dart';
import '../common/farm_today.dart';
import '../common/form_body.dart';
import '../common/attention_band.dart';
import '../common/choice_buttons.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
import '../common/pond_choice.dart';
import '../common/number_field.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import 'sales_providers.dart';
import '../../domain/dates.dart';

/// Fish taken out of a pond for sale (SPEC F12). Isolated ponds are not
/// offered: no fish leave them. With [harvestId], corrects that harvest.
class HarvestScreen extends ConsumerStatefulWidget {
  const HarvestScreen({super.key, required this.batchId, this.harvestId});

  final String batchId;
  final String? harvestId;

  @override
  ConsumerState<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends ConsumerState<HarvestScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _count = TextEditingController();
  final _weight = TextEditingController();
  String? _pondId;
  var _isFinal = false;
  late var _date = ref.read(farmTodayProvider);
  var _loaded = false;

  @override
  void dispose() {
    _count.dispose();
    _weight.dispose();
    super.dispose();
  }

  int? get _countValue {
    final v = parseDecimal(_count.text);
    return v == null || v <= 0 ? null : v.round();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final input = HarvestInput(
      batchId: widget.batchId,
      pondId: _pondId!,
      date: _date,
      count: _countValue!,
      weightG: (parseDecimal(_weight.text)! * 1000).round(),
      isFinal: _isFinal,
    );
    final repo = ref.read(harvestRepositoryProvider);
    final id = widget.harvestId;
    await (id == null ? repo.harvest(input) : repo.correct(id, input));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDone(context, id == null ? l10n.doneHarvested : l10n.doneCorrected);
    _leave();
  }

  void _leave() => context.canPop()
      ? context.pop()
      : context.go('/more/batches/${widget.batchId}');

  Future<void> _delete(Harvest old, int sales, String pond) async {
    final l10n = AppLocalizations.of(context);
    if (sales > 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.harvestHasSales(sales))));
      return;
    }
    final ok = await confirmDelete(
      context,
      l10n.deleteHarvestConfirm(
        formatDate(old.recordedAt),
        formatKg(old.weightG, Localizations.localeOf(context)),
        pond,
      ),
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(harvestRepositoryProvider).delete(old.id);
    } on HarvestHasSalesException {
      return;
    }
    if (!mounted) return;
    showDone(context, l10n.doneDeleted);
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final placements = ref.watch(placementsProvider).value;
    final ponds = ref.watch(allPondsByIdProvider).value;
    final batch = ref
        .watch(batchSummariesProvider)
        .value
        ?.where((s) => s.batch.id == widget.batchId)
        .firstOrNull
        ?.batch;
    final editing = widget.harvestId != null;
    final oldEntry = editing
        ? ref
              .watch(batchHarvestsProvider(widget.batchId))
              .value
              ?.where((h) => h.harvest.id == widget.harvestId)
              .firstOrNull
        : null;
    final old = oldEntry?.harvest;
    if (placements == null ||
        ponds == null ||
        batch == null ||
        (editing && old == null)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (old != null && !_loaded) {
      _loaded = true;
      _pondId = old.pondId;
      _isFinal = old.isFinal;
      _date = farmDate(old.recordedAt);
      _count.text = '${old.count}';
      _weight.text = formatForInput(old.weightG / 1000);
    }
    final here = [
      for (final p in placements)
        if (p.batchId == widget.batchId &&
            p.live.count > 0 &&
            ponds[p.pondId] != null &&
            ponds[p.pondId]!.status != PondStatus.isolated)
          p.pondId,
      // A correction keeps its pond, emptied by the harvest itself.
      if (old != null &&
          !placements.any(
            (p) =>
                p.batchId == widget.batchId &&
                p.pondId == old.pondId &&
                p.live.count > 0,
          ))
        old.pondId,
    ];
    if (_pondId != null && !here.contains(_pondId)) _pondId = null;
    final live = placements
        .where((p) => p.batchId == widget.batchId && p.pondId == _pondId)
        .fold(0, (n, p) => n + p.live.count);
    final count = _countValue;
    final missing = !editing && _isFinal && count != null && count < live
        ? live - count
        : 0;
    const gap = SizedBox(height: 16);

    Widget band(String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AttentionBand(severity: BandSeverity.warning, text: text),
    );
    final pond = ponds[_pondId];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? l10n.harvestEditTitle(batch.code)
              : l10n.harvestTitle(batch.code),
        ),
        actions: [
          if (old != null)
            FormMenu(
              entries: [
                FormMenuEntry(
                  label: l10n.delete,
                  icon: Icons.delete_outline,
                  onTap: () => _delete(
                    old,
                    oldEntry!.sales.length,
                    ponds[old.pondId]?.code ?? '?',
                  ),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: here.isEmpty
          ? null
          : PinnedAction(
              icon: editing ? Icons.check : Icons.set_meal,
              label: editing ? l10n.actionSaveCorrection : l10n.harvestAction,
              onPressed: saving ? null : () => saveOnce(_save),
            ),
      body: here.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: AttentionBand(
                severity: BandSeverity.warning,
                text: l10n.harvestNoPond,
              ),
            )
          : Form(
              key: _form,
              child: FormBody(
                children: [
                  PondChoiceField(
                    label: l10n.harvestPond,
                    requiredText: l10n.fieldRequired,
                    options: [
                      for (final id in here)
                        if (ponds[id] != null) PondOption(pond: ponds[id]!),
                    ],
                    value: _pondId,
                    onChanged: (v) => setState(() => _pondId = v),
                  ),
                  gap,
                  DateField(
                    label: l10n.harvestDate,
                    value: _date,
                    onChanged: (d) => setState(() => _date = d),
                  ),
                  gap,
                  NumberField(
                    label: l10n.harvestWeight,
                    controller: _weight,
                    decimal: true,
                    suffix: 'kg',
                    validator: (v) => (parseDecimal(v ?? '') ?? 0) <= 0
                        ? l10n.fieldRequired
                        : null,
                  ),
                  gap,
                  if (!editing && pond != null) ...[
                    EstimatedLabel(
                      value: l10n.harvestAim(
                        formatCount(live, locale),
                        pond.code,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  NumberField(
                    label: l10n.harvestCount,
                    controller: _count,
                    onChanged: (_) => setState(() {}),
                    validator: (_) =>
                        _countValue == null ? l10n.fieldRequired : null,
                  ),
                  gap,
                  ChoiceButtons<bool>(
                    options: [
                      (false, l10n.harvestPartial),
                      (true, l10n.harvestFinal),
                    ],
                    value: _isFinal,
                    onChanged: (v) => setState(() => _isFinal = v),
                  ),
                  if (missing > 0)
                    band(l10n.harvestMissing(formatCount(missing, locale))),
                ],
              ),
            ),
    );
  }
}
