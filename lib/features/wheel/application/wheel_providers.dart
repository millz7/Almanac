import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/context/almanac_context.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/environment/geo_location.dart';
import '../../../core/settings/settings_providers.dart';
import '../domain/festival_calendar.dart';
import '../domain/festival_timing.dart';

export '../domain/festival_calendar.dart';
export '../domain/festival_timing.dart';

/// The hemisphere the Wheel of the Year follows: the user's own stated
/// preference, and never a live location fix.
///
/// Every other calculation in the app that needs a hemisphere prefers a
/// real position when one is available — see `resolvedHemisphereProvider`
/// — because a known position is more accurate than a guess. Festivals
/// are different: which tradition's calendar someone is keeping is a
/// question about who they are, not about where their phone currently
/// puts them, so it stays exactly as they chose it during onboarding and
/// is never silently overridden. Falls back to the same technical
/// default used before onboarding has been answered.
final wheelHemisphereProvider = Provider<Hemisphere>(
  (ref) =>
      ref.watch(userSettingsProvider).hemisphere ??
      kTechnicalFallbackHemisphere,
);

/// Every festival's date in the year before, the year of, and the year
/// after today — hemisphere-aware, and the single place this is worked
/// out.
final festivalOccurrencesProvider = Provider<List<FestivalOccurrence>>((ref) {
  final today = ref.watch(todayProvider);
  final hemisphere = ref.watch(wheelHemisphereProvider);
  final zone = ref.watch(timeZoneProvider);
  return FestivalCalendar.occurrencesNear(today, hemisphere, zone);
});

/// The nearest festival on or after today.
final nextFestivalProvider = Provider<FestivalOccurrence>((ref) {
  final today = ref.watch(todayProvider);
  final occurrences = ref.watch(festivalOccurrencesProvider);
  return FestivalCalendar.next(today, occurrences);
});

/// Where today sits around the wheel, 0.0 up to but not reaching 1.0.
final wheelPositionProvider = Provider<double>((ref) {
  final today = ref.watch(todayProvider);
  final occurrences = ref.watch(festivalOccurrencesProvider);
  return FestivalCalendar.wheelPosition(today, occurrences);
});

/// How close the nearest festival is, right now.
final festivalTimingStateProvider = Provider<FestivalTimingState>((ref) {
  final today = ref.watch(todayProvider);
  final next = ref.watch(nextFestivalProvider);
  return timingStateFor(next.date, today);
});
