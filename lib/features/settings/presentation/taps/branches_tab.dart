import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/cache/cache_helper.dart';
import 'package:whats_order/core/cache/cache_keys.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/auth/sign_in/data/user_model.dart';
import 'package:whats_order/features/settings/data/branch/branch_model.dart';
import 'package:whats_order/features/settings/presentation/bloc/branches_bloc.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/branches_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/branches_state.dart';
import 'package:whats_order/features/settings/presentation/widgets/branch_card.dart';
import 'package:whats_order/features/settings/presentation/widgets/branch_form_dialog.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_confirmation_dialog.dart';
import 'package:whats_order/features/settings/presentation/widgets/settings_empty_state.dart';

class BranchesTab extends StatefulWidget {
  const BranchesTab({super.key});

  @override
  State<BranchesTab> createState() => _BranchesTabState();
}

class _BranchesTabState extends State<BranchesTab> {
  String _userId = '';

  @override
  void initState() {
    super.initState();

    final cachedUser = CacheHelper.getDataFromSharedPreference(
      key: CacheKeys.userModel,
    );

    if (cachedUser != null && cachedUser.isNotEmpty) {
      final user = UserModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(cachedUser) as Map),
      );
      _userId = user.id?.toString() ?? '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('current_user_not_identified'))),
        );
        return;
      }

      context.read<BranchesBloc>().add(FetchBranchesEvent(userId: _userId));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("branches"), style: AppTextStyles.heading18),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('branches_description'),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: _userId.isEmpty ? null : () => _showBranchForm(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(context.tr('add_branch')),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textFaint,
                    overlayColor: Colors.white,
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 18, 0),
                    iconSize: 20,
                    textStyle: AppTextStyles.cellMuted13.copyWith(fontSize: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocConsumer<BranchesBloc, BranchesState>(
              listener: (context, state) {
                if (state is BranchesActionSuccessState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.trMessage(state.message))),
                  );
                } else if (state is BranchesErrorState) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.trMessage(state.message))),
                  );
                }
              },
              builder: (context, state) {
                if (state is BranchesLoadingState ||
                    state is BranchesInitialState) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final branches = switch (state) {
                  BranchesLoadedState s => s.branches,
                  BranchesActionLoadingState s => s.branches,
                  BranchesActionSuccessState s => s.branches,
                  BranchesErrorState s => s.branches,
                  _ => <BranchModel>[],
                };

                if (branches.isEmpty && state is! BranchesActionLoadingState) {
                  return SettingsEmptyState(
                    icon: Icons.store_outlined,
                    message: context.tr('no_branches_available'),
                  );
                }

                return Column(
                  children: [
                    if (state is BranchesActionLoadingState)
                      const LinearProgressIndicator(
                        color: AppColors.primaryGreen,
                      ),
                    ...branches.map(
                      (branch) => BranchCard(
                        branch: branch,
                        isBusy: state is BranchesActionLoadingState,
                        onEdit: () => _showBranchForm(branch: branch),
                        onDelete: () => _confirmDelete(branch),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Add / Edit form ─────────────────────────

  Future<void> _showBranchForm({BranchModel? branch}) async {
    final result = await showBranchFormDialog(context, branch: branch);

    if (result == null || !mounted) return;

    final bloc = context.read<BranchesBloc>();

    if (branch == null) {
      bloc.add(AddBranchEvent(userId: _userId, branch: result));
    } else {
      bloc.add(
        UpdateBranchEvent(userId: _userId, branchId: branch.id, branch: result),
      );
    }
  }

  Future<void> _confirmDelete(BranchModel branch) async {
    final confirmed = await showSettingsConfirmationDialog(
      context,
      title: context.tr('delete_branch'),
      message: context.tr('confirm_delete_branch_message'),
      itemName: branch.name,
    );

    if (confirmed == true && mounted) {
      context.read<BranchesBloc>().add(
        DeleteBranchEvent(userId: _userId, branchId: branch.id),
      );
    }
  }
}
