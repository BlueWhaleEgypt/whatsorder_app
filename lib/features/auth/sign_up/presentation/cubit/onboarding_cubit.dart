import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whats_order/core/utils/account_type.dart';
import '../../../../../base/base_repository.dart';
import '../../data/onboarding_data.dart';
import '../../data/sector_response.dart';
import '../../data/sign_up_request.dart';
import '../../data/sign_up_response.dart';
import 'onboarding_state.dart';

/*
|--------------------------------------------------------------------------
| OnboardingCubit
|--------------------------------------------------------------------------
|
| Drives the 3-step wizard (Info → Location → Files).
|
| Key responsibilities:
|   • loadSectors()            — fetches /api/auth/sector on wizard start
|   • setInitialCredentials()  — carries phone+password from SignUpScreen
|   • updateInfo / updateLocation / updateAccountType / file setters …
|   • submit()                 — builds the full SignUpRequest and fires
|                                the single POST /api/auth/signup call
|
| NOTE: this file assumes `OnboardingData` (onboarding_data.dart) has been
| extended with an `AccountType accountType` field (see the migration
| note shared alongside this file) — it's used below to decide which
| files/labels apply and to fill the `type` field on SignUpRequest.
|--------------------------------------------------------------------------
*/

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  // ── Bootstrap ──────────────────────────────────────────────────────────

  /// Called by OnboardingScreen after BlocProvider creates the cubit.
  /// Stores the credentials entered on SignUpScreen so they are included
  /// in the final submit payload.
  void setInitialCredentials({
    required String phone,
    required String password,
  }) {
    emit(
      state.copyWith(
        data: state.data.copyWith(phone: phone, password: password),
      ),
    );
  }

  /// Fetches the sector list from /api/auth/sector.
  Future<void> loadSectors() async {
    emit(state.copyWith(sectorsLoading: true, clearSectorsError: true));

    final result = await BaseRepository('SectorResponse').getData(null);

    result.fold(
      (failure) => emit(
        state.copyWith(sectorsLoading: false, sectorsError: failure.message),
      ),
      (response) => emit(
        state.copyWith(sectorsLoading: false, sectors: response.asSectors()),
      ),
    );
  }

  // ── Step 1: Info ───────────────────────────────────────────────────────

  void updateInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String sectorId,
  }) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          firstName: firstName,
          lastName: lastName,
          email: email,
          sectorId: sectorId,
        ),
      ),
    );
  }

  // ── Step 2: Location ───────────────────────────────────────────────────

  void updateLocation({
    required String governorate,
    required String city,
    required String state_,
    required String street,
    required String building,
    required String area,
    required String neighborhood,
    ServiceArea? serviceArea,
    double? latitude,
    double? longitude,
    double? serviceDistance,
  }) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          governorate: governorate,
          city: city,
          state: state_,
          street: street,
          building: building,
          area: area,
          neighborhood: neighborhood,
          serviceArea: serviceArea,
          latitude: latitude,
          longitude: longitude,
          serviceDistance: serviceDistance,
        ),
      ),
    );
  }

  // ── Step 3: Account type + Files ────────────────────────────────────────

  /// Sets whether this signup is for a person or a company. Shown as a
  /// toggle above the file-upload section on step 3. Switching types
  /// clears files that no longer apply so a stale file can't slip
  /// through validation (e.g. leftover ID card files when switching
  /// from person -> company).
  void updateAccountType(AccountType type) {
    emit(
      state.copyWith(
        data: state.data.copyWith(
          accountType: type,
          // Person-only files are irrelevant once switched to company.
          idCardFront: type == AccountType.person
              ? state.data.idCardFront
              : null,
          idCardBack: type == AccountType.person ? state.data.idCardBack : null,
        ),
      ),
    );
  }

  void updateIdCardFront(File file) {
    emit(state.copyWith(data: state.data.copyWith(idCardFront: file)));
  }

  void updateIdCardBack(File file) {
    emit(state.copyWith(data: state.data.copyWith(idCardBack: file)));
  }

  /// Person -> store front photo (صورة واجهة المحل التجاري)
  /// Company -> commercial register document (صورة السجل التجاري)
  void updateCommercialRegister(File file) {
    emit(state.copyWith(data: state.data.copyWith(commercialRegister: file)));
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  void goToStep(int step) => emit(state.copyWith(currentStep: step));

  void nextStep() {
    if (state.currentStep < 2) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────

  Future<void> submit() async {
    final data = state.data;
    final isPerson = data.accountType == AccountType.person;

    // Guard: required files differ by account type.
    //   person  -> ID card front + back + store front photo
    //   company -> commercial register document only
    if (isPerson) {
      if (data.idCardFront == null ||
          data.idCardBack == null ||
          data.commercialRegister == null) {
        return;
      }
    } else {
      if (data.commercialRegister == null) return;
    }

    // Guard: the API needs coordinates and a service area to place the
    // vendor and route orders — never fire the request without them.
    if (!data.isLocationStepValid) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));
    final fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
    // Build the full request from accumulated wizard data.
    final request = SignUpRequest(
      phone: data.phone,
      password: data.password,
      firstName: data.firstName,
      lastName: data.lastName.isNotEmpty ? data.lastName : null,
      email: data.email,
      type: data.accountType,
      sectorId: data.sectorId.isNotEmpty ? data.sectorId : null,
      governorate: data.governorate.isNotEmpty ? data.governorate : null,
      city: data.city.isNotEmpty ? data.city : null,
      state: data.state.isNotEmpty ? data.state : null,
      street: data.street.isNotEmpty ? data.street : null,
      building: data.building.isNotEmpty ? data.building : null,
      area: data.area.isNotEmpty ? data.area : null,
      neighborhood: data.neighborhood.isNotEmpty ? data.neighborhood : null,
      latitude: data.latitude,
      longitude: data.longitude,
      serviceDistance: data.serviceDistance,
      servingTheEntireGovernorate: data.serviceArea == ServiceArea.governorate,
      servingTheEntireArea: data.serviceArea == ServiceArea.area,
      availableInAllRegions: data.serviceArea == ServiceArea.allRegions,
      faceIdCard: isPerson ? data.idCardFront : null,
      backIdCard: isPerson ? data.idCardBack : null,
      commercialRegister: data.commercialRegister!,
      readLicense: true,
      firebaseToken: fcmToken,
    );

    final result = await const SignupResponse().getData(request);

    result.fold(
      (failure) => emit(
        state.copyWith(isSubmitting: false, submitError: failure.message),
      ),
      (_) => emit(state.copyWith(isSubmitting: false, submitted: true)),
    );
  }
}
