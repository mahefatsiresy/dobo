import 'package:dobo/domain/accounts.dart';
import 'package:dobo/domain/types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? worker(String login, String secret) =>
      accountProblem(role: MemberRole.worker, login: login, secret: secret);
  String? member(String login, String secret) =>
      accountProblem(role: MemberRole.member, login: login, secret: secret);

  group('a worker signs in with a username and a 6-digit PIN', () {
    test('rakoto and 123456 are fine', () {
      expect(worker('rakoto', '123456'), isNull);
    });
    test('a username under 3 characters is bad_login', () {
      expect(worker('ra', '123456'), 'bad_login');
    });
    test('a username with a space is bad_login', () {
      expect(worker('ra koto', '123456'), 'bad_login');
    });
    test('the username is checked lowercased', () {
      expect(worker('Rakoto', '123456'), isNull);
    });
    test('5 or 7 digits, or a letter, is bad_secret', () {
      expect(worker('rakoto', '12345'), 'bad_secret');
      expect(worker('rakoto', '1234567'), 'bad_secret');
      expect(worker('rakoto', '12a456'), 'bad_secret');
    });
  });

  group('a member signs in with an email and a password', () {
    test('a@b.mg and motdepasse are fine', () {
      expect(member('a@b.mg', 'motdepasse'), isNull);
    });
    test('an address without @ is bad_login', () {
      expect(member('ab.mg', 'motdepasse'), 'bad_login');
    });
    test('the address is checked lowercased and trimmed', () {
      expect(member(' Soa@B.mg ', 'motdepasse'), isNull);
    });
    test('a password under $minPasswordLength characters is bad_secret', () {
      expect(member('a@b.mg', 'court'), 'bad_secret');
      expect(member('a@b.mg', '1234567'), 'bad_secret');
      expect(member('a@b.mg', '12345678'), isNull);
    });
  });

  test('secretProblem checks only the secret, by role', () {
    expect(secretProblem(role: MemberRole.worker, secret: '654321'), isNull);
    expect(secretProblem(role: MemberRole.worker, secret: '65432'), 'bad_secret');
    expect(secretProblem(role: MemberRole.member, secret: 'court'), 'bad_secret');
    expect(pinLength, 6);
  });
}
