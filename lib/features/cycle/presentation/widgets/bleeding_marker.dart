import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/bleeding_marker.dart';
import '../cycle_text.dart';

export '../../domain/bleeding_marker.dart';

/// The colours a bleeding mark is drawn in.
///
/// A muted rust, taken once so the wheel, the legend and the calendar
/// cannot end up with three different reds. On paper the ink is fixed;
/// this is the one place it is written down.
abstract final class BleedingInk {
  /// Spotting: the same hue, lighter, so it reads as less.
  static const spotting = Color(0xFFC08A7A);

  /// Bleeding, and the fill of a heavy day.
  static const fill = Color(0xFFA94B3C);

  /// The heavy day's extra ring: the same hue, darker.
  static const outline = Color(0xFF6E2A20);

  static Color fillFor(BleedingLevel level) =>
      level == BleedingLevel.spotting ? spotting : fill;
}

/// Draws one bleeding mark, from the shared specification.
///
/// **One symbol language.** The geometry comes from
/// [BleedingMarkerSpec], so a legend swatch and a mark on a calendar
/// day and a mark on the month wheel are the same drawing at different
/// sizes — spotting visibly smaller than bleeding, and heavy identical
/// to bleeding plus exactly one thin outer ring.
///
/// Decorative: every mark is stated in words beside or behind it, so a
/// screen reader gains nothing from the dot.
class BleedingMarker extends StatelessWidget {
  const BleedingMarker({super.key, required this.level, required this.size});

  final BleedingLevel level;

  /// The mark's box. The spec's fractions are of half of this.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkerPainter(BleedingMarkers.of(level))),
    ),
  );
}

class _MarkerPainter extends CustomPainter {
  const _MarkerPainter(this.spec);

  final BleedingMarkerSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    paintBleedingMarker(
      canvas,
      spec: spec,
      centre: size.center(Offset.zero),
      half: size.shortestSide / 2,
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.spec != spec;
}

/// Paints a mark onto any canvas, so the wheel can draw the same mark
/// inside its own painting without a second description of it.
///
/// [half] is half the mark's box: the spec's fractions are of it.
void paintBleedingMarker(
  Canvas canvas, {
  required BleedingMarkerSpec spec,
  required Offset centre,
  required double half,
}) {
  if (half <= 0) return;

  canvas.drawCircle(
    centre,
    half * spec.innerRadiusFraction,
    Paint()..color = BleedingInk.fillFor(spec.level),
  );

  if (spec.outlineRadiusFraction case final outer?) {
    canvas.drawCircle(
      centre,
      half * outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = half * BleedingMarkerSpec.outlineStrokeFraction
        ..color = BleedingInk.outline,
    );
  }
}

/// The three marks, named. Real text beside each one, so nothing depends
/// on telling two dots apart by size.
class BleedingLegend extends StatelessWidget {
  const BleedingLegend({super.key});

  /// The box every legend swatch is drawn in. Big enough that spotting
  /// and bleeding are plainly different sizes.
  static const swatchSize = 22.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CycleText.legend,
          style: textTheme.journalLabel?.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            // The same specs the wheel and the calendar read, in the
            // same order as the levels themselves.
            for (final spec in BleedingMarkers.all)
              Semantics(
                container: true,
                label: spec.level.label,
                excludeSemantics: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BleedingMarker(level: spec.level, size: swatchSize),
                    const SizedBox(width: AppSpacing.xs),
                    Text(spec.level.label, style: textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
