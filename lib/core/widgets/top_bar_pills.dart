import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        _Pill(
          icon: Icons.language,
          label: context.tr('language_label'),
          onTap: () => context.read<LocaleCubit>().toggle(),
        ),
        const _Pill(icon: Icons.auto_awesome, label: "What's Order"),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Pill({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightGreenBg,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primaryGreen),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
