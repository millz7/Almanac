import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/nature_book.dart';

/// The size of a mark in a list.
const kNatureMarkSize = 44.0;

/// The size on an entry's own page.
const kLargeNatureMarkSize = 88.0;

/// A small ink mark for something in the Nature Book.
///
/// **A vocabulary, not a field guide.** Seven forms — bird, leaf,
/// flower, insect, butterfly, fungus and a fallback — drawn with Flutter
/// primitives and no assets, with a small deterministic variation per
/// entry so a page is not stamped. Nobody identifies a tūī from a
/// forty-pixel drawing: the **name** does that, and the name is always
/// there in text.
///
/// **Nature moves; the interface stays still.** There are no fluttering
/// wings and no drifting leaves. The one movement is a single settle
/// when a list first appears, and reduced motion skips even that.
///
/// Decorative, so it says nothing to a screen reader.
class NatureMark extends StatelessWidget {
  const NatureMark({
    super.key,
    required this.form,
    this.variant = 0,
    this.growth = 1,
    this.size = kNatureMarkSize,
  });

  final NatureMarkForm form;

  /// 0 to 2. Small differences between entries of the same form.
  final int variant;

  /// How far the mark has settled in, 0–1. One shot, never a loop.
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
          painter: _NaturePainter(
            form: form,
            variant: variant % 3,
            growth: growth.clamp(0.0, 1.0),
            ink: palette.primary,
            wash: palette.water,
            earth: palette.earth,
          ),
        ),
      ),
    );
  }
}

/// The mark for a book entry, with its variation taken from its id so
/// the same entry always looks the same.
class NatureItemMark extends StatelessWidget {
  const NatureItemMark({
    super.key,
    required this.item,
    this.growth = 1,
    this.size = kNatureMarkSize,
  });

  final NatureItem item;
  final double growth;
  final double size;

  @override
  Widget build(BuildContext context) => NatureMark(
    form: item.form,
    variant: item.id.codeUnits.fold(0, (sum, unit) => sum + unit) % 3,
    growth: growth,
    size: size,
  );
}

class _NaturePainter extends CustomPainter {
  const _NaturePainter({
    required this.form,
    required this.variant,
    required this.growth,
    required this.ink,
    required this.wash,
    required this.earth,
  });

  final NatureMarkForm form;
  final int variant;
  final double growth;
  final Color ink;
  final Color wash;
  final Color earth;

  /// Drawn in a 100 by 100 square and scaled.
  static const _grid = 100.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _grid;
    if (scale <= 0) return;

    canvas.save();
    canvas.scale(scale);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3
      ..color = ink;
    final fill = Paint()..color = wash.withValues(alpha: 0.65);

    switch (form) {
      case NatureMarkForm.bird:
        _bird(canvas, line, fill);
      case NatureMarkForm.leaf:
        _leafSprig(canvas, line, fill);
      case NatureMarkForm.flower:
        _flower(canvas, line, fill);
      case NatureMarkForm.insect:
        _insect(canvas, line, fill);
      case NatureMarkForm.butterfly:
        _butterfly(canvas, line, fill);
      case NatureMarkForm.fungus:
        _fungus(canvas, line, fill);
      case NatureMarkForm.other:
        _other(canvas, line, fill);
    }

    canvas.restore();
  }

  /// A leaf: two curves meeting at a point.
  void _leaf(
    Canvas canvas,
    Paint paint,
    Offset base,
    double angle,
    double length,
    double width,
  ) {
    if (length <= 0) return;

    final tip = base + Offset(math.sin(angle), -math.cos(angle)) * length;
    final across = Offset(math.cos(angle), math.sin(angle)) * width;
    final middle = Offset.lerp(base, tip, 0.5)!;

    canvas.drawPath(
      Path()
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
        ..close(),
      paint,
    );
  }

  /// A perched bird: body, head, beak, tail. The tail length is what
  /// separates one bird from another here — long for a fantail, short
  /// for a sparrow.
  void _bird(Canvas canvas, Paint line, Paint fill) {
    final tail = 22.0 + variant * 9;
    const body = Offset(46, 52);

    canvas.drawOval(
      Rect.fromCenter(center: body, width: 40 * growth, height: 28 * growth),
      fill,
    );
    canvas.drawCircle(const Offset(66, 38), 11 * growth, fill);
    // Beak.
    canvas.drawLine(const Offset(76, 37), Offset(76 + 9 * growth, 35), line);
    // Tail.
    canvas.drawLine(
      const Offset(28, 58),
      Offset(28 - tail * 0.7 * growth, 58 + tail * 0.5 * growth),
      line,
    );
    // Perch.
    canvas.drawLine(const Offset(20, 82), const Offset(80, 78), line);
    canvas.drawLine(const Offset(48, 66), const Offset(50, 80), line);
    // Eye.
    canvas.drawCircle(
      const Offset(69, 36),
      1.8,
      Paint()..color = earth.withValues(alpha: 0.9),
    );
  }

  void _leafSprig(Canvas canvas, Paint line, Paint fill) {
    canvas.drawLine(const Offset(50, 86), const Offset(50, 26), line);
    for (var i = 0; i < 3 + variant; i++) {
      final y = 78 - i * 15.0;
      for (final side in [-1.0, 1.0]) {
        _leaf(canvas, fill, Offset(50, y), side * 1.0, 19 * growth, 7 * growth);
      }
    }
  }

  void _flower(Canvas canvas, Paint line, Paint fill) {
    canvas.drawLine(const Offset(50, 86), const Offset(50, 44), line);
    _leaf(canvas, fill, const Offset(50, 70), 1.2, 18 * growth, 7 * growth);

    const centre = Offset(50, 36);
    final petals = 5 + variant;
    for (var i = 0; i < petals; i++) {
      final angle = 2 * math.pi * i / petals;
      _leaf(canvas, fill, centre, angle, 19 * growth, 7 * growth);
    }
    canvas.drawCircle(
      centre,
      5 * growth,
      Paint()..color = earth.withValues(alpha: 0.9),
    );
  }

  void _insect(Canvas canvas, Paint line, Paint fill) {
    const body = Offset(50, 56);
    canvas.drawOval(
      Rect.fromCenter(center: body, width: 26 * growth, height: 34 * growth),
      fill,
    );
    canvas.drawCircle(const Offset(50, 34), 9 * growth, fill);
    // Antennae.
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        const Offset(50, 28),
        Offset(50 + side * 12 * growth, 16),
        line..strokeWidth = 2,
      );
      // Legs.
      for (var i = 0; i < 3; i++) {
        final y = 46 + i * 11.0;
        canvas.drawLine(
          Offset(50 + side * 12, y),
          Offset(50 + side * 26 * growth, y + 6),
          line,
        );
      }
    }
  }

  void _butterfly(Canvas canvas, Paint line, Paint fill) {
    canvas.drawLine(
      const Offset(50, 32),
      const Offset(50, 70),
      line..strokeWidth = 3,
    );
    for (final side in [-1.0, 1.0]) {
      // Upper and lower wing.
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(50 + side * 20 * growth, 42),
          width: 34 * growth,
          height: 26 * growth,
        ),
        fill,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(50 + side * 15 * growth, 64),
          width: 24 * growth,
          height: 20 * growth,
        ),
        fill,
      );
      canvas.drawLine(
        const Offset(50, 32),
        Offset(50 + side * 10 * growth, 20),
        line..strokeWidth = 2,
      );
    }
  }

  void _fungus(Canvas canvas, Paint line, Paint fill) {
    // Stem.
    canvas.drawLine(
      const Offset(50, 82),
      const Offset(50, 52),
      line..strokeWidth = 6,
    );
    // Cap.
    canvas.drawPath(
      Path()
        ..moveTo(22, 54)
        ..quadraticBezierTo(50, 54 - 34 * growth, 78, 54)
        ..close(),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(22, 54)
        ..quadraticBezierTo(50, 54 - 34 * growth, 78, 54),
      line..strokeWidth = 3,
    );
    // A smaller one alongside, for the variants that have it.
    if (variant > 0) {
      canvas.drawLine(const Offset(72, 84), const Offset(72, 68), line);
      canvas.drawPath(
        Path()
          ..moveTo(60, 69)
          ..quadraticBezierTo(72, 69 - 16 * growth, 84, 69)
          ..close(),
        fill,
      );
    }
    // Ground.
    canvas.drawLine(const Offset(16, 84), const Offset(88, 84), line);
  }

  /// Everything else: a simple curved form, enough to say "something
  /// noticed" without pretending to be a portrait.
  void _other(Canvas canvas, Paint line, Paint fill) {
    canvas.drawPath(
      Path()
        ..moveTo(18, 66)
        ..cubicTo(30, 40, 62, 40, 74, 58)
        ..cubicTo(80, 68, 70, 78, 58, 74)
        ..cubicTo(44, 69, 34, 78, 18, 66)
        ..close(),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(18, 66)
        ..cubicTo(30, 40, 62, 40, 74, 58),
      line..strokeWidth = 3,
    );
    canvas.drawCircle(
      const Offset(62, 56),
      2.2,
      Paint()..color = earth.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_NaturePainter old) =>
      old.form != form ||
      old.variant != variant ||
      old.growth != growth ||
      old.ink != ink;
}
