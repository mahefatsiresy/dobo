import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import 'report_providers.dart';
import '../../theme/tokens.dart';

/// Published reports, newest first, with my draft on top (SPEC F8).
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(draftVisitProvider);
    final reports = ref.watch(reportsProvider).value ?? const [];
    final unread = ref.watch(unreadReportIdsProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabReports)),
      body: draft == null && reports.isEmpty
          ? Center(child: Text(l10n.reportsEmpty))
          : ListView(
              children: [
                if (draft != null)
                  Card(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      minTileHeight: 56,
                      leading: const Icon(Icons.edit_note),
                      title: Text(l10n.reportDraft),
                      subtitle: Text(formatDate(visitDayOf(draft))),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/reports/draft/${draft.id}'),
                    ),
                  ),
                for (final r in reports)
                  _ReportCard(reportId: r.id, unread: unread.contains(r.id)),
              ],
            ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.reportId, required this.unread});

  final String reportId;
  final bool unread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(reportContentProvider(reportId)).value;
    final h = content?.header;
    final danger =
        content?.alerts.where((a) => a.severity == Severity.danger).length ?? 0;
    return ListTile(
      minTileHeight: 56,
      leading: Icon(
        unread ? Icons.mark_email_unread : Icons.description,
        color: unread ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        h == null
            ? l10n.reportTitle
            : l10n.reportCardTitle(formatDate(h.visitDay), h.memberName),
        style: unread ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
      subtitle: h == null
          ? (content == null ? Text(l10n.reportUpdateApp) : null)
          : Text(
              l10n.reportPeriod(
                formatDate(h.periodFrom),
                formatDate(h.periodTo),
              ),
            ),
      trailing: danger == 0
          ? null
          : Chip(
              avatar: Icon(Icons.error, color: context.dobo.danger, size: 18),
              label: Text('$danger'),
            ),
      onTap: () => context.go('/reports/$reportId'),
    );
  }
}
