import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/environment/environment_providers.dart';
import '../../../core/time/date_words.dart';
import '../../../core/widgets/widgets.dart';
import '../application/nature_log_providers.dart';
import 'nature_log_text.dart';
import 'widgets/nature_mark.dart';

/// Where in the Nature Log the user is.
///
/// A stack, so going back from an entry returns to the page it was
/// opened from — the book can be reached from two directions.
sealed class NatureLogPage {
  const NatureLogPage();
}

/// The two routes and the way in.
final class NatureLogLanding extends NatureLogPage {
  const NatureLogLanding();
}

/// What the guide suggests noticing.
final class NatureAroundNowPage extends NatureLogPage {
  const NatureAroundNowPage();
}

/// The whole Nature Book, for choosing something to record.
final class NatureBookPage extends NatureLogPage {
  const NatureBookPage({this.forRecording = false});

  /// Whether the user came here to record rather than to read.
  final bool forRecording;
}

/// One entry's page.
final class NatureItemPage extends NatureLogPage {
  const NatureItemPage(this.itemId);

  final String itemId;
}

/// The form for something the user describes themselves.
final class NatureCustomPage extends NatureLogPage {
  const NatureCustomPage();
}

/// The form for recording a book entry.
final class NatureRecordPage extends NatureLogPage {
  const NatureRecordPage(this.itemId);

  final String itemId;
}

/// Everything the user has noticed.
final class NatureObservationsPage extends NatureLogPage {
  const NatureObservationsPage();
}

/// One observation, to read or change.
final class NatureObservationPage extends NatureLogPage {
  const NatureObservationPage(this.instanceId);

  final String instanceId;
}

/// A quiet record of the natural world around you.
///
/// **Two halves that never blur.** *Around now* is the guide: what the
/// Nature Book says may be worth noticing this month, where the book has
/// coverage. *My observations* is what the user actually saw. A
/// suggestion is never treated as a sighting, and nothing is ever
/// inferred from location.
///
/// **The app does not identify anything.** Something the user describes
/// themselves is kept exactly as they wrote it.
///
/// Nothing here calculates a season, a hemisphere or a date of its own,
/// and opening the screen never asks for a permission.
class NatureLogScreen extends ConsumerStatefulWidget {
  const NatureLogScreen({super.key});

  @override
  ConsumerState<NatureLogScreen> createState() => _NatureLogScreenState();
}

class _NatureLogScreenState extends ConsumerState<NatureLogScreen>
    with SingleTickerProviderStateMixin {
  final List<NatureLogPage> _stack = [const NatureLogLanding()];

  late final AnimationController _settle;
  bool _started = false;
  bool _saveFailed = false;

  /// Set once after saving, so the page can say so quietly.
  bool _acknowledged = false;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Reduced motion draws the final state at once. Nature moves; the
    // interface does not.
    if (MediaQuery.disableAnimationsOf(context)) {
      _settle.value = 1;
    } else {
      _settle.forward();
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  NatureLogPage get _page => _stack.last;

  void _open(NatureLogPage page) => setState(() {
    _stack.add(page);
    _acknowledged = false;
    _saveFailed = false;
  });

  void _back() => setState(() {
    if (_stack.length > 1) _stack.removeLast();
    _acknowledged = false;
    _saveFailed = false;
  });

  void _toLanding() => setState(() {
    _stack
      ..clear()
      ..add(const NatureLogLanding());
    _acknowledged = false;
    _saveFailed = false;
  });

  NatureLogController get _log => ref.read(natureLogProvider.notifier);

  Future<void> _saving(Future<void> Function() change) async {
    try {
      await change();
      if (mounted) setState(() => _saveFailed = false);
    } on Object {
      if (mounted) setState(() => _saveFailed = true);
    }
  }

  /// Saves a new observation and returns to the log, where it will
  /// already be at the top.
  Future<void> _save(Future<void> Function() record) async {
    await _saving(record);
    if (!mounted) return;
    setState(() {
      _stack
        ..clear()
        ..addAll([const NatureLogLanding(), const NatureObservationsPage()]);
      _acknowledged = true;
    });
  }

  Future<bool> _confirm({required String title, required String body}) async {
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(NatureLogText.remove),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(NatureLogText.keep),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  Future<void> _remove(NatureObservation observation) async {
    final confirmed = await _confirm(
      title: NatureLogText.removeTitle,
      body: NatureLogText.removeBody,
    );
    if (!confirmed) return;
    await _saving(() => _log.remove(observation.instanceId));
    if (mounted) _back();
  }

  Future<void> _clear() async {
    final confirmed = await _confirm(
      title: NatureLogText.clearTitle,
      body: NatureLogText.clearBody,
    );
    if (!confirmed) return;
    await _saving(_log.clear);
  }

  /// Asks for a date, offering nothing later than today: nothing can
  /// have been noticed on a day that has not happened.
  Future<CalendarDate?> _askForDate(CalendarDate initial) async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.toLocalDateTime(),
      firstDate: DateTime(today.year - 3),
      lastDate: today.toLocalDateTime(),
      helpText: NatureLogText.dateLabel,
    );
    return picked == null ? null : CalendarDate.from(picked);
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final today = ref.watch(todayProvider);
    final season = ref.watch(currentSeasonProvider);
    final guide = ref.watch(natureGuideProvider);

    return AppScaffold(
      title: switch (page) {
        NatureLogLanding() => NatureLogText.title,
        NatureAroundNowPage() => NatureLogText.aroundNow,
        NatureBookPage() => NatureLogText.chooseFromBook,
        NatureItemPage(:final itemId) =>
          NatureBook.tryFind(itemId)?.primaryName ?? NatureLogText.title,
        NatureCustomPage() => NatureLogText.writeYourOwn,
        NatureRecordPage() => NatureLogText.recordAnObservation,
        NatureObservationsPage() => NatureLogText.myObservations,
        NatureObservationPage() => NatureLogText.myObservations,
      },
      subtitle: switch (page) {
        NatureLogLanding() => NatureLogText.context(today.month, season),
        NatureAroundNowPage() => NatureLogText.guideLine(guide, season),
        NatureItemPage(:final itemId) => NatureBook.tryFind(
          itemId,
        )?.category.label,
        _ => null,
      },
      trailing: const AlmanacButton(),
      body: [
        // Above the content: a page here can be a long list, and a way
        // back at the far end of one is a way back nobody reaches.
        if (page is! NatureLogLanding)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _stack.length > 2 ? _back : _toLanding,
              child: const Text(NatureLogText.back),
            ),
          ),

        switch (page) {
          NatureLogLanding() => _Landing(
            onAroundNow: () => _open(const NatureAroundNowPage()),
            onObservations: () => _open(const NatureObservationsPage()),
            onRecord: () => _open(const NatureBookPage(forRecording: true)),
          ),

          NatureAroundNowPage() => _AroundNowList(
            settle: _settle,
            onOpenItem: (item) => _open(NatureItemPage(item.id)),
          ),

          NatureBookPage(:final forRecording) => _BookList(
            settle: _settle,
            forRecording: forRecording,
            onOpenItem: (item) => _open(
              forRecording
                  ? NatureRecordPage(item.id)
                  : NatureItemPage(item.id),
            ),
            onWriteYourOwn: () => _open(const NatureCustomPage()),
          ),

          NatureItemPage(:final itemId) => _ItemPage(
            item: NatureBook.byId(itemId),
            settle: _settle,
            onRecord: () => _open(NatureRecordPage(itemId)),
          ),

          NatureRecordPage(:final itemId) => _ObservationForm(
            key: ValueKey('record-$itemId'),
            item: NatureBook.byId(itemId),
            today: today,
            onAskForDate: _askForDate,
            onSave: (draft) => _save(
              () => _log.recordFromBook(
                item: NatureBook.byId(itemId),
                on: draft.date,
                note: draft.note,
                placeLabel: draft.place,
              ),
            ),
          ),

          NatureCustomPage() => _ObservationForm(
            key: const ValueKey('record-custom'),
            today: today,
            onAskForDate: _askForDate,
            onSave: (draft) => _save(
              () => _log.recordCustom(
                name: draft.name!,
                category: draft.category!,
                on: draft.date,
                note: draft.note,
                placeLabel: draft.place,
              ),
            ),
          ),

          NatureObservationsPage() => _ObservationsList(
            settle: _settle,
            acknowledged: _acknowledged,
            onOpen: (observation) =>
                _open(NatureObservationPage(observation.instanceId)),
            onRecord: () => _open(const NatureBookPage(forRecording: true)),
            onClear: _clear,
          ),

          NatureObservationPage(:final instanceId) => _ObservationDetail(
            key: ValueKey('edit-$instanceId'),
            instanceId: instanceId,
            settle: _settle,
            onAskForDate: _askForDate,
            onSave: (draft) => _saving(
              () => _log.edit(
                instanceId,
                date: draft.date,
                category: draft.category,
                label: draft.name,
                note: draft.note,
                placeLabel: draft.place,
              ),
            ),
            onRemove: _remove,
          ),
        },

        if (_saveFailed)
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              NatureLogText.saveFailed,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: context.palette.error),
            ),
          ),
      ],
    );
  }
}

/// The two routes, and the way in.
class _Landing extends ConsumerWidget {
  const _Landing({
    required this.onAroundNow,
    required this.onObservations,
    required this.onRecord,
  });

  final VoidCallback onAroundNow;
  final VoidCallback onObservations;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final guide = ref.watch(natureGuideProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RouteCard(
          title: NatureLogText.aroundNow,
          description: NatureLogText.aroundNowDescription,
          onTap: onAroundNow,
        ),
        const SizedBox(height: AppSpacing.md),
        _RouteCard(
          title: NatureLogText.myObservations,
          description: NatureLogText.myObservationsDescription,
          onTap: onObservations,
        ),

        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: NatureLogText.recordSomething,
            onPressed: onRecord,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        Text(
          guide.isSupported ? guide.coverage.label : NatureLogText.noGuideHere,
          style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
        ),
        if (guide.isUnconfirmed) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            NatureLogText.unconfirmedGuide,
            style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
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

/// What the guide suggests, grouped by category with empty groups left
/// out entirely.
class _AroundNowList extends ConsumerWidget {
  const _AroundNowList({required this.settle, required this.onOpenItem});

  final Animation<double> settle;
  final ValueChanged<NatureItem> onOpenItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final around = ref.watch(aroundNowProvider);

    if (!around.guide.isSupported) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(NatureLogText.noGuideHere, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(NatureLogText.noGuideNote, style: textTheme.bodyMedium),
        ],
      );
    }

    if (around.isEmpty) {
      return Text(NatureLogText.nothingAroundNow, style: textTheme.bodyLarge);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (around.guide.isUnconfirmed) ...[
          Text(
            NatureLogText.unconfirmedGuide,
            style: textTheme.bodySmall?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final category in NatureCategory.values)
          if (around.ofCategory(category) case final found
              when found.isNotEmpty) ...[
            SectionHeader(title: category.plural),
            const SizedBox(height: AppSpacing.sm),
            if (category == NatureCategory.fungi) ...[
              Text(NatureLogText.fungiNote, style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final suggestion in found)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ItemTile(
                  item: suggestion.item,
                  line: suggestion.note.text,
                  spoken: suggestion.spokenLabel,
                  settle: settle,
                  onTap: () => onOpenItem(suggestion.item),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// The whole book, for reading or for choosing something to record.
class _BookList extends StatelessWidget {
  const _BookList({
    required this.settle,
    required this.forRecording,
    required this.onOpenItem,
    required this.onWriteYourOwn,
  });

  final Animation<double> settle;
  final bool forRecording;
  final ValueChanged<NatureItem> onOpenItem;
  final VoidCallback onWriteYourOwn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (forRecording) ...[
          Text(NatureLogText.whatDidYouNotice, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          // The other half of the answer: not everything worth noticing
          // is in a book.
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: NatureLogText.writeYourOwn,
              onPressed: onWriteYourOwn,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        for (final category in NatureCategory.values)
          if (NatureBook.ofCategory(category) case final items
              when items.isNotEmpty) ...[
            SectionHeader(title: category.plural),
            const SizedBox(height: AppSpacing.sm),
            if (category == NatureCategory.fungi) ...[
              Text(NatureLogText.fungiNote, style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
            ],
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ItemTile(
                  item: item,
                  settle: settle,
                  onTap: () => onOpenItem(item),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// One book entry in a list.
class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.settle,
    required this.onTap,
    this.line,
    this.spoken,
  });

  final NatureItem item;
  final Animation<double> settle;
  final VoidCallback onTap;

  /// An extra line, e.g. the seasonal note that put it here.
  final String? line;

  /// What a screen reader hears, when it differs from the name alone.
  final String? spoken;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    return Semantics(
      container: true,
      button: true,
      label: spoken ?? item.spokenName,
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: settle,
              builder: (context, _) =>
                  NatureItemMark(item: item, growth: settle.value),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.primaryName, style: textTheme.titleMedium),
                  if (item.alternateName case final other?)
                    Text(
                      other,
                      style: textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    line ?? item.category.label,
                    style: textTheme.bodyMedium,
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

/// One entry's page: what it is, what to listen or look for, and a way
/// to record having seen it.
class _ItemPage extends ConsumerWidget {
  const _ItemPage({
    required this.item,
    required this.settle,
    required this.onRecord,
  });

  final NatureItem item;
  final Animation<double> settle;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final month = ref.watch(todayProvider).month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: AnimatedBuilder(
            animation: settle,
            builder: (context, _) => NatureItemMark(
              item: item,
              growth: settle.value,
              size: kLargeNatureMarkSize,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (item.alternateName case final other?)
          Text(other, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(item.description, style: textTheme.bodyLarge),

        if (item.category == NatureCategory.fungi) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(NatureLogText.fungiNote, style: textTheme.bodySmall),
        ],

        if (item.notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: NatureLogText.aroundNow),
          const SizedBox(height: AppSpacing.sm),
          for (final note in item.notes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _months(note.window),
                    style: textTheme.labelMedium?.copyWith(
                      color: note.isRelevantIn(month)
                          ? palette.primary
                          : palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(note.text, style: textTheme.bodyLarge),
                ],
              ),
            ),
        ],

        if (item.scientificName case final latin?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            latin,
            style: textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: palette.textSecondary,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: NatureLogText.recordAnObservation,
            onPressed: onRecord,
          ),
        ),
      ],
    );
  }

  /// "September to November", or "June".
  static String _months(MonthWindow window) => window.from == window.to
      ? monthName(window.from)
      : '${monthName(window.from)} to ${monthName(window.to)}';
}

/// What a form has collected.
class _Draft {
  const _Draft({
    required this.date,
    this.name,
    this.category,
    this.note,
    this.place,
  });

  final CalendarDate date;
  final String? name;
  final NatureCategory? category;
  final String? note;
  final String? place;
}

/// The one form, used for recording a book entry, writing your own, and
/// changing something already recorded.
class _ObservationForm extends StatefulWidget {
  const _ObservationForm({
    super.key,
    required this.today,
    required this.onAskForDate,
    required this.onSave,
    this.item,
    this.existing,
  });

  /// The book entry being recorded, if it came from the book.
  final NatureItem? item;

  /// The observation being changed, if this is an edit.
  final NatureObservation? existing;

  final CalendarDate today;
  final Future<CalendarDate?> Function(CalendarDate) onAskForDate;
  final ValueChanged<_Draft> onSave;

  @override
  State<_ObservationForm> createState() => _ObservationFormState();
}

class _ObservationFormState extends State<_ObservationForm> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late final TextEditingController _place;
  late CalendarDate _date;
  late NatureCategory _category;

  /// Whether the name is the user's to write. A book entry's name is
  /// not: it is what the book calls it.
  bool get _namesItself => widget.item == null && !_isFromBook;

  bool get _isFromBook => widget.existing?.isFromBook ?? false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _name = TextEditingController(text: existing?.label ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _place = TextEditingController(text: existing?.placeLabel ?? '');
    _date = existing?.date ?? widget.today;
    _category =
        existing?.category ?? widget.item?.category ?? NatureCategory.other;
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _place.dispose();
    super.dispose();
  }

  bool get _canSave => !_namesItself || _name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final item = widget.item;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item != null) ...[
          Text(item.displayName, style: textTheme.headlineSmall),
          Text(
            item.category.label,
            style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (_namesItself) ...[
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            style: textTheme.bodyLarge,
            decoration: const InputDecoration(
              labelText: NatureLogText.nameLabel,
              hintText: NatureLogText.nameHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(NatureLogText.categoryLabel, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final category in NatureCategory.values)
                _CategoryChip(
                  category: category,
                  selected: category == _category,
                  onTap: () => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        Text(NatureLogText.dateLabel, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Text(formatDate(_date), style: textTheme.bodyLarge),
            ),
            TextButton(
              onPressed: () async {
                final picked = await widget.onAskForDate(_date);
                if (picked != null && mounted) setState(() => _date = picked);
              },
              child: const Text(NatureLogText.changeDate),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          style: textTheme.bodyLarge,
          decoration: const InputDecoration(
            labelText: NatureLogText.noteLabel,
            hintText: NatureLogText.noteHint,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        TextField(
          controller: _place,
          textCapitalization: TextCapitalization.sentences,
          style: textTheme.bodyLarge,
          decoration: const InputDecoration(
            labelText: NatureLogText.placeLabel,
            hintText: NatureLogText.placeHint,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Said where it matters: the place is a phrase, not a position.
        Text(NatureLogText.privacyNote, style: textTheme.bodySmall),

        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: widget.existing == null
                ? NatureLogText.saveObservation
                : NatureLogText.saveChanges,
            onPressed: _canSave
                ? () => widget.onSave(
                    _Draft(
                      date: _date,
                      name: _namesItself ? _name.text : null,
                      category: _namesItself ? _category : null,
                      note: _note.text,
                      place: _place.text,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final NatureCategory category;
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
      label: category.label,
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
                  Text(category.label, style: textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Everything noticed, most recent first, gathered under its day.
class _ObservationsList extends ConsumerWidget {
  const _ObservationsList({
    required this.settle,
    required this.acknowledged,
    required this.onOpen,
    required this.onRecord,
    required this.onClear,
  });

  final Animation<double> settle;
  final bool acknowledged;
  final ValueChanged<NatureObservation> onOpen;
  final VoidCallback onRecord;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final log = ref.watch(natureLogProvider);
    if (log.isLoading) return const SizedBox.shrink();

    final observations = (log.value ?? NatureLog.empty).recent;

    if (observations.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(NatureLogText.logEmpty, style: textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(NatureLogText.logEmptyNote, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: NatureLogText.recordSomething,
              onPressed: onRecord,
            ),
          ),
        ],
      );
    }

    final season = ref.watch(currentSeasonProvider);
    final environment = ref.watch(naturalEnvironmentProvider).value;
    final summary = environment == null
        ? null
        : NatureLogText.seasonSummary(
            (log.value ?? NatureLog.empty).countBetween(
              CalendarDate.from(environment.season.startedAt.toLocal()),
              ref.watch(todayProvider),
            ),
            season,
          );

    // Grouped before the list is built rather than while it is being
    // built: a running value updated inside a `Builder` is not set yet
    // when the next child is created, so every observation would get a
    // heading of its own.
    final days = <String, List<NatureObservation>>{};
    for (final observation in observations) {
      days
          .putIfAbsent(NatureLogText.dateHeading(observation.date), () => [])
          .add(observation);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (acknowledged) ...[
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(NatureLogText.added, style: textTheme.bodyMedium),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        for (final (index, day) in days.entries.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          SectionHeader(title: day.key),
          const SizedBox(height: AppSpacing.sm),
          for (final observation in day.value)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ObservationTile(
                observation: observation,
                settle: settle,
                onTap: () => onOpen(observation),
              ),
            ),
        ],

        const SizedBox(height: AppSpacing.lg),
        if (summary != null) ...[
          Text(summary, style: textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: PrimaryButton(
            label: NatureLogText.recordSomething,
            onPressed: onRecord,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onClear,
            child: const Text(NatureLogText.clearAll),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(NatureLogText.privacyNote, style: textTheme.bodySmall),
      ],
    );
  }
}

/// One observation in the log. A free-text one and a book one look
/// exactly the same, because they are worth the same.
class _ObservationTile extends StatelessWidget {
  const _ObservationTile({
    required this.observation,
    required this.settle,
    required this.onTap,
  });

  final NatureObservation observation;
  final Animation<double> settle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final item = observation.item;

    return Semantics(
      container: true,
      button: true,
      label: NatureLogText.observationLabel(observation),
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: settle,
              builder: (context, _) => item == null
                  ? NatureMark(form: NatureMarkForm.other, growth: settle.value)
                  : NatureItemMark(item: item, growth: settle.value),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(observation.label, style: textTheme.titleMedium),
                  Text(
                    observation.category.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  if (observation.note case final note?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(note, style: textTheme.bodyMedium),
                  ],
                  if (observation.placeLabel case final place?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      place,
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

/// One observation, to change or remove.
class _ObservationDetail extends ConsumerWidget {
  const _ObservationDetail({
    super.key,
    required this.instanceId,
    required this.settle,
    required this.onAskForDate,
    required this.onSave,
    required this.onRemove,
  });

  final String instanceId;
  final Animation<double> settle;
  final Future<CalendarDate?> Function(CalendarDate) onAskForDate;
  final ValueChanged<_Draft> onSave;
  final ValueChanged<NatureObservation> onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final observation = ref.watch(natureLogProvider).value?.find(instanceId);
    if (observation == null) return const SizedBox.shrink();

    final item = observation.item;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ObservationForm(
          today: ref.watch(todayProvider),
          item: item,
          existing: observation,
          onAskForDate: onAskForDate,
          onSave: onSave,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => onRemove(observation),
            child: const Text(NatureLogText.remove),
          ),
        ),
      ],
    );
  }
}
