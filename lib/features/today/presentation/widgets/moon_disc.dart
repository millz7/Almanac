import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/environment/moon_phase.dart';

/// Draws the moon as it is lit right now.
///
/// Painted rather than shipped as artwork: the shape is a continuous
/// function of the illuminated fraction, so it is right on every night of
/// the cycle instead of snapping between eight pictures, and it takes its
/// colours from the active seasonal palette like everything else.
///
/// **What this is and is not.** The *shape* is real — it follows the
/// illuminated fraction the calculation produced. The lit side is real
/// too, and depends on the hemisphere: a waxing moon is lit on the right
/// as seen from the north and on the left as seen from the south, which
/// is why [mirrored] exists. What is *not* claimed is the moon's tilt, its
/// position in the sky, or whether it is above the horizon at all — none
/// of which this knows.
class MoonDisc extends StatelessWidget {
  const MoonDisc({
    super.key,
    required this.moon,
    required this.size,
    required this.litColor,
    required this.unlitColor,
    this.mirrored = false,
  });

  final MoonPhaseState moon;

  /// Diameter in logical pixels.
  final double size;

  /// The sunlit part of the disc.
  final Color litColor;

  /// The part in shadow. Kept visible but quiet, so the moon reads as a
  /// whole sphere with a shadow rather than as a floating sliver.
  final Color unlitColor;

  /// Flips the lit side, for a southern-hemisphere observer.
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    // Decorative: the phase is stated in words next to it, so a screen
    // reader gains nothing from the drawing.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _MoonPainter(
            illuminatedFraction: moon.illuminatedFraction,
            waxing: moon.elongationDegrees < 180,
            mirrored: mirrored,
            litColor: litColor,
            unlitColor: unlitColor,
          ),
        ),
      ),
    );
  }
}

/// Draws the moon's shape onto a canvas, given the geometry.
///
/// A free function rather than a method so the Today screen's sky can draw
/// the same moon inside its own painting without duplicating the shape —
/// there is one description of what the moon looks like tonight.
///
/// [illuminatedFraction] is 0–1. [waxing] and [mirrored] decide which side
/// the light comes from: waxing is lit on the right as seen from the
/// northern hemisphere, and [mirrored] turns that over for the south.
void paintMoon(
  Canvas canvas, {
  required Offset centre,
  required double radius,
  required double illuminatedFraction,
  required bool waxing,
  required bool mirrored,
  required Color litColor,
  required Color unlitColor,
}) {
  if (radius <= 0) return;

  final discRect = Rect.fromCircle(center: centre, radius: radius);
  final disc = Path()..addOval(discRect);

  // The whole sphere first, in shadow.
  canvas.drawPath(disc, Paint()..color = unlitColor);

  final lit = _litPath(
    disc: disc,
    discRect: discRect,
    centre: centre,
    radius: radius,
    illuminatedFraction: illuminatedFraction,
    waxing: waxing,
    mirrored: mirrored,
  );
  if (lit != null) canvas.drawPath(lit, Paint()..color = litColor);
}

/// The lit region of the disc, or null when nothing is lit.
///
/// The terminator — the line between light and shadow — is a circle on
/// the sphere, and a circle seen at an angle projects to an ellipse. Its
/// vertical semi-axis is always the moon's radius; its horizontal one
/// shrinks to zero at the quarters, when the terminator is edge-on and
/// looks straight. So the lit region is the lit half of the disc, with
/// that ellipse either cut out of it (a crescent) or added to it (a
/// gibbous moon).
Path? _litPath({
  required Path disc,
  required Rect discRect,
  required Offset centre,
  required double radius,
  required double illuminatedFraction,
  required bool waxing,
  required bool mirrored,
}) {
  final fraction = illuminatedFraction.clamp(0.0, 1.0);
  if (fraction <= 0.005) return null;
  if (fraction >= 0.995) return disc;

  // The illuminated fraction is (1 - cos elongation) / 2, so the
  // ellipse's horizontal semi-axis, radius * |cos elongation|, is this.
  final semiAxis = radius * (1 - 2 * fraction).abs();
  final terminator = Path()
    ..addOval(
      Rect.fromCenter(center: centre, width: semiAxis * 2, height: radius * 2),
    );

  // Which side the sunlight comes from. Waxing is lit on the right for
  // a northern observer; the southern sky turns the whole thing over.
  final litOnRight = waxing != mirrored;
  final litHalf = Path()
    ..addRect(
      Rect.fromLTRB(
        litOnRight ? centre.dx : discRect.left,
        discRect.top,
        litOnRight ? discRect.right : centre.dx,
        discRect.bottom,
      ),
    );
  final litHalfDisc = Path.combine(PathOperation.intersect, disc, litHalf);

  return fraction < 0.5
      // Crescent: the ellipse bulges into the lit half and eats most of
      // it, leaving a sliver against the limb.
      ? Path.combine(PathOperation.difference, litHalfDisc, terminator)
      // Gibbous: the ellipse spills over into the shadowed half.
      : Path.combine(
          PathOperation.union,
          litHalfDisc,
          Path.combine(PathOperation.intersect, disc, terminator),
        );
}

class _MoonPainter extends CustomPainter {
  const _MoonPainter({
    required this.illuminatedFraction,
    required this.waxing,
    required this.mirrored,
    required this.litColor,
    required this.unlitColor,
  });

  final double illuminatedFraction;
  final bool waxing;
  final bool mirrored;
  final Color litColor;
  final Color unlitColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    paintMoon(
      canvas,
      centre: Offset(size.width / 2, size.height / 2),
      radius: radius,
      illuminatedFraction: illuminatedFraction,
      waxing: waxing,
      mirrored: mirrored,
      litColor: litColor,
      unlitColor: unlitColor,
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.illuminatedFraction != illuminatedFraction ||
      old.waxing != waxing ||
      old.mirrored != mirrored ||
      old.litColor != litColor ||
      old.unlitColor != unlitColor;
}
