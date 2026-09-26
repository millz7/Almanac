import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/context/cycle_phase_context.dart';
import '../../../app/context/festival_context.dart';
import '../../../core/context/almanac_context.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/own_recipes_providers.dart';
import '../domain/cycle_recipes.dart';
import '../domain/recipe_catalogue.dart';
import '../domain/weather_cookbook_note.dart';
import 'cookbook_text.dart';
import 'own_recipes.dart';
import 'widgets/recipe_card.dart';
import 'widgets/season_selector.dart';
import 'widgets/season_sprig.dart';

/// A small seasonal cookbook.
///
/// **The season comes from the Environment.** It asks
/// [currentSeasonProvider] which season the user is actually in — real
/// astronomy, their own hemisphere — and marks that one "Your season".
/// There is no second season calculation here, and no northern default.
///
/// **Browsing is only browsing.** Choosing another season changes what
/// this screen lists and nothing else: the marker stays where it was,
/// nothing is written down, and the Environment is untouched. On a
/// restart the Cookbook simply opens on the current season again.
///
/// **What it does not claim.** The app knows the season; it does not know
/// what is growing near anybody. So a collection is "inspired by winter
/// ingredients, wherever you are" and never "in season near you".
///
/// **Your recipes.** The one thing the Cookbook keeps is what the user
/// writes down themselves — see [OwnRecipesSection] — in its own local
/// store. It still keeps no favourites, no history and no note of what
/// was looked at.
class CookbookScreen extends ConsumerStatefulWidget {
  const CookbookScreen({super.key});

  @override
  ConsumerState<CookbookScreen> createState() => _CookbookScreenState();
}

class _CookbookScreenState extends ConsumerState<CookbookScreen>
    with SingleTickerProviderStateMixin {
  /// The season being browsed, or null to follow the user's own.
  Season? _browsing;

  /// The cycle phase the user arrived with, when they came from Cycle
  /// Syncing's food guidance.
  ///
  /// Taken from the shared intent on arrival and held for as long as
  /// this screen is the one in front of them; dropped the moment it is
  /// not, because a contextual intent belongs to the journey that
  /// created it.
  CyclePhase? _arrivedForPhase;

  /// The festival the user arrived with, when they came from the Wheel
  /// of the Year's food and drink suggestions.
  ///
  /// Independent of [_arrivedForPhase]: a cycle phase and a festival are
  /// two separate observations about the same day.
  FestivalId? _arrivedForFestival;

  /// The recipe being read, or null for the collection.
  Recipe? _open;

  /// One of the user's own recipes being read or written, or null.
  _OwnView? _own;

  /// Whether the own recipe on screen has just been saved.
  bool _ownSaved = false;
  bool _ownSaveFailed = false;

  /// Whether the recipe form on screen holds words not yet saved. Read
  /// by system Back, which asks the same question Cancel does.
  bool _formDirty = false;

  /// Set while a save is being written, so a second tap on Save cannot
  /// write the recipe twice.
  bool _ownSaving = false;

  late final AnimationController _growth;
  bool _started = false;

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
    _syncArrival();
    if (_started) return;
    _started = true;

    // Reduced motion arrives at the destination instead of travelling
    // to it: the sprigs are simply already drawn.
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

  bool get _still => MediaQuery.disableAnimationsOf(context);

  /// Collects an intent on arrival, and lets go of it on the way out.
  ///
  /// The intent is read now and emptied after the frame: changing a
  /// provider from a widget life-cycle is not allowed, and deferring it
  /// also means the first frame already shows the right collection
  /// rather than flickering into it.
  void _syncArrival() {
    // The same seam the immersive sessions use to notice they are no
    // longer the visible branch.
    if (!TickerMode.valuesOf(context).enabled) {
      _arrivedForPhase = null;
      _arrivedForFestival = null;
      return;
    }

    final intent = ref.read(almanacIntentProvider);
    // Two doors into the same room, and each is remembered separately.
    if (intent is CycleCookbookIntent) {
      _arrivedForPhase = intent.phase;
    } else if (intent is FestivalCookbookIntent) {
      _arrivedForFestival = intent.festival;
    } else {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(almanacIntentProvider.notifier).take(FeatureId.cookbook);
    });
  }

  void _browse(Season season) {
    setState(() => _browsing = season);
    // The new collection grows in as the last one did. One shot, and
    // nothing at all if the device has asked for less motion.
    if (!_still) _growth.forward(from: 0);
  }

  OwnRecipesController get _ownRecipes => ref.read(ownRecipesProvider.notifier);

  void _showOwn(_OwnView? view, {bool saved = false}) => setState(() {
    _own = view;
    _ownSaved = saved;
    _ownSaveFailed = false;
    _formDirty = false;
  });

  /// Asks before anything is thrown away. The same plain dialog the
  /// Garden and the Nature Log use, so a question reads the same
  /// everywhere in the book.
  Future<bool> _confirm({
    required String title,
    required String body,
    required String yes,
    required String no,
  }) => Confirm.ask(context, title: title, body: body, yes: yes, no: no);

  Future<void> _saveOwn(String? id, OwnRecipeDraft draft) async {
    if (_ownSaving) return;
    _ownSaving = true;
    try {
      final savedId = id == null
          ? await _ownRecipes.add(
              title: draft.title,
              ingredients: draft.ingredients,
              method: draft.method,
              note: draft.note,
            )
          : await _ownRecipes
                .edit(
                  id,
                  title: draft.title,
                  ingredients: draft.ingredients,
                  method: draft.method,
                  note: draft.note,
                )
                .then((_) => id);
      if (mounted) _showOwn(_ReadingOwn(savedId), saved: true);
    } on Object {
      // Nothing is shown as saved, the form keeps every word, and Save
      // can simply be tried again.
      if (mounted) setState(() => _ownSaveFailed = true);
    } finally {
      _ownSaving = false;
    }
  }

  Future<void> _cancelOwn(String? id, {required bool changed}) async {
    if (changed && !await UnsavedChanges.confirmLeave(context)) return;
    if (mounted) _showOwn(id == null ? null : _ReadingOwn(id));
  }

  Future<void> _deleteOwn(OwnRecipe recipe) async {
    final confirmed = await _confirm(
      title: CookbookText.deleteTitle,
      body: CookbookText.deleteBody,
      yes: CookbookText.delete,
      no: CookbookText.keep,
    );
    if (!confirmed) return;
    try {
      await _ownRecipes.remove(recipe.id);
      if (mounted) _showOwn(null);
    } on Object {
      if (mounted) setState(() => _ownSaveFailed = true);
    }
  }

  Widget _ownPage(_OwnView view) {
    final recipes = ref.watch(ownRecipesProvider).value ?? OwnRecipes.empty;
    final textTheme = Theme.of(context).textTheme;

    final failure = _ownSaveFailed
        ? Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              CookbookText.saveFailed,
              style: textTheme.bodyMedium?.copyWith(
                color: context.palette.error,
              ),
            ),
          )
        : null;

    switch (view) {
      case _ReadingOwn(:final id):
        final recipe = recipes.find(id);
        // Gone — removed, or never stored — so there is nothing to read.
        if (recipe == null) return _collection();
        return AppScaffold(
          title: recipe.title,
          subtitle: CookbookText.yourRecipe,
          trailing: const AlmanacButton(),
          body: [
            OwnRecipePage(
              recipe: recipe,
              saved: _ownSaved,
              onEdit: () => _showOwn(_WritingOwn(id)),
              onDelete: () => _deleteOwn(recipe),
              onBack: () => _showOwn(null),
            ),
            ?failure,
          ],
        );
      case _WritingOwn(:final id):
        final existing = id == null ? null : recipes.find(id);
        return AppScaffold(
          title: existing == null
              ? CookbookText.addRecipe
              : CookbookText.editRecipe,
          subtitle: existing?.title,
          trailing: const AlmanacButton(),
          body: [
            OwnRecipeForm(
              key: ValueKey('own-form-$id'),
              existing: existing,
              onSave: (draft) => _saveOwn(existing?.id, draft),
              onCancel: (changed) => _cancelOwn(existing?.id, changed: changed),
              onDirtyChanged: (dirty) => _formDirty = dirty,
            ),
            ?failure,
          ],
        );
    }
  }

  /// One logical level up: from a form (asking first if anything was
  /// typed), from one of the user's recipes, or from a catalogue recipe.
  void _up() {
    switch (_own) {
      case _WritingOwn(:final id):
        final existing = id == null
            ? null
            : ref.read(ownRecipesProvider).value?.find(id);
        _cancelOwn(existing?.id, changed: _formDirty);
      case _ReadingOwn():
        _showOwn(null);
      case null:
        if (_open != null) setState(() => _open = null);
    }
  }

  @override
  Widget build(BuildContext context) => InnerBack(
    atTop: _own == null && _open == null,
    onBack: _up,
    child: _page(),
  );

  Widget _page() {
    final recipe = _open;

    if (_own case final own?) return _ownPage(own);

    if (recipe != null) {
      return AppScaffold(
        // The recipe's own name is the heading of its page: it is what
        // the page is, and it is what a screen reader should say first.
        title: recipe.name,
        subtitle: '${recipe.season.label} recipe',
        trailing: const AlmanacButton(),
        body: [
          _RecipePage(
            recipe: recipe,
            onBack: () => setState(() => _open = null),
          ),
        ],
      );
    }

    return _collection();
  }

  /// The Cookbook's main page: the seasonal collection, then whatever
  /// the day adds, then the user's own recipes.
  Widget _collection() {
    final current = ref.watch(currentSeasonProvider);
    final season = _browsing ?? current;

    // What the cycle collection is for: the phase they arrived with, or
    // — on a direct entry — whatever phase Cycle currently shows.
    // Null when Cycle is not part of their Almanac or has nothing to
    // say, and then there is simply no cycle collection.
    final cyclePhase = ref.watch(almanacCyclePhaseProvider(_arrivedForPhase));
    // The same shape for the Wheel of the Year: null when it is switched
    // off, or when no festival is close enough to be worth mentioning.
    final festival = ref.watch(almanacFestivalProvider(_arrivedForFestival));

    return AppScaffold(
      title: CookbookText.title,
      subtitle: CookbookText.introduction,
      trailing: const AlmanacButton(),
      body: [
        // The seasonal collection, unchanged and still the page.
        SeasonSelector(selected: season, current: current, onSelected: _browse),
        Text(
          RecipeCatalogue.collectionNote(season),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        // Only while looking at the season actually being lived in —
        // browsing away from it says nothing about today's weather.
        if (season == current) const _WeatherNote(),
        _Collection(
          season: season,
          growth: _growth,
          onOpen: (recipe) => setState(() => _open = recipe),
        ),
        // Then an approaching festival — a few ideas for one particular
        // day, so it reads before anything that applies all month.
        if (festival case final active?)
          _FestivalCollection(
            active: active,
            arrived: _arrivedForFestival != null,
          ),
        // And last, a small collection for the time of month.
        if (cyclePhase case final phase?)
          _CycleCollection(
            phase: phase,
            arrived: _arrivedForPhase != null,
            growth: _growth,
            onOpen: (recipe) => setState(() => _open = recipe),
          ),
        // The user's own, after everything the Almanac offers.
        OwnRecipesSection(
          onOpen: (recipe) => _showOwn(_ReadingOwn(recipe.id)),
          onAdd: () => _showOwn(const _WritingOwn()),
        ),
      ],
    );
  }
}

/// Which of the user's own recipes is on screen, and how.
sealed class _OwnView {
  const _OwnView();
}

/// Reading one.
final class _ReadingOwn extends _OwnView {
  const _ReadingOwn(this.id);

  final String id;
}

/// Writing one: a new recipe when [id] is null, or changing one.
final class _WritingOwn extends _OwnView {
  const _WritingOwn([this.id]);

  final String? id;
}

/// A quiet, secondary nudge towards the warmer or lighter end of
/// today's seasonal collection. Never a second way of choosing what to
/// cook — see `WeatherCookbookNotes`. Absent entirely with no location,
/// no network, or a day with nothing distinctive about it.
class _WeatherNote extends ConsumerWidget {
  const _WeatherNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weather = ref.watch(currentWeatherProvider);
    if (weather == null) return const SizedBox.shrink();
    final cue = WeatherCookbookNotes.cueFor(weather.current);
    if (cue == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        WeatherCookbookNotes.noteFor(cue),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.palette.textSecondary),
      ),
    );
  }
}

/// A small collection for the time of month.
///
/// **Not a second cookbook.** The same sixteen recipes, filtered by a
/// mapping the Cookbook owns — see [CycleRecipes] — so there is no
/// hidden recipe database and nothing is duplicated. It sits under the
/// seasonal collection rather than replacing it.
///
/// No recipe here is claimed to treat anything.
class _CycleCollection extends StatelessWidget {
  const _CycleCollection({
    required this.phase,
    required this.arrived,
    required this.growth,
    required this.onOpen,
  });

  final CyclePhase phase;

  /// Whether the user came through Cycle Syncing's door, which decides
  /// only how the heading reads.
  final bool arrived;

  final Animation<double> growth;
  final ValueChanged<Recipe> onOpen;

  @override
  Widget build(BuildContext context) {
    final recipes = CycleRecipes.forPhase(phase);
    if (recipes.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        AlmanacSectionLabel(
          label: arrived
              ? CookbookText.forYourPhase(phase)
              : CookbookText.forYourCycle,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(CycleRecipes.collectionNote(phase), style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        for (final (index, recipe) in recipes.indexed) ...[
          AnimatedBuilder(
            animation: growth,
            builder: (context, _) => RecipeCard(
              recipe: recipe,
              variant: index,
              growth: Curves.easeOut.transform(growth.value),
              onTap: () => onOpen(recipe),
            ),
          ),
          if (recipe != recipes.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// A small set of suggestions for an approaching or current festival.
///
/// **Not a recipe collection.** Unlike the seasonal and cycle
/// collections, these are the Wheel of the Year's own suggestion ideas
/// for a meal, a treat and a drink — not full recipes drawn from the
/// catalogue — and the section says so plainly rather than implying they
/// are the same kind of thing as the cards above.
class _FestivalCollection extends StatelessWidget {
  const _FestivalCollection({required this.active, required this.arrived});

  final ActiveFestival active;

  /// Whether the user came through the Wheel's own door, which decides
  /// only how the heading reads.
  final bool arrived;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final heading = arrived
        ? FestivalCookbookIntent(active.id).heading
        : (active.state == FestivalTimingState.today
              ? 'Today is ${active.id.label}'
              : '${active.id.label} is approaching');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        AlmanacSectionLabel(label: heading),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'A few suggestion ideas for the day, not full recipes.',
          style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        _FestivalIdea(
          label: 'Meal',
          value: active.food.meal,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppSpacing.sm),
        _FestivalIdea(
          label: 'Treat',
          value: active.food.treat,
          textTheme: textTheme,
        ),
        const SizedBox(height: AppSpacing.sm),
        _FestivalIdea(
          label: 'Drink',
          value: active.food.drink,
          textTheme: textTheme,
        ),
      ],
    );
  }
}

class _FestivalIdea extends StatelessWidget {
  const _FestivalIdea({
    required this.label,
    required this.value,
    required this.textTheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// The four recipes of one season.
class _Collection extends StatelessWidget {
  const _Collection({
    required this.season,
    required this.growth,
    required this.onOpen,
  });

  final Season season;
  final Animation<double> growth;
  final ValueChanged<Recipe> onOpen;

  @override
  Widget build(BuildContext context) {
    final recipes = RecipeCatalogue.forSeason(season);

    return Column(
      children: [
        for (final (index, recipe) in recipes.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == recipes.length - 1 ? 0 : AppSpacing.md,
            ),
            child: AnimatedBuilder(
              animation: growth,
              // Only the drawn sprig follows the animation; the words are
              // there from the first frame, which is both faster to read
              // and less to rebuild.
              builder: (context, _) => RecipeCard(
                recipe: recipe,
                variant: index,
                growth: Curves.easeOut.transform(growth.value),
                onTap: () => onOpen(recipe),
              ),
            ),
          ),
      ],
    );
  }
}

/// One recipe, laid out for cooking from.
///
/// Calmer than the collection, and in the order a cook needs: what it is,
/// how long it takes, what to get out, what to do. The illustration is
/// small and at the top, so the ingredients are never more than a glance
/// away.
class _RecipePage extends StatelessWidget {
  const _RecipePage({required this.recipe, required this.onBack});

  final Recipe recipe;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final tags = CookbookText.tagLine(recipe);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: SeasonSprig(season: recipe.season, size: kLargeSprigSize),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(recipe.description, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.md),

        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _Fact(
              label: CookbookText.prepLabel,
              value: CookbookText.duration(recipe.prepTime),
              spoken: CookbookText.prepSpoken(recipe.prepTime),
            ),
            _Fact(
              label: CookbookText.cookLabel,
              value: CookbookText.duration(recipe.cookTime),
              spoken: CookbookText.cookSpoken(recipe.cookTime),
            ),
            _Fact(
              label: CookbookText.servesLabel,
              value: '${recipe.servings}',
              spoken: CookbookText.serves(recipe.servings),
            ),
          ],
        ),
        if (tags != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            tags,
            style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        AlmanacSectionLabel(label: CookbookText.ingredients),
        const SizedBox(height: AppSpacing.sm),
        for (final ingredient in recipe.ingredients)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(ingredient.line, style: textTheme.bodyLarge),
          ),

        const SizedBox(height: AppSpacing.xl),
        AlmanacSectionLabel(label: CookbookText.method),
        const SizedBox(height: AppSpacing.sm),
        for (final step in recipe.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Semantics(
              container: true,
              // "Step 3. Add the pumpkin and the stock." — a step has to
              // make sense on its own, without the number beside it
              // being read as part of the sentence.
              label: step.spoken,
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: AppSpacing.lg,
                    child: Text(
                      '${step.number}',
                      style: textTheme.titleMedium?.copyWith(
                        color: palette.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(step.instruction, style: textTheme.bodyLarge),
                  ),
                ],
              ),
            ),
          ),

        if (recipe.note case final note?) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(child: Text(note, style: textTheme.bodyMedium)),
        ],

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onBack,
            child: const Text(CookbookText.back),
          ),
        ),
      ],
    );
  }
}

/// One short fact about a recipe: a label, a value, and a fuller form for
/// a screen reader.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, required this.spoken});

  final String label;
  final String value;
  final String spoken;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          Text(value, style: textTheme.titleMedium),
        ],
      ),
    );
  }
}
