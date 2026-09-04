# Almanac

A nature-connected wellbeing app for Android, built with Flutter. Its
central idea: wellbeing experienced through connection with the natural
world — the sun, moon, tides, seasons and the life around us.

This repository currently contains the **project foundation only**: the
navigation shell, design system and placeholder screens that later
features (Today, Wellbeing, Rhythms, Nature, Food) will be built inside.
No feature functionality — real sun/moon/tide data, location, breathing
exercises, recipes, etc. — is implemented yet.

## Getting started

```
flutter pub get
flutter run
```

## Architecture

- `lib/app/` — app entry widget, router, and the central theme/design
  system (`lib/app/theme/`).
- `lib/core/environment/` — the natural environment: season, day/night,
  hemisphere, location and solar services. The single source of truth the
  theme (and later, features) read from.
- `lib/core/settings/` — the small set of persisted user choices, behind a
  `SettingsStore` interface.
- `lib/core/widgets/` — small reusable UI building blocks shared across
  features (`AppScaffold`, `AppCard`, `SectionHeader`, `PrimaryButton`,
  `EmptyState`, `FeaturePlaceholderScreen`).
- `lib/features/<feature>/presentation/` — one folder per top-level tab
  (today, wellbeing, rhythms, nature, food). `data/` and `domain/`
  subfolders will be added to a feature once it has real business logic.
- `lib/dev/` — development-only tooling, excluded from the production
  experience.

State management is [Riverpod](https://riverpod.dev); navigation is
[go_router](https://pub.dev/packages/go_router) with a
`StatefulShellRoute` powering the five-tab bottom navigation.

## Seasonal and day/night theme

The app changes appearance with the world outside it. There are eight
palettes — spring, summer, autumn and winter, each with a day and a night
interpretation — and the active one is chosen automatically:

- **Season** comes from the true equinox and solstice instants (Meeus,
  *Astronomical Algorithms* ch. 27) combined with the user's hemisphere,
  so December is summer in Wellington and winter in London.
- **Day/night** comes from sunrise/sunset for the user's location, as a
  continuous `daylight` value from 0 to 1. Dawn and dusk interpolate
  between the season's night and day palettes rather than snapping.

Screens never ask what season it is. They read semantic tokens
(`background`, `primary`, `accent`, `water`, `earth`, …) from the active
`SeasonalPalette`, either through `Theme.of(context)` or
`context.palette`, so any screen written later inherits the season for
free. Typography, spacing and shape do not change with the season.

Only the summer palette is designed — it is built on supplied reference
colours (`SummerReferenceColors`). Spring, autumn and winter are marked
**PROVISIONAL** and exist to prove the engine works; they will be
replaced with designed palettes.

## Hemisphere, location and privacy

The app needs to know which hemisphere the user is in, because the same
date is a different season north and south. It gets that in one of three
ways, in priority order:

1. **A real latitude**, if the user has shared their location.
2. **The hemisphere they chose** during onboarding — the normal case.
3. A documented technical fallback, reachable only before onboarding has
   been completed.

A location-derived hemisphere is used for calculations but **never
overwrites the stored choice**, so revoking location returns the user to
their own preference. `HemisphereSource` records which of the three is in
play.

Location itself is optional and stays that way:

- The first screen is the hemisphere question, never a permission dialog.
- The explanation of what location is for is shown once, and "Not Now" is
  a first-class answer.
- Everything seasonal works without it. Features that genuinely need
  coordinates must check `NaturalEnvironment.hasPreciseLocation` rather
  than assume a position.
- Only `ACCESS_COARSE_LOCATION` is declared, only "while in use" is ever
  requested, and no position is written to disk — the app asks the
  platform when it needs one.
- The app never re-prompts on its own; a permanent denial sets
  `canRequest` to false.

Note that seasons are **astronomical**: they turn at the equinoxes and
solstices, not on the 1st of a month. Early September is therefore still
summer in the north and winter in the south.

## Time, sun and place

- **Time zone.** A real IANA zone (`Pacific/Auckland`, not "UTC+12"),
  read from the device and re-read when the app resumes. That matters
  because an offset cannot describe a place: a daylight-saving zone is
  +12 for part of the year and +13 for the rest, and the local day it
  implies is 23 or 25 hours long on the days the clocks shift.
- **Sunrise and sunset** are calculated on the device from latitude,
  longitude and the local date, using NOAA's published solar algorithm
  (Meeus ch. 25). Accurate to about a minute below ~72° latitude. Results
  are absolute UTC instants, converted to local time only for display —
  never stored as a naive clock time.
- **Polar days** are represented explicitly: inside the polar circles
  `SolarEvents` reports `sunNeverRises` or `sunNeverSets` rather than
  inventing a time, and the day/night engine pins the palette to full
  night or full day accordingly.
- **Without coordinates** the app cannot know sunrise, so it estimates
  day/night from the local clock and flags the result
  `DayNightAccuracy.estimatedWithoutLocation`. The estimate is good
  enough to theme by and is never presented as a sunrise time.
- **Location is read sparingly.** A fix is reused while it is less than
  15 minutes old; the app re-checks permission on resume without
  prompting, and only ever prompts from a deliberate tap. There is no
  tracking, no background location and no stored history.

## Settings

A gear icon on Today opens `/settings` — pushed over the app rather than
being a sixth tab. It has one section, "Location & Region": change the
hemisphere, and see and act on location access. Changing the hemisphere
takes effect immediately, with no restart.

### Previewing palettes during development

In debug builds, the palette icon on the Today screen opens a preview
screen (`/dev/theme`) for inspecting all eight combinations, the semantic
tokens and the environment the engine detected. It is not a user setting
and is absent from release builds.

## Design system

All colour, typography, spacing, radius, elevation, motion and icon-size
values are centralised in `lib/app/theme/`. Widgets should reference
these tokens (via `Theme.of(context)`, `context.palette`, or the `App*`
token classes) rather than hard-coding values.

## Testing

```
flutter test
```
