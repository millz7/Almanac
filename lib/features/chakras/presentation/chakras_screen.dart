import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../application/chakra_reflections.dart';
import '../domain/chakras.dart';
import 'widgets/chakra_journey.dart';
import 'widgets/chakra_symbol.dart';

/// Where the user has got to.
enum ChakraStage {
  /// All seven, down the body line.
  journey,

  /// One of them, on its own.
  chakra,

  /// A prompt and somewhere to answer it.
  reflection,
}

/// A quiet visual pause: seven traditional centres, one at a time.
///
/// **What this is careful not to be.** Nothing here is presented as a
/// fact about the body, and nothing is measured, scored, tracked or
/// compared. Every claim in the feature is written as what it is — a
/// traditional association — and there is a test that reads every string
/// the feature can show looking for anything that strays into medical or
/// gamified language.
///
/// **No clock, no session, no immersion.** Unlike Meditation and Yoga
/// there is nothing here that runs: the two animations are one-shot
/// arrivals, so this screen needs neither the immersive infrastructure
/// nor a lifecycle of its own, and the Almanac panel stays reachable
/// throughout.
class ChakrasScreen extends ConsumerStatefulWidget {
  const ChakrasScreen({super.key});

  @override
  ConsumerState<ChakrasScreen> createState() => _ChakrasScreenState();
}

class _ChakrasScreenState extends ConsumerState<ChakrasScreen> {
  ChakraStage _stage = ChakraStage.journey;
  Chakra? _selected;

  void _open(Chakra chakra) => setState(() {
    _selected = chakra;
    _stage = ChakraStage.chakra;
  });

  void _backToJourney() => setState(() {
    _selected = null;
    _stage = ChakraStage.journey;
  });

  void _reflect() => setState(() => _stage = ChakraStage.reflection);

  void _closeReflection() => setState(() => _stage = ChakraStage.chakra);

  void _save(String text) {
    ref.read(chakraReflectionsProvider.notifier).save(_selected!.id, text);
    _closeReflection();
  }

  @override
  Widget build(BuildContext context) {
    final chakra = _selected;

    return AppScaffold(
      title: 'Chakras',
      subtitle: chakra?.name,
      trailing: const AlmanacButton(),
      body: [
        switch (_stage) {
          ChakraStage.journey => _Journey(onChosen: _open),
          ChakraStage.chakra => _ChakraDetail(
            // A new detail screen for each chakra, so its symbol comes
            // into focus rather than the previous one's changing shape.
            key: ValueKey(chakra!.id),
            chakra: chakra,
            reflection: ref.watch(chakraReflectionsProvider)[chakra.id],
            onReflect: _reflect,
            onBack: _backToJourney,
          ),
          ChakraStage.reflection => _Reflection(
            key: ValueKey(chakra!.id),
            chakra: chakra,
            existing: ref.read(chakraReflectionsProvider)[chakra.id],
            onSave: _save,
            onDismiss: _closeReflection,
          ),
        },
      ],
    );
  }
}

/// The seven, and the words that frame them.
class _Journey extends StatelessWidget {
  const _Journey({required this.onChosen});

  final ValueChanged<Chakra> onChosen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ChakraCatalogue.introduction, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.lg),
        ChakraJourney(onChosen: onChosen),
      ],
    );
  }
}

/// One chakra, on its own.
class _ChakraDetail extends StatefulWidget {
  const _ChakraDetail({
    super.key,
    required this.chakra,
    required this.reflection,
    required this.onReflect,
    required this.onBack,
  });

  final Chakra chakra;

  /// What the user wrote here this visit, if anything.
  final String? reflection;

  final VoidCallback onReflect;
  final VoidCallback onBack;

  @override
  State<_ChakraDetail> createState() => _ChakraDetailState();
}

class _ChakraDetailState extends State<_ChakraDetail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focus;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _focus = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // With motion turned off the chakra is simply already in focus.
    if (MediaQuery.disableAnimationsOf(context)) {
      _focus.value = 1;
    } else {
      _focus.forward();
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chakra = widget.chakra;
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _focus,
          builder: (context, _) => ChakraSymbol(
            chakra: chakra,
            focus: Curves.easeOut.transform(_focus.value),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(chakra.name, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          chakra.sanskrit,
          style: textTheme.titleMedium?.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),

        Text(chakra.traditionSentence, style: textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        // The colour in words as well as in paint, and its place on the
        // body said rather than only drawn.
        Text(
          'Traditionally placed at ${chakra.place}, and shown '
          'as ${chakra.hue.label}.',
          style: textTheme.bodyMedium,
        ),

        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A reflective prompt', style: textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(chakra.prompt, style: textTheme.titleMedium),
            ],
          ),
        ),

        if (widget.reflection case final written?) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: palette.surfaceElevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What you wrote', style: textTheme.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(written, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(label: 'Reflect', onPressed: widget.onReflect),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: widget.onBack,
            child: const Text('Back to the seven'),
          ),
        ),
      ],
    );
  }
}

/// The prompt, and somewhere to answer it. Or not.
class _Reflection extends StatefulWidget {
  const _Reflection({
    super.key,
    required this.chakra,
    required this.existing,
    required this.onSave,
    required this.onDismiss,
  });

  final Chakra chakra;
  final String? existing;
  final ValueChanged<String> onSave;
  final VoidCallback onDismiss;

  @override
  State<_Reflection> createState() => _ReflectionState();
}

class _ReflectionState extends State<_Reflection> {
  late final TextEditingController _text;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.existing ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.chakra.name, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Text(widget.chakra.prompt, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.lg),

        TextField(
          controller: _text,
          // Room for a few lines, growing to a few more, rather than a
          // single-line box that makes writing feel like filling in a
          // form.
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          style: textTheme.bodyLarge,
          // The app's default field styling, as used by the name
          // question in setup, rather than a box of its own.
          decoration: const InputDecoration(
            labelText: 'Your reflection',
            hintText: 'Write anything that comes to mind.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          ChakraCatalogue.reflectionNote,
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: 'Save reflection',
            onPressed: () => widget.onSave(_text.text),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: widget.onDismiss,
            child: const Text('Not now'),
          ),
        ),
      ],
    );
  }
}
