import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/top_bar_pills.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import 'steps/location_step.dart';
import 'steps/upload_files_step.dart';
import 'steps/user_info_step.dart';
import 'widgets/stepper_header.dart';

/*
|--------------------------------------------------------------------------
| OnboardingScreen — hosts the 3-step wizard (Info → Location → Files).
|
| Accepts the phone + password entered on SignUpScreen so the cubit can
| carry them through all steps and include them in the final single-call
| POST /api/auth/signup.
|
| On creation it immediately:
|   1. Calls setInitialCredentials() on the cubit.
|   2. Calls loadSectors() to populate the sector dropdown in step 1.
|--------------------------------------------------------------------------
*/

class OnboardingScreen extends StatelessWidget {
  final String phone;
  final String password;

  const OnboardingScreen({
    super.key,
    required this.phone,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = OnboardingCubit();
        cubit.setInitialCredentials(phone: phone, password: password);
        cubit.loadSectors();
        return cubit;
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SafeArea(
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            builder: (context, state) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (state.currentStep > 0)
                              IconButton(
                                onPressed: () => context
                                    .read<OnboardingCubit>()
                                    .previousStep(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 16,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            if (state.currentStep > 0)
                              const SizedBox(width: 12),
                            const Expanded(child: TopBarPills()),
                          ],
                        ),
                        const SizedBox(height: 18),
                        StepperHeader(currentStep: state.currentStep),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _stepFor(state.currentStep),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stepFor(int step) {
    switch (step) {
      case 0:
        return const UserInfoStep(key: ValueKey('info'));
      case 1:
        return const LocationStep(key: ValueKey('location'));
      default:
        return const UploadFilesStep(key: ValueKey('files'));
    }
  }
}
