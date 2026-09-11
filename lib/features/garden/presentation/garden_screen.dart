import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/date_words.dart';
import '../../../core/widgets/widgets.dart';
import '../application/garden_providers.dart';
import 'garden_text.dart';
import 'widgets/plant_mark.dart';

/// Where in the Garden the user is.
///
/// A stack rather than a flag, so going back from a plant returns to the
/// chapter it was opened from — and so the plant book can be reached
/// from two directions without either one losing its place.
sealed class GardenPage {
  const GardenPage();
}

/// The six chapters.
final class GardenLanding extends GardenPage {
  const GardenLanding();
}

/// One chapter: Sow, Plant, Tend, Harvest or Prune.
final class GardenActionPage extends GardenPage {
  const GardenActionPage(this.action);

  final GardenAction action;
}

/// The whole plant book, for adding something already growing.
final class GardenPlantBookPage extends GardenPage {
  const GardenPlantBookPage();
}

/// One plant's page.
final class GardenPlantPage extends GardenPage {
  const GardenPlantPage(this.plantId, {this.focus, this.forAdding = false});

  final String plantId;

  /// The chapter it was opened from, whose section comes first.
  final GardenAction? focus;

  /// Whether the user arrived here to add something they already grow,
  /// which is what decides whether adding asks how it is doing.
  final bool forAdding;
}

/// What the user grows.
final class GardenMyGardenPage extends GardenPage {
  const GardenMyGardenPage();
}

/// A gardening almanac: what is worth doing, where you are, now.
///
/// **The layering, which is the whole design.** The Environment resolves
/// where and when. That becomes a [GardeningGuide] — a broad climate
/// band, never a claim about a garden. The band plus the calendar drives
/// the *general* guide, which is Sow and Plant: discovery, open to the
/// whole plant book. The band plus the calendar plus **My Garden**
/// drives the *personalised* guide, which is Tend, Harvest and Prune:
/// nothing appears in those unless the user has said they grow it.
///
/// Nothing here calculates a season, a hemisphere or a date of its own,
/// and opening this screen never asks for a permission.
class GardenScreen extends ConsumerStatefulWidget {
  const GardenScreen({super.key});

  @override
  ConsumerState<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends ConsumerState<GardenScreen>
    with SingleTickerProviderStateMixin {
  final List<GardenPage> _stack = [const GardenLanding()];

  late final AnimationController _growth;
  bool _started = false;

  /// The plant just added, so the page can say so quietly and once.
  String? _acknowledged;

  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _growth = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Reduced motion arrives at the destination instead of travelling
    // to it: the marks are simply already drawn.
    if (MediaQuery.disableAnimationsOf(context)) {
      _growth.value = 1;
    } else {
      _growth.forward();
    }
  }

  @override
  void dispose() {
    _growth.dispose();
    super.dispose();
  }

  GardenPage get _page => _stack.last;

  void _open(GardenPage page) => setState(() {
    _stack.add(page);
    _acknowledged = null;
    _saveFailed = false;
  });

  void _back() => setState(() {
    if (_stack.length > 1) _stack.removeLast();
    _acknowledged = null;
    _saveFailed = false;
  });

  void _toLanding() => setState(() {
    _stack
      ..clear()
      ..add(const GardenLanding());
    _acknowledged = null;
    _saveFailed = false;
  });

  GardenController get _garden => ref.read(myGardenProvider.notifier);

  /// Runs a change to stored data, and says so if it could not be saved.
  Future<void> _saving(Future<void> Function() change) async {
    try {
      await change();
      if (mounted) setState(() => _saveFailed = false);
    } on Object {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  Future<void> _addSown(PlantDefinition plant) async {
    await _saving(() => _garden.addSown(plant.id));
    if (mounted) setState(() => _acknowledged = plant.id);
  }

  /// Adding something the user already has: the one question worth
  /// asking is how far along it is.
  Future<void> _addExisting(PlantDefinition plant) async {
    final state = await showDialog<EstablishmentState>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text(GardenText.howIsItGrowing),
        children: [
          for (final state in EstablishmentState.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(state),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(state.question),
              ),
            ),
        ],
      ),
    );
    if (state == null) return;

    await _saving(() => _garden.addExisting(plantId: plant.id, state: state));
    if (mounted) setState(() => _acknowledged = plant.id);
  }

  Future<void> _remove(PlantDefinition plant) async {
    final confirmed = await _confirm(
      title: GardenText.removeQuestion(plant),
      body: GardenText.removeBody,
      confirm: GardenText.remove,
    );
    if (!confirmed) return;
    await _saving(() => _garden.remove(plant.id));
  }

  Future<void> _clear() async {
    final confirmed = await _confirm(
      title: GardenText.clearTitle,
      body: GardenText.clearBody,
      confirm: GardenText.remove,
    );
    if (!confirmed) return;
    await _saving(_garden.clear);
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirm,
  }) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirm),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(GardenText.keep),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  /// Asks for a date, offering nothing later than today: a plant cannot
  /// have been sown on a day that has not happened.
  Future<CalendarDate?> _askForDate({CalendarDate? initial}) async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: (initial ?? today).toLocalDateTime(),
      firstDate: DateTime(today.year - 3),
      lastDate: today.toLocalDateTime(),
      helpText: GardenText.whenSown,
    );
    return picked == null ? null : CalendarDate.from(picked);
  }

  @override
  Widget build(BuildContext context) {
    final guide = ref.watch(gardeningGuideProvider);
    final today = ref.watch(todayProvider);
    final page = _page;

    return AppScaffold(
      title: switch (page) {
        GardenLanding() => GardenText.title,
        GardenActionPage(:final action) => action.label,
        GardenPlantBookPage() => GardenText.addExisting,
        GardenPlantPage(:final plantId) =>
          PlantBook.tryFind(plantId)?.name ?? GardenText.title,
        GardenMyGardenPage() => GardenText.myGarden,
      },
      subtitle: switch (page) {
        GardenLanding() => GardenText.context(guide, today.month),
        GardenActionPage(:final action) =>
          '${GardenText.intro(action)} · ${GardenText.context(guide, today.month)}',
        GardenPlantPage(:final plantId) => PlantBook.tryFind(
          plantId,
        )?.category.label,
        _ => null,
      },
      trailing: const AlmanacButton(),
      body: [
        // The way back sits above the content rather than below it: a
        // chapter can be a long list, and a control at the far end of
        // one is a control nobody can reach without scrolling past
        // everything.
        if (page is! GardenLanding)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _stack.length > 2 ? _back : _toLanding,
              child: const Text(GardenText.back),
            ),
          ),

        switch (page) {
          GardenLanding() => _Landing(guide: guide, onOpen: _open),
          GardenActionPage(:final action) => _ActionChapter(
            action: action,
            growth: _growth,
            onOpenPlant: (plant) =>
                _open(GardenPlantPage(plant.id, focus: action)),
            onOpenMyGarden: () => _open(const GardenMyGardenPage()),
            onOpenBook: () => _open(const GardenPlantBookPage()),
          ),
          GardenPlantBookPage() => _PlantBookList(
            growth: _growth,
            onOpenPlant: (plant) =>
                _open(GardenPlantPage(plant.id, forAdding: true)),
          ),
          GardenPlantPage(:final plantId, :final focus, :final forAdding) =>
            _PlantPage(
              plant: PlantBook.byId(plantId),
              focus: focus,
              guide: guide,
              growth: _growth,
              acknowledged: _acknowledged == plantId,
              onAdd: forAdding ? _addExisting : _addSown,
              onRemove: _remove,
              onState: (plant, state) =>
                  _saving(() => _garden.setState(plant.id, state)),
              onSowingDate: (plant) async {
                final date = await _askForDate(
                  initial: ref
                      .read(myGardenProvider)
                      .value
                      ?.find(plant.id)
                      ?.sownOn,
                );
                if (date == null) return;
                await _saving(() => _garden.setSownOn(plant.id, date));
              },
              onForgetDate: (plant) =>
                  _saving(() => _garden.setSownOn(plant.id, null)),
            ),
          GardenMyGardenPage() => _MyGardenList(
            growth: _growth,
            onOpenPlant: (plant) => _open(GardenPlantPage(plant.id)),
            onAddExisting: () => _open(const GardenPlantBookPage()),
            onClear: _clear,
          ),
        },

        if (_saveFailed)
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              GardenText.saveFailed,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.palette.error),
            ),
          ),
      ],
    );
  }
}

/// The six chapters, and the honest note about what the app knows.
class _Landing extends StatelessWidget {
  const _Landing({required this.guide, required this.onOpen});

  final GardeningGuide guide;
  final ValueChanged<GardenPage> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final action in GardenAction.values) ...[
          _ChapterCard(
            title: action.label,
            description: GardenText.cardDescription(action),
            onTap: () => onOpen(GardenActionPage(action)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _ChapterCard(
          title: GardenText.myGarden,
          description: GardenText.myGardenDescription,
          onTap: () => onOpen(const GardenMyGardenPage()),
        ),

        const SizedBox(height: AppSpacing.lg),
        Text(
          GardenText.precisionNote,
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
        if (!guide.isLocationBacked) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            GardenText.noLocationNote,
            style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      // A node of its own: without this the annotation merges into
      // whatever node happens to enclose it, and a heading above a card
      // ends up read as part of the card.
      container: true,
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimens.minTouchTarget,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// One chapter's list.
///
/// Sow and Plant come from the general guide and are grouped by
/// category. Tend, Harvest and Prune come from My Garden, so they are
/// one list with a line saying why each entry is there.
class _ActionChapter extends ConsumerWidget {
  const _ActionChapter({
    required this.action,
    required this.growth,
    required this.onOpenPlant,
    required this.onOpenMyGarden,
    required this.onOpenBook,
  });

  final GardenAction action;
  final Animation<double> growth;
  final ValueChanged<PlantDefinition> onOpenPlant;
  final VoidCallback onOpenMyGarden;
  final VoidCallback onOpenBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = action.isPersonal
        ? ref.watch(personalGuideProvider).forAction(action)
        : ref.watch(generalGuideProvider).forAction(action);

    if (suggestions.isEmpty) {
      return _Empty(
        message: GardenText.emptyFor(action),
        // A personalised chapter with nothing in it points at My Garden;
        // a general one points at the book. Neither invents a
        // recommendation to fill the space.
        actionLabel: action.isPersonal
            ? GardenText.addExisting
            : GardenText.seeThePlantBook,
        onAction: action.isPersonal ? onOpenMyGarden : onOpenBook,
      );
    }

    if (action.isPersonal) {
      return Column(
        children: [
          for (final suggestion in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SuggestionTile(
                suggestion: suggestion,
                growth: growth,
                onTap: () => onOpenPlant(suggestion.plant),
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in PlantCategory.values)
          if (suggestions.where((s) => s.plant.category == category)
              case final inCategory when inCategory.isNotEmpty) ...[
            AlmanacSectionLabel(label: category.plural),
            const SizedBox(height: AppSpacing.sm),
            for (final suggestion in inCategory)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _SuggestionTile(
                  suggestion: suggestion,
                  growth: growth,
                  onTap: () => onOpenPlant(suggestion.plant),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// One recommendation in a list.
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.growth,
    required this.onTap,
  });

  final GardenSuggestion suggestion;
  final Animation<double> growth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final reason = suggestion.reason;

    return Semantics(
      container: true,
      button: true,
      label: GardenText.suggestionLabel(suggestion),
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: growth,
              builder: (context, _) =>
                  PlantMark(plant: suggestion.plant, growth: growth.value),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(suggestion.plant.name, style: textTheme.titleMedium),
                  Text(
                    suggestion.plant.category.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    GardenText.actionPhrase(suggestion),
                    style: textTheme.bodyMedium,
                  ),
                  if (reason != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${GardenText.relevantBecause}: $reason',
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The whole plant book, for adding something already growing.
class _PlantBookList extends StatelessWidget {
  const _PlantBookList({required this.growth, required this.onOpenPlant});

  final Animation<double> growth;
  final ValueChanged<PlantDefinition> onOpenPlant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in PlantCategory.values) ...[
          AlmanacSectionLabel(label: category.plural),
          const SizedBox(height: AppSpacing.sm),
          for (final plant in PlantBook.ofCategory(category))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PlantTile(
                plant: plant,
                growth: growth,
                onTap: () => onOpenPlant(plant),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// A plain plant in the book: name, category, and its own short line.
class _PlantTile extends StatelessWidget {
  const _PlantTile({
    required this.plant,
    required this.growth,
    required this.onTap,
    this.trailingLine,
  });

  final PlantDefinition plant;
  final Animation<double> growth;
  final VoidCallback onTap;

  /// An extra line, e.g. what state a My Garden entry is in.
  final String? trailingLine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Semantics(
      container: true,
      button: true,
      label: trailingLine == null
          ? plant.spokenName
          : '${plant.name}. $trailingLine.',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: growth,
              builder: (context, _) =>
                  PlantMark(plant: plant, growth: growth.value),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plant.name, style: textTheme.titleMedium),
                  Text(
                    trailingLine ?? plant.category.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One plant's page: what to know, then what to do and when.
class _PlantPage extends ConsumerWidget {
  const _PlantPage({
    required this.plant,
    required this.focus,
    required this.guide,
    required this.growth,
    required this.acknowledged,
    required this.onAdd,
    required this.onRemove,
    required this.onState,
    required this.onSowingDate,
    required this.onForgetDate,
  });

  final PlantDefinition plant;
  final GardenAction? focus;
  final GardeningGuide guide;
  final Animation<double> growth;

  /// Whether this plant was just added, so the page can say so once.
  final bool acknowledged;

  final ValueChanged<PlantDefinition> onAdd;
  final ValueChanged<PlantDefinition> onRemove;
  final void Function(PlantDefinition, EstablishmentState) onState;
  final ValueChanged<PlantDefinition> onSowingDate;
  final ValueChanged<PlantDefinition> onForgetDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final entry = ref.watch(myGardenProvider).value?.find(plant.id);
    final month = ref.watch(todayProvider).month;

    // The section the user came for goes first; the rest keep the
    // gardener's own order.
    final actions = [
      ?focus,
      for (final action in GardenAction.values)
        if (action != focus) action,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: AnimatedBuilder(
            animation: growth,
            builder: (context, _) => PlantMark(
              plant: plant,
              growth: growth.value,
              size: kLargePlantMarkSize,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(GardenText.whatToKnow, style: textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(plant.description, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          plant.lifecycle.label,
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),

        for (final action in actions)
          if (plant.rulesFor(action) case final rules when rules.isNotEmpty)
            _PlantSection(
              action: action,
              rules: rules,
              guide: guide,
              month: month,
            ),

        const SizedBox(height: AppSpacing.lg),
        if (entry == null)
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: GardenText.addToMyGarden,
              onPressed: () => onAdd(plant),
            ),
          )
        else
          _EntryEditor(
            plant: plant,
            entry: entry,
            onRemove: onRemove,
            onState: onState,
            onSowingDate: onSowingDate,
            onForgetDate: onForgetDate,
          ),

        if (acknowledged) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(GardenText.added, style: textTheme.bodyMedium),
          ),
        ],
      ],
    );
  }
}

/// One action's rules on a plant's page, with the month they apply in
/// this region and any qualification they carry.
class _PlantSection extends StatelessWidget {
  const _PlantSection({
    required this.action,
    required this.rules,
    required this.guide,
    required this.month,
  });

  final GardenAction action;
  final List<GardeningRule> rules;
  final GardeningGuide guide;
  final int month;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AlmanacSectionLabel(label: GardenText.sectionTitle(action)),
          const SizedBox(height: AppSpacing.sm),
          for (final rule in rules)
            if (rule.appliesIn(guide.region))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthsOf(rule.windowIn(guide.region)),
                      style: textTheme.labelMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      rule.method == null
                          ? rule.guidance
                          : '${rule.method!.label}. ${rule.guidance}',
                      style: textTheme.bodyLarge,
                    ),
                    if (rule.caution case final caution?) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(caution, style: textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
        ],
      ),
    );
  }

  /// "September to March", or "June" for a single month.
  static String _monthsOf(MonthWindow window) => window.from == window.to
      ? monthName(window.from)
      : '${monthName(window.from)} to ${monthName(window.to)}';
}

/// The editing block for a plant that is in My Garden.
class _EntryEditor extends StatelessWidget {
  const _EntryEditor({
    required this.plant,
    required this.entry,
    required this.onRemove,
    required this.onState,
    required this.onSowingDate,
    required this.onForgetDate,
  });

  final PlantDefinition plant;
  final GardenPlant entry;
  final ValueChanged<PlantDefinition> onRemove;
  final void Function(PlantDefinition, EstablishmentState) onState;
  final ValueChanged<PlantDefinition> onSowingDate;
  final ValueChanged<PlantDefinition> onForgetDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(GardenText.inMyGarden, style: textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(GardenText.dateLine(entry), style: textTheme.bodyMedium),

          const SizedBox(height: AppSpacing.md),
          Text(GardenText.howIsItGrowing, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final state in EstablishmentState.values)
                _StateChip(
                  state: state,
                  selected: entry.state == state,
                  onTap: () => onState(plant, state),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            children: [
              TextButton(
                onPressed: () => onSowingDate(plant),
                child: Text(
                  entry.sownOn == null
                      ? GardenText.addSowingDate
                      : GardenText.changeDate,
                ),
              ),
              if (entry.sownOn != null)
                TextButton(
                  onPressed: () => onForgetDate(plant),
                  child: const Text(GardenText.forgetDate),
                ),
            ],
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => onRemove(plant),
              child: const Text(GardenText.remove),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.state,
    required this.selected,
    required this.onTap,
  });

  final EstablishmentState state;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: state.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.primarySoft : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? palette.primary : palette.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimens.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A second, non-colour signal.
                  if (selected) ...[
                    Icon(
                      Icons.check,
                      size: AppIconSize.sm,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(state.label, style: textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the user grows.
class _MyGardenList extends ConsumerWidget {
  const _MyGardenList({
    required this.growth,
    required this.onOpenPlant,
    required this.onAddExisting,
    required this.onClear,
  });

  final Animation<double> growth;
  final ValueChanged<PlantDefinition> onOpenPlant;
  final VoidCallback onAddExisting;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final garden = ref.watch(myGardenProvider);

    if (garden.isLoading) return const SizedBox.shrink();

    final mine = garden.value ?? MyGarden.empty;

    if (mine.known.isEmpty) {
      return _Empty(
        message: GardenText.gardenEmpty,
        note: GardenText.gardenEmptyNote,
        actionLabel: GardenText.addExisting,
        onAction: onAddExisting,
        primary: true,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in PlantCategory.values)
          if (mine.ofCategory(category) case final entries
              when entries.isNotEmpty) ...[
            AlmanacSectionLabel(label: category.plural),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PlantTile(
                  plant: PlantBook.byId(entry.plantId),
                  growth: growth,
                  trailingLine: entry.state.label,
                  onTap: () => onOpenPlant(PlantBook.byId(entry.plantId)),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],

        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: GardenText.addExisting,
            onPressed: onAddExisting,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onClear,
            child: const Text(GardenText.clearAll),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(GardenText.privacyNote, style: textTheme.bodySmall),
      ],
    );
  }
}

/// An empty state that says what is missing and offers the one route
/// out, rather than inventing something to show.
class _Empty extends StatelessWidget {
  const _Empty({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.note,
    this.primary = false,
  });

  final String message;
  final String? note;
  final String actionLabel;
  final VoidCallback onAction;

  /// Whether the way out is the point of the screen — as it is for an
  /// empty garden — or a quiet secondary route, as it is for a chapter
  /// that simply has nothing in season.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: textTheme.bodyLarge),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(note!, style: textTheme.bodySmall),
        ],
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: primary
              ? PrimaryButton(label: actionLabel, onPressed: onAction)
              : TextButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    );
  }
}
