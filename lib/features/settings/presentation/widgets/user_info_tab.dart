import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/sector_dropdown.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_state.dart';
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

  String? _sectorId;
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

    final data = context.read<OnboardingCubit>().state.data;

    _sectorId = data.sectorId.isEmpty ? null : data.sectorId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<OnboardingCubit>().loadSectors();
    });
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

    if (_sectorId == null || _sectorId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('sector_is_required'))));
      return;
    }

    // TODO: استدعاء Update Profile API لإرسال:
    // firstNameController.text.trim()
    // lastNameController.text.trim()
    // emailController.text.trim()
    // _sectorId
    //
    // اقفل وضع التعديل بعد نجاح الـ API.

    setState(() => isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final sectors = widget.vendor.sectors ?? [];

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
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

                const SizedBox(height: 20),
                if (sectors.isEmpty) _emptyState(),

                ...sectors.map((sector) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryGreen.withOpacity(
                            .1,
                          ),
                          child: const Icon(
                            Icons.token_outlined,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sector.name ?? '-',
                                style: AppTextStyles.cardTitle15,
                              ),
                              if (sector.note != null &&
                                  sector.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  sector.note!,
                                  style: AppTextStyles.cellMuted13,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (isEditing) ...[
                  const SizedBox(height: 20),

                  SectorDropdown(
                    sectors: state.sectors,
                    loading: state.sectorsLoading,
                    error: state.sectorsError,
                    value: _sectorId,
                    onChanged: (value) {
                      setState(() {
                        _sectorId = value;
                      });
                    },
                    onRetry: () {
                      context.read<OnboardingCubit>().loadSectors();
                    },
                  ),
                ],

                // SectorDropdown(
                //   sectors: state.sectors,
                //   loading: state.sectorsLoading,
                //   error: state.sectorsError,
                //   value: _sectorId,
                //   onChanged: isEditing
                //       ? (value) {
                //           setState(() => _sectorId = value);
                //         }
                //       : (_) {},
                //   onRetry: () {
                //     context.read<OnboardingCubit>().loadSectors();
                //   },
                // ),
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
      },
    );
  }
}

Widget _emptyState() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      children: [
        Icon(Icons.store_outlined, size: 42, color: AppColors.textGrey),
        SizedBox(height: 12),
        Text(
          'No sectors available',
          style: TextStyle(color: AppColors.textGrey),
        ),
      ],
    ),
  );
}
