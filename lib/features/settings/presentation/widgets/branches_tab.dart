import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // LatLng
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/map_picker_field.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import 'package:whats_order/features/auth/sign_up/presentation/screens/widgets/map_picker_page.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/data/branch_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_state.dart';

import '../../../../core/utils/logger.dart';
// import '.../map_picker_field.dart';   // MapPickerField
// import '.../map_picker_page.dart';    // MapPickerPage
// import '.../logger.dart';             // logger

class BranchesTab extends StatefulWidget {
  final VendorModel vendor;

  const BranchesTab({super.key, required this.vendor});

  @override
  State<BranchesTab> createState() => _BranchesTabState();
}

class _BranchesTabState extends State<BranchesTab> {
  String _userId = '';

  @override
  void initState() {
    super.initState();

    final cachedUser = CacheHelper.getDataFromSharedPreference(
      key: CacheKeys.userModel,
    );

    if (cachedUser != null && cachedUser.isNotEmpty) {
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(cachedUser) as Map),
      );
      _userId = user.id?.toString() ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to identify the current user')),
        );
        return;
      }

      context.read<BranchesBloc>().add(FetchBranchesEvent(userId: _userId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('branches_description'),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('branches'),
                  style: AppTextStyles.cardTitle15,
                ),
              ),
              FilledButton.icon(
                onPressed: _userId.isEmpty ? null : () => _showBranchForm(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('add_branch')),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocConsumer<BranchesBloc, BranchesState>(
            listener: (context, state) {
              if (state is BranchesActionSuccessState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr(state.message))),
                );
              } else if (state is BranchesErrorState) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              if (state is BranchesLoadingState ||
                  state is BranchesInitialState) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final branches = switch (state) {
                BranchesLoadedState s => s.branches,
                BranchesActionLoadingState s => s.branches,
                BranchesActionSuccessState s => s.branches,
                BranchesErrorState s => s.branches,
                _ => <BranchModel>[],
              };

              if (branches.isEmpty && state is! BranchesActionLoadingState) {
                return _emptyState(context);
              }

              return Column(
                children: [
                  if (state is BranchesActionLoadingState)
                    const LinearProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ...branches.map((branch) => _branchCard(context, branch)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Branch card ─────────────────────────

  Widget _branchCard(BuildContext context, BranchModel branch) {
    final title = branch.name.isNotEmpty ? branch.name : branch.nameEn;
    final showSubtitle = branch.name.isNotEmpty && branch.nameEn.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          top: BorderSide(color: AppColors.primaryGreen, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.09),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryGreen.withOpacity(.07),
                    AppColors.surface,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SvgPicture.asset(
                      AppAssets.store,
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primaryGreenTint,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.cardTitle15),
                        if (showSubtitle) ...[
                          const SizedBox(height: 3),
                          Text(branch.nameEn, style: AppTextStyles.cellMuted13),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Address chip
            if (branch.address.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          branch.address,
                          style: AppTextStyles.heading18.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showBranchForm(branch: branch),
                      icon: SvgPicture.asset(
                        AppAssets.edit,
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primaryGreenTint,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(context.tr('edit')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        backgroundColor: AppColors.primaryGreen.withOpacity(
                          .04,
                        ),
                        side: BorderSide(
                          color: AppColors.primaryGreen.withOpacity(.25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(branch),
                      icon: SvgPicture.asset(
                        AppAssets.delete,
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.danger,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: Text(context.tr('delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.withOpacity(.04),
                        side: BorderSide(color: Colors.red.withOpacity(.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.store_outlined, size: 42, color: AppColors.textGrey),
          const SizedBox(height: 12),
          Text(
            context.tr('no_branches_available'),
            style: const TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Add / Edit form ─────────────────────────

  Future<void> _showBranchForm({BranchModel? branch}) async {
    final result = await showDialog<BranchModel>(
      context: context,
      builder: (_) => _BranchFormDialog(branch: branch),
    );

    if (result == null || !mounted) return;

    final bloc = context.read<BranchesBloc>();

    if (branch == null) {
      bloc.add(AddBranchEvent(userId: _userId, branch: result));
    } else {
      bloc.add(
        UpdateBranchEvent(userId: _userId, branchId: branch.id, branch: result),
      );
    }
  }

  Future<void> _confirmDelete(BranchModel branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('delete_branch')),
        content: Text('${context.tr('confirm_delete_branch')} ${branch.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<BranchesBloc>().add(
        DeleteBranchEvent(userId: _userId, branchId: branch.id),
      );
    }
  }
}

// ───────────────────────── Branch form dialog ─────────────────────────

class _BranchFormDialog extends StatefulWidget {
  final BranchModel? branch;

  const _BranchFormDialog({this.branch});

  @override
  State<_BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<_BranchFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _addressController;

  double? _lat;
  double? _lng;
  bool _locationError = false;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _nameController = TextEditingController(text: b?.name ?? '');
    _nameEnController = TextEditingController(text: b?.nameEn ?? '');
    _addressController = TextEditingController(text: b?.address ?? '');
    _lat = b?.latitude;
    _lng = b?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameEnController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final LatLng? location = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );

    if (location == null || !mounted) return;

    setState(() {
      _lat = location.latitude;
      _lng = location.longitude;
      _locationError = false;
      _loadingAddress = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        _addressController.text = _buildAddress(placemarks.first);
      }
    } catch (e) {
      logger.e(e);
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  /// يبني العنوان من الـ placemark ويشيل القيم الفاضية والمكررة
  String _buildAddress(Placemark p) {
    final parts = <String>[];
    for (final v in [
      p.street,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.postalCode,
      p.country,
    ]) {
      final s = v?.trim() ?? '';
      if (s.isNotEmpty && !parts.contains(s)) parts.add(s);
    }
    return parts.join(', ');
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();

    if (_lat == null || _lng == null) {
      setState(() => _locationError = true);
      return;
    }
    if (!valid) return;

    Navigator.pop(
      context,
      BranchModel(
        id: widget.branch?.id ?? '',
        name: _nameController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        latitude: _lat!,
        longitude: _lng!,
        address: _addressController.text.trim(),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.tr('required_field');
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdd = widget.branch == null;

    return AlertDialog(
      title: Text(context.tr(isAdd ? 'add_branch' : 'edit_branch')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(_nameController, context.tr('branch_name_ar')),
                _field(_nameEnController, context.tr('branch_name_en')),
                MapPickerField(
                  hasLocation: _lat != null && _lng != null,
                  onTap: _pickLocation,
                ),
                if (_locationError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      context.tr('invalid_coordinates'),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                if (_loadingAddress)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                _field(_addressController, context.tr('address')),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.tr(isAdd ? 'add' : 'save')),
        ),
      ],
    );
  }
}
