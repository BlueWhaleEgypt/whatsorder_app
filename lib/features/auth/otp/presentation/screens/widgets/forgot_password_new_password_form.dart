import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/password_field.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_rules.dart';

/// Step 3: new password (with show/hide), requirements and Reset Password.
class ForgotPasswordNewPasswordForm extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  const ForgotPasswordNewPasswordForm({
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
        PasswordField(
          label: context.tr('new_password'),
          controller: controller,
          validator: (value) {
            final key = ForgotPasswordRules.passwordError(value);
            return key == null ? null : context.tr(key);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.textGrey,
            ),
            const SizedBox(width: 6),
            Text(
              context.tr('password_requirement_min_6'),
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: context.tr('Reset_Password'),
          loading: loading,
          onPressed: loading ? null : onSubmit,
        ),
      ],
    );
  }
}
