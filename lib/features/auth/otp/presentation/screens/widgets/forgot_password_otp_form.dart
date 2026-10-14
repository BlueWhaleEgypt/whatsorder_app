import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_rules.dart';

/// Step 2: OTP input, Verify, Resend code and Change number.
class ForgotPasswordOtpForm extends StatelessWidget {
  final String phone;
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeNumber;

  const ForgotPasswordOtpForm({
    super.key,
    required this.phone,
    required this.controller,
    required this.loading,
    required this.onVerify,
    required this.onResend,
    required this.onChangeNumber,
  });

  PinTheme _pinTheme({
    Color border = AppColors.border,
    Color fill = AppColors.surface,
    double width = 1,
  }) {
    return PinTheme(
      width: 46,
      height: 54,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: width),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone numbers always read left-to-right, even in Arabic.
        Text(
          phone,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 20),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Pinput(
              controller: controller,
              length: ForgotPasswordRules.otpLength,
              enabled: !loading,
              keyboardType: TextInputType.number,
              defaultPinTheme: _pinTheme(),
              focusedPinTheme: _pinTheme(
                border: AppColors.primaryGreen,
                width: 1.6,
              ),
              submittedPinTheme: _pinTheme(
                border: AppColors.primaryGreen,
                fill: AppColors.lightGreenBg,
              ),
              errorPinTheme: _pinTheme(border: AppColors.danger),
              errorTextStyle: const TextStyle(
                color: AppColors.danger,
                fontSize: 12,
              ),
              validator: (value) {
                final key = ForgotPasswordRules.otpError(value);
                return key == null ? null : context.tr(key);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: context.tr('Verify_OTP'),
          loading: loading,
          onPressed: loading ? null : onVerify,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.tr('didnt_get_code'),
              style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
            ),
            TextButton(
              onPressed: loading ? null : onResend,
              child: Text(
                context.tr('resend_code'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: loading ? AppColors.textFaint : AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: loading ? null : onChangeNumber,
          child: Text(
            context.tr('change_number'),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textGrey,
            ),
          ),
        ),
      ],
    );
  }
}
