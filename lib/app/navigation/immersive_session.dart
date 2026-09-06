import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'immersion.dart';

/// The lifecycle a screen needs when it takes the whole display for a
/// timed session — Meditation's breathing, Yoga's movement, and whatever
/// comes next.
///
/// Two features needed exactly the same three rules, so they are written
/// once here rather than twice in two screens:
///
/// * Backgrounding the app ends the session. `onHide` and `onPause`
///   both, and deliberately **not** `onInactive`: hidden and paused mean
///   the app is genuinely out of sight, whereas inactive is a
///   notification shade or an incoming call, which should not throw away
///   somebody's practice.
/// * Switching to another part of the Almanac ends it too. That leaves
///   the screen alive but mutes its ticker, which would otherwise freeze
///   a session half-finished and resume it days later.
/// * While a session runs, the app's frame steps out of the way, and it
///   comes back however the session ends.
///
/// Composition rather than a mixin: a screen owns one of these, which
/// keeps the ordering of `initState` and `dispose` in plain sight.
class ImmersiveSession {
  ImmersiveSession({required this.ref, required VoidCallback onLeave})
    : _onLeave = onLeave {
    _lifecycle = AppLifecycleListener(onHide: onLeave, onPause: onLeave);
  }

  final WidgetRef ref;
  final VoidCallback _onLeave;
  late final AppLifecycleListener _lifecycle;

  /// Asks the shell to step back. Call when a session begins.
  void enter() => ref.read(immersiveModeProvider.notifier).enter();

  /// Gives the frame back. Safe to call when it was never taken, which is
  /// what lets a screen clear this on the way past.
  void exit() => ref.read(immersiveModeProvider.notifier).exit();

  /// Call from `didChangeDependencies`: ends the session if this screen
  /// is no longer the one in front of the user.
  ///
  /// [onLeave] must be safe to call when nothing is running.
  void checkVisibility(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) _onLeave();
  }

  void dispose() => _lifecycle.dispose();
}
