import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/utils/account_type.dart';
import 'package:whats_order/core/widgets/account_type_toggle.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_bloc.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_event.dart';
import 'package:whats_order/features/auth/otp/presentation/bloc/otp_state.dart';
import '../../../../../../core/routing/named_routes.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/dashed_upload_box.dart';
import '../../../../../../core/widgets/gradient_button.dart';
import '../../cubit/onboarding_cubit.dart';
import '../../cubit/onboarding_state.dart';

/*
|--------------------------------------------------------------------------
| UploadFilesStep — step 3 of the onboarding wizard ("Upload Files").
|
| An AccountType toggle (Person / Company) sits above the upload section
| and decides which fields are shown, all required:
|
|   Person  -> ID card (face)         *
|              ID card (back)         *
|              Store front photo      *   (commercialRegister field)
|
|   Company -> Commercial register photo * (commercialRegister field)
|
| Tapping "Submit" fires the single unified POST /api/auth/signup call
| via OnboardingCubit.submit(). On success the user is pushed to the
| phone-verification screen (TODO: implement verify endpoint).
|--------------------------------------------------------------------------
*/

class UploadFilesStep extends StatelessWidget {
  const UploadFilesStep({super.key});

  Future<void> _pickImage(
    BuildContext context, {
    required _PickTarget target,
  }) async {
    final cubit = context.read<OnboardingCubit>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;
    final file = File(picked.path);
    switch (target) {
      case _PickTarget.front:
        cubit.updateIdCardFront(file);
        break;
      case _PickTarget.back:
        cubit.updateIdCardBack(file);
        break;
      case _PickTarget.commercial:
        cubit.updateCommercialRegister(file);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<OnboardingCubit, OnboardingState>(
          listener: (context, state) {
            if (state.submitted ||
                (state.submitError?.contains("Phone is already taken") ??
                    false)) {
              context.read<OtpBloc>().add(SendOtpEvent(state.data.phone));
            }

            if (state.submitError != null &&
                !(state.submitError?.contains("Phone is already taken") ??
                    false)) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.submitError!)));
            }
          },
        ),
        BlocListener<OtpBloc, OtpState>(
          listener: (context, state) {
            if (state is LoadedOtpState) {
              Navigator.pushReplacementNamed(
                context,
                NamedRoutes.verifyOtp,
                arguments: context.read<OnboardingCubit>().state.data.phone,
              );
            }

            if (state is ErrorOtpState) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ],
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        listenWhen: (prev, curr) =>
            prev.submitted != curr.submitted ||
            prev.submitError != curr.submitError,
        listener: (_, __) {},
        builder: (context, state) {
          final canSubmit = state.data.isFilesStepValid && !state.isSubmitting;
          final isPerson = state.data.accountType == AccountType.person;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr("upload_files"),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr("upload_files_subtitle"),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Account type toggle (Person / Company) ─────────────
                _FieldLabel(context.tr("account_type") + " *"),
                const SizedBox(height: 8),
                // NOTE: adjust value/onChanged names below if your actual
                // AccountTypeToggle widget (core/widgets/account_type_toggle.dart)
                // exposes a different API — I don't have that file's source.
                AccountTypeToggle(
                  value: state.data.accountType,
                  onChanged: (type) =>
                      context.read<OnboardingCubit>().updateAccountType(type),
                ),
                const SizedBox(height: 22),

                // ID card front/back are required for both person and
                // company (company's ID belongs to the responsible person).
                _FieldLabel(context.tr("id_card_face") + " *"),
                const SizedBox(height: 8),
                DashedUploadBox(
                  file: state.data.idCardFront,
                  onTap: () => _pickImage(context, target: _PickTarget.front),
                ),
                const SizedBox(height: 18),
                _FieldLabel(context.tr("id_card_back") + " *"),
                const SizedBox(height: 8),
                DashedUploadBox(
                  file: state.data.idCardBack,
                  onTap: () => _pickImage(context, target: _PickTarget.back),
                ),
                const SizedBox(height: 18),

                // Third photo's label depends on account type; same field
                // (commercialRegister) either way.
                _FieldLabel(
                  "${isPerson ? context.tr("store_front_photo") : context.tr("commercial_register_photo")} *",
                ),
                const SizedBox(height: 8),
                DashedUploadBox(
                  file: state.data.commercialRegister,
                  onTap: () =>
                      _pickImage(context, target: _PickTarget.commercial),
                ),

                const SizedBox(height: 28),
                GradientButton(
                  label: context.tr("submit"),
                  loading: state.isSubmitting,
                  onPressed: canSubmit
                      ? () => context.read<OnboardingCubit>().submit()
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _PickTarget { front, back, commercial }

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textGrey,
        letterSpacing: 0.3,
      ),
    );
  }
}
