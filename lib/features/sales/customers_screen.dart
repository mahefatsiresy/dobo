import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/customer_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../common/form_body.dart';
import '../common/save_once.dart';
import 'sales_providers.dart';

/// Who buys the fish (SPEC F12).
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customers = ref.watch(activeCustomersProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.customersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customer-new',
        onPressed: () => context.push('/more/sales/customers/new'),
        icon: const Icon(Icons.person_add),
        label: Text(l10n.customerNew),
      ),
      body: customers == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.customersNone),
                  ),
                for (final c in customers)
                  ListTile(
                    minTileHeight: 56,
                    title: Text(c.name),
                    subtitle: Text(
                      [
                        l10n.customerTypeLabel(c.type),
                        if (c.contact != null) c.contact!,
                      ].join(' · '),
                    ),
                    onTap: () => context.push('/more/sales/customers/${c.id}'),
                  ),
              ],
            ),
    );
  }
}

/// Adds or edits a customer; pops with its id.
class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final String? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<CustomerFormScreen>
    with SaveOnce {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  CustomerType? _type;
  var _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  CustomerInput get _input =>
      CustomerInput(name: _name.text, type: _type!, contact: _contact.text);

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(customerRepositoryProvider);
    final id = widget.customerId;
    if (id == null) {
      final created = await repo.create(_input);
      if (mounted) context.pop(created);
    } else {
      await repo.update(id, _input);
      if (mounted) context.pop(id);
    }
  }

  Future<void> _archive() async {
    await ref.read(customerRepositoryProvider).archive(widget.customerId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.customerId != null && !_loaded) {
      final c = ref.watch(customersByIdProvider).value?[widget.customerId!];
      if (c == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _loaded = true;
      _name.text = c.name;
      _contact.text = c.contact ?? '';
      _type = c.type;
    }
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customerId == null ? l10n.customerNew : l10n.customerEdit,
        ),
      ),
      body: Form(
        key: _form,
        child: FormBody(
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.customerName),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            gap,
            Text(
              l10n.customerType,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            FormField<CustomerType>(
              validator: (_) => _type == null ? l10n.fieldRequired : null,
              builder: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in CustomerType.values)
                        ChoiceChip(
                          label: Text(l10n.customerTypeLabel(t)),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
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
            TextFormField(
              controller: _contact,
              decoration: InputDecoration(labelText: l10n.customerContact),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: saving ? null : () => saveOnce(_save),
              child: Text(l10n.save),
            ),
            if (widget.customerId != null) ...[
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: saving ? null : () => saveOnce(_archive),
                child: Text(l10n.customerArchive),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
