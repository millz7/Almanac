import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

/// The application root.
///
/// Riverpod's [ProviderScope] wraps the whole app so any provider added by
/// a future feature is available everywhere without further setup here.
class AlmanacApp extends ConsumerWidget {
  const AlmanacApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Almanac',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
