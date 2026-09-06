import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/chakras.dart';

/// The width of the column the body line is drawn in. Fixed, so the line
/// runs unbroken from the head cap, through all seven stops, to the base.
const kBodyLineWidth = 64.0;

/// The seven, drawn down an abstract body line.
///
/// Not a list of settings: a single line with a soft dome at the top and
/// a resting point at the bottom, with seven points along it and the
/// words beside each one. Reading downwards goes from the crown to the
/// base, because that is the way round a body is.
///
/// **The animation is one-shot.** The points rise into place once, from
/// the base upwards, over about a second, and then the screen is still.
/// There is no permanent ticker anywhere in this feature — the same rule
/// the Environment screen has kept since it was built.
class ChakraJourney extends StatefulWidget {
  const ChakraJourney({super.key, required this.onChosen});

  final ValueChanged<Chakra> onChosen;

  @override
  State<ChakraJourney> createState() => _ChakraJourneyState();
}

class _ChakraJourneyState extends State<ChakraJourney>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrival;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _arrival = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Reduced motion arrives at the destination instead of travelling to
    // it: the same screen, already settled. Nothing about what can be
    // done, or how long anything takes, changes.
    if (MediaQuery.disableAnimationsOf(context)) {
      _arrival.value = 1;
    } else {
      _arrival.forward();
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  /// Each point rises a little after the one below it, so the line fills
  /// from the base upwards rather than all at once.
  Animation<double> _riseFor(Chakra chakra) {
    final start = (chakra.position - 1) / ChakraCatalogue.all.length * 0.55;
    return CurvedAnimation(
      parent: _arrival,
      curve: Interval(
        start,
        (start + 0.45).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BodyLineEnd(head: true),
        // Down the body: the crown at the top, the root at the base.
        for (final chakra in ChakraCatalogue.all.reversed)
          _ChakraStop(
            chakra: chakra,
            rise: _riseFor(chakra),
            onTap: () => widget.onChosen(chakra),
          ),
        const _BodyLineEnd(head: false),
      ],
    );
  }
}

/// One chakra on the line: its point, its name, and what it is
/// traditionally associated with.
class _ChakraStop extends StatelessWidget {
  const _ChakraStop({
    required this.chakra,
    required this.rise,
    required this.onTap,
  });

  final Chakra chakra;
  final Animation<double> rise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      // "Root chakra. Traditionally associated with grounding, stability
      // and belonging." The drawing says nothing; this is the whole of
      // what a chakra is, in words.
      label: chakra.semanticLabel,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimens.minTouchTarget + AppSpacing.md,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: kBodyLineWidth,
                    child: AnimatedBuilder(
                      animation: rise,
                      // Only the painter rebuilds as the point rises; the
                      // words beside it are built once.
                      builder: (context, _) => CustomPaint(
                        painter: _StopPainter(
                          rise: rise.value,
                          accent: palette.chakraAccent(chakra.hue),
                          glow: palette.chakraGlow(chakra.hue),
                          line: palette.border,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(chakra.name, style: textTheme.titleLarge),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            chakra.associationPhrase,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The line's own beginning and end: a soft dome above the crown, and a
/// resting mark below the root.
///
/// This is the whole of the "figure" — no shoulders, no outline, nothing
/// anatomical. Just enough for the seven points to be somewhere on a body
/// rather than floating in a column.
class _BodyLineEnd extends StatelessWidget {
  const _BodyLineEnd({required this.head});

  final bool head;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ExcludeSemantics(
      child: SizedBox(
        width: kBodyLineWidth,
        height: head ? 56 : 40,
        child: CustomPaint(
          painter: _EndPainter(head: head, line: palette.border),
        ),
      ),
    );
  }
}

/// The centre of the body line within its column.
const _lineX = kBodyLineWidth / 2;
const _lineWidth = 1.6;

class _StopPainter extends CustomPainter {
  const _StopPainter({
    required this.rise,
    required this.accent,
    required this.glow,
    required this.line,
  });

  /// How far this point has risen into place, 0–1.
  final double rise;
  final Color accent;
  final Color glow;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final middle = size.height / 2;

    canvas.drawLine(
      const Offset(_lineX, 0),
      Offset(_lineX, size.height),
      Paint()
        ..color = line
        ..strokeWidth = _lineWidth,
    );

    final centre = Offset(_lineX, middle);
    final halo = 12 + 8 * rise;
    canvas.drawCircle(
      centre,
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glow.withValues(alpha: glow.a * rise),
            glow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: halo)),
    );
    canvas.drawCircle(
      centre,
      4 + 3 * rise,
      Paint()..color = accent.withValues(alpha: 0.55 + 0.45 * rise),
    );
  }

  @override
  bool shouldRepaint(_StopPainter old) =>
      old.rise != rise ||
      old.accent != accent ||
      old.glow != glow ||
      old.line != line;
}

class _EndPainter extends CustomPainter {
  const _EndPainter({required this.head, required this.line});

  final bool head;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = _lineWidth;

    if (head) {
      // A dome opening downwards: the top of a head, suggested rather
      // than drawn.
      const radius = 15.0;
      const centre = Offset(_lineX, 26);
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        3.14159,
        3.14159,
        false,
        paint,
      );
      canvas.drawLine(
        const Offset(_lineX, 26),
        Offset(_lineX, size.height),
        paint,
      );
      return;
    }

    canvas.drawLine(
      const Offset(_lineX, 0),
      Offset(_lineX, size.height - 12),
      paint,
    );
    // Somewhere to rest: a short ground line under the base.
    canvas.drawLine(
      Offset(_lineX - 14, size.height - 12),
      Offset(_lineX + 14, size.height - 12),
      paint,
    );
  }

  @override
  bool shouldRepaint(_EndPainter old) => old.head != head || old.line != line;
}
