import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

class ChangePhoneTab extends StatefulWidget {
  final VendorModel vendor;

  const ChangePhoneTab({super.key, required this.vendor});

  @override
  State<ChangePhoneTab> createState() => _ChangePhoneTabState();
}

class _ChangePhoneTabState extends State<ChangePhoneTab> {
  late final TextEditingController currentPhoneController;
  final newPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    currentPhoneController = TextEditingController(
      text: widget.vendor.phone ?? '',
    );
  }

  @override
  void dispose() {
    currentPhoneController.dispose();
    newPhoneController.dispose();
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
            context.tr("update_the_phone_number"),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 28),

          AppTextField(
            label: context.tr('new_phone'),
            required: true,
            hint: context.tr('phone_hint_signin'),
            controller: newPhoneController,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 28),
          GradientButton(
            label: context.tr("change_phone"),
            // loading: state.isSubmitting,
            onPressed: () {
              // Handle form submission
            },
          ),
        ],
      ),
    );
  }
}
