import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/network/end_points.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/features/orders/data/vendor_model.dart';
import 'package:whats_order/features/settings/data/profile/update_profile_request.dart';
import 'package:whats_order/features/settings/presentation/bloc/event/update_profile_event.dart';
import 'package:whats_order/features/settings/presentation/bloc/states/update_profile_state.dart';
import 'package:whats_order/features/settings/presentation/bloc/update_profile_bloc.dart';

class FilesTab extends StatefulWidget {
  final VendorModel vendor;

  const FilesTab({super.key, required this.vendor});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  final ImagePicker _picker = ImagePicker();
  final Map<String, File> _selectedFiles = {};

  Future<void> _pickFile(String fieldName) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedFiles[fieldName] = File(picked.path);
      });
    }
  }

  void _saveFiles() {
    final userId = widget.vendor.id;

    if (userId == null || userId.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID not found')));
      return;
    }

    context.read<UpdateProfileBloc>().add(
      SubmitUpdateProfileEvent(
        request: UpdateProfileRequest.fromVendor(
          userId: userId,
          vendor: widget.vendor,
          files: Map<String, File>.from(_selectedFiles),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateProfileBloc, UpdateProfileState>(
      listener: (context, state) {
        if (state is UpdateProfileSuccess) {
          setState(() => _selectedFiles.clear());

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }

        if (state is UpdateProfileError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is UpdateProfileLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('manage_files_description'),
                style: AppTextStyles.cellMuted13,
              ),
              const SizedBox(height: 10),
              _buildFileCard(
                title: 'Face ID Card',
                fieldName: 'faceIdCard',
                fileName: widget.vendor.faceIdCard,
                icon: Icons.badge_outlined,
              ),
              _buildFileCard(
                title: 'Back ID Card',
                fieldName: 'backIdCard',
                fileName: widget.vendor.backIdCard,
                icon: Icons.badge_outlined,
              ),
              _buildFileCard(
                title: 'Commercial Register',
                fieldName: 'commercialRegister',
                fileName: widget.vendor.commercialRegister,
                icon: Icons.business_center_outlined,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveFiles,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save files'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileCard({
    required String title,
    required String fieldName,
    required String? fileName,
    required IconData icon,
  }) {
    final selectedFile = _selectedFiles[fieldName];
    final hasSelectedFile = selectedFile != null;
    final hasRemoteFile = fileName != null && fileName.trim().isNotEmpty;

    final imageUrl = hasRemoteFile
        ? '${EndPoints.baseUrl}/uploads/$fileName'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryGreen.withOpacity(.1),
                child: Icon(icon, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.cardTitle15)),
              TextButton.icon(
                onPressed: () => _pickFile(fieldName),
                icon: Icon(
                  hasSelectedFile
                      ? Icons.check_circle_outline
                      : Icons.upload_file_outlined,
                ),
                label: Text(hasSelectedFile ? 'Selected' : 'Choose'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasSelectedFile)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                selectedFile,
                width: double.infinity,
                height: 230,
                fit: BoxFit.contain,
              ),
            )
          else if (hasRemoteFile)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                height: 230,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 140,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 45,
                      color: AppColors.textGrey,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(
              height: 140,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 42,
                  color: AppColors.textGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
