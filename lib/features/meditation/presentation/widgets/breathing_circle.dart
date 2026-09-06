import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// The largest the circle's box is allowed to get.
///
/// The breath should be something you rest your eyes on, not something
/// that fills the screen — so on a tablet it stays a circle in a page
/// rather than becoming the page.
const kBreathingCircleMaxSize = 300.0;

/// How small and how large the breath itself gets, as a fraction of the
/// box's radius. The gap between them is what reads as breathing; the
/// space above the larger of the two is where the session ring lives.
const kBreathRestingScale = 0.42;
const kBreathFullScale = 0.86;

/// Where the circle sits when there is nothing to show — before a session
/// starts, and throughout one when the device has asked for less motion.
const kBreathStillScale = (kBreathRestingScale + kBreathFullScale) / 2;

/// The breath, drawn.
///
/// A soft disc that grows and shrinks, with a hairline ring around the
/// outside that fills once over the whole session. Everything is a
/// palette token: the same circle is a warm green on a summer afternoon
/// and a cold blue on a winter night, without knowing that either exists.
///
/// It says nothing to a screen reader. The phase is written underneath in
/// real text, which is the primary cue for everyone — this is the same
/// information, drawn.
class BreathingCircle extends StatelessWidget {
  const BreathingCircle({
    super.key,
    required this.openness,
    required this.sessionProgress,
    this.still = false,
  });

  /// 0.0 fully out, 1.0 fully in.
  final double openness;

  /// How far through the session, 0.0 to 1.0.
  final double sessionProgress;

  /// Holds the breath at a resting size instead of following [openness].
  ///
  /// Used when the device has asked for reduced motion: the rhythm is
  /// then carried entirely by the words, and nothing on screen moves
  /// continuously.
  final bool still;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ExcludeSemantics(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kBreathingCircleMaxSize,
            maxHeight: kBreathingCircleMaxSize,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _BreathingCirclePainter(
                // Eased here rather than in the model: a linear breath
                // looks mechanical, and how it is drawn is presentation.
                openness: still
                    ? kBreathStillScale
                    : Curves.easeInOut.transform(openness.clamp(0.0, 1.0)),
                still: still,
                sessionProgress: sessionProgress.clamp(0.0, 1.0),
                // `water` rather than a UI colour: this is the season's
                // own element, and a breath that fills and empties is
                // closer to a tide than to a control. It is one of the
                // palette's illustrative tokens, which is exactly right
                // here — the circle carries no information of its own,
                // the words do.
                fill: Color.lerp(palette.water, palette.background, 0.3)!,
                edge: palette.primary,
                halo: palette.water,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingCirclePainter extends CustomPainter {
  const _BreathingCirclePainter({
    required this.openness,
    required this.still,
    required this.sessionProgress,
    required this.fill,
    required this.edge,
    required this.halo,
  });

  /// Already eased, or already the resting value when [still].
  final double openness;
  final bool still;
  final double sessionProgress;
  final Color fill;
  final Color edge;
  final Color halo;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) / 2;
    if (radius <= 0) return;

    final centre = Offset(size.width / 2, size.height / 2);
    final breathRadius = still
        ? radius * openness
        : radius *
              (kBreathRestingScale +
                  (kBreathFullScale - kBreathRestingScale) * openness);

    _paintSessionRing(canvas, centre, radius * 0.96);
    _paintHalo(canvas, centre, breathRadius);
    _paintBreath(canvas, centre, breathRadius);
  }

  /// A hairline that draws itself closed, clockwise from the top, over
  /// the whole session.
  ///
  /// Deliberately *only* the arc — no empty track behind it. A ring with
  /// a channel and a sweeping head is a loading spinner, and this is not
  /// something to wait for. An arc that grows until it meets itself reads
  /// as the session gathering up, and is quiet enough to ignore.
  void _paintSessionRing(Canvas canvas, Offset centre, double radius) {
    if (sessionProgress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      2 * math.pi * sessionProgress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = edge.withValues(alpha: 0.35),
    );
  }

  /// A soft edge, so the breath sits in the page rather than being cut
  /// out of it.
  void _paintHalo(Canvas canvas, Offset centre, double breathRadius) {
    final outer = breathRadius * 1.28;
    canvas.drawCircle(
      centre,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [halo.withValues(alpha: 0.35), halo.withValues(alpha: 0)],
          stops: const [0.7, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: outer)),
    );
  }

  void _paintBreath(Canvas canvas, Offset centre, double breathRadius) {
    canvas.drawCircle(centre, breathRadius, Paint()..color = fill);
    canvas.drawCircle(
      centre,
      breathRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = edge.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_BreathingCirclePainter old) =>
      old.openness != openness ||
      old.still != still ||
      old.sessionProgress != sessionProgress ||
      old.fill != fill ||
      old.edge != edge ||
      old.halo != halo;
}
