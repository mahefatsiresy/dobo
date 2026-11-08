import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../common/farm_today.dart';
import '../common/pond_colour.dart';
import '../common/save_once.dart';
import '../ponds/pond_overview.dart';
import '../reports/share_report.dart';
import '../transcription/week.dart';
import 'paper_sheet_pdf.dart';
import 'print_pdf.dart';

/// Blank worker sheets to print or share (SPEC F13).
class PaperSheetScreen extends ConsumerStatefulWidget {
  const PaperSheetScreen({super.key});

  @override
  ConsumerState<PaperSheetScreen> createState() => _PaperSheetScreenState();
}

class _PaperSheetScreenState extends ConsumerState<PaperSheetScreen>
    with SaveOnce {
  late DateTime _monday = weekOf(ref.read(farmTodayProvider)).first;
  var _weeks = 1;

  /// Ponds unticked; a pond added meanwhile starts ticked.
  final _left = <String>{};

  void _moveWeek(int by) => setState(
    () => _monday = DateTime(_monday.year, _monday.month, _monday.day + 7 * by),
  );

  Future<void> _build(List<Pond> ponds, {required bool print}) async {
    final (regular, bold) = await pdfFonts();
    final bytes = await buildPaperSheetPdf(
      ponds: [
        for (final p in ponds)
          if (!_left.contains(p.id)) PaperPond(code: p.code, colour: p.colour),
      ],
      firstWeek: _monday,
      weeks: _weeks,
      regular: regular,
      bold: bold,
    );
    final name = paperFileName(_monday);
    if (print) {
      await ref.read(pdfPrinterProvider)(name, bytes);
    } else {
      await sharePdfFile(ref, name, bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ponds = ref.watch(pondsProvider).value;
    if (ponds == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final chosen = ponds.where((p) => !_left.contains(p.id)).toList();
    final enabled = chosen.isNotEmpty && !saving;
    final buttonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.morePaper)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.previousWeek,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _moveWeek(-1),
              ),
              Expanded(
                child: Text(
                  l10n.weekOfLabel(formatDate(_monday)),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.nextWeek,
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _moveWeek(1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.paperWeeksLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final n in const [1, 2, 4])
                ChoiceChip(
                  key: ValueKey('paperWeeks-$n'),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  label: Text('$n'),
                  selected: _weeks == n,
                  onSelected: (_) => setState(() => _weeks = n),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.paperPondsLabel),
          const SizedBox(height: 8),
          if (ponds.isEmpty) Text(l10n.paperNoPonds),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ponds)
                FilterChip(
                  key: ValueKey('paperPond-${p.code}'),
                  label: PondBadge(code: p.code, colour: p.colour),
                  selected: !_left.contains(p.id),
                  onSelected: (on) => setState(
                    () => on ? _left.remove(p.id) : _left.add(p.id),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: buttonStyle,
            icon: const Icon(Icons.print),
            label: Text(l10n.paperPrint),
            onPressed: enabled
                ? () => saveOnce(() => _build(ponds, print: true))
                : null,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: buttonStyle,
            icon: const Icon(Icons.share),
            label: Text(l10n.paperShare),
            onPressed: enabled
                ? () => saveOnce(() => _build(ponds, print: false))
                : null,
          ),
        ],
      ),
    );
  }
}
