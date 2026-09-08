import 'package:flutter/foundation.dart';

import 'cycle_phase.dart';

export 'cycle_phase.dart';

/// What Cycle Syncing offers for one phase.
///
/// **Guidance, and guidance only.** Every section here exists whatever
/// the user's Almanac contains: the food ideas are present with the
/// Cookbook switched off, the movement ideas with Yoga switched off, the
/// reflective line with Meditation switched off. Feature choices control
/// the **doorways** underneath, never the words. That is the app's
/// firmest product rule and there are tests on both sides of it.
///
/// **What it never does.** It does not claim a deficiency, prescribe a
/// diet, require a supplement, promise an energy level, promise a mood,
/// or say what anybody's body can do on a given day. Iron-containing
/// foods are offered during menstruation because menstruation involves
/// blood loss and that is worth knowing — not because the user is being
/// told they are short of iron. `cycle_content_test.dart` fails on
/// detoxes, seed cycling, hormone-balancing foods, guaranteed feelings
/// and every fertility or pregnancy claim.
@immutable
class PhaseGuide {
  const PhaseGuide({
    required this.phase,
    required this.focus,
    required this.about,
    required this.food,
    required this.movement,
    required this.reflection,
    required this.duration,
  });

  final CyclePhase phase;

  /// Two or three words: "Rest & reflection".
  final String focus;

  /// A short description of where in the cycle this is.
  final String about;

  /// Practical food ideas. Real suggestions, not a regime.
  final List<String> food;

  /// Ways to move, offered rather than prescribed.
  final List<String> movement;

  /// One reflective or mindful suggestion.
  final String reflection;

  /// Where this sits in the cycle, described rather than promised.
  final String duration;

  @override
  String toString() => 'PhaseGuide(${phase.name})';
}

/// The four phases, and what Cycle Syncing offers for each.
abstract final class PhaseGuides {
  /// The guide for a phase. Total: every [CyclePhase] has one.
  static PhaseGuide forPhase(CyclePhase phase) =>
      all.firstWhere((guide) => guide.phase == phase);

  static const all = <PhaseGuide>[
    PhaseGuide(
      phase: CyclePhase.menstrual,
      focus: 'Rest & reflection',
      about:
          'The period has begun. Energy and comfort can vary considerably '
          'from person to person and from day to day, so this is offered '
          'as ideas rather than a plan.',
      food: [
        'Iron-containing foods are worth knowing about while bleeding: '
            'leafy greens such as spinach and silverbeet, lentils, beans, '
            'tofu, eggs, and red meat if you eat it.',
        'Pumpkin seeds and sesame seeds also carry iron, and scatter '
            'easily over whatever you are already making.',
        'Pairing plant iron with something vitamin-C rich in the same '
            'meal — lemon, tomatoes, capsicum, citrus — helps the body '
            'take more of it up.',
        'Warm meals if they appeal: soups, stews and anything that can '
            'be eaten from a bowl.',
      ],
      movement: [
        'Rest, if rest is what appeals. Nothing here needs doing.',
        'A walk, at whatever pace suits the day.',
        'Gentle stretching, or slow restorative yoga.',
        'More active movement is fine too, if it feels good — nothing is '
            'off limits.',
      ],
      reflection:
          'A quiet few minutes, if you can find them. This part of the '
          'cycle is often used as a point to slow down and notice where '
          'things are.',
      duration:
          'Bleeding commonly lasts somewhere between three and seven '
          'days, and varies widely. The app counts from the day you '
          'marked as the first.',
    ),
    PhaseGuide(
      phase: CyclePhase.follicular,
      focus: 'Begin & explore',
      about:
          'The stretch after menstruation and before the approximate '
          'ovulatory phase. Often a time people describe as opening out '
          'again, though that is a description and not a promise.',
      food: [
        'Balanced meals, nothing special required: protein, whole grains, '
            'vegetables and fruit.',
        'Legumes, eggs, fish, tofu or meat — whatever you usually build a '
            'meal around.',
        'Fresh seasonal food where you can get it, which is what the '
            'Cookbook is for.',
      ],
      movement: [
        'Gradually more active movement, if the energy is there.',
        'A flowing yoga practice.',
        'Walking, strength work, or simply more of whatever you enjoy.',
        'And less, on a day when less is right.',
      ],
      reflection:
          'A short practice for focus, or a few minutes to think about '
          'what you would like to begin.',
      duration:
          'In the app\'s model this runs from the end of the menstrual '
          'days to just before the estimated ovulatory phase, so its '
          'length follows the cycle length you chose.',
    ),
    PhaseGuide(
      phase: CyclePhase.ovulatory,
      focus: 'Connect & express',
      about:
          'A short estimated phase around the middle of the cycle, later '
          'in a longer one. Its position is arithmetic from the cycle '
          'length, not an observation.',
      food: [
        'Balanced meals again: protein, whole foods, plenty of colour on '
            'the plate.',
        'Fresh produce and salads if the weather suits them.',
        'Water through the day, which is dull advice and still worth it.',
      ],
      movement: [
        'More energetic movement can feel good here: brisk walking, '
            'strength work, an active yoga practice.',
        'Something with other people, if that appeals.',
        'None of it compulsory — this is an invitation.',
      ],
      reflection:
          'A practice for presence, or a few minutes of paying attention '
          'to what is around you rather than ahead of you.',
      duration:
          'The app estimates a three-day window rather than a single '
          'day, because a single day would be a claim it cannot make.',
    ),
    PhaseGuide(
      phase: CyclePhase.luteal,
      focus: 'Ground & complete',
      about:
          'The stretch after the approximate ovulatory window and before '
          'the next period. Often described as steadier and then quieter, '
          'though people differ a great deal.',
      food: [
        'Satisfying, balanced meals: protein, complex carbohydrates such '
            'as oats, brown rice or kumara, and vegetables.',
        'Legumes, nuts and seeds, and leafy greens — all of which happen '
            'to carry magnesium, if that is something you like to think '
            'about.',
        'Something warm and filling in the later days, if that is what '
            'appeals.',
      ],
      movement: [
        'Steady movement earlier on: strength work, walking, a regular '
            'practice.',
        'Gentler movement later, if that feels better — and it may not.',
        'A grounding yoga practice, at whatever pace suits.',
      ],
      reflection:
          'A practice for grounding, or a few minutes to put something '
          'down rather than pick something up.',
      duration:
          'In the app\'s model this runs from the day after the '
          'estimated ovulatory window to the end of the estimated cycle.',
    ),
  ];
}
