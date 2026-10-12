import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/sector_dropdown.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_state.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

class SectorsTab extends StatefulWidget {
  final VendorModel vendor;

  const SectorsTab({super.key, required this.vendor});

  @override
  State<SectorsTab> createState() => _SectorsTabState();
}

class _SectorsTabState extends State<SectorsTab> {
  String? _sectorId;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();

    final onboardingCubit = context.read<OnboardingCubit>();
    final data = onboardingCubit.state.data;

    _sectorId = data.sectorId.isEmpty ? null : data.sectorId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OnboardingCubit>().loadSectors();
    });
  }

  void _toggleEditing() {
    if (!isEditing) {
      setState(() => isEditing = true);
      return;
    }

    if (_sectorId == null || _sectorId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('sector_is_required'))));
      return;
    }

    // TODO: استدعاء Update Profile API لإرسال القطاع المختار.
    // اقفل وضع التعديل بعد نجاح الـ API فقط.
    setState(() => isEditing = false);
  }

  Future<void> _confirmDeleteSector(String sectorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Delete sector'),
          content: Text('Are you sure you want to delete "$sectorName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    // TODO: استدعاء Delete Sector API هنا.
    // بعد نجاح الحذف، حدّث قائمة القطاعات من الـ API.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connect the delete sector API to complete deletion.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sectors = widget.vendor.sectors ?? [];

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('manage_user_info_description'),
                style: AppTextStyles.cellMuted13,
              ),

              const SizedBox(height: 24),

              if (sectors.isEmpty)
                _buildEmptyState()
              else
                ...sectors.map((sector) {
                  final sectorName = sector.name ?? '-';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryGreen.withOpacity(
                            0.1,
                          ),
                          child: const Icon(
                            Icons.token_outlined,
                            color: AppColors.primaryGreen,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sectorName,
                                style: AppTextStyles.cardTitle15,
                              ),
                              if (sector.note != null &&
                                  sector.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  sector.note!,
                                  style: AppTextStyles.cellMuted13,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        IconButton(
                          onPressed: () => _confirmDeleteSector(sectorName),
                          tooltip: 'Delete sector',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              if (isEditing) ...[
                const SizedBox(height: 12),

                SectorDropdown(
                  sectors: state.sectors,
                  loading: state.sectorsLoading,
                  error: state.sectorsError,
                  value: _sectorId,
                  onChanged: (value) {
                    setState(() {
                      _sectorId = value;
                    });
                  },
                  onRetry: () {
                    context.read<OnboardingCubit>().loadSectors();
                  },
                ),
              ],

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: context.tr(isEditing ? 'save_changes' : 'edit'),
                  onPressed: _toggleEditing,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.store_outlined, size: 42, color: AppColors.textGrey),
          SizedBox(height: 12),
          Text(
            'No sectors available',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
