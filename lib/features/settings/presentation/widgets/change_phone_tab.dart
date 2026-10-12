import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/routing/named_routes.dart';
import 'package:whats_order/core/utils/logger.dart';
import 'package:whats_order/core/widgets/app_text_field.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_state.dart';

class ChangePhoneTab extends StatefulWidget {
  final VendorModel vendor;

  const ChangePhoneTab({super.key, required this.vendor});

  @override
  State<ChangePhoneTab> createState() => _ChangePhoneTabState();
}

class _ChangePhoneTabState extends State<ChangePhoneTab> {
  late final TextEditingController currentPhoneController;
  late final TextEditingController newPhoneController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    currentPhoneController = TextEditingController(
      text: widget.vendor.phone ?? '',
    );

    newPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    currentPhoneController.dispose();
    newPhoneController.dispose();
    super.dispose();
  }

  void _submitChangePhone() {
    if (!formKey.currentState!.validate()) return;

    final userId = widget.vendor.id?.toString() ?? '';
    final inputPhone = newPhoneController.text.trim();
    logger.i(
      'Submitting change phone request for userId: $userId, new phone: $inputPhone',
    );
    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID is missing')));
      return;
    }

    final phone = inputPhone.startsWith('20')
        ? inputPhone
        : '20${inputPhone.substring(1)}';

    context.read<ChangePhoneBloc>().add(
      SubmitChangePhoneEvent(userId: userId, phone: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePhoneBloc, ChangePhoneState>(
      listener: (context, state) {
        if (state is ChangePhoneSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone change request sent successfully'),
            ),
          );

          Navigator.pushNamed(
            context,
            NamedRoutes.verifyOtp,
            arguments: newPhoneController.text.trim().startsWith('20')
                ? newPhoneController.text.trim()
                : '20${newPhoneController.text.trim().substring(1)}',
          );
        }

        if (state is ChangePhoneError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is ChangePhoneLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('update_the_phone_number'),
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 28),

                AppTextField(
                  label: context.tr('current_phone'),
                  required: true,
                  hint: context.tr('phone_hint_signin'),
                  controller: currentPhoneController,
                  keyboardType: TextInputType.phone,
                  enabled: false,
                ),

                const SizedBox(height: 28),

                AppTextField(
                  label: context.tr('new_phone'),
                  required: true,
                  hint: context.tr('phone_hint_signin'),
                  controller: newPhoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,

                  validator: (value) {
                    final phone = value?.trim() ?? '';

                    if (phone.isEmpty) {
                      return context.tr('phone_required');
                    }

                    final isLocalPhone = RegExp(r'^01\d{9}$').hasMatch(phone);
                    final isInternationalPhone = RegExp(
                      r'^20\d{10}$',
                    ).hasMatch(phone);

                    if (!isLocalPhone && !isInternationalPhone) {
                      return context.tr('phone_invalid_length');
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: context.tr('change_phone'),
                    loading: isLoading,
                    onPressed: isLoading ? null : _submitChangePhone,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
