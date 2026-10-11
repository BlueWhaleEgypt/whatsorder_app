import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
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
                child: AppTextField(
                  label: context.tr("first_name"),
                  required: true,
                  hint: context.tr("first_name"),
                  controller: firstNameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Required" : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: context.tr("last_name"),
                  hint: context.tr("last_name"),
                  controller: lastNameController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Email ──────────────────────────────────────────────
          AppTextField(
            label: context.tr("email"),
            required: true,
            hint: "you@example.com",
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return context.tr("email_is_required");
              }
              if (!v.contains('@')) return context.tr("enter_a_valid_email");
              return null;
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.tr('phone'),
            required: true,
            hint: context.tr('phone_hint_signin'),
            controller: phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return context.tr('phone_required');
              }
              if (v.trim().length < 11) {
                return context.tr('phone_invalid_length');
              }
              return null;
            },
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
                child: AppTextField(
                  label: context.tr("city"),
                  hint: context.tr("city"),
                  controller: cityController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: context.tr("state"),
                  hint: context.tr("state"),
                  controller: stateController,
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
          GradientButton(
            label: context.tr("save_changes"),
            // loading: state.isSubmitting,
            onPressed: () {
              // Handle form submission
            },
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
