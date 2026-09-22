import 'package:timezone/timezone.dart' as tz;

/// How people experience the day, rather than a solar-geometry phase
/// like dawn/dusk — see `DayPhase` for that. A weather sentence talks
/// about "this morning" or "tonight", which is a human daypart, not an
/// angle of the sun.
enum Daypart {
  morning,
  afternoon,
  evening,
  night;

  /// A short label for the part of the day: "this morning".
  String get phrase => switch (this) {
    Daypart.morning => 'this morning',
    Daypart.afternoon => 'this afternoon',
    Daypart.evening => 'this evening',
    Daypart.night => 'tonight',
  };

  /// The daypart that follows this one — what a narrative looks ahead
  /// towards. Night's "next" is tomorrow morning, which is exactly the
  /// direction its own sentence looks ("towards morning").
  Daypart get next => switch (this) {
    Daypart.morning => Daypart.afternoon,
    Daypart.afternoon => Daypart.evening,
    Daypart.evening => Daypart.night,
    Daypart.night => Daypart.morning,
  };
}

/// The daypart [local] falls in.
///
/// **Fixed, documented, local-clock boundaries** — not a fraction of
/// daylight or a solar angle, which would make "morning" start at a
/// different clock hour every day of the year and read strangely close
/// to a solstice. A human daypart is predictable: the same rough hours
/// every day, wherever the sun happens to be.
///
///   05:00–11:59  morning
///   12:00–16:59  afternoon
///   17:00–20:59  evening
///   21:00–04:59  night
///
/// Takes the local wall time directly — never reads a clock itself — so
/// it is exactly as pure and testable as the rest of the environment
/// domain.
Daypart daypartAt(tz.TZDateTime local) {
  final hour = local.hour;
  if (hour >= 5 && hour < 12) return Daypart.morning;
  if (hour >= 12 && hour < 17) return Daypart.afternoon;
  if (hour >= 17 && hour < 21) return Daypart.evening;
  return Daypart.night;
}
