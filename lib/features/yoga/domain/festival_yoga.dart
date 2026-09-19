import 'package:flutter/foundation.dart';

import '../../../core/context/festival_id.dart';
import 'yoga_practices.dart';

export '../../../core/context/festival_id.dart' show FestivalId;

/// What Yoga offers somebody who arrived from a festival on the Wheel of
/// the Year.
///
/// **Yoga decides this, not the Wheel.** The intent that travels between
/// them carries a [FestivalId] and nothing else, so the Wheel never
/// names a practice, a pose or a duration — and Yoga never learns
/// anything about solstices or cross-quarter dates. Each feature answers
/// for its own half.
///
/// **The three practices that already exist.** No fourth practice, no
/// separate festival library: each festival points at Morning, Ground or
/// Unwind, plus one line saying why it suits. All three remain fully
/// offered on the normal chooser.
///
/// Invitational, never prescriptive: nothing here says what a body can
/// do on a given day, and nothing claims a practice is a required part
/// of marking any festival.
@immutable
class FestivalYogaSuggestion {
  const FestivalYogaSuggestion({
    required this.festival,
    required this.practice,
    required this.invitation,
  });

  final FestivalId festival;
  final YogaPracticeId practice;
  final String invitation;

  @override
  bool operator ==(Object other) =>
      other is FestivalYogaSuggestion &&
      other.festival == festival &&
      other.practice == practice;

  @override
  int get hashCode => Object.hash(festival, practice);

  @override
  String toString() =>
      'FestivalYogaSuggestion(${festival.name} → ${practice.name})';
}

/// One suggestion per festival, mapped onto the practices that exist.
abstract final class FestivalYoga {
  /// The suggestion for a festival. Total: every [FestivalId] has one.
  static FestivalYogaSuggestion forFestival(FestivalId festival) =>
      all.firstWhere((suggestion) => suggestion.festival == festival);

  /// The practice itself, for a festival.
  static YogaPractice practiceFor(FestivalId festival) =>
      YogaPractices.byId(forFestival(festival).practice);

  static const all = <FestivalYogaSuggestion>[
    FestivalYogaSuggestion(
      festival: FestivalId.yule,
      practice: YogaPracticeId.unwind,
      invitation:
          'A slower practice, for the stillness of the longest '
          'night.',
    ),
    FestivalYogaSuggestion(
      festival: FestivalId.imbolc,
      practice: YogaPracticeId.morning,
      invitation:
          'A brighter practice, for the first stirrings of the '
          'year.',
    ),
    FestivalYogaSuggestion(
      festival: FestivalId.ostara,
      practice: YogaPracticeId.morning,
      invitation: 'A practice for beginnings, as the days grow longer.',
    ),
    FestivalYogaSuggestion(
      festival: FestivalId.beltane,
      practice: YogaPracticeId.morning,
      invitation: 'An energetic practice, for vitality and connection.',
    ),
    FestivalYogaSuggestion(
      festival: FestivalId.litha,
      practice: YogaPracticeId.morning,
      invitation:
          'The most active of the three, for the fullness of '
          'midsummer.',
    ),
    FestivalYogaSuggestion(
      festival: FestivalId.lughnasadh,
      practice: YogaPracticeId.ground,
      invitation: 'Weight and stillness, for a day of gathering in.',
    ),
    FestivalYogaSuggestion(
      festival: FestivalId.mabon,
      practice: YogaPracticeId.ground,
      invitation: 'A grounded practice, for a day of balance.',
    ),
    FestivalYogaSuggestion(
      festival: FestivalId.samhain,
      practice: YogaPracticeId.unwind,
      invitation:
          'A slower practice, for reflection as the year turns '
          'toward the dark.',
    ),
  ];
}
