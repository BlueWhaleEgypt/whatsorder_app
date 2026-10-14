import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/password_field.dart';

/// Phone input: required, exactly the 11 digits of a local number.
class SignInPhoneField extends StatelessWidget {
  final TextEditingController controller;

  const SignInPhoneField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: context.tr('phone'),
      required: true,
      hint: context.tr('phone_hint_signin'),
      controller: controller,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return context.tr('phone_required');
        }
        if (v.trim().length < 11) {
          return context.tr('phone_invalid_length');
        }
        return null;
      },
    );
  }
}

/// Password input with the show/hide toggle; required.
class SignInPasswordField extends StatelessWidget {
  final TextEditingController controller;

  const SignInPasswordField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return PasswordField(
      label: context.tr('password'),
      hint: context.tr('password_hint'),
      controller: controller,
      validator: (v) =>
          (v == null || v.isEmpty) ? context.tr('password_required') : null,
    );
  }
}
