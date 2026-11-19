import 'package:dobo/db/repositories/pond_repository.dart';
import 'package:dobo/db/repositories/setup_repository.dart';
import 'package:dobo/domain/types.dart';
import 'package:dobo/features/ponds/pond_overview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  appTest('pond colours include archived ponds', (tester, db) async {
    final session = (await SetupRepository(db).currentSession())!;
    final ponds = PondRepository(db, session);
    final e1 = await ponds.create(
      const PondInput(
        code: 'E1',
        colour: PondColour.red,
        role: PondRole.growout,
      ),
    );
    final e2 = await ponds.create(
      const PondInput(
        code: 'E2',
        colour: PondColour.green,
        role: PondRole.growout,
      ),
    );
    await ponds.archive(e2);
    final sub = appContainer(tester).listen(pondColoursProvider, (_, _) {});
    addTearDown(sub.close);
    await tester.pumpAndSettle();
    expect(sub.read(), {e1: PondColour.red, e2: PondColour.green});
  });
}
