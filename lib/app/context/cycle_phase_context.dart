import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/context/almanac_context.dart';
import '../../features/cycle/application/cycle_providers.dart';

/// The cycle phase a feature should answer for, or null.
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
/// **The argument** is the phase the screen was *travelled to* with, from
/// one of Cycle Syncing's doorways, or null on a direct entry. Passing it
/// through here rather than preferring it at the call site is what makes
/// the gate below total: a screen cannot keep showing cycle content it
/// arrived with after Cycle has been switched off.
///
/// ## Dormancy: the gate that must come first
///
/// An optional Almanac feature that is turned off becomes dormant. Its
/// locally stored data is retained unless the user explicitly deletes
/// it, but other features do not read it while the feature is disabled.
///
/// So availability is checked *before* Cycle's own providers are touched,
/// and the early return below is the whole mechanism. Because Riverpod
/// builds only what is watched, not watching [displayedCyclePhaseProvider]
/// means `cycleMomentProvider`, `cycleDataProvider` and therefore
/// `CycleStore.read()` are never reached at all. This is deliberately not
/// "read it and throw the answer away": a store that is never opened
/// cannot leak, cannot appear in a log, and cannot be blamed for a phase
/// nobody asked for.
///
/// Switching Cycle back on makes the stored data available again, because
/// nothing was deleted — only left unread.
///
/// A consumer therefore needs no `if` about feature availability of its
/// own, gets null when Cycle is absent and null when it is present with
/// nothing to say, and shows nothing rather than showing an empty
/// section.
final almanacCyclePhaseProvider = Provider.family<CyclePhase?, CyclePhase?>((
  ref,
  arrivedWith,
) {
  // Dormant: do not open the store, do not derive a phase, say nothing.
  if (!ref.watch(featureAvailableProvider(FeatureId.cycle))) return null;

  // A phase the user walked in with is the phase they asked about; only
  // a direct entry needs today's.
  return arrivedWith ?? ref.watch(displayedCyclePhaseProvider);
});
