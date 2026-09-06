import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether a screen has asked for the app's frame to step out of the way.
///
/// The navigation bar belongs to the shell, not to any one screen, so a
/// screen that wants the whole display — Meditation, once a session
/// starts — has to be able to say so. This is that seam, and it is
/// deliberately one boolean: a screen asks, the shell listens, and
/// neither knows anything else about the other.
///
/// Kept in the app layer rather than in a feature, because it is a fact
/// about the frame rather than about meditating.
final immersiveModeProvider = NotifierProvider<ImmersionController, bool>(
  ImmersionController.new,
);

class ImmersionController extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;

  /// Safe to call when already out, which is what lets a screen clear
  /// this on the way past without first asking whether it needs to.
  void exit() => state = false;
}
