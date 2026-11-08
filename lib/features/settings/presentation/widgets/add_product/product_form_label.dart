import 'package:flutter/material.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';

class ProductFormLabel extends StatelessWidget {
  final String text;
  final bool isRequired;

  const ProductFormLabel(this.text, {super.key, this.isRequired = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        isRequired ? '$text *' : text,
        style: AppTextStyles.sectionLabel13,
      ),
    );
  }
}
