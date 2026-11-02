import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../db/repositories/providers.dart';
import '../../domain/report/report_content.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../common/farm_today.dart';
import '../common/save_once.dart';
import 'report_providers.dart';
import 'report_sections.dart';

/// A visit report: a draft to review and publish, or a published one to
/// read and share (SPEC F8).
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen.draft({super.key, required String this.visitId})
    : reportId = null;

  const ReportScreen.published({super.key, required String this.reportId})
    : visitId = null;

  final String? visitId;
  final String? reportId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> with SaveOnce {
  final _summary = TextEditingController();
  var _summaryLoaded = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final visitId = widget.visitId;
    if (visitId != null) {
      // Read once from the database: a cached list may predate the summary
      // saved as the visit ended.
      ref.read(visitRepositoryProvider).get(visitId).then((v) {
        if (mounted && !_summaryLoaded) {
          setState(() {
            _summary.text = v.summary ?? '';
            _summaryLoaded = true;
          });
        }
      });
    }
    final id = widget.reportId;
    if (id != null) {
      // Opening a report marks it read on this phone (plan Decision 7).
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(reportRepositoryProvider).markRead(id),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _summary.dispose();
    super.dispose();
  }

  String? get _summaryText {
    final t = _summary.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _saveSummary() async {
    _debounce?.cancel();
    // Never write over the saved summary before it has been read.
    if (!_summaryLoaded) return;
    await ref
        .read(visitRepositoryProvider)
        .setSummary(widget.visitId!, _summaryText);
  }

  Future<void> _publish(ReportContent draft) async {
    await _saveSummary();
    final id = await ref
        .read(reportRepositoryProvider)
        .publish(
          visitId: widget.visitId!,
          content: draft.publishedAs(
            summary: _summaryText,
            builtAt: ref.read(clockProvider)().toUtc(),
          ),
        );
    if (mounted) context.go('/reports/$id');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visitId = widget.visitId;
    final AsyncValue<ReportContent?> content = visitId != null
        ? ref.watch(draftReportProvider(visitId))
        : ref.watch(reportContentProvider(widget.reportId!));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportTitle)),
      body: switch (content) {
        AsyncData(value: null) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.reportUpdateApp, textAlign: TextAlign.center),
          ),
        ),
        AsyncData(value: final c?) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(content: c, draft: visitId != null),
            ReportSections(
              content: c,
              summary: visitId == null
                  ? null
                  : TextField(
                      controller: _summary,
                      maxLines: null,
                      minLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.reportSummary,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 600),
                          _saveSummary,
                        );
                      },
                    ),
            ),
          ],
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      // Always in reach: the member reviews, then publishes.
      bottomNavigationBar: switch ((visitId, content)) {
        (_?, AsyncData(value: final c?)) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: saving || !_summaryLoaded
                  ? null
                  : () => saveOnce(() => _publish(c)),
              icon: const Icon(Icons.send),
              label: Text(l10n.reportPublish),
            ),
          ),
        ),
        _ => null,
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.content, required this.draft});

  final ReportContent content;
  final bool draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final h = content.header;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.labelValue(h.siteName, formatDate(h.visitDay)),
          style: theme.textTheme.titleLarge,
        ),
        if (h.memberName.isNotEmpty)
          Text(
            h.groupName == null
                ? l10n.reportAuthor(h.memberName)
                : l10n.reportAuthorGroup(h.memberName, h.groupName!),
          ),
        Text(
          l10n.reportPeriod(formatDate(h.periodFrom), formatDate(h.periodTo)),
        ),
        if (!draft)
          Text(
            l10n.reportPublishedOn(formatDate(h.builtAt)),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}
