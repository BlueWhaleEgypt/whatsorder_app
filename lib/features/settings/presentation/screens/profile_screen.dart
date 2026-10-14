import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/change_phone_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/sectors_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';
import 'package:whats_order/features/settings/presentation/taps/change_phone_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/files_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/location_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/sectores_tap.dart';
import 'package:whats_order/features/settings/presentation/taps/security_tab.dart';
import 'package:whats_order/features/settings/presentation/taps/user_info_tab.dart';
import 'package:whats_order/injection/injection_container.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedIndex = 0;

  // Last loaded vendor: while a refresh is in flight (or fails) we keep
  // showing it so the tabs are not torn down and unsaved state is not lost.
  bool _hasVendor = false;

  @override
  void initState() {
    super.initState();

    context.read<VendorBloc>().add(const FetchVendorEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("profile"), style: AppTextStyles.heading18),
      ),
      body: BlocBuilder<VendorBloc, VendorState>(
        buildWhen: (previous, current) =>
            !(_hasVendor &&
                (current is VendorLoading || current is VendorError)),
        builder: (context, state) {
          if (state is VendorLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VendorError) {
            return Center(
              child: Text(
                context.trMessage(state.message),
                style: AppTextStyles.cardTitle15,
              ),
            );
          }

          if (state is VendorLoaded) {
            final vendor = state.vendorResponse.vendor;

            if (vendor == null) {
              return Center(
                child: Text(context.tr('vendor_data_not_available')),
              );
            }

            _hasVendor = true;

            return Column(
              children: [
                _buildTopNavigation(),

                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: [
                      // Info tab
                      _updateProfileScope(child: UserInfoTab(vendor: vendor)),

                      // Files tab
                      _updateProfileScope(child: FilesTab(vendor: vendor)),

                      // Location tab
                      _updateProfileScope(child: LocationTab(vendor: vendor)),

                      // sectors tap
                      BlocProvider(
                        create: (_) => sl<SectorsBloc>(),
                        child: SectorsTab(vendor: vendor),
                      ),
                      // change phone tap
                      BlocProvider(
                        create: (_) => sl<ChangePhoneBloc>(),
                        child: ChangePhoneTab(vendor: vendor),
                      ),

                      // security tap
                      SecurityTab(vendor: vendor),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Provides an [UpdateProfileBloc] to [child] and reloads the vendor once
  /// per successful update (never on failure).
  Widget _updateProfileScope({required Widget child}) {
    return BlocProvider(
      create: (_) => sl<UpdateProfileBloc>(),
      child: BlocListener<UpdateProfileBloc, UpdateProfileState>(
        listenWhen: (previous, current) =>
            current is UpdateProfileSuccess &&
            previous is! UpdateProfileSuccess,
        listener: (context, state) =>
            context.read<VendorBloc>().add(const FetchVendorEvent()),
        child: child,
      ),
    );
  }

  Widget _buildTopNavigation() {
    final tabs = [
      _ProfileTab(title: context.tr("profile"), icon: AppAssets.person),
      _ProfileTab(title: context.tr("files"), icon: AppAssets.file),
      _ProfileTab(title: context.tr("location"), icon: AppAssets.location),
      _ProfileTab(title: context.tr("sector"), icon: AppAssets.grid),
      _ProfileTab(
        title: context.tr("change_phone"),
        icon: AppAssets.smartphone,
      ),
      _ProfileTab(title: context.tr("security"), icon: AppAssets.safe),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(6),
        child: Row(
          children: List.generate(tabs.length, (index) {
            return Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == tabs.length - 1 ? 0 : 6,
              ),
              child: _ProfileTabItem(
                tab: tabs[index],
                selected: selectedIndex == index,
                onTap: () => setState(() => selectedIndex = index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ProfileTabItem extends StatelessWidget {
  final _ProfileTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileTabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryGreen : AppColors.textGrey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryGreen.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              tab.icon,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(width: 8),
            Text(
              tab.title,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab {
  final String title;
  final String icon;

  const _ProfileTab({required this.title, required this.icon});
}
