import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_rules.dart';

/// Step 1: phone input and the Send OTP action.
class ForgotPasswordPhoneForm extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  const ForgotPasswordPhoneForm({
    super.key,
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          enabled: !loading,
          label: context.tr('phone_number_label'),
          hint: context.tr('phone_hint_signin'),
          validator: (value) {
            final key = ForgotPasswordRules.phoneError(value);
            return key == null ? null : context.tr(key);
          },
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: context.tr('Send_OTP'),
          loading: loading,
          onPressed: loading ? null : onSubmit,
        ),
      ],
    );
  }
}
