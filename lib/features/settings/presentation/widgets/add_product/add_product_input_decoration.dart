import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';

/// The text-field look shared by every add-product input.
class AddProductInputDecoration {
  AddProductInputDecoration._();

  static const _radius = BorderRadius.all(Radius.circular(12));

  static const InputDecoration plain = InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColors.primaryGreenLight),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: AppColors.danger),
    ),
  );

  static InputDecoration withPrefix(String prefixText) =>
      plain.copyWith(prefixText: prefixText);
}
