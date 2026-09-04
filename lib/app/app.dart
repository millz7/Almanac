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
/// every screen — including ones not written yet — inherits the current
/// season automatically, and Flutter animates the change rather than
/// snapping to it.
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
        routerConfig: appRouter,
      ),
    );
  }
}

/// Re-resolves the natural environment when the app comes back to the
/// foreground.
///
/// A phone can sit in a pocket from afternoon to well after dark; the
/// scheduled refresh timer covers a running app, and this covers the case
/// where the app was not running at the moment the sun set.
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
    _listener = AppLifecycleListener(
      onResume: () => ref.invalidate(naturalEnvironmentProvider),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
