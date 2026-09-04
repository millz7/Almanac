import 'moon_calculator.dart';
import 'moon_phase.dart';

export 'moon_phase.dart';

/// Supplies the moon's phase.
///
/// Behind an interface for the same reason `SolarService` is: so the rest
/// of the app depends on the idea of "the moon's phase right now" rather
/// than on one particular way of working it out, and so tests can pin the
/// phase instead of arranging a date that happens to produce one.
///
/// Synchronous, unlike the solar service, because the phase needs no
/// position and no permission — only the instant. There is nothing to
/// wait for.
abstract interface class MoonService {
  /// The moon's phase at [instant].
  MoonPhaseState phaseAt(DateTime instant);
}

/// Calculates the phase on the device, from the moon's elongation from
/// the sun.
///
/// No network, no position, nothing about the user involved: the phase of
/// the moon is the same for everybody on Earth at a given moment. (Which
/// way up the lit part appears is not — that depends on where you are
/// standing — and this does not claim to know it.) See [MoonCalculator]
/// for the algorithm and its accuracy.
class AstronomicalMoonService implements MoonService {
  const AstronomicalMoonService();

  @override
  MoonPhaseState phaseAt(DateTime instant) => MoonCalculator.phaseAt(instant);
}
