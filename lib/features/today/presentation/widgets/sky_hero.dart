import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/geo_location.dart';
import '../../../../core/environment/moon_phase.dart';
import '../../../../core/environment/natural_environment.dart';
import 'moon_disc.dart';

/// The dominant graphic on the Today screen: sky, hill, water, ground,
/// and whichever of the sun or the moon belongs in it.
///
/// This is the "look out of the window" moment, so it is deliberately
/// large, soft and wordless. It carries no numbers and no readings — the
/// words underneath do that — which is what keeps the screen from feeling
/// like a dashboard.
///
/// **Everything comes from the palette.** No colour is hard-coded here;
/// the sky is built from the season's `water` and `accent` tokens, the
/// land from `earth` and `primary`, so the same painting is a green-and-gold
/// summer afternoon or a deep winter night without any branching on
/// which one it is.
///
/// **What is real and what is composition.** The sun's height above the
/// horizon follows [NaturalEnvironment.dayProgress] — real, calculated
/// from the user's own sunrise and sunset. The moon's *shape* follows the
/// real illuminated fraction. Their left-to-right *placement*, and the
/// stars, are composition: the app does not know where in the sky the
/// moon is, and does not pretend to. That is why the whole painting is
/// marked decorative and states nothing to a screen reader.
class SkyHero extends StatelessWidget {
  const SkyHero({super.key, required this.environment});

  final NaturalEnvironment environment;

  /// Height of the sun's arc, as a fraction of the panel.
  static const _arcHeight = 0.44;

  /// Where the water meets the sky.
  static const _horizon = 0.60;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final daylight = environment.dayNight.daylight;
    final progress = environment.dayProgress;

    // One slow glide when the sun's position changes, and none at all for
    // anyone who has asked their device to reduce motion. Implicit, so a
    // refresh part-way through simply redirects it, and it stops when it
    // arrives — there is no ticker left running behind this screen.
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 900);

    return Semantics(
      // Decorative. The date, season, light and moon are all stated in
      // text elsewhere on the screen, so there is nothing here to read
      // out and nothing lost by skipping it.
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: daylight, end: daylight),
            duration: duration,
            curve: Curves.easeInOut,
            builder: (context, easedDaylight, _) =>
                TweenAnimationBuilder<double>(
                  // -1 stands for "no position to show". Tweening through
                  // it would drag the sun across the sky, so the painter
                  // treats anything negative as absent instead.
                  tween: Tween(begin: progress ?? -1, end: progress ?? -1),
                  duration: duration,
                  curve: Curves.easeInOut,
                  builder: (context, easedProgress, _) => CustomPaint(
                    painter: _SkyPainter(
                      palette: palette,
                      daylight: easedDaylight,
                      dayProgress: easedProgress < 0 ? null : easedProgress,
                      moon: environment.moon,
                      southern: environment.hemisphere == Hemisphere.southern,
                    ),
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter({
    required this.palette,
    required this.daylight,
    required this.dayProgress,
    required this.moon,
    required this.southern,
  });

  final SeasonalPalette palette;
  final double daylight;
  final double? dayProgress;
  final MoonPhaseState moon;
  final bool southern;

  /// Star positions, fixed rather than random so the sky is the same
  /// every time the screen is built and a test can rely on it.
  static const _stars = <(double, double, double)>[
    (0.10, 0.14, 1.1),
    (0.22, 0.30, 0.8),
    (0.31, 0.09, 1.4),
    (0.44, 0.22, 0.9),
    (0.53, 0.06, 1.0),
    (0.61, 0.33, 0.8),
    (0.79, 0.11, 1.3),
    (0.88, 0.27, 0.9),
    (0.94, 0.05, 0.8),
    (0.16, 0.42, 0.8),
    (0.69, 0.44, 0.9),
    (0.37, 0.38, 1.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * SkyHero._horizon;

    _paintSky(canvas, size, horizon);
    _paintStars(canvas, size, horizon);

    final disc = _discCentre(size, horizon);
    // Behind the hills, so the sun genuinely sets into the landscape.
    _paintCelestialBody(canvas, disc, size.width * 0.055);

    _paintHills(canvas, size, horizon);
    _paintWater(canvas, size, horizon, disc);
    _paintBank(canvas, size);
  }

  /// Settles a colour towards the page as the light goes.
  ///
  /// Without this the landscape would be as bright at midnight as at
  /// noon, because a palette describes a season's colours rather than one
  /// moment's brightness. Pulling everything towards [SeasonalPalette.background]
  /// by how dark it is keeps the picture part of the same evening as the
  /// page around it — and still uses nothing but palette tokens.
  Color _settled(Color color, double amount) =>
      Color.lerp(color, palette.background, amount * (1 - daylight))!;

  /// Sky: the season's water colour overhead, warming into its accent at
  /// the horizon. Night palettes make the same gradient deep and quiet
  /// without any special case here.
  void _paintSky(Canvas canvas, Size size, double horizon) {
    final rect = Rect.fromLTRB(0, 0, size.width, horizon);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _settled(palette.water, 0.55),
            _settled(Color.lerp(palette.water, palette.accent, 0.7)!, 0.5),
            _settled(palette.accent, 0.6),
          ],
          stops: const [0, 0.72, 1],
        ).createShader(rect),
    );
  }

  /// Stars fade in as the light goes, and are simply absent by day.
  void _paintStars(Canvas canvas, Size size, double horizon) {
    final strength = (1 - daylight * 1.6).clamp(0.0, 1.0);
    if (strength <= 0.01) return;

    final paint = Paint()
      ..color = palette.textPrimary.withValues(alpha: 0.55 * strength);
    for (final (x, y, r) in _stars) {
      canvas.drawCircle(
        Offset(size.width * x, horizon * y),
        r * strength,
        paint,
      );
    }
  }

  /// Where the sun or moon sits.
  Offset _discCentre(Size size, double horizon) {
    final progress = dayProgress;
    if (progress != null) {
      // A real arc: on the horizon at sunrise and sunset, highest in the
      // middle of the day.
      return Offset(
        size.width * (0.14 + 0.72 * progress),
        horizon -
            math.sin(math.pi * progress) * size.height * SkyHero._arcHeight,
      );
    }
    // No arc to trace — night, a polar day, or no position shared. The
    // body still belongs in the sky; its placement is composition, which
    // is why this graphic tells a screen reader nothing.
    return Offset(size.width * 0.72, size.height * 0.22);
  }

  void _paintCelestialBody(Canvas canvas, Offset centre, double radius) {
    if (daylight >= 0.5) {
      _paintSun(canvas, centre, radius);
    } else {
      paintMoon(
        canvas,
        centre: centre,
        radius: radius,
        illuminatedFraction: moon.illuminatedFraction,
        waxing: moon.elongationDegrees < 180,
        mirrored: southern,
        litColor: palette.textPrimary,
        unlitColor: palette.textPrimary.withValues(alpha: 0.16),
      );
    }
  }

  void _paintSun(Canvas canvas, Offset centre, double radius) {
    final halo = radius * 3.4;
    canvas.drawCircle(
      centre,
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.accent.withValues(alpha: 0.55),
            palette.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: halo)),
    );
    canvas.drawCircle(centre, radius, Paint()..color = palette.background);
  }

  /// Two soft hills, the far one lighter, so there is depth without any
  /// drawn detail.
  void _paintHills(Canvas canvas, Size size, double horizon) {
    final far = Path()
      ..moveTo(0, horizon)
      ..quadraticBezierTo(
        size.width * 0.20,
        horizon - size.height * 0.17,
        size.width * 0.46,
        horizon,
      )
      ..close();
    canvas.drawPath(
      far,
      Paint()
        ..color = _settled(
          Color.lerp(palette.primary, palette.water, 0.55)!,
          0.4,
        ),
    );

    final near = Path()
      ..moveTo(size.width * 0.38, horizon)
      ..quadraticBezierTo(
        size.width * 0.66,
        horizon - size.height * 0.24,
        size.width,
        horizon,
      )
      ..close();
    canvas.drawPath(
      near,
      Paint()
        ..color = _settled(
          Color.lerp(palette.primary, palette.water, 0.28)!,
          0.35,
        ),
    );
  }

  /// The water, with a light path across it under whatever is in the sky.
  void _paintWater(Canvas canvas, Size size, double horizon, Offset disc) {
    final rect = Rect.fromLTRB(0, horizon, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..color = _settled(
          Color.lerp(palette.water, palette.primary, 0.3)!,
          0.45,
        ),
    );

    // The light on the water, as broken strokes rather than a solid
    // column: a shape with edges would read as a pane of glass. The
    // widths are uneven — fixed, not random, so the picture is the same
    // every build — because evenly stacked lines read as a ladder.
    final reflected = daylight >= 0.5 ? palette.accent : palette.textPrimary;
    const widths = [0.55, 1.0, 0.72, 1.0, 0.62, 0.9, 0.5];
    final shimmer = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < widths.length; i++) {
      final t = i / (widths.length - 1);
      final y = horizon + (size.height * 0.84 - horizon) * t;
      final halfWidth = size.width * (0.045 + 0.06 * t) * widths[i];
      shimmer
        ..color = reflected.withValues(alpha: 0.34 * (1 - t * 0.85))
        ..strokeWidth = 3.5 - 2 * t;
      canvas.drawLine(
        Offset(disc.dx - halfWidth, y),
        Offset(disc.dx + halfWidth, y),
        shimmer,
      );
    }

    // A few ripples, close together near the horizon and further apart
    // towards the viewer, which is what makes a flat band read as water.
    final ripple = Paint()
      ..color = palette.background.withValues(alpha: 0.18)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const lines = <(double, double, double)>[
      (0.04, 0.10, 0.30),
      (0.10, 0.55, 0.82),
      (0.17, 0.06, 0.24),
      (0.17, 0.62, 0.90),
    ];
    for (final (dy, from, to) in lines) {
      final y = horizon + (size.height - horizon) * dy;
      canvas.drawLine(
        Offset(size.width * from, y),
        Offset(size.width * to, y),
        ripple,
      );
    }
  }

  /// The near bank, holding the bottom of the picture.
  void _paintBank(Canvas canvas, Size size) {
    final top = size.height * 0.84;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, top + size.height * 0.05)
      ..quadraticBezierTo(
        size.width * 0.42,
        top - size.height * 0.06,
        size.width,
        top + size.height * 0.02,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = _settled(palette.earth, 0.45));
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.palette != palette ||
      old.daylight != daylight ||
      old.dayProgress != dayProgress ||
      old.moon.illuminatedFraction != moon.illuminatedFraction ||
      old.southern != southern;
}
