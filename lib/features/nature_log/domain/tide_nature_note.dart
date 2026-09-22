import '../../../core/environment/tide.dart';

/// A quiet, tide-shaped prompt for what might be worth noticing on a
/// shore — never a claim about what is actually there, never a safety
/// instruction, and never naming a species. Only the three tide states
/// the brief this was built against actually asked for get a note; a
/// rising tide or one too far from either state to characterise simply
/// has nothing to say.
enum TideNatureCue { lowShoreline, fallingShoreline, highShoreline }

abstract final class TideNatureNotes {
  static TideNatureCue? cueFor(TideDirection direction) => switch (direction) {
    TideDirection.nearLow => TideNatureCue.lowShoreline,
    TideDirection.falling => TideNatureCue.fallingShoreline,
    TideDirection.nearHigh => TideNatureCue.highShoreline,
    TideDirection.rising || TideDirection.unknown => null,
  };

  static String noteFor(TideNatureCue cue) => switch (cue) {
    TideNatureCue.lowShoreline =>
      'Low tide can reveal more of the shoreline to explore.',
    TideNatureCue.fallingShoreline =>
      'As the tide falls, more of the shore may become visible.',
    TideNatureCue.highShoreline =>
      'The shoreline may look quite different around high tide.',
  };
}
