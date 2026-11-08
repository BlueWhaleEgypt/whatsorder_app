import 'package:whats_order/core/network/end_points.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final String deliveryTime;
  final String note;
  final String sectorId;
  final String sectorName;

  /// File names served from `/uploads/`; the first one is the cover.
  final List<String> photos;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.deliveryTime,
    required this.note,
    this.sectorId = '',
    this.sectorName = '',
    this.photos = const [],
  });

  /// Where an uploaded photo is served from.
  static String photoUrl(String fileName) =>
      '${EndPoints.baseUrl}/uploads/${Uri.encodeComponent(fileName)}';

  /// Full URLs of all the photos, in order.
  List<String> get photoUrls => [for (final photo in photos) photoUrl(photo)];

  /// Full URL of the cover photo, or null when the product has none.
  String? get coverPhotoUrl => photos.isEmpty ? null : photoUrls.first;

  /// The API spells the delivery field `delivaryTime`.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final sector = json['sector'];
    final photos = json['photos'];
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']) ?? 0,
      deliveryTime: json['delivaryTime']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      sectorId: sector is Map ? sector['id']?.toString() ?? '' : '',
      sectorName: sector is Map ? sector['name']?.toString() ?? '' : '',
      photos: photos is List
          ? [
              for (final photo in photos)
                if (photo != null && photo.toString().isNotEmpty)
                  photo.toString(),
            ]
          : const [],
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
