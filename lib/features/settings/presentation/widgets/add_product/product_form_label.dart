import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_colors.dart';

class ProductFormLabel extends StatelessWidget {
  final String text;
  final bool isRequired;

  const ProductFormLabel(this.text, {super.key, this.isRequired = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        isRequired ? text.toUpperCase() : '$text *',

        // style: AppTextStyles.sectionLabel13,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
