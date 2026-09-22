import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

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

/// The Almanac's masthead and its standing line.
///
/// The tagline is approved copy and is used **exactly** as written. It is
/// a constant rather than a literal in a widget so that a paraphrase
/// cannot creep in, and so a test can assert the exact words.
abstract final class EnvironmentText {
  static const masthead = 'Almanac';

  // There is no second line under the masthead. The mock-ups carried
  // one; it is not product copy, and the constant that held it was
  // deleted so it cannot quietly come back.
  static const tagline = 'In tune with the natural world and yourself';
  static const today = 'TODAY';

  static const sunLabel = 'The sun';
  static const sunriseLabel = 'Sunrise';
  static const sunsetLabel = 'Sunset';
  static const moonLabel = 'Moon';
  static const tidesLabel = 'Tides';

  /// A value with no value: shown where a time genuinely does not exist.
  static const noValue = '—';

  /// What the strip says on a day the sun does not cross the horizon.
  /// Never a time, because there is not one.
  static String polarSunValue(SolarDayKind kind) => switch (kind) {
    SolarDayKind.sunNeverSets => 'Never sets today',
    SolarDayKind.sunNeverRises => 'Never rises today',
    SolarDayKind.risesAndSets => noValue,
  };

  /// The line under the strip when the sun's times are not simply times.
  /// Null when they are, so nothing is said that need not be.
  static String? sunNote(NaturalEnvironment environment) =>
      switch (environment.solarEvents.kind) {
        SolarDayKind.sunNeverSets =>
          'The sun stays above the horizon all day where you are.',
        SolarDayKind.sunNeverRises =>
          'The sun stays below the horizon all day where you are.',
        SolarDayKind.risesAndSets =>
          environment.solarEvents.hasTimes
              ? null
              : 'Sunrise and sunset need a rough idea of where you are. '
                    'Everything else on this page works without it.',
      };

  /// How long the light lasts, when that is genuinely known.
  static String? dayLengthNote(NaturalEnvironment environment) {
    final length = environment.solarEvents.dayLength;
    if (length == null) return null;
    return '${formatSpan(length)} of light';
  }
}
