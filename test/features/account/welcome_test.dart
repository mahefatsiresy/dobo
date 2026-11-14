import 'package:dobo/sync/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';
import '../../sync/fake_auth_gateway.dart';

void main() {
  appTest('welcome offers sign-in, worker sign-in and backup only', (
    tester,
    db,
  ) async {
    expect(find.byKey(const Key('welcomeMember')), findsOneWidget);
    expect(find.byKey(const Key('welcomeWorker')), findsOneWidget);
    expect(find.byKey(const Key('welcomeImport')), findsOneWidget);
    expect(find.byKey(const Key('welcomeCreate')), findsNothing);
    expect(find.textContaining("Créer l'association"), findsNothing);
  },
    setUp: false,
    overrides: [authGatewayProvider.overrideWith((ref) => FakeAuthGateway())],
  );
}
