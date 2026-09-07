import 'package:flutter/widgets.dart';

import '../../core/features/feature_registry.dart';
import '../../features/chakras/presentation/chakras_screen.dart';
import '../../features/cycle/presentation/cycle_screen.dart';
import '../../features/environment/presentation/environment_screen.dart';
import '../../features/meditation/presentation/meditation_screen.dart';
import '../../features/placeholder/presentation/feature_screen.dart';
import '../../features/yoga/presentation/yoga_screen.dart';

/// The screen a feature opens.
///
/// Lives here rather than on [FeatureDefinition] because the catalogue is
/// plain data in `core/` and must not reach up into feature screens to
/// get it. This is the one place that knows which features have actually
/// been built.
///
/// Anything not named below gets the placeholder, which is the right
/// default: adding a feature to the registry gives it a proper screen
/// saying what it will be, and building it for real is one line here.
Widget screenForFeature(FeatureDefinition feature) => switch (feature.id) {
  FeatureId.environment => const EnvironmentScreen(),
  FeatureId.meditation => const MeditationScreen(),
  FeatureId.yoga => const YogaScreen(),
  FeatureId.chakras => const ChakrasScreen(),
  FeatureId.cycle => const CycleScreen(),
  FeatureId.cookbook ||
  FeatureId.garden ||
  FeatureId.natureLog => FeatureScreen(feature: feature),
};
