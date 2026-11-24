import 'dart:io';

import 'package:whats_order/features/orders/data/vendor_model.dart';

class UpdateProfileRequest {
  /// Bundled placeholder uploaded for every image field the user did not
  /// replace. The backend requires this exact multipart filename.
  static const String noPhotoAsset = 'assets/images/noPhoto.jpeg';
  static const String noPhotoFileName = 'noPhoto.jpeg';

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
    String? storeName,
    String? storeAbout,
    File? storePhoto,
    String? existingStorePhoto,
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

    // Always resend the store fields: the PUT replaces the profile, so
    // omitting them would clear them.
    fields['storeName'] = storeName ?? vendor.storeName ?? '';
    fields['storeAbout'] = storeAbout ?? vendor.storeAbout ?? '';

    // File fields must never be sent as String values.
    fields.remove('faceIdCard');
    fields.remove('backIdCard');
    fields.remove('commercialRegister');
    fields.remove('storePhoto');

    final existingFileNames = <String, String>{
      if ((vendor.faceIdCard ?? '').trim().isNotEmpty)
        'faceIdCard': vendor.faceIdCard!.trim(),
      if ((vendor.backIdCard ?? '').trim().isNotEmpty)
        'backIdCard': vendor.backIdCard!.trim(),
      if ((vendor.commercialRegister ?? '').trim().isNotEmpty)
        'commercialRegister': vendor.commercialRegister!.trim(),
      if (((existingStorePhoto ?? vendor.storePhoto) ?? '').trim().isNotEmpty)
        'storePhoto': (existingStorePhoto ?? vendor.storePhoto)!.trim(),
    };

    return UpdateProfileRequest(
      userId: userId,
      fields: fields,
      files: {...files, if (storePhoto != null) 'storePhoto': storePhoto},
      existingFileNames: existingFileNames,
    );
  }
}
