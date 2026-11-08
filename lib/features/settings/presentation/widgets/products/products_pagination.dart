import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_style.dart';

class ProductsPagination extends StatelessWidget {
  final int from;
  final int to;
  final int total;

  /// Zero-based current page.
  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  const ProductsPagination({
    super.key,
    required this.from,
    required this.to,
    required this.total,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr('showing_products', {
            'from': '$from',
            'to': '$to',
            'total': '$total',
          }),
          style: AppTextStyles.subtitle13,
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 6,
            children: [
              _PageButton(
                onTap: page > 0 ? () => onPageChanged(page - 1) : null,
                child: const Icon(Icons.chevron_left, size: 16),
              ),
              for (var i = 0; i < pageCount; i++)
                _PageButton(
                  selected: i == page,
                  onTap: () => onPageChanged(i),
                  child: Text('${i + 1}'),
                ),
              _PageButton(
                onTap: page < pageCount - 1
                    ? () => onPageChanged(page + 1)
                    : null,
                child: const Icon(Icons.chevron_right, size: 16),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  final Widget child;
  final bool selected;
  final VoidCallback? onTap;

  const _PageButton({required this.child, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : onTap == null
        ? AppColors.textFaint
        : AppColors.textDark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: ProductsStyle.pageButtonSize,
          height: ProductsStyle.pageButtonSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryGreen : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primaryGreen : AppColors.border,
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
            child: IconTheme(
              data: IconThemeData(color: foreground),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
