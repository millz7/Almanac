import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../dev/theme_preview_screen.dart';
import '../features/food/presentation/food_screen.dart';
import '../features/nature/presentation/nature_screen.dart';
import '../features/onboarding/domain/onboarding_stage.dart';
import '../features/onboarding/presentation/hemisphere_screen.dart';
import '../features/onboarding/presentation/location_intro_screen.dart';
import '../features/rhythms/presentation/rhythms_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/wellbeing/presentation/wellbeing_screen.dart';
import 'app_shell.dart';

/// Where the app lands once setup is done.
const kTodayRoute = '/today';

/// Onboarding lives outside the navigation shell — it is part of startup,
/// not a place the user can navigate back to.
const kHemisphereRoute = '/onboarding/hemisphere';
const kLocationIntroRoute = '/onboarding/location';

/// Settings, pushed over the app rather than being a sixth tab.
const kSettingsRoute = '/settings';

/// Route for the developer theme preview. Only registered in debug builds.
const kThemePreviewRoute = '/dev/theme';

/// The app's router.
///
/// A provider rather than a global so its redirect can consult the
/// onboarding stage. The [GoRouter] itself is built once; a listenable
/// nudges it to re-run redirects whenever that stage changes, which is
/// what carries the user from the hemisphere question into the app
/// without any explicit navigation call.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(onboardingStageProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: kTodayRoute,
    refreshListenable: refresh,
    redirect: (context, state) {
      final stage = ref.read(onboardingStageProvider);
      final location = state.matchedLocation;

      return switch (stage) {
        // Until there is a hemisphere the app cannot show anyone's
        // season, so every route leads back to the question.
        OnboardingStage.hemisphere =>
          location == kHemisphereRoute ? null : kHemisphereRoute,
        OnboardingStage.location =>
          location == kLocationIntroRoute ? null : kLocationIntroRoute,
        // Setup done: onboarding routes are no longer reachable.
        OnboardingStage.complete =>
          location.startsWith('/onboarding') ? kTodayRoute : null,
      };
    },
    routes: [
      GoRoute(
        path: kHemisphereRoute,
        builder: (context, state) => const HemisphereScreen(),
      ),
      GoRoute(
        path: kLocationIntroRoute,
        builder: (context, state) => const LocationIntroScreen(),
      ),
      // Outside the navigation shell: settings is somewhere you go and
      // come back from, not a place in the app's main structure.
      GoRoute(
        path: kSettingsRoute,
        builder: (context, state) => const SettingsScreen(),
      ),
      // Declared outside the navigation shell so it covers the whole
      // screen, and omitted entirely from release builds.
      if (kDebugMode)
        GoRoute(
          path: kThemePreviewRoute,
          builder: (context, state) => const ThemePreviewScreen(),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: kTodayRoute,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wellbeing',
                builder: (context, state) => const WellbeingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rhythms',
                builder: (context, state) => const RhythmsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nature',
                builder: (context, state) => const NatureScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/food',
                builder: (context, state) => const FoodScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
