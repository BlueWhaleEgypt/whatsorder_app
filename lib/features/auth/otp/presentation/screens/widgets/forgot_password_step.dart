import 'package:flutter/material.dart';

/// The three stages of the password-recovery flow, in order.
enum ForgotPasswordStep {
  phone(
    icon: Icons.phone_iphone_rounded,
    titleKey: 'fp_phone_title',
    descriptionKey: 'fp_phone_desc',
  ),
  otp(
    icon: Icons.sms_outlined,
    titleKey: 'fp_otp_title',
    descriptionKey: 'fp_otp_desc',
  ),
  password(
    icon: Icons.lock_reset_rounded,
    titleKey: 'fp_password_title',
    descriptionKey: 'fp_password_desc',
  );

  final IconData icon;
  final String titleKey;
  final String descriptionKey;

  const ForgotPasswordStep({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
  });
}
