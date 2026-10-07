import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

class SecurityTab extends StatelessWidget {
  final VendorModel vendor;

  const SecurityTab({super.key, required this.vendor});

  @override
  Widget build(BuildContext context) {
    final isVerified = vendor.verificationStatus == 'Verified';

    final phoneVerified = vendor.verifiedPhone == true;

    final whatsappEnabled = vendor.whatsappNotificationsEnabled == true;

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
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {},
          ),

          _securityTile(
            icon: Icons.verified_user_outlined,
            title: 'Verification Status',
            subtitle: isVerified ? 'Verified' : 'Not verified',
            onTap: () {},
          ),

          _securityTile(
            icon: Icons.phone_android_outlined,
            title: 'Phone Verification',
            subtitle: phoneVerified ? 'Verified' : 'Not verified',
            onTap: () {},
          ),

          _securityTile(
            icon: Icons.notifications_active_outlined,
            title: 'WhatsApp Notifications',
            subtitle: whatsappEnabled ? 'Enabled' : 'Disabled',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _securityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}
