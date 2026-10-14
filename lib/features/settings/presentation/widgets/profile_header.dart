import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, NamedRoutes.profile),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppAssets.person,
                  width: 30,
                  height: 30,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: ProfileName.fullName,
                    builder: (_, name, __) =>
                        Text(name, style: AppTextStyles.cardTitle15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr("edit_profile"),
                    style: AppTextStyles.cellMuted13,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
