import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/fcr.dart';
import 'package:dobo/domain/trace.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/sales/trace_pdf.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  DateTime d(int month, int day) => farmDateToUtc(DateTime(2026, month, day));
  final l10n = lookupAppLocalizations(const Locale('fr'));
  const fr = Locale('fr');
  pw.Font font(String name) => pw.Font.ttf(
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()),
  );

  BatchTraceView closed() => BatchTraceView(
    code: 'L26-01',
    strain: 'GIFT',
    hatchery: 'Ferme Soa',
    certificateNo: 'C-123',
    monosex: true,
    stockedOn: d(3, 1),
    stockedAvgWeightG: 20,
    trace: const BatchTrace(
      stockedCount: 1000,
      stockedWeightG: 20000,
      harvestedCount: 950,
      harvestedWeightG: 250000,
      unaccounted: 50,
      live: 0,
      survival: 0.95,
      cycleFcr: FcrValue(400 / 230),
      batchFeedG: 400000,
    ),
    moves: [
      TraceMove(at: d(3, 1), toPond: 'E1', count: 1000, avgWeightG: 20),
      TraceMove(at: d(4, 1), fromPond: 'E1', toPond: 'E2', count: 400),
    ],
    treatments: [
      TraceTreatment(
        at: d(4, 10),
        pond: 'E2',
        product: 'Sel',
        dose: '3 g/L',
        advisedBy: 'Technicien',
      ),
    ],
    harvests: [
      TraceHarvest(
        at: d(7, 1),
        pond: 'E1',
        count: 950,
        weightG: 250000,
        isFinal: true,
        sales: [
          TraceSale(
            at: d(7, 1),
            customer: 'Marché Antsirabe',
            form: ProductForm.fresh,
            weightG: 200000,
          ),
        ],
      ),
    ],
  );

  List<String> textOf(BatchTraceView v) => [
    for (final s in traceSections(v, l10n, fr)) ...[s.heading, ...s.lines],
  ];

  test("a closed batch's sheet has its cycle FCR, harvests and customers", () {
    final text = textOf(closed());
    expect(text, contains('Lot L26-01'));
    expect(text, contains('IC du cycle : 1,74 (estimé)'));
    expect(text, contains('Survie : 95 %'));
    expect(text, contains('Poissons non retrouvés : 50'));
    expect(
      text.any((t) => t.contains('Marché Antsirabe · Frais · 200 kg')),
      isTrue,
    );
    expect(text.any((t) => t.contains('Sel, 3 g/L')), isTrue);
    expect(text.any((t) => t.contains('E1 → E2')), isTrue);
  });

  test('an open batch with no harvest says cycle en cours', () {
    final text = textOf(
      const BatchTraceView(
        code: 'L26-02',
        trace: BatchTrace(
          stockedCount: 500,
          stockedWeightG: 7500,
          harvestedCount: 0,
          harvestedWeightG: 0,
          unaccounted: 0,
          live: 500,
          survival: 1,
          cycleFcr: null,
          batchFeedG: 0,
        ),
      ),
    );
    expect(text, contains('IC du cycle : cycle en cours'));
    expect(text, contains('Rien à signaler'));
  });

  test('both sheets build as PDF', () async {
    for (final v in [
      closed(),
      const BatchTraceView(
        code: 'L26-02',
        trace: BatchTrace(
          stockedCount: 0,
          stockedWeightG: 0,
          harvestedCount: 0,
          harvestedWeightG: 0,
          unaccounted: 0,
          live: 0,
          survival: null,
          cycleFcr: null,
          batchFeedG: 0,
        ),
      ),
    ]) {
      final bytes = await buildTracePdf(
        v,
        l10n,
        fr,
        regular: font('NotoSans-Regular.ttf'),
        bold: font('NotoSans-Bold.ttf'),
        symbols: font('NotoSansMath-Symbols.ttf'),
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    }
  });

  test('the file is tracabilite-<code>-<day>.pdf', () {
    expect(
      traceFileName('L26-01', DateTime(2026, 7, 2)),
      'tracabilite-L26-01-2026-07-02.pdf',
    );
  });
}
