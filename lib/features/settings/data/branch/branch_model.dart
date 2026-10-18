class BranchModel {
  final String id;
  final String name;
  final String nameEn;
  final double? latitude;
  final double? longitude;
  final String address;

  /// Optional, display-only. Read from the API response when the backend
  /// sends `city` / `area`; never written back (not part of [toJson]).
  final String? city;
  final String? area;

  const BranchModel({
    required this.id,
    required this.name,
    required this.nameEn,
    this.latitude,
    this.longitude,
    required this.address,
    this.city,
    this.area,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString(),
      area: json['area']?.toString(),
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
