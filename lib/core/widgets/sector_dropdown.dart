import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';

class SectorDropdown extends StatelessWidget {
  final List sectors;
  final bool loading;
  final String? error;
  final String? value;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  const SectorDropdown({
    super.key,
    required this.sectors,
    required this.loading,
    required this.error,
    required this.value,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSector = sectors.where((sector) => sector.id == value);

    final hasSelectedSector = selectedSector.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.token_outlined,
                color: AppColors.primaryGreen,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.tr('your_sector'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Dropdown / Loading / Error
        if (loading)
          Container(
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          )
        else if (error != null)
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Failed to load sectors — tap to retry',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.danger.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasSelectedSector
                    ? AppColors.primaryGreen.withOpacity(0.45)
                    : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: sectors.any((sector) => sector.id == value) ? value : null,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryGreen,
                size: 24,
              ),
              borderRadius: BorderRadius.circular(14),
              dropdownColor: AppColors.surface,
              menuMaxHeight: 320,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textGrey,
              ),
              hint: Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 19,
                    color: AppColors.textGrey.withOpacity(0.65),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr('select_your_sector'),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textGrey.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              items: sectors.map<DropdownMenuItem<String>>((sector) {
                return DropdownMenuItem<String>(
                  value: sector.id as String,
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.token_outlined,
                          color: AppColors.primaryGreen,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          sector.name?.toString() ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 1.4,
                  ),
                ),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
      ],
    );
  }
}
