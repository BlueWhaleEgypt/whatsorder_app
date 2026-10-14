import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/features/orders/notification/presentation/bloc/notification_counter.dart';
import 'package:whats_order/features/settings/presentation/screens/terms_conditions_screen.dart';
import 'package:whats_order/features/settings/presentation/widgets/language_dialog.dart';
import 'package:whats_order/features/settings/presentation/widgets/profile_header.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_confirmation_dialog.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_group.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_tile.dart';
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
            const ProfileHeader(),
            const SizedBox(height: 24),
            Text(
              context.tr("preferences"),
              style: AppTextStyles.sectionLabel13,
            ),
            const SizedBox(height: 8),
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: SvgPicture.asset(
                    AppAssets.stor,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryGreen,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: context.tr('branches'),
                  onTap: () =>
                      Navigator.pushNamed(context, NamedRoutes.branches),
                ),

                SettingsTile(
                  icon: SvgPicture.asset(
                    AppAssets.lang,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryGreen,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: context.tr('language'),
                  trailing: context.tr('language_label'),
                  onTap: () => showLanguageDialog(context),
                  // onTap: () => context.read<LocaleCubit>().toggle(),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: NotificationCounter.notificationCount,
                  builder: (context, count, child) {
                    return SettingsTile(
                      icon: SvgPicture.asset(
                        AppAssets.ring,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primaryGreen,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: context.tr('notifications'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        NamedRoutes.notification,
                      ),
                    );
                  },
                ),

                // SettingsTile(
                //     icon: Icons.dark_mode_outlined,
                //     label: context.tr('appearance'),
                //     trailing: context.tr('system')),
              ],
            ),
            const SizedBox(height: 20),
            Text(context.tr("account"), style: AppTextStyles.sectionLabel13),
            const SizedBox(height: 8),
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: SvgPicture.asset(
                    AppAssets.paper,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryGreen,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: context.tr('terms_conditions'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),
                SettingsTile(
                  icon: SvgPicture.asset(
                    AppAssets.help,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryGreen,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: context.tr('help_center'),
                  onTap: openWhatsApp,
                ),
                SettingsTile(
                  icon: SvgPicture.asset(
                    AppAssets.logout,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      AppColors.danger,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: context.tr('logout'),
                  iconColor: AppColors.danger,
                  labelColor: AppColors.danger,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: context.tr('logout'),
      message: context.tr('logout_msg'),
      iconAsset: null,
      confirmLabel: context.tr('logout'),
    );

    if (confirmed != true || !context.mounted) return;

    CacheHelper.removeData(key: CacheKeys.userModel);
    ProfileName.clear();
    CacheHelper.removeData(key: CacheKeys.accessToken);
    CacheHelper.removeData(key: CacheKeys.refreshToken);
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(NamedRoutes.signin, (r) => false);
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
