import 'package:dobo/db/database.dart';
import 'package:dobo/db/repositories/batch_repository.dart';
import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter/material.dart';
import 'package:dobo/features/ponds/pond_detail_screen.dart';
import 'package:dobo/features/batches/transfer_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late PondRepository ponds;
  late String q1, e1;

  Future<void> farm(WidgetTester tester, AppDatabase db) async {
    final session = (await SetupRepository(db).currentSession())!;
    ponds = PondRepository(db, session);
    q1 = await ponds.create(
      const PondInput(
        code: 'Q1',
        colour: PondColour.red,
        role: PondRole.quarantine,
      ),
    );
    e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.blue,
        role: PondRole.growout,
      ),
    );
    await ponds.setStatus(e1, PondStatus.ready);
    await BatchRepository(db, session).stockBatch(
      StockInput(
        code: 'L26-01',
        pondId: q1,
        date: DateTime(2026, 3, 1),
        count: 1000,
        avgWeightMg: 12500,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTransfer(WidgetTester tester) async {
    await tapAndSettle(tester, find.text('Q1'));
    await tapAndSettle(tester, find.text('Transférer'));
  }

  Future<void> pickDestination(WidgetTester tester) async {
    await tapAndSettle(tester, find.byKey(ValueKey('pond-$e1')));
  }

  /// The pinned action, named for what it does.
  Finder save([String label = 'Transférer']) => find.descendant(
    of: find.byType(SafeArea),
    matching: find.widgetWithText(FilledButton, label),
  );

  Finder countField() =>
      find.widgetWithText(TextFormField, 'Nombre de poissons');

  appTest('leaving quarantine moves the batch and empties the pond', (
    tester,
    db,
  ) async {
    await farm(tester, db);
    await openTransfer(tester);
    expect(find.textContaining('1 000 poissons'), findsOneWidget);
    await pickDestination(tester);
    await enterAndSettle(tester, countField(), '1000');
    await tapAndSettle(tester, save());

    expect(find.text('Actif'), findsOneWidget);
    expect(find.textContaining('1 000'), findsWidgets);
    expect((await ponds.get(q1)).status, PondStatus.empty);
    expect((await ponds.get(e1)).status, PondStatus.stocked);
  });

  appTest('more than the estimate warns but still saves', (tester, db) async {
    await farm(tester, db);
    await openTransfer(tester);
    await pickDestination(tester);
    await enterAndSettle(tester, countField(), '1200');
    expect(find.text("Plus que l'estimation (1 000)"), findsOneWidget);
    await tapAndSettle(tester, save());
    expect((await db.select(db.transfers).getSingle()).count, 1200);
  });

  appTest('no fish leave an isolated pond', (tester, db) async {
    await farm(tester, db);
    await ponds.setStatus(q1, PondStatus.isolated);
    await tester.pumpAndSettle();
    await openTransfer(tester);
    expect(
      find.text('Étang isolé : aucun poisson ne doit en sortir'),
      findsOneWidget,
    );
    expect(save(), findsNothing);
  });

  appTest('correct a move from the batch history', (tester, db) async {
    await farm(tester, db);
    await openTransfer(tester);
    await pickDestination(tester);
    await enterAndSettle(tester, countField(), '1000');
    await tapAndSettle(tester, save());
    await tapAndSettle(tester, find.text('Corriger').first);
    await enterAndSettle(tester, countField(), '600');
    await tapAndSettle(tester, save('Enregistrer la correction'));
    expect(find.textContaining('400'), findsWidgets);
    expect(find.textContaining('600'), findsWidgets);
    expect(await db.select(db.transfers).get(), hasLength(2));
  });

  appTest('back leaves the transfer screen', (tester, db) async {
    await farm(tester, db);
    await openTransfer(tester);
    await tapAndSettle(tester, find.byType(BackButton));
    // The pond page: its stock button is now below the dashboard.
    expect(find.byType(PondDetailScreen), findsOneWidget);
    expect(find.byType(TransferScreen), findsNothing);
  });

  appTest('a double tap on Save records one move', (tester, db) async {
    await farm(tester, db);
    await openTransfer(tester);
    await pickDestination(tester);
    await enterAndSettle(tester, countField(), '1000');
    await tester.tap(save());
    await tester.tap(save(), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(await db.select(db.transfers).get(), hasLength(1));
  });
}
