import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// The paper a detail page is written on.
///
/// **Why this exists rather than a hard cream.** Environment is the app's
/// living painting; the pages underneath it are paper. But the app is
/// already dressed by eight seasonal palettes including night ones, and a
/// fixed cream would be a white sheet held up in a dark room. So the
/// paper tone is the palette's own ground, warmed a little toward its
/// earth token: warm cream by day, and the same paper by lamplight after
/// dark.
///
/// The warmth is deliberately slight — six per cent — so text contrast
/// is unchanged in every palette. There is a test.
///
/// See `docs/almanac_visual_language.md`: detail pages are paper, not
/// scenery. No landscape, no wreath, one illustration, and mostly space.
class AlmanacPaperSurface extends StatelessWidget {
  const AlmanacPaperSurface({super.key, required this.child});

  final Widget child;

  /// The paper tone for a palette. Exposed so a page can paint it into
  /// something other than this widget — an app bar, say — without
  /// working the blend out again.
  static Color toneOf(SeasonalPalette palette) =>
      Color.lerp(palette.background, palette.earth, 0.06)!;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: toneOf(context.palette), child: child);
}
