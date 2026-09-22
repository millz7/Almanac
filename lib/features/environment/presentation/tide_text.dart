import '../../../core/context/almanac_context.dart';
import 'environment_text.dart';

/// Everything the Tides fact and its detail page say.
///
/// Gathered in one file like the rest of the app's copy. The one line
/// every string here must respect: nothing claims harbour-table
/// precision, and nothing is ever shown as though it were safe to plan a
/// crossing around — see [nonNavigationNote].
abstract final class TideText {
  static const title = 'Tides';
  static const back = 'Back to the day';

  static const currentLabel = 'Current';
  static const nextHighLabel = 'Next high';
  static const nextLowLabel = 'Next low';
  static const followingHighLabel = 'Following high';
  static const followingLowLabel = 'Following low';

  /// What the fact strip and the detail page's "Current" line say. The
  /// strip shows only this — never the numbers behind it — see section
  /// 10 of the brief this was built against: one current state, not a
  /// cramped pair of times.
  static String directionLabel(TideDirection direction) => switch (direction) {
    TideDirection.rising => 'Rising',
    TideDirection.falling => 'Falling',
    TideDirection.nearHigh => 'Near high',
    TideDirection.nearLow => 'Near low',
    TideDirection.unknown => EnvironmentText.noValue,
  };

  /// The fact-strip value, and the detail page's own heading, for the
  /// three states that are not [TideAvailable] — which reads
  /// [directionLabel] instead.
  static const locationNeeded = 'Location needed';
  static const unavailableHere = 'Unavailable here';
  static const notAvailableNow = 'Not available now';

  static const locationNeededExplanation =
      "Connect location to see the tide where you are. Everything else "
      "here works without it.";

  static const unavailableHereExplanation =
      "Tide information isn't available for this location. This is "
      "expected well inland, or anywhere the tide model has no coverage "
      "— the app would rather say nothing than guess at a coast.";

  static const providerUnavailableExplanation =
      "The tide could not be looked up just now. It should be back the "
      "next time the Almanac checks.";

  /// Said once, quietly, on the detail page — never a warning banner,
  /// and never implied to be more precise than it is. Exact wording
  /// matters: this is the one place the app states its own limitation
  /// plainly rather than only in a code comment.
  static const nonNavigationNote =
      'Approximate local tide estimate, modelled from sea level rather '
      'than a harbour tide table. Not for navigation.';

  /// "Rising. Next high 8:42 pm. Next low 2:51 am." — the whole fact as
  /// a screen reader hears it, in one node rather than three.
  static String spokenFacts({
    required TideDirection direction,
    String? nextHigh,
    String? nextLow,
  }) {
    final parts = [
      directionLabel(direction),
      if (nextHigh != null) '$nextHighLabel $nextHigh',
      if (nextLow != null) '$nextLowLabel $nextLow',
    ];
    return '${parts.join('. ')}.';
  }
}
