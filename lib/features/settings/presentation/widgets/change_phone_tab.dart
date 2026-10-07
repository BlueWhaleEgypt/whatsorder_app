import 'package:flutter/material.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
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

          const SizedBox(height: 24),

          TextFormField(
            controller: currentPhoneController,
            enabled: false,
            decoration: _decoration(
              label: 'Current Phone',
              icon: Icons.phone_outlined,
            ),
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: newPhoneController,
            keyboardType: TextInputType.phone,
            decoration: _decoration(
              label: 'New Phone',
              icon: Icons.phone_android_outlined,
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // Change phone API later.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Change Phone',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
