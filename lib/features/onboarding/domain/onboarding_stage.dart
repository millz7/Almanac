import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_providers.dart';

/// Where the user has got to in first-launch setup.
///
/// Derived from saved settings rather than stored separately, so there is
/// no second source of truth that could disagree with them.
enum OnboardingStage {
  /// No hemisphere chosen yet. The app cannot know anyone's season, so
  /// this is the one thing it must ask for.
  hemisphere,

  /// Hemisphere chosen; the user has not yet been told what location is
  /// for. They will be asked once, and may decline.
  location,

  /// Setup is done. The app never shows onboarding again unless the saved
  /// settings are cleared.
  complete,
}

final onboardingStageProvider = Provider<OnboardingStage>((ref) {
  final settings = ref.watch(userSettingsProvider);

  if (settings.hemisphere == null) return OnboardingStage.hemisphere;
  if (!settings.locationIntroSeen) return OnboardingStage.location;
  return OnboardingStage.complete;
});
