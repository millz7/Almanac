import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';

/// Where the user has got to in first-launch setup.
///
/// Derived from saved settings rather than stored separately, so there is
/// no second source of truth that could disagree with them. The one
/// exception is the last stage: `onboardingCompleted` is a real stored
/// flag rather than something inferred, because every question in
/// onboarding has a legitimate "no" — no name, no location, no features —
/// and none of those answers can be told apart from "not asked yet"
/// without recording that the asking happened.
enum OnboardingStage {
  /// Asking what to call them. Skippable.
  name,

  /// No hemisphere chosen yet. The app cannot know anyone's season, so
  /// this is the one thing it must have an answer to.
  hemisphere,

  /// Hemisphere chosen; the user has not yet been told what location is
  /// for. They will be asked once, and may decline.
  location,

  /// Asking which parts of the app they would like. Choosing none is
  /// allowed.
  features,

  /// Setup is done. The app never shows onboarding again unless the saved
  /// settings are cleared.
  complete,
}

final onboardingStageProvider = Provider<OnboardingStage>((ref) {
  final settings = ref.watch(userSettingsProvider);

  // Checked first, so somebody who has finished setup is never sent back
  // through it by a question that did not exist when they set the app up.
  if (settings.onboardingCompleted) return OnboardingStage.complete;

  if (!settings.nameAsked) return OnboardingStage.name;
  if (settings.hemisphere == null) return OnboardingStage.hemisphere;
  if (!settings.locationIntroSeen) return OnboardingStage.location;
  return OnboardingStage.features;
});
