import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/environment_providers.dart';

/// The offer, when no position has been shared.
///
/// Deliberately not styled as an error and deliberately not a filled
/// button: declining location is a perfectly good answer, the rest of the
/// Almanac works without it, and the app never prompts on its own — only
/// from this tap.
///
/// Lifted out of the old `SunCard` unchanged when the Environment was
/// rebuilt in Step 18. Same words, same two states, same behaviour: the
/// permission flow is one implementation and this is it.
class LocationInvitation extends ConsumerWidget {
  const LocationInvitation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(locationStateProvider);
    final controller = ref.read(locationStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect location to see sunrise and sunset where you are.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Read on this device only, and never sent anywhere. Everything '
          'else here works without it.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        // A quiet text action rather than a filled button: this is an
        // offer, and "no" stays a first-class answer.
        Align(
          alignment: Alignment.centerLeft,
          child: state.canRequest
              ? TextButton(
                  onPressed: controller.requestAccess,
                  child: const Text('Enable location'),
                )
              : TextButton(
                  // Android will not prompt again once it has been
                  // permanently denied, so the only honest offer left is
                  // a route to the place that can change it.
                  onPressed: controller.openSystemSettings,
                  child: const Text('Open device settings'),
                ),
        ),
      ],
    );
  }
}
