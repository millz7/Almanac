import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/plant_book.dart';

/// The size of a plant mark in a list.
const kPlantMarkSize = 44.0;

/// The size on a plant's own page.
const kLargePlantMarkSize = 96.0;

/// A small botanical mark for a plant.
///
/// **A vocabulary, not a portrait gallery.** Ten forms — a leafy green,
/// a root, a climber, a fruiting stem, a bulb, a herb sprig, a shrub, a
/// tree, a flower, a vine — drawn with Flutter primitives and no assets.
/// Sixty hand-drawn species would be a painter layer bigger than the
/// rest of the feature, and it would still not be how anybody
/// identifies a plant: the **name** does that, and the name is always
/// there in text.
///
/// Purely decorative, so it says nothing to a screen reader.
class PlantMark extends StatelessWidget {
  const PlantMark({
    super.key,
    required this.plant,
    this.growth = 1,
    this.size = kPlantMarkSize,
  });

  final PlantDefinition plant;

  /// How far the mark has drawn itself in, 0–1. A one-shot arrival.
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
          painter: _MarkPainter(
            form: plant.form,
            // Small deterministic variation between species of the same
            // form, so a page of leafy greens is not stamped.
            variant: plant.id.codeUnits.fold(0, (sum, unit) => sum + unit) % 3,
            growth: growth.clamp(0.0, 1.0),
            stem: palette.primary,
            leaf: palette.water,
            earth: palette.earth,
          ),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter({
    required this.form,
    required this.variant,
    required this.growth,
    required this.stem,
    required this.leaf,
    required this.earth,
  });

  final PlantForm form;
  final int variant;
  final double growth;
  final Color stem;
  final Color leaf;
  final Color earth;

  /// Drawn in a 100 by 100 square and scaled.
  static const _grid = 100.0;
  static const _ground = 84.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _grid;
    if (scale <= 0) return;

    canvas.save();
    canvas.scale(scale);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = stem;
    final fill = Paint()..color = leaf.withValues(alpha: 0.7);
    final soil = Paint()..color = earth.withValues(alpha: 0.8);

    switch (form) {
      case PlantForm.leafyGreen:
        _rosette(canvas, line, fill, leaves: 5 + variant);
      case PlantForm.root:
        _root(canvas, line, fill, soil);
      case PlantForm.climber:
        _climber(canvas, line, fill);
      case PlantForm.fruiting:
        _fruiting(canvas, line, fill);
      case PlantForm.bulb:
        _bulb(canvas, line, fill, soil);
      case PlantForm.herb:
        _sprig(canvas, line, fill);
      case PlantForm.shrub:
        _shrub(canvas, line, fill);
      case PlantForm.tree:
        _tree(canvas, line, fill);
      case PlantForm.flower:
        _flower(canvas, line, fill);
      case PlantForm.vine:
        _vine(canvas, line, fill);
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

  void _rosette(Canvas canvas, Paint line, Paint fill, {required int leaves}) {
    const base = Offset(50, _ground);
    for (var i = 0; i < leaves; i++) {
      final spread = 1.5;
      final angle = -spread + 2 * spread * i / (leaves - 1);
      _leaf(canvas, fill, base, angle, 52 * growth, 15 * growth);
    }
  }

  void _root(Canvas canvas, Paint line, Paint fill, Paint soil) {
    // The root below the line, tapering.
    canvas.drawPath(
      Path()
        ..moveTo(38, _ground - 22)
        ..quadraticBezierTo(
          50,
          _ground + 14 * growth,
          50,
          _ground + 16 * growth,
        )
        ..quadraticBezierTo(50, _ground + 14 * growth, 62, _ground - 22)
        ..close(),
      soil,
    );
    // And the tops above it.
    for (final angle in [-0.5, 0.0, 0.5]) {
      _leaf(
        canvas,
        fill,
        const Offset(50, _ground - 20),
        angle,
        34 * growth,
        8 * growth,
      );
    }
  }

  void _climber(Canvas canvas, Paint line, Paint fill) {
    canvas.drawLine(const Offset(30, _ground), const Offset(30, 20), line);
    final path = Path()..moveTo(30, _ground);
    for (var i = 0; i < 4; i++) {
      final y = _ground - (i + 1) * 16 * growth;
      path.quadraticBezierTo(30 + (i.isEven ? 22 : -6), y + 8, 30, y);
      _leaf(
        canvas,
        fill,
        Offset(30, y),
        i.isEven ? 1.2 : -1.2,
        20 * growth,
        7 * growth,
      );
    }
    canvas.drawPath(path, line..strokeWidth = 2);
  }

  void _fruiting(Canvas canvas, Paint line, Paint fill) {
    canvas.drawLine(const Offset(50, _ground), const Offset(50, 24), line);
    for (final (index, y) in [58.0, 42.0, 30.0].indexed) {
      final side = index.isEven ? 1 : -1;
      _leaf(canvas, fill, Offset(50, y), side * 1.1, 20 * growth, 7 * growth);
      canvas.drawCircle(
        Offset(50 - side * 13, y + 4),
        6 * growth,
        Paint()..color = leaf.withValues(alpha: 0.45),
      );
    }
  }

  void _bulb(Canvas canvas, Paint line, Paint fill, Paint soil) {
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, _ground - 4),
        width: 26,
        height: 20,
      ),
      soil,
    );
    for (final angle in [-0.35, -0.1, 0.15, 0.4]) {
      _leaf(
        canvas,
        fill,
        const Offset(50, _ground - 12),
        angle,
        50 * growth,
        6 * growth,
      );
    }
  }

  void _sprig(Canvas canvas, Paint line, Paint fill) {
    canvas.drawLine(const Offset(50, _ground), const Offset(50, 34), line);
    for (var i = 0; i < 3 + variant; i++) {
      final y = _ground - 12 - i * 14.0;
      for (final side in [-1.0, 1.0]) {
        _leaf(canvas, fill, Offset(50, y), side * 0.9, 16 * growth, 6 * growth);
      }
    }
  }

  void _shrub(Canvas canvas, Paint line, Paint fill) {
    for (final lean in [-0.45, 0.0, 0.45]) {
      canvas.drawLine(
        const Offset(50, _ground),
        Offset(50 + lean * 40, 40),
        line..strokeWidth = 2.5,
      );
      _leaf(
        canvas,
        fill,
        Offset(50 + lean * 40, 40),
        lean,
        22 * growth,
        11 * growth,
      );
    }
  }

  void _tree(Canvas canvas, Paint line, Paint fill) {
    canvas.drawLine(
      const Offset(50, _ground),
      const Offset(50, 52),
      line..strokeWidth = 4,
    );
    canvas.drawLine(const Offset(50, 62), const Offset(34, 48), line);
    canvas.drawLine(const Offset(50, 58), const Offset(66, 44), line);
    canvas.drawCircle(const Offset(50, 38), 24 * growth, fill);
  }

  void _flower(Canvas canvas, Paint line, Paint fill) {
    canvas.drawLine(const Offset(50, _ground), const Offset(50, 40), line);
    _leaf(canvas, fill, const Offset(50, 64), 1.2, 18 * growth, 7 * growth);
    const centre = Offset(50, 34);
    final petals = 6 + variant;
    for (var i = 0; i < petals; i++) {
      final angle = 2 * math.pi * i / petals;
      _leaf(canvas, fill, centre, angle, 18 * growth, 6 * growth);
    }
    canvas.drawCircle(centre, 5, Paint()..color = earth.withValues(alpha: 0.9));
  }

  void _vine(Canvas canvas, Paint line, Paint fill) {
    final path = Path()..moveTo(16, _ground);
    path.cubicTo(40, 74, 24, 46, 50, 40);
    path.cubicTo(76, 34, 62, 22, 86, 24);
    canvas.drawPath(path, line..strokeWidth = 2.5);

    for (final at in [const Offset(34, 58), const Offset(58, 36)]) {
      _leaf(canvas, fill, at, 0.4, 22 * growth, 10 * growth);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.form != form ||
      old.variant != variant ||
      old.growth != growth ||
      old.stem != stem;
}
