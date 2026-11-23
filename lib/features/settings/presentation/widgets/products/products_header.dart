import 'package:material_ui/material_ui.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_style.dart';

class ProductsHeader extends StatelessWidget {
  // final int productsCount;
  final VoidCallback onAddProduct;

  const ProductsHeader({
    super.key,
    // required this.productsCount,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: ProductsStyle.controlHeight,
          child: FilledButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              context.tr('add_product'),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 47, 144, 87),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.textFaint,
              overlayColor: Colors.white,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 18, 0),
              iconSize: 20,
              textStyle: AppTextStyles.cellMuted13.copyWith(fontSize: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
