import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';

/// Small icon + title + subtitle tile (e.g. "Secure platform").
class SignInInfoChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SignInInfoChip({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreenBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
