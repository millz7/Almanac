import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/recipe_catalogue.dart';

/// The size a sprig takes on a recipe card.
const kSprigSize = 56.0;

/// The size on a recipe's own page.
const kLargeSprigSize = 96.0;

/// A small botanical mark for a season.
///
/// Four shapes, drawn with Flutter primitives and no assets: spring puts
/// out new leaves and a bud, summer is broad-leaved with something round
/// ripening, autumn has a leaf on its way down, and winter is a bare twig
/// with buds waiting. [variant] gives the four recipes in a collection
/// slightly different sprigs, so a page of cards does not look stamped.
///
/// Purely decorative: the season is written out in words on every card
/// and on every recipe page, so this says nothing to a screen reader.
class SeasonSprig extends StatelessWidget {
  const SeasonSprig({
    super.key,
    required this.season,
    this.variant = 0,
    this.growth = 1,
    this.size = kSprigSize,
  });

  final Season season;

  /// 0 to 3. Leans the stem and changes how many leaves it carries.
  final int variant;

  /// How far the sprig has grown in, 0–1. A one-shot arrival, not a loop.
  final double growth;

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _SprigPainter(
            season: season,
            variant: variant % 4,
            growth: growth.clamp(0.0, 1.0),
            ink: seasonInk(palette, season),
          ),
        ),
      ),
    );
  }
}

class _SprigPainter extends CustomPainter {
  const _SprigPainter({
    required this.season,
    required this.variant,
    required this.growth,
    required this.ink,
  });

  final Season season;
  final int variant;
  final double growth;
  final Color ink;

  /// Drawn in a 100 by 100 square and scaled, so the geometry reads as
  /// proportions rather than pixels.
  static const _grid = 100.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _grid;
    if (scale <= 0) return;

    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4
      ..color = ink;
    final fill = Paint()..color = ink.withValues(alpha: 0.55);

    // The stem leans a little differently for each of the four recipes
    // in a collection.
    final lean = (variant - 1.5) * 7;
    final top = 26 - 6 * growth;
    final stem = Path()
      ..moveTo(50, 92)
      ..quadraticBezierTo(50 + lean, 60, 50 + lean * 1.6, top);
    canvas.drawPath(stem, stroke);

    switch (season) {
      case Season.spring:
        _leaves(canvas, fill, lean, count: 2 + variant % 2, spread: 16);
        // A bud, not yet open.
        canvas.drawCircle(Offset(50 + lean * 1.6, top - 3), 3.2 * growth, fill);
      case Season.summer:
        _leaves(canvas, fill, lean, count: 3 + variant % 2, spread: 22);
        // Something round, ripening.
        canvas.drawCircle(
          Offset(50 + lean * 1.6, top - 5),
          7 * growth,
          Paint()..color = ink.withValues(alpha: 0.35),
        );
        canvas.drawCircle(Offset(50 + lean * 1.6, top - 5), 7 * growth, stroke);
      case Season.autumn:
        _leaves(canvas, fill, lean, count: 2, spread: 20);
        // One leaf already on its way down.
        canvas.save();
        canvas.translate(66 + lean, 78);
        canvas.rotate(0.9 + variant * 0.2);
        _leaf(canvas, Offset.zero, 0, 18 * growth, 9 * growth, fill);
        canvas.restore();
      case Season.winter:
        // Bare, with two short twigs and buds waiting on them.
        for (final side in [-1.0, 1.0]) {
          final from = Offset(50 + lean * 0.6, 66 + (side < 0 ? 0 : 12));
          final to = from + Offset(side * 15 * growth, -10 * growth);
          canvas.drawLine(from, to, stroke);
          canvas.drawCircle(to, 2.6 * growth, fill);
        }
        canvas.drawCircle(Offset(50 + lean * 1.6, top - 2), 2.6 * growth, fill);
    }

    canvas.restore();
  }

  /// Leaves up the stem, alternating sides.
  void _leaves(
    Canvas canvas,
    Paint paint,
    double lean, {
    required int count,
    required double spread,
  }) {
    for (var i = 0; i < count; i++) {
      final t = (i + 1) / (count + 1);
      final base = Offset(50 + lean * t * 1.4, 88 - 56 * t);
      final side = i.isEven ? 1 : -1;
      _leaf(
        canvas,
        base,
        side * (0.7 + 0.15 * i),
        spread * growth,
        spread * 0.5 * growth,
        paint,
      );
    }
  }

  /// One leaf: two curves meeting at a point.
  void _leaf(
    Canvas canvas,
    Offset base,
    double angle,
    double length,
    double width,
    Paint paint,
  ) {
    if (length <= 0) return;

    final tip = base + Offset(math.sin(angle), -math.cos(angle)) * length;
    final across = Offset(math.cos(angle), math.sin(angle)) * width;
    final middle = Offset.lerp(base, tip, 0.5)!;

    final leaf = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(
        middle.dx + across.dx,
        middle.dy + across.dy,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        middle.dx - across.dx,
        middle.dy - across.dy,
        base.dx,
        base.dy,
      )
      ..close();

    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(_SprigPainter old) =>
      old.season != season ||
      old.variant != variant ||
      old.growth != growth ||
      old.ink != ink;
}
