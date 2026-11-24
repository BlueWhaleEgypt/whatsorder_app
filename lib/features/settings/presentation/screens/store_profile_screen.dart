import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/features/settings/data/store_profile/store_profile_response.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/store_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/store_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/store_profile_bloc.dart';
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

  StoreProfile? _profile; // last loaded / saved record
  File? _logo; // newly picked, not yet uploaded

  @override
  void initState() {
    super.initState();
    _about.addListener(() => setState(() {}));
    context.read<StoreProfileBloc>().add(const LoadStoreProfileEvent());
  }

  void _fill(StoreProfile p) {
    _profile = p;
    _name.text = p.name;
    _about.text = p.about;
    _logo = null;
  }

  @override
  void dispose() {
    for (final c in [_name, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() => _logo = File(x.path));
  }

  void _save() {
    final profile = _profile;
    if (profile == null || !_formKey.currentState!.validate()) return;
    context.read<StoreProfileBloc>().add(
      SaveStoreProfileEvent(
        profile.copyWith(name: _name.text.trim(), about: _about.text.trim()),
        newPhoto: _logo,
      ),
    );
  }

  void _onState(BuildContext context, StoreProfileState state) {
    final messenger = ScaffoldMessenger.of(context);
    if (state is StoreProfileLoaded) {
      setState(() => _fill(state.profile));
    } else if (state is StoreProfileSaved) {
      setState(() => _fill(state.profile));
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.tr('sp_saved')),
          backgroundColor: AppColors.primaryGreenTint,
        ),
      );
    } else if (state is StoreProfileError && state.whileSaving) {
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
      body: BlocConsumer<StoreProfileBloc, StoreProfileState>(
        listener: _onState,
        builder: (context, state) {
          if (_profile == null) {
            if (state is StoreProfileError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(context.trMessage(state.message)),
                    TextButton(
                      onPressed: () => context.read<StoreProfileBloc>().add(
                        const LoadStoreProfileEvent(),
                      ),
                      child: Text(context.tr('retry')),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final saving = state is StoreProfileSaving;
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
                        url: _profile!.photo == null
                            ? null
                            : '${EndPoints.baseUrl}/uploads/${Uri.encodeComponent(_profile!.photo!)}',
                        onChange: _pickLogo,
                        onRemove: () => setState(() => _logo = null),
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
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.editIconBg,
            shape: BoxShape.circle,
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
