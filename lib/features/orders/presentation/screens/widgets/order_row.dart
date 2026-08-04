import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      height: 62,
      color: order.view ? Colors.white : Colors.green.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          /// DATE
          Expanded(
            flex: 3,
            child: Text(
              _formatDate(order.createdDate),
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
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onOpenMap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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

          /// EDIT
          SizedBox(
            width: 50,
            child: Center(
              child: InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(20),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.editIconBg,
                  child: Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryGreen,
                    size: 16,
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
