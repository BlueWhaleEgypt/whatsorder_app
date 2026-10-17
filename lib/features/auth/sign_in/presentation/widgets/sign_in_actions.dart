import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';

/// "Forgot password?" text link, aligned to the right like the original.
class ForgotPasswordLink extends StatelessWidget {
  final VoidCallback onTap;

  const ForgotPasswordLink({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          context.tr('forget_password'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }
}

/// Remember-me checkbox with its label.
class RememberMeRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const RememberMeRow({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Flexible(
          child: Text(
            context.tr('remember_me'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cellText13,
          ),
        ),
      ],
    );
  }
}

/// "No account? Sign up" footer link.
class SignInFooter extends StatelessWidget {
  final VoidCallback onSignUp;

  const SignInFooter({super.key, required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onSignUp,
        child: RichText(
          text: TextSpan(
            text: context.tr('no_account'),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textGrey,
            ),
            children: [
              TextSpan(
                text: context.tr('sign_up'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
