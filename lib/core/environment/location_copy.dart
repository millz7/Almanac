/// The words every screen uses to explain what location is for, and what
/// happens to it.
///
/// One source, because the same promise is made in onboarding, in the
/// Almanac drawer and on the Environment page, and three hand-written
/// copies had already drifted apart — two of them still claimed nothing
/// was ever sent anywhere after weather and tides began making a limited
/// request. Every claim here has to stay true of the code.
abstract final class LocationCopy {
  /// What location adds. Phrased as things the Almanac can show, never as
  /// things the user is missing out on — and never more precise than the
  /// app really is: the tide is a modelled local estimate, not a reading
  /// from a named coast or harbour.
  static const benefits = <String>[
    'Match the seasons around you',
    'Real sunrise and sunset times',
    'Local weather',
    'Local tide estimates',
    'Flora and fauna in your area',
  ];

  /// What happens to the position. Simple on purpose — the provider and
  /// the rounding are documented in the README, not recited to the user.
  static const privacy =
      'Your location is read on this device. An approximate position is '
      'sent only to look up local weather and tide estimates — no '
      'account, no tracking, and no history of where you have been.';
}
