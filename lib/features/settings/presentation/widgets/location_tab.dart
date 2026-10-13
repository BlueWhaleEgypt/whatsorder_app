
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
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

  late bool servingTheEntireGovernorate;
  late bool servingTheEntireArea;
  late bool availableInAllRegions;

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

    servingTheEntireGovernorate =
        widget.vendor.servingTheEntireGovernorate ?? false;
    servingTheEntireArea = widget.vendor.servingTheEntireArea ?? false;
    availableInAllRegions = widget.vendor.availableInAllRegions ?? false;
  }

  @override
  void dispose() {
    latitudeController.dispose();
    longitudeController.dispose();
    cityController.dispose();
    stateController.dispose();
    super.dispose();
  }



void _saveLocation() {
  final userId = widget.vendor.id.toString();

  if (userId.isEmpty || userId == 'null') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User ID not found')),
    );
    return;
  }

  context.read<UpdateProfileBloc>().add(
    SubmitUpdateProfileEvent(
      request: UpdateProfileRequest.fromVendor(
        userId: userId,
        vendor: widget.vendor,
        overrides: {
          'latitude': latitudeController.text.trim(),
          'longitude': longitudeController.text.trim(),
          'city': cityController.text.trim(),
          'state': stateController.text.trim(),
          'servingTheEntireGovernorate':
              servingTheEntireGovernorate,
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
        if (state is UpdateProfileSuccess ||
            state is UpdateProfileError) {
          final message = state is UpdateProfileSuccess
              ? state.message
              : (state as UpdateProfileError).message;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is UpdateProfileLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('manage_location'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      label: 'Latitude',
                      controller: latitudeController,
                      enabled: !isLoading,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _field(
                      label: 'Longitude',
                      controller: longitudeController,
                      enabled: !isLoading,
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
                      enabled: !isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: context.tr('state'),
                      hint: context.tr('state'),
                      controller: stateController,
                      enabled: !isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Serving entire governorate'),
                value: servingTheEntireGovernorate,
                onChanged: isLoading
                    ? null
                    : (value) => setState(
                          () => servingTheEntireGovernorate = value,
                        ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Serving entire area'),
                value: servingTheEntireArea,
                onChanged: isLoading
                    ? null
                    : (value) => setState(
                          () => servingTheEntireArea = value,
                        ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available in all regions'),
                value: availableInAllRegions,
                onChanged: isLoading
                    ? null
                    : (value) => setState(
                          () => availableInAllRegions = value,
                        ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: isLoading
                      ? context.tr('loading')
                      : context.tr('save_location'),
                  onPressed: isLoading ? () {} : _saveLocation,
                ),
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
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
