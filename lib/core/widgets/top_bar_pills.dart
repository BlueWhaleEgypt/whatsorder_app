import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import '../localization/app_localizations.dart';
import '../localization/locale_cubit.dart';
import '../theme/app_colors.dart';

/*
|--------------------------------------------------------------------------
| TopBarPills — the language pill + "✨ What's Order" brand pill shown
| at the top of every auth screen. Tapping the language pill toggles
| between English/Arabic via LocaleCubit (persisted, and switches the
| whole app to RTL automatically for Arabic).
|--------------------------------------------------------------------------
*/

class TopBarPills extends StatelessWidget {
  const TopBarPills({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: _Pill(
            icon: AppAssets.lang,
            iconSize: 17,
            iconColor: AppColors.primaryGreenTint,
            label: context.tr('language_label'),
            onTap: () => context.read<LocaleCubit>().toggle(),
          ),
        ),
        const SizedBox(width: 8),
        const Flexible(
          child: _Pill(
            icon: AppAssets.star,
            iconColor: Color.fromARGB(255, 18, 173, 75),
            iconSize: 18,
            label: "What's Order",
            textColor: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;
  final Color textColor;

  /// Optional tint/size for the icon; null keeps the SVG's own look.
  final double? iconSize;
  final Color? iconColor;

  const _Pill({
    required this.icon,
    required this.label,
    this.onTap,
    this.textColor = AppColors.primaryGreen,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightGreenBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: iconSize,
              height: iconSize,
              colorFilter: iconColor == null
                  ? null
                  : ColorFilter.mode(iconColor!, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
