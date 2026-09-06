import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/meditation_technique.dart';

/// How long a line of guidance takes to arrive, how long it stays, and
/// how long it takes to go.
const _fadeIn = Duration(milliseconds: 350);
const _linger = Duration(milliseconds: 1450);
const _fadeOut = Duration(milliseconds: 800);

/// How visible the guidance should be, [elapsedInStep] into a step.
///
/// A pure function of the one clock, which is the point: the words arrive
/// with the breath, sit for a moment and leave, without a second timer to
/// keep in step with the first. Nothing hangs around the orb.
double guidanceOpacity(Duration elapsedInStep) {
  final elapsed = elapsedInStep.inMicroseconds;
  if (elapsed <= 0) return 0;

  final fadeIn = _fadeIn.inMicroseconds;
  if (elapsed < fadeIn) return elapsed / fadeIn;

  final settled = fadeIn + _linger.inMicroseconds;
  if (elapsed < settled) return 1;

  final gone = settled + _fadeOut.inMicroseconds;
  if (elapsed >= gone) return 0;
  return 1 - (elapsed - settled) / (gone - settled);
}

/// What to do, said once and then let go of.
///
/// The orb's size is the cue for most of every phase; this is here for
/// the parts a size cannot say — which nostril, what to do with your
/// mouth — and for the first moments of a breath, when it helps to be
/// told. It is never persistent, so the orb stays the experience.
///
/// When the device has asked for reduced motion the line simply stays:
/// text appearing and disappearing is itself motion, and with a still orb
/// the words are the only cue there is.
class BreathGuidance extends StatelessWidget {
  const BreathGuidance({
    super.key,
    required this.moment,
    required this.persistent,
  });

  final BreathingMoment moment;

  /// Show the line for the whole step instead of fading it.
  final bool persistent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      // Its own node with its own words, announced once when the step
      // begins — for Balance that is where "left", "right" and "both"
      // actually live, since the orb's lean is a hint and not a label.
      container: true,
      liveRegion: true,
      label: moment.spokenInstruction,
      excludeSemantics: true,
      child: Opacity(
        opacity: persistent ? 1 : guidanceOpacity(moment.elapsedInStep),
        child: Text(
          moment.instruction,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: palette.textSecondary),
        ),
      ),
    );
  }
}
