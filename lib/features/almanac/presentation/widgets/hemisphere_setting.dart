import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/environment/environment_providers.dart';
import '../../../../core/environment/geo_location.dart';
import '../../../../core/settings/settings_providers.dart';
import '../../../../core/widgets/widgets.dart';
import 'inline_note.dart';

/// Lets the user correct the hemisphere they chose during onboarding.
class HemisphereSetting extends ConsumerStatefulWidget {
  const HemisphereSetting({super.key});

  @override
  ConsumerState<HemisphereSetting> createState() => HemisphereSettingState();
}

class HemisphereSettingState extends ConsumerState<HemisphereSetting> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _choose(Hemisphere hemisphere) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });

    try {
      await ref
          .read(userSettingsProvider.notifier)
          .selectHemisphere(hemisphere);
      // Nothing to navigate: the environment and theme are watching the
      // setting, so the whole app has already changed season by now.
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chosen = ref.watch(userSettingsProvider).hemisphere;
    final resolved = ref.watch(resolvedHemisphereProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hemisphere', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Which half of the world your seasons follow.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        for (final hemisphere in Hemisphere.values) ...[
          ChoiceCard(
            title: hemisphere.label,
            selected: chosen == hemisphere,
            enabled: !_saving,
            onPressed: () => _choose(hemisphere),
          ),
          if (hemisphere != Hemisphere.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],

        // When a real position disagrees with the stored choice, say so
        // plainly rather than letting the app quietly contradict the user.
        if (resolved.disagreesWithPreference) ...[
          const SizedBox(height: AppSpacing.md),
          InlineNote(
            icon: Icons.my_location_outlined,
            text:
                'Your location puts you in the '
                '${resolved.hemisphere.label.toLowerCase()}, so seasons are '
                'following that. Your choice above is kept.',
          ),
        ],

        if (_failed) ...[
          const SizedBox(height: AppSpacing.md),
          InlineNote(
            icon: Icons.error_outline,
            isError: true,
            text: 'That could not be saved on this device. Please try again.',
          ),
        ],
      ],
    );
  }
}
