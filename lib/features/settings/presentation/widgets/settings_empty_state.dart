import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';

class SettingsEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const SettingsEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.textGrey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}
