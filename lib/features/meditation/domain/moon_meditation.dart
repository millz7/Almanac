import 'package:flutter/foundation.dart';

import '../../../core/environment/moon_phase.dart';
import 'meditation_technique.dart';

export '../../../core/environment/moon_phase.dart' show MoonPhase;

/// What Meditation offers somebody who arrived with a moon.
///
/// **Meditation decides this, not the Moon page.** The intent that
/// travels between them carries a [MoonPhase] and nothing else, so the
/// Moon page knows nothing about breathing patterns and Meditation knows
/// nothing about lunar reflection copy. Each feature answers for its own
/// half.
///
/// **The smallest coherent implementation, deliberately.** No new
/// breathing engine, no ninth pattern, no second Meditation screen: each
/// phase points at **one of the four practices that already exist** and
/// adds one line saying why it suits this moon. The four practices —
/// Focus, Sleep, Balance and Release Tension — are untouched and all
/// still offered.
///
/// Nothing here claims the moon does anything to a body. A phase is a
/// visible marker; the line says what the practice is for.
@immutable
class MoonMeditation {
  const MoonMeditation({
    required this.phase,
    required this.technique,
    required this.invitation,
  });

  final MoonPhase phase;

  /// One of the four existing practices.
  final TechniqueId technique;

  /// One line. An invitation, not a prescription.
  final String invitation;

  @override
  bool operator ==(Object other) =>
      other is MoonMeditation &&
      other.phase == phase &&
      other.technique == technique;

  @override
  int get hashCode => Object.hash(phase, technique);

  @override
  String toString() => 'MoonMeditation(${phase.label} → ${technique.name})';
}

/// One suggestion per phase, mapped onto the practices that exist.
abstract final class MoonMeditations {
  /// The suggestion for a phase. Total: every [MoonPhase] has one.
  static MoonMeditation forPhase(MoonPhase phase) =>
      all.firstWhere((meditation) => meditation.phase == phase);

  /// The practice itself, for a phase.
  static MeditationTechnique techniqueFor(MoonPhase phase) =>
      MeditationTechniques.byId(forPhase(phase).technique);

  static const all = <MoonMeditation>[
    MoonMeditation(
      phase: MoonPhase.newMoon,
      technique: TechniqueId.focus,
      invitation:
          'A quiet practice for turning inward and noticing what you '
          'want to begin.',
    ),
    MoonMeditation(
      phase: MoonPhase.waxingCrescent,
      technique: TechniqueId.focus,
      invitation:
          'Steady attention, for returning to something small you have '
          'already started.',
    ),
    MoonMeditation(
      phase: MoonPhase.firstQuarter,
      technique: TechniqueId.focus,
      invitation: 'An even rhythm, for sitting with a decision.',
    ),
    MoonMeditation(
      phase: MoonPhase.waxingGibbous,
      technique: TechniqueId.balance,
      invitation:
          'A longer, level breath, for staying with something already '
          'underway.',
    ),
    MoonMeditation(
      phase: MoonPhase.fullMoon,
      technique: TechniqueId.balance,
      invitation:
          'A settled practice, for looking clearly at where things have '
          'got to.',
    ),
    MoonMeditation(
      phase: MoonPhase.waningGibbous,
      technique: TechniqueId.balance,
      invitation: 'An unhurried breath, for looking back over the month.',
    ),
    MoonMeditation(
      phase: MoonPhase.lastQuarter,
      technique: TechniqueId.releaseTension,
      invitation: 'A long breath out, for putting something down.',
    ),
    MoonMeditation(
      phase: MoonPhase.waningCrescent,
      technique: TechniqueId.sleep,
      invitation: 'A slow, settling practice, for resting rather than doing.',
    ),
  ];
}
