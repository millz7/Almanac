import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/yoga_practice.dart';

/// The largest the figure's box gets.
const kPoseFigureSize = 260.0;

/// The shape of the body, drawn.
///
/// Deliberately not an illustration. Each pose is a few strokes and a
/// head on a floor line — enough to see the form of the movement at a
/// glance, and quiet enough to sit beside Meditation's orb rather than
/// looking like a fitness app. Photographs and drawn artwork are for
/// later; this is here so the words are not the only thing on screen.
///
/// It says nothing to a screen reader: the pose and the instruction are
/// written out in real text beside it, which is the same information and
/// the primary cue for everyone.
class PoseFigure extends StatelessWidget {
  const PoseFigure({
    super.key,
    required this.shape,
    this.side,
    this.openness,
    this.size = kPoseFigureSize,
  });

  final PoseShape shape;

  /// Mirrors the figure, so a left-side pose leans left.
  final BodySide? side;

  /// How open the breath is, 0–1, for the shapes that move with it.
  ///
  /// Null holds the figure still — which is what a held pose wants, and
  /// what the device asks for when it has animations turned off.
  final double? openness;

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
              painter: _PosePainter(
                shape: shape,
                // A left-side pose reads better leaning left, which is
                // the way round somebody facing you would see it.
                mirrored: side == BodySide.left,
                openness: openness,
                line: palette.primary,
                floor: palette.border,
                glow: palette.water,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PosePainter extends CustomPainter {
  const _PosePainter({
    required this.shape,
    required this.mirrored,
    required this.openness,
    required this.line,
    required this.floor,
    required this.glow,
  });

  final PoseShape shape;
  final bool mirrored;
  final double? openness;
  final Color line;
  final Color floor;
  final Color glow;

  /// The figure is described in a 100 by 100 square and scaled, so the
  /// geometry below reads as proportions rather than as pixels.
  static const _grid = 100.0;

  /// Where the ground is.
  static const _floorY = 88.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _grid;
    if (scale <= 0) return;

    canvas.save();
    canvas.scale(scale);
    if (mirrored) {
      // Flip about the middle, so a mirrored figure stays in its box.
      canvas.translate(_grid, 0);
      canvas.scale(-1, 1);
    }

    _paintFloor(canvas, scale);
    _paintFigure(canvas, scale);

    canvas.restore();
  }

  /// A single soft line for the ground, so a standing pose has something
  /// to stand on and a lying one has something to rest on.
  void _paintFloor(Canvas canvas, double scale) {
    canvas.drawLine(
      const Offset(10, _floorY),
      const Offset(90, _floorY),
      Paint()
        ..color = floor
        ..strokeWidth = 1.2 / scale
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintFigure(Canvas canvas, double scale) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = line;

    final (head, radius, body) = switch (shape) {
      PoseShape.seated => _seated(),
      PoseShape.standing => _standing(),
      PoseShape.folded => _folded(),
      PoseShape.allFours => _allFours(),
      PoseShape.curled => _curled(),
      PoseShape.sideBend => _sideBend(),
      PoseShape.lunge => _lunge(),
      PoseShape.twist => _twist(),
      PoseShape.lying => _lying(),
    };

    // A breath of light behind the figure, the same idea as the orb's
    // bloom, so the two features feel like one world.
    canvas.drawCircle(
      const Offset(50, 52),
      36,
      Paint()
        ..shader =
            RadialGradient(
              colors: [glow.withValues(alpha: 0.2), glow.withValues(alpha: 0)],
              stops: const [0.4, 1],
            ).createShader(
              Rect.fromCircle(center: const Offset(50, 52), radius: 36),
            ),
    );

    canvas.drawPath(body, stroke);
    canvas.drawCircle(
      head,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 / scale
        ..color = line,
    );
  }

  /// Sitting cross-legged: a short spine over a low base.
  (Offset, double, Path) _seated() => (
    const Offset(50, 30),
    7,
    Path()
      ..moveTo(50, 38)
      ..lineTo(50, 66)
      ..moveTo(50, 66)
      ..lineTo(30, 82)
      ..moveTo(50, 66)
      ..lineTo(70, 82)
      ..moveTo(30, 82)
      ..lineTo(70, 82),
  );

  /// Standing tall, arms down.
  (Offset, double, Path) _standing() => (
    const Offset(50, 22),
    7,
    Path()
      ..moveTo(50, 30)
      ..lineTo(50, 58)
      ..moveTo(50, 34)
      ..lineTo(38, 56)
      ..moveTo(50, 34)
      ..lineTo(62, 56)
      ..moveTo(50, 58)
      ..lineTo(45, _floorY)
      ..moveTo(50, 58)
      ..lineTo(55, _floorY),
  );

  /// Folded forward from the hips, head and arms hanging.
  (Offset, double, Path) _folded() => (
    const Offset(40, 62),
    7,
    Path()
      ..moveTo(56, 40)
      ..quadraticBezierTo(52, 52, 44, 58)
      ..moveTo(50, 52)
      ..lineTo(42, 78)
      ..moveTo(56, 40)
      ..lineTo(54, _floorY)
      ..moveTo(56, 40)
      ..lineTo(62, _floorY),
  );

  /// On hands and knees, the spine rounding and lengthening with the
  /// breath: fully out arches it up, fully in lets it dip.
  (Offset, double, Path) _allFours() {
    // Held still — or asked to hold still — sits between the two.
    final breath = openness ?? 0.5;
    // Cat at the end of the out-breath, cow at the top of the in-breath.
    final spineY = 40.0 + 18.0 * breath;
    final headY = 50.0 + 6.0 * breath;

    return (
      Offset(24, headY),
      6,
      Path()
        ..moveTo(31, headY)
        ..quadraticBezierTo(50, spineY, 68, 50)
        ..moveTo(34, headY + 3)
        ..lineTo(34, _floorY)
        ..moveTo(68, 50)
        ..lineTo(70, _floorY),
    );
  }

  /// Curled forward, hips back over the heels.
  (Offset, double, Path) _curled() => (
    const Offset(32, 76),
    6,
    Path()
      ..moveTo(38, 74)
      ..quadraticBezierTo(56, 62, 70, 70)
      ..moveTo(38, 78)
      ..lineTo(18, _floorY)
      ..moveTo(70, 70)
      ..lineTo(74, _floorY),
  );

  /// Sitting tall and leaning to one side, one arm overhead.
  (Offset, double, Path) _sideBend() => (
    const Offset(60, 28),
    7,
    Path()
      ..moveTo(46, 66)
      ..quadraticBezierTo(50, 46, 58, 36)
      ..moveTo(56, 40)
      ..quadraticBezierTo(66, 30, 72, 34)
      ..moveTo(46, 66)
      ..lineTo(28, 82)
      ..moveTo(46, 66)
      ..lineTo(64, 82)
      ..moveTo(28, 82)
      ..lineTo(64, 82),
  );

  /// One foot forward, the back knee down, chest lifted.
  (Offset, double, Path) _lunge() => (
    const Offset(46, 26),
    7,
    Path()
      ..moveTo(46, 34)
      ..lineTo(48, 58)
      ..moveTo(47, 42)
      ..lineTo(58, 32)
      ..moveTo(48, 58)
      ..lineTo(68, 70)
      ..lineTo(68, _floorY)
      ..moveTo(48, 58)
      ..lineTo(30, 84)
      ..lineTo(18, _floorY),
  );

  /// Sitting and turned gently to one side.
  (Offset, double, Path) _twist() => (
    const Offset(56, 28),
    7,
    Path()
      ..moveTo(48, 66)
      ..quadraticBezierTo(54, 48, 54, 36)
      ..moveTo(52, 46)
      ..lineTo(34, 54)
      ..moveTo(52, 46)
      ..lineTo(70, 58)
      ..moveTo(48, 66)
      ..lineTo(30, 82)
      ..moveTo(48, 66)
      ..lineTo(66, 82),
  );

  /// Lying down, arms a little away from the body.
  (Offset, double, Path) _lying() => (
    const Offset(24, 78),
    7,
    Path()
      ..moveTo(31, 79)
      ..lineTo(72, 79)
      ..moveTo(72, 79)
      ..lineTo(84, 84)
      ..moveTo(44, 79)
      ..lineTo(40, _floorY)
      ..moveTo(58, 79)
      ..lineTo(62, _floorY),
  );

  @override
  bool shouldRepaint(_PosePainter old) =>
      old.shape != shape ||
      old.mirrored != mirrored ||
      old.openness != openness ||
      old.line != line ||
      old.floor != floor ||
      old.glow != glow;
}
