import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/context/almanac_context.dart';
import '../../features/wheel/application/wheel_providers.dart';
import '../../features/wheel/domain/festival.dart';

export '../../features/wheel/domain/festival.dart' show FestivalFoodTheme;
export '../../features/wheel/domain/festival_timing.dart'
    show FestivalTimingState;

/// A festival worth mentioning right now, and how close it is.
///
/// Carries [food] so the Cookbook can show a festival's suggestion ideas
/// without ever importing the Wheel of the Year feature — the same
/// reason the phase carried to the Cookbook by `almanacCyclePhaseProvider`
/// is a bare [CyclePhase] rather than a reference into Cycle's own
/// store. The Wheel authors the words; this is simply where they cross
/// the seam.
class ActiveFestival {
  const ActiveFestival(this.id, this.state, this.daysUntil, this.food);

  final FestivalId id;

  /// Never [FestivalTimingState.normal] — see [almanacFestivalProvider].
  final FestivalTimingState state;

  /// 0 on the festival's own day, otherwise how many days remain.
  final int daysUntil;

  /// The festival's own suggestion ideas for a meal, a treat and a
  /// drink — not full recipes, and not the Cookbook's own content.
  final FestivalFoodTheme food;

  @override
  bool operator ==(Object other) =>
      other is ActiveFestival &&
      other.id == id &&
      other.state == state &&
      other.daysUntil == daysUntil;

  @override
  int get hashCode => Object.hash(id, state, daysUntil);

  @override
  String toString() => 'ActiveFestival(${id.name}, $state, $daysUntil)';
}

/// The festival a feature should answer for, or null.
///
/// **Why this is in the app layer.** The Environment, Cookbook, Yoga and
/// Meditation each want to know "is there a festival to answer for?" —
/// and none of them may import the Wheel of the Year. `lib/core/context/`
/// cannot supply it either, because knowing it means reading an optional
/// feature's own availability, and answering "is this feature part of
/// the Almanac?" for a *specific* feature is exactly what belongs at the
/// composition root. The same shape as `almanacCyclePhaseProvider`.
///
/// **The argument** is the festival the screen was *travelled to* with,
/// from one of the Wheel's own doorways, or null on a direct entry —
/// exactly as with the cycle-phase bridge, and for the same reason: a
/// screen must not keep showing a festival it arrived with after the
/// Wheel has been switched off.
///
/// ## Dormancy: the gate that must come first
///
/// A Wheel of the Year switched off is dormant, not deleted: there is no
/// user data to delete, but other features stop reading its calculation
/// while it is off. Availability is checked before anything else here,
/// so a consumer that only watches this provider never has to add its
/// own `if` about whether Wheel is chosen.
///
/// **Never [FestivalTimingState.normal].** A festival more than a week
/// away is not "active" in the cross-feature sense — this returns null
/// for it, exactly as it does when the Wheel is switched off, so a
/// consumer has one null check that covers both "nothing to say" and
/// "the feature that would say it isn't here".
final almanacFestivalProvider = Provider.family<ActiveFestival?, FestivalId?>((
  ref,
  arrivedWith,
) {
  // Dormant: do not compute a wheel position, say nothing.
  if (!ref.watch(featureAvailableProvider(FeatureId.wheel))) return null;

  final today = ref.watch(todayProvider);
  final next = ref.watch(nextFestivalProvider);
  final state = ref.watch(festivalTimingStateProvider);

  if (arrivedWith != null) {
    // A festival the user walked in with is the one they asked about —
    // but it is only "active" if it genuinely still is; a stale link
    // followed a week late should not go on claiming it is approaching.
    if (next.id != arrivedWith || state == FestivalTimingState.normal) {
      return null;
    }
    return ActiveFestival(
      arrivedWith,
      state,
      next.date.daysSince(today),
      WheelOfYear.byId(arrivedWith).food,
    );
  }

  if (state == FestivalTimingState.normal) return null;
  return ActiveFestival(
    next.id,
    state,
    next.date.daysSince(today),
    WheelOfYear.byId(next.id).food,
  );
});
