import 'package:whats_order/core/utils/phone_utils.dart' as phone_utils;

/// Pure input rules for the password-recovery flow.
///
/// Validators return a translation key (or null when valid) so they stay free
/// of `BuildContext`; the widgets translate the key.
class ForgotPasswordRules {
  ForgotPasswordRules._();

  static const otpLength = 6;
  static const minPasswordLength = 6;

  /// Same normalisation the sign-in screen uses (see `normalizePhone`).
  static String normalizePhone(String phone) =>
      phone_utils.normalizePhone(phone);

  static String? phoneError(String? value) {
    final phone = (value ?? '').trim().replaceAll(' ', '');
    if (phone.isEmpty) return 'phone_required';
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(phone)) return 'phone_invalid';
    return null;
  }

  static String? otpError(String? value) =>
      (value ?? '').length == otpLength ? null : 'otp_incomplete';

  static String? passwordError(String? value) {
    if (value == null || value.isEmpty) return 'field_required';
    if (value.length < minPasswordLength) return 'password_min_6';
    return null;
  }
}
