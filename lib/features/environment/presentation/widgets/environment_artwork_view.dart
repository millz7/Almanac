import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/season.dart';
import '../../domain/environment_artwork.dart';

/// The Environment's painting.
///
/// **The artwork owns the scene; the UI owns the facts.** Nothing is
/// drawn over this: no plants, no mountains, no stars, and no second sun
/// or moon. The celestial bodies inside the plates are part of the
/// painting, and the real astronomy is live text underneath it.
///
/// It is decorative and excluded from semantics — everything the picture
/// shows is also written in words on the page, so a screen reader loses
/// nothing by skipping it.
///
/// **The artwork is never distorted.** The plates are 1770 × 1500, and
/// the frame holds that ratio, so `BoxFit.cover` inside it crops nothing
/// and stretches nothing. On a wide screen the frame grows to a wider
/// column than the text does — a wider Almanac page, rather than a phone
/// pasted into the middle of a tablet.
class EnvironmentArtworkView extends StatelessWidget {
  const EnvironmentArtworkView({super.key, required this.asset});

  /// The plate to show, from [EnvironmentArtwork.forState].
  final String asset;

  /// The plates' own ratio. Holding it means the fit never has anything
  /// to crop, which is what guarantees the painting is never squashed.
  static const aspectRatio = 1770 / 1500;

  /// How long one plate takes to become another.
  static const fadeDuration = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    // Reduced motion arrives at the new light rather than travelling to
    // it. No ticker is left running either way: this is a one-shot fade
    // that starts when the state changes and stops when it arrives.
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : fadeDuration;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: AnimatedSwitcher(
            duration: duration,
            // Cross-fade rather than fade-out-then-in, so the lake is
            // never briefly missing between two paintings of it.
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            child: Image.asset(
              asset,
              // The key is what tells the switcher two plates are
              // different pictures rather than one rebuilt widget.
              key: ValueKey(asset),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              // A plate is decorative; the page says everything it shows.
              excludeFromSemantics: true,
              gaplessPlayback: true,
              // Until the bytes are decoded, the paper shows through
              // rather than a grey box or a spinner.
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return ColoredBox(color: AlmanacPaper.groundInset);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the *next* likely plate warm without loading a gallery.
///
/// At most the current plate and the one the day is heading towards are
/// decoded — two images, not sixteen. The day runs sunrise, day, sunset,
/// night and round again *within the season*: a spring night is followed
/// by a spring sunrise, not by a summer one.
Future<void> precacheAdjacentArtwork(
  BuildContext context, {
  required Season season,
  required EnvironmentLightState light,
}) async {
  const order = EnvironmentLightState.values;
  final next = order[(order.indexOf(light) + 1) % order.length];
  await precacheImage(
    AssetImage(EnvironmentArtwork.forState(season: season, light: next)),
    context,
  );
}
