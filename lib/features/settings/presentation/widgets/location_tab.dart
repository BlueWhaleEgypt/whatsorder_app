import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

class LocationTab extends StatefulWidget {
  final VendorModel vendor;

  const LocationTab({
    super.key,
    required this.vendor,
  });

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

    servingTheEntireArea =
        widget.vendor.servingTheEntireArea ?? false;

    availableInAllRegions =
        widget.vendor.availableInAllRegions ?? false;
  }

  @override
  void dispose() {
    latitudeController.dispose();
    longitudeController.dispose();
    cityController.dispose();
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _field(
                  label: 'Longitude',
                  controller: longitudeController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _field(
                  label: 'City',
                  controller: cityController,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _field(
                  label: 'State',
                  controller: stateController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // _switchTile(
          //   title: 'Serving Entire Governorate',
          //   value: servingTheEntireGovernorate,
          //   onChanged: (value) {
          //     setState(() {
          //       servingTheEntireGovernorate = value;
          //     });
          //   },
          // ),

          // _switchTile(
          //   title: 'Serving Entire Area',
          //   value: servingTheEntireArea,
          //   onChanged: (value) {
          //     setState(() {
          //       servingTheEntireArea = value;
          //     });
          //   },
          // ),

          // _switchTile(
          //   title: 'Available In All Regions',
          //   value: availableInAllRegions,
          //   onChanged: (value) {
          //     setState(() {
          //       availableInAllRegions = value;
          //     });
          //   },
          // ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Update location API later.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Location',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
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

  // Widget _switchTile({
  //   required String title,
  //   required bool value,
  //   required ValueChanged<bool> onChanged,
  // }) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 10),
  //     decoration: BoxDecoration(
  //       color: AppColors.surface,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: AppColors.border,
  //       ),
  //     ),
  //     child: SwitchListTile(
  //       value: value,
  //       onChanged: onChanged,
  //       activeColor: AppColors.primaryGreen,
  //       title: Text(title),
  //     ),
  //   );
  // }
}