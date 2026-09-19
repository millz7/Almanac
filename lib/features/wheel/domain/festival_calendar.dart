import 'package:flutter/foundation.dart';

import '../../../core/context/festival_id.dart';
import '../../../core/environment/astronomical_seasons.dart';
import '../../../core/environment/geo_location.dart';
import '../../../core/environment/local_time_zone.dart';
import '../../../core/time/calendar_date.dart';

/// One festival's observance date in a particular year.
@immutable
class FestivalOccurrence {
  const FestivalOccurrence(this.id, this.date);

  final FestivalId id;
  final CalendarDate date;

  @override
  bool operator ==(Object other) =>
      other is FestivalOccurrence && other.id == id && other.date == date;

  @override
  int get hashCode => Object.hash(id, date);

  @override
  String toString() => 'FestivalOccurrence(${id.name}, $date)';
}

/// Works out when each festival of the Wheel of the Year falls, for a
/// given hemisphere.
///
/// **No second astronomy calculator.** The four festivals that sit on an
/// equinox or a solstice use the real astronomical instant from
/// `solarTermInstant`, exactly the primitive the Environment's own
/// season system is built on — never a hard-coded 21 June or 21
/// December, since the true date drifts by a day either way year to
/// year.
///
/// **Hemisphere changes the calendar date, never the meaning.** Yule is
/// always the winter solstice, in whichever hemisphere it is being kept
/// — so it is always genuinely midwinter, just on a different day of the
/// year. The mapping below is what makes that true: a Southern
/// Hemisphere Yule is pinned to the *June* solstice, a Northern one to
/// the *December* solstice, and so on around the wheel.
///
/// **The other four are a documented convention, not astronomy.** Real
/// Wheel-of-the-Year traditions vary on the exact day a cross-quarter
/// festival falls; this app picks one canonical date per festival for
/// v1 — the first of the relevant month — rather than pretending there
/// is a single correct answer. See [_crossQuarterDates].
abstract final class FestivalCalendar {
  /// Which solar term marks each of the four quarter festivals, by
  /// hemisphere.
  static const _quarterTerms = <Hemisphere, Map<FestivalId, SolarTerm>>{
    Hemisphere.northern: {
      FestivalId.yule: SolarTerm.decemberSolstice,
      FestivalId.ostara: SolarTerm.marchEquinox,
      FestivalId.litha: SolarTerm.juneSolstice,
      FestivalId.mabon: SolarTerm.septemberEquinox,
    },
    Hemisphere.southern: {
      FestivalId.litha: SolarTerm.decemberSolstice,
      FestivalId.mabon: SolarTerm.marchEquinox,
      FestivalId.yule: SolarTerm.juneSolstice,
      FestivalId.ostara: SolarTerm.septemberEquinox,
    },
  };

  /// The canonical observance date for each of the four cross-quarter
  /// festivals, by hemisphere: `(month, day)`.
  ///
  /// **The v1 decision, documented here rather than left implicit.**
  /// Northern Hemisphere dates follow the common modern convention of
  /// the first of the month — 1 February, 1 May, 1 August, 1 November —
  /// which is simple, memorable and roughly midway between the
  /// surrounding quarter festivals. Southern Hemisphere dates are the
  /// same convention shifted exactly six months, so each festival keeps
  /// the same seasonal meaning (Southern Imbolc is still the first
  /// stirrings after midwinter, just in August rather than February).
  /// This is a chosen convention, not an astronomically exact midpoint —
  /// the festival pages say so.
  static const _crossQuarterDates =
      <Hemisphere, Map<FestivalId, (int month, int day)>>{
        Hemisphere.northern: {
          FestivalId.imbolc: (2, 1),
          FestivalId.beltane: (5, 1),
          FestivalId.lughnasadh: (8, 1),
          FestivalId.samhain: (11, 1),
        },
        Hemisphere.southern: {
          FestivalId.imbolc: (8, 1),
          FestivalId.beltane: (11, 1),
          FestivalId.lughnasadh: (2, 1),
          FestivalId.samhain: (5, 1),
        },
      };

  /// [id]'s observance date within [year], for [hemisphere].
  static CalendarDate dateOf(
    FestivalId id,
    int year,
    Hemisphere hemisphere,
    LocalTimeZone zone,
  ) {
    final term = _quarterTerms[hemisphere]![id];
    if (term != null) {
      final instant = solarTermInstant(year, term);
      return CalendarDate.from(zone.wallTimeAt(instant));
    }

    final (month, day) = _crossQuarterDates[hemisphere]![id]!;
    return CalendarDate(year, month, day);
  }

  /// All eight festivals of [year], in wheel order.
  static List<FestivalOccurrence> yearOf(
    int year,
    Hemisphere hemisphere,
    LocalTimeZone zone,
  ) => [
    for (final id in FestivalId.values)
      FestivalOccurrence(id, dateOf(id, year, hemisphere, zone)),
  ];

  /// Every occurrence in the year before, the year of, and the year
  /// after [today] — enough to look both forward and backward across a
  /// year boundary without ever running out on either side.
  static List<FestivalOccurrence> occurrencesNear(
    CalendarDate today,
    Hemisphere hemisphere,
    LocalTimeZone zone,
  ) => [
    ...yearOf(today.year - 1, hemisphere, zone),
    ...yearOf(today.year, hemisphere, zone),
    ...yearOf(today.year + 1, hemisphere, zone),
  ];

  /// The nearest festival on or after [today], from [occurrences].
  ///
  /// [occurrences] should come from [occurrencesNear] so there is always
  /// at least one candidate; this is total over that input.
  static FestivalOccurrence next(
    CalendarDate today,
    List<FestivalOccurrence> occurrences,
  ) {
    final upcoming = [
      for (final occurrence in occurrences)
        if (!occurrence.date.isBefore(today)) occurrence,
    ]..sort((a, b) => a.date.compareTo(b.date));
    return upcoming.first;
  }

  /// Where [today] sits around the wheel: 0.0 at Yule, up to but not
  /// reaching 1.0 as the wheel comes back around to it.
  ///
  /// **Interpolated, not linear-by-day-of-year.** The eight festivals
  /// are drawn at equal angular spacing, one eighth of the circle apart,
  /// but the real gap between them in days is not equal — Yule to
  /// Imbolc is roughly six weeks, Ostara to Beltane roughly six weeks
  /// too, but the exact spans vary by a few days each year. The marker's
  /// position within its current eighth is the fraction of days elapsed
  /// between whichever two festivals bound today, so it moves at a
  /// steady pace between one festival and the next rather than jumping
  /// at each one. Deterministic: the same date and hemisphere always
  /// gives the same position.
  static double wheelPosition(
    CalendarDate today,
    List<FestivalOccurrence> occurrences,
  ) {
    final sorted = [...occurrences]..sort((a, b) => a.date.compareTo(b.date));
    final previous = sorted.lastWhere(
      (occurrence) => !occurrence.date.isAfter(today),
    );
    final next = sorted.firstWhere(
      (occurrence) => occurrence.date.isAfter(previous.date),
    );

    final slot = 1 / FestivalId.values.length;
    final slotIndex = FestivalId.values.indexOf(previous.id);

    final totalDays = next.date.daysSince(previous.date);
    final elapsedDays = today.daysSince(previous.date);
    final withinSlot = totalDays <= 0 ? 0.0 : elapsedDays / totalDays;

    return slotIndex * slot + withinSlot.clamp(0.0, 1.0) * slot;
  }
}
