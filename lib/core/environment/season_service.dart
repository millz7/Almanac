import 'astronomical_seasons.dart';
import 'geo_location.dart';
import 'season.dart';

/// Works out which season a moment falls in, for a given hemisphere.
///
/// Synchronous on purpose: this is pure astronomy with no I/O, so callers
/// (including the theme system) never have to await it.
abstract interface class SeasonService {
  SeasonState seasonAt(DateTime instant, Hemisphere hemisphere);
}

/// Determines the season from the true equinox and solstice instants.
///
/// Because an equinox happens at one instant worldwide, comparing absolute
/// instants is automatically correct for every time zone: a user in
/// Auckland and a user in London switch season at the same moment, which
/// falls on different local dates for each of them.
class AstronomicalSeasonService implements SeasonService {
  const AstronomicalSeasonService();

  @override
  SeasonState seasonAt(DateTime instant, Hemisphere hemisphere) {
    final utc = instant.toUtc();
    final (:term, :startedAt, :endsAt) = _quarterContaining(utc);

    return SeasonState(
      season: _seasonStartedBy(term, hemisphere),
      startedAt: startedAt,
      endsAt: endsAt,
    );
  }

  /// Finds which equinox/solstice most recently passed before [utc], and
  /// when the following one arrives.
  ({SolarTerm term, DateTime startedAt, DateTime endsAt}) _quarterContaining(
    DateTime utc,
  ) {
    final year = utc.year;
    final march = solarTermInstant(year, SolarTerm.marchEquinox);
    final june = solarTermInstant(year, SolarTerm.juneSolstice);
    final september = solarTermInstant(year, SolarTerm.septemberEquinox);
    final december = solarTermInstant(year, SolarTerm.decemberSolstice);

    if (utc.isBefore(march)) {
      // Still inside the quarter that began at last year's December solstice.
      return (
        term: SolarTerm.decemberSolstice,
        startedAt: solarTermInstant(year - 1, SolarTerm.decemberSolstice),
        endsAt: march,
      );
    }
    if (utc.isBefore(june)) {
      return (term: SolarTerm.marchEquinox, startedAt: march, endsAt: june);
    }
    if (utc.isBefore(september)) {
      return (term: SolarTerm.juneSolstice, startedAt: june, endsAt: september);
    }
    if (utc.isBefore(december)) {
      return (
        term: SolarTerm.septemberEquinox,
        startedAt: september,
        endsAt: december,
      );
    }
    return (
      term: SolarTerm.decemberSolstice,
      startedAt: december,
      endsAt: solarTermInstant(year + 1, SolarTerm.marchEquinox),
    );
  }

  /// The same astronomical event opens opposite seasons in each hemisphere.
  Season _seasonStartedBy(SolarTerm term, Hemisphere hemisphere) {
    final northern = switch (term) {
      SolarTerm.marchEquinox => Season.spring,
      SolarTerm.juneSolstice => Season.summer,
      SolarTerm.septemberEquinox => Season.autumn,
      SolarTerm.decemberSolstice => Season.winter,
    };

    if (hemisphere == Hemisphere.northern) return northern;

    return switch (northern) {
      Season.spring => Season.autumn,
      Season.summer => Season.winter,
      Season.autumn => Season.spring,
      Season.winter => Season.summer,
    };
  }
}
