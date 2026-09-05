import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/almanac/presentation/almanac_drawer.dart';
import 'almanac_button.dart';
import 'navigation/almanac_navigation_bar.dart';
import 'navigation/navigation_providers.dart';

/// The frame around the app: the user's own navigation at the bottom, and
/// their Almanac a swipe or a tap away at the top right.
///
/// Wraps the [StatefulNavigationShell] go_router hands us, so each
/// destination keeps its own navigation stack and scroll position when
/// switching between them — including destinations the user has
/// temporarily switched off, which is why coming back to one lands where
/// they left it.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(visibleDestinationsProvider);

    // The bar's own indices, which are not branch indices: branches exist
    // for every feature, the bar only shows the chosen ones.
    final selected = destinations.indexWhere(
      (feature) => branchIndexOf(feature) == navigationShell.currentIndex,
    );

    return Scaffold(
      // Held in a provider so a tab screen's own header can open this
      // Scaffold's drawer rather than its own.
      key: ref.watch(almanacScaffoldKeyProvider),
      body: navigationShell,
      endDrawer: const AlmanacDrawer(),
      // Opened from the top-right control, not by dragging from the
      // screen edge: an accidental swipe while reading the sky should not
      // pull the settings panel out.
      endDrawerEnableOpenDragGesture: false,
      bottomNavigationBar: AlmanacNavigationBar(
        destinations: destinations,
        selectedIndex: selected,
        onDestinationSelected: (index) {
          final branch = branchIndexOf(destinations[index]);
          navigationShell.goBranch(
            branch,
            // Tapping the destination you are already on returns to the
            // top of it, which is the convention everywhere else.
            initialLocation: branch == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
