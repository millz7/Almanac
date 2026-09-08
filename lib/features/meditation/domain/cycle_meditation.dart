import 'package:flutter/foundation.dart';

import '../../../core/context/cycle_phase.dart';
import 'meditation_technique.dart';

export '../../../core/context/cycle_phase.dart' show CyclePhase;

/// What Meditation offers somebody who arrived from their cycle.
///
/// The same shape as `MoonMeditation`, and deliberately separate from
/// it. A moon and a cycle are two different observations about the same
/// day; Meditation may hold both at once and never combines them into
/// one claim.
///
/// **The four practices that already exist.** No fifth pattern and no
/// new engine: each phase points at Focus, Sleep, Balance or Release
/// Tension, plus one line.
@immutable
class CycleMeditation {
  const CycleMeditation({
    required this.phase,
    required this.technique,
    required this.invitation,
  });

  final CyclePhase phase;
  final TechniqueId technique;
  final String invitation;

  @override
  bool operator ==(Object other) =>
      other is CycleMeditation &&
      other.phase == phase &&
      other.technique == technique;

  @override
  int get hashCode => Object.hash(phase, technique);

  @override
  String toString() => 'CycleMeditation(${phase.name} → ${technique.name})';
}

/// One suggestion per phase.
abstract final class CycleMeditations {
  /// The suggestion for a phase. Total: every [CyclePhase] has one.
  static CycleMeditation forPhase(CyclePhase phase) =>
      all.firstWhere((meditation) => meditation.phase == phase);

  /// The practice itself, for a phase.
  static MeditationTechnique techniqueFor(CyclePhase phase) =>
      MeditationTechniques.byId(forPhase(phase).technique);

  static const all = <CycleMeditation>[
    CycleMeditation(
      phase: CyclePhase.menstrual,
      technique: TechniqueId.focus,
      invitation: 'An even rhythm, for a few quiet minutes turned inward.',
    ),
    CycleMeditation(
      phase: CyclePhase.follicular,
      technique: TechniqueId.focus,
      invitation: 'Steady attention, for the beginning of something.',
    ),
    CycleMeditation(
      phase: CyclePhase.ovulatory,
      technique: TechniqueId.balance,
      invitation: 'A level breath, for being where you are.',
    ),
    CycleMeditation(
      phase: CyclePhase.luteal,
      technique: TechniqueId.releaseTension,
      invitation: 'A long breath out, for putting something down.',
    ),
  ];
}
