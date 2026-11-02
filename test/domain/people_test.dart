import 'package:dobo/domain/people.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dir = PeopleDirectory(
    people: {'p1': 'Rakoto', 'p2': 'Hery'},
    accounts: {
      'm1': AccountRef(name: 'rakoto', personId: 'p1'),
      'm2': AccountRef(name: 'Soa'),
    },
  );

  test("worker's own log resolves to the linked person", () {
    expect(dir.observerKey(enteredBy: 'm1'), 'p1');
    expect(dir.observerName(enteredBy: 'm1'), 'Rakoto');
  });

  test('transcribed log resolves to the observer, not the typist', () {
    expect(dir.observerKey(observedBy: 'p2', enteredBy: 'm1'), 'p2');
    expect(dir.observerName(observedBy: 'p2', enteredBy: 'm1'), 'Hery');
  });

  test('account with no person falls back to the account name', () {
    expect(dir.observerKey(enteredBy: 'm2'), 'account:m2');
    expect(dir.observerName(enteredBy: 'm2'), 'Soa');
  });

  test('unknown observed_by gives null name, never the typist', () {
    expect(dir.observerKey(observedBy: 'p9', enteredBy: 'm1'), 'p9');
    expect(dir.observerName(observedBy: 'p9', enteredBy: 'm1'), isNull);
  });

  test('unknown account gives null name', () {
    expect(dir.observerName(enteredBy: 'm9'), isNull);
  });
}
