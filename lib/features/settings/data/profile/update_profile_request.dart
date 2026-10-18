import 'dart:io';

import 'package:whats_order/features/orders/data/vendor_model.dart';

class UpdateProfileRequest {
  final String userId;
  final Map<String, dynamic> fields;
  final Map<String, File> files;
  final Map<String, String> existingFileNames;

  const UpdateProfileRequest({
    required this.userId,
    required this.fields,
    this.files = const {},
    this.existingFileNames = const {},
  });

  factory UpdateProfileRequest.fromVendor({
    required String userId,
    required VendorModel vendor,
    Map<String, dynamic> overrides = const {},
    Map<String, File> files = const {},
  }) {
    final fields = <String, dynamic>{
      'firstName': vendor.firstName ?? '',
      'lastName': vendor.lastName ?? '',
      'phone': vendor.phone ?? '',
      'email': vendor.email ?? '',
      'latitude': vendor.latitude?.toString() ?? '',
      'longitude': vendor.longitude?.toString() ?? '',
      'city': vendor.city ?? '',
      'state': vendor.state ?? '',
      'street': vendor.street ?? '',
      'building': vendor.building ?? '',
      'area': vendor.area ?? '',
      'neighborhood': vendor.neighborhood ?? '',
      'servingTheEntireGovernorate':
          vendor.servingTheEntireGovernorate ?? false,
      'servingTheEntireArea': vendor.servingTheEntireArea ?? false,
      'availableInAllRegions': vendor.availableInAllRegions ?? false,
      'serviceDistance': vendor.serviceDistance?.toString() ?? '',
    };

    fields.addAll(overrides);

    // File fields must never be sent as String values.
    fields.remove('faceIdCard');
    fields.remove('backIdCard');
    fields.remove('commercialRegister');

    final existingFileNames = <String, String>{
      if ((vendor.faceIdCard ?? '').trim().isNotEmpty)
        'faceIdCard': vendor.faceIdCard!.trim(),
      if ((vendor.backIdCard ?? '').trim().isNotEmpty)
        'backIdCard': vendor.backIdCard!.trim(),
      if ((vendor.commercialRegister ?? '').trim().isNotEmpty)
        'commercialRegister': vendor.commercialRegister!.trim(),
    };

    return UpdateProfileRequest(
      userId: userId,
      fields: fields,
      files: files,
      existingFileNames: existingFileNames,
    );
  }
}
