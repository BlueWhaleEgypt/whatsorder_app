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
/// verification badge and the PDF export action.
class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreenTint,
            AppColors.primaryGreenLight,
          ],
          stops: [0, 0.55, 1],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr("welcome_subtitle"),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          // Wraps onto a second line on narrow screens or long labels.
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              BlocBuilder<VendorBloc, VendorState>(
                builder: (context, state) {
                  if (state is! VendorLoaded) return const SizedBox.shrink();

                  final isVerified =
                      state.vendorResponse.vendor?.verificationStatus ==
                      'Verified';
                  return _VerificationBadge(
                    isVerified: isVerified,
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
                  );
                },
              ),
              _ExportButton(
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact status pill: translucent white when verified, amber when not.
class _VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final VoidCallback? onTap;

  const _VerificationBadge({required this.isVerified, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color textColor = isVerified
        ? Colors.white
        : AppColors.pillYellowText;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: isVerified
          ? Colors.white.withValues(alpha: 0.16)
          : AppColors.pillYellow,
      shape: StadiumBorder(
        side: BorderSide(
          color: isVerified
              ? Colors.white.withValues(alpha: 0.3)
              : AppColors.pillYellowText.withValues(alpha: 0.25),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVerified) ...[
                Container(
                  width: 22,
                  height: 22,
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    AppAssets.baselineVerified,
                    colorFilter: const ColorFilter.mode(
                      Color.fromARGB(255, 0, 136, 214),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  isVerified
                      ? context.tr("account_verified")
                      : context.tr("account_not_verified"),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isVerified) ...[
                const SizedBox(width: 6),
                Icon(
                  // Points the way the text flows.
                  isRtl
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  color: textColor,
                  size: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Export action styled as a translucent chip that sits on the green card.
class _ExportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ExportButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(
        Icons.file_download_outlined,
        color: Colors.white,
        size: 18,
      ),
      label: Text(
        context.tr("export"),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 14, 0),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        shape: const StadiumBorder(),
      ),
    );
  }
}
