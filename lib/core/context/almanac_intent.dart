import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../environment/moon_phase.dart';
import '../features/feature_id.dart';
import 'cycle_phase.dart';

export '../features/feature_id.dart';
export 'cycle_phase.dart';

/// Why the user is going somewhere.
///
/// A tap on "Try a meditation →" from the Moon is not the same journey as
/// opening Meditation from the navigation bar, and the destination should
/// be allowed to know the difference. Without this, the only way to say
/// so later is a second, ad-hoc route system with query parameters in it.
///
/// **The destination stays the normal feature.** An intent adds a small
/// contextual area to a screen that already exists; it never opens a
/// hidden duplicate of one. Meditation entered from the Moon is
/// Meditation, with all four practices still there.
///
/// **Deterministic.** An intent is a value: the same context always
/// produces an equal intent with the same [heading]. Nothing here reads a
/// clock, a store or a position — the caller passes in the fact it is
/// travelling with.
///
/// **The shape, and the connections still to come.** A new pathway is
/// one more subclass, and nothing else. Cycle → Cookbook, Yoga and
/// Meditation are built; Garden → Cookbook, Season → Garden/Cookbook/
/// Nature Log and time of day → Meditation/Yoga are each a class with
/// its own payload, its own [destination] and its own [heading]. None of
/// them needs a route, a parameter or a change to the navigation.
@immutable
sealed class AlmanacIntent {
  const AlmanacIntent();

  /// The feature the user is being taken to.
  FeatureId get destination;

  /// One short line the destination can show, naming the context the
  /// user arrived with: "For today's New Moon".
  String get heading;
}

/// Meditation, entered from the Moon.
///
/// Carries the phase and nothing else. What Meditation *does* with a
/// phase is Meditation's business, decided in its own domain — which is
/// what keeps the Moon page from knowing anything about breathing
/// patterns, and Meditation from knowing anything about the Moon page.
final class MoonMeditationIntent extends AlmanacIntent {
  const MoonMeditationIntent(this.phase);

  final MoonPhase phase;

  @override
  FeatureId get destination => FeatureId.meditation;

  @override
  String get heading => "For today's ${phase.label}";

  @override
  bool operator ==(Object other) =>
      other is MoonMeditationIntent && other.phase == phase;

  @override
  int get hashCode => phase.hashCode;

  @override
  String toString() => 'MoonMeditationIntent(${phase.label})';
}

/// Somewhere the user is going from their cycle, carrying the phase.
///
/// **One payload, three destinations.** The Cookbook, Yoga and
/// Meditation each answer differently for a phase, so each gets its own
/// class — but all three carry the same typed [CyclePhase] and none of
/// them carries a string. Cycle knows *that* it is asking for recipes
/// for a phase; the Cookbook knows *which* recipes, and Cycle never
/// learns.
sealed class CyclePhaseIntent extends AlmanacIntent {
  const CyclePhaseIntent(this.phase);

  final CyclePhase phase;

  @override
  String get heading => 'For your ${phase.phrase}';

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is CyclePhaseIntent &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(runtimeType, phase);

  @override
  String toString() => '$runtimeType(${phase.name})';
}

/// The Cookbook, entered from Cycle Syncing's food guidance.
final class CycleCookbookIntent extends CyclePhaseIntent {
  const CycleCookbookIntent(super.phase);

  @override
  FeatureId get destination => FeatureId.cookbook;
}

/// Yoga, entered from Cycle Syncing's movement guidance.
final class CycleYogaIntent extends CyclePhaseIntent {
  const CycleYogaIntent(super.phase);

  @override
  FeatureId get destination => FeatureId.yoga;
}

/// Meditation, entered from Cycle Syncing's reflective suggestion.
///
/// Independent of [MoonMeditationIntent]. Meditation may have a moon
/// context and a cycle context at once, and they are two separate
/// observations about the same day — never combined into one claim.
final class CycleMeditationIntent extends CyclePhaseIntent {
  const CycleMeditationIntent(super.phase);

  @override
  FeatureId get destination => FeatureId.meditation;
}

/// The intent the user is currently travelling with, if any.
///
/// **A hand-off, not stored state.** It is set the instant a doorway is
/// tapped and taken by the destination on arrival, which clears it. It is
/// never persisted, never written to disk, and never becomes a history:
/// nothing can be learned later about where somebody has been.
///
/// Because the destination consumes it, an intent cannot outlive the
/// journey that created it — opening Meditation from the navigation bar
/// afterwards finds nothing waiting.
final almanacIntentProvider =
    NotifierProvider<AlmanacIntentController, AlmanacIntent?>(
      AlmanacIntentController.new,
    );

class AlmanacIntentController extends Notifier<AlmanacIntent?> {
  @override
  AlmanacIntent? build() {
    // Kept alive deliberately. Providers dispose themselves when nothing
    // is listening, and nothing does listen to this one: a doorway
    // writes it and the destination reads it once, a frame later and
    // from a different part of the tree. Without this the intent would
    // be collected in between and every journey would arrive with
    // nothing.
    ref.keepAlive();
    return null;
  }

  /// Sets the intent the user is about to travel with. Called by a
  /// doorway, immediately before it navigates.
  void open(AlmanacIntent intent) => state = intent;

  /// Takes the intent, if one is waiting for [destination], and clears
  /// it. Returns null when there is nothing to take — which is the
  /// normal case, and what a direct entry sees.
  AlmanacIntent? take(FeatureId destination) {
    final waiting = state;
    if (waiting == null || waiting.destination != destination) return null;
    state = null;
    return waiting;
  }

  /// Drops an intent nobody arrived to collect. Safe to call when there
  /// is none.
  void clear() => state = null;
}
