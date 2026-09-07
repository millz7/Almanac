import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/cycle_calculator.dart';

/// The largest the wheel gets.
const kCycleWheelSize = 240.0;

/// The cycle as a slow circle, with today somewhere on it.
///
/// A soft ring divided into the four approximate phases, with a gap
/// between each one so the boundaries are visible as *gaps* rather than
/// as changes of colour, and a small marker where today falls. Day one
/// is at the top and the year turns clockwise, like everything else in
/// this app that goes round.
///
/// Deliberately not a chart: no axes, no percentages, no readings. The
/// numbers are written underneath it in real text, and the drawing says
/// nothing to a screen reader.
class CycleWheel extends StatelessWidget {
  const CycleWheel({
    super.key,
    required this.moment,
    this.entrance = 1,
    this.size = kCycleWheelSize,
  });

  final CycleMoment moment;

  /// How far the wheel has drawn itself in, 0–1. A one-shot arrival, not
  /// a loop.
  final double entrance;

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ExcludeSemantics(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size, maxHeight: size),
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: _WheelPainter(
                phases: moment.phases,
                length: moment.assumedCycleLength,
                progress: moment.hasCurrentCycle ? moment.progress : null,
                entrance: entrance.clamp(0.0, 1.0),
                track: palette.border,
                marker: palette.primary,
                glow: palette.primarySoft,
                colours: {
                  for (final phase in CyclePhase.values)
                    phase: phaseColour(phase, palette),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The tint each phase is drawn in.
///
/// Decorative only, and never the sole carrier of anything: every phase
/// is named in text wherever it is drawn, and the wheel's own boundaries
/// are gaps rather than colour changes. These are the palette's
/// illustration tokens, so the wheel changes with the season like the
/// rest of the app.
Color phaseColour(CyclePhase phase, SeasonalPalette palette) => switch (phase) {
  CyclePhase.menstrual => palette.earth,
  CyclePhase.follicular => palette.water,
  CyclePhase.ovulatory => palette.accent,
  CyclePhase.luteal => palette.secondary,
};

class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.phases,
    required this.length,
    required this.progress,
    required this.entrance,
    required this.track,
    required this.marker,
    required this.glow,
    required this.colours,
  });

  final List<CyclePhaseSpan> phases;
  final int length;

  /// Where today is, 0–1 around the ring, or null when there is no
  /// current cycle to place.
  final double? progress;

  final double entrance;
  final Color track;
  final Color marker;
  final Color glow;
  final Map<CyclePhase, Color> colours;

  /// Drawn in a 100 by 100 square and scaled, so the geometry reads as
  /// proportions rather than pixels.
  static const _grid = 100.0;
  static const _centre = Offset(50, 50);
  static const _radius = 38.0;

  /// Day one sits at the top.
  static const _start = -math.pi / 2;

  /// The gap left between two phases, in radians.
  static const _gap = 0.055;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _grid;
    if (scale <= 0) return;

    canvas.save();
    canvas.scale(scale);

    final rect = Rect.fromCircle(center: _centre, radius: _radius);

    canvas.drawCircle(
      _centre,
      _radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = track,
    );

    for (final span in phases) {
      final from = _start + (span.firstDay - 1) / length * 2 * math.pi;
      final to = _start + span.lastDay / length * 2 * math.pi;
      final sweep = (to - from - _gap) * entrance;
      if (sweep <= 0) continue;

      canvas.drawArc(
        rect,
        from + _gap / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6
          ..color = colours[span.phase]!,
      );
    }

    _paintMarker(canvas);
    canvas.restore();
  }

  /// Today: a small filled point with a soft halo, eased into place.
  void _paintMarker(Canvas canvas) {
    final position = progress;
    if (position == null) return;

    final angle = _start + position * 2 * math.pi * entrance;
    final at = _centre + Offset(math.cos(angle), math.sin(angle)) * _radius;

    canvas.drawCircle(
      at,
      9,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glow.withValues(alpha: 0.7 * entrance),
            glow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: at, radius: 9)),
    );
    canvas.drawCircle(at, 3.4, Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.entrance != entrance ||
      old.progress != progress ||
      old.length != length ||
      old.phases != phases ||
      old.marker != marker;
}
