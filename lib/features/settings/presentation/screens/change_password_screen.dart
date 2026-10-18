import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/password_field.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/change_password_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userId;

  const ChangePasswordScreen({super.key, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state is ChangePasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trMessage(state.message))),
          );

          Navigator.pop(context);
        }

        if (state is ChangePasswordError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trMessage(state.message))),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ChangePasswordLoading;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,

          appBar: AppBar(
            title: Text(
              context.tr('change_password'),
              style: AppTextStyles.heading18,
            ),
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 24),

                  // Old password
                  PasswordField(
                    label: context.tr('old_password'),
                    controller: _oldPasswordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('field_required');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // New password
                  PasswordField(
                    label: context.tr('new_password'),
                    controller: _newPasswordController,
                    hint: context.tr('minimum_8_characters'),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return context.tr('minimum_8_characters');
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm new password
                  PasswordField(
                    label: context.tr('confirm_password'),
                    controller: _confirmPasswordController,
                    hint: context.tr('minimum_8_characters'),

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return context.tr('field_required');
                      }

                      if (value != _newPasswordController.text) {
                        return context.tr('passwords_dont_match');
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  GradientButton(
                    label: context.tr('save_new_password'),
                    loading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            logger.i(widget.userId);
                            logger.i(_oldPasswordController.text);
                            logger.i(_newPasswordController.text);

                            context.read<ChangePasswordBloc>().add(
                              SubmitChangePasswordEvent(
                                userId: widget.userId,
                                plainPassword: _oldPasswordController.text,
                                newPassword: _newPasswordController.text,
                              ),
                            );
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
