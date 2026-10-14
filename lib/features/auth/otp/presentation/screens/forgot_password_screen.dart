import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_state.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_header.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_new_password_form.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_otp_form.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_phone_form.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_progress.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_rules.dart';
import 'package:whats_order/features/auth/otp/presentation/screens/widgets/forgot_password_step.dart';

/// Coordinates the Send OTP → Verify OTP → Reset Password flow: owns the
/// current step, controllers and verified user id, talks to [OtpBloc] and
/// shows feedback. The step UIs live in `widgets/forgot_password_*.dart`.
class ForgotPasswordScreen extends StatefulWidget {
  final String phone;
  const ForgotPasswordScreen({super.key, required this.phone});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  // One Form for all steps: only the current step's fields are mounted, so
  // validate() only checks the active step.
  final _formKey = GlobalKey<FormState>();

  ForgotPasswordStep _step = ForgotPasswordStep.phone;
  String? _userId;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _phone = widget.phone;
    _phoneController.text = widget.phone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ───────────────────────── Actions ─────────────────────────

  void _sendOtp() {
    if (!_formKey.currentState!.validate()) return;

    _phone = ForgotPasswordRules.normalizePhone(_phoneController.text);
    context.read<OtpBloc>().add(SendOtpEvent(_phone));
  }

  void _resendOtp() => context.read<OtpBloc>().add(SendOtpEvent(_phone));

  void _verifyOtp() {
    if (!_formKey.currentState!.validate()) return;

    context.read<OtpBloc>().add(
      VerifyOtpEvent(phone: _phone, otp: _otpController.text),
    );
  }

  void _resetPassword() {
    if (!_formKey.currentState!.validate()) return;

    context.read<OtpBloc>().add(
      ForgetPasswordEvent(
        userId: _userId!,
        newPassword: _passwordController.text,
      ),
    );
  }

  void _goBackToPhone() {
    _otpController.clear();
    setState(() => _step = ForgotPasswordStep.phone);
  }

  // ───────────────────────── Bloc feedback ─────────────────────────

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _onState(BuildContext context, OtpState state) {
    if (state is LoadedOtpState) {
      setState(() => _step = ForgotPasswordStep.otp);
      _showMessage(context.tr('otp_sent_successfully'));
    }

    if (state is VerifiedOtpState) {
      _userId = state.response.userId;
      setState(() => _step = ForgotPasswordStep.password);
      _showMessage(context.tr('otp_verified_successfully'));
    }

    if (state is ForgetPasswordSuccessState) {
      _showMessage(context.tr('password_changed_successfully'));
      Navigator.pop(context);
    }

    if (state is ErrorOtpState) _showMessage(context.trMessage(state.message));
    if (state is ForgetPasswordErrorState) {
      _showMessage(context.trMessage(state.message));
    }
    if (state is VerifiedOtpErrorState) {
      _showMessage(context.trMessage(state.message));
    }
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpBloc, OtpState>(
      listener: _onState,
      builder: (context, state) {
        final loading = state is LoadingOtpState;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              context.tr('forgot_password_title'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildCard(loading),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(bool loading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ForgotPasswordHeader(
              step: _step,
              progress: ForgotPasswordProgress(step: _step),
            ),
            const SizedBox(height: 24),
            switch (_step) {
              ForgotPasswordStep.phone => ForgotPasswordPhoneForm(
                controller: _phoneController,
                loading: loading,
                onSubmit: _sendOtp,
              ),
              ForgotPasswordStep.otp => ForgotPasswordOtpForm(
                phone: _phone,
                controller: _otpController,
                loading: loading,
                onVerify: _verifyOtp,
                onResend: _resendOtp,
                onChangeNumber: _goBackToPhone,
              ),
              ForgotPasswordStep.password => ForgotPasswordNewPasswordForm(
                controller: _passwordController,
                loading: loading,
                onSubmit: _resetPassword,
              ),
            },
          ],
        ),
      ),
    );
  }
}
