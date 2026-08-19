import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/password_field.dart';
import 'package:whats_order/core/widgets/top_bar_pills.dart';
import '../../../../../core/routing/named_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection/injection_container.dart';
import '../../data/sign_in_request.dart';
import '../bloc/sign_in_bloc.dart';
import '../bloc/sign_in_event.dart';
import '../bloc/sign_in_state.dart';

/*
|--------------------------------------------------------------------------
| SignInScreen
|--------------------------------------------------------------------------
|
| Minimal login form wired to SignInBloc. On success it navigates to
| the home screen; on failure it shows a SnackBar with the mapped
| error message.
|
|--------------------------------------------------------------------------
*/
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool rememberMe = false;
  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final remember = await CacheHelper.getDataFromSharedPreference(
      key: CacheKeys.rememberMe,
    );

    if (remember == true) {
      _phoneController.text =
          await CacheHelper.getDataFromSharedPreference(key: CacheKeys.phone) ??
          "";

      _passwordController.text =
          await CacheHelper.getDataFromSharedPreference(
            key: CacheKeys.password,
          ) ??
          "";

      setState(() {
        rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SignInBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: BlocConsumer<SignInBloc, SignInState>(
            listener: (context, state) async {
              if (state is LoadedSignInState) {
                // await CacheHelper.saveDataSharedPreference(
                //   key: 'accessToken',
                //   value: state.getSignInResponse.accessToken,
                // );

                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(NamedRoutes.home, (r) => false);

                if (rememberMe) {
                  await CacheHelper.saveDataSharedPreference(
                    key: CacheKeys.rememberMe,
                    value: true,
                  );

                  await CacheHelper.saveDataSharedPreference(
                    key: CacheKeys.phone,
                    value: _phoneController.text.trim(),
                  );

                  await CacheHelper.saveDataSharedPreference(
                    key: CacheKeys.password,
                    value: _passwordController.text,
                  );
                } else {
                  await CacheHelper.removeData(key: CacheKeys.rememberMe);
                  await CacheHelper.removeData(key: CacheKeys.phone);
                  await CacheHelper.removeData(key: CacheKeys.password);
                }
              }
              if (state is ErrorSignInState) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              final isLoading = state is LoadingSignInState;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TopBarPills(),
                      const SizedBox(height: 20),
                      const _WelcomeHero(),
                      const SizedBox(height: 22),
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
                        label: context.tr('password'),
                        hint: context.tr('password_hint'),
                        controller: _passwordController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? context.tr('password_required')
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            String normalizePhone(String phone) {
                              phone = phone.trim().replaceAll(' ', '');

                              if (phone.startsWith('0')) {
                                return '2${phone}';
                              }

                              if (phone.startsWith('20')) {
                                return phone;
                              }

                              return phone;
                            }

                            final phone = normalizePhone(_phoneController.text);
                            // TODO: push a ForgotPasswordScreen once that flow/endpoint is available.
                            Navigator.pushNamed(
                              context,
                              NamedRoutes.forgotPassword,
                              arguments: phone,
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            context.tr('forget_password'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ),

                      // const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (value) {
                              setState(() {
                                rememberMe = value!;
                              });
                            },
                          ),
                          Text(
                            context.tr('remember_me'),
                            style: AppTextStyles.cellText13,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GradientButton(
                        label: context.tr('sign_in'),
                        loading: isLoading,
                        onPressed: () async {
                          String normalizePhone(String phone) {
                            phone = phone.trim().replaceAll(' ', '');

                            if (phone.startsWith('0')) {
                              return '2${phone}';
                            }

                            if (phone.startsWith('20')) {
                              return phone;
                            }

                            return phone;
                          }

                          final phone = normalizePhone(_phoneController.text);

                          print(phone); // 201234567890
                          final fcmToken =
                              await FirebaseMessaging.instance.getToken() ?? '';
                          logger.w('fcm token $fcmToken');
                          if (!_formKey.currentState!.validate()) return;
                          context.read<SignInBloc>().add(
                            LoginEvent(
                              request: SignInRequest(
                                phone: phone,
                                // phone: _phoneController.text.trim(),
                                password: _passwordController.text,
                                fcmToken: fcmToken,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(
                            context,
                          ).pushReplacementNamed(NamedRoutes.signup),
                          child: RichText(
                            text: TextSpan(
                              text: context.tr('no_account'),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                color: AppColors.textGrey,
                              ),
                              children: [
                                TextSpan(
                                  text: context.tr('sign_up'),
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.shield_outlined,
                              title: context.tr('secure_platform'),
                              subtitle: context.tr('secure_platform_desc'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.bolt_outlined,
                              title: context.tr('fast_delivery'),
                              subtitle: context.tr('fast_delivery_desc'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreenLight, AppColors.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('welcome_back'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('signin_subtitle'),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoChip({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGreenBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryGreen),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
