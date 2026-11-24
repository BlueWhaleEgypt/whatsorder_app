import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/orders/presentation/screens/account_verification_screen.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_confirmation_dialog.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/settings/data/profile/update_profile_request.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/update_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';

/*
|--------------------------------------------------------------------------
| StoreProfileScreen — edit the store's logo, name and "about" text.
|
| The save endpoint needs the whole store record (slug, address, hours,
| fee, days), so the loaded profile is kept and only the edited fields are
| replaced before sending.
|--------------------------------------------------------------------------
*/

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  static const _maxAbout = 300;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _name = TextEditingController();
  final _about = TextEditingController();

  VendorModel? _vendor; // last loaded vendor
  File? _logo; // newly picked, not yet uploaded

  @override
  void initState() {
    super.initState();
    _about.addListener(() => setState(() {}));
    context.read<VendorBloc>().add(const FetchVendorEvent());
  }

  void _fill(VendorModel v) {
    _vendor = v;
    _name.text = v.storeName ?? '';
    _about.text = v.storeAbout ?? '';
    _logo = null;
  }

  @override
  void dispose() {
    for (final c in [_name, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Changing the store photo needs a verified account (by the status cached
  /// after the last vendor fetch); otherwise offers to verify it first.
  Future<bool> _ensureVerified() async {
    final isVerified =
        CacheHelper.getDataFromSharedPreference(
          key: CacheKeys.verificationStatus,
        ) ==
        'Verified';
    if (isVerified) return true;

    final verify = await showSettingsConfirmationDialog(
      context,
      title: context.tr('store_profile'),
      message: context.tr('store_photo_requires_verification'),
      iconAsset: null,
      color: AppColors.primaryGreen,
      confirmLabel: context.tr('verify_account'),
    );
    if (verify == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AccountVerificationScreen()),
      );
    }
    return false;
  }

  Future<void> _pickLogo() async {
    if (!await _ensureVerified()) return;
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _logo = File(x.path));
  }

  void _save() {
    final vendor = _vendor;
    if (vendor == null || !_formKey.currentState!.validate()) return;
    context.read<UpdateProfileBloc>().add(
      SubmitUpdateProfileEvent(
        request: UpdateProfileRequest.fromVendor(
          userId: vendor.id ?? '',
          vendor: vendor,
          storeName: _name.text.trim(),
          storeAbout: _about.text.trim(),
          storePhoto: _logo,
        ),
      ),
    );
  }

  void _onUpdateState(BuildContext context, UpdateProfileState state) {
    final messenger = ScaffoldMessenger.of(context);
    if (state is UpdateProfileSuccess) {
      context.read<VendorBloc>().add(const FetchVendorEvent());
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.tr('sp_saved')),
          backgroundColor: AppColors.primaryGreenTint,
        ),
      );
    } else if (state is UpdateProfileError) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.trMessage(state.message)),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('field_required') : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(
          context.tr('store_profile'),
          style: AppTextStyles.heading18,
        ),
      ),
      body: BlocListener<UpdateProfileBloc, UpdateProfileState>(
        listener: _onUpdateState,
        child: BlocConsumer<VendorBloc, VendorState>(
          listener: (context, state) {
            if (state is VendorLoaded && state.vendorResponse.vendor != null) {
              setState(() => _fill(state.vendorResponse.vendor!));
            }
          },
          builder: (context, state) {
            if (_vendor == null) {
              if (state is VendorError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.trMessage(state.message)),
                      TextButton(
                        onPressed: () => context.read<VendorBloc>().add(
                          const FetchVendorEvent(),
                        ),
                        child: Text(context.tr('retry')),
                      ),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            final saving =
                context.watch<UpdateProfileBloc>().state
                    is UpdateProfileLoading;
            return SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Store identity ──────────────────────────────────────────
                    _SectionCard(
                      title: context.tr('sp_identity'),
                      subtitle: context.tr('sp_identity_sub'),
                      children: [
                        _LogoRow(
                          file: _logo,
                          url: (_vendor!.storePhoto ?? '').isEmpty
                              ? null
                              : '${EndPoints.baseUrl}/uploads/${Uri.encodeComponent(_vendor!.storePhoto!)}',
                          onChange: _pickLogo,
                          onRemove: () => setState(() => _logo = null),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mapGreenLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryGreenLight,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB800),
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('sp_rating'),
                                style: AppTextStyles.cellText13.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                (_vendor!.rate ?? 0).toStringAsFixed(1),
                                style: AppTextStyles.cardTitle15.copyWith(
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: context.tr('sp_store_name'),
                          required: true,
                          controller: _name,
                          validator: _required,
                          maxLength: 100,
                        ),
                        const SizedBox(height: 14),
                        AppTextField(
                          label: context.tr('sp_about'),
                          controller: _about,
                          maxLines: 4,
                          maxLength: _maxAbout,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('sp_about_hint', {
                            'count': '${_about.text.length}',
                            'max': '$_maxAbout',
                          }),
                          style: AppTextStyles.cellMuted13.copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    GradientButton(
                      label: context.tr('sp_save'),
                      loading: saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────────── helpers ─────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading18),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.cellMuted13),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _LogoRow extends StatelessWidget {
  final File? file;
  final String? url;
  final VoidCallback onChange;
  final VoidCallback onRemove;
  const _LogoRow({
    required this.file,
    required this.url,
    required this.onChange,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: AppColors.editIconBg,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: file != null
              ? Image.file(file!, fit: BoxFit.cover)
              : url != null
              ? Image.network(
                  url!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primaryGreen,
                    size: 28,
                  ),
                )
              : const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('sp_logo'),
                style: AppTextStyles.cellText13.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('sp_logo_hint'),
                style: AppTextStyles.cellMuted13.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onChange,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryGreen,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(context.tr('sp_change')),
        ),
        if (file != null)
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.tr('sp_remove')),
          ),
      ],
    );
  }
}
