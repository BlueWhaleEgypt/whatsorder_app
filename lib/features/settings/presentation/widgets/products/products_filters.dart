import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/presentation/widgets/products/products_style.dart';

/// Search box and sector dropdown.
///
/// The search text lives in [searchController], owned by the screen, so it
/// survives this widget being rebuilt or recreated (e.g. after an error).
class ProductsFilters extends StatelessWidget {
  static const _searchIcon = ColorFilter.mode(
    AppColors.textGrey,
    BlendMode.srcIn,
  );

  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;

  /// Sector id -> name.
  final Map<String, String> sectors;
  final String? selectedSectorId;
  final ValueChanged<String?> onSectorChanged;

  const ProductsFilters({
    super.key,
    required this.searchController,
    required this.onQueryChanged,
    required this.sectors,
    required this.selectedSectorId,
    required this.onSectorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            style: AppTextStyles.cellText13,
            decoration: _decoration(
              hint: context.tr('search_products'),
              prefix: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  AppAssets.search,
                  width: 16,
                  height: 16,
                  colorFilter: _searchIcon,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String?>(
            // `initialValue` is only read on creation, so re-key on change.
            key: ValueKey(selectedSectorId),
            initialValue: selectedSectorId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
            style: AppTextStyles.cellText13,
            decoration: _decoration(),
            onChanged: onSectorChanged,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(
                  context.tr('all_categories'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final e in sectors.entries)
                DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static InputDecoration _decoration({String? hint, Widget? prefix}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(ProductsStyle.controlRadius),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.cellMuted13,
      prefixIcon: prefix,
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primaryGreenLight),
    );
  }
}
