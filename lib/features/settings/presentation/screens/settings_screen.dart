import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/localization/locale_cubit.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import '../../../../core/routing/named_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/*
|--------------------------------------------------------------------------
| SettingsScreen — "Settings" tab.
|
| Grouped, modern settings list. Static for now — wire each item's
| onTap / trailing to real state (e.g. a ThemeCubit, a LocaleCubit) the
| same way every other feature is wired to a Bloc.
|--------------------------------------------------------------------------
*/

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr("settings"), style: AppTextStyles.heading18),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileHeader(),
            const SizedBox(height: 24),
            Text(
              context.tr("preferences"),
              style: AppTextStyles.sectionLabel13,
            ),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.language_outlined,
                  label: context.tr('language'),
                  trailing: context.tr('language_label'),
                  onTap: () => context.read<LocaleCubit>().toggle(),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: NotificationCounter.notificationCount,
                  builder: (context, count, child) {
                    return _SettingsTile(
                      icon: Icons.notifications_none_rounded,
                      label: context.tr('notifications'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        NamedRoutes.notification,
                      ),
                    );
                  },
                ),

                // _SettingsTile(
                //     icon: Icons.dark_mode_outlined,
                //     label: context.tr('appearance'),
                //     trailing: context.tr('system')),
              ],
            ),
            const SizedBox(height: 20),
            Text(context.tr("account"), style: AppTextStyles.sectionLabel13),
            const SizedBox(height: 8),
            _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.lock_outline,
                  label: context.tr('privacy_security'),
                  onTap: openWebsite,
                ),
                _SettingsTile(
                  icon: Icons.help_outline,
                  label: context.tr('help_center'),
                  onTap: openWhatsApp,
                ),
                _SettingsTile(
                  icon: Icons.logout,
                  label: context.tr('logout'),
                  iconColor: AppColors.danger,
                  labelColor: AppColors.danger,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.tr('logout')),
                        content: Text(context.tr('logout_msg')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(context.tr('cancel')),
                          ),
                          TextButton(
                            onPressed: () {
                              CacheHelper.removeData(key: CacheKeys.userModel);
                              CacheHelper.removeData(
                                key: CacheKeys.accessToken,
                              );
                              CacheHelper.removeData(
                                key: CacheKeys.refreshToken,
                              );
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                NamedRoutes.signin,
                                (r) => false,
                              );
                            },
                            child: Text(context.tr('logout')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> openWebsite() async {
    final uri = Uri.parse("https://whatsorder.shop/ar/terms-conditions");

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> openWhatsApp() async {
    const phone = "19296190855";
    const message = "مرحبًا، أحتاج مساعدة من خدمة عملاء WhatsOrder.";

    final whatsappUri = Uri.parse(
      "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}",
    );

    final webUri = Uri.parse(
      "https://wa.me/$phone?text=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = UserModel.fromJson(
      jsonDecode(
        CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
            '{}',
      ),
    );
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
            const CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryGreen,
              child: Icon(Icons.person, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.firstName ?? ''} ${user.lastName ?? ''}',
                    style: AppTextStyles.cardTitle15,
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

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: List.generate(children.length, (i) {
            return Column(
              children: [
                children[i],
                if (i != children.length - 1)
                  const Divider(height: 1, indent: 54, color: AppColors.border),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap ?? () {},
      leading: Icon(icon, size: 20, color: iconColor ?? AppColors.textGrey),
      title: Text(
        label,
        style: AppTextStyles.cellText13.copyWith(
          color: labelColor ?? AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing != null
          ? Text(trailing!, style: AppTextStyles.cellMuted13)
          : const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textFaint,
            ),
    );
  }
}
