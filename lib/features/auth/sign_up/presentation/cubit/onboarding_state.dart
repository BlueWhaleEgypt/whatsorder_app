import 'package:equatable/equatable.dart';
import '../../data/onboarding_data.dart';
import '../../data/sector_model.dart';

/*
|--------------------------------------------------------------------------
| OnboardingState — single state object for the 3-step wizard:
|   currentStep   0 = Info, 1 = Location, 2 = Files
|   data          Accumulated form data carried through all steps
|   sectors       Live list fetched from /api/auth/sector
|   sectorsLoading Whether a sector fetch is in progress
|   sectorsError  Non-null when the sector fetch failed
|   isSubmitting  True while the final sign-up POST is in flight
|   submitError   Non-null when submit failed
|   submitted     True once the POST succeeded
|--------------------------------------------------------------------------
*/

class OnboardingState extends Equatable {
  final int currentStep;
  final OnboardingData data;

  // Sector dropdown
  final List<SectorModel> sectors;
  final bool sectorsLoading;
  final String? sectorsError;

  // Submit
  final bool isSubmitting;
  final String? submitError;
  final bool submitted;

  const OnboardingState({
    this.currentStep = 0,
    this.data = const OnboardingData(),
    this.sectors = const [],
    this.sectorsLoading = false,
    this.sectorsError,
    this.isSubmitting = false,
    this.submitError,
    this.submitted = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    OnboardingData? data,
    List<SectorModel>? sectors,
    bool? sectorsLoading,
    String? sectorsError,
    bool clearSectorsError = false,
    bool? isSubmitting,
    String? submitError,
    bool clearError = false,
    bool? submitted,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      data: data ?? this.data,
      sectors: sectors ?? this.sectors,
      sectorsLoading: sectorsLoading ?? this.sectorsLoading,
      sectorsError: clearSectorsError ? null : (sectorsError ?? this.sectorsError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearError ? null : (submitError ?? this.submitError),
      submitted: submitted ?? this.submitted,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        data,
        sectors,
        sectorsLoading,
        sectorsError,
        isSubmitting,
        submitError,
        submitted,
      ];
}
