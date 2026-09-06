import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/chakras.dart';

/// The largest the symbol's box gets.
const kChakraSymbolSize = 220.0;

/// One chakra's symbol: a ring of points around a quiet centre.
///
/// The number of points is the traditional petal count — four at the
/// Root, sixteen at the Throat, two at the Third Eye — so each of the
/// seven has a distinct shape as well as a distinct hue, and nobody has
/// to be able to see colour to tell them apart.
///
/// Abstract on purpose. No lotus illustration, no Sanskrit letterform, no
/// crystals: a circle, a ring of points, and a soft halo drawn in the
/// season's own light.
///
/// It says nothing to a screen reader. Everything it carries — which
/// chakra, its colour, its associations — is written out in real text
/// beside it.
class ChakraSymbol extends StatelessWidget {
  const ChakraSymbol({
    super.key,
    required this.chakra,
    this.focus = 1,
    this.size = kChakraSymbolSize,
  });

  final Chakra chakra;

  /// How far the symbol has come into focus, 0–1. Drives the halo and the
  /// weight of the ring, nothing else.
  final double focus;

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
              painter: _SymbolPainter(
                points: chakra.points,
                focus: focus.clamp(0.0, 1.0),
                accent: palette.chakraAccent(chakra.hue),
                glow: palette.chakraGlow(chakra.hue),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  const _SymbolPainter({
    required this.points,
    required this.focus,
    required this.accent,
    required this.glow,
  });

  final int points;
  final double focus;
  final Color accent;
  final Color glow;

  /// Described in a 100 by 100 square and scaled, so the geometry reads
  /// as proportions rather than pixels.
  static const _grid = 100.0;
  static const _centre = Offset(50, 50);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / _grid;
    if (scale <= 0) return;

    canvas.save();
    canvas.scale(scale);

    _paintHalo(canvas);
    _paintRing(canvas);
    _paintPoints(canvas);

    canvas.restore();
  }

  /// A soft fade outwards, brighter as the chakra comes into focus. This
  /// is the whole of the "glow": no rays, no sparkle.
  void _paintHalo(Canvas canvas) {
    final radius = 30 + 16 * focus;
    final rect = Rect.fromCircle(center: _centre, radius: radius);
    canvas.drawCircle(
      _centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glow.withValues(alpha: glow.a * (0.5 + 0.5 * focus)),
            glow.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  void _paintRing(Canvas canvas) {
    canvas.drawCircle(
      _centre,
      28,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.45 + 0.35 * focus),
    );
    canvas.drawCircle(
      _centre,
      5 + 1.5 * focus,
      Paint()..color = accent.withValues(alpha: 0.6 + 0.4 * focus),
    );
  }

  /// The petal count, drawn as evenly spaced points on a wider ring.
  ///
  /// Their size follows how many there are, so the Root's four are
  /// generous and the Crown's full ring stays a ring rather than becoming
  /// a solid band.
  void _paintPoints(Canvas canvas) {
    const orbit = 38.0;
    final spacing = 2 * math.pi * orbit / points;
    final radius = math.min(4.0, spacing * 0.3);
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.55 + 0.45 * focus);

    for (var i = 0; i < points; i++) {
      // Starting at the top, so a two-point symbol reads as a pair of
      // eyes and an even one is symmetrical about the vertical.
      final angle = -math.pi / 2 + 2 * math.pi * i / points;
      canvas.drawCircle(
        _centre + Offset(math.cos(angle), math.sin(angle)) * orbit,
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SymbolPainter old) =>
      old.points != points ||
      old.focus != focus ||
      old.accent != accent ||
      old.glow != glow;
}
