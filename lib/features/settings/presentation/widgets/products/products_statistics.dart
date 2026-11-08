import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_style.dart';

class ProductsStatistics extends StatelessWidget {
  final int productsCount;
  final int categoriesCount;

  const ProductsStatistics({
    super.key,
    required this.productsCount,
    required this.categoriesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.inventory_2_outlined,
            label: context.tr('total_products'),
            value: '$productsCount',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.category_outlined,
            label: context.tr('categories'),
            value: '$categoriesCount',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  static const _labelStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 11,
    color: AppColors.textGrey,
  );

  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ProductsStyle.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ProductsStyle.successTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryGreenTint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle,
                ),
                Text(value, style: AppTextStyles.heading22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
