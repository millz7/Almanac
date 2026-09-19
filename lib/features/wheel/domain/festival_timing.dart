import '../../../core/time/calendar_date.dart';

/// How close a festival is, in the coarse terms the rest of the Almanac
/// treats it in.
///
/// **Three states, and no afterglow.** A festival is either more than a
/// week away (nothing to say), inside the week leading up to it, or
/// happening today. The day after, it drops straight back to whichever
/// state the *next* festival is in — there is no week of lingering
/// "recently was" content, which would otherwise mean two festivals
/// could plausibly be active in cross-feature suggestions at once.
enum FestivalTimingState {
  /// More than a week away. No cross-feature context should mention it.
  normal,

  /// One to seven calendar days away.
  approaching,

  /// The local calendar date containing the observance.
  today,
}

/// How close [festivalDate] is to [today].
///
/// Pure and deterministic: given the same two dates this always answers
/// the same way, with no clock of its own.
FestivalTimingState timingStateFor(
  CalendarDate festivalDate,
  CalendarDate today,
) {
  final daysUntil = festivalDate.daysSince(today);
  if (daysUntil == 0) return FestivalTimingState.today;
  if (daysUntil >= 1 && daysUntil <= 7) return FestivalTimingState.approaching;
  return FestivalTimingState.normal;
}
