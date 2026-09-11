import 'package:flutter_test/flutter_test.dart';
import 'package:tryon2buy/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('accepts formatted Indian numbers', () {
      expect(Validators.phone('+91 98765 43210'), isNull);
      expect(Validators.phone('9876543210'), isNull);
    });

    test('rejects blanks and too few digits', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('12345'), isNotNull);
    });
  });

  group('Validators.email', () {
    test('accepts a normal address', () {
      expect(Validators.email('vendor@example.com'), isNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('vendor'), isNotNull);
      expect(Validators.email('vendor@'), isNotNull);
      expect(Validators.email('a b@example.com'), isNotNull);
    });
  });

  test('Validators.password enforces a minimum length', () {
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);
  });

  test('Validators.name rejects blanks and single characters', () {
    expect(Validators.name('  '), isNotNull);
    expect(Validators.name('A'), isNotNull);
    expect(Validators.name('Ananya'), isNull);
  });
}
