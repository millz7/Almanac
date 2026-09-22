import 'package:almanac/core/environment/tide.dart';
import 'package:almanac/features/nature_log/domain/tide_nature_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cueFor', () {
    test('near low suggests more shoreline to explore', () {
      expect(
        TideNatureNotes.cueFor(TideDirection.nearLow),
        TideNatureCue.lowShoreline,
      );
    });

    test('a falling tide suggests more of the shore becoming visible', () {
      expect(
        TideNatureNotes.cueFor(TideDirection.falling),
        TideNatureCue.fallingShoreline,
      );
    });

    test('near high suggests the shoreline looking different', () {
      expect(
        TideNatureNotes.cueFor(TideDirection.nearHigh),
        TideNatureCue.highShoreline,
      );
    });

    test('a rising tide has nothing distinctive to say', () {
      expect(TideNatureNotes.cueFor(TideDirection.rising), isNull);
    });

    test('an indeterminate tide has nothing to say', () {
      expect(TideNatureNotes.cueFor(TideDirection.unknown), isNull);
    });
  });

  group('wording is cautious and never a safety instruction', () {
    test('no note tells anyone to walk onto tidal ground', () {
      for (final cue in TideNatureCue.values) {
        final text = TideNatureNotes.noteFor(cue).toLowerCase();
        expect(text, isNot(contains('walk onto')));
        expect(text, isNot(contains('safe')));
        expect(text, isNot(contains('you will')));
        expect(
          RegExp('can|may').hasMatch(text),
          isTrue,
          reason: 'expected tentative wording in "$text"',
        );
      }
    });

    test('no note names a specific animal or plant', () {
      for (final cue in TideNatureCue.values) {
        final text = TideNatureNotes.noteFor(cue).toLowerCase();
        for (final creature in ['crab', 'bird', 'shell', 'fish', 'seal']) {
          expect(text, isNot(contains(creature)));
        }
      }
    });
  });
}
