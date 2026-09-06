import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/meditation_technique.dart';

/// How big the orb's box is allowed to get while the setup controls are
/// still on screen, and once it is the whole experience.
const kOrbSetupSize = 240.0;
const kOrbImmersiveSize = 300.0;

/// How small and how large the breath itself gets, as a fraction of the
/// box's radius. The gap between them is what reads as breathing.
const kOrbRestingScale = 0.46;
const kOrbFullScale = 0.9;

/// Where the orb sits when it is not following a breath — before a
/// session, during the settling second, and throughout one when the
/// device has asked for less motion.
const kOrbStillScale = (kOrbRestingScale + kOrbFullScale) / 2;

/// The glowing ball.
///
/// Luminous rather than a button: a wide soft bloom, a body lit from
/// inside, and a highlight offset from centre so it reads as a sphere
/// with light in it rather than a filled circle. There is no hard edge,
/// no ring and no track — nothing about it should suggest waiting for
/// something to finish.
///
/// Every colour comes from the active palette, so the orb is a warm
/// green-gold bead on a summer afternoon and a cold lantern on a winter
/// night without knowing that either exists.
///
/// **Size is what it says.** Bigger is breathing in, still is holding,
/// smaller is breathing out. Nothing else about the drawing carries
/// information — which is why the painting itself says nothing to a
/// screen reader.
class GlowingOrb extends StatelessWidget {
  const GlowingOrb({
    super.key,
    required this.openness,
    required this.size,
    this.still = false,
    this.nostril,
    this.countdown,
  });

  /// 0.0 fully out, 1.0 fully in.
  final double openness;

  /// The largest the orb's box may be.
  final double size;

  /// Holds the orb at a resting size instead of following [openness].
  ///
  /// Used before a session and when the device has asked for reduced
  /// motion, where the rhythm is carried entirely by the words.
  final bool still;

  /// Which side the breath is using, for alternate-nostril breathing.
  ///
  /// Leans the orb's inner light that way — the gentlest guidance
  /// available, and the reason Balance needs no text hanging around the
  /// orb while it runs.
  final Nostril? nostril;

  /// A number to show inside the orb, for the counted hold. Absent for
  /// every other step.
  final int? countdown;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: size, maxHeight: size),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The painting is decoration: the phase is written out in
              // real text beside it, which is the same information and
              // the primary cue for everyone.
              ExcludeSemantics(
                child: CustomPaint(
                  size: Size.square(size),
                  painter: _OrbPainter(
                    // Eased here rather than in the model: a linear
                    // breath looks mechanical, and how it is drawn is
                    // presentation.
                    openness: still
                        ? kOrbStillScale
                        : kOrbRestingScale +
                              (kOrbFullScale - kOrbRestingScale) *
                                  Curves.easeInOut.transform(
                                    openness.clamp(0.0, 1.0),
                                  ),
                    lean: switch (nostril) {
                      Nostril.left => -1.0,
                      Nostril.right => 1.0,
                      Nostril.both || null => 0.0,
                    },
                    // `water` and `accent` rather than UI colours: the
                    // season's own element with the season's own light in
                    // it. Both are the palette's illustrative tokens,
                    // which is exactly right — the orb carries no
                    // information a reader has to get from its colour.
                    body: palette.water,
                    light: palette.accent,
                    depth: palette.primary,
                  ),
                ),
              ),
              if (countdown != null) _Countdown(value: countdown!),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 4-3-2-1 of a counted hold, inside the orb.
///
/// Decorative on purpose: the hold is announced once, with its length,
/// when it begins. Counting it out loud every second would be noise.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ExcludeSemantics(
      child: Text(
        '$value',
        style: Theme.of(context).textTheme.displayMedium?.copyWith(
          // `textPrimary` is by definition the palette's most legible
          // content colour, and the orb's body is a mid-tone in every
          // palette — so this reads on a pale summer orb and on a dark
          // winter one alike. Softened, so it sits in the orb's light
          // rather than on top of it.
          color: palette.textPrimary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  const _OrbPainter({
    required this.openness,
    required this.lean,
    required this.body,
    required this.light,
    required this.depth,
  });

  /// Already the drawn radius as a fraction of the box's, eased.
  final double openness;

  /// -1 leans the inner light left, 1 right, 0 centres it.
  final double lean;

  final Color body;
  final Color light;
  final Color depth;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    if (radius <= 0) return;

    final centre = Offset(size.width / 2, size.height / 2);
    final orbRadius = radius * openness;

    _paintBloom(canvas, centre, orbRadius);
    _paintBody(canvas, centre, orbRadius);
    _paintInnerLight(canvas, centre, orbRadius);
  }

  /// The air around the orb catching its light. Wide and very faint —
  /// this is what makes it glow rather than sit.
  void _paintBloom(Canvas canvas, Offset centre, double orbRadius) {
    final reach = orbRadius * 1.9;
    canvas.drawCircle(
      centre,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: [
            light.withValues(alpha: 0.22),
            body.withValues(alpha: 0.12),
            body.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.6, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: reach)),
    );
  }

  /// The orb itself: lit from a point inside it, and deepening towards
  /// the far edge, with no outline at all.
  void _paintBody(Canvas canvas, Offset centre, double orbRadius) {
    final rect = Rect.fromCircle(center: centre, radius: orbRadius);
    canvas.drawCircle(
      centre,
      orbRadius,
      Paint()
        ..shader = RadialGradient(
          // Off-centre, so it reads as a sphere rather than a disc. Leans
          // with the breath's own side when a technique has one.
          center: Alignment(-0.25 + lean * 0.45, -0.3),
          radius: 0.85,
          colors: [
            Color.lerp(light, body, 0.35)!,
            body,
            Color.lerp(body, depth, 0.55)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  /// A small soft highlight where the light sits, which is the whole
  /// difference between a ball and a circle.
  void _paintInnerLight(Canvas canvas, Offset centre, double orbRadius) {
    final spot =
        centre + Offset(orbRadius * (-0.22 + lean * 0.4), -orbRadius * 0.26);
    final reach = orbRadius * 0.7;
    canvas.drawCircle(
      spot,
      reach,
      Paint()
        ..shader = RadialGradient(
          colors: [light.withValues(alpha: 0.34), light.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: spot, radius: reach)),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.openness != openness ||
      old.lean != lean ||
      old.body != body ||
      old.light != light ||
      old.depth != depth;
}
