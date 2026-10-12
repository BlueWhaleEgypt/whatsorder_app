import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/password_field.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_password_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userId;

  const ChangePasswordScreen({super.key, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
      listener: (context, state) {
        if (state is ChangePasswordSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));

          Navigator.pop(context);
        }

        if (state is ChangePasswordError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is ChangePasswordLoading;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              context.tr("change_password"),
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
                  PasswordField(
                    label: context.tr("password"),
                    controller: _newPasswordController,
                    validator: (v) => (v == null || v.length < 8)
                        ? context.tr("minimum_8_characters")
                        : null,
                  ),
                  PasswordField(
                    label: context.tr("password"),
                    controller: _newPasswordController,
                    validator: (v) => (v == null || v.length < 8)
                        ? context.tr("minimum_8_characters")
                        : null,
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    label: context.tr("confirm_password"),
                    controller: _confirmPasswordController,
                    validator: (v) => (v != _newPasswordController.text)
                        ? context.tr("passwords_dont_match")
                        : null,
                  ),
                  const SizedBox(height: 28),

                  GradientButton(
                    label: 'Save New Password',
                    loading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            context.read<ChangePasswordBloc>().add(
                              SubmitChangePasswordEvent(
                                userId: widget.userId,
                                plainPassword: "",
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
