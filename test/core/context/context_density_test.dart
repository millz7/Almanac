import 'package:almanac/core/context/context_density.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one presentation rule every contextual suggestion shares: a new
/// one is admitted only if it adds something the page is not already
/// saying, and only while there is room for it.
void main() {
  group('ContextDensity.admits', () {
    test('a new suggestion is admitted while there is room', () {
      expect(
        ContextDensity.admits(candidate: 'b', alreadyShown: ['a'], limit: 2),
        isTrue,
      );
    });

    test('nothing already said is said again', () {
      expect(
        ContextDensity.admits(candidate: 'a', alreadyShown: ['a'], limit: 3),
        isFalse,
      );
    });

    test('nothing is admitted once the page is full', () {
      expect(
        ContextDensity.admits(
          candidate: 'c',
          alreadyShown: ['a', 'b'],
          limit: 2,
        ),
        isFalse,
      );
    });

    test('an empty page admits anything', () {
      expect(
        ContextDensity.admits(candidate: 'a', alreadyShown: [], limit: 1),
        isTrue,
      );
    });

    test('it is a pure rule: no scoring, and the same answer every time', () {
      for (var i = 0; i < 3; i++) {
        expect(
          ContextDensity.admits(candidate: 1, alreadyShown: [2, 3], limit: 3),
          isTrue,
        );
      }
    });
  });
}
