import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';

/*
|--------------------------------------------------------------------------
| Shared look of the products widgets.
|--------------------------------------------------------------------------
*/

class ProductsStyle {
  ProductsStyle._();

  static const double cardRadius = 14;
  static const double controlRadius = 12;
  static const double controlHeight = 44;
  static const double pageButtonSize = 32;

  static const Color successTint = Color(0xFFDCFCE7);

  static const List<Color> tileColors = [
    successTint,
    Color(0xFFFFEDD5),
    Color(0xFFDBEAFE),
    Color(0xFFFEE2E2),
  ];

  static Color tileColor(int index) => tileColors[index % tileColors.length];

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(color: AppColors.border),
    boxShadow: const [
      BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
    ],
  );
}
