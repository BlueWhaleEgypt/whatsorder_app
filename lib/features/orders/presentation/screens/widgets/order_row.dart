import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/order_model.dart';

/*
|--------------------------------------------------------------------------
| OrderRow — now a mobile-friendly card instead of a wide table row.
|
| Layout (stacked, not side-by-side columns):
|   [checkbox]  Order ID              [edit icon]
|               Date
|               [ Open Map pill ]
|
| This keeps every value readable on a narrow screen instead of
| squeezing 4 columns into ~360px.
|--------------------------------------------------------------------------
*/
class OrderRow extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onOpenMap;
  final VoidCallback? onEdit;
  final ValueChanged<bool?>? onToggle;

  const OrderRow({
    super.key,
    required this.order,
    this.onOpenMap,
    this.onEdit,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        // Unseen orders get a light green tint.
        color: order.view ? AppColors.surface : AppColors.lightGreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.view
              ? AppColors.border
              : AppColors.primaryGreen.withValues(alpha: 0.25),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(
              value: order.isChecked,
              onChanged: onToggle,
              activeColor: AppColors.primaryGreen,
              shape: const CircleBorder(),
            ),
          ),

          /// ORDER ID
          Expanded(
            flex: 2,
            child: SizedBox(
              width: 60,
              child: Text(
                "${order.orderId}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          /// DATE
          Expanded(
            flex: 3,
            child: Text(
              _formatDate(order.createdDate),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.tableDateGrey,
                fontSize: 13,
              ),
            ),
          ),

          /// MAP
          Expanded(
            flex: 3,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: InkWell(
                onTap: onOpenMap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.mapGreenLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primaryGreenLight,
                      width: .5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.tr('open_map'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          /// EDIT
          SizedBox(
            width: 50,
            child: Center(
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20),
                child: SvgPicture.asset(
                  AppAssets.edit,
                  width: 20,
                  height: 20,

                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryGreenTint,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '';
    try {
      final date = DateTime.parse(value);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return value;
    }
  }
}
