import 'package:almanac/features/meditation/presentation/meditation_text.dart';
import 'package:almanac/features/meditation/presentation/widgets/breath_guidance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('the guidance arrives and leaves', () {
    double opacityAt(num seconds) =>
        guidanceOpacity(Duration(milliseconds: (seconds * 1000).round()));

    test('nothing at the very start of a step', () {
      expect(opacityAt(0), 0);
    });

    test('fades in, sits, then fades out', () {
      expect(opacityAt(0.175), closeTo(0.5, 0.01));
      expect(opacityAt(0.35), 1);
      expect(opacityAt(1), 1);
      expect(opacityAt(1.8), 1);
      expect(opacityAt(2.2), closeTo(0.5, 0.05));
      expect(opacityAt(2.6), 0);
    });

    test('is gone well before the shortest phase ends', () {
      // Focus's four seconds is the shortest phase any practice has, and
      // the words must not still be sitting there when the next breath
      // starts.
      expect(opacityAt(3), 0);
      expect(opacityAt(4), 0);
    });

    test('never leaves 0 to 1, and never jumps', () {
      var previous = opacityAt(0);
      for (var ms = 0; ms <= 6000; ms += 25) {
        final opacity = guidanceOpacity(Duration(milliseconds: ms));
        expect(opacity, inInclusiveRange(0, 1), reason: 'at ${ms}ms');
        expect(
          (opacity - previous).abs(),
          lessThan(0.1),
          reason: 'the guidance flickered at ${ms}ms',
        );
        previous = opacity;
      }
    });

    test('a negative elapsed is nothing, not something', () {
      expect(guidanceOpacity(const Duration(milliseconds: -100)), 0);
    });
  });

  group('the words at the end', () {
    test('spell the number rather than printing it', () {
      expect(describeSessionLength(4), 'Four quiet minutes.');
      expect(describeSessionLength(2), 'Two quiet minutes.');
      expect(describeSessionLength(20), 'Twenty quiet minutes.');
    });

    test('gets the singular right', () {
      expect(describeSessionLength(1), 'One quiet minute.');
    });

    test('falls back to digits rather than breaking', () {
      expect(describeSessionLength(45), '45 quiet minutes.');
      expect(spellNumber(-1), '-1');
    });
  });
}
