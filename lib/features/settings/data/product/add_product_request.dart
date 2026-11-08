class AddProductRequest {
  final String name;
  final double price;
  final String deliveryTime;
  final String sectorId;
  final String vendorId;
  final String note;

  /// Local file paths of the picked photos.
  final List<String> photoPaths;

  const AddProductRequest({
    required this.name,
    required this.price,
    required this.deliveryTime,
    required this.sectorId,
    required this.vendorId,
    this.note = '',
    this.photoPaths = const [],
  });
}
