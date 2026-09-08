import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/context/almanac_context.dart';
import '../../features/cycle/application/cycle_providers.dart';

/// The user's current cycle phase, for the features that answer to one.
///
/// **Why this is in the app layer.** The Cookbook, Yoga and Meditation
/// each want to know "is there a cycle phase to answer for?" — and none
/// of them may import Cycle. `lib/core/context/` cannot supply it
/// either, because knowing it means reading a feature's store, and core
/// knows about no features.
///
/// The app layer is the composition root: it already knows every feature
/// exists (`feature_screens.dart` builds all eight). So this is the one
/// place the wire is soldered, and it exposes the smallest possible
/// value — a phase, or null.
///
/// Null when Cycle is not part of the user's Almanac, and null when it
/// is but has nothing to say. A consumer therefore needs no `if` about
/// feature availability of its own, and shows nothing rather than
/// showing an empty section.
final almanacCyclePhaseProvider = Provider<CyclePhase?>((ref) {
  // Switching Cycle off takes its context with it, immediately.
  if (!ref.watch(featureAvailableProvider(FeatureId.cycle))) return null;
  return ref.watch(displayedCyclePhaseProvider);
});
