import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/harvest_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/sales.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../batches/batch_providers.dart';
import '../common/attention_band.dart';
import '../common/choice_buttons.dart';
import '../common/date_field.dart';
import '../common/details_fold.dart';
import '../common/farm_today.dart';
import '../common/form_body.dart';
import '../common/form_menu.dart';
import '../common/number_field.dart';
import '../common/pinned_action.dart';
import '../common/pond_choice.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import '../../theme/tokens.dart';
import 'customer_picker.dart';
import 'sales_providers.dart';

/// Fish from a harvest going to a customer (SPEC F12). No price in v1.
/// [harvestId] presets the harvest; [saleId] corrects that sale.
class SaleScreen extends ConsumerStatefulWidget {
  const SaleScreen({
    super.key,
    required this.batchId,
    this.harvestId,
    this.saleId,
  });

  final String batchId;
  final String? harvestId;
  final String? saleId;

  @override
  ConsumerState<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends ConsumerState<SaleScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _note = TextEditingController();
  late String? _harvestId = widget.harvestId;
  String? _customerId;
  ProductForm? _productForm;
  late var _date = ref.read(farmTodayProvider);
  var _loaded = false;

  bool get _correcting => widget.saleId != null;

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  void _leave() => context.canPop()
      ? context.pop()
      : context.go('/more/batches/${widget.batchId}');

  Future<void> _pickCustomer() async {
    final id = await pickCustomer(context, current: _customerId);
    if (id != null && mounted) setState(() => _customerId = id);
  }

  SaleInput get _input => SaleInput(
    harvestId: _harvestId!,
    customerId: _customerId!,
    date: _date,
    weightG: (parseDecimal(_weight.text)! * 1000).round(),
    form: _productForm!,
    deliveryNote: _note.text,
  );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(harvestRepositoryProvider);
    _correcting
        ? await repo.correctSale(widget.saleId!, _input)
        : await repo.sell(_input);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDone(context, _correcting ? l10n.doneCorrected : l10n.doneSold);
    _leave();
  }

  Future<void> _delete(Sale sale, String customer) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmDelete(
      context,
      l10n.deleteSaleConfirm(
        formatDate(sale.recordedAt),
        formatKg(sale.weightG, Localizations.localeOf(context)),
        customer,
      ),
    );
    if (!ok || !mounted) return;
    await ref.read(harvestRepositoryProvider).deleteSale(sale.id);
    if (!mounted) return;
    showDone(context, l10n.doneDeleted);
    _leave();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final harvests = ref.watch(batchHarvestsProvider(widget.batchId)).value;
    final customers = ref.watch(customersByIdProvider).value;
    final ponds = ref.watch(allPondsByIdProvider).value;
    final batch = ref
        .watch(batchSummariesProvider)
        .value
        ?.where((s) => s.batch.id == widget.batchId)
        .firstOrNull
        ?.batch;
    if (harvests == null ||
        customers == null ||
        ponds == null ||
        batch == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sale = !_correcting
        ? null
        : [for (final h in harvests) ...h.sales]
              .where((s) => s.id == widget.saleId)
              .firstOrNull;
    if (_correcting && sale == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (sale != null && !_loaded) {
      _loaded = true;
      _harvestId = sale.harvestId;
      _customerId = sale.customerId;
      _productForm = sale.form;
      _date = farmDate(sale.recordedAt);
      _weight.text = formatForInput(sale.weightG / 1000);
      _note.text = sale.deliveryNote ?? '';
    }

    /// Kilos of [h] not yet sold, this sale left out when correcting it.
    int unsold(HarvestWithSales h) => unsoldG(h.harvest.weightG, [
      for (final s in h.sales)
        if (s.id != widget.saleId) s.weightG,
    ]);
    final chosen = harvests
        .where((h) => h.harvest.id == _harvestId)
        .firstOrNull;
    final unsoldNow = chosen == null ? 0 : unsold(chosen);
    final kg = parseDecimal(_weight.text);
    final over = chosen != null && kg != null && kg * 1000 > unsoldNow;
    final customer = customers[_customerId];
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _correcting ? l10n.correctionTitle : l10n.saleTitle(batch.code),
        ),
        actions: [
          if (sale != null)
            FormMenu(
              entries: [
                FormMenuEntry(
                  label: l10n.delete,
                  icon: Icons.delete_outline,
                  onTap: () => _delete(sale, customer?.name ?? '?'),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: PinnedAction(
        icon: _correcting ? Icons.check : Icons.storefront,
        label: _correcting ? l10n.actionSaveCorrection : l10n.sellAction,
        onPressed: saving ? null : () => saveOnce(_save),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            if (widget.harvestId != null && chosen != null)
              PondHeader(
                label: l10n.saleHarvest,
                pond: ponds[chosen.harvest.pondId]!,
                trailing: Text(
                  l10n.saleHarvestLeft(
                    formatDate(chosen.harvest.recordedAt),
                    chosen.harvest.isFinal
                        ? l10n.harvestKindFinal
                        : l10n.harvestKindPartial,
                    formatKg(unsoldNow, locale),
                  ),
                ),
              )
            else
              ChoiceField<String>(
                label: l10n.saleHarvest,
                requiredText: l10n.fieldRequired,
                options: [
                  for (final h in harvests)
                    (
                      h.harvest.id,
                      l10n.saleHarvestChoice(
                        formatDate(h.harvest.recordedAt),
                        ponds[h.harvest.pondId]?.code ?? '?',
                        formatKg(unsold(h), locale),
                      ),
                    ),
                ],
                value: _harvestId,
                onChanged: (v) => setState(() => _harvestId = v),
              ),
            gap,
            DateField(
              label: l10n.saleDate,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            gap,
            NumberField(
              label: l10n.saleWeight,
              controller: _weight,
              decimal: true,
              suffix: 'kg',
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  (parseDecimal(v ?? '') ?? 0) <= 0 ? l10n.fieldRequired : null,
            ),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AttentionBand(
                  severity: BandSeverity.warning,
                  text: l10n.saleOverHarvest(formatKg(unsoldNow, locale)),
                ),
              ),
            gap,
            FormField<String>(
              validator: (_) => _customerId == null ? l10n.fieldRequired : null,
              builder: (state) => InkWell(
                key: const ValueKey('sale-customer'),
                onTap: _pickCustomer,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.saleCustomer,
                    errorText: state.errorText,
                    suffixIcon: const Icon(Icons.chevron_right),
                  ),
                  child: Text(customer?.name ?? ''),
                ),
              ),
            ),
            gap,
            ChoiceField<ProductForm>(
              label: l10n.saleForm,
              requiredText: l10n.fieldRequired,
              options: [
                for (final f in ProductForm.values) (f, l10n.productForm(f)),
              ],
              value: _productForm,
              onChanged: (f) => setState(() => _productForm = f),
            ),
            DetailsFold(
              initiallyOpen: _note.text.isNotEmpty,
              children: [
                gap,
                TextFormField(
                  controller: _note,
                  decoration: InputDecoration(labelText: l10n.saleNote),
                ),
              ],
            ),
            if (harvests.isEmpty)
              Text(
                l10n.harvestNoPond,
                style: TextStyle(color: context.dobo.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}
