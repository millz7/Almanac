import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/own_recipes_providers.dart';
import 'cookbook_text.dart';

/// "Your recipes": the ones the user keeps themselves, under the
/// Almanac's own collections.
///
/// Always present, whichever season is being browsed — a recipe
/// somebody wrote down is theirs all year — and never mixed into the
/// seasonal collections above it.
class OwnRecipesSection extends ConsumerWidget {
  const OwnRecipesSection({
    super.key,
    required this.onOpen,
    required this.onAdd,
  });

  final ValueChanged<OwnRecipe> onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final stored = ref.watch(ownRecipesProvider);
    // Nothing until the store has answered, rather than an empty state
    // that flickers into a list.
    if (stored.isLoading) return const SizedBox.shrink();
    final recipes = (stored.value ?? OwnRecipes.empty).newestFirst;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AlmanacSectionDivider(spacing: AppSpacing.lg),
        AlmanacSectionLabel(label: CookbookText.yourRecipes),
        const SizedBox(height: AppSpacing.sm),
        if (recipes.isEmpty) ...[
          Text(CookbookText.noOwnRecipes, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CookbookText.noOwnRecipesNote,
            style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ] else
          for (final (index, recipe) in recipes.indexed) ...[
            if (index > 0) const AlmanacRule(spacing: AppSpacing.xs),
            _OwnRecipeRow(recipe: recipe, onTap: () => onOpen(recipe)),
          ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: CookbookText.addRecipe,
            icon: Icons.add,
            onPressed: onAdd,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          CookbookText.ownPrivacy,
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

/// One of the user's recipes in the list: its name, and how much is
/// written down. A row on the page, not a floating card.
class _OwnRecipeRow extends StatelessWidget {
  const _OwnRecipeRow({required this.recipe, required this.onTap});

  final OwnRecipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Semantics(
      container: true,
      button: true,
      label: CookbookText.ownRecipeLabel(recipe),
      excludeSemantics: true,
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
                      Text(recipe.title, style: textTheme.titleMedium),
                      Text(
                        CookbookText.ownRecipeSummary(recipe),
                        style: textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(
                  child: Icon(
                    Icons.arrow_forward,
                    size: AppIconSize.sm,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One of the user's recipes, laid out the way the Almanac's own are:
/// what goes in, then what to do.
class OwnRecipePage extends StatelessWidget {
  const OwnRecipePage({
    super.key,
    required this.recipe,
    required this.saved,
    required this.onEdit,
    required this.onDelete,
    required this.onBack,
  });

  final OwnRecipe recipe;

  /// Whether it has just been saved, so the page can say so once.
  final bool saved;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (saved) ...[
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(CookbookText.saved, style: textTheme.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        AlmanacSectionLabel(label: CookbookText.ingredients),
        const SizedBox(height: AppSpacing.sm),
        if (recipe.ingredients.isEmpty)
          Text(
            CookbookText.noIngredients,
            style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          )
        else
          for (final ingredient in recipe.ingredients)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(ingredient, style: textTheme.bodyLarge),
            ),

        const SizedBox(height: AppSpacing.xl),
        AlmanacSectionLabel(label: CookbookText.method),
        const SizedBox(height: AppSpacing.sm),
        if (recipe.method.isEmpty)
          Text(
            CookbookText.noMethod,
            style: textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          )
        else
          for (final (index, step) in recipe.method.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Semantics(
                container: true,
                label: 'Step ${index + 1}. $step',
                excludeSemantics: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppSpacing.lg,
                      child: Text(
                        '${index + 1}',
                        style: textTheme.titleMedium?.copyWith(
                          color: palette.primary,
                        ),
                      ),
                    ),
                    Expanded(child: Text(step, style: textTheme.bodyLarge)),
                  ],
                ),
              ),
            ),

        if (recipe.note case final note?) ...[
          const SizedBox(height: AppSpacing.md),
          AlmanacSectionLabel(label: CookbookText.noteLabel),
          const SizedBox(height: AppSpacing.sm),
          Text(note, style: textTheme.bodyMedium),
        ],

        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: CookbookText.editRecipe,
            icon: Icons.edit_outlined,
            onPressed: onEdit,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onDelete,
            child: const Text(CookbookText.deleteRecipe),
          ),
        ),
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

/// What the form hands back when saved.
@immutable
class OwnRecipeDraft {
  const OwnRecipeDraft({
    required this.title,
    required this.ingredients,
    required this.method,
    required this.note,
  });

  final String title;
  final List<String> ingredients;
  final List<String> method;
  final String note;
}

/// Writing a recipe down, or changing one.
///
/// Four plain fields, one item per line. Nothing is required but a
/// name: a recipe that is only a name and a note is still worth keeping.
class OwnRecipeForm extends StatefulWidget {
  const OwnRecipeForm({
    super.key,
    this.existing,
    required this.onSave,
    required this.onCancel,
  });

  /// The recipe being changed, or null for a new one.
  final OwnRecipe? existing;

  final ValueChanged<OwnRecipeDraft> onSave;

  /// Called with whether anything has been changed, so the screen can
  /// ask before throwing words away.
  final ValueChanged<bool> onCancel;

  @override
  State<OwnRecipeForm> createState() => _OwnRecipeFormState();
}

class _OwnRecipeFormState extends State<OwnRecipeForm> {
  late final TextEditingController _title;
  late final TextEditingController _ingredients;
  late final TextEditingController _method;
  late final TextEditingController _note;
  late final String _initial;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _ingredients = TextEditingController(
      text: existing?.ingredients.join('\n') ?? '',
    );
    _method = TextEditingController(text: existing?.method.join('\n') ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _initial = _snapshot;
  }

  @override
  void dispose() {
    _title.dispose();
    _ingredients.dispose();
    _method.dispose();
    _note.dispose();
    super.dispose();
  }

  String get _snapshot =>
      [_title.text, _ingredients.text, _method.text, _note.text].join('\u0000');

  bool get _changed => _snapshot != _initial;

  bool get _canSave => _title.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          style: textTheme.bodyLarge,
          decoration: const InputDecoration(
            labelText: CookbookText.titleLabel,
            hintText: CookbookText.titleHint,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _ingredients,
          minLines: 3,
          maxLines: 12,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: textTheme.bodyLarge,
          decoration: const InputDecoration(
            labelText: CookbookText.ingredientsLabel,
            hintText: CookbookText.ingredientsHint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _method,
          minLines: 3,
          maxLines: 16,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: textTheme.bodyLarge,
          decoration: const InputDecoration(
            labelText: CookbookText.methodLabel,
            hintText: CookbookText.methodHint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          style: textTheme.bodyLarge,
          decoration: const InputDecoration(
            labelText: CookbookText.noteLabel,
            hintText: CookbookText.noteHint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          CookbookText.ownPrivacy,
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),

        const SizedBox(height: AppSpacing.lg),
        // Said, not only implied by a greyed-out button.
        if (!_canSave) ...[
          Text(
            CookbookText.nameNeeded,
            style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: widget.existing == null
                ? CookbookText.saveRecipe
                : CookbookText.saveChanges,
            onPressed: _canSave
                ? () => widget.onSave(
                    OwnRecipeDraft(
                      title: _title.text,
                      ingredients: linesOf(_ingredients.text),
                      method: linesOf(_method.text),
                      note: _note.text,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => widget.onCancel(_changed),
            child: const Text(CookbookText.cancel),
          ),
        ),
      ],
    );
  }
}
