import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';

/// Resolved order address plus the Open Map action.
///
/// [address] null (or empty) shows the localized "unknown location" text.
/// [onOpenMap] null disables the map action (no coordinates).
class OrderLocationSection extends StatelessWidget {
  final String? address;
  final bool loading;
  final VoidCallback? onOpenMap;

  const OrderLocationSection({
    super.key,
    required this.address,
    required this.loading,
    required this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = address != null && address!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('location'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mapGreenLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryGreenLight),
          ),
          child: Row(
            children: [
              if (loading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                )
              else
                Icon(
                  hasAddress
                      ? Icons.location_on_outlined
                      : Icons.location_off_outlined,
                  size: 22,
                  color: hasAddress
                      ? AppColors.primaryGreen
                      : AppColors.textGrey,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loading
                      ? context.tr('loading_location')
                      : hasAddress
                      ? address!
                      : context.tr('unknown_location'),
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: loading || !hasAddress
                        ? AppColors.textGrey
                        : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOpenMap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(context.tr('open_map')),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            disabledForegroundColor: AppColors.textFaint,
            side: BorderSide(
              color: onOpenMap == null
                  ? AppColors.border
                  : AppColors.primaryGreen.withValues(alpha: 0.4),
            ),
            minimumSize: const Size.fromHeight(48),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
