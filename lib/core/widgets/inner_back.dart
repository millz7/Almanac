import 'package:flutter/widgets.dart';

/// Makes Android's system Back walk up a feature's own pages.
///
/// Most features keep their inner pages — a recipe, a chakra, a Nature
/// Log form — as state inside one screen rather than as routes, so the
/// navigator underneath only ever sees the feature's first page. Left
/// alone, system Back from three pages deep would close the app.
///
/// Wrapped in this, Back does exactly what the page's own Back control
/// does: [onBack] while [atTop] is false, and the ordinary behaviour
/// (leaving the feature) once it is true. It adds no prompt of its own —
/// a page with something to lose asks in its [onBack], through the same
/// path its own Back or Cancel control takes.
///
/// A dialog or sheet on top is closed first, by the navigator, before
/// this is ever asked.
class InnerBack extends StatelessWidget {
  const InnerBack({
    super.key,
    required this.atTop,
    required this.onBack,
    required this.child,
  });

  /// Whether the feature is on its first page, where Back leaves it.
  final bool atTop;

  /// One logical level up.
  final VoidCallback onBack;

  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: atTop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onBack();
    },
    child: child,
  );
}
