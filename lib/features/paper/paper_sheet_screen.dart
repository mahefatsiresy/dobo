import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/database.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/formatting.dart';
import '../common/farm_today.dart';
import '../common/choice_buttons.dart';
import '../common/pinned_action.dart';
import '../common/pond_choice.dart';
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
    final bytes = await buildPaperSheetPdfInBackground(
      ponds: [for (final p in ponds) PaperPond(code: p.code, colour: p.colour)],
      firstWeek: _monday,
      weeks: _weeks,
      fonts: await appPdfFontData(),
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
    final text = Theme.of(context).textTheme;
    final pondList = ref.watch(pondsProvider).value;
    if (pondList == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ponds = [...pondList]..sort((a, b) => a.code.compareTo(b.code));
    final chosen = ponds.where((p) => !_left.contains(p.id)).toList();
    final enabled = chosen.isNotEmpty && !saving;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.morePaper)),
      // The progress sits by the button just tapped, not at the list's foot.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (saving)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(l10n.exportBuilding),
                ],
              ),
            ),
          PinnedAction(
            icon: Icons.print,
            label: l10n.paperPrint,
            onPressed: enabled
                ? () => saveOnce(() => _build(chosen, print: true))
                : null,
          ),
        ],
      ),
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
                  style: text.titleMedium,
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
          ChoiceField<int>(
            label: l10n.paperWeeksLabel,
            options: [
              for (final n in const [1, 2, 3, 4]) (n, '$n'),
            ],
            value: _weeks,
            onChanged: (n) => setState(() => _weeks = n),
          ),
          const SizedBox(height: 16),
          Text(l10n.paperPondsLabel, style: text.titleMedium),
          const SizedBox(height: 8),
          if (ponds.isEmpty) Text(l10n.paperNoPonds),
          PondChoice(
            options: [for (final p in ponds) PondOption(pond: p)],
            value: null,
            onChanged: (_) {},
            multi: true,
            values: {for (final p in chosen) p.id},
            onChangedMany: (picked) => setState(() {
              _left
                ..clear()
                ..addAll(
                  ponds.map((p) => p.id).where((id) => !picked.contains(id)),
                );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.paperPages(
              l10n.paperPageCount(chosen.length * _weeks),
              l10n.paperPondCount(chosen.length),
              l10n.paperWeekCount(_weeks),
            ),
            style: text.titleMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.share),
            label: Text(l10n.paperShare),
            onPressed: enabled
                ? () => saveOnce(() => _build(chosen, print: false))
                : null,
          ),
        ],
      ),
    );
  }
}
