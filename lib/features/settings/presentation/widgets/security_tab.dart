import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_state.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_bloc.dart';
import 'package:whats_order/features/settings/presentation/screens/change_password_screen.dart';
import 'package:whats_order/injection/injection_container.dart';

class SecurityTab extends StatelessWidget {
  final VendorModel vendor;

  const SecurityTab({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final isVerified = vendor.verificationStatus == 'Verified';
    final isActive = vendor.activation == true;
    final phoneVerified = vendor.verifiedPhone == true;
    final whatsappEnabled = vendor.whatsappNotificationsEnabled == true;

    return BlocProvider(
      create: (_) => sl<OtpBloc>(),
      child: BlocConsumer<OtpBloc, OtpState>(
        listener: (context, state) {
          if (state is LoadedOtpState) {
            Navigator.pushNamed(
              context,
              NamedRoutes.verifyOtp,
              arguments: _normalizePhone(vendor.phone),
            );
          }

          if (state is ErrorOtpState) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isSending = state is LoadingOtpState;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('manage_security'),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _securityTile(
                  icon: Icons.lock_outline_rounded,
                  trailingIcon: Icons.chevron_right_rounded,
                  title: context.tr('change_password'),
                  subtitle: context.tr('mange_password'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (_) => sl<ChangePasswordBloc>(),
                          child: ChangePasswordScreen(
                            userId: vendor.id.toString(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                _securityTile(
                  icon: Icons.phone_android_outlined,
                  title: context.tr('phone_verification'),
                  subtitle: phoneVerified
                      ? context.tr('verified')
                      : context.tr('not_verified'),
                  trailingIcon: phoneVerified
                      ? null
                      : Icons.chevron_right_rounded,
                  isLoading: isSending,
                  onTap: phoneVerified || isSending
                      ? null
                      : () {
                          final phone = _normalizePhone(vendor.phone);

                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.tr('phone_number_missing'),
                                ),
                              ),
                            );
                            return;
                          }

                          context.read<OtpBloc>().add(SendOtpEvent(phone));
                        },
                ),

                _securityTile(
                  icon: Icons.verified,
                  title: context.tr('verification_status'),
                  subtitle: isVerified
                      ? context.tr('verified')
                      : context.tr('not_verified'),
                  onTap: () {},
                ),

                _securityTile(
                  icon: Icons.verified_user_outlined,
                  title: context.tr('activation_status'),
                  subtitle: isActive
                      ? context.tr('active')
                      : context.tr('inactive'),
                  onTap: () {},
                ),

                _securityTile(
                  icon: Icons.notifications_active_outlined,
                  title: context.tr('whatsapp_notifications'),
                  subtitle: whatsappEnabled
                      ? context.tr('enabled')
                      : context.tr('disabled'),
                  onTap: () {},
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _normalizePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) return '';
    if (phone.startsWith('20')) return phone;
    if (phone.startsWith('0')) {
      return '20${phone.substring(1)}';
    }

    return phone;
  }

  Widget _securityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? trailingIcon,
    bool isLoading = false,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryGreen.withOpacity(.1),
            child: Icon(icon, color: AppColors.primaryGreen),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : trailingIcon != null
              ? Icon(trailingIcon, color: AppColors.textGrey)
              : null,
        ),
      ),
    );
  }
}
