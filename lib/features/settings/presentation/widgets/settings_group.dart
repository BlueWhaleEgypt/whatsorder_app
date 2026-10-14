import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';

class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: List.generate(children.length, (i) {
            return Column(
              children: [
                children[i],
                if (i != children.length - 1)
                  const Divider(height: 1, indent: 54, color: AppColors.border),
              ],
            );
          }),
        ),
      ),
    );
  }
}
