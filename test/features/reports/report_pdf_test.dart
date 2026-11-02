import 'dart:io';
import 'dart:typed_data';

import 'package:dobo/domain/dates.dart';
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
  final regular = font('NotoSans-Regular.ttf');
  final bold = font('NotoSans-Bold.ttf');

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
      photoBytes: (key) async {
        asked.add(key);
        if (key == 'broken') throw const FileSystemException('gone');
        return null;
      },
    );
    expect(asked, containsAll(['missing', 'broken', 'k1', 'k2']));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('a 40-pond report spans pages without error', () async {
    final bytes = await buildReportPdf(
      full(ponds: 40),
      l10n,
      const Locale('fr'),
      regular: regular,
      bold: bold,
    );
    expect(await pages(bytes), greaterThan(1));
  });
}
