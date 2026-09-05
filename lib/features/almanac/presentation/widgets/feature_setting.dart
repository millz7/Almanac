import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/features/feature_registry.dart';
import '../../../../core/settings/settings_providers.dart';
import 'inline_note.dart';

/// The list of things that can be in an Almanac, each with a switch.
///
/// The Environment is at the top and has no switch, because it is not a
/// choice: it is the app. Everything below it can be added or removed at
/// any time, and each change is written to disk before the switch moves,
/// so a switch that has moved is a change that has been saved.
class FeatureSetting extends ConsumerStatefulWidget {
  const FeatureSetting({super.key});

  @override
  ConsumerState<FeatureSetting> createState() => _FeatureSettingState();
}

class _FeatureSettingState extends ConsumerState<FeatureSetting> {
  /// Which feature is mid-save, so one slow write cannot be raced by a
  /// second tap on the same row.
  FeatureId? _saving;
  bool _failed = false;

  Future<void> _toggle(FeatureId id, bool chosen) async {
    setState(() {
      _saving = id;
      _failed = false;
    });

    try {
      await ref
          .read(userSettingsProvider.notifier)
          .setFeatureChosen(id, chosen);
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(userSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Almanac', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Add or remove parts whenever you like. Each one becomes its own '
          'place at the bottom of the screen.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        const _AlwaysOnRow(feature: FeatureRegistry.environment),

        for (final feature in FeatureRegistry.optional)
          _FeatureRow(
            feature: feature,
            chosen: settings.features.contains(feature.id),
            busy: _saving != null,
            onChanged: (chosen) => _toggle(feature.id, chosen),
          ),

        if (_failed) ...[
          const SizedBox(height: AppSpacing.sm),
          const InlineNote(
            icon: Icons.error_outline,
            isError: true,
            text: 'That could not be saved on this device. Please try again.',
          ),
        ],
      ],
    );
  }
}

/// The Environment: shown so the list is complete and it is obvious the
/// app has not forgotten it, with no control because there is no decision
/// to make.
class _AlwaysOnRow extends StatelessWidget {
  const _AlwaysOnRow({required this.feature});

  final FeatureDefinition feature;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '${feature.name}. Always part of your Almanac.',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              feature.selectedIcon,
              size: AppIconSize.md,
              color: palette.icon,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.name, style: textTheme.bodyLarge),
                  Text('Always here', style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.chosen,
    required this.busy,
    required this.onChanged,
  });

  final FeatureDefinition feature;
  final bool chosen;
  final bool busy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return SwitchListTile(
      value: chosen,
      onChanged: busy ? null : onChanged,
      contentPadding: EdgeInsets.zero,
      // The switch already announces its own state; this makes the
      // announcement say which feature it belongs to.
      title: Text(feature.name, style: textTheme.bodyLarge),
      subtitle: Text(feature.description, style: textTheme.bodySmall),
      secondary: Icon(
        chosen ? feature.selectedIcon : feature.icon,
        size: AppIconSize.md,
        color: palette.icon,
      ),
    );
  }
}
