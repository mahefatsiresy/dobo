import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../../theme/tokens.dart';

/// Customers for the sale form's picker: recent buyers first.
final customersByRecentSaleProvider = StreamProvider<List<Customer>>(
  (ref) => ref.watch(customerRepositoryProvider).watchByRecentSale(),
);

/// Opens the customer picker; the picked customer's id, or null on back.
Future<String?> pickCustomer(BuildContext context, {String? current}) =>
    context.push<String>(
      Uri(
        path: '/more/sales/customers/pick',
        queryParameters: {'current': ?current},
      ).toString(),
    );

/// A page of customers, one tap to pick, "Nouveau client" at its foot
/// (docs/design.md §Step 7).
class CustomerPickerScreen extends ConsumerWidget {
  const CustomerPickerScreen({super.key, this.current});

  final String? current;

  Future<void> _new(BuildContext context) async {
    final id = await context.push<String>('/more/sales/customers/new');
    if (id != null && context.mounted) context.pop(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.dobo;
    final customers = ref.watch(customersByRecentSaleProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.customerPickTitle)),
      body: customers == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final customer in customers) ...[
                  ListTile(
                    minTileHeight: 56,
                    title: Text(customer.name),
                    subtitle: Text(l10n.customerTypeLabel(customer.type)),
                    trailing: customer.id == current
                        ? Icon(Icons.check, color: c.ink)
                        : null,
                    onTap: () => context.pop(customer.id),
                  ),
                  Divider(height: 1, color: c.line),
                ],
                ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.person_add),
                  title: Text(l10n.customerNew),
                  onTap: () => _new(context),
                ),
              ],
            ),
    );
  }
}
