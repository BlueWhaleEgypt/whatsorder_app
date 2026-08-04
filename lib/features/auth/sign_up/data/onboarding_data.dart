// import 'dart:io';

// /*
// |--------------------------------------------------------------------------
// | OnboardingData
// |--------------------------------------------------------------------------
// |
// | Accumulates everything collected across the 3-step wizard (Info →
// | Location → Files) before the final Submit call. Held by
// | OnboardingCubit and mutated with copyWith() as the user moves through
// | each step.
// |
// | The real API sends everything in a single /api/auth/signup multipart
// | POST, so credentials (phone, password) are carried here from the
// | initial screen and merged at submit time.
// |--------------------------------------------------------------------------
// */

// enum ServiceArea { governorate, area, allRegions }

// class OnboardingData {
//   // ── From SignUpScreen (step 0) ────────────────────────────────────────
//   final String phone;
//   final String password;

//   // ── Step 1: User Info ────────────────────────────────────────────────
//   final String firstName;
//   final String lastName;
//   final String email;
//   final String sectorId; // UUID from /api/auth/sector

//   // ── Step 2: Location ─────────────────────────────────────────────────
//   final String governorate;
//   final String city;
//   final String state;
//   final String street;
//   final String building;
//   final String area;
//   final String neighborhood;
//   final double? latitude;
//   final double? longitude;
//   final ServiceArea? serviceArea;
//   final double? serviceDistance;

//   // ── Step 3: Files ────────────────────────────────────────────────────
//   final File? idCardFront;
//   final File? idCardBack;
//   final File? commercialRegister;

//   const OnboardingData({
//     this.phone = '',
//     this.password = '',
//     this.firstName = '',
//     this.lastName = '',
//     this.email = '',
//     this.sectorId = '',
//     this.governorate = '',
//     this.city = '',
//     this.state = '',
//     this.street = '',
//     this.building = '',
//     this.area = '',
//     this.neighborhood = '',
//     this.latitude,
//     this.longitude,
//     this.serviceArea,
//     this.serviceDistance,
//     this.idCardFront,
//     this.idCardBack,
//     this.commercialRegister,
//   });

//   OnboardingData copyWith({
//     String? phone,
//     String? password,
//     String? firstName,
//     String? lastName,
//     String? email,
//     String? sectorId,
//     String? governorate,
//     String? city,
//     String? state,
//     String? street,
//     String? building,
//     String? area,
//     String? neighborhood,
//     double? latitude,
//     double? longitude,
//     ServiceArea? serviceArea,
//     double? serviceDistance,
//     File? idCardFront,
//     File? idCardBack,
//     File? commercialRegister,
//   }) {
//     return OnboardingData(
//       phone: phone ?? this.phone,
//       password: password ?? this.password,
//       firstName: firstName ?? this.firstName,
//       lastName: lastName ?? this.lastName,
//       email: email ?? this.email,
//       sectorId: sectorId ?? this.sectorId,
//       governorate: governorate ?? this.governorate,
//       city: city ?? this.city,
//       state: state ?? this.state,
//       street: street ?? this.street,
//       building: building ?? this.building,
//       area: area ?? this.area,
//       neighborhood: neighborhood ?? this.neighborhood,
//       latitude: latitude ?? this.latitude,
//       longitude: longitude ?? this.longitude,
//       serviceArea: serviceArea ?? this.serviceArea,
//       serviceDistance: serviceDistance ?? this.serviceDistance,
//       idCardFront: idCardFront ?? this.idCardFront,
//       idCardBack: idCardBack ?? this.idCardBack,
//       commercialRegister: commercialRegister ?? this.commercialRegister,
//     );
//   }

//   bool get isInfoStepValid =>
//       firstName.trim().isNotEmpty &&
//       email.trim().isNotEmpty &&
//       sectorId.trim().isNotEmpty;

//   bool get isLocationStepValid => city.trim().isNotEmpty || street.trim().isNotEmpty;

//   bool get isFilesStepValid => idCardFront != null && idCardBack != null;
// }
import 'dart:io';

import 'package:whats_order/core/utils/account_type.dart';

/*
|--------------------------------------------------------------------------
| OnboardingData
|--------------------------------------------------------------------------
|
| Accumulates everything collected across the 3-step wizard (Info →
| Location → Files) before the final Submit call. Held by
| OnboardingCubit and mutated with copyWith() as the user moves through
| each step.
|
| The real API sends everything in a single /api/auth/signup multipart
| POST, so credentials (phone, password) are carried here from the
| initial screen and merged at submit time.
|--------------------------------------------------------------------------
*/

enum ServiceArea { governorate, area, allRegions }

class OnboardingData {
  // ── From SignUpScreen (step 0) ────────────────────────────────────────
  final String phone;
  final String password;

  // ── Step 1: User Info ────────────────────────────────────────────────
  final String firstName;
  final String lastName;
  final String email;
  final String sectorId; // UUID from /api/auth/sector
  final AccountType accountType;

  // ── Step 2: Location ─────────────────────────────────────────────────
  final String governorate;
  final String city;
  final String state;
  final String street;
  final String building;
  final String area;
  final String neighborhood;
  final double? latitude;
  final double? longitude;
  final ServiceArea? serviceArea;
  final double? serviceDistance;

  // ── Step 3: Files ────────────────────────────────────────────────────
  final File? idCardFront;
  final File? idCardBack;
  final File? commercialRegister;

  const OnboardingData({
    this.phone = '',
    this.password = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.sectorId = '',
    this.accountType = AccountType.person,
    this.governorate = '',
    this.city = '',
    this.state = '',
    this.street = '',
    this.building = '',
    this.area = '',
    this.neighborhood = '',
    this.latitude,
    this.longitude,
    this.serviceArea,
    this.serviceDistance,
    this.idCardFront,
    this.idCardBack,
    this.commercialRegister,
  });

  OnboardingData copyWith({
    String? phone,
    String? password,
    String? firstName,
    String? lastName,
    String? email,
    String? sectorId,
    AccountType? accountType,
    String? governorate,
    String? city,
    String? state,
    String? street,
    String? building,
    String? area,
    String? neighborhood,
    double? latitude,
    double? longitude,
    ServiceArea? serviceArea,
    double? serviceDistance,
    // Files use explicit "clear" flags because a nullable positional value
    // can't tell "leave as-is" apart from "set it back to null" (e.g. when
    // switching account type and clearing ID card files).
    File? idCardFront,
    bool clearIdCardFront = false,
    File? idCardBack,
    bool clearIdCardBack = false,
    File? commercialRegister,
    bool clearCommercialRegister = false,
  }) {
    return OnboardingData(
      phone: phone ?? this.phone,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      sectorId: sectorId ?? this.sectorId,
      accountType: accountType ?? this.accountType,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      state: state ?? this.state,
      street: street ?? this.street,
      building: building ?? this.building,
      area: area ?? this.area,
      neighborhood: neighborhood ?? this.neighborhood,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceArea: serviceArea ?? this.serviceArea,
      serviceDistance: serviceDistance ?? this.serviceDistance,
      idCardFront: clearIdCardFront ? null : (idCardFront ?? this.idCardFront),
      idCardBack: clearIdCardBack ? null : (idCardBack ?? this.idCardBack),
      commercialRegister: clearCommercialRegister
          ? null
          : (commercialRegister ?? this.commercialRegister),
    );
  }

  bool get isInfoStepValid =>
      firstName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      sectorId.trim().isNotEmpty;

  bool get isLocationStepValid =>
      city.trim().isNotEmpty || street.trim().isNotEmpty;

  /// Required files differ by account type:
  ///   person  -> ID card front + back + store front photo
  ///   company -> commercial register document only
  bool get isFilesStepValid => accountType == AccountType.person
      ? (idCardFront != null &&
            idCardBack != null &&
            commercialRegister != null)
      : commercialRegister != null;
}
