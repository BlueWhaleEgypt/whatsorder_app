import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/data/profile/update_profile_request.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/update_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';

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
  void didUpdateWidget(covariant UserInfoTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Refreshed vendor arrived: show saved values unless the user is mid-edit.
    if (widget.vendor != oldWidget.vendor && !isEditing) {
      firstNameController.text = widget.vendor.firstName ?? '';
      lastNameController.text = widget.vendor.lastName ?? '';
      emailController.text = widget.vendor.email ?? '';
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (!isEditing) {
      setState(() => isEditing = true);
      return;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final userId = widget.vendor.id.toString();

    if (userId.isEmpty || userId == 'null') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('user_id_not_found'))));
      return;
    }

    context.read<UpdateProfileBloc>().add(
      SubmitUpdateProfileEvent(
        request: UpdateProfileRequest.fromVendor(
          userId: userId,
          vendor: widget.vendor,
          overrides: {
            'firstName': firstNameController.text.trim(),
            'lastName': lastNameController.text.trim(),
            'email': emailController.text.trim(),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateProfileBloc, UpdateProfileState>(
      listener: (context, state) {
        if (state is UpdateProfileSuccess) {
          setState(() => isEditing = false);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trMessage(state.message))),
          );
        }

        if (state is UpdateProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trMessage(state.message))),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is UpdateProfileLoading;

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
                        enabled: isEditing && !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.tr('field_required');
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
                        enabled: isEditing && !isLoading,
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
                  enabled: isEditing && !isLoading,
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
                    label: isLoading
                        ? context.tr('loading')
                        : context.tr(isEditing ? 'save_changes' : 'edit'),
                    onPressed: isLoading ? () {} : _save,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
