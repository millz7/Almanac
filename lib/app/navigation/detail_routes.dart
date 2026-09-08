import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/features/feature_registry.dart';
import '../../features/environment/presentation/moon_screen.dart';

/// Pages that live *inside* a feature rather than beside it.
///
/// The Environment has hidden depth: the moon on the page is a way in to
/// a page about the moon. That page is not a feature — no tab, no
/// [FeatureId], no onboarding question — so it is a child route of the
/// feature's own branch. It inherits the right behaviour rather than
/// being given it: Back returns to the feature, the navigation bar keeps
/// the feature selected, and there is no second navigator anywhere.
///
/// One function so the router does not grow a branch-shaped `if` for
/// every detail page a feature turns out to want.
List<RouteBase> detailRoutesFor(FeatureDefinition feature) =>
    switch (feature.id) {
      FeatureId.environment => [
        GoRoute(
          // Relative to the parent, which makes the full path
          // `/environment/moon`.
          path: 'moon',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const MoonScreen(),
            // Short, and a fade with the faintest scale — the moon on the
            // Environment page grows into the moon on this one. A true
            // shared-element transition would be a fragile flight between
            // two navigators for a gain nobody would name; consistency and
            // stability outrank cleverness. See
            // `docs/almanac_visual_language.md`.
            transitionDuration: const Duration(milliseconds: 220),
            reverseTransitionDuration: const Duration(milliseconds: 180),
            transitionsBuilder: (context, animation, _, child) {
              // Reduced motion arrives at the page rather than travelling
              // to it.
              if (MediaQuery.disableAnimationsOf(context)) return child;

              final eased = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: eased,
                child: ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(eased),
                  child: child,
                ),
              );
            },
          ),
        ),
      ],
      _ => const [],
    };
