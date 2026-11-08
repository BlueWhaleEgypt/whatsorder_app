import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/*
|--------------------------------------------------------------------------
| ProductPhotosController — the photos picked for a new product.
|
| Enforces the [maxPhotos] limit and owns the "at least one photo" error.
| When editing, it also holds the photos the product already has (file
| names); they can be removed like new ones. The first photo is the cover.
| The error only appears once a submit was attempted, and then follows the
| list: adding a photo clears it, removing the last one brings it back.
|--------------------------------------------------------------------------
*/

class ProductPhotosController extends ChangeNotifier {
  static const int maxPhotos = 8;

  /// Whether at least one photo (existing or new) must be present.
  final bool isRequired;

  final List<String> _existing;
  final List<XFile> _photos = [];
  bool _submitAttempted = false;
  bool _removedExisting = false;

  /// [existingPhotos] are the server file names of a product being edited.
  ProductPhotosController({
    this.isRequired = true,
    List<String> existingPhotos = const [],
  }) : _existing = [...existingPhotos];

  /// File names of the product's photos that are still kept.
  UnmodifiableListView<String> get existingPhotos =>
      UnmodifiableListView(_existing);

  /// Newly picked photos.
  UnmodifiableListView<XFile> get photos => UnmodifiableListView(_photos);

  int get totalCount => _existing.length + _photos.length;
  bool get isEmpty => totalCount == 0;
  bool get canAddMore => remaining > 0;
  int get remaining => math.max(0, maxPhotos - totalCount);
  bool get showError => _submitAttempted && isRequired && isEmpty;

  /// Whether the photo set differs from what the product started with.
  bool get hasChanges => _removedExisting || _photos.isNotEmpty;

  List<String> get paths => [for (final p in _photos) p.path];

  /// Adds as many of [picked] as still fit; the rest are dropped.
  void add(Iterable<XFile> picked) {
    final accepted = picked.take(remaining).toList();
    if (accepted.isEmpty) return;
    _photos.addAll(accepted);
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _photos.length) return;
    _photos.removeAt(index);
    notifyListeners();
  }

  void removeExistingAt(int index) {
    if (index < 0 || index >= _existing.length) return;
    _existing.removeAt(index);
    _removedExisting = true;
    notifyListeners();
  }

  /// Call on every submit. Returns whether the photo requirement is met.
  bool validate() {
    final wasShowingError = showError;
    _submitAttempted = true;
    if (showError != wasShowingError) notifyListeners();
    return !isRequired || !isEmpty;
  }
}
