import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/utils/logger.dart';
import '../../../../../core/routing/named_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/password_field.dart';
import '../../../../../core/widgets/top_bar_pills.dart';

/*
|--------------------------------------------------------------------------
| SignUpScreen — "Create Account" step (phone + password only).
|
| No API call is made here. The user fills in their phone number and
| password, then taps "Continue" to proceed to the 3-step onboarding
| wizard. The credentials are passed to OnboardingScreen so the cubit
| can carry them through all three steps and include them in the single
| POST /api/auth/signup multipart call fired at the very last step.
|--------------------------------------------------------------------------
*/

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String normalizePhone(String phone) {
    phone = phone.trim().replaceAll(' ', '');

    if (phone.startsWith('0')) {
      return '2$phone';
    }

    if (phone.startsWith('20')) {
      return phone;
    }

    return phone;
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    final phone = normalizePhone(_phoneController.text);
    logger.d("phone: $phone");
    Navigator.of(context).pushNamed(
      NamedRoutes.onboarding,
      arguments: {'phone': phone, 'password': _passwordController.text},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopBarPills(),
                const SizedBox(height: 28),
                Text(
                  context.tr("create_account"),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr("join_subtitle"),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: context.tr('phone'),
                  required: true,
                  hint: context.tr('phone_hint_signin'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? context.tr('phone_required')
                      : null,
                ),

                const SizedBox(height: 16),
                PasswordField(
                  label: context.tr("password"),
                  controller: _passwordController,
                  validator: (v) => (v == null || v.length < 8)
                      ? context.tr("minimum_8_characters")
                      : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  label: context.tr("confirm_password"),
                  controller: _confirmController,
                  validator: (v) => (v != _passwordController.text)
                      ? context.tr("passwords_dont_match")
                      : null,
                ),
                const SizedBox(height: 28),
                GradientButton(
                  label: context.tr("continue"),
                  trailingIcon: Icons.arrow_forward,
                  onPressed: _onContinue,
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).pushReplacementNamed(NamedRoutes.signin),
                    child: RichText(
                      text: TextSpan(
                        text: "${context.tr("already_have_account")} ",
                        style: const TextStyle(
                          fontFamily: "Cairo",
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                        children: [
                          TextSpan(
                            text: context.tr("sign_in"),
                            style: const TextStyle(
                              fontFamily: "Cairo",
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
