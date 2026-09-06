import 'yoga_practice.dart';

export 'yoga_practice.dart';

/// A slow breath to move with: in for four, out for six.
///
/// Meditation's own [BreathingPattern], used for the steps where the
/// breath leads the movement. Nothing here counts holds or names
/// nostrils — a yoga practice wants a rhythm to follow, not a technique
/// to learn.
const _slowBreath = BreathingPattern(
  steps: [
    BreathingStep(
      phase: BreathingPhase.inhale,
      duration: Duration(seconds: 4),
      instruction: 'Breathe in',
      saysSeconds: false,
    ),
    BreathingStep(
      phase: BreathingPhase.exhale,
      duration: Duration(seconds: 6),
      instruction: 'Breathe out',
      saysSeconds: false,
    ),
  ],
);

/// The rhythm of a cat-cow flow: lengthen on the way in, round on the way
/// out, four seconds each.
const _flowingBreath = BreathingPattern(
  steps: [
    BreathingStep(
      phase: BreathingPhase.inhale,
      duration: Duration(seconds: 4),
      instruction: 'Breathe in and lengthen',
      saysSeconds: false,
    ),
    BreathingStep(
      phase: BreathingPhase.exhale,
      duration: Duration(seconds: 4),
      instruction: 'Breathe out and round',
      saysSeconds: false,
    ),
  ],
);

/// The three practices.
///
/// Short on purpose — five to six minutes — and built from movements
/// somebody who has never done yoga can follow from a sentence. No
/// inversions, nothing balanced on one leg, nothing that needs
/// flexibility to attempt. Names and descriptions say what the practice
/// is like, never what it will do for anybody.
abstract final class YogaPractices {
  /// Five minutes, eight movements: sitting, opening the sides, flowing
  /// on all fours, then up onto the feet.
  static const morning = YogaPractice(
    id: YogaPracticeId.morning,
    name: 'Morning',
    description: 'Waking the body gently, from the floor to your feet.',
    sequence: [
      YogaStep(
        pose: 'Seated breathing',
        duration: Duration(seconds: 45),
        instruction:
            'Sit however is comfortable. Rest your hands on your knees and '
            'let the breath slow down.',
        shape: PoseShape.seated,
        breathing: _slowBreath,
      ),
      YogaStep(
        pose: 'Seated side stretch',
        side: BodySide.left,
        duration: Duration(seconds: 30),
        instruction:
            'Sit tall. Reach your left arm overhead and lean gently to the '
            'right, keeping both hips down.',
        shape: PoseShape.sideBend,
        breathNote: 'Slow and even.',
      ),
      YogaStep(
        pose: 'Seated side stretch',
        side: BodySide.right,
        duration: Duration(seconds: 30),
        instruction:
            'Come back to the middle, then reach your right arm overhead '
            'and lean gently to the left.',
        shape: PoseShape.sideBend,
        breathNote: 'Slow and even.',
      ),
      YogaStep(
        pose: 'Cat cow',
        duration: Duration(seconds: 60),
        instruction:
            'On your hands and knees, hands under your shoulders. Let your '
            'back round and lengthen with the breath.',
        shape: PoseShape.allFours,
        breathing: _flowingBreath,
      ),
      YogaStep(
        pose: 'Mountain',
        duration: Duration(seconds: 30),
        instruction:
            'Stand tall with your feet together and your arms by your '
            'sides. Weight even through both feet.',
        shape: PoseShape.standing,
        breathNote: 'Three slow breaths.',
      ),
      YogaStep(
        pose: 'Forward fold',
        duration: Duration(seconds: 45),
        instruction:
            'Soften your knees and fold forward from the hips. Let your '
            'head and arms hang.',
        shape: PoseShape.folded,
        breathNote: 'Let each out-breath soften you a little further.',
      ),
      YogaStep(
        pose: 'Low lunge',
        side: BodySide.left,
        duration: Duration(seconds: 30),
        instruction:
            'Step your left foot forward and lower your right knee to the '
            'floor. Sink gently and lift your chest.',
        shape: PoseShape.lunge,
        breathNote: 'Steady and slow.',
      ),
      YogaStep(
        pose: 'Low lunge',
        side: BodySide.right,
        duration: Duration(seconds: 30),
        instruction:
            'Change over: right foot forward, left knee down. Sink gently '
            'and lift your chest.',
        shape: PoseShape.lunge,
        breathNote: 'Steady and slow.',
      ),
    ],
  );

  /// Six minutes, eight movements, all of them slow and close to the
  /// floor.
  static const ground = YogaPractice(
    id: YogaPracticeId.ground,
    name: 'Ground',
    description: 'Slower and closer to the floor. Weight and stillness.',
    sequence: [
      YogaStep(
        pose: 'Seated breathing',
        duration: Duration(seconds: 60),
        instruction:
            'Sit down and feel the floor underneath you. Let the breath '
            'lengthen without forcing it.',
        shape: PoseShape.seated,
        breathing: _slowBreath,
      ),
      YogaStep(
        pose: "Child's pose",
        duration: Duration(seconds: 60),
        instruction:
            'Knees wide, hips back towards your heels, forehead down and '
            'arms stretched forward.',
        shape: PoseShape.curled,
        breathNote: 'Breathe into your back.',
      ),
      YogaStep(
        pose: 'Cat cow',
        duration: Duration(seconds: 45),
        instruction:
            'Come onto your hands and knees. Round and lengthen slowly, '
            'letting the breath set the pace.',
        shape: PoseShape.allFours,
        breathing: _flowingBreath,
      ),
      YogaStep(
        pose: 'Mountain',
        duration: Duration(seconds: 45),
        instruction:
            'Stand still, feet a little apart. Notice how much of you is '
            'resting on the ground.',
        shape: PoseShape.standing,
        breathNote: 'Four slow breaths.',
      ),
      YogaStep(
        pose: 'Forward fold',
        duration: Duration(seconds: 45),
        instruction:
            'Knees soft, fold slowly from the hips and let your arms and '
            'head go heavy.',
        shape: PoseShape.folded,
        breathNote: 'Unhurried.',
      ),
      YogaStep(
        pose: 'Seated twist',
        side: BodySide.left,
        duration: Duration(seconds: 35),
        instruction:
            'Sit down. Turn gently to the left, left hand resting on the '
            'floor behind you.',
        shape: PoseShape.twist,
        breathNote: 'Lengthen in, turn a little further out.',
      ),
      YogaStep(
        pose: 'Seated twist',
        side: BodySide.right,
        duration: Duration(seconds: 35),
        instruction:
            'Unwind to the middle, then turn gently to the right in the '
            'same way.',
        shape: PoseShape.twist,
        breathNote: 'Lengthen in, turn a little further out.',
      ),
      YogaStep(
        pose: 'Rest',
        duration: Duration(seconds: 35),
        instruction:
            'Lie on your back with your arms a little away from your body. '
            'Nothing to do.',
        shape: PoseShape.lying,
        breathNote: 'Let the breath do as it likes.',
      ),
    ],
  );

  /// Five minutes, eight movements, ending lying down.
  static const unwind = YogaPractice(
    id: YogaPracticeId.unwind,
    name: 'Unwind',
    description: 'Soft stretches for the end of the day.',
    sequence: [
      YogaStep(
        pose: 'Seated breathing',
        duration: Duration(seconds: 45),
        instruction:
            'Sit comfortably and let your shoulders drop. Longer out '
            'than in.',
        shape: PoseShape.seated,
        breathing: _slowBreath,
      ),
      YogaStep(
        pose: 'Seated side stretch',
        side: BodySide.left,
        duration: Duration(seconds: 30),
        instruction:
            'Reach your left arm overhead and lean gently to the right. No '
            'need to go far.',
        shape: PoseShape.sideBend,
        breathNote: 'Easy and slow.',
      ),
      YogaStep(
        pose: 'Seated side stretch',
        side: BodySide.right,
        duration: Duration(seconds: 30),
        instruction:
            'Back to the middle, then reach your right arm overhead and '
            'lean gently to the left.',
        shape: PoseShape.sideBend,
        breathNote: 'Easy and slow.',
      ),
      YogaStep(
        pose: 'Seated forward fold',
        duration: Duration(seconds: 45),
        instruction:
            'Legs out in front, knees as bent as they like. Fold forward '
            'from the hips and let your head hang.',
        shape: PoseShape.folded,
        breathNote: 'Soften on every out-breath.',
      ),
      YogaStep(
        pose: "Child's pose",
        duration: Duration(seconds: 60),
        instruction:
            'Knees wide, hips back to your heels, forehead resting down.',
        shape: PoseShape.curled,
        breathNote: 'Slow and quiet.',
      ),
      YogaStep(
        pose: 'Seated twist',
        side: BodySide.left,
        duration: Duration(seconds: 30),
        instruction: 'Sit up and turn gently to the left. Keep it small.',
        shape: PoseShape.twist,
        breathNote: 'Gentle.',
      ),
      YogaStep(
        pose: 'Seated twist',
        side: BodySide.right,
        duration: Duration(seconds: 30),
        instruction: 'Unwind, then turn gently to the right.',
        shape: PoseShape.twist,
        breathNote: 'Gentle.',
      ),
      YogaStep(
        pose: 'Rest',
        duration: Duration(seconds: 30),
        instruction:
            'Lie down, arms loose, eyes closed if you like. Stay as long '
            'as you want after this.',
        shape: PoseShape.lying,
        breathNote: 'Nothing to follow.',
      ),
    ],
  );

  /// In the order they are offered.
  static const all = <YogaPractice>[morning, ground, unwind];

  static YogaPractice byId(YogaPracticeId id) =>
      all.firstWhere((practice) => practice.id == id);
}
