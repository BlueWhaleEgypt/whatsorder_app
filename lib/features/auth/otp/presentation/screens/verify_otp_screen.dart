import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_state.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.phone});

  final String phone;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state is VerifiedOtpState) {
          final token = CacheHelper.getDataFromSharedPreference(
            key: CacheKeys.accessToken,
          );

          if (token != null && token.toString().isNotEmpty) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(NamedRoutes.home, (r) => false);
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              NamedRoutes.signin,
              (_) => false,
            );
          }
          // Navigator.pushNamedAndRemoveUntil(
          //   context,
          //   NamedRoutes.signin,
          //   (_) => false,
          // );
        }

        if (state is ErrorOtpState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trMessage(state.message))),
          );
        }
      },
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
              context.tr('fp_otp_title'),
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
                      child: _buildCard(context, state, loading),
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

  Widget _buildCard(BuildContext context, OtpState state, bool loading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: AppColors.lightGreenBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sms_outlined,
                size: 32,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('fp_otp_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('fp_otp_desc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 14),
          // Phone numbers always read left-to-right, even in Arabic.
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightGreenBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                widget.phone,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Pinput(
                controller: otpController,
                length: 6,
                enabled: !loading,
                keyboardType: TextInputType.number,
                forceErrorState: state is ErrorOtpState,
                defaultPinTheme: _pinTheme(),
                focusedPinTheme: _pinTheme(
                  border: AppColors.primaryGreen,
                  width: 1.6,
                ),
                submittedPinTheme: _pinTheme(
                  border: AppColors.primaryGreen,
                  fill: AppColors.lightGreenBg,
                ),
                errorPinTheme: _pinTheme(border: AppColors.danger),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: context.tr('Verify_OTP'),
            loading: loading,
            onPressed: loading
                ? null
                : () {
                    context.read<OtpBloc>().add(
                      VerifyOtpEvent(
                        phone: widget.phone,
                        otp: otpController.text.trim(),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.tr('didnt_get_code'),
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textGrey,
                ),
              ),
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                        context.read<OtpBloc>().add(SendOtpEvent(widget.phone));
                      },
                child: Text(
                  context.tr('resend_code'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: loading
                        ? AppColors.textFaint
                        : AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PinTheme _pinTheme({
    Color border = AppColors.border,
    Color fill = AppColors.surface,
    double width = 1,
  }) {
    return PinTheme(
      width: 46,
      height: 54,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: width),
      ),
    );
  }
}
