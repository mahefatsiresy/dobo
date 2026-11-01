import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/labels.dart';
import '../common/pond_colour.dart';
import 'pond_figures.dart';
import 'pond_overview.dart';
import '../../domain/types.dart';
import '../common/notice.dart';
import '../../domain/alerts/alert.dart';
import '../../l10n/formatting.dart';
import '../alerts/alert_providers.dart';
import '../common/estimated.dart';

class PondsScreen extends ConsumerWidget {
  const PondsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overviews = ref.watch(pondOverviewsProvider).value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabPonds)),
      // Ponds are set up by admins (SPEC §3).
      floatingActionButton: (ref.watch(sessionProvider).value?.isAdmin ?? false)
          ? FloatingActionButton.extended(
              heroTag: null, // Tabs keep each branch alive: shared tags clash.
              onPressed: () => context.go('/ponds/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.pondAdd),
            )
          : null,
      body: overviews == null
          ? const Center(child: CircularProgressIndicator())
          : overviews.isEmpty
          ? Center(child: Text(l10n.pondsEmpty))
          : ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
              children: [
                for (final o in overviews)
                  Card(
                    child: InkWell(
                      onTap: () => context.go('/ponds/${o.pond.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PondBadge(code: o.pond.code, colour: o.pond.colour),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.pondRole(o.pond.role),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(l10n.pondStatus(o.status)),
                                  if (o.status == PondStatus.isolated)
                                    Notice(
                                      l10n.pondIsolatedBanner,
                                      danger: true,
                                    ),
                                  const SizedBox(height: 4),
                                  PondFigures(overview: o),
                                  if (o.rationG > 0)
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        Text(l10n.labelColon(l10n.rationToday)),
                                        EstimatedLabel(
                                          value: formatKg(
                                            o.rationG,
                                            Localizations.localeOf(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  _AlertCounts(
                                    alerts: ref.watch(
                                      pondAlertsProvider(o.pond.id),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Red and amber counts of a pond's alerts; nothing when it has none.
class _AlertCounts extends StatelessWidget {
  const _AlertCounts({required this.alerts});

  final List<Alert> alerts;

  @override
  Widget build(BuildContext context) {
    final danger = alerts.where((a) => a.severity == Severity.danger).length;
    final warning = alerts.length - danger;
    Widget chip(IconData icon, Color colour, int n) => Padding(
      padding: const EdgeInsets.only(right: 12, top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colour),
          const SizedBox(width: 4),
          Text(
            '$n',
            style: TextStyle(color: colour, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
    return Row(
      children: [
        if (danger > 0) chip(Icons.error, Colors.red.shade800, danger),
        if (warning > 0) chip(Icons.warning, Colors.amber.shade800, warning),
      ],
    );
  }
}
