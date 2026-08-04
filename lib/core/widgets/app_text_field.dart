import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/*
|--------------------------------------------------------------------------
| AppTextField — the filled, borderless-until-focused text field style
| used across sign up / onboarding ("PHONE", "FIRST NAME", "CITY"...).
|--------------------------------------------------------------------------
*/

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool required;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.required = false,
    this.controller,
    this.keyboardType,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.3,
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            counterText: "",
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.textFaint, fontSize: 14),
            filled: true,
            fillColor: AppColors.lightGreenBg.withOpacity(0.6),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primaryGreen, width: 1.4),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          ),
          maxLength: maxLength,
        ),
      ],
    );
  }
}
