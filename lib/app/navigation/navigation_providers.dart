import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/features/feature_registry.dart';
import '../../core/settings/settings_providers.dart';

/// What appears in the bottom navigation, in order.
///
/// This is the whole personalisation model in one place: the Environment,
/// then whichever features the user has chosen, in registry order. There
/// is no hub, no "more" and no overflow — if it is in this list it has its
/// own destination, and if it is not, it is not in the bar.
///
/// Note what this does *not* decide: which routes exist. Every feature's
/// route is registered permanently, so a feature switched back on is
/// reachable immediately rather than after a restart. The router knows
/// what exists; this decides what is visible.
final visibleDestinationsProvider = Provider<List<FeatureDefinition>>(
  (ref) => [
    FeatureRegistry.environment,
    ...ref.watch(userSettingsProvider).chosenFeatures,
  ],
);

/// The shell branch a feature's screen lives in.
///
/// Branches are declared in [FeatureRegistry.all] order and never change,
/// which is what lets each feature keep its own navigation stack and
/// scroll position across a change to the Almanac.
int branchIndexOf(FeatureDefinition feature) =>
    FeatureRegistry.all.indexWhere((other) => other.id == feature.id);
