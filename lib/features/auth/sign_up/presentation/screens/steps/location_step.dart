import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/features/auth/sign_up/presentation/screens/widgets/map_picker_page.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_text_field.dart';
import '../../../../../../core/widgets/gradient_button.dart';
import '../../../../../../core/theme/app_text_styles.dart';
import '../../../data/onboarding_data.dart';
import '../../cubit/onboarding_cubit.dart';

/*
|--------------------------------------------------------------------------
| LocationStep — step 2 of the onboarding wizard ("Your Location").
|--------------------------------------------------------------------------
*/

class LocationStep extends StatefulWidget {
  const LocationStep({super.key});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  late final TextEditingController _governorate;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _street;
  late final TextEditingController _building;
  late final TextEditingController _area;
  late final TextEditingController _neighborhood;
  late final TextEditingController _serviceDistance;
  ServiceArea? _serviceArea;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final data = context.read<OnboardingCubit>().state.data;
    _governorate = TextEditingController(text: data.governorate);
    _city = TextEditingController(text: data.city);
    _state = TextEditingController(text: data.state);
    _street = TextEditingController(text: data.street);
    _building = TextEditingController(text: data.building);
    _area = TextEditingController(text: data.area);
    _neighborhood = TextEditingController(text: data.neighborhood);
    _serviceArea = data.serviceArea;
    _lat = data.latitude;
    _lng = data.longitude;
    _serviceDistance = TextEditingController(
      text: data.serviceDistance?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    for (final c in [
      _governorate,
      _city,
      _state,
      _street,
      _building,
      _area,
      _neighborhood,
    ]) {
      c.dispose();
    }
    _serviceDistance.dispose();
    super.dispose();
  }

  void _commitAndContinue() {
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("location_is_required"))),
      );
      return;
    }
    if (_serviceArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("service_area_is_required"))),
      );
      return;
    }

    context.read<OnboardingCubit>().updateLocation(
      governorate: _governorate.text.trim(),
      city: _city.text.trim(),
      state_: _state.text.trim(),
      street: _street.text.trim(),
      building: _building.text.trim(),
      area: _area.text.trim(),
      neighborhood: _neighborhood.text.trim(),
      serviceArea: _serviceArea,
      latitude: _lat,
      longitude: _lng,
      serviceDistance: double.tryParse(_serviceDistance.text.trim()),
    );
    context.read<OnboardingCubit>().nextStep();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("your_location"),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr("location_subtitle"),
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 18),
          _MapPickerField(
            hasLocation: _lat != null,
            onTap: () async {
              final LatLng? location = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapPickerPage()),
              );

              if (location == null) return;

              setState(() {
                _lat = location.latitude;
                _lng = location.longitude;
              });

              try {
                final placemarks = await placemarkFromCoordinates(
                  location.latitude,
                  location.longitude,
                );

                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  logger.i("""
 _lat = <${location.latitude}>,;
                _lng = <<${location.longitude}>>;
Name: ${place.name}
Street: ${place.street}
SubLocality: ${place.subLocality}
Locality: ${place.locality}
SubAdministrativeArea: ${place.subAdministrativeArea}
AdministrativeArea: ${place.administrativeArea}
PostalCode: ${place.postalCode}
Country: ${place.country}
""");
                  setState(() {
                    _city.text = place.locality ?? '';
                    _state.text = place.administrativeArea ?? '';
                    // _street.text = place.street ?? '';
                    // _area.text = place.subLocality ?? '';
                    // _neighborhood.text = place.subLocality ?? '';
                    // _governorate.text = place.administrativeArea ?? '';
                  });
                  logger.w("""
Fields Updated:
Governorate: ${_governorate.text}
City: ${_city.text}
State: ${_state.text}
Street: ${_street.text}
Area: ${_area.text}
Neighborhood: ${_neighborhood.text}
""");
                }
              } catch (e) {
                logger.e(e);
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: context.tr("city"),
                  hint: context.tr("city"),
                  controller: _city,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: context.tr("state"),
                  hint: context.tr("state"),
                  controller: _state,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: context.tr("street"),
                  hint: context.tr("street"),
                  controller: _street,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: context.tr("building"),
                  hint: context.tr("building"),
                  controller: _building,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: context.tr("area"),
                  hint: context.tr("area"),
                  controller: _area,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: context.tr("neighborhood"),
                  hint: context.tr("neighborhood"),
                  controller: _neighborhood,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ServiceAreaCard(
            value: _serviceArea,
            // onChanged: (v) => setState(() => _serviceArea = v),
            onChanged: _onServiceAreaChanged,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _serviceDistance,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                final value = double.tryParse(newValue.text);

                if (value == null || value <= 50) {
                  return newValue;
                }

                return oldValue;
              }),
            ],
            label: context.tr("service_distance"),
            hint: "50",
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                widthFactor: 1.0,
                child: Text(
                  "KM",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
          GradientButton(
            label: context.tr("continue"),
            trailingIcon: Icons.arrow_forward,
            onPressed: _commitAndContinue,
          ),
        ],
      ),
    );
  }

  void _onServiceAreaChanged(ServiceArea area) {
    setState(() {
      _serviceArea = area;

      const defaults = {
        ServiceArea.governorate: 20.0,
        ServiceArea.area: 7.0,
        ServiceArea.allRegions: 30.0,
      };

      _serviceDistance.text = defaults[area]!.toStringAsFixed(0);
    });
  }
}

class _MapPickerField extends StatelessWidget {
  final bool hasLocation;
  final VoidCallback onTap;

  const _MapPickerField({required this.hasLocation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr("location_label"),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textGrey,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.lightGreenBg.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  hasLocation ? Icons.check_circle : Icons.map_outlined,
                  size: 18,
                  color: hasLocation
                      ? AppColors.primaryGreen
                      : AppColors.textGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  hasLocation
                      ? context.tr("location_selected")
                      : context.tr("choose_on_map"),
                  style: TextStyle(
                    fontSize: 14,
                    color: hasLocation
                        ? AppColors.textDark
                        : AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceAreaCard extends StatelessWidget {
  final ServiceArea? value;
  final ValueChanged<ServiceArea> onChanged;

  const _ServiceAreaCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreenBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("service_area_title"),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: AppColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 10),
          _OptionRow(
            label: context.tr("serving_governorate"),
            selected: value == ServiceArea.governorate,
            onTap: () => onChanged(ServiceArea.governorate),
          ),
          _OptionRow(
            label: context.tr("serving_area"),
            selected: value == ServiceArea.area,
            onTap: () => onChanged(ServiceArea.area),
          ),
          _OptionRow(
            label: context.tr("serving_all_regions"),
            selected: value == ServiceArea.allRegions,
            onTap: () => onChanged(ServiceArea.allRegions),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: selected ? AppColors.primaryGreen : AppColors.border,
                  width: 1.4,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.cellText13),
          ],
        ),
      ),
    );
  }
}
