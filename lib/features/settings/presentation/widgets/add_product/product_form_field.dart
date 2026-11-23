import 'package:material_ui/material_ui.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
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
        AppTextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          label: label,
          hint: prefixText,
          validator: validator,
        ),
      ],
    );
  }
}
