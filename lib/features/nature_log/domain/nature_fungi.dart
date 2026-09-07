import 'nature_item.dart';

/// Fungi, and the handful of other things that are neither bird, plant
/// nor insect.
///
/// **The fungi entries describe forms, not dinners.** They are here to
/// help somebody notice and name what they are looking at. Nothing in
/// this book says whether any fungus is safe to eat, touch or pick,
/// because an app looking at nothing cannot know that — and
/// `nature_content_test.dart` fails if that language ever appears.
abstract final class NatureFungiAndOther {
  static const all = <NatureItem>[
    NatureItem(
      id: 'bracket-fungi',
      primaryName: 'Bracket fungi',
      category: NatureCategory.fungi,
      form: NatureMarkForm.fungus,
      description:
          'Hard, shelf-like growths on standing trunks and fallen '
          'logs, often in tiers.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.appearing,
          window: MonthWindow(1, 12),
          text:
              'Often on trunks and logs year round, and easier to see in '
              'winter.',
        ),
      ],
    ),
    NatureItem(
      id: 'puffball',
      primaryName: 'Puffballs',
      category: NatureCategory.fungi,
      form: NatureMarkForm.fungus,
      description:
          'Rounded and stalkless, releasing a cloud of spores '
          'through a hole at the top when knocked.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.appearing,
          window: MonthWindow(3, 6),
          text: 'Often appearing on grass and open ground in autumn.',
        ),
      ],
    ),
    NatureItem(
      id: 'basket-fungus',
      primaryName: 'Tūtae whetū',
      alternateName: 'Basket fungus',
      category: NatureCategory.fungi,
      form: NatureMarkForm.fungus,
      scientificName: 'Ileodictyon cibarium',
      description:
          'A hollow white lattice ball that breaks out of an egg '
          'in the soil. Unmistakable, and it smells.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.appearing,
          window: MonthWindow(3, 6),
          text: 'Often appearing on garden soil and mulch in autumn.',
        ),
      ],
    ),
    NatureItem(
      id: 'wood-ear',
      primaryName: 'Hakeke',
      alternateName: 'Wood ear',
      category: NatureCategory.fungi,
      form: NatureMarkForm.fungus,
      scientificName: 'Auricularia species',
      description:
          'Soft, rubbery and ear-shaped, on dead wood. Shrivels '
          'dry and swells again after rain.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.appearing,
          window: MonthWindow(4, 9),
          text: 'Often swelling on dead wood after winter rain.',
        ),
      ],
    ),
    NatureItem(
      id: 'fly-agaric',
      primaryName: 'Fly agaric',
      category: NatureCategory.fungi,
      form: NatureMarkForm.fungus,
      scientificName: 'Amanita muscaria',
      description:
          'Red cap with white flecks, introduced with pines and '
          'birches. One of the few fungi almost everybody recognises.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.appearing,
          window: MonthWindow(3, 6),
          text: 'Often appearing under pines and birches in autumn.',
        ),
      ],
    ),
    NatureItem(
      id: 'common-skink',
      primaryName: 'Mokomoko',
      alternateName: 'Common skink',
      category: NatureCategory.other,
      form: NatureMarkForm.other,
      scientificName: 'Oligosoma species',
      description:
          'Small, brown and quick, basking on warm stone and '
          'timber before vanishing into cover.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(10, 3),
          text: 'Often basking on warm surfaces on still summer days.',
        ),
      ],
    ),
    NatureItem(
      id: 'longfin-eel',
      primaryName: 'Tuna',
      alternateName: 'Longfin eel',
      category: NatureCategory.other,
      form: NatureMarkForm.other,
      scientificName: 'Anguilla dieffenbachii',
      description:
          'Long-lived and found in streams and lakes, usually seen '
          'as a shadow under a bank.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.activity,
          window: MonthWindow(11, 3),
          text: 'Often more visible in low, clear summer water.',
        ),
      ],
    ),
    NatureItem(
      id: 'garden-spider',
      primaryName: 'Pūngāwerewere',
      alternateName: 'Orbweb spider',
      category: NatureCategory.other,
      form: NatureMarkForm.other,
      description:
          'The maker of the round webs across paths and gaps, '
          'rebuilt most nights.',
      notes: [
        NatureNote(
          kind: NatureNoteKind.appearing,
          window: MonthWindow(1, 4),
          text: 'Webs often at their largest and most obvious in autumn.',
        ),
      ],
    ),
  ];
}
