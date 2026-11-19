import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../theme/tokens.dart';
import '../alerts/alert_providers.dart';
import '../common/attention_band.dart';
import '../common/estimated.dart';
import '../daily_log/daily_log_providers.dart';
import '../prep/prep_providers.dart';
import 'pond_attention.dart';
import 'pond_overview.dart';
import 'pond_row.dart';

/// The member's ponds (docs/design.md §Step 1): which ponds need someone
/// and how much to feed each, at a glance, in code order.
class PondsScreen extends ConsumerWidget {
  const PondsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Alerts decide the bands, the stop-feeding signs and the danger line:
    // until they are known the list would claim an all-clear and show
    // rations for ponds that must not be fed.
    final overviews = ref.watch(alertsProvider).hasValue
        ? ref.watch(pondOverviewsProvider).value
        : null;
    // Ponds are set up by admins (SPEC §3).
    final isAdmin = ref.watch(sessionProvider).value?.isAdmin ?? false;
    final add = isAdmin
        ? _AddPondRow(onTap: () => context.go('/ponds/new'))
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabPonds)),
      body: switch (overviews) {
        null => const Center(child: CircularProgressIndicator()),
        [] => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.pondsEmpty),
            ),
            ?add,
          ],
        ),
        final overviews => _PondList(overviews: overviews, add: add),
      },
    );
  }
}

class _PondList extends ConsumerWidget {
  const _PondList({required this.overviews, required this.add});

  final List<PondOverview> overviews;
  final Widget? add;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logged = ref.watch(loggedTodayProvider).value ?? const {};
    final prep = ref.watch(prepProgressAllProvider).value ?? const {};
    var totalG = 0;
    var dangerPonds = 0;
    final rows = <Widget>[];
    for (final o in overviews) {
      final id = o.pond.id;
      final attention = pondAttention(o, ref.watch(pondAlertsProvider(id)));
      if (attention?.severity == BandSeverity.danger) dangerPonds++;
      void open() => context.go('/ponds/$id');
      if (o.liveCount == 0 && !o.inconsistent) {
        rows.add(
          ShortPondRow(
            overview: o,
            attention: attention,
            prep: prep[id],
            onTap: open,
          ),
        );
        continue;
      }
      final stop = ref.watch(stopFeedingProvider(id));
      if (stop.isEmpty) totalG += o.rationG;
      rows.add(
        StockedPondRow(
          overview: o,
          attention: attention,
          loggedToday: logged.contains(id),
          stopFeeding: stop,
          onTap: open,
        ),
      );
    }
    return ListView(
      children: [
        _TopLines(totalG: totalG, dangerPonds: dangerPonds),
        const Divider(),
        for (final row in rows) ...[row, const Divider()],
        ?add,
      ],
    );
  }
}

/// Today's ration over the ponds that may be fed, and how many ponds show
/// a danger band.
class _TopLines extends StatelessWidget {
  const _TopLines({required this.totalG, required this.dangerPonds});

  final int totalG;
  final int dangerPonds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final danger = dangerPonds > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalG > 0)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  l10n.labelColon(l10n.pondsRationTotal),
                  style: text.bodyLarge,
                ),
                Text(
                  approx(formatKg(totalG, Localizations.localeOf(context))),
                  style: text.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                danger ? Icons.error : Icons.check_circle,
                color: danger ? c.danger : c.ok,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.pondsDangerCount(dangerPonds),
                  style: text.bodyLarge?.copyWith(
                    color: danger ? c.danger : c.ink,
                    fontWeight: danger ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddPondRow extends StatelessWidget {
  const _AddPondRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.add),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).pondAdd,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
