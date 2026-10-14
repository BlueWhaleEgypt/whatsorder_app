import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/core/widgets/map_picker_field.dart';
import 'package:whats_order/features/auth/sign_up/presentation/screens/widgets/map_picker_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/data/profile/update_profile_request.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/update_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';

class LocationTab extends StatefulWidget {
  final VendorModel vendor;

  const LocationTab({super.key, required this.vendor});

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  late final TextEditingController latitudeController;
  late final TextEditingController longitudeController;
  late final TextEditingController cityController;
  late final TextEditingController stateController;
  late final TextEditingController serviceDistanceController;

  late bool servingTheEntireGovernorate;
  late bool servingTheEntireArea;
  late bool availableInAllRegions;

  bool _isEditing = false;

  // Last saved values, restored when the user cancels.
  late Map<String, String> _savedTexts;
  late List<bool> _savedSwitches;

  @override
  void initState() {
    super.initState();

    latitudeController = TextEditingController(
      text: widget.vendor.latitude?.toString() ?? '',
    );
    longitudeController = TextEditingController(
      text: widget.vendor.longitude?.toString() ?? '',
    );
    cityController = TextEditingController(
      text: widget.vendor.city?.trim() ?? '',
    );
    stateController = TextEditingController(
      text: widget.vendor.state?.trim() ?? '',
    );

    serviceDistanceController = TextEditingController(
      text: widget.vendor.serviceDistance?.toString() ?? '',
    );

    servingTheEntireGovernorate =
        widget.vendor.servingTheEntireGovernorate ?? false;
    servingTheEntireArea = widget.vendor.servingTheEntireArea ?? false;
    availableInAllRegions = widget.vendor.availableInAllRegions ?? false;

    _snapshot();
  }

  @override
  void didUpdateWidget(covariant LocationTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Refreshed vendor arrived: show saved values unless the user is mid-edit.
    if (widget.vendor != oldWidget.vendor && !_isEditing) {
      latitudeController.text = widget.vendor.latitude?.toString() ?? '';
      longitudeController.text = widget.vendor.longitude?.toString() ?? '';
      cityController.text = widget.vendor.city?.trim() ?? '';
      stateController.text = widget.vendor.state?.trim() ?? '';
      serviceDistanceController.text =
          widget.vendor.serviceDistance?.toString() ?? '';
      servingTheEntireGovernorate =
          widget.vendor.servingTheEntireGovernorate ?? false;
      servingTheEntireArea = widget.vendor.servingTheEntireArea ?? false;
      availableInAllRegions = widget.vendor.availableInAllRegions ?? false;
      _snapshot();
    }
  }

  void _snapshot() {
    _savedTexts = {
      'lat': latitudeController.text,
      'lng': longitudeController.text,
      'city': cityController.text,
      'state': stateController.text,
      'distance': serviceDistanceController.text,
    };
    _savedSwitches = [
      servingTheEntireGovernorate,
      servingTheEntireArea,
      availableInAllRegions,
    ];
  }

  void _cancelEdit() {
    setState(() {
      latitudeController.text = _savedTexts['lat']!;
      longitudeController.text = _savedTexts['lng']!;
      cityController.text = _savedTexts['city']!;
      stateController.text = _savedTexts['state']!;
      serviceDistanceController.text = _savedTexts['distance']!;
      servingTheEntireGovernorate = _savedSwitches[0];
      servingTheEntireArea = _savedSwitches[1];
      availableInAllRegions = _savedSwitches[2];
      _isEditing = false;
    });
  }

  @override
  void dispose() {
    latitudeController.dispose();
    longitudeController.dispose();
    cityController.dispose();
    stateController.dispose();
    serviceDistanceController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final lat = double.tryParse(latitudeController.text.trim());
    final lng = double.tryParse(longitudeController.text.trim());

    final LatLng? location = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLocation: lat != null && lng != null ? LatLng(lat, lng) : null,
        ),
      ),
    );

    if (location == null || !mounted) return;

    setState(() {
      latitudeController.text = location.latitude.toString();
      longitudeController.text = location.longitude.toString();
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        setState(() {
          cityController.text = place.locality ?? '';
          stateController.text = place.administrativeArea ?? '';
        });
      }
    } catch (e) {
      logger.e(e);
    }
  }

  void _saveLocation() {
    final userId = widget.vendor.id.toString();

    if (userId.isEmpty || userId == 'null') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('user_id_not_found'))));
      return;
    }

    final latitude = double.tryParse(latitudeController.text.trim());
    final longitude = double.tryParse(longitudeController.text.trim());
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('location_is_required'))),
      );
      return;
    }

    final serviceDistance = double.tryParse(
      serviceDistanceController.text.trim(),
    );

    context.read<UpdateProfileBloc>().add(
      SubmitUpdateProfileEvent(
        request: UpdateProfileRequest.fromVendor(
          userId: userId,
          vendor: widget.vendor,
          overrides: {
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
            if (serviceDistance != null) 'serviceDistance': serviceDistance,
            'city': cityController.text.trim(),
            'state': stateController.text.trim(),
            'servingTheEntireGovernorate': servingTheEntireGovernorate,
            'servingTheEntireArea': servingTheEntireArea,
            'availableInAllRegions': availableInAllRegions,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateProfileBloc, UpdateProfileState>(
      listener: (context, state) {
        if (state is UpdateProfileSuccess) {
          setState(() {
            _snapshot();
            _isEditing = false;
          });
        }
        if (state is UpdateProfileSuccess || state is UpdateProfileError) {
          final message = state is UpdateProfileSuccess
              ? context.trMessage(state.message)
              : context.trMessage((state as UpdateProfileError).message);

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is UpdateProfileLoading;
        final canEdit = _isEditing && !isLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('manage_location'),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              MapPickerField(
                hasLocation:
                    double.tryParse(latitudeController.text.trim()) != null &&
                    double.tryParse(longitudeController.text.trim()) != null,
                onTap: canEdit ? _pickLocation : () {},
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      label: context.tr('latitude'),
                      controller: latitudeController,
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _field(
                      label: context.tr('longitude'),
                      controller: longitudeController,
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: context.tr('city'),
                      hint: context.tr('city'),
                      controller: cityController,
                      enabled: canEdit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: context.tr('state'),
                      hint: context.tr('state'),
                      controller: stateController,
                      enabled: canEdit,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              AppTextField(
                controller: serviceDistanceController,
                enabled: canEdit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final value = double.tryParse(newValue.text);
                    if (value == null || value <= 50) return newValue;
                    return oldValue;
                  }),
                ],
                label: context.tr('service_distance'),
                hint: '50',
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(
                    widthFactor: 1.0,
                    child: Text(
                      'KM',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (!_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: context.tr('edit_label'),
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : _cancelEdit,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(context.tr('cancel')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        label: context.tr('save_location'),
                        loading: isLoading,
                        onPressed: isLoading ? () {} : _saveLocation,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: true,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
