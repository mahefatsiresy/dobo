import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/harvest_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../batches/batch_providers.dart';
import '../common/date_field.dart';
import '../common/farm_today.dart';
import '../common/form_body.dart';
import '../common/notice.dart';
import '../common/number_field.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import 'sales_providers.dart';

/// Fish from a harvest going to a customer (SPEC F12). No price in v1.
class SaleScreen extends ConsumerStatefulWidget {
  const SaleScreen({super.key, required this.batchId});

  final String batchId;

  @override
  ConsumerState<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends ConsumerState<SaleScreen> with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _note = TextEditingController();
  String? _harvestId;
  String? _customerId;
  ProductForm? _productForm;
  late var _date = ref.read(farmTodayProvider);

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _newCustomer() async {
    final id = await context.push<String>('/more/sales/customers/new');
    if (id != null && mounted) setState(() => _customerId = id);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await ref
        .read(harvestRepositoryProvider)
        .sell(
          SaleInput(
            harvestId: _harvestId!,
            customerId: _customerId!,
            date: _date,
            weightG: (parseDecimal(_weight.text)! * 1000).round(),
            form: _productForm!,
            deliveryNote: _note.text,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final harvests = ref.watch(batchHarvestsProvider(widget.batchId)).value;
    final customers = ref.watch(activeCustomersProvider).value;
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
    if (_harvestId == null ||
        !harvests.any((h) => h.harvest.id == _harvestId)) {
      _harvestId = harvests.firstOrNull?.harvest.id;
    }
    final chosen = harvests
        .where((h) => h.harvest.id == _harvestId)
        .firstOrNull;
    final unsoldG = chosen == null
        ? 0
        : chosen.harvest.weightG -
              chosen.sales.fold<int>(0, (n, s) => n + s.weightG);
    final kg = parseDecimal(_weight.text);
    final over = chosen != null && kg != null && kg * 1000 > unsoldG;
    String? required(Object? v) => v == null ? l10n.fieldRequired : null;
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.saleTitle(batch.code))),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _harvestId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.saleHarvest),
              validator: required,
              items: [
                for (final h in harvests)
                  DropdownMenuItem(
                    value: h.harvest.id,
                    child: Text(
                      l10n.saleHarvestOption(
                        formatDate(h.harvest.recordedAt),
                        ponds[h.harvest.pondId]?.code ?? '?',
                        formatKg(h.harvest.weightG, locale),
                      ),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _harvestId = v),
            ),
            gap,
            KeyedSubtree(
              key: const ValueKey('sale-customer'),
              child: DropdownButtonFormField<String>(
                // Rebuilt when "Nouveau client" picks the one just made.
                key: ValueKey(_customerId),
                initialValue: customers.any((c) => c.id == _customerId)
                    ? _customerId
                    : null,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.saleCustomer),
                validator: required,
                items: [
                  for (final c in customers)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _customerId = v),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
                onPressed: _newCustomer,
                icon: const Icon(Icons.person_add),
                label: Text(l10n.saleNewCustomer),
              ),
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
            if (over) Notice(l10n.saleOverHarvest(formatKg(unsoldG, locale))),
            gap,
            Text(l10n.saleForm, style: Theme.of(context).textTheme.titleMedium),
            FormField<ProductForm>(
              validator: (_) => required(_productForm),
              builder: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in ProductForm.values)
                        ChoiceChip(
                          label: Text(l10n.productForm(f)),
                          selected: _productForm == f,
                          onSelected: (_) => setState(() => _productForm = f),
                        ),
                    ],
                  ),
                  if (state.hasError)
                    Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            gap,
            DateField(
              label: l10n.saleDate,
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            gap,
            TextFormField(
              controller: _note,
              decoration: InputDecoration(labelText: l10n.saleNote),
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
      ),
    );
  }
}
