import 'package:flutter_test/flutter_test.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_rules.dart';

void main() {
  group('normalizePhone', () {
    test('adds the country prefix to local numbers', () {
      expect(ForgotPasswordRules.normalizePhone('01012345678'), '201012345678');
    });

    test('trims and removes spaces', () {
      expect(
        ForgotPasswordRules.normalizePhone(' 010 1234 5678 '),
        '201012345678',
      );
    });

    test('leaves international numbers unchanged', () {
      expect(
        ForgotPasswordRules.normalizePhone('201012345678'),
        '201012345678',
      );
      expect(
        ForgotPasswordRules.normalizePhone('+201012345678'),
        '+201012345678',
      );
    });
  });

  group('phoneError', () {
    test('requires a value', () {
      expect(ForgotPasswordRules.phoneError(null), 'phone_required');
      expect(ForgotPasswordRules.phoneError('  '), 'phone_required');
    });

    test('rejects malformed numbers', () {
      expect(ForgotPasswordRules.phoneError('12ab'), 'phone_invalid');
      expect(ForgotPasswordRules.phoneError('123456789'), 'phone_invalid');
      expect(ForgotPasswordRules.phoneError('1' * 16), 'phone_invalid');
    });

    test('accepts local and international numbers', () {
      expect(ForgotPasswordRules.phoneError('01012345678'), isNull);
      expect(ForgotPasswordRules.phoneError('010 1234 5678'), isNull);
      expect(ForgotPasswordRules.phoneError('+201012345678'), isNull);
    });
  });

  test('otpError needs exactly six digits', () {
    expect(ForgotPasswordRules.otpError(null), 'otp_incomplete');
    expect(ForgotPasswordRules.otpError('12345'), 'otp_incomplete');
    expect(ForgotPasswordRules.otpError('123456'), isNull);
  });

  test('passwordError needs at least six characters', () {
    expect(ForgotPasswordRules.passwordError(''), 'field_required');
    expect(ForgotPasswordRules.passwordError('12345'), 'password_min_6');
    expect(ForgotPasswordRules.passwordError('123456'), isNull);
  });
}
