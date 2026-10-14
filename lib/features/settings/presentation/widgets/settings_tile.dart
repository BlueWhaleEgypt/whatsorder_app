import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';

class SettingsTile extends StatelessWidget {
  // final IconData icon;
  final Widget icon;
  final String label;
  final String? trailing;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: icon,
      title: Text(
        label,
        style: AppTextStyles.cellText13.copyWith(
          color: labelColor ?? AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing != null
          ? Text(trailing!, style: AppTextStyles.cellMuted13)
          : const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textGrey,
            ),
    );
  }
}
