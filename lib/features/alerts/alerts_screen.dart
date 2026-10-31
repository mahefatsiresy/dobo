import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/database.dart';
import '../../db/repositories/batch_repository.dart';
import '../../domain/alerts/alert.dart';
import '../../l10n/app_localizations.dart';
import '../ponds/pond_overview.dart';
import 'alert_providers.dart';
import 'alert_route.dart';
import 'alert_tile.dart';

/// Every open alert and due task, danger first, filterable by pond
/// (SPEC F7).
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  /// The pond shown, or every pond when null.
  String? _pondId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final alerts = ref.watch(alertsProvider).value;
    final ponds = <String, Pond>{
      for (final p in ref.watch(pondsProvider).value ?? const <Pond>[]) p.id: p,
    };
    final batchCodes = <String, String>{
      for (final s
          in ref.watch(batchSummariesProvider).value ?? const <BatchSummary>[])
        s.batch.id: s.batch.code,
    };
    final withAlerts = [
      for (final p in ponds.values)
        if (alerts?.any((a) => a.pondId == p.id) ?? false) p,
    ]..sort((a, b) => a.code.compareTo(b.code));
    final pondId = withAlerts.any((p) => p.id == _pondId) ? _pondId : null;
    final shown = [
      for (final a in alerts ?? const <Alert>[])
        if (pondId == null || a.pondId == pondId) a,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabAlerts)),
      body: alerts == null
          ? const Center(child: CircularProgressIndicator())
          : alerts.isEmpty
          ? Center(child: Text(l10n.alertsEmpty))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (withAlerts.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        for (final (id, label) in [
                          (null, l10n.alertsAll),
                          for (final p in withAlerts) (p.id, p.code),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: pondId == id,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.padded,
                              onSelected: (_) => setState(() => _pondId = id),
                            ),
                          ),
                      ],
                    ),
                  ),
                for (final a in shown)
                  AlertTile(
                    alert: a,
                    pond: ponds[a.pondId],
                    batchCode: batchCodes[a.batchId],
                    onTap: switch (alertRoute(a)) {
                      final route? => () => context.push(route),
                      null => null,
                    },
                  ),
              ],
            ),
    );
  }
}
