import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../common/notice.dart';
import '../common/number_field.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';

/// Fish taken out of a pond for sale (SPEC F12). Isolated ponds are not
/// offered: no fish leave them.
class HarvestScreen extends ConsumerStatefulWidget {
  const HarvestScreen({super.key, required this.batchId});

  final String batchId;

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
    await ref
        .read(harvestRepositoryProvider)
        .harvest(
          HarvestInput(
            batchId: widget.batchId,
            pondId: _pondId!,
            date: _date,
            count: _countValue!,
            weightG: (parseDecimal(_weight.text)! * 1000).round(),
            isFinal: _isFinal,
          ),
        );
    if (mounted) context.pop();
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
    if (placements == null || ponds == null || batch == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final here = [
      for (final p in placements)
        if (p.batchId == widget.batchId &&
            p.live.count > 0 &&
            ponds[p.pondId] != null &&
            ponds[p.pondId]!.status != PondStatus.isolated)
          p,
    ];
    if (_pondId == null || !here.any((p) => p.pondId == _pondId)) {
      _pondId = here.firstOrNull?.pondId;
    }
    final live = here
        .where((p) => p.pondId == _pondId)
        .fold(0, (n, p) => n + p.live.count);
    final count = _countValue;
    final missing = _isFinal && count != null && count < live
        ? live - count
        : 0;
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.harvestTitle(batch.code))),
      body: here.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Notice(l10n.harvestNoPond),
            )
          : Form(
              key: _form,
              child: FormBody(
                children: [
                  DropdownButtonFormField<String>(
                    key: const ValueKey('harvest-pond'),
                    initialValue: _pondId,
                    decoration: InputDecoration(labelText: l10n.harvestPond),
                    items: [
                      for (final p in here)
                        DropdownMenuItem(
                          value: p.pondId,
                          child: Text(ponds[p.pondId]!.code),
                        ),
                    ],
                    onChanged: (v) => setState(() => _pondId = v),
                  ),
                  const SizedBox(height: 8),
                  EstimatedLabel(
                    value: l10n.harvestEstimate(formatCount(live, locale)),
                  ),
                  gap,
                  DateField(
                    label: l10n.harvestDate,
                    value: _date,
                    onChanged: (d) => setState(() => _date = d),
                  ),
                  gap,
                  NumberField(
                    label: l10n.harvestCount,
                    controller: _count,
                    onChanged: (_) => setState(() {}),
                    validator: (_) =>
                        _countValue == null ? l10n.fieldRequired : null,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.harvestPartial),
                        selected: !_isFinal,
                        onSelected: (_) => setState(() => _isFinal = false),
                      ),
                      ChoiceChip(
                        label: Text(l10n.harvestFinal),
                        selected: _isFinal,
                        onSelected: (_) => setState(() => _isFinal = true),
                      ),
                    ],
                  ),
                  if (missing > 0) ...[
                    gap,
                    Notice(l10n.harvestMissing(formatCount(missing, locale))),
                  ],
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
            ),
    );
  }
}
