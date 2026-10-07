import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_bloc.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_event.dart';
import 'package:whats_order/features/orders/presentation/bloc/vendor_state.dart';
import 'package:whats_order/features/settings/presentation/widgets/branches_tab.dart';
import 'package:whats_order/features/settings/presentation/widgets/change_phone_tab.dart';
import 'package:whats_order/features/settings/presentation/widgets/files_tab.dart';
import 'package:whats_order/features/settings/presentation/widgets/location_tab.dart';
import 'package:whats_order/features/settings/presentation/widgets/security_tab.dart';
import 'package:whats_order/features/settings/presentation/widgets/user_info_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedIndex = 0;

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
        builder: (context, state) {
          if (state is VendorLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VendorError) {
            return Center(
              child: Text(state.message, style: AppTextStyles.cardTitle15),
            );
          }

          if (state is VendorLoaded) {
            final vendor = state.vendorResponse.vendor;

            if (vendor == null) {
              return const Center(child: Text('Vendor data not available'));
            }

            return Column(
              children: [
                _buildTopNavigation(),

                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: [
                      UserInfoTab(vendor: vendor),
                      ChangePhoneTab(vendor: vendor),
                      LocationTab(vendor: vendor),
                      BranchesTab(vendor: vendor),
                      FilesTab(vendor: vendor),
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
Widget _buildTopNavigation() {
  final tabs = [
    _ProfileTab(
      title: context.tr("profile"),
      icon: Icons.person_outline_rounded,
    ),
    _ProfileTab(
      title: context.tr("change_phone"),
      icon: Icons.phone_android_outlined,
    ),
    _ProfileTab(
      title: context.tr("location"),
      icon: Icons.location_on_outlined,
    ),
    _ProfileTab(
      title: context.tr("branches"),
      icon: Icons.store_outlined,
    ),
    _ProfileTab(
      title: context.tr("files"),
      icon: Icons.description_outlined,
    ),
    _ProfileTab(
      title: context.tr("security"),
      icon: Icons.lock_outline_rounded,
    ),
  ];

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    width: double.infinity,
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      color: Colors.white,
      borderRadius: const BorderRadius.all(
        Radius.circular(12),
      ),
      border: Border.all(
        color: AppColors.primaryGreen,
      ),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final selected = selectedIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFDFFFF0)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab.icon,
                      size: 19,
                      color: selected
                          ? AppColors.primaryGreen
                          : AppColors.textGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tab.title,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primaryGreen
                            : AppColors.textGrey,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}
}

class _ProfileTab {
  final String title;
  final IconData icon;

  const _ProfileTab({required this.title, required this.icon});
}
