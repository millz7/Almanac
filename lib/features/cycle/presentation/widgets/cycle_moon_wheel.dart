import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/geo_location.dart';
import '../../../../core/environment/moon_phase.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../environment/presentation/widgets/moon_disc.dart';
import '../../domain/cycle_wheel_geometry.dart';
import 'bleeding_marker.dart';

/// The wheel's size at ordinary text size.
const kCycleWheelSize = 300.0;

/// How wide the wheel should be drawn, given the space and the text.
///
/// **It grows with the text.** The centre carries three short lines of
/// real text, and at 2x they need room — so rather than shrinking the
/// words to fit a fixed circle, the circle grows to fit the words, up to
/// whatever width the page has. Everything inside is a fraction of the
/// size, so the geometry simply scales.
double cycleWheelSizeFor(BuildContext context, double available) {
  final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
  return math.min(available, kCycleWheelSize * scale);
}

/// The month as a ring of moons, with the cycle in the middle.
///
/// **A data visualisation, not a composition.** Every number it draws
/// with comes from [CycleWheelGeometry], which is a pure value and is
/// tested directly. The properties that matter are therefore facts about
/// the code rather than things somebody checked by eye:
///
/// * **all moons are exactly the same diameter.** A new moon is not
///   smaller for being dark, a full moon is not larger, and today's moon
///   is not larger either;
/// * every moon centre is the same distance from the middle;
/// * the spacing between neighbours is identical all the way round.
///
/// Today is marked by **one thin ring outside** its moon — a
/// current-date indicator, not part of the moon artwork, so the moon
/// inside keeps the shared diameter.
///
/// One position per calendar date, so a 28-, 29-, 30- or 31-day month
/// each fills the ring exactly. Each moon is the real phase for that
/// date, from the app's one moon service.
///
/// Bleeding marks sit just outside their date's moon, drawn from the
/// same [BleedingMarkers] specs the legend and the calendar use.
///
/// Decorative in full: thirty moons say nothing useful one at a time, so
/// the drawing is excluded and the page states the summary in words.
class CycleMoonWheel extends StatelessWidget {
  const CycleMoonWheel({
    super.key,
    required this.month,
    required this.today,
    required this.moons,
    required this.records,
    required this.hemisphere,
    this.size = kCycleWheelSize,
    this.centre,
  });

  /// Any date in the month being drawn.
  final CalendarDate month;

  /// Today, so the current-day ring goes in the right place. Drawn only
  /// when today falls in [month].
  final CalendarDate today;

  /// One phase per day of the month, in day order.
  final List<MoonPhaseState> moons;

  /// What the user recorded, keyed by day of the month.
  final Map<int, CycleDayRecord> records;

  /// Which way round the light falls.
  final Hemisphere hemisphere;

  final double size;

  /// What sits in the middle: the cycle day and the phase, in real text.
  final Widget? centre;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final geometry = CycleWheelGeometry.forMonth(month, size: size);

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: CustomPaint(
              size: Size.square(size),
              painter: _WheelPainter(
                geometry: geometry,
                moons: moons,
                records: records,
                mirrored: hemisphere == Hemisphere.southern,
                currentDayIndex:
                    today.year == month.year && today.month == month.month
                    ? today.day - 1
                    : null,
                lit: palette.textPrimary,
                unlit: palette.textPrimary.withValues(alpha: 0.12),
                ring: palette.primary,
              ),
            ),
          ),
          if (centre case final middle?)
            // Inside the ring of moons, with room to spare, so a long
            // phase name at 2x text has somewhere to wrap. The moons
            // orbit at 0.78 of the radius, so a little over half the
            // width is clear of them.
            SizedBox(
              width: size * 0.60,
              child: Center(child: middle),
            ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.geometry,
    required this.moons,
    required this.records,
    required this.mirrored,
    required this.currentDayIndex,
    required this.lit,
    required this.unlit,
    required this.ring,
  });

  final CycleWheelGeometry geometry;
  final List<MoonPhaseState> moons;
  final Map<int, CycleDayRecord> records;
  final bool mirrored;
  final int? currentDayIndex;
  final Color lit;
  final Color unlit;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    // The one diameter, taken once and used by every moon below.
    final radius = geometry.moonRadius;
    if (radius <= 0) return;

    for (var index = 0; index < geometry.days; index++) {
      final centre = geometry.centreOf(index);

      // The current-day ring first, so it sits behind its moon rather
      // than over the edge of it.
      if (index == currentDayIndex) {
        canvas.drawCircle(
          centre,
          geometry.currentDayRingRadius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = geometry.currentDayRingStroke
            ..color = ring,
        );
      }

      final moon = index < moons.length ? moons[index] : null;
      if (moon != null) {
        paintMoon(
          canvas,
          centre: centre,
          // Every moon, every phase, every day: one radius.
          radius: radius,
          illuminatedFraction: moon.illuminatedFraction,
          waxing: moon.elongationDegrees < 180,
          mirrored: mirrored,
          litColor: lit,
          unlitColor: unlit,
        );
      }

      if (records[index + 1] case final record?) {
        paintBleedingMarker(
          canvas,
          spec: BleedingMarkers.of(record.level),
          centre: geometry.markerCentreOf(index),
          half: geometry.markerExtent,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.geometry != geometry ||
      old.currentDayIndex != currentDayIndex ||
      old.mirrored != mirrored ||
      old.lit != lit ||
      old.records.length != records.length ||
      old.moons.length != moons.length;
}
