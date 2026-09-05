import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/environment/day_night.dart';
import '../../../core/environment/natural_environment.dart';
import '../../../core/environment/season.dart';
import '../../../core/environment/solar_service.dart';

/// The words the Environment screen uses.
///
/// Kept out of the widgets so the phrasing can be read, reviewed and
/// tested in one place — and so it is obvious at a glance that nothing
/// here invents a fact. Every string is either fixed text or derived from
/// the environment the app actually resolved.
///
/// English only for now, and the date and time formats deliberately come
/// from Flutter's own localisations rather than being hand-rolled, so the
/// clock follows the device's 12/24-hour setting.
const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "Thursday 4 September" — the user's local date, in their own day.
String formatLongDate(tz.TZDateTime local) =>
    '${_weekdays[local.weekday - 1]} ${local.day} ${_months[local.month - 1]}';

/// A local clock time, following the device's 12/24-hour preference.
String formatClockTime(BuildContext context, tz.TZDateTime local) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: local.hour, minute: local.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// "14 hours 32 minutes", for a span of daylight.
String formatSpan(Duration span) {
  final hours = span.inHours;
  final minutes = span.inMinutes.remainder(60);
  final hourPart = '$hours ${hours == 1 ? 'hour' : 'hours'}';
  if (minutes == 0) return hourPart;
  return '$hourPart $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
}

/// "Early summer", "Summer", "Late summer".
///
/// Taken from how far through the season the real equinox/solstice
/// boundaries put us, so it is a description rather than a guess.
String describeSeason(SeasonState season, DateTime instant) {
  final elapsed = season.fractionElapsedAt(instant);
  final name = season.season.label.toLowerCase();
  if (elapsed < 0.28) return 'Early $name';
  if (elapsed > 0.72) return 'Late $name';
  return season.season.label;
}

/// "Autumn arrives in 78 days" — the next real turning point.
String describeNextSeason(SeasonState season, DateTime instant) {
  final next = season.season.next.label;
  final days = season.endsAt.difference(instant.toUtc()).inDays;
  return switch (days) {
    <= 0 => '$next arrives today',
    1 => '$next arrives tomorrow',
    _ => '$next arrives in $days days',
  };
}

/// A short, honest line about where the light is.
///
/// Says only what the app knows. When the times were estimated from the
/// clock because no position has been shared, it says so instead of
/// implying a sunrise it has not calculated.
String describeLight(NaturalEnvironment environment) {
  switch (environment.solarEvents.kind) {
    case SolarDayKind.sunNeverSets:
      return 'The sun does not set here today';
    case SolarDayKind.sunNeverRises:
      return 'The sun stays below the horizon today';
    case SolarDayKind.risesAndSets:
      break;
  }

  final estimated =
      environment.dayNight.accuracy ==
      DayNightAccuracy.estimatedWithoutLocation;

  return switch (environment.dayNight.phase) {
    DayPhase.dawn => 'The light is coming back',
    DayPhase.day => estimated ? 'Daylight, by the clock' : 'The sun is up',
    DayPhase.dusk => 'The light is going',
    DayPhase.night =>
      estimated ? 'Night, by the clock' : 'Dark, and the world is resting',
  };
}
