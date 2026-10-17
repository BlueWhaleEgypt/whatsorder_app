import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whats_order/core/cache/profile_name.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/utils/pdf_export.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/orders_state.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/orders/presentation/screens/account_verification_screen.dart';

/// Green welcome banner: greeting with the profile first name, account
/// verification status and the PDF export action.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    // final user = UserModel.fromJson(
    //   jsonDecode(
    //     CacheHelper.getDataFromSharedPreference(key: CacheKeys.userModel) ??
    //         '{}',
    //   ),
    // );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreenShade, AppColors.primaryGreenTint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: ProfileName.firstName,
                  builder: (_, name, __) => Text(
                    "${context.tr("welcome")} ${name.isEmpty ? 'UserName' : name}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr("welcome_subtitle"),
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                BlocBuilder<VendorBloc, VendorState>(
                  builder: (context, state) {
                    if (state is VendorLoaded) {
                      final verificationStatus =
                          state.vendorResponse.vendor?.verificationStatus;

                      final isVerified = verificationStatus == 'Verified';
                      return Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: InkWell(
                          onTap: isVerified
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AccountVerificationScreen(),
                                    ),
                                  );
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isVerified) ...[
                                  Container(
                                    width: 30,
                                    height: 30,
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: AppColors.border,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: SvgPicture.asset(
                                        AppAssets.baselineVerified,
                                        colorFilter: const ColorFilter.mode(
                                          Color.fromARGB(255, 0, 136, 214),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  isVerified
                                      ? context.tr("account_verified")
                                      : context.tr("account_not_verified"),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (!isVerified) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final state = context.read<OrdersBloc>().state;

              if (state is! LoadedOrdersState) return;

              final selectedOrders = state.response.orders
                  .where((order) => order.isChecked)
                  .toList();

              if (selectedOrders.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr("select_at_least_one_order")),
                  ),
                );
                return;
              }

              await PdfExport.exportOrders(selectedOrders);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr("orders_exported_successfully")),
                ),
              );
            },
            icon: const Icon(
              Icons.file_download_outlined,
              color: Colors.white,
              size: 16,
            ),
            label: Text(
              context.tr("export"),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              backgroundColor: Colors.white.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}
