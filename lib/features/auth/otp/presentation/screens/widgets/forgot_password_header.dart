import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_step.dart';

/// Step icon, an optional progress indicator, then title and description.
class ForgotPasswordHeader extends StatelessWidget {
  final ForgotPasswordStep step;

  /// Shown between the icon and the title (the step progress bar).
  final Widget? progress;

  const ForgotPasswordHeader({super.key, required this.step, this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            color: AppColors.lightGreenBg,
            shape: BoxShape.circle,
          ),
          child: Icon(step.icon, size: 32, color: AppColors.primaryGreen),
        ),
        const SizedBox(height: 20),
        if (progress != null) ...[progress!, const SizedBox(height: 24)],
        Text(
          context.tr(step.titleKey),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(step.descriptionKey),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}
