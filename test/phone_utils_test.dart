import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/core/utils/phone_utils.dart';

void main() {
  group('normalizePhone', () {
    test('prefixes local numbers starting with 0', () {
      expect(normalizePhone('01012345678'), '201012345678');
    });

    test('trims surrounding whitespace and removes spaces', () {
      expect(normalizePhone('  010 1234 5678  '), '201012345678');
    });

    test('leaves numbers starting with 20 unchanged', () {
      expect(normalizePhone('201012345678'), '201012345678');
    });

    test('leaves any other input unchanged', () {
      expect(normalizePhone('+201012345678'), '+201012345678');
      expect(normalizePhone('12345'), '12345');
      expect(normalizePhone(''), '');
      expect(normalizePhone('   '), '');
    });
  });
}
