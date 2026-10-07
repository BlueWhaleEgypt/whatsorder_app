import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

class BranchesTab extends StatelessWidget {
  final VendorModel vendor;

  const BranchesTab({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final sectors = vendor.sectors ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('branches_description'),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),

          const SizedBox(height: 10),

          if (sectors.isEmpty) _emptyState(),

          ...sectors.map((sector) {
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
                    backgroundColor: AppColors.primaryGreen.withOpacity(.1),
                    child: const Icon(
                      Icons.store_outlined,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sector.name ?? '-',
                          style: AppTextStyles.cardTitle15,
                        ),
                        if (sector.note != null && sector.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(sector.note!, style: AppTextStyles.cellMuted13),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Edit sector later.
                    },
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () {
              // Add sector later.
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Branch'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.store_outlined, size: 42, color: AppColors.textGrey),
          SizedBox(height: 12),
          Text(
            'No sectors available',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
