import 'package:flutter/widgets.dart';

import '../../core/features/feature_registry.dart';
import '../../core/widgets/widgets.dart';
import '../../features/chakras/presentation/chakras_screen.dart';
import '../../features/cookbook/presentation/cookbook_screen.dart';
import '../../features/cycle/presentation/cycle_screen.dart';
import '../../features/environment/presentation/environment_screen.dart';
import '../../features/garden/presentation/garden_screen.dart';
import '../../features/nature_log/presentation/nature_log_screen.dart';
import '../../features/meditation/presentation/meditation_screen.dart';
import '../../features/yoga/presentation/yoga_screen.dart';

/// The screen a feature opens, on the paper it belongs on.
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
///
/// ## ENVIRONMENT IS OUTSIDE. DETAIL PAGES ARE THE BOOK.
///
/// This is also the one place the app's two visual worlds are separated,
/// and separating them here rather than inside each screen is the point.
/// Every feature except the Environment is a chapter of the book, so
/// every feature except the Environment is wrapped in
/// [AlmanacPaperSurface] — warm cream in all eight palettes, by day and
/// by night. A feature cannot forget to be paper, and a future feature
/// gets it by being added to the switch.
///
/// The Environment is the living painting and is handed through
/// untouched. There is a test for both halves.
Widget screenForFeature(FeatureDefinition feature) => switch (feature.id) {
  // Outside.
  FeatureId.environment => const EnvironmentScreen(),

  // The book.
  FeatureId.meditation => const AlmanacPaperSurface(child: MeditationScreen()),
  FeatureId.yoga => const AlmanacPaperSurface(child: YogaScreen()),
  FeatureId.chakras => const AlmanacPaperSurface(child: ChakrasScreen()),
  FeatureId.cycle => const AlmanacPaperSurface(child: CycleScreen()),
  FeatureId.cookbook => const AlmanacPaperSurface(child: CookbookScreen()),
  FeatureId.garden => const AlmanacPaperSurface(child: GardenScreen()),
  FeatureId.natureLog => const AlmanacPaperSurface(child: NatureLogScreen()),
};
