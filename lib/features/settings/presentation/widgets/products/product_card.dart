import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// While true the actions are disabled (the product is being deleted).
  final bool isBusy;

  const ProductCard({
    super.key,
    required this.product,
    required this.tileColor,
    required this.onEdit,
    required this.onDelete,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ProductsStyle.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(color: tileColor, photoUrl: product.coverPhotoUrl),
          const SizedBox(width: 12),
          Expanded(child: _Details(product: product)),
          const SizedBox(width: 8),
          _Actions(onEdit: onEdit, onDelete: onDelete, isBusy: isBusy),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  static const double _size = 44;
  static const _radius = BorderRadius.all(Radius.circular(10));
  static const _placeholder = Icon(
    Icons.image_outlined,
    size: 20,
    color: AppColors.textGrey,
  );

  final Color color;
  final String? photoUrl;

  const _Thumbnail({required this.color, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(color: color, borderRadius: _radius),
      child: url == null
          ? _placeholder
          : ClipRRect(
              borderRadius: _radius,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                // Decode at thumbnail size instead of the full photo.
                cacheWidth: (_size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                // The tinted tile shows until the photo arrives, and stays
                // if it can't be loaded.
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _placeholder,
                errorBuilder: (_, _, _) => _placeholder,
              ),
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

class _Actions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isBusy;

  const _Actions({
    required this.onEdit,
    required this.onDelete,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          tooltip: context.tr('edit'),
          asset: AppAssets.edit,
          color: AppColors.primaryGreen,
          background: AppColors.editIconBg,
          onTap: isBusy ? null : onEdit,
        ),
        const SizedBox(height: 6),
        isBusy
            ? const SizedBox(
                width: _ActionButton.size,
                height: _ActionButton.size,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.danger,
                  ),
                ),
              )
            : _ActionButton(
                tooltip: context.tr('delete'),
                asset: AppAssets.delete,
                color: AppColors.danger,
                background: ProductsStyle.dangerTint,
                onTap: onDelete,
              ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  static const double size = 32;

  final String tooltip;
  final String asset;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.tooltip,
    required this.asset,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            asset,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              onTap == null ? AppColors.textFaint : color,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
