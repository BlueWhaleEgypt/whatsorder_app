import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';

/// One branch in the Branches list: names, address and Edit / Delete actions.
class BranchCard extends StatelessWidget {
  final BranchModel branch;

  /// Disables Delete while another branch action is running.
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BranchCard({
    super.key,
    required this.branch,
    required this.onEdit,
    required this.onDelete,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = branch.name.isNotEmpty ? branch.name : branch.nameEn;
    final showSubtitle = branch.name.isNotEmpty && branch.nameEn.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          top: BorderSide(color: AppColors.primaryGreen, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.09),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryGreenTint.withOpacity(.2),
                    AppColors.surface,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SvgPicture.asset(
                      AppAssets.stor,
                      width: 8,
                      height: 8,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryGreenTint,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.cardTitle15),
                        if (showSubtitle) ...[
                          const SizedBox(height: 3),
                          Text(
                            branch.nameEn,
                            style: AppTextStyles.sectionLabel13.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Address chip
            if (branch.address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          branch.address,
                          style: AppTextStyles.heading18.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: SvgPicture.asset(
                        AppAssets.edit,
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primaryGreenTint,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(context.tr('edit')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        backgroundColor: AppColors.primaryGreen.withOpacity(
                          .04,
                        ),
                        side: BorderSide(
                          color: AppColors.primaryGreen.withOpacity(.25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onDelete,
                      icon: SvgPicture.asset(
                        AppAssets.delete,
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.danger,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(context.tr('delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.withOpacity(.04),
                        side: BorderSide(color: Colors.red.withOpacity(.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
