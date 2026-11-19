import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../locale_controller.dart';
import '../../sync/sync_controller.dart';
import '../sync/sync_badge.dart';
import '../common/farm_today.dart';
import '../common/pond_colour.dart';
import '../ponds/pond_overview.dart';
import '../../domain/alerts/worker_advice.dart';
import '../alerts/alert_providers.dart';
import 'daily_log_providers.dart';
import 'stop_feeding_sign.dart';
import '../common/pictograms.dart';
import '../../theme/tokens.dart';

/// The worker's whole app (SPEC §6): today's ponds as big tiles, a tick on
/// those already logged. A worker account lands here and stays (a long
/// press on the title lets an admin take the phone back); a member reaches
/// it from More and leaves with the exit button.
class WorkerHomeScreen extends ConsumerWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overviews = ref.watch(pondOverviewsProvider).value;
    final logged = ref.watch(loggedTodayProvider).value ?? const {};
    final workerAccount = ref.watch(sessionProvider).value?.isWorker ?? false;
    // Today's ponds are those holding fish (SPEC F3); a count that doesn't
    // add up still has fish to feed.
    final fish = [
      for (final o in overviews ?? const <PondOverview>[])
        if (o.liveCount > 0 || o.inconsistent) o,
    ];
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          key: const Key('workerTakeover'),
          onLongPress: workerAccount
              ? () => context.push('/welcome/login?takeover=1')
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.workerToday),
              Text(
                formatDate(ref.watch(farmTodayProvider)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            key: const Key('workerSync'),
            tooltip: l10n.syncNow,
            iconSize: 32,
            icon: const SyncBadge(child: Icon(Icons.cloud_upload)),
            onPressed: () =>
                ref.read(syncControllerProvider.notifier).syncNow(),
          ),
          if (!workerAccount)
            IconButton(
              tooltip: l10n.workerExit,
              iconSize: 32,
              icon: const Icon(Icons.logout),
              onPressed: () {
                // The worker's last "saved" belongs to the tiles; on the
                // member's screens it would cover a form's Save.
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref
                    .read(localeControllerProvider.notifier)
                    .set(const Locale('fr'));
                context.go('/more');
              },
            ),
        ],
      ),
      body: overviews == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // The account's session ended: records wait on the phone
                // until the worker signs in again.
                if (ref.watch(syncControllerProvider).state ==
                    SyncRunState.signedOut)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: FilledButton.icon(
                      key: const Key('workerRelogin'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(64),
                      ),
                      icon: const Icon(Icons.login, size: 32),
                      label: Text(l10n.syncRelogin),
                      onPressed: () => context.push('/welcome/login?worker=1'),
                    ),
                  ),
                _Progress(fish: fish, logged: logged),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      for (final o in fish)
                        _PondTile(
                          key: ValueKey('tile-${o.pond.code}'),
                          overview: o,
                          stopFeeding: ref.watch(
                            stopFeedingProvider(o.pond.id),
                          ),
                          logged: logged.contains(o.pond.id),
                          onTap: () => context.push('/log/${o.pond.id}'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _PondTile extends StatelessWidget {
  const _PondTile({
    super.key,
    required this.overview,
    required this.stopFeeding,
    required this.logged,
    required this.onTap,
  });

  final PondOverview overview;

  /// Why not to feed today; the ration shows when empty.
  final Set<StopFeedingReason> stopFeeding;
  final bool logged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pond = overview.pond;
    final isolated = overview.status == PondStatus.isolated;
    final background = pondColourValue(pond.colour);
    final ink = background.computeLuminance() > 0.4
        ? Colors.black
        : Colors.white;
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isolated
            ? BorderSide(color: context.dobo.danger, width: 6)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pond.code,
                    style: Theme.of(context).textTheme.displayMedium
                        ?.copyWith(color: ink, fontWeight: FontWeight.bold),
                  ),
                  if (stopFeeding.isNotEmpty)
                    StopFeedingSign(reasons: stopFeeding)
                  else if (overview.rationG > 0)
                    // The ration to aim for: an instruction, not an estimate
                    // (docs/design.md §Step 3).
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(feedIcon, color: ink, size: 28),
                        const SizedBox(width: 6),
                        Text(
                          formatKg(
                            overview.rationG,
                            Localizations.localeOf(context),
                          ),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: ink,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  if (isolated)
                    Container(
                      color: context.dobo.danger,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        AppLocalizations.of(context).pondIsolatedBanner,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            if (logged)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.task_alt, color: context.dobo.ok, size: 44),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// How many of today's ponds are logged; one line with a tick once all
/// are, or a word when no pond holds fish.
class _Progress extends StatelessWidget {
  const _Progress({required this.fish, required this.logged});

  final List<PondOverview> fish;
  final Set<String> logged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme.titleMedium;
    if (fish.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.workerNoPonds, style: text),
      );
    }
    final done = fish.where((o) => logged.contains(o.pond.id)).length;
    final all = done == fish.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (all) ...[
            Icon(Icons.task_alt, color: context.dobo.ok, size: 32),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              all ? l10n.workerAllDone : l10n.workerProgress(done, fish.length),
              style: text,
            ),
          ),
        ],
      ),
    );
  }
}
