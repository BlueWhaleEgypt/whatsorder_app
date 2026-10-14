import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_dialog_style.dart';

void showLanguageDialog(BuildContext context) {
  final cubit = context.read<LocaleCubit>();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: SettingsDialogStyle.background,
        elevation: 0,
        insetPadding: SettingsDialogStyle.insetPadding,
        shape: SettingsDialogStyle.shape,
        title: Text(
          context.tr('language'),
          textAlign: TextAlign.center,
          style: AppTextStyles.heading18,
        ),
        content: BlocBuilder<LocaleCubit, Locale>(
          bloc: cubit,
          builder: (_, locale) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOption(
                flag: '🇸🇦',
                label: 'العربية',
                selected: locale.languageCode == 'ar',
                onTap: () {
                  Navigator.pop(dialogContext);
                  cubit.changeLocale(const Locale('ar'));
                },
              ),
              const SizedBox(height: 8),
              _LanguageOption(
                flag: '🇬🇧',
                label: 'English',
                selected: locale.languageCode == 'en',
                onTap: () {
                  Navigator.pop(dialogContext);
                  cubit.changeLocale(const Locale('en'));
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryGreen.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.cellText13.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: AppColors.primaryGreen,
              ),
          ],
        ),
      ),
    );
  }
}
