import 'package:dobo/domain/config.dart';
import 'package:dobo/domain/dates.dart';
import 'package:dobo/domain/exports/register.dart';
import 'package:dobo/domain/exports/weekly.dart';
import 'package:dobo/domain/farm_facts.dart';
import 'package:dobo/domain/occupancy.dart';
import 'package:dobo/domain/report/report_content.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/exports/export_tables.dart';
import 'package:dobo/l10n/app_localizations.dart';
import 'package:dobo/l10n/formatting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));
  const fr = Locale('fr');
  DateTime d(int day) => farmDateToUtc(DateTime(2026, 3, day));
  final from = DateTime(2026, 3, 1);
  final to = DateTime(2026, 3, 31);
  const names = ExportNames(
    site: 'Ferme Soa',
    ponds: {'e1': 'E1', 'e2': 'E2'},
    batches: {'b1': 'L26-01', 'b2': 'L26-02'},
    origins: {
      'b1': BatchOrigin(hatchery: 'Station Ivato', certificateNo: 'C-9'),
    },
    customers: {'c1': 'Marché Antsirabe'},
  );

  List<String> only(RegisterRow r) =>
      registerTable([r], names, l10n, fr, from: from, to: to).rows.single;

  test('a log row has its pond, batch, feed, deaths and observations', () {
    final row = only(
      LogRow(
        LogFact(
          id: 'l',
          pondId: 'e1',
          date: d(12),
          feedG: 12500,
          deaths: 3,
          signs: const {WarningSign.surfaceSwimming},
          waterColour: WaterColour.darkGreen,
          note: 'Digue fuit',
        ),
        const ['b1'],
      ),
    );
    expect(row, [
      '12/03/2026',
      'E1 / L26-01',
      '',
      '12,5',
      '3',
      '',
      "Nage en surface · Couleur de l'eau : Vert foncé · Digue fuit",
    ]);
  });

  test('zero deaths print blank', () {
    final row = only(
      LogRow(
        LogFact(id: 'l', pondId: 'e1', date: d(12), feedG: 2000),
        const [],
      ),
    );
    expect(row.sublist(1, 5), ['E1', '', '2', '']);
  });

  test('a stocking row carries the hatchery and certificate', () {
    final row = only(
      StockingRow(
        StockingFact(
          batchId: 'b1',
          pondId: 'e1',
          count: 1000,
          avgWeightG: 20,
          date: d(1),
        ),
      ),
    );
    expect(row[2], 'Station Ivato · N° de certificat sanitaire : C-9');
    expect(row[6], 'Empoissonnement : ${formatCount(1000, fr)} × 20 g');
  });

  test('a transfer row names both ponds', () {
    final row = only(
      TransferRow(
        TransferFact(
          batchId: 'b1',
          fromPondId: 'e1',
          toPondId: 'e2',
          count: 400,
          avgWeightG: 85,
          date: d(5),
        ),
      ),
    );
    expect(row[1], 'E1 → E2 / L26-01');
    expect(row[6], 'Transfert : 400 × 85 g');
  });

  test('a harvest row says final or partial with its fish and weight', () {
    final row = only(
      HarvestRow(
        HarvestFact(
          batchId: 'b1',
          pondId: 'e2',
          count: 950,
          weightG: 240000,
          isFinal: true,
          date: d(20),
        ),
      ),
    );
    expect(row[6], 'Récolte finale : 950 poissons · 240 kg');
  });

  test('a sale row has its kg under Ventes and the customer and form under '
      'Observations', () {
    final row = only(
      SaleRow(
        SaleFact(
          date: d(20),
          batchId: 'b1',
          pondId: 'e2',
          weightG: 80500,
          customerId: 'c1',
          form: ProductForm.fresh,
        ),
      ),
    );
    expect(row[5], '80,5');
    expect(row[6], startsWith('Marché Antsirabe · '));
  });

  test('treatment and health rows', () {
    final treatment = only(
      TreatmentRow(
        'e1',
        TreatmentLine(
          at: d(8),
          product: 'Sel',
          dose: '3 g/L',
          advisedBy: 'Technicien',
        ),
        const ['b1'],
      ),
    );
    expect(treatment[6], 'Traitement : Sel, 3 g/L · conseillé par Technicien');
    final health = only(
      HealthRow(
        'e1',
        HealthLine(
          at: d(7),
          suspectedIssue: 'Parasites',
          signs: const {WarningSign.whiteSpots},
          actions: const {HealthAction.isolated},
        ),
        const [],
      ),
    );
    expect(health[6], 'Problème signalé : Parasites · Points blancs · isolé');
  });

  test('the register has the handbook columns, a title and a period', () {
    final t = registerTable(const [], names, l10n, fr, from: from, to: to);
    expect(t.header, [
      'Date',
      'Étang / Lot',
      'Provenance alevins',
      'Quantité aliment (kg)',
      'Mortalité (nb)',
      'Ventes (kg)',
      'Observations',
    ]);
    expect(t.title, 'Registre de production');
    expect(t.period, 'Ferme Soa · Du 01/03/2026 au 31/03/2026');
    expect(t.rows, isEmpty);
    expect(csvRows(t), [t.header]);
  });

  test('weekly rows print their values, and two batches by code', () {
    final t = weeklyTable(
      [
        WeeklyRow(
          pondId: 'e1',
          weekStart: DateTime(2026, 3, 2),
          temperatureC: 26.5,
          ph: 7.2,
          oxygenMgL: 4,
          feedG: 21000,
          deaths: 0,
          loggedDays: 7,
          avgWeightGByBatch: const {'b1': 45, 'b2': 120},
        ),
        WeeklyRow(
          pondId: 'e1',
          weekStart: DateTime(2026, 3, 9),
          avgWeightGByBatch: const {'b1': 50.25},
        ),
      ],
      names,
      DomainConfig.defaults,
      l10n,
      fr,
      from: DateTime(2026, 3, 2),
      to: DateTime(2026, 3, 15),
    );
    expect(t.header.first, 'Étang');
    expect(t.rows[0], [
      'E1',
      '02/03/2026',
      '26,5',
      '7,2',
      '4',
      '21',
      '0',
      'L26-01 : 45 g ; L26-02 : 120 g',
    ]);
    // No log that week: feed and deaths are unknown, not zero.
    expect(t.rows[1], ['E1', '09/03/2026', '', '', '', '', '', '50,3']);
  });

  test('the weekly footer says oxygène ≥ 3 mg/L from the config', () {
    final t = weeklyTable(
      const [],
      names,
      DomainConfig.defaults,
      l10n,
      fr,
      from: DateTime(2026, 3, 2),
      to: DateTime(2026, 3, 8),
    );
    expect(t.footer, contains('oxygène ≥ 3 mg/L'));
    expect(t.footer, contains('température 27–32 °C'));
    expect(t.footer, contains('pH 6,5–8,5'));
  });
}
