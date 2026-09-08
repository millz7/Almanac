import 'package:flutter/foundation.dart';

import '../../../core/context/almanac_context.dart';
import '../../../core/environment/moon_phase.dart';

export '../../../core/environment/moon_phase.dart';

/// A quiet thing somebody might do with a moon.
///
/// Words, not instructions. Each carries an optional [destination] — the
/// feature that could actually take them somewhere — and that is where
/// the app's one product rule bites: the **word** is shown whatever the
/// user's Almanac contains, and only the **doorway** depends on the
/// destination being part of it. Somebody with Meditation switched off
/// still reads "Meditate" here.
enum MoonPractice {
  pause('Pause'),
  listen('Listen'),
  setIntentions('Set intentions'),
  imagine('Imagine'),
  breathe('Breathe', destination: FeatureId.meditation),
  meditate('Meditate', destination: FeatureId.meditation),
  visualise('Visualise'),
  reflect('Reflect'),
  notice('Notice'),
  appreciate('Appreciate'),
  tend('Tend what is beginning'),
  choose('Choose one thing'),
  refine('Refine'),
  release('Let something go'),
  simplify('Simplify'),
  rest('Rest'),
  makeSpace('Make space');

  const MoonPractice(this.label, {this.destination});

  final String label;

  /// The feature this practice could open, where there is one. Null for
  /// the ones that need nothing but the person and the evening.
  final FeatureId? destination;
}

/// What might be worth doing with one phase of the moon.
///
/// **Reflective, and framed as such.** Nothing here is a claim about
/// what the moon does to a body. The moon is a long way off and lights
/// the sky; this page is about the fact that a repeating, visible rhythm
/// is a convenient thing to hang a habit of noticing on. The copy says
/// "can be used as", "may be", "you might", and where an idea belongs to
/// a tradition it says so. `moon_content_test.dart` fails on any causal
/// biological, hormonal, menstrual, fertility, emotional or personality
/// claim.
///
/// **Astronomy and cycle records are separate things.** The moon's phase
/// is astronomy, the same for everybody on Earth tonight. A menstrual
/// cycle is something the user recorded. They may happen to align, and
/// this app does not say that one moves the other.
@immutable
class MoonReflection {
  const MoonReflection({
    required this.phase,
    required this.theme,
    required this.explanation,
    required this.words,
    required this.practices,
  });

  final MoonPhase phase;

  /// Two or three words: "Begin inward".
  final String theme;

  /// A sentence or two, offered rather than asserted.
  final String explanation;

  /// The shape of the phase in single words, shown as one row:
  /// "Intention · Rest · Imagine · Listen".
  final List<String> words;

  /// Things somebody might do. Always shown in full, whatever the user's
  /// Almanac contains.
  final List<MoonPractice> practices;

  /// "Intention · Rest · Imagine · Listen".
  String get wordLine => words.join(' · ');

  /// The features these practices could open, each named once, in the
  /// order they first appear. What the page's doorways are built from —
  /// so adding a practice with a new destination adds a doorway, and no
  /// page has to be edited to keep up.
  List<FeatureId> get destinations {
    final found = <FeatureId>[];
    for (final practice in practices) {
      final destination = practice.destination;
      if (destination != null && !found.contains(destination)) {
        found.add(destination);
      }
    }
    return found;
  }

  @override
  String toString() => 'MoonReflection(${phase.label})';
}

/// The eight phases, and what each might be used for.
abstract final class MoonReflections {
  /// The reflection for a phase. Total: every [MoonPhase] has one, and a
  /// missing entry would be a programming error rather than a runtime
  /// condition.
  static MoonReflection forPhase(MoonPhase phase) =>
      all.firstWhere((reflection) => reflection.phase == phase);

  static const all = <MoonReflection>[
    MoonReflection(
      phase: MoonPhase.newMoon,
      theme: 'Begin inward',
      explanation:
          'The sky is dark, and nothing of the moon is on show. A new '
          'moon can be used as a quiet point to stop and ask what you '
          'would like to begin — the start of a lunar month is as good a '
          'marker as any, and it comes round without a calendar.',
      words: ['Intention', 'Rest', 'Imagine', 'Listen'],
      practices: [
        MoonPractice.setIntentions,
        MoonPractice.imagine,
        MoonPractice.breathe,
        MoonPractice.rest,
        MoonPractice.visualise,
      ],
    ),
    MoonReflection(
      phase: MoonPhase.waxingCrescent,
      theme: 'Nurture what is beginning',
      explanation:
          'A thin line of light after dark. In some modern spiritual '
          'traditions this is treated as the tending part of the month: '
          'you might return to something you decided a few days ago and '
          'give it a little attention rather than a plan.',
      words: ['Tend', 'Return', 'Patience', 'Small steps'],
      practices: [
        MoonPractice.tend,
        MoonPractice.breathe,
        MoonPractice.listen,
        MoonPractice.visualise,
      ],
    ),
    MoonReflection(
      phase: MoonPhase.firstQuarter,
      theme: 'Choose and move',
      explanation:
          'Half lit, half dark, and high in the sky at sunset. Half way '
          'between new and full, you might pick one thing over another '
          '— not because the moon asks it, but because a halfway point '
          'is a useful moment to decide.',
      words: ['Decide', 'Act', 'Commit', 'Steady'],
      practices: [
        MoonPractice.choose,
        MoonPractice.breathe,
        MoonPractice.meditate,
        MoonPractice.notice,
      ],
    ),
    MoonReflection(
      phase: MoonPhase.waxingGibbous,
      theme: 'Refine and continue',
      explanation:
          'Nearly full, and bright enough to walk by. A useful stretch '
          'for adjusting rather than starting: you might look at what is '
          'already underway and change one small part of how you are '
          'going about it.',
      words: ['Adjust', 'Continue', 'Attend', 'Trust'],
      practices: [
        MoonPractice.refine,
        MoonPractice.breathe,
        MoonPractice.reflect,
        MoonPractice.notice,
      ],
    ),
    MoonReflection(
      phase: MoonPhase.fullMoon,
      theme: 'Notice and illuminate',
      explanation:
          'The whole disc is lit, and it rises as the sun sets. The one '
          'phase everybody recognises, which makes it the easiest to '
          'stop for: a full moon can be used as a monthly point to '
          'notice where things have actually got to, and to say so out '
          'loud or in writing.',
      words: ['See clearly', 'Gratitude', 'Fullness', 'Mark it'],
      practices: [
        MoonPractice.notice,
        MoonPractice.appreciate,
        MoonPractice.meditate,
        MoonPractice.reflect,
      ],
    ),
    MoonReflection(
      phase: MoonPhase.waningGibbous,
      theme: 'Reflect and appreciate',
      explanation:
          'Still bright, and now shrinking. The light is going without '
          'any hurry, which makes this a comfortable stretch for looking '
          'back: you might reread something you wrote a fortnight ago, '
          'or simply notice what the month turned out to be about.',
      words: ['Look back', 'Thank', 'Gather', 'Settle'],
      practices: [
        MoonPractice.reflect,
        MoonPractice.appreciate,
        MoonPractice.breathe,
        MoonPractice.listen,
      ],
    ),
    MoonReflection(
      phase: MoonPhase.lastQuarter,
      theme: 'Release and simplify',
      explanation:
          'Half lit again, on the way down, and rising after midnight. '
          'In some modern spiritual traditions the waning half of the '
          'month is given to letting things go — you might use it to '
          'finish something, or simply to put one thing down.',
      words: ['Release', 'Finish', 'Clear', 'Soften'],
      practices: [
        MoonPractice.release,
        MoonPractice.simplify,
        MoonPractice.breathe,
        MoonPractice.pause,
      ],
    ),
    MoonReflection(
      phase: MoonPhase.waningCrescent,
      theme: 'Rest and make space',
      explanation:
          'The last sliver before dark, low in the sky before dawn. '
          'Nothing much is being asked of anybody here. It may be a '
          'moment to rest, to leave a few days unplanned, and to let the '
          'next new moon arrive on its own.',
      words: ['Rest', 'Empty', 'Quiet', 'Wait'],
      practices: [
        MoonPractice.rest,
        MoonPractice.makeSpace,
        MoonPractice.breathe,
        MoonPractice.pause,
      ],
    ),
  ];
}
