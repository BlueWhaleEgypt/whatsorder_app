
import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';

class MapPickerField extends StatefulWidget {
  final bool hasLocation;
  final VoidCallback onTap;

  const MapPickerField({
    super.key,
    required this.hasLocation,
    required this.onTap,
  });

  @override
  State<MapPickerField> createState() => _MapPickerFieldState();
}

class _MapPickerFieldState extends State<MapPickerField> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr("location_label"),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightGreenBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  widget.hasLocation
                      ? Icons.check_circle
                      : Icons.map_outlined,
                  size: 18,
                  color: widget.hasLocation
                      ? AppColors.primaryGreen
                      : AppColors.textGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.hasLocation
                      ? context.tr("location_selected")
                      : context.tr("choose_on_map"),
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.hasLocation
                        ? AppColors.textDark
                        : AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
