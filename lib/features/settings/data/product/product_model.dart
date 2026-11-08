class ProductModel {
  final String id;
  final String name;
  final double price;
  final String deliveryTime;
  final String note;
  final String sectorId;
  final String sectorName;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.deliveryTime,
    required this.note,
    this.sectorId = '',
    this.sectorName = '',
  });

  /// The API spells the delivery field `delivaryTime`.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final sector = json['sector'];
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']) ?? 0,
      deliveryTime: json['delivaryTime']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      sectorId: sector is Map ? sector['id']?.toString() ?? '' : '',
      sectorName: sector is Map ? sector['name']?.toString() ?? '' : '',
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
