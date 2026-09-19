import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/geo_location.dart';
import '../../../../core/environment/natural_environment.dart';
import '../../../../core/environment/solar_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../environment_text.dart';
import '../moon_text.dart';
import 'moon_disc.dart';

/// The four things the Almanac knows about today, in a row.
///
/// The Home reference's strip: a small drawn medallion, the word under
/// it, the value under that, and a hairline between each pair. Labels in
/// an almanac, not four Material tiles — which is why there is no card,
/// no shadow and no fill here, only rules.
///
/// **Nothing is invented.** Sunrise and sunset are the real calculated
/// instants, converted to the user's zone for display only, and the three
/// honest not-a-time cases are shown as themselves rather than dressed up
/// as times. The moon is the real phase. Tides say plainly that they are
/// not ready.
class EnvironmentFacts extends StatelessWidget {
  const EnvironmentFacts({super.key, required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final events = environment.solarEvents;
    final zone = environment.timeZone;
    final moon = environment.moon;

    String solar(DateTime? instant) => instant == null
        ? EnvironmentText.noValue
        : formatClockTime(context, zone.wallTimeAt(instant));

    final note = EnvironmentText.sunNote(environment);
    final dayLength = EnvironmentText.dayLengthNote(environment);

    final facts = <Widget>[
      // On a polar day there is no sunrise and no sunset, so the strip
      // does not offer two empty slots where times would go: it says
      // what the sun is doing instead. A dash where a time belongs still
      // invites somebody to read it as a time that failed to load.
      if (events.kind != SolarDayKind.risesAndSets)
        _Fact(
          label: EnvironmentText.sunLabel,
          value: EnvironmentText.polarSunValue(events.kind),
          mark: _SunMark(rising: events.kind == SolarDayKind.sunNeverSets),
        )
      // With no position there is no sunrise to show, so the strip does
      // not carry an empty one. The invitation under the page is the
      // whole answer, and it is only ever an offer.
      else if (events.hasTimes) ...[
        _Fact(
          label: EnvironmentText.sunriseLabel,
          value: solar(events.sunrise),
          mark: const _SunMark(rising: true),
        ),
        _Fact(
          label: EnvironmentText.sunsetLabel,
          value: solar(events.sunset),
          mark: const _SunMark(rising: false),
        ),
      ],

      // The one fact with somewhere to go: the Moon has a page.
      _Fact(
        label: EnvironmentText.moonLabel,
        value: moon.phase.label,
        detail: MoonText.illumination(moon.illuminatedPercent),
        spoken: MoonText.spokenFacts(moon),
        onTap: () => context.push(kMoonRoute),
        mark: _MoonMark(environment: environment),
      ),

      _Fact(
        label: EnvironmentText.tidesLabel,
        value: EnvironmentText.tidesValue,
        spoken: '${EnvironmentText.tidesLabel}. ${EnvironmentText.tidesNote}',
        mark: const _TideMark(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Four narrow columns on a phone squeezed "Waning Gibbous"
            // into two lines and left the dividers stretched to the
            // tallest of them. Below the threshold the strip wraps into
            // rows of two, which is wide enough for any value the app
            // can produce at any text size.
            final scaled = MediaQuery.textScalerOf(context).scale(16) / 16;
            final perColumn = constraints.maxWidth / facts.length;
            final wide = perColumn >= 116 * scaled;

            return wide
                ? _Row(facts: facts)
                : Column(
                    children: [
                      for (var i = 0; i < facts.length; i += 2) ...[
                        if (i > 0) const AlmanacRule(spacing: AppSpacing.xs),
                        _Row(
                          facts: facts.sublist(
                            i,
                            (i + 2).clamp(0, facts.length),
                          ),
                        ),
                      ],
                    ],
                  );
          },
        ),

        if (note != null) ...[
          const SizedBox(height: AppSpacing.md),
          AlmanacAnnotation(note, textAlign: TextAlign.center),
        ] else if (dayLength != null) ...[
          const SizedBox(height: AppSpacing.md),
          AlmanacAnnotation(dayLength, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

/// One row of facts, with a hairline between each pair.
class _Row extends StatelessWidget {
  const _Row({required this.facts});

  final List<Widget> facts;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, fact) in facts.indexed) ...[
          if (index > 0) const _Divider(),
          Expanded(child: fact),
        ],
      ],
    ),
  );
}

/// One medallion: mark, word, value.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.mark,
    this.detail,
    this.spoken,
    this.onTap,
  });

  final String label;
  final String value;
  final String? detail;
  final String? spoken;
  final Widget mark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The drawn ring the reference puts each mark inside.
          ExcludeSemantics(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.border.withValues(alpha: 0.7),
                ),
              ),
              child: Center(child: mark),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.valueLabel?.copyWith(color: palette.textSecondary),
          ),
          Text(value, textAlign: TextAlign.center, style: textTheme.valueText),
          if (detail case final line?)
            Text(
              line,
              textAlign: TextAlign.center,
              style: textTheme.annotation?.copyWith(
                color: palette.textSecondary,
              ),
            ),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: onTap != null,
      label: spoken ?? '$label $value',
      excludeSemantics: true,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// The hairline between two facts — the reference's one piece of
/// punctuation in the strip. Decorative.
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SizedBox(
        width: 1,
        child: ColoredBox(
          color: context.palette.border.withValues(alpha: 0.45),
        ),
      ),
    ),
  );
}

/// A sun on the horizon with a few rays. Rising and setting differ by
/// which way the rays lean, so the two medallions are not one glyph used
/// twice.
class _SunMark extends StatelessWidget {
  const _SunMark({required this.rising});

  final bool rising;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(22),
    painter: _SunMarkPainter(colour: context.palette.icon, rising: rising),
  );
}

class _SunMarkPainter extends CustomPainter {
  const _SunMarkPainter({required this.colour, required this.rising});

  final Color colour;
  final bool rising;

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.72;
    final centre = Offset(size.width / 2, horizon);
    final radius = size.width * 0.26;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, horizon));
    canvas.drawCircle(centre, radius, Paint()..color = colour);
    canvas.restore();

    final line = Paint()
      ..color = colour
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.06, horizon),
      Offset(size.width * 0.94, horizon),
      line,
    );

    // Three short rays: up and outward for a rising sun, tucked down for
    // a setting one.
    final reach = rising ? -size.height * 0.30 : -size.height * 0.16;
    for (final dx in [-0.22, 0.0, 0.22]) {
      final x = size.width * (0.5 + dx);
      canvas.drawLine(
        Offset(x, horizon - radius * 1.5),
        Offset(x + size.width * dx * 0.4, horizon - radius * 1.5 + reach),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_SunMarkPainter old) =>
      old.colour != colour || old.rising != rising;
}

/// The real moon, at medallion size.
class _MoonMark extends StatelessWidget {
  const _MoonMark({required this.environment});

  final NaturalEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return MoonDisc(
      moon: environment.moon,
      size: 22,
      // Illuminated is light and unilluminated is dark — the way a moon
      // actually looks. It used to be inked the other way round, which
      // put a solid black disc next to the words "Full Moon".
      litColor: AlmanacPaper.moonlight,
      unlitColor: palette.textPrimary.withValues(alpha: 0.88),
      outlineColor: palette.border,
      // Which way round the light falls depends on where you are
      // standing on the planet.
      mirrored: environment.hemisphere == Hemisphere.southern,
    );
  }
}

/// Two small waves.
class _TideMark extends StatelessWidget {
  const _TideMark();

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(22),
    painter: _TideMarkPainter(colour: context.palette.icon),
  );
}

class _TideMarkPainter extends CustomPainter {
  const _TideMarkPainter({required this.colour});

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (final y in [0.38, 0.62]) {
      final path = Path()..moveTo(size.width * 0.10, size.height * y);
      path.quadraticBezierTo(
        size.width * 0.30,
        size.height * (y - 0.16),
        size.width * 0.50,
        size.height * y,
      );
      path.quadraticBezierTo(
        size.width * 0.70,
        size.height * (y + 0.16),
        size.width * 0.90,
        size.height * y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TideMarkPainter old) => old.colour != colour;
}
