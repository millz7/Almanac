import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// The wheel's size at ordinary text size.
const kWheelDiagramSize = 240.0;

/// The Wheel of the Year, drawn as a plain circular diagram: a rim, eight
/// evenly spaced festival ticks, and one small mark for today's position.
///
/// **Decorative, and says nothing on its own.** The same discipline as
/// the Cycle's moon wheel: eight points on a rim cannot carry their own
/// names without either crowding at large text or deforming the circle
/// to make room, so this paints nothing but geometry and is excluded
/// from the semantics tree. The festival names, the current season and
/// the next festival are all said in real, readable text around it —
/// see `wheel_screen.dart` — so nothing here is the only way to reach
/// that information.
///
/// **Static.** No animation, no rotation, no pulse: the marker sits
/// exactly where today's date puts it and stays there until the date
/// changes, matching the app's "nature moves, interface stays still"
/// rule for its own chrome.
class WheelDiagram extends StatelessWidget {
  const WheelDiagram({
    super.key,
    required this.currentPosition,
    this.size = kWheelDiagramSize,
  });

  /// Where today sits around the wheel: 0.0 at Yule, up to but not
  /// reaching 1.0 as the wheel comes back around to it. See
  /// `FestivalCalendar.wheelPosition`.
  final double currentPosition;

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _WheelPainter(
          currentPosition: currentPosition,
          rim: palette.border,
          tick: palette.textSecondary,
          marker: palette.primary,
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.currentPosition,
    required this.rim,
    required this.tick,
    required this.marker,
  });

  final double currentPosition;
  final Color rim;
  final Color tick;
  final Color marker;

  static const _festivalCount = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide / 2 * 0.82;

    // The rim: a fine hairline, never a heavy ring.
    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rim,
    );

    // Eight festival ticks, equally spaced. The four astronomical ones —
    // Yule, Ostara, Litha, Mabon — are drawn a little larger, so the
    // wheel's four main spokes read as the solstices and equinoxes they
    // are, with a cross-quarter festival at each mid-point.
    for (var index = 0; index < _festivalCount; index++) {
      final angle = _angleFor(index / _festivalCount);
      final direction = Offset(math.cos(angle), math.sin(angle));
      final onRim = centre + direction * radius;
      final towardCentre = centre + direction * (radius - 12);
      final isQuarterFestival = index.isEven;

      canvas.drawLine(
        onRim,
        towardCentre,
        Paint()
          ..strokeWidth = 1
          ..color = rim,
      );
      canvas.drawCircle(
        onRim,
        isQuarterFestival ? 5 : 3,
        Paint()..color = tick,
      );
    }

    // Today: a small filled mark with a soft halo around it, drawn last
    // so it sits above the rim and every tick.
    final markAngle = _angleFor(currentPosition);
    final markPoint =
        centre + Offset(math.cos(markAngle), math.sin(markAngle)) * radius;
    canvas.drawCircle(
      markPoint,
      9,
      Paint()..color = marker.withValues(alpha: 0.18),
    );
    canvas.drawCircle(markPoint, 4, Paint()..color = marker);
  }

  /// Yule sits at the top of the wheel; the year runs clockwise from
  /// there, the same direction a clock face reads in.
  double _angleFor(double fraction) => -math.pi / 2 + fraction * 2 * math.pi;

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.currentPosition != currentPosition ||
      old.rim != rim ||
      old.tick != tick ||
      old.marker != marker;
}
