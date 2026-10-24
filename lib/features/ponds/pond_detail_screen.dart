import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/config.dart';
import '../../domain/phase.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../l10n/labels.dart';
import '../common/estimated.dart';
import '../common/pond_colour.dart';
import 'pond_figures.dart';
import 'pond_overview.dart';

class PondDetailScreen extends ConsumerWidget {
  const PondDetailScreen({super.key, required this.pondId});

  final String pondId;

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.archiveConfirm(code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(pondRepositoryProvider).archive(pondId);
    if (context.mounted) context.go('/ponds');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final o = ref
        .watch(pondOverviewsProvider)
        .value
        ?.where((o) => o.pond.id == pondId)
        .firstOrNull;
    if (o == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pond = o.pond;
    final theme = Theme.of(context);
    final wide = FilledButton.styleFrom(minimumSize: const Size.fromHeight(56));

    return Scaffold(
      appBar: AppBar(title: Text(pond.code)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              PondBadge(code: pond.code, colour: pond.colour),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pondRole(pond.role),
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(l10n.pondStatus(pond.status)),
                    Text(
                      '${l10n.structure(pond.structure)}'
                      '${o.surfaceM2 == null ? '' : ' · ${formatNumber(o.surfaceM2!, locale)} m²'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PondFigures(overview: o),
          for (final b in o.batches) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.batch.code, style: theme.textTheme.titleLarge),
                    if (b.phase != null) Text(l10n.phase(b.phase!)),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text('${l10n.pondFish} :'),
                        EstimatedLabel(
                          value: formatCount(b.placement.live.count, locale),
                        ),
                      ],
                    ),
                    if (b.placement.avgWeightG != null)
                      Text(
                        '${l10n.avgWeight} : '
                        '${formatGrams(b.placement.avgWeightG!, locale)}',
                      ),
                    if (b.biomassG != null)
                      Wrap(
                        spacing: 8,
                        children: [
                          Text('${l10n.pondBiomass} :'),
                          EstimatedLabel(value: formatKg(b.biomassG!, locale)),
                        ],
                      ),
                    if (b.phase != null)
                      Text(_feedingGuide(l10n, b.phase!, locale)),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      onPressed: () => context.go(
                        '/transfer?batchId=${b.batch.id}&fromPondId=${pond.id}',
                      ),
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(l10n.pondTransfer),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            style: wide,
            onPressed: () => context.go('/stock?pondId=${pond.id}'),
            icon: const Icon(Icons.add),
            label: Text(l10n.pondStock),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () => context.go('/ponds/${pond.id}/edit'),
            icon: const Icon(Icons.edit),
            label: Text(l10n.edit),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => _archive(context, ref, pond.code),
            icon: const Icon(Icons.archive),
            label: Text(l10n.archive),
          ),
        ],
      ),
    );
  }

  String _feedingGuide(AppLocalizations l10n, Phase phase, Locale locale) {
    final g = feedingGuideFor(phase, DomainConfig.defaults);
    String n(num v) => formatNumber(v.toDouble(), locale);
    final protein = g.proteinPct == null
        ? l10n.adultFeed
        : '${n(g.proteinPct!.min)}–${n(g.proteinPct!.max)} %';
    final pellet = g.pelletMaxMm == null
        ? '≥ ${n(g.pelletMinMm)} mm'
        : g.pelletMaxMm == g.pelletMinMm
        ? '${n(g.pelletMinMm)} mm'
        : '${n(g.pelletMinMm)}–${n(g.pelletMaxMm!)} mm';
    final meals = '${g.feedingsPerDay.min} à ${g.feedingsPerDay.max}';
    return l10n.feedingGuide(protein, pellet, meals);
  }
}
