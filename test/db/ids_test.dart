import 'package:dobo/db/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  test('accountPersonId is stable and differs per member', () {
    expect(accountPersonId('m1'), accountPersonId('m1'));
    expect(accountPersonId('m1'), isNot(accountPersonId('m2')));
    expect(Uuid.isValidUUID(fromString: accountPersonId('m1')), isTrue);
  });
}
