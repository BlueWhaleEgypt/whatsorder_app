import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  static const _fontFamily = 'Cairo';

  static const TextStyle greeting13 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textGrey,
  );

  static const TextStyle heading22 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.textDark,
  );
  static const TextStyle heading18 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    color: AppColors.textDark,
  );
  static const TextStyle subtitle13 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    color: AppColors.textGrey,
  );

  static const TextStyle sectionLabel13 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textGrey,
  );

  static const TextStyle tableHeader12 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryGreen,
  );

  static const TextStyle cellText13 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    color: AppColors.textDark,
  );

  static const TextStyle cellTextbold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  static const TextStyle cellMuted13 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    color: AppColors.textGrey,
  );

  static const TextStyle cardTitle15 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );
}
