import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/utils/phone_utils.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/top_bar_pills.dart';
import '../../../../../core/routing/named_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection/injection_container.dart';
import '../../data/sign_in_request.dart';
import '../bloc/sign_in_bloc.dart';
import '../bloc/sign_in_event.dart';
import '../bloc/sign_in_state.dart';
import '../widgets/sign_in_actions.dart';
import '../widgets/sign_in_fields.dart';
import '../widgets/sign_in_info_chip.dart';
import '../widgets/sign_in_welcome_hero.dart';

/*
|--------------------------------------------------------------------------
| SignInScreen
|--------------------------------------------------------------------------
|
| Login form wired to SignInBloc. On success it navigates to the home
| screen (and applies the Remember Me choice); on failure it shows a
| SnackBar with the mapped error message. The pieces of UI live in
| ../widgets/sign_in_*.dart.
|
|--------------------------------------------------------------------------
*/
class SignInScreen extends StatefulWidget {
  /// Resolves the FCM token sent with the login request. Overridable so the
  /// screen can run without Firebase (tests).
  final Future<String?> Function() fcmTokenProvider;

  const SignInScreen({super.key, this.fcmTokenProvider = _firebaseToken});

  static Future<String?> _firebaseToken() =>
      FirebaseMessaging.instance.getToken();

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  late final SignInBloc _bloc = sl<SignInBloc>();

  bool rememberMe = false;

  /// True while the FCM token is being fetched, before the bloc is loading.
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _bloc.close();
    super.dispose();
  }

  // ───────────────────────── Remember me ─────────────────────────

  Future<void> _loadRememberMe() async {
    final remember = await CacheHelper.getDataFromSharedPreference(
      key: CacheKeys.rememberMe,
    );
    if (remember != true || !mounted) return;

    final phone = await CacheHelper.getDataFromSharedPreference(
      key: CacheKeys.phone,
    );
    final password = await CacheHelper.getDataFromSharedPreference(
      key: CacheKeys.password,
    );
    if (!mounted) return;

    _phoneController.text = phone ?? '';
    _passwordController.text = password ?? '';
    setState(() => rememberMe = true);
  }

  Future<void> _saveRememberMe({
    required bool remember,
    required String phone,
    required String password,
  }) async {
    if (remember) {
      await CacheHelper.saveDataSharedPreference(
        key: CacheKeys.rememberMe,
        value: true,
      );
      await CacheHelper.saveDataSharedPreference(
        key: CacheKeys.phone,
        value: phone,
      );
      await CacheHelper.saveDataSharedPreference(
        key: CacheKeys.password,
        value: password,
      );
    } else {
      await CacheHelper.removeData(key: CacheKeys.rememberMe);
      await CacheHelper.removeData(key: CacheKeys.phone);
      await CacheHelper.removeData(key: CacheKeys.password);
    }
  }

  // ───────────────────────── Actions ─────────────────────────

  Future<void> _submit() async {
    if (_submitting || _bloc.state is LoadingSignInState) return;
    if (!_formKey.currentState!.validate()) return;

    final phone = normalizePhone(_phoneController.text);
    final password = _passwordController.text;

    _submitting = true;
    try {
      final fcmToken = await widget.fcmTokenProvider() ?? '';
      if (!mounted) return;

      _bloc.add(
        LoginEvent(
          request: SignInRequest(
            phone: phone,
            password: password,
            fcmToken: fcmToken,
          ),
        ),
      );
    } finally {
      _submitting = false;
    }
  }

  void _openForgotPassword() {
    Navigator.pushNamed(
      context,
      NamedRoutes.forgotPassword,
      arguments: normalizePhone(_phoneController.text),
    );
  }

  void _onLoggedIn() {
    // Read what we need first: the screen is replaced right below.
    final remember = rememberMe;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(NamedRoutes.home, (r) => false);

    _saveRememberMe(remember: remember, phone: phone, password: password);
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: BlocConsumer<SignInBloc, SignInState>(
            listener: (context, state) {
              if (state is LoadedSignInState) _onLoggedIn();
              if (state is ErrorSignInState) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              final isLoading = state is LoadingSignInState;
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const TopBarPills(),
                            const SizedBox(height: 30),
                            const SignInWelcomeHero(),
                            const SizedBox(height: 20),
                            // One card for the whole form so the fields,
                            // options and action read as a single unit.
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                20,
                                18,
                                18,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadow,
                                    blurRadius: 16,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SignInPhoneField(
                                    controller: _phoneController,
                                  ),
                                  const SizedBox(height: 16),
                                  SignInPasswordField(
                                    controller: _passwordController,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RememberMeRow(
                                          value: rememberMe,
                                          onChanged: (v) =>
                                              setState(() => rememberMe = v),
                                        ),
                                      ),
                                      Flexible(
                                        child: ForgotPasswordLink(
                                          onTap: _openForgotPassword,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  GradientButton(
                                    label: context.tr('sign_in'),
                                    loading: isLoading,
                                    onPressed: _submit,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            SignInFooter(
                              onSignUp: () => Navigator.of(
                                context,
                              ).pushReplacementNamed(NamedRoutes.signup),
                            ),
                            const SizedBox(height: 22),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: SignInInfoChip(
                                      icon: Icons.shield_outlined,
                                      title: context.tr('secure_platform'),
                                      subtitle: context.tr(
                                        'secure_platform_desc',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SignInInfoChip(
                                      icon: Icons.bolt_outlined,
                                      title: context.tr('fast_delivery'),
                                      subtitle: context.tr(
                                        'fast_delivery_desc',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
