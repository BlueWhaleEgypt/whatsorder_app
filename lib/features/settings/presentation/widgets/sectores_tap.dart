import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whats_order/core/constants/app_assets.dart';

import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/gradient_button.dart';
import 'package:whats_order/core/widgets/sector_dropdown.dart';

import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_cubit.dart';
import 'package:whats_order/features/auth/sign_up/presentation/cubit/onboarding_state.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';

import 'package:whats_order/features/settings/presentation/bloc/sectors_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/sectors_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/sectors_state.dart';

class SectorsTab extends StatefulWidget {
  final VendorModel vendor;

  const SectorsTab({super.key, required this.vendor});

  @override
  State<SectorsTab> createState() => _SectorsTabState();
}

class _SectorsTabState extends State<SectorsTab> {
  String? _sectorId;
  bool isEditing = false;

  // نسخة محلية من القطاعات المعروضة.
  // يتم تحديثها بعد نجاح الإضافة أو الحذف.
  List<dynamic> _sectors = [];

  String? _pendingAction;
  String? _pendingSectorId;

  @override
  void initState() {
    super.initState();

    _sectors = List<dynamic>.from(widget.vendor.sectors ?? []);

    final onboardingCubit = context.read<OnboardingCubit>();
    final data = onboardingCubit.state.data;

    _sectorId = data.sectorId.isEmpty ? null : data.sectorId;
  }

  @override
  void didUpdateWidget(covariant SectorsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // لو الشاشة الأم أرسلت VendorModel محدثًا من الـ API،
    // حدّث القائمة المحلية بالبيانات الجديدة.
    if (!identical(oldWidget.vendor, widget.vendor)) {
      _sectors = List<dynamic>.from(widget.vendor.sectors ?? []);
    }
  }

  void _toggleEditing() {
    if (!isEditing) {
      setState(() {
        isEditing = true;
      });

      context.read<OnboardingCubit>().loadSectors();
      return;
    }

    if (_sectorId == null || _sectorId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('sector_is_required'))));
      return;
    }

    final userId = widget.vendor.id?.toString() ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID is missing')));
      return;
    }

    _pendingAction = 'add';
    _pendingSectorId = _sectorId;

    context.read<SectorsBloc>().add(
      AddSectorEvent(userId: userId, sectorId: _sectorId!),
    );
  }

  Future<void> _confirmDeleteSector({
    required String sectorId,
    required String sectorName,
  }) async {
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

    final userId = widget.vendor.id?.toString() ?? '';

    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID is missing')));
      return;
    }

    _pendingAction = 'delete';
    _pendingSectorId = sectorId;

    context.read<SectorsBloc>().add(
      DeleteSectorEvent(userId: userId, sectorId: sectorId),
    );
  }

  void _handleSuccess(SectorsActionSuccess state) {
    final action = _pendingAction;
    final sectorId = _pendingSectorId;

    setState(() {
      if (action == 'delete' && sectorId != null) {
        _sectors.removeWhere((sector) => sector.id.toString() == sectorId);
      } else if (action == 'add' && sectorId != null) {
        final onboardingState = context.read<OnboardingCubit>().state;

        final selectedSector = onboardingState.sectors.where(
          (sector) => sector.id.toString() == sectorId,
        );

        if (selectedSector.isNotEmpty) {
          _sectors.add(selectedSector.first);
        }

        isEditing = false;
      }
    });

    _pendingAction = null;
    _pendingSectorId = null;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr(state.messageKey))));
  }

  void _handleError(SectorsError state) {
    _pendingAction = null;
    _pendingSectorId = null;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr(state.messageKey))));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SectorsBloc, SectorsState>(
      listener: (context, state) {
        if (state is SectorsActionSuccess) {
          _handleSuccess(state);
        } else if (state is SectorsError) {
          _handleError(state);
        }
      },
      builder: (context, sectorsState) {
        final isActionLoading = sectorsState is SectorsActionLoading;

        return BlocBuilder<OnboardingCubit, OnboardingState>(
          builder: (context, onboardingState) {
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

                  if (_sectors.isEmpty)
                    _buildEmptyState()
                  else
                    ..._sectors.map((sector) {
                      final sectorName = sector.name?.toString() ?? '-';
                      final sectorId = sector.id.toString();

                      return Container(
                        key: ValueKey(sectorId),
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
                              backgroundColor: AppColors.primaryGreen
                                  .withOpacity(0.1),
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
                                      sector.note.toString().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      sector.note.toString(),
                                      style: AppTextStyles.cellMuted13,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            IconButton(
                              onPressed: isActionLoading
                                  ? null
                                  : () => _confirmDeleteSector(
                                      sectorId: sectorId,
                                      sectorName: sectorName,
                                    ),
                              tooltip: 'Delete sector',
                              icon: SvgPicture.asset(
                                AppAssets.delete,
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.danger,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  if (isEditing) ...[
                    const SizedBox(height: 12),

                    SectorDropdown(
                      sectors: onboardingState.sectors,
                      loading: onboardingState.sectorsLoading,
                      error: onboardingState.sectorsError,
                      value: _sectorId,
                      onChanged: (value) {
                        if (isActionLoading) return;

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
                      label: context.tr(isEditing ? 'save_changes' : 'add'),
                      onPressed: isActionLoading ? () {} : _toggleEditing,
                      loading: isActionLoading,
                    ),
                  ),
                ],
              ),
            );
          },
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
          Icon(Icons.token_outlined, size: 42, color: AppColors.textGrey),
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
