import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_providers.dart';
import 'theme/app_theme.dart';

/// The key of the shell's [Scaffold], so the Almanac can be opened from
/// inside a tab screen.
///
/// Each tab screen builds its own [Scaffold] (through `AppScaffold`), so
/// `Scaffold.of(context)` from a tab finds that one rather than the shell
/// that actually holds the drawer. Holding the shell's key in a provider
/// is the smallest way to bridge that, and it means a test can open the
/// Almanac without going through the widget tree.
final almanacScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>(
  (ref) => GlobalKey<ScaffoldState>(debugLabel: 'almanacShell'),
);

/// The top-right control that opens the user's Almanac.
///
/// Deliberately not a settings cog. It is a small pressed-leaf mark, and
/// its label is the user's own — "Millie's Almanac" — so the panel reads
/// as their own book rather than as a preferences screen. The name is
/// carried by the tooltip and the accessibility label rather than printed
/// beside the icon, which keeps the header calm at any text size.
class AlmanacButton extends ConsumerWidget {
  const AlmanacButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final title = ref.watch(almanacTitleProvider);

    return IconButton(
      onPressed: () =>
          ref.read(almanacScaffoldKeyProvider).currentState?.openEndDrawer(),
      icon: const Icon(Icons.eco_outlined),
      // The full title, so the control announces whose Almanac it opens
      // rather than "button".
      tooltip: title,
      // A thin ring rather than a filled disc. The reference's top-right
      // control is drawn, not stamped: on an illustrated header a solid
      // capsule is the one thing that reads as a toolbar.
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.icon,
        side: BorderSide(color: palette.border.withValues(alpha: 0.8)),
        minimumSize: const Size.square(AppDimens.minTouchTarget),
        iconSize: AppIconSize.sm + 2,
      ),
    );
  }
}
