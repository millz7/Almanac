import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/almanac_button.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/time/date_words.dart';
import '../../../core/widgets/widgets.dart';
import '../application/journal_providers.dart';
import 'journal_text.dart';

/// Which page of the Journal is open.
sealed class _View {
  const _View();
}

/// Today's page — the only one that can be written on.
final class _TodayView extends _View {
  const _TodayView();
}

/// A saved page from another day, to read.
final class _EntryView extends _View {
  const _EntryView(this.date);

  final CalendarDate date;
}

/// Every saved page, by month.
final class _ContentsView extends _View {
  const _ContentsView();
}

/// A private page for each day the user chooses to write.
///
/// **Only today can be written.** The page opens on today, and the date
/// comes from the app's one idea of today — there is no date picker, and
/// no way to write on a page from another day. A past page is read-only.
///
/// **Only pages that were written exist.** Opening, reading, leaving and
/// flipping write nothing; a page is stored the first time something is
/// saved on it. Previous and Next move only between saved pages — never
/// through blank days — and forward from the newest saved page is today.
///
/// **The midnight rule.** Today's page keeps the date it was opened
/// with — see `JournalDraft`. Somebody writing across midnight saves on
/// the day they began; once they leave the page, today's page is the new
/// day's.
///
/// **Private.** Nothing here is sent anywhere, shown anywhere else in the
/// app, or written to a log.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  _View _view = const _TodayView();

  /// Today's page, once opened. Cleared on leaving it, so the next visit
  /// opens whatever day it then is.
  JournalDraft? _draft;

  final TextEditingController _text = TextEditingController();

  /// Set while a save or a removal is being written, so a second tap
  /// cannot do it twice.
  bool _busy = false;
  bool _saved = false;
  bool _saveFailed = false;
  bool _removeFailed = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  JournalController get _journal => ref.read(journalProvider.notifier);

  JournalBook get _book => ref.read(journalProvider).value ?? JournalBook.empty;

  /// What is stored on today's page, or nothing.
  String get _savedText =>
      _draft == null ? '' : _book.find(_draft!.date)?.text ?? '';

  /// Whether today's page holds words that are not yet saved. Spaces on
  /// a blank page are not words: there is nothing there to lose.
  bool get _dirty {
    if (_draft == null || _text.text == _savedText) return false;
    return _savedText.isNotEmpty || _text.text.trim().isNotEmpty;
  }

  /// Opens today's page, if it is not already open, with whatever is
  /// saved on it. Reads; never writes.
  void _ensureDraft(JournalBook book) {
    if (_draft != null) return;
    final draft = _journal.openToday();
    _draft = draft;
    _text.text = book.find(draft.date)?.text ?? '';
  }

  void _clearFlags() {
    _saved = false;
    _saveFailed = false;
    _removeFailed = false;
  }

  /// Goes to [target], asking first if today's page holds unsaved words.
  /// Every way off today's page — Previous, Contents, system Back —
  /// comes through here, so there is one rule and one question.
  Future<void> _go(_View target) async {
    if (_dirty && !await UnsavedChanges.confirmLeave(context)) return;
    if (!mounted) return;
    setState(() {
      _clearFlags();
      if (target is! _TodayView) {
        // Leaving today's page: the next visit opens the day it then is.
        _draft = null;
        _text.clear();
      }
      _view = target;
    });
  }

  /// System Back and the page's own Back: one level up, which is today.
  Future<void> _back() async {
    if (_view is _TodayView) {
      // Only reached with unsaved words (otherwise Back leaves the
      // Journal). Asked first; choosing Leave puts the page back as it
      // was saved, and the next Back leaves.
      if (!await UnsavedChanges.confirmLeave(context)) return;
      if (!mounted) return;
      setState(() {
        _clearFlags();
        _text.text = _savedText;
      });
      return;
    }
    await _go(const _TodayView());
  }

  Future<void> _save() async {
    final draft = _draft;
    if (_busy || draft == null || _text.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _clearFlags();
    });
    try {
      await _journal.save(draft, _text.text);
      if (mounted) setState(() => _saved = true);
    } on Object {
      // The words stay exactly where they are, so Save can be tried
      // again. Nothing about them is logged.
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(CalendarDate date) async {
    if (_busy) return;
    final confirmed = await Confirm.ask(
      context,
      title: JournalText.removeTitle,
      body: JournalText.removeBody,
      yes: JournalText.removeYes,
      no: JournalText.removeNo,
    );
    if (!confirmed || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _clearFlags();
    });
    try {
      await _journal.remove(date);
      if (!mounted) return;
      setState(() {
        if (_view is _TodayView) {
          _text.clear();
        } else {
          _view = const _TodayView();
        }
      });
    } on Object {
      if (mounted) setState(() => _removeFailed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens a saved page — today's own opens as today's page.
  void _openEntry(CalendarDate date) {
    final today = _draft?.date ?? ref.read(todayProvider);
    _go(date == today ? const _TodayView() : _EntryView(date));
  }

  /// Forward from a past page: the next saved page, or today.
  void _forwardFrom(CalendarDate date, JournalBook book) {
    final next = book.nextAfter(date);
    final today = ref.read(todayProvider);
    if (next == null || !next.date.isBefore(today)) {
      _go(const _TodayView());
    } else {
      _go(_EntryView(next.date));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Past midnight with nothing unsaved: today's page becomes the new
    // day's. With unsaved words it stays on the day it was opened — the
    // midnight rule.
    ref.listen(todayProvider, (previous, next) {
      if (_view is _TodayView && _draft != null && !_dirty) {
        setState(() {
          _draft = null;
          _clearFlags();
        });
      }
    });

    final journal = ref.watch(journalProvider);
    final book = journal.value;

    return InnerBack(
      atTop: _view is _TodayView && !_dirty,
      onBack: _back,
      child: AppScaffold(
        title: JournalText.title,
        trailing: const AlmanacButton(),
        body: [
          if (book == null)
            // Still reading, or unreadable: nothing to write on yet, so
            // nothing can be saved over what is stored.
            const SizedBox.shrink()
          else ...[
            if (_view is! _TodayView)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => _go(const _TodayView()),
                  child: const Text(JournalText.backToToday),
                ),
              ),
            ...switch (_view) {
              _TodayView() => _today(context, book),
              _EntryView(:final date) => _entry(context, book, date),
              _ContentsView() => _contents(context, book),
            },
          ],
        ],
      ),
    );
  }

  List<Widget> _today(BuildContext context, JournalBook book) {
    _ensureDraft(book);
    final draft = _draft!;
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final today = ref.watch(todayProvider);
    final saved = book.find(draft.date);
    // A saved page shows what it recorded; an unsaved one what it would.
    final JournalContext pageContext = switch (saved) {
      final page? => page.context,
      null when today == draft.date => ref.watch(journalContextProvider),
      null => draft.context,
    };
    final canSave = !_busy && _dirty && _text.text.trim().isNotEmpty;

    return [
      _Header(
        date: draft.date,
        context: pageContext,
        eyebrow: JournalText.today,
      ),
      const SizedBox(height: AppSpacing.lg),
      if (today != draft.date) ...[
        Text(JournalText.midnight, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
      ],
      Semantics(
        label: JournalText.spokenField(draft.date),
        child: TextField(
          controller: _text,
          minLines: 8,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(_clearFlags),
          decoration: const InputDecoration(
            labelText: JournalText.fieldLabel,
            hintText: JournalText.fieldHint,
            alignLabelWithHint: true,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PrimaryButton(
            label: JournalText.save,
            onPressed: canSave ? _save : null,
          ),
          if (saved != null)
            TextButton(
              onPressed: _busy ? null : () => _remove(draft.date),
              child: const Text(JournalText.remove),
            ),
        ],
      ),
      if (_saved) ...[
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          liveRegion: true,
          child: Text(JournalText.saved, style: textTheme.bodySmall),
        ),
      ],
      if (_saveFailed || _removeFailed) ...[
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          liveRegion: true,
          child: Text(
            _saveFailed ? JournalText.saveFailed : JournalText.removeFailed,
            style: textTheme.bodySmall?.copyWith(color: palette.error),
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      _PageTurns(
        onPrevious: switch (book.previousBefore(draft.date)) {
          final previous? => () => _openEntry(previous.date),
          null => null,
        },
        // Today is the last page: there is nothing ahead of it.
        onNext: null,
        onContents: () => _go(const _ContentsView()),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        JournalText.private,
        style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
      ),
    ];
  }

  List<Widget> _entry(
    BuildContext context,
    JournalBook book,
    CalendarDate date,
  ) {
    final entry = book.find(date);
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    if (entry == null) {
      // Removed from under the page, which cannot normally happen; show
      // the contents rather than a blank page.
      return _contents(context, book);
    }

    return [
      Semantics(
        container: true,
        readOnly: true,
        label: JournalText.spokenReadOnly(entry),
        excludeSemantics: true,
        child: _Header(date: date, context: entry.context),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        JournalText.readOnly,
        style: textTheme.bodySmall?.copyWith(color: palette.textSecondary),
      ),
      const SizedBox(height: AppSpacing.lg),
      Semantics(
        readOnly: true,
        child: Text(entry.text, style: textTheme.bodyLarge),
      ),
      const SizedBox(height: AppSpacing.lg),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _busy ? null : () => _remove(date),
          child: const Text(JournalText.remove),
        ),
      ),
      if (_removeFailed)
        Semantics(
          liveRegion: true,
          child: Text(
            JournalText.removeFailed,
            style: textTheme.bodySmall?.copyWith(color: palette.error),
          ),
        ),
      const SizedBox(height: AppSpacing.md),
      _PageTurns(
        onPrevious: switch (book.previousBefore(date)) {
          final previous? => () => _openEntry(previous.date),
          null => null,
        },
        // Forward from any past page: the next saved one, or today.
        onNext: () => _forwardFrom(date, book),
        onContents: () => _go(const _ContentsView()),
      ),
    ];
  }

  List<Widget> _contents(BuildContext context, JournalBook book) {
    final textTheme = Theme.of(context).textTheme;
    if (book.isEmpty) {
      return [
        Semantics(
          header: true,
          child: Text(JournalText.contents, style: textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(JournalText.contentsEmpty, style: textTheme.bodyMedium),
      ];
    }
    return [
      Semantics(
        header: true,
        child: Text(JournalText.contents, style: textTheme.headlineSmall),
      ),
      for (final group in book.byMonth) ...[
        const SizedBox(height: AppSpacing.lg),
        AlmanacSectionLabel(label: formatMonth(group.month)),
        const SizedBox(height: AppSpacing.xs),
        for (final entry in group.entries)
          _ContentsRow(entry: entry, onTap: () => _openEntry(entry.date)),
      ],
    ];
  }
}

/// A page's date and what surrounded it.
class _Header extends StatelessWidget {
  const _Header({required this.date, required this.context, this.eyebrow});

  final CalendarDate date;
  final JournalContext context;
  final String? eyebrow;

  @override
  Widget build(BuildContext buildContext) {
    final palette = buildContext.palette;
    final textTheme = Theme.of(buildContext).textTheme;
    final quiet = textTheme.bodyMedium?.copyWith(color: palette.textSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) Text(eyebrow!, style: textTheme.eyebrow),
        Semantics(
          header: true,
          child: Text(
            JournalText.longDate(date),
            style: textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(JournalText.moon(context), style: quiet),
        if (context.festivalName case final festival?)
          Text(festival, style: quiet),
        if (context.maramatakaName != null)
          Text(JournalText.maramataka(context), style: quiet),
      ],
    );
  }
}

/// Previous, Contents and Next — each a full-size target.
class _PageTurns extends StatelessWidget {
  const _PageTurns({
    required this.onPrevious,
    required this.onNext,
    required this.onContents,
  });

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onContents;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onPrevious,
        tooltip: JournalText.previous,
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Center(
          child: TextButton(
            onPressed: onContents,
            child: const Text(JournalText.contents),
          ),
        ),
      ),
      IconButton(
        onPressed: onNext,
        tooltip: JournalText.next,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

/// One saved page in the contents: its full date, its Moon and any
/// festival, read as one sentence.
class _ContentsRow extends StatelessWidget {
  const _ContentsRow({required this.entry, required this.onTap});

  final JournalEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final quiet = textTheme.bodySmall?.copyWith(color: palette.textSecondary);

    return Semantics(
      button: true,
      label: JournalText.spokenRow(entry),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimens.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  JournalText.longDate(entry.date),
                  style: textTheme.bodyLarge,
                ),
                Text(JournalText.moon(entry.context), style: quiet),
                if (entry.context.festivalName case final festival?)
                  Text(festival, style: quiet),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
