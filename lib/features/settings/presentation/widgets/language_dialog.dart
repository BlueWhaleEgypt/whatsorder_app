import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_dialog_style.dart';

void showLanguageDialog(BuildContext context) {
  final cubit = context.read<LocaleCubit>();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: cubit,
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LanguageOption(
                    flag: '🇸🇦',
                    label: 'العربية',
                    selected: locale.languageCode == 'ar',
                    onTap: () async {
                      if (locale.languageCode == 'ar') {
                        Navigator.pop(dialogContext);
                        return;
                      }
                      Navigator.pop(dialogContext);

                      await cubit.changeLocale(const Locale('ar'));
                    },
                  ),
                  const SizedBox(height: 8),
                  _LanguageOption(
                    flag: '🇬🇧',
                    label: 'English',
                    selected: locale.languageCode == 'en',
                    onTap: () async {
                      if (locale.languageCode == 'en') {
                        Navigator.pop(dialogContext);
                        return;
                      }
                      Navigator.pop(dialogContext);

                      await cubit.changeLocale(const Locale('en'));
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _LanguageOption extends StatefulWidget {
  final String flag;
  final String label;
  final bool selected;
  final Future<void> Function() onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_LanguageOption> createState() => _LanguageOptionState();
}

class _LanguageOptionState extends State<_LanguageOption> {
  bool _isChangingLanguage = false;

  Future<void> _handleTap() async {
    if (_isChangingLanguage) return;

    setState(() {
      _isChangingLanguage = true;
    });

    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() {
          _isChangingLanguage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isChangingLanguage ? null : _handleTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: widget.selected
              ? AppColors.primaryGreen.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.selected ? AppColors.primaryGreen : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(widget.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: AppTextStyles.cellText13.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (widget.selected)
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
