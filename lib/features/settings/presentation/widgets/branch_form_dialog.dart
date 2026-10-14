import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // LatLng
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/map_picker_field.dart';
import 'package:whats_order/features/auth/sign_up/presentation/screens/widgets/map_picker_page.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_dialog_style.dart';

/// Add (branch == null) / Edit branch form. Pops the resulting [BranchModel],
/// or null when cancelled.
class BranchFormDialog extends StatefulWidget {
  final BranchModel? branch;

  const BranchFormDialog({super.key, this.branch});

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
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
      padding: const EdgeInsets.only(bottom: 16),
      child: AppTextField(
        controller: controller,
        label: label,
        hint: label,
        required: true,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return context.tr('required_field');
          }
          return null;
        },
      ),
    );
  }

  Widget _header(bool isAdd) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(11),
          decoration: const BoxDecoration(
            color: AppColors.lightGreenBg,
            shape: BoxShape.circle,
          ),
          child: SvgPicture.asset(
            AppAssets.stor,
            colorFilter: const ColorFilter.mode(
              AppColors.primaryGreen,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.tr(isAdd ? 'add_branch' : 'edit_branch'),
            style: AppTextStyles.heading18,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdd = widget.branch == null;

    return Dialog(
      backgroundColor: SettingsDialogStyle.background,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: SettingsDialogStyle.shape,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(isAdd),
                const SizedBox(height: 20),
                _field(_nameController, context.tr('branch_name_ar')),
                _field(_nameEnController, context.tr('branch_name_en')),
                MapPickerField(
                  hasLocation: _lat != null && _lng != null,
                  onTap: _pickLocation,
                ),
                if (_locationError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                    child: Text(
                      context.tr('invalid_coordinates'),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (_loadingAddress)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                _field(_addressController, context.tr('address')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(context.tr('cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(context.tr(isAdd ? 'add' : 'save')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [BranchFormDialog]; resolves to the entered branch or null.
Future<BranchModel?> showBranchFormDialog(
  BuildContext context, {
  BranchModel? branch,
}) {
  return showDialog<BranchModel>(
    context: context,
    builder: (_) => BranchFormDialog(branch: branch),
  );
}
