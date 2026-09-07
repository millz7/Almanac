import 'gardening_rule.dart';
import 'plant.dart';

/// The herb shelf. Mostly perennials, which means less sowing and more
/// pruning and dividing than the vegetable bed.
abstract final class HerbPlants {
  static const all = <PlantDefinition>[
    PlantDefinition(
      id: 'basil',
      name: 'Basil',
      category: PlantCategory.herb,
      form: PlantForm.herb,
      lifecycle: Lifecycle.annual,
      description:
          'Wants heat and hates wind. Pinch the tips to keep it '
          'bushy.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 10),
          method: SowingMethod.underCover,
          guidance: 'Sow in pots somewhere warm and bright.',
        ),
        GardeningRule.sow(
          window: MonthWindow(11, 12),
          method: SowingMethod.outdoors,
          regions: warmerRegions,
          guidance: 'Sow direct once nights are warm.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 3),
          minWeeksFromSowing: 8,
          guidance: 'Pick from the top to keep it branching.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'parsley',
      name: 'Parsley',
      category: PlantCategory.herb,
      form: PlantForm.herb,
      lifecycle: Lifecycle.biennial,
      description:
          'Slow to germinate, then useful for a year or more. Runs '
          'to seed in its second spring.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 3),
          method: SowingMethod.either,
          guidance: 'Sow and keep damp; it can take a few weeks to appear.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(10, 6),
          minWeeksFromSowing: 10,
          guidance: 'Cut outer stems at the base.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'coriander',
      name: 'Coriander',
      category: PlantCategory.herb,
      form: PlantForm.herb,
      lifecycle: Lifecycle.annual,
      description:
          'Quick to bolt in heat, so sow a little often rather than '
          'a lot once.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 3),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct; it resents being moved.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(10, 4),
          minWeeksFromSowing: 6,
          guidance: 'Cut leaves young; once it flowers, let it seed.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'mint',
      name: 'Mint',
      category: PlantCategory.herb,
      form: PlantForm.herb,
      lifecycle: Lifecycle.perennial,
      description:
          'Vigorous to the point of nuisance. A pot keeps it '
          'honest.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant into a pot or a contained bed.',
        ),
        GardeningRule.tend(
          window: MonthWindow(8, 9),
          tend: TendAction.divide,
          requires: EstablishmentState.established,
          guidance:
              'Lift and split a congested clump as it starts back into '
              'growth.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(10, 4),
          guidance: 'Pick sprigs as you need them.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'rosemary',
      name: 'Rosemary',
      category: PlantCategory.herb,
      form: PlantForm.shrub,
      lifecycle: Lifecycle.perennial,
      description:
          'A shrub, really. Wants sun, drainage and very little '
          'else.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant somewhere sunny with free-draining soil.',
        ),
        GardeningRule.harvest(
          window: MonthWindow.year,
          guidance: 'Cut sprigs whenever you want them.',
        ),
        GardeningRule.prune(
          window: MonthWindow(11, 1),
          guidance: 'Shape lightly after flowering.',
          caution:
              'Light shaping only. Rosemary rarely reshoots from bare '
              'old wood, so cut into green growth.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'thyme',
      name: 'Thyme',
      category: PlantCategory.herb,
      form: PlantForm.herb,
      lifecycle: Lifecycle.perennial,
      description: 'Low, tough and happier dry than wet.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant in full sun; it hates sitting wet.',
        ),
        GardeningRule.harvest(
          window: MonthWindow.year,
          guidance: 'Snip sprigs as needed.',
        ),
        GardeningRule.prune(
          window: MonthWindow(12, 2),
          guidance: 'Trim the spent flower stems to keep it compact.',
          caution:
              'Keep to soft growth. Cutting back hard into the woody '
              'base often kills a stem outright.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'sage',
      name: 'Sage',
      category: PlantCategory.herb,
      form: PlantForm.shrub,
      lifecycle: Lifecycle.perennial,
      description:
          'Soft grey leaves and a woody frame. Good for several '
          'years, then worth replacing.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant in sun with plenty of drainage.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(10, 5),
          guidance: 'Pick leaves as you need them.',
        ),
        GardeningRule.prune(
          window: MonthWindow(9, 10),
          guidance: 'Tidy the shape as growth begins.',
          caution:
              'Trim rather than cut back hard; old wood is slow to '
              'reshoot.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'chives',
      name: 'Chives',
      category: PlantCategory.herb,
      form: PlantForm.bulb,
      lifecycle: Lifecycle.perennial,
      description:
          'Dies back in winter and comes up again without being '
          'asked.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(8, 11),
          method: SowingMethod.either,
          guidance: 'Sow in a pot and plant out the clump.',
        ),
        GardeningRule.tend(
          window: MonthWindow(8, 9),
          tend: TendAction.divide,
          requires: EstablishmentState.established,
          guidance: 'Split a crowded clump into two or three.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(9, 5),
          guidance: 'Cut a handful at the base rather than trimming the tops.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'oregano',
      name: 'Oregano',
      category: PlantCategory.herb,
      form: PlantForm.herb,
      lifecycle: Lifecycle.perennial,
      description:
          'Spreads gently, and the flavour is strongest just before '
          'it flowers.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant in sun; it will take poor soil.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(11, 4),
          guidance: 'Cut stems just before the flowers open.',
        ),
        GardeningRule.prune(
          window: MonthWindow(2, 3),
          guidance: 'Cut back the flowered stems after flowering.',
          caution: 'Leave a hand of green growth at the base.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'dill',
      name: 'Dill',
      category: PlantCategory.herb,
      form: PlantForm.herb,
      lifecycle: Lifecycle.annual,
      description:
          'Tall, feathery and short-lived. Let one go to seed and '
          'it will sow itself.',
      rules: [
        GardeningRule.sow(
          window: MonthWindow(9, 2),
          method: SowingMethod.outdoors,
          guidance: 'Sow direct where it is to grow.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(11, 4),
          minWeeksFromSowing: 8,
          guidance:
              'Cut the feathery leaves young; the seed heads are '
              'useful too.',
        ),
      ],
    ),
  ];
}
