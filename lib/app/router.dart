import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/features/feature_registry.dart';
import '../core/settings/settings_providers.dart';
import '../dev/theme_preview_screen.dart';
import '../features/onboarding/domain/onboarding_stage.dart';
import '../features/onboarding/presentation/feature_selection_screen.dart';
import '../features/onboarding/presentation/hemisphere_screen.dart';
import '../features/onboarding/presentation/location_intro_screen.dart';
import '../features/onboarding/presentation/name_screen.dart';
import 'app_shell.dart';
import 'navigation/detail_routes.dart';
import 'navigation/feature_screens.dart';

/// Where the app lands once setup is done. Owned by the registry, so the
/// route and the navigation entry cannot disagree.
final kEnvironmentRoute = FeatureRegistry.environment.route;

/// Onboarding lives outside the navigation shell — it is part of startup,
/// not a place the user can navigate back to.
const kNameRoute = '/onboarding/name';
const kHemisphereRoute = '/onboarding/hemisphere';
const kLocationIntroRoute = '/onboarding/location';
const kFeatureChoiceRoute = '/onboarding/almanac';

/// Route for the developer theme preview. Only registered in debug builds.
const kThemePreviewRoute = '/dev/theme';

/// The Moon detail page.
///
/// **A page inside the Environment, not a feature.** It is declared as a
/// child of the Environment branch's route, which is what gives it the
/// behaviour it should have for free: Back returns to the Environment, the
/// user's own navigation bar stays put with the Environment still
/// selected, and there is no extra tab, no [FeatureId], no onboarding
/// question and no second navigator. Reaching it is a matter of having
/// explored the Environment page.
const kMoonRoute = '/environment/moon';

/// The app's router.
///
/// **Every feature has a route, always.** The user's choices decide what
/// appears in the navigation bar, not what the app is capable of showing.
/// That keeps two promises at once: switching a feature off gets you out
/// of it immediately, and switching it back on works there and then
/// rather than after a restart. It also means the router is built once —
/// rebuilding it whenever somebody changed their Almanac would tear down
/// the shell and slam the panel shut mid-tap.
///
/// A listenable nudges the router to re-run its redirect whenever the
/// user's settings change, which is what carries them through onboarding
/// and what bounces them out of a feature they have just removed.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  // Two things move the user between screens: getting further through
  // setup, and adding or removing a feature (which can strand them on a
  // route that is no longer part of their Almanac).
  ref.listen(onboardingStageProvider, (_, _) => refresh.value++);
  ref.listen(
    // A comparable projection of the set: swapping one feature for
    // another must count as a change, which a length would miss.
    userSettingsProvider.select(
      (settings) =>
          settings.chosenFeatures.map((feature) => feature.id.name).join(','),
    ),
    (_, _) => refresh.value++,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: kEnvironmentRoute,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;

      return switch (ref.read(onboardingStageProvider)) {
        OnboardingStage.name => location == kNameRoute ? null : kNameRoute,
        // Until there is a hemisphere the app cannot show anyone's
        // season, so every route leads back to the question.
        OnboardingStage.hemisphere =>
          location == kHemisphereRoute ? null : kHemisphereRoute,
        OnboardingStage.location =>
          location == kLocationIntroRoute ? null : kLocationIntroRoute,
        OnboardingStage.features =>
          location == kFeatureChoiceRoute ? null : kFeatureChoiceRoute,
        OnboardingStage.complete => _afterSetup(ref, location),
      };
    },
    routes: [
      GoRoute(path: kNameRoute, builder: (_, _) => const NameScreen()),
      GoRoute(
        path: kHemisphereRoute,
        builder: (_, _) => const HemisphereScreen(),
      ),
      GoRoute(
        path: kLocationIntroRoute,
        builder: (_, _) => const LocationIntroScreen(),
      ),
      GoRoute(
        path: kFeatureChoiceRoute,
        builder: (_, _) => const FeatureSelectionScreen(),
      ),
      // Declared outside the navigation shell so it covers the whole
      // screen, and omitted entirely from release builds.
      if (kDebugMode)
        GoRoute(
          path: kThemePreviewRoute,
          builder: (_, _) => const ThemePreviewScreen(),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        // One branch per feature in the catalogue, in registry order, so
        // a branch index is a stable fact about a feature rather than a
        // consequence of what the user happens to have chosen.
        branches: [
          for (final feature in FeatureRegistry.all)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: feature.route,
                  builder: (_, _) => screenForFeature(feature),
                  routes: [
                    // Detail pages that belong *inside* a feature rather
                    // than beside it. The Moon is the first: it is part
                    // of the Environment, so it lives in the
                    // Environment's own branch and its stack.
                    ...detailRoutesFor(feature),
                  ],
                ),
              ],
            ),
        ],
      ),
    ],
  );
});

/// Where to go once setup is finished.
///
/// Two jobs. Onboarding is no longer reachable — someone pressing back
/// after finishing should not land in it. And a route belonging to a
/// feature the user has since removed sends them to the Environment: the
/// route still exists, but it is no longer part of their Almanac, so
/// standing on it would leave them somewhere their navigation bar cannot
/// get back to.
String? _afterSetup(Ref ref, String location) {
  if (location.startsWith('/onboarding')) return kEnvironmentRoute;

  final feature = FeatureRegistry.forRoute(location);
  if (feature != null && !ref.read(userSettingsProvider).includes(feature.id)) {
    return kEnvironmentRoute;
  }
  return null;
}
