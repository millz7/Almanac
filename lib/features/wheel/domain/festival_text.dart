import '../../../core/time/calendar_date.dart';
import 'festival_calendar.dart';
import 'festival_timing.dart';

/// "Next: Beltane · in 12 days", "Next: Yule · tomorrow", "Today: Samhain".
///
/// Calculated from an already-resolved [FestivalOccurrence] rather than
/// reading a clock itself, the same discipline as `describeNextSeason`
/// for the Environment's own countdown.
String describeNextFestival(FestivalOccurrence occurrence, CalendarDate today) {
  final daysUntil = occurrence.date.daysSince(today);
  if (daysUntil <= 0) return 'Today: ${occurrence.id.label}';
  if (daysUntil == 1) return 'Next: ${occurrence.id.label} · tomorrow';
  return 'Next: ${occurrence.id.label} · in $daysUntil days';
}

/// The one line the Environment's TODAY section adds when a festival is
/// worth a quiet mention: "Beltane is approaching · 4 days" or "Today is
/// Beltane". Null when there is nothing to say.
String? describeFestivalContext(
  FestivalOccurrence occurrence,
  FestivalTimingState state,
  CalendarDate today,
) {
  switch (state) {
    case FestivalTimingState.today:
      return 'Today is ${occurrence.id.label}';
    case FestivalTimingState.approaching:
      final daysUntil = occurrence.date.daysSince(today);
      return '${occurrence.id.label} is approaching · $daysUntil '
          '${daysUntil == 1 ? 'day' : 'days'}';
    case FestivalTimingState.normal:
      return null;
  }
}
