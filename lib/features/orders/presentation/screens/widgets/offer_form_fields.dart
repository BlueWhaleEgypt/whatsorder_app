import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';

/// Multiline offer details input. Needs at least [minLength] trimmed chars.
class OfferDetailsField extends StatelessWidget {
  static const minLength = 5;

  final TextEditingController controller;

  const OfferDetailsField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: context.tr('offer_details'),
      hint: context.tr('write_your_offer'),
      required: true,
      maxLines: 4,
      keyboardType: TextInputType.multiline,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return context.tr('please_enter_offer_details');
        }
        if (value.trim().length < minLength) {
          return context.tr('offer_details_too_short');
        }
        return null;
      },
    );
  }
}

/// Execution-time dropdown. Values are translation keys, so labels follow
/// the current locale and nothing translated is cached.
class ExecutionTimeSelector extends StatelessWidget {
  static const options = [
    '15_minutes',
    '30_minutes',
    '45_minutes',
    '1_hour',
    '2_hours',
  ];

  /// Called with the selected translation key; null disables the field.
  final ValueChanged<String?>? onChanged;

  const ExecutionTimeSelector({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border([Color color = Colors.transparent]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 1.4),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: context.tr('order_execution_time').toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.3,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.danger),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textGrey,
          ),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textDark,
          ),
          validator: (value) =>
              value == null ? context.tr('please_select_execution_time') : null,
          items: [
            for (final key in options)
              DropdownMenuItem(value: key, child: Text(context.tr(key))),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.lightGreenBg.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: border(),
            enabledBorder: border(),
            focusedBorder: border(AppColors.primaryGreen),
            errorBorder: border(AppColors.danger),
            focusedErrorBorder: border(AppColors.danger),
          ),
        ),
      ],
    );
  }
}
