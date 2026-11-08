import 'package:flutter/material.dart';
import 'package:whats_order/features/settings/presentation/widgets/add_product/add_product_input_decoration.dart';
import 'package:whats_order/features/settings/presentation/widgets/add_product/product_form_label.dart';

/// A labelled text input of the add-product form.
class ProductFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? prefixText;

  const ProductFormField({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductFormLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: prefixText == null
              ? AddProductInputDecoration.plain
              : AddProductInputDecoration.withPrefix(prefixText!),
          validator: validator,
        ),
      ],
    );
  }
}
