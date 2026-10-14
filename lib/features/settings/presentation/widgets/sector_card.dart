import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';

class SectorCard extends StatelessWidget {
  final String name;
  final String? note;

  /// Null disables the delete button (e.g. while an action is in progress).
  final VoidCallback? onDelete;

  const SectorCard({super.key, required this.name, this.note, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null && note!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
            child: const Icon(
              Icons.token_outlined,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.cardTitle15),
                if (hasNote) ...[
                  const SizedBox(height: 4),
                  Text(note!, style: AppTextStyles.cellMuted13),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            tooltip: context.tr('delete_sector'),
            icon: SvgPicture.asset(
              AppAssets.delete,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.danger,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
