import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/context/cycle_phase_context.dart';
import '../../../core/context/almanac_context.dart';
import '../domain/cycle_recipes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/recipe_catalogue.dart';
import 'cookbook_text.dart';
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
/// Read-only, and it stores nothing: no favourites, no history, no note
/// of what was looked at.
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

  /// The recipe being read, or null for the collection.
  Recipe? _open;

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
      return;
    }

    final intent = ref.read(almanacIntentProvider);
    if (intent is! CycleCookbookIntent) return;

    _arrivedForPhase = intent.phase;
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

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentSeasonProvider);
    final season = _browsing ?? current;
    final recipe = _open;

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

    // What the cycle collection is for: the phase they arrived with, or
    // — on a direct entry — whatever phase Cycle currently shows.
    // Null when Cycle is not part of their Almanac or has nothing to
    // say, and then there is simply no cycle collection.
    final cyclePhase = ref.watch(almanacCyclePhaseProvider(_arrivedForPhase));

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
        _Collection(
          season: season,
          growth: _growth,
          onOpen: (recipe) => setState(() => _open = recipe),
        ),
        // And, underneath it, a small collection for the time of month.
        if (cyclePhase case final phase?)
          _CycleCollection(
            phase: phase,
            arrived: _arrivedForPhase != null,
            growth: _growth,
            onOpen: (recipe) => setState(() => _open = recipe),
          ),
      ],
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
