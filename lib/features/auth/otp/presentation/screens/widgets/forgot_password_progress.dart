import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_step.dart';

/// Compact three-step progress: completed ✓, active highlighted, upcoming muted.
class ForgotPasswordProgress extends StatelessWidget {
  final ForgotPasswordStep step;

  const ForgotPasswordProgress({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.tr('fp_step_phone'),
      context.tr('fp_step_otp'),
      context.tr('fp_step_password'),
    ];
    final current = step.index;
    final children = <Widget>[];

    for (var i = 0; i < labels.length; i++) {
      children.add(
        Expanded(
          child: _StepDot(
            index: i,
            label: labels[i],
            done: i < current,
            active: i == current,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Connector lines sit behind the dots.
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: (labels.length - 1) / labels.length,
                child: Row(
                  children: List.generate(labels.length - 1, (i) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: i < current
                              ? AppColors.primaryGreen
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool done;
  final bool active;

  const _StepDot({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = done || active;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: highlighted ? AppColors.primaryGreen : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: highlighted ? AppColors.primaryGreen : AppColors.border,
              width: 1.6,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textGrey,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
            color: highlighted ? AppColors.primaryGreen : AppColors.textGrey,
          ),
        ),
      ],
    );
  }
}
