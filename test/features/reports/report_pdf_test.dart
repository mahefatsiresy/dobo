import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/feed_stock.dart';
import 'package:dobo/domain/growth.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/reports/report_pdf.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));
  final l10n = lookupAppLocalizations(const Locale('fr'));
  pw.Font font(String name) => pw.Font.ttf(
    ByteData.sublistView(File('assets/fonts/$name').readAsBytesSync()),
  );
  final regular = font('AtkinsonHyperlegibleNext-Regular.ttf');
  final bold = font('AtkinsonHyperlegibleNext-Bold.ttf');
  final fallback = [
    font('NotoSans-Regular.ttf'),
    font('NotoSansMath-Symbols.ttf'),
  ];

  ReportHeader header() => ReportHeader(
    siteName: 'Ambohidratrimo',
    visitDay: d(20),
    memberName: 'Hery',
    groupName: 'Rabe',
    periodFrom: d(13),
    periodTo: d(20),
    builtAt: d(20),
  );

  ReportContent full({int ponds = 2}) => ReportContent(
    header: header(),
    summary: 'Digue à reprendre, O₂ bas le matin.',
    pondCodes: {for (var i = 1; i <= ponds; i++) 'e$i': 'E$i'},
    batchCodes: const {'l1': 'L1'},
    health: [
      for (var i = 1; i <= ponds; i++)
        PondHealth(
          pondId: 'e$i',
          deaths: 6,
          byObserver: const [
            ObserverDeaths(name: 'Rakoto', deaths: 4),
            ObserverDeaths(name: null, deaths: 2),
          ],
          events: [
            HealthLine(
              at: d(15),
              signs: const {WarningSign.rubbing},
              actions: const {HealthAction.isolated},
              photoKeys: const ['missing', 'broken'],
            ),
          ],
        ),
    ],
    water: [
      for (var i = 1; i <= ponds; i++)
        PondWater(pondId: 'e$i', at: d(19), ph: 7.2, oxygenMgL: 2.5),
    ],
    growth: [
      for (var i = 1; i <= ponds; i++)
        BatchGrowth(
          batchId: 'l1',
          pondId: 'e$i',
          avgWeightG: 30,
          weighedOn: d(15),
          liveCount: 990,
          biomassG: 29700,
          fcr: 1.6,
          trend: FcrTrend.worse,
          survival: 0.99,
        ),
    ],
    feed: [for (var i = 1; i <= ponds; i++) PondFeed(pondId: 'e$i', feedG: 1)],
    feedTotalG: ponds,
    observations: const [
      ReportObservation(
        pondId: 'e1',
        category: ObservationCategory.dike,
        ok: false,
        note: 'Fuite',
        photoKeys: ['k1'],
      ),
    ],
    visitPhotoKeys: const ['k2'],
  );

  Future<int> pages(Uint8List bytes) async =>
      RegExp(r'/Type\s*/Page[^s]')
          .allMatches(String.fromCharCodes(bytes))
          .length;

  test('builds a full report', () async {
    final bytes = await buildReportPdf(
      full(),
      l10n,
      const Locale('fr'),
      regular: regular,
      bold: bold,
      fallback: fallback,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(await pages(bytes), greaterThanOrEqualTo(1));
  });

  test('builds an empty report', () async {
    final bytes = await buildReportPdf(
      ReportContent(header: header()),
      l10n,
      const Locale('fr'),
      regular: regular,
      bold: bold,
      fallback: fallback,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('a missing photo is skipped, not thrown', () async {
    final asked = <String>[];
    final bytes = await buildReportPdf(
      full(),
      l10n,
      const Locale('fr'),
      regular: regular,
      bold: bold,
      fallback: fallback,
      photoBytes: (key) async {
        asked.add(key);
        if (key == 'broken') throw const FileSystemException('gone');
        return null;
      },
    );
    expect(asked, containsAll(['missing', 'broken', 'k1', 'k2']));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('a report with feed stock and prep dates builds', () async {
    final bytes = await buildReportPdf(
      ReportContent(
        header: header(),
        pondCodes: const {'e2': 'E2'},
        feedStock: FeedStockSection(
          onHandG: 44000,
          daysLeft: 7.4,
          overdrawnG: 3000,
          lots: [
            FeedLotLine(
              phase: Phase.growout,
              manufacturedOn: d(1),
              balanceG: 44000,
              age: FeedAge.expired,
            ),
          ],
        ),
        next: [
          NextItem(
            kind: NextKind.prepStep,
            date: d(23),
            pondId: 'e2',
            step: PrepStep.rest,
          ),
        ],
      ),
      l10n,
      const Locale('fr'),
      regular: regular,
      bold: bold,
      fallback: fallback,
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('a 40-pond report spans pages without error', () async {
    final bytes = await buildReportPdf(
      full(ponds: 40),
      l10n,
      const Locale('fr'),
      regular: regular,
      bold: bold,
      fallback: fallback,
    );
    expect(await pages(bytes), greaterThan(1));
  });

  /// The PDF's text, page by page, as `pdftotext -layout` reads it; null
  /// where poppler isn't installed.
  Future<List<String>?> text(Uint8List bytes) async {
    final which = await Process.run('which', ['pdftotext']);
    if (which.exitCode != 0) return null;
    final dir = await Directory.systemTemp.createTemp('report_pdf');
    addTearDown(() => dir.delete(recursive: true));
    final pdf = File('${dir.path}/r.pdf')..writeAsBytesSync(bytes);
    final out = await Process.run('pdftotext', ['-layout', pdf.path, '-']);
    return (out.stdout as String).split('\f')
      ..removeWhere((p) => p.trim().isEmpty);
  }

  Future<Uint8List> build(
    ReportContent c, {
    Map<String, PondColour>? colours,
  }) => buildReportPdf(
    c,
    l10n,
    const Locale('fr'),
    regular: regular,
    bold: bold,
    fallback: fallback,
    pondColours: colours ?? const {},
  );

  test(
    'sections in F8 order; the worst health first; estimates say so',
    () async {
      final c = full();
      final pagesText = await text(
        await build(
          ReportContent(
            header: c.header,
            summary: c.summary,
            pondCodes: const {'e2': 'E2', 'e5': 'E5'},
            batchCodes: c.batchCodes,
            health: [
              const PondHealth(pondId: 'e5', deaths: 500),
              PondHealth(
                pondId: 'e2',
                deaths: 1,
                events: [
                  HealthLine(at: d(15), actions: const {HealthAction.isolated}),
                ],
              ),
            ],
            water: c.water,
            growth: [
              BatchGrowth(
                batchId: 'l1',
                pondId: 'e2',
                avgWeightG: 30,
                weighedOn: d(15),
                liveCount: 990,
                biomassG: 29700,
                fcr: 1.6,
                survival: 0.99,
              ),
            ],
            feed: c.feed,
            feedTotalG: c.feedTotalG,
            observations: c.observations,
          ),
          colours: const {'e2': PondColour.yellow},
        ),
      );
      if (pagesText == null) return markTestSkipped('pdftotext not installed');
      final all = pagesText.join('\n');
      final at = [
        for (final h in const [
          'Résumé',
          'Alertes',
          'Santé',
          'Eau',
          'Croissance',
          'Aliment',
          'À venir',
          'Observations et photos',
        ])
          all.indexOf(RegExp('^\\s*$h\\s*\$', multiLine: true)),
      ];
      expect(at.every((i) => i >= 0), isTrue, reason: '$at\n$all');
      expect(at, [...at]..sort());
      final health = all.substring(at[2], at[3]);
      expect(health.indexOf('E2'), lessThan(health.indexOf('E5')));
      expect(all, contains('29,7 kg (estimé)'));
    },
  );

  test('every page ends with the footer', () async {
    final pagesText = await text(await build(full(ponds: 40)));
    if (pagesText == null) return markTestSkipped('pdftotext not installed');
    expect(pagesText.length, greaterThan(1));
    for (final (i, page) in pagesText.indexed) {
      expect(
        page.trim().split('\n').last.trim(),
        'Dobo · Ambohidratrimo · 20/03/2026 · ${i + 1}/${pagesText.length}',
      );
    }
  });

  test('the report is set in Atkinson Hyperlegible Next', () async {
    final bytes = await build(full());
    expect(String.fromCharCodes(bytes), contains('AtkinsonHyperlegibleNext'));
  });

  test('a pond with no known colour builds', () async {
    final bytes = await build(full(), colours: const {'e2': PondColour.red});
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('a long pond code never runs into its line', () async {
    if ((await Process.run('which', ['pdftotext'])).exitCode != 0) {
      return markTestSkipped('pdftotext not installed');
    }
    final bytes = await build(
      ReportContent(
        header: header(),
        pondCodes: const {'b3': 'BASSIN-NORD-3'},
        feed: const [PondFeed(pondId: 'b3', feedG: 37500)],
        feedTotalG: 37500,
      ),
      colours: const {'b3': PondColour.green},
    );
    final dir = await Directory.systemTemp.createTemp('report_pdf');
    addTearDown(() => dir.delete(recursive: true));
    final pdf = File('${dir.path}/r.pdf')..writeAsBytesSync(bytes);
    final html = File('${dir.path}/r.html');
    await Process.run('pdftotext', ['-bbox', pdf.path, html.path]);
    // Each word: <word xMin=".." yMin=".." xMax=".." yMax="..">text</word>
    final words = [
      for (final m in RegExp(
        r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="[\d.]+">([^<]*)</word>',
      ).allMatches(html.readAsStringSync()))
        (
          xMin: double.parse(m[1]!),
          y: double.parse(m[2]!),
          xMax: double.parse(m[3]!),
          text: m[4]!,
        ),
    ];
    final code = words.firstWhere((w) => w.text.contains('BASSIN'));
    // The feed row's kilos: the "37,5" nearest the code's line.
    final kg =
        (words.where((w) => w.text == '37,5').toList()..sort(
              (a, b) => (a.y - code.y).abs().compareTo((b.y - code.y).abs()),
            ))
            .first;
    expect(code.xMax, lessThanOrEqualTo(kg.xMin));
  });
}
