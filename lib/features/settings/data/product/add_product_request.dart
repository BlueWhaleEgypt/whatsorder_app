import 'package:dio/dio.dart';
import 'package:whats_order/features/settings/data/product/product_model.dart';

class AddProductRequest {
  final String name;
  final double price;
  final String deliveryTime;
  final String sectorId;
  final String vendorId;
  final String note;

  /// Local file paths of the picked photos.
  final List<String> photoPaths;

  /// Photos the product already has and wants to keep, as server file names.
  /// The API has no way to delete a photo, so when the photo set changes the
  /// kept ones are downloaded and sent again together with [photoPaths]; the
  /// server then ends up with exactly this set. Leave empty to not touch the
  /// photos at all.
  final List<String> keptPhotoFileNames;

  const AddProductRequest({
    required this.name,
    required this.price,
    required this.deliveryTime,
    required this.sectorId,
    required this.vendorId,
    this.note = '',
    this.photoPaths = const [],
    this.keptPhotoFileNames = const [],
  });

  /// The multipart body of POST / PUT /api/auth/vendor-services. The API
  /// spells the delivery field `delivaryTime`.
  Future<FormData> toFormData() async {
    // Kept photos first so the cover stays the first photo.
    final kept = await Future.wait(keptPhotoFileNames.map(_download));
    return FormData.fromMap({
      'name': name,
      'price': price,
      'delivaryTime': deliveryTime,
      'sectorId': sectorId,
      'vendorId': vendorId,
      'note': note,
      'photos': [
        ...kept,
        for (final path in photoPaths) await MultipartFile.fromFile(path),
      ],
    });
  }

  static Future<MultipartFile> _download(String fileName) async {
    final response = await Dio().get<List<int>>(
      ProductModel.photoUrl(fileName),
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Could not download existing photo: $fileName');
    }
    return MultipartFile.fromBytes(bytes, filename: fileName);
  }
}
