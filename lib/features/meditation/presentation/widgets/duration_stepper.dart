import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/meditation_technique.dart';

/// How long to sit for.
///
/// A minus, a number and a plus. Not a slider — a slider invites fiddling
/// and reads a value nobody needs to the nearest pixel — and not a picker
/// with presets and categories, which would be a settings screen in
/// disguise. Whole minutes, and four of them to begin with.
class DurationStepper extends StatelessWidget {
  const DurationStepper({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  bool get _canShorten => minutes > kMinSessionMinutes;
  bool get _canLengthen => minutes < kMaxSessionMinutes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final recommended = minutes == kDefaultSessionMinutes;

    return Column(
      children: [
        // The number on its own line rather than wedged between the two
        // buttons: at a large text size a row of button-word-button has
        // nowhere to go, and this cannot run out of room.
        Semantics(
          container: true,
          // Announced when it changes, because the change is the answer
          // to the button that was just pressed.
          liveRegion: true,
          child: Text(
            '$minutes ${minutes == 1 ? 'minute' : 'minutes'}',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _canShorten ? () => onChanged(minutes - 1) : null,
              icon: const Icon(Icons.remove),
              tooltip: 'A minute less',
            ),
            const SizedBox(width: AppSpacing.xl),
            IconButton(
              onPressed: _canLengthen ? () => onChanged(minutes + 1) : null,
              icon: const Icon(Icons.add),
              tooltip: 'A minute more',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // Kept in the layout either way, so nudging the duration does not
        // make the page jump.
        Opacity(
          opacity: recommended ? 1 : 0,
          child: ExcludeSemantics(
            excluding: !recommended,
            child: Text(
              'A good place to start',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
