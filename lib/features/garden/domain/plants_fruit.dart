import 'gardening_region.dart';
import 'gardening_rule.dart';
import 'plant.dart';

/// The fruit shelf: perennials, planted once and pruned for years
/// afterwards.
///
/// Pruning windows are the part of this dataset most worth getting
/// right, because the wrong month costs a season's crop or lets disease
/// in. Every pruning rule carries its qualification.
abstract final class FruitPlants {
  static const all = <PlantDefinition>[
    PlantDefinition(
      id: 'strawberry',
      name: 'Strawberry',
      category: PlantCategory.fruit,
      form: PlantForm.leafyGreen,
      lifecycle: Lifecycle.perennial,
      description:
          'Best replaced every few years from its own runners. '
          'Wants sun and something clean to sit on.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(5, 9),
          guidance: 'Plant crowns level with the soil, not buried.',
        ),
        GardeningRule.tend(
          window: MonthWindow(9, 11),
          tend: TendAction.mulch,
          requires: EstablishmentState.established,
          guidance:
              'Tuck straw or mulch under the plants before the fruit '
              'sets.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(11, 2),
          guidance: 'Pick fully red, with the stem attached.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'raspberry',
      name: 'Raspberry',
      category: PlantCategory.fruit,
      form: PlantForm.shrub,
      lifecycle: Lifecycle.perennial,
      description:
          'Canes, not bushes. Which canes to cut depends entirely '
          'on whether it fruits in summer or autumn.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(6, 8),
          guidance: 'Plant bare-rooted canes while they are dormant.',
        ),
        GardeningRule.tend(
          window: MonthWindow(10, 12),
          tend: TendAction.support,
          requires: EstablishmentState.established,
          guidance: 'Tie new canes to wires as they lengthen.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 3),
          guidance: 'Pick when the berry pulls away from its core cleanly.',
        ),
        GardeningRule.prune(
          window: MonthWindow(5, 7),
          guidance:
              'Cut out the canes that carried fruit and keep the '
              'strongest new ones.',
          caution:
              'Summer-fruiting and autumn-fruiting kinds are pruned '
              'differently. Check which you have before cutting: removing '
              'the wrong canes costs next season.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'blueberry',
      name: 'Blueberry',
      category: PlantCategory.fruit,
      form: PlantForm.shrub,
      lifecycle: Lifecycle.perennial,
      description:
          'Wants acid soil and steady moisture. Two varieties '
          'crop better than one.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(6, 8),
          guidance:
              'Plant into acid, well-drained soil enriched with '
              'compost.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 2),
          guidance:
              'Leave them a few days after they turn blue; they sweeten '
              'on the bush.',
        ),
        GardeningRule.prune(
          window: MonthWindow(7, 8),
          guidance: 'Thin out the oldest wood while the bush is dormant.',
          caution:
              'Young bushes need almost nothing. Take no more than a '
              'fifth of the oldest wood from an established one.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'blackberry',
      name: 'Blackberry',
      category: PlantCategory.fruit,
      form: PlantForm.climber,
      lifecycle: Lifecycle.perennial,
      description:
          'Thornless garden varieties are worth seeking out. Train '
          'the canes along wires.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(6, 8),
          guidance: 'Plant while dormant, against a fence or wires.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(1, 3),
          guidance:
              'Pick when the berry is dull black and comes away '
              'easily.',
        ),
        GardeningRule.prune(
          window: MonthWindow(5, 7),
          guidance: 'Remove the canes that fruited and tie in the new ones.',
          caution:
              'Only the canes that carried fruit come out. This year\'s '
              'new growth is next year\'s crop.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'apple',
      name: 'Apple',
      category: PlantCategory.fruit,
      form: PlantForm.tree,
      lifecycle: Lifecycle.perennial,
      description:
          'Most varieties need a pollinator nearby. Dwarf '
          'rootstocks suit a small garden.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(6, 8),
          guidance:
              'Plant bare-rooted trees in winter, staked against '
              'wind.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(2, 4),
          guidance: 'Ripe when a lifted fruit parts easily from the spur.',
        ),
        GardeningRule.prune(
          window: MonthWindow(6, 8),
          guidance: 'Prune in winter for shape and to open the centre.',
          caution:
              'Apples fruit on short spurs that last for years. '
              'Shortening every branch tip removes next season\'s fruit.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'pear',
      name: 'Pear',
      category: PlantCategory.fruit,
      form: PlantForm.tree,
      lifecycle: Lifecycle.perennial,
      description:
          'Longer-lived and more upright than an apple, and best '
          'picked before it is soft.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(6, 8),
          guidance: 'Plant while dormant, with a stake.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(2, 4),
          guidance: 'Pick while still firm and ripen them indoors.',
        ),
        GardeningRule.prune(
          window: MonthWindow(6, 8),
          guidance: 'Prune in winter, lightly, to keep the frame open.',
          caution:
              'Like apples, pears fruit on spurs. Hard heading back '
              'trades fruit for leafy growth.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'peach',
      name: 'Peach',
      category: PlantCategory.fruit,
      form: PlantForm.tree,
      lifecycle: Lifecycle.perennial,
      description:
          'Fruits on wood grown the previous year, so it needs '
          'yearly renewal to keep cropping.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(6, 8),
          guidance: 'Plant while dormant in a warm, sheltered spot.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 2),
          guidance: 'Ripe when the flesh gives slightly beside the stem.',
        ),
        GardeningRule.prune(
          window: MonthWindow(11, 2),
          guidance: 'Prune in the warm months, straight after harvest.',
          caution:
              'Stone fruit are pruned in warm, dry weather — not in '
              'winter — because cold wet cuts invite silver leaf. Avoid '
              'pruning in rain.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'plum',
      name: 'Plum',
      category: PlantCategory.fruit,
      form: PlantForm.tree,
      lifecycle: Lifecycle.perennial,
      description:
          'Heavy croppers. Thinning the fruit early gives better '
          'plums and saves broken branches.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(6, 8),
          guidance: 'Plant while dormant, staked.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(12, 3),
          guidance: 'Pick as they soften and colour fully.',
        ),
        GardeningRule.prune(
          window: MonthWindow(11, 2),
          guidance: 'Prune after harvest, in warm dry weather.',
          caution:
              'As with all stone fruit, avoid winter and wet-weather '
              'pruning: it is how silver leaf gets in.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'lemon',
      name: 'Lemon',
      category: PlantCategory.fruit,
      form: PlantForm.tree,
      lifecycle: Lifecycle.perennial,
      description:
          'The most forgiving citrus, and happy in a large pot. '
          'Hungry, and hates cold wind.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance:
              'Plant in spring, once the soil has warmed, in the '
              'warmest corner you have.',
        ),
        GardeningRule.tend(
          window: MonthWindow(8, 9),
          tend: TendAction.feed,
          requires: EstablishmentState.seedling,
          guidance: 'Feed with a citrus food as growth begins.',
        ),
        GardeningRule.tend(
          window: MonthWindow(5, 8),
          tend: TendAction.frostProtect,
          requires: EstablishmentState.seedling,
          regions: {
            GardeningRegion.nzCentral,
            GardeningRegion.nzSouthern,
            GardeningRegion.genericSouthern,
            GardeningRegion.genericNorthern,
          },
          guidance:
              'Shelter young trees on frosty nights, or move a potted '
              'one under cover.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(5, 10),
          guidance: 'Leave fruit on the tree until you want it.',
        ),
        GardeningRule.prune(
          window: MonthWindow(10, 11),
          guidance:
              'Tidy the shape and take out dead wood after the main '
              'harvest.',
          caution:
              'Citrus need very little pruning. Avoid cutting in cold '
              'weather, and never remove more than a fifth of the canopy.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'lime',
      name: 'Lime',
      category: PlantCategory.fruit,
      form: PlantForm.tree,
      lifecycle: Lifecycle.perennial,
      description:
          'The most cold-tender of the common citrus. A pot that '
          'can be moved is a good idea.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(10, 12),
          regions: warmerRegions,
          guidance: 'Plant once the soil is genuinely warm, in full sun.',
        ),
        GardeningRule.tend(
          window: MonthWindow(8, 9),
          tend: TendAction.feed,
          requires: EstablishmentState.seedling,
          guidance: 'Feed with a citrus food as growth begins.',
        ),
        GardeningRule.tend(
          window: MonthWindow(5, 8),
          tend: TendAction.frostProtect,
          requires: EstablishmentState.seedling,
          regions: {
            GardeningRegion.nzCentral,
            GardeningRegion.nzSouthern,
            GardeningRegion.genericSouthern,
            GardeningRegion.genericNorthern,
          },
          guidance:
              'Protect from frost; limes are the first citrus to '
              'suffer.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(4, 8),
          guidance: 'Pick while still green and heavy for their size.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'orange',
      name: 'Orange',
      category: PlantCategory.fruit,
      form: PlantForm.tree,
      lifecycle: Lifecycle.perennial,
      description:
          'Slower than a lemon to come into crop, and worth the '
          'wait. Wants shelter and feeding.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant in spring in a warm, sheltered spot.',
        ),
        GardeningRule.tend(
          window: MonthWindow(8, 9),
          tend: TendAction.feed,
          requires: EstablishmentState.seedling,
          guidance: 'Feed with a citrus food as growth begins.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(7, 10),
          guidance:
              'Taste one before picking the rest; colour alone is not '
              'ripeness.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'feijoa',
      name: 'Feijoa',
      category: PlantCategory.fruit,
      form: PlantForm.shrub,
      lifecycle: Lifecycle.perennial,
      description:
          'Tough, wind-hardy and generous. Two varieties usually '
          'set more fruit than one.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(9, 11),
          guidance: 'Plant in spring; it will take a hedge position.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(3, 5),
          guidance: 'Let them fall, and collect them from underneath.',
        ),
        GardeningRule.prune(
          window: MonthWindow(6, 8),
          guidance: 'Thin and shape after the harvest is finished.',
          caution:
              'Prune after fruiting rather than in spring: spring cuts '
              'remove the wood that would have flowered.',
        ),
      ],
    ),
    PlantDefinition(
      id: 'passionfruit',
      name: 'Passionfruit',
      category: PlantCategory.fruit,
      form: PlantForm.vine,
      lifecycle: Lifecycle.perennial,
      description:
          'A short-lived vine that crops heavily for a few years. '
          'Needs a warm wall and a strong frame.',
      rules: [
        GardeningRule.plant(
          window: MonthWindow(10, 12),
          regions: warmerRegions,
          guidance:
              'Plant against a sunny wall or fence with room to '
              'climb.',
        ),
        GardeningRule.tend(
          window: MonthWindow(10, 1),
          tend: TendAction.feed,
          requires: EstablishmentState.seedling,
          guidance: 'Feed through the growing season; it is a hungry vine.',
        ),
        GardeningRule.harvest(
          window: MonthWindow(2, 5),
          regions: warmerRegions,
          guidance: 'Collect the fruit once it drops and wrinkles slightly.',
        ),
        GardeningRule.prune(
          window: MonthWindow(9, 10),
          guidance:
              'Thin out tangled growth in spring, keeping the main '
              'framework.',
          caution:
              'Never cut back to bare wood — passionfruit flowers on '
              'new growth from live stems.',
        ),
      ],
    ),
  ];
}
