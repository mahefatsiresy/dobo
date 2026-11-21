import 'package:dobo/db/database.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:dobo/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  appTest('an admin raises the oxygen minimum; 3,5 mg/L now shows in red', (
    tester,
    db,
  ) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Administration'));
    await tapAndSettle(tester, find.text('Réglages'));
    await tapAndSettle(tester, find.text("Qualité de l'eau"));
    final row = find.byKey(const Key('setting-minOxygenMgL'));
    expect(
      find.descendant(of: row, matching: find.textContaining('3')),
      findsWidgets,
    );
    await enterAndSettle(
      tester,
      find.descendant(of: row, matching: find.byType(TextField)),
      '4',
    );
    await tapAndSettle(tester, find.byKey(const Key('saveSettings')));

    final override = await db.select(db.settingOverrides).getSingle();
    expect((override.key, override.value), ('minOxygenMgL', 4.0));

    // A pond with a reading of 3,5 mg/L: out of range now.
    final s = (await db.select(db.sites).getSingle());
    await db
        .into(db.ponds)
        .insert(
          PondsCompanion.insert(
            id: const Value('p1'),
            associationId: s.associationId,
            enteredBy: s.enteredBy,
            deviceId: s.deviceId,
            siteId: s.id,
            code: 'E1',
            colour: PondColour.blue,
            role: PondRole.growout,
          ),
        );
    await db
        .into(db.waterReadings)
        .insert(
          WaterReadingsCompanion.insert(
            associationId: s.associationId,
            enteredBy: s.enteredBy,
            deviceId: s.deviceId,
            recordedAt: DateTime.utc(2026, 3, 1, 9),
            pondId: 'p1',
            oxygenMgL: const Value(3.5),
          ),
        );
    appContainer(tester).read(routerProvider).go('/ponds/p1');
    await tester.pumpAndSettle();
    final oxygen = tester.widget<Text>(find.textContaining('3,5'));
    expect(oxygen.style?.color, DoboColors.standard.danger);
  });

  appTest('an admin sets the photo cap to 500', (tester, db) async {
    await tapAndSettle(tester, find.text('Plus'));
    await tapAndSettle(tester, find.text('Administration'));
    await tapAndSettle(tester, find.text('Réglages'));
    await tapAndSettle(tester, find.text('Photos'));
    final row = find.byKey(const Key('setting-photoUploadCap'));
    await enterAndSettle(
      tester,
      find.descendant(of: row, matching: find.byType(TextField)),
      '500',
    );
    await tapAndSettle(tester, find.byKey(const Key('saveSettings')));
    final override = await db.select(db.settingOverrides).getSingle();
    expect((override.key, override.value), ('photoUploadCap', 500.0));
  });
}
