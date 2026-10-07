import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

class FilesTab extends StatelessWidget {
  final VendorModel vendor;

  const FilesTab({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("manage_files_description"),

            style: AppTextStyles.cellMuted13,
          ),

          const SizedBox(height: 10),

          _buildFileCard(
            title: 'Face ID Card',
            fileName: vendor.faceIdCard,
            icon: Icons.badge_outlined,
          ),

          _buildFileCard(
            title: 'Back ID Card',
            fileName: vendor.backIdCard,
            icon: Icons.badge_outlined,
          ),

          _buildFileCard(
            title: 'Commercial Register',
            fileName: vendor.commercialRegister,
            icon: Icons.business_center_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard({
    required String title,
    required String? fileName,
    required IconData icon,
  }) {
    final hasFile = fileName != null && fileName.trim().isNotEmpty;

    /*
     * IMPORTANT:
     * Replace this with your real files endpoint.
     *
     * Example:
     * https://ain.utes.ie/uploads/$fileName
     */
    // final imageUrl = hasFile
    //     ? 'YOUR_FILES_BASE_URL/$fileName'
    //     : null;
    final imageUrl = hasFile ? '${EndPoints.baseUrl}/uploads/$fileName' : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryGreen.withOpacity(.1),
                child: Icon(icon, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.cardTitle15)),
            ],
          ),

          const SizedBox(height: 14),

          if (hasFile)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                height: 230,
                fit: BoxFit.fill,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const SizedBox(
                    height: 230,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(
                    height: 230,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 45,
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 42,
                  color: AppColors.textGrey,
                ),
              ),
            ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                // Replace/upload file later.
              },
              icon: Icon(
                hasFile ? Icons.edit_outlined : Icons.upload_file_outlined,
              ),
              label: Text(hasFile ? 'Replace' : 'Upload'),
            ),
          ),
        ],
      ),
    );
  }
}
