import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/gradient_button.dart';
import '../../cubit/onboarding_cubit.dart';
import '../../cubit/onboarding_state.dart';

/*
|--------------------------------------------------------------------------
| UserInfoStep — step 1 of the onboarding wizard ("User Information").
|
| Collects firstName, lastName, email, and the sector (loaded live from
| /api/auth/sector and displayed as a searchable dropdown).
|--------------------------------------------------------------------------
*/

class UserInfoStep extends StatefulWidget {
  const UserInfoStep({super.key});

  @override
  State<UserInfoStep> createState() => _UserInfoStepState();
}

class _UserInfoStepState extends State<UserInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  String? _sectorId;

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingCubit>().state.data;
    _firstName = TextEditingController(text: data.firstName);
    _lastName = TextEditingController(text: data.lastName);
    _email = TextEditingController(text: data.email);
    _sectorId = data.sectorId.isEmpty ? null : data.sectorId;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr("user_information"),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr("user_info_subtitle"),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 22),

                // ── Name row ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: context.tr("first_name"),
                        required: true,
                        hint: context.tr("first_name"),
                        controller: _firstName,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: context.tr("last_name"),
                        hint: context.tr("last_name"),
                        controller: _lastName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Email ──────────────────────────────────────────────
                AppTextField(
                  label: context.tr("email"),
                  required: true,
                  hint: "you@example.com",
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return context.tr("email_is_required");
                    if (!v.contains('@'))
                      return context.tr("enter_a_valid_email");
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Sector dropdown ────────────────────────────────────
                _SectorDropdown(
                  sectors: state.sectors,
                  loading: state.sectorsLoading,
                  error: state.sectorsError,
                  value: _sectorId,
                  onChanged: (v) => setState(() => _sectorId = v),
                  onRetry: () => context.read<OnboardingCubit>().loadSectors(),
                ),
                const SizedBox(height: 28),

                GradientButton(
                  label: context.tr("continue"),
                  trailingIcon: Icons.arrow_forward,
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    if (_sectorId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr("sector_is_required")),
                        ),
                      );
                      return;
                    }
                    context.read<OnboardingCubit>().updateInfo(
                      firstName: _firstName.text.trim(),
                      lastName: _lastName.text.trim(),
                      email: _email.text.trim(),
                      sectorId: _sectorId!,
                    );
                    context.read<OnboardingCubit>().nextStep();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sector Dropdown Widget ─────────────────────────────────────────────────

class _SectorDropdown extends StatelessWidget {
  final List sectors;
  final bool loading;
  final String? error;
  final String? value;
  final ValueChanged<String?> onChanged;
  final VoidCallback onRetry;

  const _SectorDropdown({
    required this.sectors,
    required this.loading,
    required this.error,
    required this.value,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: context.tr("your_sector"),
            style: const TextStyle(
              fontFamily: "Cairo",
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textGrey,
              letterSpacing: 0.3,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.danger),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (loading)
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.lightGreenBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          )
        else if (error != null)
          GestureDetector(
            onTap: onRetry,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.refresh, color: AppColors.danger, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Failed to load sectors — tap to retry",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.danger.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: value,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            isExpanded: true,
            items: sectors
                .map(
                  (s) => DropdownMenuItem<String>(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            hint: Text(
              context.tr("select_your_sector"),
              style: const TextStyle(fontSize: 13, fontFamily: "Cairo"),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.lightGreenBg.withOpacity(0.6),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryGreen,
                  width: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
