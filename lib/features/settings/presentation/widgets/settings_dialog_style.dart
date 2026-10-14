import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';

/// Shared look for Settings dialogs (confirmation, language, ...).
class SettingsDialogStyle {
  SettingsDialogStyle._();

  static const Color background = AppColors.surface;
  static const EdgeInsets insetPadding = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(24, 28, 24, 20);

  static RoundedRectangleBorder get shape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
    side: const BorderSide(color: AppColors.border),
  );
}
