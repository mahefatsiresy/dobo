import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../l10n/app_localizations.dart';
import '../../sync/providers.dart';
import '../../sync/sync_controller.dart';
import '../../sync/sync_status_repository.dart';
import '../../l10n/formatting.dart';
import '../common/attention_band.dart';
import '../common/folded_section.dart';
import '../common/pinned_action.dart';
import 'backup_actions.dart';
import '../../theme/tokens.dart';

/// This phone's photos marked to send and not sent yet.
final _pendingPhotosProvider = StreamProvider<List<(String, String?)>>(
  (ref) => ref.watch(photoRepositoryProvider).watchPendingUploads(),
);
final _rejectedProvider = StreamProvider<List<RejectedRow>>(
  (ref) => ref.watch(syncStatusRepositoryProvider).watchRejected(),
);

final lastSyncProvider = StreamProvider<DateTime?>(
  (ref) => ref.watch(syncStatusRepositoryProvider).watchLastSyncAt(),
);

/// Sync status (SPEC §7): last sync, what waits, what was refused and why.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(syncControllerProvider);
    final sync = ref.read(syncControllerProvider.notifier);
    final counts =
        ref.watch(syncCountsProvider).value ?? (pending: 0, rejected: 0);
    final photos = ref.watch(_pendingPhotosProvider).value ?? const [];
    final rejected = ref.watch(_rejectedProvider).value ?? const [];
    final last = ref.watch(lastSyncProvider).value;
    final worker = ref.watch(sessionProvider).value?.isWorker ?? false;
    final status = switch (view.state) {
      SyncRunState.running => l10n.syncStateRunning,
      SyncRunState.offline => l10n.syncStateOffline,
      SyncRunState.signedOut => l10n.syncStateSignedOut,
      SyncRunState.unlinked => l10n.syncStateUnlinked,
      SyncRunState.notConfigured => l10n.syncStateNotConfigured,
      SyncRunState.failed => l10n.syncStateFailed(view.error ?? ''),
      SyncRunState.idle => null,
    };
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    Widget band(BandSeverity severity, String words) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AttentionBand(severity: severity, text: words),
    );
    Widget outlined(String label, IconData icon, VoidCallback onPressed) =>
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton.icon(
            icon: Icon(icon),
            label: Text(label),
            onPressed: onPressed,
          ),
        );
    final running = view.state == SyncRunState.running;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreSync)),
      bottomNavigationBar: PinnedAction(
        icon: Icons.sync,
        label: l10n.syncNow,
        onPressed: running ? null : sync.syncNow,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // The state first (docs/design.md §Step 7b).
          if (counts.rejected > 0)
            band(BandSeverity.danger, l10n.syncRejectedCount(counts.rejected)),
          if (status != null && !running) band(BandSeverity.warning, status),
          if (running)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(status ?? '', style: text.bodyLarge)),
                ],
              ),
            ),
          Text(
            last == null
                ? l10n.syncNever
                : l10n.syncLast(
                    '${formatDate(last)} '
                    '${DateFormat('HH:mm').format(last.toUtc().add(farmUtcOffset))}',
                  ),
            style: text.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(l10n.syncPending(counts.pending)),
          if (photos.isNotEmpty) Text(l10n.syncPhotosWaiting(photos.length)),
          if (photos.any((p) => p.$2 == 'cap')) ...[
            const SizedBox(height: 8),
            band(BandSeverity.warning, l10n.syncPhotoCap),
          ],
          for (final r in rejected) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.block, color: c.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tableLabel(l10n, r.table)}, '
                        '${formatDate(r.recordedOrUpdatedAt)}',
                        style: text.titleSmall,
                      ),
                      Text(switch (r.errorCode) {
                        '42501' => l10n.rejectRole,
                        'P0001' when r.errorMessage == 'last_admin' =>
                          l10n.rejectLastAdmin,
                        _ => l10n.rejectOther(
                          '${r.errorCode} ${r.errorMessage}',
                        ),
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (counts.rejected > 0)
            outlined(l10n.syncRetry, Icons.replay, sync.retryRejected),
          if (view.state == SyncRunState.signedOut)
            outlined(
              l10n.syncRelogin,
              Icons.login,
              () => context.push(
                worker ? '/welcome/login?worker=1' : '/welcome/login',
              ),
            ),
          const SizedBox(height: 16),
          Divider(height: 1, color: c.line),
          FoldedSection(
            title: l10n.backupSection,
            summary: l10n.backupSummary,
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: Text(l10n.backupExport),
                  onPressed: () => exportAndShare(ref),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.restore),
                  label: Text(l10n.backupImport),
                  onPressed: () => pickAndImport(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A synced table's name, for people.
String tableLabel(AppLocalizations l10n, String table) => switch (table) {
  'daily_logs' => l10n.tableDailyLogs,
  'water_readings' => l10n.tableWaterReadings,
  'samples' => l10n.tableSamples,
  'observations' => l10n.tableObservations,
  'health_events' => l10n.tableHealthEvents,
  'treatments' => l10n.tableTreatments,
  'stockings' => l10n.tableStockings,
  'transfers' => l10n.tableTransfers,
  'ponds' => l10n.tablePonds,
  'batches' => l10n.tableBatches,
  'people' => l10n.tablePeople,
  'sites' => l10n.tableSites,
  'visits' => l10n.tableVisits,
  'groups' => l10n.tableGroups,
  'members' => l10n.tableMembers,
  'setting_overrides' => l10n.tableSettingOverrides,
  _ => table,
};
