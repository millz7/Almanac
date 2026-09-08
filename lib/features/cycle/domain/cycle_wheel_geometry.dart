import 'dart:math' as math;

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../core/time/calendar_date.dart';

/// Where every mark on the month wheel goes.
///
/// **This is a data visualisation, and mathematical consistency outranks
/// composition.** The geometry is therefore a pure value derived from
/// two numbers — how many days the month has, and how wide the wheel is
/// — rather than something a painter arranges by eye. It lives out here
/// so the properties that matter can be *proved* instead of eyeballed:
///
/// * every moon has **exactly** the same diameter, whatever its phase.
///   A new moon is not smaller because less of it is lit, a full moon is
///   not bigger, and **today's moon is not bigger either**;
/// * every moon centre sits at the same radius from the wheel's centre;
/// * the angular spacing between neighbours is identical all the way
///   round.
///
/// Today is shown by **one thin outer ring** drawn around its moon. The
/// ring is a current-date indicator and not part of the moon artwork, so
/// the moon inside it keeps the shared diameter.
///
/// **The wheel is a lunar calendar for the current local month.** One
/// position per calendar date: 28 or 29 in February, 30 in September, 31
/// in October. That was chosen over a synthetic 28-day lunar month
/// because bleeding records *are* calendar dates, the user enters them
/// through a calendar, and the moon for a given local date can be
/// calculated from the existing astronomy — where finding the exact
/// instant a new moon begins would need an astronomy engine the app does
/// not have.
@immutable
class CycleWheelGeometry {
  const CycleWheelGeometry({required this.days, required this.size});

  /// How many positions the wheel has: the days in the month.
  final int days;

  /// The wheel's width and height in logical pixels.
  final double size;

  /// Twelve o'clock. The first of the month starts at the top and the
  /// month runs clockwise, like everything else in this app that goes
  /// round.
  static const startAngle = -math.pi / 2;

  /// The share of the radius the moons' ring sits at.
  static const _orbitFraction = 0.78;

  /// A moon's diameter as a share of the gap between two neighbours,
  /// leaving air between them at every month length.
  static const _packing = 0.62;

  /// The largest a moon may get, as a share of the wheel, so a short
  /// month does not produce eight enormous discs.
  static const _maxDiameterFraction = 0.13;

  double get centreX => size / 2;
  double get centreY => size / 2;

  /// How far every moon centre is from the wheel's centre. One number,
  /// used by all of them.
  double get orbitRadius => size / 2 * _orbitFraction;

  /// The angle from one position to the next. Constant by construction.
  double get angleStep => days <= 0 ? 0 : 2 * math.pi / days;

  /// **One diameter, calculated once, used by every moon.**
  ///
  /// It adapts to the wheel's width and to how many days the month has —
  /// but within a wheel it is a single number, which is what makes "all
  /// moons are the same size" a fact about the code rather than a
  /// promise.
  double get moonDiameter {
    if (days <= 0) return 0;
    // The straight-line gap between neighbouring centres on the orbit.
    final gap = 2 * orbitRadius * math.sin(math.pi / days);
    return math.min(gap * _packing, size * _maxDiameterFraction);
  }

  double get moonRadius => moonDiameter / 2;

  /// The current-day ring: outside the moon, and separate from it.
  double get currentDayRingRadius => moonRadius + moonDiameter * 0.30;

  double get currentDayRingStroke => math.max(1.2, moonDiameter * 0.075);

  /// A bleeding mark's box, sized relative to a moon so the two read as
  /// belonging to one drawing.
  double get markerExtent => moonDiameter * 0.46;

  /// How far out a bleeding mark sits from its moon's centre — beyond
  /// the current-day ring, so a mark and the ring never overlap.
  double get markerOffset => currentDayRingRadius + markerExtent * 0.75;

  /// The angle of the day at [index], zero-based.
  double angleOf(int index) => startAngle + angleStep * index;

  /// The centre of the moon for the day at [index], zero-based.
  Offset centreOf(int index) {
    final angle = angleOf(index);
    return Offset(
      centreX + orbitRadius * math.cos(angle),
      centreY + orbitRadius * math.sin(angle),
    );
  }

  /// Where a bleeding mark for the day at [index] is drawn: on the same
  /// radial line, just outside the moon.
  Offset markerCentreOf(int index) {
    final angle = angleOf(index);
    return Offset(
      centreX + (orbitRadius + markerOffset) * math.cos(angle),
      centreY + (orbitRadius + markerOffset) * math.sin(angle),
    );
  }

  /// Every centre, in day order. Useful to a test that wants to check
  /// the whole ring at once rather than a sample of it.
  List<Offset> get centres => [for (var i = 0; i < days; i++) centreOf(i)];

  /// The geometry for the month [date] falls in.
  static CycleWheelGeometry forMonth(
    CalendarDate date, {
    required double size,
  }) => CycleWheelGeometry(days: date.daysInMonth, size: size);

  @override
  bool operator ==(Object other) =>
      other is CycleWheelGeometry && other.days == days && other.size == size;

  @override
  int get hashCode => Object.hash(days, size);

  @override
  String toString() => 'CycleWheelGeometry($days days, ${size.round()}px)';
}
