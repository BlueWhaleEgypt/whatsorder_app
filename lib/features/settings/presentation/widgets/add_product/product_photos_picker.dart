import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whats_order/core/localization/app_localizations.dart';
import 'package:whats_order/core/theme/app_colors.dart';
import 'package:whats_order/core/theme/app_text_styles.dart';
import 'package:whats_order/core/widgets/dashed_upload_box.dart';
import 'package:whats_order/features/settings/presentation/utils/product_photos_controller.dart';
import 'package:whats_order/features/settings/presentation/widgets/add_product/product_form_label.dart';

/// Photo strip of the add-product form: an "add" tile followed by the picked
/// photos (the first one is the cover), and a hint that turns into the
/// "photo required" error.
class ProductPhotosPicker extends StatelessWidget {
  static const double _tileSize = 96;
  static const double _tileSpacing = 10;
  static const int _emptySlotCount = 3;
  static const _tileRadius = BorderRadius.all(Radius.circular(12));

  final ProductPhotosController controller;
  final VoidCallback onAddPressed;

  const ProductPhotosPicker({
    super.key,
    required this.controller,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final photos = controller.photos;
        final hasAddTile = controller.canAddMore;
        // Only a few placeholders are shown as a hint, not one per free slot.
        final emptySlots = math.min(controller.remaining, _emptySlotCount);
        final decodeWidth = (_tileSize * MediaQuery.devicePixelRatioOf(context))
            .round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductFormLabel(
              context.tr('product_photos'),
              isRequired: controller.isRequired,
            ),
            SizedBox(
              height: _tileSize,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length + (hasAddTile ? 1 : 0) + emptySlots,
                itemBuilder: (context, index) {
                  if (hasAddTile && index == 0) {
                    return _AddTile(onTap: onAddPressed);
                  }
                  final photoIndex = hasAddTile ? index - 1 : index;
                  if (photoIndex >= photos.length) {
                    return _EmptySlot(
                      color: _EmptySlot
                          .palette[photoIndex % _EmptySlot.palette.length],
                      showCover: photoIndex == 0,
                      onTap: onAddPressed,
                    );
                  }
                  final photo = photos[photoIndex];
                  return _PhotoTile(
                    key: ValueKey(photo.path),
                    photo: photo,
                    isCover: photoIndex == 0,
                    decodeWidth: decodeWidth,
                    onRemove: () => controller.removeAt(photoIndex),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.showError
                  ? context.tr('photos_required')
                  : context.tr('photos_hint', {
                      'n': '${ProductPhotosController.maxPhotos}',
                    }),
              style: AppTextStyles.subtitle13.copyWith(
                color: controller.showError ? AppColors.danger : null,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ProductPhotosPicker._tileSize,
        margin: const EdgeInsetsDirectional.only(
          end: ProductPhotosPicker._tileSpacing,
        ),
        decoration: const BoxDecoration(
          color: AppColors.lightGreenBg,
          borderRadius: ProductPhotosPicker._tileRadius,
        ),
        child: CustomPaint(
          foregroundPainter: DashedBorderPainter(
            color: AppColors.primaryGreenLight.withValues(alpha: 0.5),
            radius: 12,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.file_upload_outlined,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 4),
              Text(context.tr('add_photos'), style: AppTextStyles.cellMuted13),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastel placeholder for a photo slot that has not been filled yet.
class _EmptySlot extends StatelessWidget {
  static const palette = [
    Color(0xFFDCFCE7),
    Color(0xFFD6EAFF),
    Color(0xFFFFE6C9),
  ];

  final Color color;
  final bool showCover;
  final VoidCallback onTap;

  const _EmptySlot({
    required this.color,
    required this.showCover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ProductPhotosPicker._tileSize,
        margin: const EdgeInsetsDirectional.only(
          end: ProductPhotosPicker._tileSpacing,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: ProductPhotosPicker._tileRadius,
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.image_outlined,
                size: 32,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
            if (showCover)
              PositionedDirectional(
                top: 4,
                start: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.tr('cover'),
                    style: _PhotoTile._coverStyle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  static const _coverStyle = TextStyle(
    fontFamily: 'Cairo',
    fontSize: 10,
    color: Colors.white,
  );

  final XFile photo;
  final bool isCover;
  final int decodeWidth;
  final VoidCallback onRemove;

  const _PhotoTile({
    super.key,
    required this.photo,
    required this.isCover,
    required this.decodeWidth,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ProductPhotosPicker._tileSize,
      margin: const EdgeInsetsDirectional.only(
        end: ProductPhotosPicker._tileSpacing,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: ProductPhotosPicker._tileRadius,
            // Decode at tile size instead of the full camera resolution.
            child: Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              cacheWidth: decodeWidth,
            ),
          ),
          PositionedDirectional(
            top: 4,
            end: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.white,
                child: Icon(Icons.close, size: 14),
              ),
            ),
          ),
          if (isCover)
            PositionedDirectional(
              top: 4,
              start: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(context.tr('cover'), style: _coverStyle),
              ),
            ),
        ],
      ),
    );
  }
}
