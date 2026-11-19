import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/types.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../../theme/tokens.dart';
import 'report_providers.dart';

/// Published reports, newest first, with my draft on top (SPEC F8,
/// docs/design.md §Step 6): ink rows, a dot while unread, dangers in words.
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.reportsEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView(
              children: [
                if (draft != null) ...[
                  _Row(
                    leading: const Icon(Icons.edit),
                    onTap: () => context.go('/reports/draft/${draft.id}'),
                    children: [
                      Text(
                        l10n.reportDraftRow(formatDate(visitDayOf(draft))),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                ],
                for (final r in reports) ...[
                  _ReportRow(reportId: r.id, unread: unread.contains(r.id)),
                  const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _ReportRow extends ConsumerWidget {
  const _ReportRow({required this.reportId, required this.unread});

  final String reportId;
  final bool unread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = context.dobo;
    final content = ref.watch(reportContentProvider(reportId)).value;
    final h = content?.header;
    final danger =
        content?.alerts.where((a) => a.severity == Severity.danger).length ?? 0;
    return _Row(
      // An ink dot while unread; the space stays so titles line up.
      leading: SizedBox(
        width: 24,
        child: unread
            ? Center(
                child: Container(
                  key: const ValueKey('unreadDot'),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
      onTap: () => context.go('/reports/$reportId'),
      children: [
        Text(
          h == null
              ? l10n.reportTitle
              : l10n.reportCardTitle(formatDate(h.visitDay), h.memberName),
          style: text.titleMedium?.copyWith(
            fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        if (h == null && content == null)
          Text(l10n.reportUpdateApp, style: text.bodySmall)
        else if (h != null)
          Text(
            l10n.reportPeriod(formatDate(h.periodFrom), formatDate(h.periodTo)),
            style: text.bodySmall,
          ),
        if (danger > 0)
          Row(
            children: [
              Icon(Icons.error, size: 18, color: c.danger),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.reportDangerCount(danger),
                  style: text.bodyMedium?.copyWith(
                    color: c.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// A list row: [leading], then [children] stacked, then a chevron; at
/// least 56 dp tall, the whole row one tap target.
class _Row extends StatelessWidget {
  const _Row({
    required this.leading,
    required this.onTap,
    required this.children,
  });

  final Widget leading;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
