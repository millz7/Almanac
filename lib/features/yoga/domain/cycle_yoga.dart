import 'package:flutter/foundation.dart';

import '../../../core/context/cycle_phase.dart';
import 'yoga_practices.dart';

export '../../../core/context/cycle_phase.dart' show CyclePhase;

/// What Yoga offers somebody who arrived from their cycle.
///
/// **Yoga decides this, not Cycle.** The intent that travels between
/// them carries a [CyclePhase] and nothing else, so Cycle never names a
/// practice, a pose or a duration — and Yoga never learns anything about
/// bleeding. Each feature answers for its own half.
///
/// **The three practices that already exist.** No fourth practice, no
/// separate cycle library: each phase points at Morning, Ground or
/// Unwind, plus one line saying why it suits. All three remain fully
/// offered on the normal chooser.
///
/// Invitational, never prescriptive: nothing here says what a body can
/// do on a given day.
@immutable
class CycleYogaSuggestion {
  const CycleYogaSuggestion({
    required this.phase,
    required this.practice,
    required this.invitation,
  });

  final CyclePhase phase;

  /// One of the three existing practices.
  final YogaPracticeId practice;

  /// One line. An invitation.
  final String invitation;

  @override
  bool operator ==(Object other) =>
      other is CycleYogaSuggestion &&
      other.phase == phase &&
      other.practice == practice;

  @override
  int get hashCode => Object.hash(phase, practice);

  @override
  String toString() => 'CycleYogaSuggestion(${phase.name} → ${practice.name})';
}

/// One suggestion per phase, mapped onto the practices that exist.
abstract final class CycleYoga {
  /// The suggestion for a phase. Total: every [CyclePhase] has one.
  static CycleYogaSuggestion forPhase(CyclePhase phase) =>
      all.firstWhere((suggestion) => suggestion.phase == phase);

  /// The practice itself, for a phase.
  static YogaPractice practiceFor(CyclePhase phase) =>
      YogaPractices.byId(forPhase(phase).practice);

  static const all = <CycleYogaSuggestion>[
    CycleYogaSuggestion(
      phase: CyclePhase.menstrual,
      practice: YogaPracticeId.unwind,
      invitation:
          'A slower practice, for a day when gentler movement feels right.',
    ),
    CycleYogaSuggestion(
      phase: CyclePhase.follicular,
      practice: YogaPracticeId.morning,
      invitation: 'A brighter practice, for when the energy is there.',
    ),
    CycleYogaSuggestion(
      phase: CyclePhase.ovulatory,
      practice: YogaPracticeId.morning,
      invitation: 'The most active of the three, if that appeals today.',
    ),
    CycleYogaSuggestion(
      phase: CyclePhase.luteal,
      practice: YogaPracticeId.ground,
      invitation: 'Weight and stillness, closer to the floor.',
    ),
  ];
}
