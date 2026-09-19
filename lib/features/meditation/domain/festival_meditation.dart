import 'package:flutter/foundation.dart';

import '../../../core/context/festival_id.dart';
import 'meditation_technique.dart';

export '../../../core/context/festival_id.dart' show FestivalId;

/// What Meditation offers somebody who arrived from a festival on the
/// Wheel of the Year.
///
/// The same shape as `MoonMeditation` and `CycleMeditation`, and
/// deliberately separate from both: the moon, a cycle and a festival are
/// three different observations about the same day, and Meditation may
/// hold all three at once without ever combining them into one claim.
///
/// **The four practices that already exist.** No fifth pattern and no
/// new engine: each festival points at Focus, Sleep, Balance or Release
/// Tension, plus one line — never a religious prescription, only an
/// invitation that fits the festival's own reflective theme.
@immutable
class FestivalMeditation {
  const FestivalMeditation({
    required this.festival,
    required this.technique,
    required this.invitation,
  });

  final FestivalId festival;
  final TechniqueId technique;
  final String invitation;

  @override
  bool operator ==(Object other) =>
      other is FestivalMeditation &&
      other.festival == festival &&
      other.technique == technique;

  @override
  int get hashCode => Object.hash(festival, technique);

  @override
  String toString() =>
      'FestivalMeditation(${festival.name} → ${technique.name})';
}

/// One suggestion per festival.
abstract final class FestivalMeditations {
  /// The suggestion for a festival. Total: every [FestivalId] has one.
  static FestivalMeditation forFestival(FestivalId festival) =>
      all.firstWhere((meditation) => meditation.festival == festival);

  /// The practice itself, for a festival.
  static MeditationTechnique techniqueFor(FestivalId festival) =>
      MeditationTechniques.byId(forFestival(festival).technique);

  static const all = <FestivalMeditation>[
    FestivalMeditation(
      festival: FestivalId.yule,
      technique: TechniqueId.sleep,
      invitation:
          'A slow, settling practice, for the longest night of the '
          'year.',
    ),
    FestivalMeditation(
      festival: FestivalId.imbolc,
      technique: TechniqueId.focus,
      invitation:
          'Steady attention, for the first small stirrings of '
          'something new.',
    ),
    FestivalMeditation(
      festival: FestivalId.ostara,
      technique: TechniqueId.focus,
      invitation: 'An even rhythm, for a day of balance and beginnings.',
    ),
    FestivalMeditation(
      festival: FestivalId.beltane,
      technique: TechniqueId.balance,
      invitation: 'A level breath, for vitality and connection.',
    ),
    FestivalMeditation(
      festival: FestivalId.litha,
      technique: TechniqueId.balance,
      invitation: 'A settled practice, for the fullness of the longest day.',
    ),
    FestivalMeditation(
      festival: FestivalId.lughnasadh,
      technique: TechniqueId.balance,
      invitation:
          'An unhurried breath, for taking stock of what is '
          'starting to show.',
    ),
    FestivalMeditation(
      festival: FestivalId.mabon,
      technique: TechniqueId.balance,
      invitation: 'A level breath, for a day of balance and gratitude.',
    ),
    FestivalMeditation(
      festival: FestivalId.samhain,
      technique: TechniqueId.releaseTension,
      invitation:
          'A long breath out, for remembrance and letting something '
          'go.',
    ),
  ];
}
