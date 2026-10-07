import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

class UserInfoTab extends StatefulWidget {
  final VendorModel vendor;

  const UserInfoTab({super.key, required this.vendor});

  @override
  State<UserInfoTab> createState() => _UserInfoTabState();
}

class _UserInfoTabState extends State<UserInfoTab> {
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController usernameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController typeController;
  late final TextEditingController cityController;
  late final TextEditingController stateController;
  late final TextEditingController serviceDistanceController;

  @override
  void initState() {
    super.initState();

    firstNameController = TextEditingController(
      text: widget.vendor.firstName ?? '',
    );

    lastNameController = TextEditingController(
      text: widget.vendor.lastName ?? '',
    );

    usernameController = TextEditingController(
      text: widget.vendor.username ?? '',
    );

    emailController = TextEditingController(text: widget.vendor.email ?? '');

    phoneController = TextEditingController(text: widget.vendor.phone ?? '');

    typeController = TextEditingController(text: widget.vendor.type ?? '');

    cityController = TextEditingController(
      text: widget.vendor.city?.trim() ?? '',
    );

    stateController = TextEditingController(
      text: widget.vendor.state?.trim() ?? '',
    );

    serviceDistanceController = TextEditingController(
      text: widget.vendor.serviceDistance?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    typeController.dispose();
    cityController.dispose();
    stateController.dispose();
    serviceDistanceController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("manage_user_info_description"),

            style: AppTextStyles.cellMuted13,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'First Name',
                  controller: firstNameController,
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _field(
                  label: 'Last Name',
                  controller: lastNameController,
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _field(
            label: 'Username',
            controller: usernameController,
            icon: Icons.alternate_email_rounded,
          ),

          const SizedBox(height: 16),

          _field(
            label: 'Email',
            controller: emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          _field(
            label: 'Phone',
            controller: phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 16),

          _field(
            label: 'Account Type',
            controller: typeController,
            icon: Icons.badge_outlined,
            enabled: false,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'City',
                  controller: cityController,
                  icon: Icons.location_city_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _field(
                  label: 'State',
                  controller: stateController,
                  icon: Icons.map_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _field(
            label: 'Service Distance',
            controller: serviceDistanceController,
            icon: Icons.social_distance_outlined,
            keyboardType: TextInputType.number,
            suffixText: 'm',
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Update API later.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixText: suffixText,
        filled: true,
        fillColor: enabled
            ? AppColors.surface
            : AppColors.surface.withOpacity(.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
