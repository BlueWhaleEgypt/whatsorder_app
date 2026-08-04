import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';

/*
|--------------------------------------------------------------------------
| StepperHeader — the Info / Location / Files progress indicator at the
| top of the onboarding wizard. A step is:
|   • done      → filled green circle with a check
|   • current   → filled green circle with its icon
|   • upcoming  → grey outlined circle with its icon
| Connecting lines are green once the step before them is done.
|--------------------------------------------------------------------------
*/

class StepperHeader extends StatelessWidget {
  final int currentStep; // 0, 1, 2

  const StepperHeader({super.key, required this.currentStep});

  static const _labels = ["Info", "Location", "Files"];
  static const _icons = [
    Icons.person_outline,
    Icons.location_on_outlined,
    Icons.description_outlined
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final leftStepDone = (i - 1) ~/ 2 < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 22),
              color: leftStepDone ? AppColors.primaryGreen : AppColors.border,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isDone = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;

        return Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDone || isCurrent)
                    ? AppColors.primaryGreen
                    : Colors.white,
                border: Border.all(
                  color: (isDone || isCurrent)
                      ? AppColors.primaryGreen
                      : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Icon(
                isDone ? Icons.check : _icons[stepIndex],
                size: 17,
                color:
                    (isDone || isCurrent) ? Colors.white : AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _labels[stepIndex],
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: (isDone || isCurrent)
                    ? AppColors.primaryGreen
                    : AppColors.textGrey,
              ),
            ),
          ],
        );
      }),
    );
  }
}
