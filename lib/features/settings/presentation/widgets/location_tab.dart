import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

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

  @override
  Widget build(BuildContext context) {
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
                child: AppTextField(
                  label: context.tr("city"),
                  hint: context.tr("city"),
                  controller: cityController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: context.tr("state"),
                  hint: context.tr("state"),
                  controller: stateController,
                ),
              ),
            ],
          ),


          const SizedBox(height: 28),
          GradientButton(
            label: context.tr("save_location"),
            // loading: state.isSubmitting,
            onPressed: () {
              // Handle form submission
            },
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
