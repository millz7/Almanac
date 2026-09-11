import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// The paper an inner page of the Almanac is written on.
///
/// **The Environment changes with the world outside; the pages inside
/// the Almanac remain paper.** The ground is a fixed warm cream in all
/// eight palettes — every season, day and night — because opening a
/// detail page should feel like turning to a page of a physical almanac
/// rather than stepping outside again. There is no night paper and no
/// seasonal paper, and there is a test for each.
///
/// It does more than paint a colour: it re-prints the active palette on
/// paper (see [AlmanacPaper.reprint]) and hands that to the theme. So a
/// page inside it goes on using `Theme.of(context).textTheme` and
/// `context.palette` exactly as any other screen does, and gets paper
/// ink and paper-safe accents without knowing anything about either.
/// That is what lets Cycle, a recipe, a plant or a Nature Log entry
/// share one inner-page language later by wrapping themselves in this
/// and changing nothing else.
///
/// The season is not thrown away. Accents, small selected states, the
/// moon's shading and illustration detail still come from the active
/// palette — re-based so a winter night's primary is still legible on
/// cream.
///
/// See `docs/almanac_visual_language.md`: detail pages are paper, not
/// scenery.
class AlmanacPaperSurface extends StatelessWidget {
  const AlmanacPaperSurface({super.key, required this.child});

  final Widget child;

  /// The paper ground. Takes no palette, because it does not depend on
  /// one — the signature is the rule.
  static Color get ground => AlmanacPaper.ground;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.fromPalette(AlmanacPaper.reprint(context.palette)),
    // The paper is painted first, and a transparent [Material] is laid
    // directly on it. That order matters: Material widgets paint their
    // ink on the nearest Material ancestor, and a ColoredBox *between* a
    // list row and its Material would swallow every ripple — which is
    // exactly what Flutter asserts about. Painting the ground outside
    // the Material keeps the page a real surface to press.
    child: ColoredBox(
      color: AlmanacPaper.ground,
      child: Material(type: MaterialType.transparency, child: child),
    ),
  );
}
