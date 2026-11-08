import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/repositories/providers.dart';
import '../../domain/dates.dart';
import '../../domain/exports/weekly.dart';
import '../../l10n/app_localizations.dart';
import '../common/date_field.dart';
import '../common/farm_today.dart';
import '../common/notice.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import '../reports/share_report.dart';
import 'csv.dart';
import 'export_pdf.dart';
import 'export_tables.dart';
import 'load_exports.dart';

enum ExportKind { register, weekly }

/// The handbook's production register and weekly sheet, as PDF or CSV,
/// for any dates and pond (SPEC F15).
class ExportsScreen extends ConsumerStatefulWidget {
  const ExportsScreen({super.key, this.from, this.to});

  /// Dates to open with; the kind's defaults when null.
  final DateTime? from;
  final DateTime? to;

  @override
  ConsumerState<ExportsScreen> createState() => _ExportsScreenState();
}

class _ExportsScreenState extends ConsumerState<ExportsScreen> with SaveOnce {
  var _kind = ExportKind.register;
  late DateTime _from;
  late DateTime _to;
  String? _pondId;

  @override
  void initState() {
    super.initState();
    _setDefaults();
    _from = widget.from ?? _from;
    _to = widget.to ?? _to;
  }

  /// The register covers the last 30 farm days, the weekly sheet the last
  /// 8 weeks (plan M8 Decision 10).
  void _setDefaults() {
    final today = ref.read(farmTodayProvider);
    _to = today;
    _from = switch (_kind) {
      ExportKind.register => DateTime(today.year, today.month, today.day - 29),
      ExportKind.weekly => DateTime(today.year, today.month, today.day - 49),
    };
  }

  Future<void> _export({required bool csv}) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final ExportTable table;
    final String name;
    switch (_kind) {
      case ExportKind.register:
        final (rows, names) = await loadRegister(
          ref,
          from: _from,
          to: _to,
          pondId: _pondId,
        );
        table = registerTable(rows, names, l10n, locale, from: _from, to: _to);
        name = exportFileName(
          'registre',
          names.site,
          _from,
          _to,
          csv ? 'csv' : 'pdf',
        );
      case ExportKind.weekly:
        final (rows, names) = await loadWeekly(
          ref,
          from: _from,
          to: _to,
          pondId: _pondId,
        );
        final (start, end) = wholeWeeks(_from, _to);
        table = weeklyTable(
          rows,
          names,
          ref.read(domainConfigProvider),
          l10n,
          locale,
          from: start,
          to: end,
        );
        name = exportFileName(
          'suivi-hebdo',
          names.site,
          start,
          end,
          csv ? 'csv' : 'pdf',
        );
    }
    if (csv) {
      await sharePdfFile(ref, name, utf8.encode(encodeCsv(csvRows(table))));
    } else {
      final fonts = await pdfFonts();
      final bytes = await buildExportPdf(
        table,
        regular: fonts.regular,
        bold: fonts.bold,
        symbols: fonts.symbols,
      );
      await sharePdfFile(ref, name, bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ponds = ref.watch(pondsProvider).value ?? const [];
    final backwards = daysBetween(_from, _to) < 0;
    final enabled = !backwards && !saving;
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreExports)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (kind, label) in [
                (ExportKind.register, l10n.exportKindRegister),
                (ExportKind.weekly, l10n.exportKindWeekly),
              ])
                ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  label: Text(label),
                  selected: _kind == kind,
                  onSelected: (_) => setState(() {
                    if (_kind == kind) return;
                    _kind = kind;
                    _setDefaults();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DateField(
            label: l10n.exportFrom,
            value: _from,
            onChanged: (d) => setState(() => _from = d),
          ),
          const SizedBox(height: 12),
          DateField(
            label: l10n.exportTo,
            value: _to,
            onChanged: (d) => setState(() => _to = d),
          ),
          if (_kind == ExportKind.weekly) ...[
            const SizedBox(height: 8),
            Text(l10n.exportWeeklyWholeWeeks),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: const ValueKey('exportPond'),
            initialValue: _pondId,
            decoration: InputDecoration(labelText: l10n.exportPond),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.exportAllPonds)),
              for (final p in ponds)
                DropdownMenuItem(value: p.id, child: Text(p.code)),
            ],
            onChanged: (v) => setState(() => _pondId = v),
          ),
          if (backwards) Notice(l10n.exportEndBeforeStart, danger: true),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: style,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(l10n.exportPdf),
            onPressed: enabled
                ? () => saveOnce(() => _export(csv: false))
                : null,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: style,
            icon: const Icon(Icons.table_chart),
            label: Text(l10n.exportCsv),
            onPressed: enabled
                ? () => saveOnce(() => _export(csv: true))
                : null,
          ),
        ],
      ),
    );
  }
}
