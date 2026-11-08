import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/*
|--------------------------------------------------------------------------
| ProductPhotosController — the photos picked for a new product.
|
| Enforces the [maxPhotos] limit and owns the "at least one photo" error.
| The first photo is the cover. The error only appears once a submit was
| attempted, and then follows the list: adding a photo clears it, removing
| the last one brings it back.
|--------------------------------------------------------------------------
*/

class ProductPhotosController extends ChangeNotifier {
  static const int maxPhotos = 8;

  final List<XFile> _photos = [];
  bool _submitAttempted = false;

  UnmodifiableListView<XFile> get photos => UnmodifiableListView(_photos);

  bool get isEmpty => _photos.isEmpty;
  bool get canAddMore => _photos.length < maxPhotos;
  int get remaining => maxPhotos - _photos.length;
  bool get showError => _submitAttempted && _photos.isEmpty;

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

  /// Call on every submit. Returns whether the photo requirement is met.
  bool validate() {
    final wasShowingError = showError;
    _submitAttempted = true;
    if (showError != wasShowingError) notifyListeners();
    return !isEmpty;
  }
}
