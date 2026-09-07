import 'gardening_region.dart';
import 'gardening_rule.dart';
import 'plant.dart';

/// The vegetable shelf.
///
/// Windows are temperate New Zealand months; see
/// [GardeningRegion.monthOffset] for how the other bands read them, and
/// `README.md` for how the windows themselves were arrived at.
abstract final class VegetablePlants {
  static const all = <PlantDefinition>[
    PlantDefinition(
      id: 'carrot',
      name: 'Carrot',
      category: PlantCategory.vegetable,
      form: PlantForm.root,
      lifecycle: Lifecycle.annual,
      description:
          'Sows direct into loose, stone-free soil. Dislikes being '
          'transplanted.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 3),
          method: SowingMethod.outdoors,
          guidance: 'Sow thinly where they are to grow.',
        ),
        GardeningRule.tend(
          window: MonthWindow(10, 4),
          tend: TendAction.thin,
          requires: EstablishmentState.seedling,
          guidance: 'Thin seedlings to a few centimetres apart.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 6),
          minWeeksFromSowing: 12,
          guidance: 'Pull one to see how they are sizing up.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'beetroot',
      name: 'Beetroot',
      category: PlantCategory.vegetable,
      form: PlantForm.root,
      lifecycle: Lifecycle.annual,
      description:
          'Quick and forgiving. The young leaves are worth eating '
          'too.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 2),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct, a few seeds to a station.',
        ),
        GardeningRule.tend(
          window: MonthWindow(10, 3),
          tend: TendAction.thin,
          requires: EstablishmentState.seedling,
          guidance: 'Thin to one seedling per station.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 6),
          minWeeksFromSowing: 10,
          guidance: 'Best pulled young, around the size of a golf ball.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'radish',
      name: 'Radish',
      category: PlantCategory.vegetable,
      form: PlantForm.root,
      lifecycle: Lifecycle.annual,
      description: 'The fastest thing in the garden. Sow a little, often.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 4),
          method: SowingMethod.outdoors,
          guidance: 'Sow a short row every few weeks.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(9, 6),
          minWeeksFromSowing: 4,
          guidance:
              'Pull as soon as they are big enough; they turn woody if '
              'left.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'potato',
      name: 'Potato',
      category: PlantCategory.vegetable,
      form: PlantForm.root,
      lifecycle: Lifecycle.annual,
      description:
          'Grown from seed potatoes rather than seed. Wants a sunny '
          'spot and loose soil.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 12),
          guidance: 'Plant seed potatoes once hard frosts have passed.',
          caution:
              'New shoots are frost-tender. Cover them if a late frost '
              'is likely.',
        ),
        GardeningRule.tend(
          window: MonthWindow(10, 1),
          tend: TendAction.mulch,
          requires: EstablishmentState.seedling,
          guidance: 'Mound soil or mulch up around the stems as they grow.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 4),
          minWeeksFromSowing: 14,
          guidance:
              'Early ones can be lifted once the flowers open; leave '
              'the rest until the tops die down.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'kumara',
      name: 'Kumara',
      category: PlantCategory.vegetable,
      form: PlantForm.root,
      lifecycle: Lifecycle.annual,
      description:
          'Grown from tipu — shoots — and wants a long warm summer '
          'and free-draining soil.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(11, 12),
          regions: warmerRegions,
          guidance: 'Plant tipu into warm soil on a raised mound.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(3, 5),
          minWeeksFromSowing: 16,
          regions: warmerRegions,
          guidance:
              'Lift before the first frost, once the leaves start to '
              'yellow.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'tomato',
      name: 'Tomato',
      category: PlantCategory.vegetable,
      form: PlantForm.fruiting,
      lifecycle: Lifecycle.annual,
      description:
          'Started under cover and planted out once nights are '
          'warm. Wants sun, support and steady water.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 10),
          method: SowingMethod.underCover,
          guidance: 'Sow in trays somewhere warm and bright.',
        ),
        GardeningRule.plant(
          window: MonthWindow(10, 12),
          guidance:
              'Plant out once the nights have warmed and frosts are '
              'past.',
          caution:
              'Frost-tender. A cold snap after planting can set them '
              'back badly.',
        ),
        GardeningRule.tend(
          window: MonthWindow(11, 3),
          tend: TendAction.support,
          requires: EstablishmentState.seedling,
          guidance: 'Tie the growing stems to a stake as they lengthen.',
        ),
        GardeningRule.tend(
          window: MonthWindow(11, 2),
          tend: TendAction.feed,
          requires: EstablishmentState.seedling,
          guidance: 'A regular liquid feed once the first fruit has set.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(1, 4),
          minWeeksFromSowing: 16,
          guidance:
              'Pick as they colour up; the flavour keeps improving on '
              'the plant.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'capsicum',
      name: 'Capsicum',
      category: PlantCategory.vegetable,
      form: PlantForm.fruiting,
      lifecycle: Lifecycle.annual,
      description:
          'Slower and more heat-hungry than tomatoes. Happiest in a '
          'sheltered, sunny corner.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 9),
          method: SowingMethod.underCover,
          guidance: 'Sow early, under cover, and keep them warm.',
        ),
        GardeningRule.plant(
          window: MonthWindow(11, 12),
          regions: warmerRegions,
          guidance:
              'Plant out into the warmest, most sheltered spot you '
              'have.',
          caution: 'Frost-tender, and sulks in cold wind.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(2, 4),
          minWeeksFromSowing: 20,
          regions: warmerRegions,
          guidance: 'Pick green, or leave longer to colour and sweeten.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'courgette',
      name: 'Courgette',
      category: PlantCategory.vegetable,
      form: PlantForm.fruiting,
      lifecycle: Lifecycle.annual,
      description:
          'One or two plants is usually plenty. Pick young and pick '
          'often.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 10),
          method: SowingMethod.underCover,
          guidance: 'Sow singly in pots to plant out later.',
        ),
        GardeningRule.sow(
          window: MonthWindow(10, 12),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct once the soil has warmed.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 3),
          minWeeksFromSowing: 8,
          guidance: 'Cut them small; a day or two makes a marrow.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'pumpkin',
      name: 'Pumpkin',
      category: PlantCategory.vegetable,
      form: PlantForm.vine,
      lifecycle: Lifecycle.annual,
      description: 'Needs room to run and a whole summer to ripen.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(10, 12),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct into warm soil, on a mound of compost.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(2, 5),
          minWeeksFromSowing: 16,
          guidance:
              'Cut with a length of stem once the skin is hard and the '
              'vine has died back.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'cucumber',
      name: 'Cucumber',
      category: PlantCategory.vegetable,
      form: PlantForm.climber,
      lifecycle: Lifecycle.annual,
      description: 'Climbs happily, which keeps the fruit clean and straight.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 10),
          method: SowingMethod.underCover,
          guidance: 'Sow in pots somewhere warm.',
        ),
        GardeningRule.sow(
          window: MonthWindow(11, 12),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct once nights are reliably mild.',
        ),
        GardeningRule.tend(
          window: MonthWindow(11, 2),
          tend: TendAction.support,
          requires: EstablishmentState.seedling,
          guidance: 'Give the vines something to climb.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(1, 3),
          minWeeksFromSowing: 9,
          guidance: 'Pick regularly to keep more coming.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'pea',
      name: 'Pea',
      category: PlantCategory.vegetable,
      form: PlantForm.climber,
      lifecycle: Lifecycle.annual,
      description:
          'Cool-season, and worth sowing in short successions. Give '
          'even dwarf types something to lean on.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 11),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct in a double row.',
        ),
        GardeningRule.sow(
          window: MonthWindow(3, 4),
          method: SowingMethod.outdoors,
          regions: warmerRegions,
          guidance:
              'An autumn sowing can crop through winter where frosts '
              'are light.',
        ),
        GardeningRule.tend(
          window: MonthWindow(9, 12),
          tend: TendAction.support,
          requires: EstablishmentState.seedling,
          guidance: 'Put support in early, before the tendrils go looking.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(10, 1),
          minWeeksFromSowing: 11,
          guidance: 'Pick from the bottom up, and pick often.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'broad-bean',
      name: 'Broad bean',
      category: PlantCategory.vegetable,
      form: PlantForm.climber,
      lifecycle: Lifecycle.annual,
      description:
          'Sown in autumn to stand through winter. One of the first '
          'things to pick in spring.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(4, 6),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct where they are to stand the winter.',
        ),
        GardeningRule.tend(
          window: MonthWindow(7, 10),
          tend: TendAction.support,
          requires: EstablishmentState.seedling,
          guidance: 'A string around stakes keeps the row upright in wind.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(9, 11),
          minWeeksFromSowing: 16,
          guidance:
              'Pick while the pods are still smooth and the beans '
              'small.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'green-bean',
      name: 'Green bean',
      category: PlantCategory.vegetable,
      form: PlantForm.climber,
      lifecycle: Lifecycle.annual,
      description:
          'Warm-season and quick. Dwarf types need no support; '
          'climbing ones need plenty.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(10, 1),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct into warm soil; they rot in cold ground.',
        ),
        GardeningRule.tend(
          window: MonthWindow(11, 2),
          tend: TendAction.support,
          requires: EstablishmentState.seedling,
          guidance: 'Climbing types want a frame or teepee.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 3),
          minWeeksFromSowing: 8,
          guidance: 'Pick young and keep picking.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'lettuce',
      name: 'Lettuce',
      category: PlantCategory.vegetable,
      form: PlantForm.leafyGreen,
      lifecycle: Lifecycle.annual,
      description:
          'Better in short successions than in one big sowing. '
          'Bolts in high summer heat.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 3),
          method: SowingMethod.either,
          guidance: 'Sow a few every couple of weeks.',
        ),
        GardeningRule.tend(
          window: MonthWindow(9, 4),
          tend: TendAction.thin,
          requires: EstablishmentState.seedling,
          guidance: 'Thin to a hand-width apart, and eat the thinnings.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(10, 5),
          minWeeksFromSowing: 6,
          guidance: 'Take outer leaves, or cut the whole head.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'spinach',
      name: 'Spinach',
      category: PlantCategory.vegetable,
      form: PlantForm.leafyGreen,
      lifecycle: Lifecycle.annual,
      description: 'A cool-season crop. Runs to seed as the days lengthen.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(2, 9),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct in the cooler months.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(4, 11),
          minWeeksFromSowing: 6,
          guidance: 'Pick outer leaves and let the centre keep growing.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'silverbeet',
      name: 'Silverbeet',
      category: PlantCategory.vegetable,
      form: PlantForm.leafyGreen,
      lifecycle: Lifecycle.biennial,
      description:
          'The most patient green there is. A few plants will pick '
          'for most of the year.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 3),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct, or in trays to plant out.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(11, 9),
          minWeeksFromSowing: 8,
          guidance: 'Snap off outer stems at the base; leave the heart.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'kale',
      name: 'Kale',
      category: PlantCategory.vegetable,
      form: PlantForm.leafyGreen,
      lifecycle: Lifecycle.biennial,
      description:
          'Sown in late summer for winter picking. Frost improves '
          'the flavour.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(10, 2),
          method: SowingMethod.either,
          guidance: 'Sow in trays or direct for autumn planting.',
        ),
        GardeningRule.plant(
          window: MonthWindow(12, 3),
          guidance: 'Plant out with room to spread.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(5, 9),
          minWeeksFromSowing: 12,
          guidance: 'Pick the lower leaves and let the top keep going.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'broccoli',
      name: 'Broccoli',
      category: PlantCategory.vegetable,
      form: PlantForm.leafyGreen,
      lifecycle: Lifecycle.annual,
      description:
          'Cut the main head and most types will give side shoots '
          'for weeks afterwards.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(10, 2),
          method: SowingMethod.either,
          guidance: 'Sow in trays to plant out as seedlings.',
        ),
        GardeningRule.plant(
          window: MonthWindow(11, 3),
          guidance: 'Plant out firmly, a good hand-span apart.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(1, 8),
          minWeeksFromSowing: 12,
          guidance: 'Cut while the head is still tight and the buds closed.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'cauliflower',
      name: 'Cauliflower',
      category: PlantCategory.vegetable,
      form: PlantForm.leafyGreen,
      lifecycle: Lifecycle.annual,
      description:
          'Fussier than broccoli: it wants steady water and rich '
          'soil to head up well.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(10, 2),
          method: SowingMethod.either,
          guidance: 'Sow in trays for planting out.',
        ),
        GardeningRule.plant(
          window: MonthWindow(11, 3),
          guidance: 'Plant out into firm, well-fed soil.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(3, 9),
          minWeeksFromSowing: 16,
          guidance: 'Cut once the curd is full but still tight.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'cabbage',
      name: 'Cabbage',
      category: PlantCategory.vegetable,
      form: PlantForm.leafyGreen,
      lifecycle: Lifecycle.annual,
      description:
          'Slow, undemanding, and useful for months. There are '
          'types for every season.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 2),
          method: SowingMethod.either,
          guidance: 'Sow in trays for planting out.',
        ),
        GardeningRule.plant(
          window: MonthWindow(10, 3),
          guidance: 'Plant out firmly and keep the water up.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 9),
          minWeeksFromSowing: 14,
          guidance: 'Cut when the head feels solid.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'onion',
      name: 'Onion',
      category: PlantCategory.vegetable,
      form: PlantForm.bulb,
      lifecycle: Lifecycle.biennial,
      description:
          'A long season in the ground for a crop that then keeps '
          'for months.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(4, 7),
          method: SowingMethod.outdoors,
          guidance: 'Sow thinly in a seed bed to transplant later.',
        ),
        GardeningRule.plant(
          window: MonthWindow(7, 9),
          guidance: 'Plant seedlings shallowly, a hand-width apart.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 2),
          minWeeksFromSowing: 26,
          guidance: 'Lift once the tops have fallen over and dried off.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'garlic',
      name: 'Garlic',
      category: PlantCategory.vegetable,
      form: PlantForm.bulb,
      lifecycle: Lifecycle.biennial,
      description:
          'The old rule is to plant on the shortest day and lift on '
          'the longest. It is close enough to be useful.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(5, 6),
          shiftsWithRegion: false,
          guidance:
              'Plant single cloves, pointed end up, around the '
              'shortest day.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 1),
          minWeeksFromSowing: 26,
          shiftsWithRegion: false,
          guidance:
              'Lift around the longest day, once the lower leaves have '
              'browned.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'leek',
      name: 'Leek',
      category: PlantCategory.vegetable,
      form: PlantForm.bulb,
      lifecycle: Lifecycle.biennial,
      description:
          'Slow but very hardy, and it will stand in the ground all '
          'winter until you want it.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 12),
          method: SowingMethod.outdoors,
          guidance: 'Sow in a seed bed to transplant later.',
        ),
        GardeningRule.plant(
          window: MonthWindow(11, 2),
          guidance: 'Drop seedlings into deep holes to blanch the stems.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(4, 9),
          minWeeksFromSowing: 26,
          guidance: 'Lift as you need them through the winter.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'sweetcorn',
      name: 'Sweetcorn',
      category: PlantCategory.vegetable,
      form: PlantForm.fruiting,
      lifecycle: Lifecycle.annual,
      description:
          'Wind-pollinated, so plant it in a block rather than a '
          'row. Best eaten the day it is picked.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(10, 12),
          method: SowingMethod.outdoors,
          regions: warmerRegions,
          guidance: 'Sow direct into warm soil, in a block of short rows.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(1, 3),
          minWeeksFromSowing: 11,
          regions: warmerRegions,
          guidance:
              'Pick when the silks have browned and a squeezed kernel '
              'runs milky.',
        ),
      ],
    ),
  ];
}
