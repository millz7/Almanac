import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/settings/settings_providers.dart';
import 'inline_note.dart';

/// Whether the Moon also shows the Māori lunar calendar.
///
/// A preference inside the Moon, not a part of the Almanac: it adds no
/// category, no tab and no onboarding question. Off until the user turns
/// it on, and — like every switch in the drawer — written to disk before
/// it moves.
class MaramatakaSetting extends ConsumerStatefulWidget {
  const MaramatakaSetting({super.key});

  static const title = 'Include Māori lunar calendar';
  static const description =
      'Show Maramataka alongside the astronomical Moon cycle.';

  @override
  ConsumerState<MaramatakaSetting> createState() => _MaramatakaSettingState();
}

class _MaramatakaSettingState extends ConsumerState<MaramatakaSetting> {
  bool _saving = false;
  bool _failed = false;

  Future<void> _toggle(bool include) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(userSettingsProvider.notifier)
          .setIncludeMaramataka(include);
    } on Object {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final include = ref.watch(
      userSettingsProvider.select((settings) => settings.includeMaramataka),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: include,
          onChanged: _saving ? null : _toggle,
          contentPadding: EdgeInsets.zero,
          title: Text(MaramatakaSetting.title, style: textTheme.bodyLarge),
          subtitle: Text(
            MaramatakaSetting.description,
            style: textTheme.bodySmall,
          ),
          secondary: Icon(
            Icons.nightlight_outlined,
            size: AppIconSize.md,
            color: palette.icon,
          ),
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
