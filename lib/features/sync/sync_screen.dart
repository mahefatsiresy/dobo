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
import 'backup_actions.dart';
import '../../theme/tokens.dart';

/// This phone's photos marked to send and not sent yet.
final _pendingPhotosProvider = StreamProvider<List<(String, String?)>>(
  (ref) => ref.watch(photoRepositoryProvider).watchPendingUploads(),
);
final _rejectedProvider = StreamProvider<List<RejectedRow>>(
  (ref) => ref.watch(syncStatusRepositoryProvider).watchRejected(),
);

final _lastSyncProvider = StreamProvider<DateTime?>(
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
    final last = ref.watch(_lastSyncProvider).value;
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
    Widget button(String label, IconData icon, VoidCallback? onPressed) =>
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: Icon(icon),
            label: Text(label),
            onPressed: onPressed,
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreSync)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            last == null
                ? l10n.syncNever
                : l10n.syncLast(
                    '${formatDate(last)} '
                    '${DateFormat('HH:mm').format(last.toUtc().add(farmUtcOffset))}',
                  ),
          ),
          const SizedBox(height: 8),
          Text(l10n.syncPending(counts.pending)),
          Text(l10n.syncRejectedCount(counts.rejected)),
          if (photos.isNotEmpty) ...[
            Text(l10n.syncPhotosWaiting(photos.length)),
            if (photos.any((p) => p.$2 == 'cap'))
              Text(
                l10n.syncPhotoCap,
                style: TextStyle(color: context.dobo.danger),
              ),
          ],
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(status, style: Theme.of(context).textTheme.titleSmall),
          ],
          button(
            l10n.syncNow,
            Icons.sync,
            view.state == SyncRunState.running ? null : sync.syncNow,
          ),
          if (counts.rejected > 0)
            button(l10n.syncRetry, Icons.replay, sync.retryRejected),
          if (view.state == SyncRunState.signedOut)
            button(
              l10n.syncRelogin,
              Icons.login,
              () => context.push(
                worker ? '/welcome/login?worker=1' : '/welcome/login',
              ),
            ),
          const Divider(height: 32),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.save_alt),
            label: Text(l10n.backupExport),
            onPressed: () => exportAndShare(ref),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.restore),
            label: Text(l10n.backupImport),
            onPressed: () => pickAndImport(context, ref),
          ),
          for (final r in rejected)
            ListTile(
              leading: Icon(
                Icons.block,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '${tableLabel(l10n, r.table)} · '
                '${formatDate(r.recordedOrUpdatedAt)}',
              ),
              subtitle: Text(switch (r.errorCode) {
                '42501' => l10n.rejectRole,
                'P0001' when r.errorMessage == 'last_admin' =>
                  l10n.rejectLastAdmin,
                _ => l10n.rejectOther('${r.errorCode} ${r.errorMessage}'),
              }),
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
