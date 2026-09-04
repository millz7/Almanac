import 'package:go_router/go_router.dart';

import '../features/food/presentation/food_screen.dart';
import '../features/nature/presentation/nature_screen.dart';
import '../features/rhythms/presentation/rhythms_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/wellbeing/presentation/wellbeing_screen.dart';
import 'app_shell.dart';

/// The app's route table.
///
/// One [StatefulShellRoute] branch per bottom-navigation tab. Each
/// feature currently has a single route; as features grow, nested routes
/// (e.g. a recipe detail page under Food) can be added to their branch
/// without touching the others.
final appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
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
