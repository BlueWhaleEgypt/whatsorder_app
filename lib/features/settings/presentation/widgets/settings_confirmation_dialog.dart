import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_dialog_style.dart';

/// Shows the shared Settings confirmation dialog.
///
/// Resolves to `true` when confirmed, `false` when cancelled and `null` when
/// dismissed through the barrier (treat `null` as "not confirmed").
Future<bool?> showSettingsConfirmationDialog(
  BuildContext context, {
  String? title,
  required String message,
  String? itemName,
  String? iconAsset = AppAssets.delete,
  String? confirmLabel,
  String? cancelLabel,
  Color color = AppColors.danger,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => SettingsConfirmationDialog(
      title: title,
      message: message,
      itemName: itemName,
      iconAsset: iconAsset,
      confirmLabel: confirmLabel ?? context.tr('delete'),
      cancelLabel: cancelLabel ?? context.tr('cancel'),
      color: color,
    ),
  );
}

class SettingsConfirmationDialog extends StatelessWidget {
  final String? title;
  final String message;
  final String? itemName;

  /// Null shows no icon badge and no icon on the confirm button.
  final String? iconAsset;
  final String confirmLabel;
  final String cancelLabel;
  final Color color;

  const SettingsConfirmationDialog({
    super.key,
    this.title,
    required this.message,
    this.itemName,
    this.iconAsset = AppAssets.delete,
    required this.confirmLabel,
    required this.cancelLabel,
    this.color = AppColors.danger,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SettingsDialogStyle.background,
      elevation: 0,
      insetPadding: SettingsDialogStyle.insetPadding,
      shape: SettingsDialogStyle.shape,
      contentPadding: SettingsDialogStyle.contentPadding,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null) ...[
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                iconAsset!,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading18,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.cellMuted13.copyWith(
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (itemName != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                itemName!,
                style: AppTextStyles.cellText13.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(cancelLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _confirmButton(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _confirmButton(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    void confirm() => Navigator.pop(context, true);

    if (iconAsset == null) {
      return ElevatedButton(
        onPressed: confirm,
        style: style,
        child: Text(confirmLabel),
      );
    }

    return ElevatedButton.icon(
      onPressed: confirm,
      icon: SvgPicture.asset(
        iconAsset!,
        width: 18,
        height: 18,
        colorFilter: const ColorFilter.mode(
          AppColors.editIconBg,
          BlendMode.srcIn,
        ),
      ),
      label: Text(confirmLabel),
      style: style,
    );
  }
}
