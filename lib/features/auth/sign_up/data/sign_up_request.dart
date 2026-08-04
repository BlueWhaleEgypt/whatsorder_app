import 'dart:io';
import 'package:dio/dio.dart';
import 'package:whats_order/core/utils/account_type.dart';

/*
|--------------------------------------------------------------------------
| SignUpRequest
|--------------------------------------------------------------------------
|
| Full payload for the single POST /api/auth/signup multipart call.
| Every field is optional unless marked required, matching the Swagger
| spec exactly. Files are converted to MultipartFile so Dio can send
| them as form-data.
|
| username is set to the phone number (same value) as per the API spec.
| role is always ["vendor"] for this vendor-facing app.
|
| `type` tells the API whether this signup is for a person or a company:
|   - person  -> faceIdCard + backIdCard + commercialRegister (used here
|                to hold the "store front photo") are all required.
|   - company -> only commercialRegister (the actual commercial register
|                document) is required; faceIdCard/backIdCard are omitted.
|--------------------------------------------------------------------------
*/

class SignUpRequest {
  // ── Account credentials ───────────────────────────────────────────────
  final String phone;
  final String password;

  // ── Personal info ─────────────────────────────────────────────────────
  final String firstName;
  final String? lastName;
  final String email;

  // ── Account type ──────────────────────────────────────────────────────
  final AccountType type;

  // ── Sector ────────────────────────────────────────────────────────────
  final String? sectorId;

  // ── Location ──────────────────────────────────────────────────────────
  final String? address;
  final String? governorate;
  final String? city;
  final String? state;
  final String? street;
  final String? building;
  final String? area;
  final String? neighborhood;
  final double? latitude;
  final double? longitude;
  final double? serviceDistance;

  // ── Service coverage ─────────────────────────────────────────────────
  final bool servingTheEntireGovernorate;
  final bool servingTheEntireArea;
  final bool availableInAllRegions;

  // ── Company (optional) ───────────────────────────────────────────────
  final String? companyName;
  final String? responsibleName;

  // ── Files ─────────────────────────────────────────────────────────────
  // Required only when [type] is AccountType.person.
  final File? faceIdCard;
  final File? backIdCard;
  // Always required:
  //   - person  -> store front photo (صورة واجهة المحل التجاري)
  //   - company -> commercial register document (صورة السجل التجاري)
  final File commercialRegister;

  // ── Misc ──────────────────────────────────────────────────────────────
  final bool readLicense;
  final String? firebaseToken;
  final String? referralCoupon;
  final String? referralEmail;

  const SignUpRequest({
    required this.phone,
    required this.password,
    required this.firstName,
    required this.email,
    required this.type,
    required this.commercialRegister,
    this.faceIdCard,
    this.backIdCard,
    this.lastName,
    this.sectorId,
    this.address,
    this.governorate,
    this.city,
    this.state,
    this.street,
    this.building,
    this.area,
    this.neighborhood,
    this.latitude,
    this.longitude,
    this.serviceDistance,
    this.servingTheEntireGovernorate = false,
    this.servingTheEntireArea = false,
    this.availableInAllRegions = false,
    this.companyName,
    this.responsibleName,
    this.readLicense = true,
    this.firebaseToken,
    this.referralCoupon,
    this.referralEmail,
  }) : assert(
         type != AccountType.person ||
             (faceIdCard != null && backIdCard != null),
         'faceIdCard and backIdCard are required when type == AccountType.person',
       );

  /// Build the Dio FormData for the multipart POST to /api/auth/signup.
  Future<FormData> toFormData() async {
    final map = <String, dynamic>{
      // username == phone as per API spec
      'username': phone,
      'phone': phone,
      'firstName': firstName,
      'email': email,
      'password': password,
      'type': type,
      'role': const ['vendor'],
      'readLicense': readLicense,
      'servingTheEntireGovernorate': servingTheEntireGovernorate,
      'servingTheEntireArea': servingTheEntireArea,
      'availableInAllRegions': availableInAllRegions,
      // Always-required file (store front photo for person / register for company)
      'commercialRegister': await MultipartFile.fromFile(
        commercialRegister.path,
        filename: commercialRegister.uri.pathSegments.last,
      ),
    };

    // Person-only files
    if (faceIdCard != null) {
      map['faceIdCard'] = await MultipartFile.fromFile(
        faceIdCard!.path,
        filename: faceIdCard!.uri.pathSegments.last,
      );
    }
    if (backIdCard != null) {
      map['backIdCard'] = await MultipartFile.fromFile(
        backIdCard!.path,
        filename: backIdCard!.uri.pathSegments.last,
      );
    }

    // Optional strings
    if (lastName != null && lastName!.isNotEmpty) map['lastName'] = lastName;
    if (sectorId != null && sectorId!.isNotEmpty) map['sectorId'] = sectorId;
    if (address != null && address!.isNotEmpty) map['address'] = address;
    if (governorate != null && governorate!.isNotEmpty)
      map['governorate'] = governorate;
    if (city != null && city!.isNotEmpty) map['city'] = city;
    if (state != null && state!.isNotEmpty) map['state'] = state;
    if (street != null && street!.isNotEmpty) map['street'] = street;
    if (building != null && building!.isNotEmpty) map['building'] = building;
    if (area != null && area!.isNotEmpty) map['area'] = area;
    if (neighborhood != null && neighborhood!.isNotEmpty)
      map['neighborhood'] = neighborhood;
    if (companyName != null && companyName!.isNotEmpty)
      map['companyName'] = companyName;
    if (responsibleName != null && responsibleName!.isNotEmpty)
      map['responsibleName'] = responsibleName;
    if (firebaseToken != null && firebaseToken!.isNotEmpty)
      map['firebaseToken'] = firebaseToken;
    if (referralCoupon != null && referralCoupon!.isNotEmpty)
      map['referralCoupon'] = referralCoupon;
    if (referralEmail != null && referralEmail!.isNotEmpty)
      map['referralEmail'] = referralEmail;

    // Optional numbers
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (serviceDistance != null) map['serviceDistance'] = serviceDistance;

    return FormData.fromMap(map);
  }
}
