import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_style.dart';

class ProductsHeader extends StatelessWidget {
  final int productsCount;
  final VoidCallback onAddProduct;

  const ProductsHeader({
    super.key,
    required this.productsCount,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('products_count', {'total': '$productsCount'}),
          style: AppTextStyles.subtitle13,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: ProductsStyle.controlHeight,
          child: FilledButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              context.tr('add_product'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ProductsStyle.controlRadius,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
