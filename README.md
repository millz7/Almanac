# Almanac

A nature-connected wellbeing app for Android, built with Flutter. Its
central idea: wellbeing experienced through connection with the natural
world — the sun, moon, tides, seasons and the life around us.

**Environment** is the first real screen and the app's anchor: the date,
the season, a drawn sky that follows the sun, today's sunrise and sunset,
and the moon's phase. Tides are held open with no data rather than filled
with a guess.

Everything else is the user's choice. On first launch the app asks four
short questions — a name, a hemisphere, whether to use location, and what
they would like in their Almanac — and the bottom navigation is then built
from the Environment plus whatever they picked. **Meditation** is built:
four breathing practices, a glowing orb, and nothing else on screen once
you begin. Yoga, Chakras, Cycle, Cookbook, Garden and Nature Log exist as
destinations but are not implemented yet.

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
- `lib/core/features/` — the feature catalogue: `FeatureId`,
  `FeatureDefinition`, `FeatureRegistry`. The single place a feature's
  name, short name, icon, route and description are written down.
- `lib/app/navigation/` — how the catalogue plus the user's preferences
  become a bottom navigation bar.
- `lib/features/<feature>/presentation/` — one folder per built feature.
  `data/` and `domain/` subfolders are added once a feature has real
  business logic. The Environment screen is composed from small widgets
  under `environment/presentation/widgets/`, with all of its wording in
  `environment/presentation/environment_text.dart`.
- `lib/features/almanac/` — the user's own panel: name, hemisphere,
  location and which features they keep.
- `lib/features/placeholder/` — one screen, driven by a
  `FeatureDefinition`, standing in for every feature not yet built.
  `lib/app/navigation/feature_screens.dart` is the one place that knows
  which features have real screens; everything else gets the placeholder.
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

During that interpolation the *grounds* — backgrounds, surfaces and
decorative fills — cross-fade, but text, icons and the colours that sit
on a coloured container do not: each is *chosen* from the day or night
palette by which reads better on the ground it has landed on. Fading
them alongside the background made them meet it in the middle and
disappear (1.01:1, twice a day). See `SeasonalPalette.lerp`.

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
summer in the north and winter in the south. The Environment screen uses
the same boundaries to say *where in* the season you are — "early
summer" — and how many days until autumn.

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

## The moon

The phase is calculated on the device from the moon's elongation from the
sun — the largest periodic terms of the lunar theory in Meeus ch. 47,
sharing its solar position with the sunrise calculation
(`lib/core/environment/astronomy.dart`). It needs no network and no
position: the phase is the same for everybody on Earth at a given moment.
Accurate to a couple of minutes of the moon's motion, which is checked
against twelve published new and full moons.

It is drawn, not shipped as artwork: `MoonDisc` paints the terminator as
a projected ellipse, so the shape is right on every night of the cycle
rather than snapping between eight pictures. The lit limb flips with the
hemisphere, because a waxing moon is lit on the right from the north and
on the left from the south.

What it does **not** claim: moonrise and moonset, where the moon is in
the sky, or whether it is visible from a particular place. Its placement
in the Environment screen's sky is composition, which is why that whole
graphic is marked decorative and states nothing to a screen reader.

## The Environment screen

The order of the page is the design: the date and season, then a large
wordless picture of the sky, then the few facts worth knowing. No score,
no streak, no chart.

- The sun's height on its arc comes from `solarDayProgress` — a
  *different* quantity from `daylight`, which has already reached 1.0 by
  breakfast and so cannot place the sun. It is null before sunrise, after
  sunset and on polar days, and nothing draws a sun at a made-up height.
- Sunrise and sunset are real local times from `SolarService`, converted
  from absolute instants for display and following the device's 12/24-hour
  setting.
- Without location the section says what it needs and offers to ask, once,
  from a deliberate tap. It is a quiet invitation, not an error — the
  season, the moon and the rest of the day are all still there.
- Inside the polar circles it says the sun does not rise or set today,
  rather than printing a time.
- Animation is implicit and one-shot: the sun glides when its position
  changes and then stops. There is no repeating ticker, and
  `MediaQuery.disableAnimationsOf` switches it off entirely.

## First launch

Four questions, in this order, each derived from stored settings rather
than from a wizard's own state — so closing the app halfway through
resumes in the right place:

1. **A name.** Optional and plainly skippable. Used for exactly one
   thing: the title of their panel. No account, nothing sent anywhere.
2. **A hemisphere.** The one question that must be answered, because the
   same date is a different season north and south.
3. **Location.** Explained, then offered. Android is asked only after a
   deliberate tap on "Allow Location" — never on arriving at the screen —
   and "Not Now" is a first-class answer.
4. **What they would like in their Almanac.** Multi-select; choosing
   nothing is allowed and gets an app that is just the Environment.

`onboardingCompleted` is a stored flag rather than something inferred,
because every one of those questions has a legitimate "no" that cannot
otherwise be told apart from "not asked yet". Anyone who finished setup
before a question existed is treated as complete, not sent back through
it.

## Personalised navigation

The bottom bar is the Environment plus the user's chosen features, in
registry order. There is no More, no Explore, no hub and no overflow: if
it is in the bar it is its own destination, and if the user did not choose
it, it is not in the bar.

**Routes and visibility are separate concerns.** Every feature's route is
registered permanently as a shell branch; preferences decide only what
appears in the bar. So removing the feature you are standing in bounces
you to the Environment immediately, and adding one back makes it reachable
there and then — with no router rebuild, which would otherwise tear down
the shell and close the panel mid-tap.

### Labels

The bar never truncates. It measures the real labels at the real text
scale and picks, in order:

1. Full names — `Environment · Meditation · Yoga`.
2. Each feature's deliberate short name — `Env · Med · Yoga · Chak ·
   Cycle · Cook · Garden · Nature`. Chosen words, not truncations.
3. A strip that scrolls sideways, with every destination still present at
   full size.

Whether a full eight-destination Almanac fits without scrolling depends
on the width and the rendered font; on a typical modern phone it does, on
a narrow one it scrolls. Items never shrink below the minimum touch
target to make room, and the bar grows taller for larger text rather than
clipping it. The visible label may be `Chak`; the accessibility label is
always `Chakras`.

## Meditation

Choose a practice, choose how long, tap the glowing orb. Everything else
disappears, there is one quiet second, and then the orb starts to breathe
with you. Bigger is in, still is held, smaller is out.

### The four practices

| | Rhythm | |
|---|---|---|
| **Focus** | 4 in, 4 held, 4 out | square breathing |
| **Sleep** | 4 in, 7 held, 8 out | a long out-breath |
| **Balance** | 4 in, 4 held, 6 out — each side | alternate nostrils |
| **Release Tension** | 4 in, 6 out | nose in, open mouth out |

### The rhythm is data

`BreathingStep` carries a phase, a length, an instruction, and — where a
practice needs them — a nostril and a countdown. `BreathingPattern` is an
ordered list of those, and `momentAt(elapsed)` is a pure function of the
time, so the orb and the words come from one source and cannot disagree.

The screen knows nothing about four seconds, or about squares, or about
which side of the nose Balance is on. It reads a `BreathingMoment` and
draws it. Adding a fifth practice is one entry in `MeditationTechniques`
and no change to the screen — there is a test that proves it, driving the
real screen with a pattern that ships nowhere.

Balance is deliberately *not* reduced to inhale/hold/exhale: the six
steps and their sides are the practice, so `Nostril` is part of the model
rather than a phrase the UI has to parse.

### One clock

A single `AnimationController` spans the settling second *and* the
session. Elapsed below one second is the pause; above it, subtract the
pause and hand the rest to the pattern. It exists only while a session
runs, and is stopped and reset the moment one ends.

`AnimationBehavior.preserve` matters more than it looks: left to its
default a controller shortens itself twentyfold when the device asks for
reduced motion — right for a transition, wrong for a clock, and it would
turn four minutes into twelve seconds.

### The immersive state

Once a session starts there is the orb, and a line of guidance below it
that arrives with each breath and fades. No title, no controls, no
progress, no remaining time — and no navigation bar either: a screen can
ask the shell to step back through `immersiveModeProvider`.

Tapping the orb ends the session. That is the whole of the exit: a
permanent Stop button would be the second-biggest thing in a room meant
to be empty. It is a labelled semantics button, so it is reachable
without sight, and a hint says so during the settling second.

- **Leaving ends it.** Backgrounding the app, or switching to another
  part of the Almanac, stops the session and returns to the setup. A
  session you cannot see is not happening. A notification shade
  (`inactive`) does not count as leaving.
- **Reduced motion.** The orb holds still and the words stay put instead
  of fading; the session still lasts its full chosen length.
- **What a screen reader hears.** The orb's painting says nothing — it is
  the same information, drawn. The guidance is a live region announcing
  the step once, with its length where the length is the point: "Hold, 7
  seconds", "Inhale through the left nostril". Balance's counted hold is
  announced once and then counted silently, inside the orb.

## The Almanac panel

A leaf mark at the top right of every screen opens a panel titled
"[Name]'s Almanac", or "Your Almanac" for someone who skipped the name.
It is not a tab and not a settings screen: Profile (the name), Location &
Region (hemisphere and location access, reusing the same widgets the old
standalone settings screen used), and Your Almanac (a switch per feature,
with the Environment listed as always on and no control to remove it).
Changes are written before the control moves, and take effect
immediately.

### Previewing palettes during development

In debug builds, the palette icon on the Environment screen opens a
preview screen (`/dev/theme`) for inspecting all eight combinations, the
semantic tokens and the environment the engine detected. It is not a user
setting and is absent from release builds.

## Design system

All colour, typography, spacing, radius, elevation, motion and icon-size
values are centralised in `lib/app/theme/`. Widgets should reference
these tokens (via `Theme.of(context)`, `context.palette`, or the `App*`
token classes) rather than hard-coding values.

## Testing

```
flutter test
```

603 tests. The ones worth knowing about:

- `moon_calculator_test.dart` checks the phase against twelve published
  new and full moons across three years.
- `solar_calculator_test.dart` checks sunrise and sunset against
  published times and against an independent closed-form day length.
- `palette_accessibility_test.dart` checks all eight palettes *and* forty
  points through each season's dawn/dusk blend.
- `environment_appearance_test.dart` renders the Environment in all eight
  season-and-phase combinations, at double text size, and with animations
  disabled.
- `navigation_labels_test.dart` checks the never-truncate rule as an
  invariant: for every plausible width, text scale and Almanac size, the
  chosen label is narrower than the item drawn for it.
- `onboarding_accessibility_test.dart` renders all four setup questions at
  1x, 1.5x and 2x text on a phone-sized viewport.
- `techniques_test.dart` pins all four practices, including that none of
  their descriptions claims to treat anything.
- `breathing_pattern_test.dart` checks the rhythms as arithmetic: phase
  order, Balance's six steps and its countdown, and that the breath never
  jumps by more than a thirtieth across two whole cycles of any practice.
- `meditation_screen_test.dart` drives whole sessions on the test clock —
  the one-second settle to the millisecond, phase progression, the chosen
  length, stopping, backgrounding, reduced motion — and asserts nothing
  is left ticking afterwards.
