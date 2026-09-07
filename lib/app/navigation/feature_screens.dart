import 'package:flutter/widgets.dart';

import '../../core/features/feature_registry.dart';
import '../../features/chakras/presentation/chakras_screen.dart';
import '../../features/cookbook/presentation/cookbook_screen.dart';
import '../../features/cycle/presentation/cycle_screen.dart';
import '../../features/environment/presentation/environment_screen.dart';
import '../../features/garden/presentation/garden_screen.dart';
import '../../features/nature_log/presentation/nature_log_screen.dart';
import '../../features/meditation/presentation/meditation_screen.dart';
import '../../features/yoga/presentation/yoga_screen.dart';

/// The screen a feature opens.
///
/// Lives here rather than on [FeatureDefinition] because the catalogue is
/// plain data in `core/` and must not reach up into feature screens to
/// get it. This is the one place that knows which features have actually
/// been built.
///
/// Every feature in the registry is now built, so this switch names them
/// all and has no default. That is deliberate: adding a `FeatureId`
/// should stop the compiler here and make somebody choose a screen,
/// rather than quietly falling through to a placeholder. The placeholder
/// screen itself is kept — see `features/placeholder/` — for the next
/// feature that needs to announce itself before it exists.
Widget screenForFeature(FeatureDefinition feature) => switch (feature.id) {
  FeatureId.environment => const EnvironmentScreen(),
  FeatureId.meditation => const MeditationScreen(),
  FeatureId.yoga => const YogaScreen(),
  FeatureId.chakras => const ChakrasScreen(),
  FeatureId.cycle => const CycleScreen(),
  FeatureId.cookbook => const CookbookScreen(),
  FeatureId.garden => const GardenScreen(),
  FeatureId.natureLog => const NatureLogScreen(),
};
