import 'package:flutter/material.dart';

import 'package:whats_order/core/localization/app_localizations.dart';
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
  final formKey = GlobalKey<FormState>();

  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController emailController;

  bool isEditing = false;

  @override
  void initState() {
    super.initState();

    firstNameController = TextEditingController(
      text: widget.vendor.firstName ?? '',
    );

    lastNameController = TextEditingController(
      text: widget.vendor.lastName ?? '',
    );

    emailController = TextEditingController(text: widget.vendor.email ?? '');
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    if (!isEditing) {
      setState(() => isEditing = true);
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    // TODO: استدعاء Update Profile API.
    //
    // firstNameController.text.trim()
    // lastNameController.text.trim()
    // emailController.text.trim()
    //
    // يتم إغلاق وضع التعديل بعد نجاح الـ API.

    setState(() => isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('manage_user_info_description'),
              style: AppTextStyles.cellMuted13,
            ),

            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: context.tr('first_name'),
                    required: true,
                    hint: context.tr('first_name'),
                    controller: firstNameController,
                    enabled: isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: context.tr('last_name'),
                    hint: context.tr('last_name'),
                    controller: lastNameController,
                    enabled: isEditing,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            AppTextField(
              label: context.tr('email'),
              required: true,
              hint: 'you@example.com',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('email_is_required');
                }

                if (!RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(value.trim())) {
                  return context.tr('enter_a_valid_email');
                }

                return null;
              },
            ),

            const SizedBox(height: 100),

            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: context.tr(isEditing ? 'save_changes' : 'edit'),
                onPressed: _toggleEditing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
