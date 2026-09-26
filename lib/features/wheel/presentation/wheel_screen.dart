import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/context/almanac_context.dart';
import '../../../core/widgets/widgets.dart';
import '../application/wheel_providers.dart';
import '../domain/festival.dart';
import '../domain/festival_text.dart';
import 'festival_detail_page.dart';
import 'widgets/wheel_diagram.dart';

/// Where the user has got to in the Wheel.
///
/// A stack, the same shape as Garden and the Nature Log, so opening a
/// festival and going back returns to the wheel rather than losing your
/// place.
sealed class WheelPage {
  const WheelPage();
}

final class WheelLanding extends WheelPage {
  const WheelLanding();
}

final class WheelFestivalPage extends WheelPage {
  const WheelFestivalPage(this.id);

  final FestivalId id;
}

/// The Wheel of the Year: the eight festivals of the modern Pagan
/// seasonal calendar, drawn as one circle and read from the user's own
/// hemisphere.
///
/// Nothing here calculates a season, a hemisphere or a date of its own —
/// see `wheel_providers.dart`, which is the one place a festival's date
/// is worked out.
///
/// Unlike Garden and the Nature Log, this screen also listens for an
/// arriving [FestivalWheelIntent] — a tap on "Beltane is approaching"
/// from the Environment, say — and opens straight to that festival's
/// page.
class WheelScreen extends ConsumerStatefulWidget {
  const WheelScreen({super.key});

  @override
  ConsumerState<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends ConsumerState<WheelScreen> {
  final List<WheelPage> _stack = [const WheelLanding()];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncArrival();
  }

  /// Collects an intent on arrival, and lets go of it on the way out.
  ///
  /// Read now, emptied after the frame — the same discipline Cookbook,
  /// Meditation and Yoga use for their own doorways.
  void _syncArrival() {
    if (!TickerMode.valuesOf(context).enabled) return;

    final intent = ref.read(almanacIntentProvider);
    if (intent is! FestivalWheelIntent) return;

    // Always lands fresh from the landing page, so "back" from the
    // festival someone arrived at returns to the wheel rather than to
    // whatever page they had open here last time.
    _stack
      ..clear()
      ..add(const WheelLanding())
      ..add(WheelFestivalPage(intent.festival));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(almanacIntentProvider.notifier).take(FeatureId.wheel);
    });
  }

  void _open(FestivalId id) =>
      setState(() => _stack.add(WheelFestivalPage(id)));

  void _back() => setState(() {
    if (_stack.length > 1) _stack.removeLast();
  });

  @override
  Widget build(BuildContext context) => InnerBack(
    // System Back from a festival returns to the wheel, as its own Back
    // does, rather than closing the app.
    atTop: _stack.length == 1,
    onBack: _back,
    child: switch (_stack.last) {
      WheelLanding() => _WheelHome(onOpen: _open),
      WheelFestivalPage(:final id) => FestivalDetailPage(id: id, onBack: _back),
    },
  );
}

/// The wheel itself, the current season and festival in words, and the
/// full list of eight festivals to open.
class _WheelHome extends ConsumerWidget {
  const _WheelHome({required this.onOpen});

  final ValueChanged<FestivalId> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final season = ref.watch(currentSeasonProvider);
    final hemisphere = ref.watch(wheelHemisphereProvider);
    final position = ref.watch(wheelPositionProvider);
    final next = ref.watch(nextFestivalProvider);
    final state = ref.watch(festivalTimingStateProvider);
    final today = ref.watch(todayProvider);
    final textTheme = Theme.of(context).textTheme;

    final nextLine = describeNextFestival(next, today);
    final daysUntil = next.date.daysSince(today);
    final festivalSummary = daysUntil <= 0
        ? 'Today is ${next.id.label}'
        : 'Next festival: ${next.id.label} in $daysUntil '
              '${daysUntil == 1 ? 'day' : 'days'}';

    return AppScaffold(
      title: 'Wheel of the Year',
      subtitle: 'Following your ${hemisphere.label} year',
      trailing: const AlmanacButton(),
      body: [
        Semantics(
          container: true,
          label:
              'Wheel of the Year. Current season: ${season.label}. '
              '$festivalSummary.',
          excludeSemantics: true,
          child: Column(
            children: [
              WheelDiagram(currentPosition: position),
              const SizedBox(height: AppSpacing.md),
              Text(
                nextLine,
                style: textTheme.journalNote,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        const AlmanacSectionLabel(label: 'The eight festivals'),
        const SizedBox(height: AppSpacing.sm),
        Column(
          children: [
            for (final festival in WheelOfYear.festivals)
              _FestivalRow(
                festival: festival,
                state: festival.id == next.id
                    ? state
                    : FestivalTimingState.normal,
                onTap: () => onOpen(festival.id),
              ),
          ],
        ),
      ],
    );
  }
}

/// One festival, named, themed, and a real tap target of its own.
///
/// **The accessible list, not the drawing.** The wheel above is
/// decorative — eight points on a rim cannot carry their own names at
/// every text size — so this is where each festival is actually named,
/// read by a screen reader, and reachable with a tap, exactly as the
/// wheel says it should be.
class _FestivalRow extends StatelessWidget {
  const _FestivalRow({
    required this.festival,
    required this.state,
    required this.onTap,
  });

  final Festival festival;
  final FestivalTimingState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final badge = switch (state) {
      FestivalTimingState.today => 'Today',
      FestivalTimingState.approaching => 'Approaching',
      FestivalTimingState.normal => null,
    };

    return Semantics(
      button: true,
      label: [festival.name, ?badge, festival.seasonalPosition].join('. '),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimens.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(festival.name, style: textTheme.titleMedium),
                        Text(
                          festival.theme,
                          style: textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    Text(
                      badge,
                      style: textTheme.labelMedium?.copyWith(
                        color: palette.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Icon(
                    Icons.chevron_right,
                    color: palette.textSecondary,
                    size: AppIconSize.sm,
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
