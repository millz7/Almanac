import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/environment/environment_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_providers.dart';

/// The application root.
///
/// Watches the active seasonal palette and rebuilds the theme when the
/// season or the sun changes. Because the theme is set on [MaterialApp],
/// every screen — onboarding included, and screens not written yet —
/// inherits the current season automatically, and Flutter animates the
/// change rather than snapping to it.
class AlmanacApp extends ConsumerWidget {
  const AlmanacApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);

    return _EnvironmentRefresher(
      child: MaterialApp.router(
        title: 'Almanac',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.fromPalette(palette),
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}

/// Keeps the environment in step with the world outside the app.
///
/// Two jobs, both about time having passed while the app was not looking:
///
/// * On startup and on resume it re-checks location **without
///   prompting**, so permission granted or revoked in system settings is
///   noticed.
/// * On resume it re-resolves the environment, since a phone can sit in
///   a pocket from afternoon until well after dark.
class _EnvironmentRefresher extends ConsumerStatefulWidget {
  const _EnvironmentRefresher({required this.child});

  final Widget child;

  @override
  ConsumerState<_EnvironmentRefresher> createState() =>
      _EnvironmentRefresherState();
}

class _EnvironmentRefresherState extends ConsumerState<_EnvironmentRefresher> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _refresh);
    // Deferred past the first frame so the app paints immediately rather
    // than waiting on a platform call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  void _refresh() {
    ref.read(locationStateProvider.notifier).refresh();
    ref.invalidate(naturalEnvironmentProvider);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
