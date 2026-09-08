import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/context/almanac_context.dart';
import '../../../core/features/feature_registry.dart';
import '../../theme/app_theme.dart';
import '../navigation_providers.dart';

/// A way from one part of the Almanac into another, which appears only
/// while the destination is part of the user's Almanac.
///
/// **The product rule this exists to enforce.** Context leads to
/// guidance, and guidance may offer a doorway:
///
/// ```
/// CONTEXT -> GUIDANCE -> OPTIONAL DOORWAY TO AN ENABLED FEATURE
/// ```
///
/// The user's feature choices control the **doorway**. They never remove
/// the **guidance**. The Moon's reflective practices still say
/// "Meditate" when Meditation is switched off; only "Try a meditation →"
/// goes. So this widget renders nothing at all when the destination is
/// not available, and a page therefore never needs an `if` of its own —
/// which is how a stale doorway to a removed feature gets shipped.
///
/// It carries the [intent] so the destination knows why the user came,
/// then navigates to the destination's normal route. There is no hidden
/// duplicate screen at the other end.
///
/// **Why it lives in the app layer.** It needs the navigation shell and
/// the branch a feature lives in, both of which are the app's business.
/// `lib/core/` must not reach upward for those: the intent model in
/// `core/context/` is a value, and turning one into a journey is a
/// decision about this app's navigation. So the direction is
/// `core/context -> app/navigation -> features`, and a test greps
/// `lib/core/` to keep it that way.
class AlmanacDoorway extends ConsumerWidget {
  const AlmanacDoorway({super.key, required this.label, required this.intent});

  /// What the doorway says: "Try a meditation".
  final String label;

  /// Why the user is going. Its `destination` decides whether this
  /// doorway exists at all.
  final AlmanacIntent intent;

  /// Carries the intent, then goes.
  ///
  /// Two steps, in this order. The intent is set first, synchronously, so
  /// it is already waiting when the destination builds and asks for it.
  /// Then the branch changes.
  ///
  /// **Leaves the detail page behind.** A doorway sits on a page the user
  /// walked into — the Moon, off the Environment. Once they have walked
  /// out of it, the feature they came from should be back at its own
  /// root, so tapping its tab later shows the feature and not the detour
  /// they left open. That is what "no ghost stacks" means in practice.
  ///
  /// **Uses the shell the app already has.** [StatefulNavigationShell]
  /// changes branch the same way the navigation bar does, keeping each
  /// feature's own stack and scroll position. `context.go` on a branch
  /// route is not equivalent from inside another branch's nested route,
  /// so there is no parallel navigator here and no route of our own.
  void _walkThrough(BuildContext context, WidgetRef ref) {
    ref.read(almanacIntentProvider.notifier).open(intent);

    final router = GoRouter.of(context);
    if (router.canPop()) router.pop();

    final shell = StatefulNavigationShell.maybeOf(context);
    if (shell == null) {
      // No shell: only reachable from a screen shown outside it, which
      // no doorway is today. Going straight to the route is the honest
      // fallback rather than doing nothing.
      context.go(FeatureRegistry.byId(intent.destination).route);
      return;
    }
    shell.goBranch(branchIndexOf(FeatureRegistry.byId(intent.destination)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(featureAvailableProvider(intent.destination));
    // Not a disabled control and not a "coming soon": absent. The
    // guidance around it stands on its own.
    if (!available) return const SizedBox.shrink();

    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _walkThrough(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimens.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Wrapped, so a long label at 2x text reflows instead
                  // of being cut off.
                  Flexible(
                    child: Text(
                      label,
                      style: textTheme.labelLarge?.copyWith(
                        color: palette.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.arrow_forward,
                    size: AppIconSize.sm,
                    color: palette.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
