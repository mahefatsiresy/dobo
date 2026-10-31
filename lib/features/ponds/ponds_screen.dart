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
