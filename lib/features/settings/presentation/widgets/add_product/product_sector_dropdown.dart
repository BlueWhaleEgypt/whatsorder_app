import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_state.dart';
import 'package:whats_order/features/settings/presentation/widgets/add_product/add_product_input_decoration.dart';
import 'package:whats_order/features/settings/presentation/widgets/add_product/product_form_label.dart';

/// Category picker. The sectors come from the [OnboardingCubit] above it.
///
/// The selected value is held by the form field itself; the parent only
/// needs [onChanged] to read it back on submit.
class ProductSectorDropdown extends StatelessWidget {
  static const _loadingHint = LinearProgressIndicator();

  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String> validator;

  const ProductSectorDropdown({
    super.key,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductFormLabel(context.tr('category')),
        BlocBuilder<OnboardingCubit, OnboardingState>(
          buildWhen: (previous, current) =>
              previous.sectors != current.sectors ||
              previous.sectorsLoading != current.sectorsLoading,
          builder: (context, state) {
            return DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: AddProductInputDecoration.plain,
              hint: state.sectorsLoading ? _loadingHint : null,
              items: [
                for (final sector in state.sectors)
                  DropdownMenuItem(
                    value: sector.id,
                    child: Text(sector.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onChanged,
              validator: validator,
            );
          },
        ),
      ],
    );
  }
}
