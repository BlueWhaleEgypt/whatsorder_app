import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_state.dart';

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

  final _formKey = GlobalKey<FormState>();

  int currentStep = 0;
  String? userId;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _phone = widget.phone;
    _phoneController.text = widget.phone;
  }

  String _normalizePhone(String phone) {
    phone = phone.trim().replaceAll(' ', '');

    if (phone.startsWith('0')) {
      return '2$phone';
    }

    return phone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state is LoadedOtpState) {
          setState(() {
            currentStep = 1;
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.response.message ?? '')));
        }

        if (state is VerifiedOtpState) {
          userId = state.response.userId;

          setState(() {
            currentStep = 2;
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.response.message ?? '')));
        }

        if (state is ForgetPasswordSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Password changed successfully")),
          );

          Navigator.pop(context);
        }

        if (state is ErrorOtpState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is ForgetPasswordErrorState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is VerifiedOtpErrorState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final loading = state is LoadingOtpState;

        return Scaffold(
          appBar: AppBar(title: const Text("Forgot Password")),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Stepper(
                  currentStep: currentStep,
                  controlsBuilder: (_, __) => const SizedBox(),
                  steps: const [
                    Step(
                      title: Text("Phone"),
                      content: SizedBox(),
                      isActive: true,
                    ),
                    Step(
                      title: Text("OTP"),
                      content: SizedBox(),
                      isActive: true,
                    ),
                    Step(
                      title: Text("New Password"),
                      content: SizedBox(),
                      isActive: true,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (currentStep == 0) ...[
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Enter phone number";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  GradientButton(
                    label: context.tr('Send_OTP'),
                    loading: loading,
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      _phone = _normalizePhone(_phoneController.text);
                      context.read<OtpBloc>().add(SendOtpEvent(_phone));
                    },
                  ),
                ],

                if (currentStep == 1) ...[
                  Text("OTP sent to $_phone"),

                  const SizedBox(height: 20),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Pinput(controller: _otpController, length: 6),
                  ),

                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.read<OtpBloc>().add(SendOtpEvent(_phone));
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Resend code',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  GradientButton(
                    label: context.tr('Verify_OTP'),
                    loading: loading,
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;

                      context.read<OtpBloc>().add(
                        VerifyOtpEvent(
                          phone: _phone,
                          otp: _otpController.text,
                        ),
                      );
                    },
                  ),
                ],

                if (currentStep == 2) ...[
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "New Password",
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return "Minimum 6 characters";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 25),

                  GradientButton(
                    label: context.tr('Reset_Password'),
                    loading: loading,
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      context.read<OtpBloc>().add(
                        ForgetPasswordEvent(
                          userId: userId!,
                          newPassword: _passwordController.text,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
