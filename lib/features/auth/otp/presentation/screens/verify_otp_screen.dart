import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:whats_order/core/routing/named_routes.dart';
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
          Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoutes.signin,
            (_) => false,
          );
        }

        if (state is ErrorOtpState) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Verify Phone",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("Enter the verification code sent to\n${widget.phone}"),
                  const SizedBox(height: 40),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Center(
                      child: Pinput(controller: otpController, length: 6),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is LoadingOtpState
                          ? null
                          : () {
                              context.read<OtpBloc>().add(
                                VerifyOtpEvent(
                                  phone: widget.phone,
                                  otp: otpController.text.trim(),
                                ),
                              );
                            },
                      child: state is LoadingOtpState
                          ? const CircularProgressIndicator()
                          : const Text("Verify"),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<OtpBloc>().add(SendOtpEvent(widget.phone));
                    },
                    child: const Text("Resend Code"),
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
