import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/customer_repository.dart';
import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../common/choice_buttons.dart';
import '../common/details_fold.dart';
import '../common/form_body.dart';
import '../common/form_menu.dart';
import '../common/pinned_action.dart';
import '../../theme/tokens.dart';
import '../common/save_once.dart';
import 'sales_providers.dart';

/// Who buys the fish (SPEC F12).
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final customers = ref.watch(activeCustomersProvider).value;
    final sorted = [...?customers]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final c = context.dobo;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.customersTitle)),
      body: customers == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.customersNone),
                  ),
                for (final customer in sorted) ...[
                  ListTile(
                    minTileHeight: 56,
                    title: Text(customer.name),
                    subtitle: Text(
                      [
                        l10n.customerTypeLabel(customer.type),
                        ?customer.contact,
                      ].join(', '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/more/sales/customers/${customer.id}'),
                  ),
                  Divider(height: 1, thickness: 1, color: c.line),
                ],
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.person_add),
                  title: Text(l10n.customerNew),
                  onTap: () => context.push('/more/sales/customers/new'),
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
    final saved = id ?? await repo.create(_input);
    if (id != null) await repo.update(id, _input);
    if (!mounted) return;
    showDone(context, AppLocalizations.of(context).doneSaved);
    context.canPop() ? context.pop(saved) : context.go('/more/sales/customers');
  }

  Future<void> _archive() async {
    await ref.read(customerRepositoryProvider).archive(widget.customerId!);
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go('/more/sales/customers');
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
    final editing = widget.customerId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l10n.customerEdit : l10n.customerNew),
        actions: [
          if (editing)
            FormMenu(
              entries: [
                FormMenuEntry(
                  label: l10n.customerArchive,
                  icon: Icons.person_remove_outlined,
                  onTap: () => saveOnce(_archive),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: PinnedAction(
        icon: editing ? Icons.check : Icons.person_add,
        label: editing ? l10n.actionSaveCustomer : l10n.actionAddCustomer,
        onPressed: saving ? null : () => saveOnce(_save),
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
            ChoiceField<CustomerType>(
              label: l10n.customerType,
              requiredText: l10n.fieldRequired,
              options: [
                for (final t in CustomerType.values)
                  (t, l10n.customerTypeLabel(t)),
              ],
              value: _type,
              onChanged: (t) => setState(() => _type = t),
            ),
            DetailsFold(
              initiallyOpen: _contact.text.isNotEmpty,
              children: [
                gap,
                TextFormField(
                  controller: _contact,
                  decoration: InputDecoration(labelText: l10n.customerContact),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
