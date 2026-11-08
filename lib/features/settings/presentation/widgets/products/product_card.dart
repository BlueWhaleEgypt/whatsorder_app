import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/utils/price_formatter.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_style.dart';

class ProductCard extends StatelessWidget {
  static const _sectorStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 11,
    color: AppColors.textGrey,
  );
  static const _priceStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryGreenTint,
  );

  final ProductModel product;
  final Color tileColor;

  const ProductCard({
    super.key,
    required this.product,
    required this.tileColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ProductsStyle.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(color: tileColor),
          const SizedBox(width: 12),
          Expanded(child: _Details(product: product)),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final Color color;

  const _Thumbnail({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 20,
        color: AppColors.textGrey,
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final ProductModel product;

  const _Details({required this.product});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.cellTextbold,
        ),
        if (p.sectorName.isNotEmpty)
          Text(
            p.sectorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ProductCard._sectorStyle,
          ),
        if (p.note.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            p.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cellMuted13,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                PriceFormatter.egp(p.price),
                style: ProductCard._priceStyle,
              ),
            ),
            if (p.deliveryTime.isNotEmpty)
              _DeliveryChip(deliveryTime: p.deliveryTime),
          ],
        ),
      ],
    );
  }
}

class _DeliveryChip extends StatelessWidget {
  static const _style = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryGreenTint,
  );

  final String deliveryTime;

  const _DeliveryChip({required this.deliveryTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: ProductsStyle.successTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${context.tr('delivery_time')}: $deliveryTime',
        style: _style,
      ),
    );
  }
}
