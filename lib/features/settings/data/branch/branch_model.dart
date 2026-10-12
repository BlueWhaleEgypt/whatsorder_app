class BranchModel {
  final String id;
  final String name;
  final String nameEn;
  final double? latitude;
  final double? longitude;
  final String address;

  const BranchModel({
    required this.id,
    required this.name,
    required this.nameEn,
    this.latitude,
    this.longitude,
    required this.address,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      address: json['address']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
