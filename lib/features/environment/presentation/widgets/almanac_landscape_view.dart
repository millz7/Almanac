import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/environment/geo_location.dart';
import '../../../../core/environment/moon_phase.dart';
import '../../../../core/environment/natural_environment.dart';
import '../../domain/almanac_landscape.dart';
import '../../domain/landscape_appearance.dart';
import 'moon_disc.dart';

/// The Almanac's window: one lake, one bank, one set of hills, painted
/// for the season and the hour.
///
/// **ENVIRONMENT IS OUTSIDE.** This is the app's one immersive surface
/// and the only screen allowed a full landscape. Detail pages stay paper.
///
/// **Fixed aspect ratio, on purpose.** The scene is described in a unit
/// square ([AlmanacLandscape]) and painted into a band of fixed ratio, so
/// projecting a point is a single uniform multiply and the same mountain
/// is the same shape on a 360 dp phone and on a tablet. Stretching the
/// band to whatever height was going would change the apparent angle of
/// every slope, which is the one thing the geometry rule forbids.
///
/// **What is real and what is composition.** The sun's height follows
/// [NaturalEnvironment.dayProgress] — calculated upstream from the user's
/// own sunrise and sunset, by the one solar service. The moon's *shape*
/// is the real illuminated fraction. Their left-to-right placement, the
/// stars, and every plant are composition: the app does not know where in
/// the sky the moon is and does not pretend to. That is why the whole
/// painting is decorative and says nothing to a screen reader — every
/// fact it hints at is written in words underneath it.
class AlmanacLandscapeView extends StatelessWidget {
  const AlmanacLandscapeView({
    super.key,
    required this.environment,
    required this.appearance,
  });

  final NaturalEnvironment environment;
  final LandscapeAppearance appearance;

  /// The band's shape. Landscape-ish, as in the Home reference, where the
  /// painting is wider than it is tall and the page breathes around it.
  static const aspectRatio = 3 / 2;

  @override
  Widget build(BuildContext context) {
    final progress = environment.dayProgress;

    // One slow glide when the sun's position changes, and none for anyone
    // who has asked their device to reduce motion. Implicit, so a refresh
    // part-way through redirects it and it stops when it arrives: there is
    // no ticker left running behind this screen.
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 900);

    return Semantics(
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: TweenAnimationBuilder<double>(
            // -1 stands for "no arc to trace". Tweening through it would
            // drag the sun across the sky, so the painter treats anything
            // negative as absent instead.
            tween: Tween(begin: progress ?? -1, end: progress ?? -1),
            duration: duration,
            curve: Curves.easeInOut,
            builder: (context, eased, _) => CustomPaint(
              painter: LandscapePainter(
                appearance: appearance,
                dayProgress: eased < 0 ? null : eased,
                moon: environment.moon,
                southern: environment.hemisphere == Hemisphere.southern,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the scene. Reads a [LandscapeAppearance] and mixes no colour of
/// its own — every `Color` below comes from the appearance, and there is
/// a test that greps this file for colour literals.
class LandscapePainter extends CustomPainter {
  const LandscapePainter({
    required this.appearance,
    required this.dayProgress,
    required this.moon,
    required this.southern,
  });

  final LandscapeAppearance appearance;

  /// How far through the daylight hours it is, or null when there is no
  /// arc — night, a polar day, or no position shared.
  final double? dayProgress;

  final MoonPhaseState moon;
  final bool southern;

  LandscapeForm get form => appearance.form;

  @override
  void paint(Canvas canvas, Size size) {
    _sky(canvas, size);
    _paintStars(canvas, size);

    final body = _bodyCentre(size);
    // Behind the hills, so the sun genuinely rises out of and sets into
    // the land rather than floating in front of it.
    _celestialBody(canvas, size, body);

    _ranges(canvas, size);
    _water(canvas, size, body);
    _shores(canvas, size);
    _bank(canvas, size);
    _plantings(canvas, size);
    _bough(canvas, size);
  }

  // ── Sky ───────────────────────────────────────────────────────────

  void _sky(Canvas canvas, Size size) {
    final rect = form.sky(size);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: appearance.skyStops,
          stops: const [0, 0.42, 0.74, 1],
        ).createShader(rect),
    );
  }

  /// Fixed positions, so the sky is the same every build and a test can
  /// rely on it. Restrained: a dozen, not a galaxy.
  static const _stars = <(double, double, double)>[
    (0.09, 0.09, 1.1),
    (0.20, 0.20, 0.8),
    (0.29, 0.06, 1.3),
    (0.41, 0.15, 0.9),
    (0.50, 0.04, 1.0),
    (0.58, 0.23, 0.8),
    (0.76, 0.08, 1.2),
    (0.85, 0.19, 0.9),
    (0.93, 0.03, 0.8),
    (0.15, 0.30, 0.8),
    (0.66, 0.31, 0.9),
    (0.35, 0.27, 1.0),
  ];

  void _paintStars(Canvas canvas, Size size) {
    final strength = appearance.starStrength;
    if (strength <= 0.01) return;

    final paint = Paint()
      ..color = appearance.sunColour.withValues(alpha: 0.55 * strength);
    final horizon = size.height * AlmanacLandscape.horizon;
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(
        Offset(size.width * x, horizon * y),
        r * strength,
        paint,
      );
    }
  }

  /// Where the sun or the moon sits.
  Offset _bodyCentre(Size size) {
    final horizon = size.height * AlmanacLandscape.horizon;
    final progress = dayProgress;
    if (progress != null) {
      // A real arc: on the horizon at sunrise and sunset, highest in the
      // middle of the day. The height is the app's own solar progress.
      return Offset(
        size.width * (0.16 + 0.68 * progress),
        horizon - math.sin(math.pi * progress) * size.height * 0.36,
      );
    }
    return Offset(size.width * 0.70, size.height * 0.17);
  }

  void _celestialBody(Canvas canvas, Size size, Offset centre) {
    final radius = size.width * 0.048;

    final halo = radius * 3.6;
    canvas.drawCircle(
      centre,
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            appearance.sunGlow.withValues(alpha: 0.55),
            appearance.sunGlow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: halo)),
    );

    if (appearance.sunIsUp) {
      canvas.drawCircle(centre, radius, Paint()..color = appearance.sunColour);
      return;
    }

    // At night it is the real moon, in its real phase, the right way up
    // for the hemisphere the user is standing in.
    paintMoon(
      canvas,
      centre: centre,
      radius: radius,
      illuminatedFraction: moon.illuminatedFraction,
      waxing: moon.elongationDegrees < 180,
      mirrored: southern,
      litColor: appearance.sunColour,
      unlitColor: appearance.sunColour.withValues(alpha: 0.14),
    );
  }

  // ── Land ──────────────────────────────────────────────────────────

  void _ranges(Canvas canvas, Size size) {
    canvas.drawPath(
      form.ridge(
        AlmanacLandscape.farRange,
        size,
        floor: AlmanacLandscape.horizon,
      ),
      Paint()..color = appearance.farRange,
    );
    canvas.drawPath(
      form.ridge(
        AlmanacLandscape.nearRange,
        size,
        floor: AlmanacLandscape.horizon,
      ),
      Paint()..color = appearance.nearRange,
    );
  }

  void _water(Canvas canvas, Size size, Offset body) {
    final rect = form.water(size);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(appearance.water, appearance.skyStops.last, 0.45)!,
            appearance.water,
          ],
        ).createShader(rect),
    );

    // The light on the water, as broken strokes rather than a column: a
    // shape with edges would read as a pane of glass. The widths are
    // uneven and fixed, because evenly stacked lines read as a ladder.
    const widths = [0.5, 1.0, 0.7, 1.0, 0.6, 0.9, 0.55, 0.8];
    final shimmer = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < widths.length; i++) {
      final t = i / (widths.length - 1);
      final y = rect.top + rect.height * t;
      final halfWidth = size.width * (0.03 + 0.055 * t) * widths[i];
      shimmer
        ..color = appearance.waterLight.withValues(alpha: 0.42 * (1 - t * 0.75))
        ..strokeWidth = 3.2 - 1.9 * t;
      canvas.drawLine(
        Offset(body.dx - halfWidth, y),
        Offset(body.dx + halfWidth, y),
        shimmer,
      );
    }

    // A few ripples: close together near the horizon, further apart
    // towards the viewer, which is what makes a flat band read as water.
    final ripple = Paint()
      ..color = appearance.waterLight.withValues(alpha: 0.20)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    const lines = <(double, double, double)>[
      (0.30, 0.06, 0.26),
      (0.46, 0.52, 0.80),
      (0.62, 0.04, 0.22),
      (0.78, 0.46, 0.72),
      (0.90, 0.10, 0.34),
    ];
    for (final (dy, from, to) in lines) {
      final y = rect.top + rect.height * dy;
      canvas.drawLine(
        Offset(size.width * from, y),
        Offset(size.width * to, y),
        ripple,
      );
    }
  }

  void _shores(Canvas canvas, Size size) {
    final headland = Paint()..color = appearance.headland;
    canvas.drawPath(
      form.smoothed(AlmanacLandscape.leftHeadland, size),
      headland,
    );
    canvas.drawPath(
      form.smoothed(AlmanacLandscape.rightHeadland, size),
      headland,
    );
    canvas.drawPath(form.smoothed(AlmanacLandscape.rightSpur, size), headland);

    final island = Paint()..color = appearance.island;
    for (final shape in AlmanacLandscape.islands) {
      canvas.drawPath(form.smoothed(shape, size), island);
    }
  }

  void _bank(Canvas canvas, Size size) {
    canvas.drawPath(form.bank(size), Paint()..color = appearance.bankColour);
    canvas.drawPath(
      form.smoothed(AlmanacLandscape.boulder, size),
      Paint()..color = appearance.boulderColour,
    );
  }

  // ── Foreground ────────────────────────────────────────────────────

  /// The bank's planting. The *positions* are fixed; how many of them
  /// carry something, and what they carry, is the season's business.
  void _plantings(Canvas canvas, Size size) {
    final density = appearance.vegetationDensity;
    final plantings = AlmanacLandscape.plantings;
    final flowers = appearance.flowers;

    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final (index, planting) in plantings.indexed) {
      // Fixed order, so raising the density adds plants to the same bank
      // rather than rearranging it.
      final standing = (index + 0.5) / plantings.length;
      if (standing > density) continue;

      final (x, groundY, height, lean) = planting;
      final base = Offset(size.width * x, size.height * groundY);
      final scaled = height * (0.62 + 0.38 * density);
      final tip = Offset(
        base.dx + size.width * lean,
        base.dy - size.height * scaled,
      );

      stem
        ..color = index.isEven ? appearance.foliage : appearance.foliageShade
        ..strokeWidth = size.width * 0.005;
      canvas.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(
            base.dx + (tip.dx - base.dx) * 0.35,
            (base.dy + tip.dy) / 2,
            tip.dx,
            tip.dy,
          ),
        stem,
      );

      _leaves(canvas, size, base, tip, density);

      if (flowers.isEmpty) continue;
      // Which form this stem carries: deterministic, and proportional to
      // each planting's share of the bank.
      final pick = ((index * 7) % plantings.length) / plantings.length;
      var running = 0.0;
      for (final flower in flowers) {
        running += flower.share;
        if (pick < running) {
          _flower(canvas, size, tip, flower);
          break;
        }
      }
    }
  }

  void _leaves(
    Canvas canvas,
    Size size,
    Offset base,
    Offset tip,
    double density,
  ) {
    final paint = Paint()..color = appearance.foliage;
    final count = (2 + density * 3).round();
    for (var i = 1; i <= count; i++) {
      final t = i / (count + 1);
      final at = Offset.lerp(base, tip, t)!;
      final length = size.width * 0.028 * (1 - t * 0.4);
      final side = i.isEven ? 1 : -1;
      final leaf = Path()
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo(
          at.dx + length * side,
          at.dy - length * 0.55,
          at.dx + length * 1.5 * side,
          at.dy - length * 0.1,
        )
        ..quadraticBezierTo(
          at.dx + length * side,
          at.dy + length * 0.30,
          at.dx,
          at.dy,
        )
        ..close();
      canvas.drawPath(leaf, paint);
    }
  }

  /// Four silhouettes, not one icon recoloured four ways.
  void _flower(Canvas canvas, Size size, Offset at, FlowerPlanting flower) {
    final unit = size.width * 0.011;
    final petal = Paint()..color = flower.colour;
    final eye = Paint()..color = flower.centre;

    switch (flower.form) {
      // A flat head of tiny florets on radiating spokes.
      case FlowerForm.umbel:
        final spoke = Paint()
          ..color = appearance.foliageShade
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * 0.16;
        for (var i = 0; i < 7; i++) {
          final angle = math.pi + (i / 6) * math.pi;
          final end = Offset(
            at.dx + math.cos(angle) * unit * 1.9,
            at.dy + math.sin(angle) * unit * 0.85,
          );
          canvas.drawLine(at, end, spoke);
          canvas.drawCircle(end, unit * 0.52, petal);
        }
        canvas.drawCircle(at, unit * 0.34, petal);

      // Separate petals around a disc.
      case FlowerForm.daisy:
        for (var i = 0; i < 8; i++) {
          final angle = (i / 8) * 2 * math.pi;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(
                at.dx + math.cos(angle) * unit * 1.05,
                at.dy + math.sin(angle) * unit * 1.05,
              ),
              width: unit * 1.0,
              height: unit * 0.62,
            ),
            petal,
          );
        }
        canvas.drawCircle(at, unit * 0.58, eye);

      // A tight cluster of very small five-petal flowers, each with a
      // pale eye. Read as a cluster; never as one large bloom.
      case FlowerForm.forgetMeNot:
        const cluster = <(double, double)>[
          (0, 0),
          (-1.5, 0.5),
          (1.4, 0.4),
          (-0.7, -1.2),
          (0.8, -1.3),
        ];
        for (final (dx, dy) in cluster) {
          final centre = Offset(at.dx + dx * unit, at.dy + dy * unit);
          for (var i = 0; i < 5; i++) {
            final angle = (i / 5) * 2 * math.pi;
            canvas.drawCircle(
              Offset(
                centre.dx + math.cos(angle) * unit * 0.42,
                centre.dy + math.sin(angle) * unit * 0.42,
              ),
              unit * 0.30,
              petal,
            );
          }
          canvas.drawCircle(centre, unit * 0.18, eye);
        }

      // A dry globe of seeds on a bare stem.
      case FlowerForm.seedHead:
        canvas.drawCircle(at, unit * 0.95, petal);
        final bristle = Paint()
          ..color = flower.centre
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * 0.16;
        for (var i = 0; i < 9; i++) {
          final angle = (i / 9) * 2 * math.pi;
          canvas.drawLine(
            at,
            Offset(
              at.dx + math.cos(angle) * unit * 1.7,
              at.dy + math.sin(angle) * unit * 1.7,
            ),
            bristle,
          );
        }
        canvas.drawCircle(at, unit * 0.45, eye);
    }
  }

  /// The overhanging bough that frames the top-left corner. Same branch
  /// every season; what is on it changes.
  void _bough(Canvas canvas, Size size) {
    final points = [
      for (final point in AlmanacLandscape.bough)
        LandscapeForm.project(point, size),
    ];

    final branch = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      branch.quadraticBezierTo(
        points[i - 1].dx,
        points[i].dy,
        points[i].dx,
        points[i].dy,
      );
    }
    canvas.drawPath(
      branch,
      Paint()
        ..color = appearance.boughColour
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.010
        ..strokeCap = StrokeCap.round,
    );

    final unit = size.width * 0.016;
    for (var i = 1; i < points.length; i++) {
      for (final side in [-1.0, 1.0]) {
        final at = Offset(points[i].dx + side * unit * 1.4, points[i].dy);
        switch (appearance.bough) {
          case BoughDress.blossom:
            for (var p = 0; p < 5; p++) {
              final angle = (p / 5) * 2 * math.pi;
              canvas.drawCircle(
                Offset(
                  at.dx + math.cos(angle) * unit * 0.5,
                  at.dy + math.sin(angle) * unit * 0.5,
                ),
                unit * 0.40,
                Paint()..color = appearance.blossomColour,
              );
            }
          case BoughDress.leaf:
          case BoughDress.turned:
            canvas.drawOval(
              Rect.fromCenter(
                center: at,
                width: unit * 2.3,
                height: unit * 1.1,
              ),
              Paint()
                ..color = appearance.bough == BoughDress.leaf
                    ? appearance.foliage
                    : appearance.blossomColour,
            );
          case BoughDress.bare:
            canvas.drawCircle(
              at,
              unit * 0.30,
              Paint()..color = appearance.blossomColour,
            );
        }
      }
    }
  }

  @override
  bool shouldRepaint(LandscapePainter old) =>
      old.appearance != appearance ||
      old.dayProgress != dayProgress ||
      old.moon.illuminatedFraction != moon.illuminatedFraction ||
      old.southern != southern;
}
