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
you begin. **Yoga** is built too: three short practices, choose then
prepare then move. **Chakras** is a quiet visual pause — seven traditional
centres down an abstract body line, one at a time. **Cycle** records one
thing — the days you bleed — and counts quietly from them, beside the
real moon.
**Cookbook** is a small seasonal cookbook — sixteen recipes, four to a
season. **Garden** is a gardening almanac: what is worth sowing,
planting, tending, harvesting or pruning where you are, now, and a record
of what you actually grow. **Nature Log** is the last of them: a quiet
personal record of what you have noticed, beside a modest offline guide
to what is often about at this time of year — offered only where the app
actually knows the guide applies.

The Environment has depth as well as breadth: tapping its moon opens a
page about the moon, and from there — if Meditation is part of your
Almanac — a practice chosen for tonight's phase.

## Getting started

```
flutter pub get
flutter run
```

## One Almanac

The eight areas are not eight apps. They are views into the same current
moment, and the relationship is always the same:

```
CONTEXT   ->   GUIDANCE   ->   OPTIONAL DOORWAY TO AN ENABLED FEATURE
```

**Feature choices control the doorway. They never remove the guidance.**
The Moon's reflective practices still say "Meditate" when Meditation is
switched off; only "Try a meditation →" goes. This is a firm product
rule, and it is tested from both sides.

`lib/core/context/` is the seam that makes it possible without features
importing each other's widgets or stores:

```
AlmanacMoment       today · season · hemisphere · moon · daylight
                    composed from the existing providers, never a
                    second calculation, and never persisted
AlmanacFeatures     "is this feature part of the user's Almanac?",
                    asked one way, in one place
AlmanacIntent       why the user is going somewhere — a value, handed
                    off once and taken by the destination
AlmanacDoorway      a link that renders itself away when its
                    destination is not part of the Almanac
                    (lib/app/navigation/widgets/ — see below)
```

The dependency direction is `core/context -> app/navigation ->
features`, and a test greps `lib/core/` to keep it that way. An intent
is a value and core owns it; turning one into a journey needs the
navigation shell and a feature's branch, which are the app's business, so
`AlmanacDoorway` lives in the app layer rather than in `core/widgets/`.

`CyclePhase` lives in `core/context/` for the same reason: four features
now speak about a phase — Cycle works one out, and the Cookbook, Yoga and
Meditation each answer for what they would offer during it — and four
private copies of the word would be four vocabularies that can drift.
The *meaning* stays with each feature: Cycle owns how a phase is
estimated, the Cookbook owns which recipes suit one, Yoga owns which
practice, Meditation owns which breathing.

Where a feature needs another feature's *state* rather than a value —
"is there a cycle phase to answer for?" — the wire is soldered in
`lib/app/context/`, because the app layer is the composition root and
already knows every feature exists. `almanacCyclePhaseProvider` is the
one such seam today, and it exposes a phase or null.

Built pathways: Moon → Meditation; Cycle → Cookbook, Yoga and
Meditation.

### A feature that is switched off goes dormant

> **An optional Almanac feature that is turned off becomes dormant. Its
> locally stored data is retained unless the user explicitly deletes it,
> but other features do not read it while the feature is disabled.**

This is a standing rule for every cross-feature seam, not a detail of
Cycle. Removing a feature in Settings hides it and hibernates it; it does
not delete anything. Turning it back on finds the data where it was.

Three things follow, and each is tested:

- **the gate comes before the read.** `almanacCyclePhaseProvider` asks
  `featureAvailableProvider(FeatureId.cycle)` and returns null *without
  watching* Cycle's providers. Because Riverpod builds only what is
  watched, `cycleDataProvider` is never created and `CycleStore.read()`
  is never called. This is deliberately not "read it and throw the answer
  away": a store that is never opened cannot leak and cannot appear in a
  log. A counting fake store proves the read count is **zero** when the
  Cookbook, Yoga and Meditation are opened with Cycle switched off;
- **the gate is in one place.** The three consuming features take a
  `CyclePhase?` and know nothing about how availability is decided —
  a test greps them for `CycleStore`, `cycleDataProvider`,
  `displayedCyclePhaseProvider` and `FeatureId.cycle` and expects none of
  them. Four copies of the rule would be four places it could differ;
- **a phase carried in from a doorway is gated too.** The intent's phase
  is passed *through* the seam rather than preferred at the call site, so
  a screen cannot keep showing cycle content it arrived with after Cycle
  has been switched off.

The next cross-feature context to be built inherits this by using the
same seam: Garden off must mean the Cookbook never opens `GardenStore`,
in the same shape, for the same reason.

`currentMoonProvider` and `currentDaylightProvider` are **selectors**,
written the same way `currentSeasonProvider` already was: they prefer
the resolved environment and fall back to the same service it uses. A
screen that needs one fact watches one provider; `almanacMomentProvider`
is there for a screen that genuinely needs several.

An intent is deliberately thin. `MoonMeditationIntent` carries a
`MoonPhase` and nothing else, so the Moon page knows nothing about
breathing patterns and Meditation knows nothing about lunar copy — each
feature answers for its own half. The connections still to come (Cycle →
Cookbook, Yoga, Meditation; Garden ↔ Cookbook; Season → Garden,
Cookbook, Nature Log) are each one more subclass, with no new route and
no change to the navigation.

Nothing in the shared context is stored. There is no context history and
no snapshot: it is derived when asked and thrown away, so there is
nothing to leak, and there are no coordinates in it at all.

The visual and animation rules the whole app follows are written down in
[`docs/almanac_visual_language.md`](docs/almanac_visual_language.md) —
including the landscape geometry rule (the landscape is one place, and
its land never changes shape between seasons or between day and night)
and the animation principle: **nature moves, interface stays still.**

## Architecture

- `lib/app/` — app entry widget, router, and the central theme/design
  system (`lib/app/theme/`).
- `lib/core/environment/` — the natural environment: season, day/night,
  hemisphere, location and solar services. The single source of truth the
  theme (and later, features) read from.
- `lib/core/context/` — the shared Almanac context: the current moment,
  feature availability, and the contextual-intent model every
  cross-feature doorway uses. Depends on `core/environment` and
  `core/time`; knows nothing about any feature.
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
- `lib/core/time/` — the shared date seam every feature reads:
  `CalendarDate`, `MonthWindow`, the words for a date, and
  `todayProvider`. One date system, not one per feature.
- `lib/features/placeholder/` — one screen, driven by a
  `FeatureDefinition`, for a feature not yet built. Every feature in the
  registry now has a real screen, so `feature_screens.dart` maps all
  eight exhaustively and nothing reaches the placeholder; it is kept
  because the next feature added should not need a stub written for it.
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

### Backlog: the agreed location-refresh policy

Recorded here so the decision is not re-argued once a feature wants
fresher place data (tides being the first). **Nothing below is
implemented yet, and the current behaviour above is unchanged.**

- **One shared coarse location source** for the whole app. Not one per
  feature, and never a second permission flow.
- **Foreground only.** No background location, ever, under any feature's
  requirements.
- **One cached location, shared by every feature.** A feature never asks
  the platform directly.
- **Refresh no more often than roughly every 12 hours.** A person's
  coarse position does not change often enough to justify more, and
  each fix is a battery and privacy cost.
- **Sooner only on an explicit user refresh**, or on another strong
  shared trigger — a time-zone change being the clearest, since it means
  the device has genuinely moved.
- **Tide data freshness and GPS freshness are separate concepts.** Tide
  *data* may refresh far more often than the location it was computed
  for: a 12-hour-old coarse position is a perfectly good input to a tide
  prediction made a minute ago. Confusing the two is what would drag the
  app towards continuous positioning.

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

## Yoga

Choose → prepare → move. Three practices, a page each, and no library to
browse.

| | | |
|---|---|---|
| **Morning** | A gentle way to wake the body up. | ~5 minutes, 8 movements |
| **Ground** | Slower shapes for feeling steady again. | ~6 minutes, 8 movements |
| **Unwind** | Soft stretches for the end of the day. | ~5 minutes, 8 movements |

Every movement is a familiar one — seated breathing, mountain, a gentle
forward fold, cat cow, child's pose, a side stretch, a low lunge, a
gentle twist, rest. Nothing upside down, nothing that needs flexibility
or balance you might not have. There is no counting of anything: no
calories, no heart rate, no streaks, no scores.

### The sequence is data

`YogaStep` carries a pose, a length, an instruction, the shape to draw,
and — where they apply — a side and a breath. `YogaPractice` is an
ordered list of those, and `momentAt(elapsed)` is a pure function of the
time, exactly as `BreathingPattern.momentAt` is in Meditation. A
`YogaMoment` answers everything the screen shows: which movement, what to
do, which breath cue, how long is left, and "3 of 8".

The breathing is Meditation's, not a second engine: the flowing steps
carry a `BreathingPattern` built from the same `BreathingStep`, and the
figure's `openness` is the same number that drives the orb. Steps that
are simply held carry a one-line note instead, so nothing has to invent
a rhythm for a pose that does not have one.

`practices_test.dart` treats the content as data too, checking every
practice for length, for step lengths a beginner can hold, for both sides
of every sided pose, and for the absence of both clinical claims and gym
vocabulary.

### One clock, and the same immersion

A single `AnimationController` spans the whole practice, with
`AnimationBehavior.preserve` for the same reason as Meditation's. The
figure, the pose name, the instruction, the breath cue, the step timer
and the count through the sequence all come from its one value. No
`Timer.periodic`, no second clock, nothing to drift.

The words are driven off two `ValueNotifier`s rather than the raw
animation, so the instruction changes once a *movement* and the countdown
once a *second*, while only the flowing figures repaint per frame. That
is also what keeps a screen reader from being told the same thing sixty
times.

Immersion itself is shared: the lifecycle rules Meditation established —
enter and leave `immersiveModeProvider`, and *end* on backgrounding or a
tab switch, because a practice you cannot see is not happening — now live
in `ImmersiveSession`, which both screens use. Meditation was refactored
onto it rather than Yoga growing its own copy.

### While you are moving

Unlike Meditation, Yoga has to speak: you cannot follow a movement you
have not been told. So the practice screen keeps the pose name, one short
instruction, the breath cue where there is one, the seconds left in this
movement and "3 of 8" — all of it below the figure and quieter than it.
One `End practice` control, and nothing else. No pause, no skip, no
previous or next, and — everywhere in Yoga — no sound of any kind.

- **The figures are drawn.** `PoseFigure` paints each shape with Flutter
  primitives on a 100×100 grid, mirrored for the left side. No
  photography, no downloads, no external assets, and it says nothing to a
  screen reader: it is the same information, drawn.
- **Reduced motion.** The figures hold still and everything else works
  exactly as before, including the breath cue changing. It does not
  shorten the practice and does not introduce a second clock.
- **What a screen reader hears.** The movement and its instruction as one
  announcement — "Cat cow. On your hands and knees, slowly round and
  lengthen your spine." — on each new movement, not each frame.

## Chakras

Seven points down an abstract body line, the crown at the top and the
root at the base. Tap one to sit with it; sit with it long enough and
there is somewhere to write.

| | Sanskrit | Traditionally | |
|---|---|---|---|
| **Root** | Muladhara | grounding, stability and belonging | red, 4 points |
| **Sacral** | Svadhisthana | creativity, feeling and flow | orange, 6 |
| **Solar Plexus** | Manipura | personal agency, confidence and will | yellow, 10 |
| **Heart** | Anahata | compassion, connection and openness | green, 12 |
| **Throat** | Vishuddha | expression, truth and communication | blue, 16 |
| **Third Eye** | Ajna | insight, awareness and intuition | indigo, 2 |
| **Crown** | Sahasrara | contemplation, connection and transcendence | violet, a full ring |

### How it is framed

"In some traditions, seven centres are described along the body. They are
not measurements of anything. They are a way of pausing, one at a time."

That framing is the feature. Everything here is written as a traditional
association and never as a fact about the body: no diagnosis, no
treatment, no claim that anything is blocked or can be fixed. There is no
quiz, no score, no streak and nothing to complete.
`chakra_content_test.dart` reads every string the feature can show —
catalogue and framing copy alike — against a list of clinical words and a
list of gamified ones, so the wording cannot drift later.

### Colour that belongs to the season

The traditional hues are the one place chakras could have dragged an
unrelated aesthetic into the app. They do not: `chakra_accents.dart` holds
the seven as *illustration tokens* alongside the rest of the theme, and
the colour that actually gets painted is derived from the palette in
force. Take the traditional hue at the app's muted saturation, stir in a
little of the season's own primary, then move it away from the page until
it clears 3:1 as a graphical object. There are no hex values in any chakra
widget.

`chakra_accents_test.dart` checks all seven in all eight palettes and
forty points through a dusk blend: legible on the page, still recognisably
their own colour, and still distinguishable from each other.

Nothing depends on seeing them. Each chakra's symbol carries its
traditional petal count — four at the Root, sixteen at the Throat, two at
the Third Eye — so the seven differ in shape as well as hue, and the
colour is named in words on the page ("shown as green") as well as drawn.

### The artwork

Two custom painters and no assets. The overview is a single line with a
dome suggested at the top and a resting mark at the base, seven points
along it, and the words beside each one — abstract, with no anatomy
anywhere. The individual screen draws a ring of points around a quiet
centre with a soft radial halo. Both are `ExcludeSemantics`: everything
they carry is written out in real text.

### No clock, and no permanent ticker

Unlike Meditation and Yoga there is nothing here that runs, so Chakras
needs neither a session nor the immersive infrastructure, and the Almanac
panel stays reachable throughout. The two animations are one-shot
arrivals: the seven points rise into place from the base upwards, once,
and the symbol comes into focus when a chakra is opened. With reduced
motion both simply start where they finish. There is no `Timer.periodic`
and no repeating controller — the same rule the Environment screen has
kept since it was built.

### Reflections stay here, and only for now

Writing is optional everywhere: the prompt is an invitation, and pressing
**Save reflection** on an untouched field is a normal thing to do.

Reflections are held in memory for as long as the Almanac is open and are
**not persisted** — the screen says so in those words. The app's only
store holds one small settings object written whole, which is the right
shape for preferences and the wrong shape for somebody's private writing;
bending it into a journal, or adding a database for seven short strings,
is a decision that deserves its own step. What is true either way is the
part that matters: nothing written here leaves the device. No account, no
sync, no network, no analytics, and no new permissions.

## Cycle

Three layers, and they stay apart.

**Cycle home** observes the current cycle beside the real moon.
**Calendar** records bleeding — the only factual thing in the feature.
**Cycle Syncing** explores the current phase through food, movement and
reflection, with optional doorways into the rest of the Almanac.

Cycle is an **inner page of the Almanac**, so it is written on paper: the
same warm cream in every season and at every hour, no landscape, and no
dark version after dark. The Environment outside is the living painting;
this is the book.

### The bleeding model

The old model recorded one thing — the days a period began. That is no
longer enough, so records are now daily:

```
enum BleedingLevel { spotting, bleeding, heavy }

CycleDayRecord { CalendarDate date, BleedingLevel level, bool isPeriodStart }
```

The date is the id, so two records for a day are the same record. There
is deliberately **no `none`**: absence of a record *is* "nothing
recorded", so clearing a day removes its record rather than writing a
zero.

**Spotting is not bleeding, and never begins a cycle.** Somebody may spot
at any point in a month, and treating that as day 1 would silently
restart their cycle. So `BleedingLevel.canStartPeriod` is false for it,
the editor does not offer the control, and `CycleData` drops the flag
even if a caller — or an old stored line — claims otherwise. The product
example is a test:

```
2 Sep spotting · 3 Sep spotting · 4 Sep bleeding · 5 Sep heavy · 6 Sep bleeding
                                   ↑ cycle day 1
```

Day 1 is the 4th, not the 2nd, and every one of those five records
survives exactly as entered.

### Day 1 is the user's, and correctable

`isPeriodStart` is a property of a bleeding day, so there is one list of
days and no separate list of starts to fall out of step with it. The
editor shows **"First day of period"** as a plain switch for Bleeding and
Heavy bleeding, and never for Spotting.

The app offers a default — `looksLikeNewEpisode`, true when nothing was
recorded in the three days before — and that is **all** it is: the toggle
stays visible, the user decides, and changing it recomputes the cycle day
without touching a single bleeding record. Turning day 1 off leaves the
day recorded as bleeding with no cycle counted from it.

### Migrating Step 11

An installation may hold `cycle.periodStarts`. Each of those dates
becomes exactly one day of recorded bleeding marked as that period's day
1 — and **nothing else**. The following four days are not invented,
because the old data never claimed them. The assumed length is
preserved.

The migration is a pure function (`migrateLegacyStarts`), runs inside
`read()`, and removes the legacy key as part of the same write — so it
happens once and a restart finds nothing left to migrate. If the write
fails the old key survives and the next launch tries again. There are
twelve tests on it, including idempotence and that delete-all removes the
old key too.

### Cycle Home is always now

**CYCLE HOME = CURRENT LOCAL MONTH.** The central wheel is the month
containing `todayProvider`'s date, and there is no way to tell it
otherwise: `_Home` takes no month argument and derives one from today.

The Calendar's month arrows are therefore **Calendar state alone** — not
persisted, not in `CycleStore`, and dropped when the Calendar is left, so
each visit opens on the current month. Walking back to August to fill in
a missed week cannot leave Home sitting in August with no current-day
ring, and the user is never asked to press a "back to today" control that
should not need to exist.

Because `todayProvider` prefers the resolved environment's instant, and
the environment re-resolves at each day/night change, on its six-hourly
cap and whenever the app returns to the foreground, a phone left open
across midnight on 30 September shows October on the 1st by itself.

Records in other months are dormant on the wheel, never ignored: a Day 1
saved on 31 August still makes 20 September cycle day 21.

### The month wheel is a data visualisation

The wheel is a **lunar calendar for the current local month**: one
position per calendar date, 28 or 29 in February, 30 in September, 31 in
October. Each moon is the real phase for that date, from the app's one
moon service — asked at **local midday**, because a record is a date and
the service wants an instant, and midday is the furthest point from
either midnight. There is no second lunar calculation, and a test greps
the feature to keep it that way.

**Mathematical consistency outranks composition**, so the geometry is a
pure value (`CycleWheelGeometry`) and the properties that matter are
proved rather than eyeballed:

- **every moon has exactly the same diameter.** A new moon is not smaller
  for being dark, a full moon is not larger, and **today's moon is not
  larger either**;
- every centre is the same distance from the middle;
- the angular spacing is identical all the way round;
- the moons never overlap at any month length.

Today is marked by **one thin ring outside** its moon — a current-date
indicator, not part of the moon artwork. Twenty-three tests hold the
geometry, including all four month lengths and both February cases.

### One symbol language for bleeding

Three marks, defined once in `BleedingMarkers` and read by the wheel, the
legend and the calendar alike:

| | Inner dot | Extra ring |
|---|---|---|
| **Spotting** | 0.30 — visibly smaller | none |
| **Bleeding** | 0.52 | none |
| **Heavy bleeding** | **0.52 — the same** | **exactly one** |

Heavy differs from bleeding by the ring and by nothing else, so the eye
reads "more" rather than "different". A legend that disagreed with the
chart it explains would need a second set of numbers, and there is not
one.

### The Calendar

A month grid on the same paper, with arrows either side of the month
name. Tapping a date opens a sheet: None · Spotting · Bleeding · Heavy
bleeding, the Day-1 switch where it applies, Save, Cancel, and Remove for
a day that already has a record. **Saving returns to the Calendar**, not
to home, so five days in a row can be entered without navigating back in
each time — which is a test.

A day 1 adds a small "Day 1" caption *beside* its mark rather than
instead of it, and every day states its record in words: "4 September.
Heavy bleeding. First day of period." A future date is not tappable at
all.

### Cycle Syncing

The displayed phase, then six passages: **Focus · About this phase ·
Food · Movement · Mind · Duration**, separated by fine rules rather than
boxed into cards.

**The guidance always exists.** Feature choices control the doorways
underneath it and never the words: the food ideas are present with the
Cookbook switched off, the movement ideas with Yoga off, the reflective
line with Meditation off. That is the app's firmest product rule and
there are tests on both sides of every one of the three.

Menstruation offers iron-containing foods by name — spinach, silverbeet,
lentils, beans, tofu, eggs, red meat — and the vitamin-C pairing that
helps absorption, because menstruation involves blood loss and that is
worth knowing. It does **not** say anybody is deficient, needs a
supplement, or should follow a diet. No detoxes, no seed cycling, no
hormone-balancing foods, no guaranteed energy and no guaranteed mood —
each of those is a test.

### Adjusting the phase

The estimate can be wrong about somebody. So:

```
displayedPhase = manualPhase ?? calculatedPhase
```

Choosing a phase changes **what is displayed** and nothing else: no
record moves, no day 1 moves, and the estimate is still there underneath.
"Use automatic estimate" hands it back. A **new recorded period start
clears a stale override**, because that answer was about the cycle that
has just ended — and ordinary bleeding on a day that is not a day 1 does
not.

With nothing recorded at all, Cycle Syncing offers the four phases to
read about rather than guessing one, and says so: "There is no cycle to
count from yet. Choose a phase to read about it."

### The moon cycle type

An optional reflective reading, derived from the moon on the recorded day
1:

| | Moon at day 1 |
|---|---|
| **White Moon cycle** | new moon |
| **Red Moon cycle** | full moon |
| **Pink Moon cycle** | waxing crescent · first quarter · waxing gibbous |
| **Purple Moon cycle** | waning gibbous · last quarter · waning crescent |

Framed once, as a tradition: "In some modern spiritual traditions, the
moon a period begins under is given a name." Nothing about it is
persisted — it is derived fresh each time — so somebody can be one this
month and another next month, and the app says so: "It is derived from
each period you record, so it can be different next month. **None of the
four is better than another.**"

**Moon data is astronomy; bleeding is the user's record.** They are drawn
together and never conflated. Nothing anywhere says the moon moves a
cycle, that a cycle should match the moon, or that one alignment is
better — and a test checks for "should align", "in sync with the moon",
"back in sync", "ideal alignment" and nine more.

Cycle Syncing (menstrual, follicular, ovulatory, luteal) and the moon
cycle type are different concepts and stay in different places.

### Cross-feature pathways

Three typed intents, all carrying a `CyclePhase` and no strings. Each
destination owns its own answer, so Cycle never names a recipe, a pose or
a breathing pattern:

| From | To | Owned by | Mapping |
|---|---|---|---|
| Food | Cookbook | `CycleRecipes` | 5–6 of the sixteen recipes per phase, chosen for what is in them |
| Movement | Yoga | `CycleYoga` | menstrual → Unwind · follicular, ovulatory → Morning · luteal → Ground |
| Mind | Meditation | `CycleMeditations` | menstrual, follicular → Focus · ovulatory → Balance · luteal → Release Tension |

None of the destinations was redesigned and nothing was duplicated: the
Cookbook's cycle collection sits *under* the seasonal one and draws from
the same sixteen recipes; Yoga's three practices and Meditation's four
are untouched and all still offered.

Meditation can now hold **two independent contexts** — a moon and a cycle
— shown as two small suggestions under one restrained "For today". They
are two observations about the same day and are never combined into one
claim.

The phase reaches those three features through
`almanacCyclePhaseProvider` in `lib/app/context/`, which is null when
Cycle is not part of the Almanac or has nothing to say. The app layer is
the composition root, so that is where the wire is soldered: no feature
imports another, and a test greps the Cookbook's imports to prove it.

### Privacy, which is the whole architecture here

Cycle records are the most sensitive thing the app holds, so they get
their own everything: their own store (`CycleStore`), their own keys
under a `cycle.` prefix, their own serialisation, and their own
`deleteAll` that removes **every** key — records, length, chosen phase
and the legacy one — so nothing is left to say anybody ever used the
feature. **They are never put in `UserSettings`.** The store is opened on
first use, so somebody who never opens Cycle never has their records read
into memory.

Stored: `cycle.dayRecords`, `cycle.assumedCycleLength`,
`cycle.manualPhase`. **Not** stored, because all of it is derived: the
moon cycle type, the current phase, the next-period estimate, the current
moon, the season.

`CycleDayRecord.toString()` says nothing at all and `CycleData.toString()`
reports only how much it holds — a `toString` is exactly how sensitive
data ends up in a crash report — and there is a test that no `debugPrint`
in the feature interpolates anything but a type name.

Local only: no account, no cloud, no sync, no network, no analytics, no
external API, no location, no microphone, no camera, no background work,
no notifications and no new permissions.

### Dates are dates, not instants

`CalendarDate` is a year, a month and a day, with no time and no zone. A
period began on the fifteenth of July wherever the phone happens to be,
and storing that as an instant is how a date ends up shifting to the day
before because somebody flew west or the clocks went back. Its arithmetic
goes through UTC internally, so adding a day is always exactly a day —
there is a test that walks it across both British daylight-saving
changes.

### The estimate, and the model

Everything past the recorded day 1 is an estimate and is labelled as one.
The length is the user's own choice, 21 to 40 days; changing it changes
estimates only, and the note under the stepper says so.

| Phase | 28-day cycle | Rule |
|---|---|---|
| Menstrual | days 1–5 | always, since bleeding length is not recorded |
| Follicular | days 6–13 | whatever is left before the window |
| Ovulatory | days 14–16 | three days from `length − 14` |
| Luteal | days 17–28 | the day after the window, to the end |

A window rather than a claimed day, because a single day would be a claim
this app cannot make. It is not a fertile window and is never called one.

**What is recorded and what is estimated stay apart.** A day inside the
estimated menstrual span is not drawn or described as bleeding unless the
user recorded it — `CycleMoment.recordedToday` is the factual half and
`phase` the estimated one, and there is a test for exactly that
distinction.

### What it does not do

No fertility prediction, no probability of anything, no ovulation
diagnosis, no pregnancy, no contraception, no symptom tracker, no mood
log, no medication log, no body metrics, no score, no streak, no
notifications, no export, no sharing. It makes no medical claim and never
says a calculated date is certain.

It also does not plaster the screen with disclaimers. "Estimated" is said
where a value is genuinely estimated; the claims are kept out of the
content rather than apologised for, and one honest line — "Your
experience may be different." — is enough.

## Cookbook

What could I make with the season I'm in? Four collections, four recipes
each, bundled with the app. No search, no filters, no favourites, no
network, no account, no storage of any kind — it does not even record
which recipes were looked at.

| | | |
|---|---|---|
| **Spring** | Pea and mint soup · Spring greens frittata · Lemon and herb roast chicken · Strawberry and rhubarb crumble |
| **Summer** | Tomato and basil pasta · Grilled summer vegetables · Sweetcorn and chickpea salad · Roasted stone fruit with yoghurt |
| **Autumn** | Pumpkin soup · Roasted root vegetables with lentils · Mushroom and barley risotto · Apple and oat bake |
| **Winter** | Leek and potato soup · Slow vegetable and bean stew · Kumara and chickpea curry · Warm pear and oat pudding |

### The season comes from the Environment

The Cookbook asks `currentSeasonProvider` which season the user is
actually in — real astronomy, their own hemisphere — and marks that one
**"Your season"**. There is no second season calculation anywhere in the
feature and no northern-hemisphere default: the same instant in January
opens on winter in London and on summer in Auckland, and there is a test
that checks exactly that.

Browsing another season is only browsing. It changes what the screen
lists and nothing else: the marker stays where it is, nothing is written
down, and the Environment is untouched.

### What it does not claim

The app knows the season. It does not know what is growing near anybody,
what the shops have, or what the weather did to the crop this year. So a
collection is *"A seasonal collection for winter. Recipes inspired by
winter ingredients, wherever you are."* — never "in season near you".
`recipe_content_test.dart` checks for that phrasing and for its absence.

That test also reads every recipe and every line of copy against three
lists: health claims (detox, immunity, anti-inflammatory, healing…),
counting language (calories, macros, low-fat…), and food moralising
(guilt-free, cheat, clean eating, healthy/unhealthy). And it checks the
ingredients themselves: no alcohol, no peanuts, nothing needing equipment
an ordinary kitchen does not have.

Those checks are **ingredient-aware, not word-blind** — see
`test/support/culinary_words.dart`. A word list on its own rejects real
food whose name merely contains an awkward word, and the rejections look
authoritative. So each check rewrites the compounds a cook would
recognise before it looks for anything: **red wine vinegar** is vinegar
(the alcohol is fermented away), **butter beans** are lima beans,
**coconut milk** is not dairy, an **eggplant** is not an egg, **cream of
tartar** is a raising agent, and **crumbled** feta contains no rum. Then
it matches whole words only, so a future recipe may describe a cured ham
without tripping "cure" and a carbonara without tripping "carb". A real
bottle of wine, a real block of butter and a real jug of buttermilk are
all still caught, and there are tests in both directions.

### Recipes as data

`Ingredient` is structured — a quantity, an optional unit, a name — and
renders itself: "1 tbsp olive oil", "500 g pumpkin", "2 eggs",
"Salt and pepper, to taste". Halves come out as halves (`1/2 tsp`), not
as `0.5`. The rule the tests hold is that an ingredient either says how
much or says the cook decides; never nothing at all.

Times are `Duration`s, never strings, so a card can say "About 45
minutes" and the page "15 minutes" and "30 minutes" without the two ever
disagreeing. Method steps are stored as an ordered list of instructions
and numbered from that order — `MethodStep` is a derived view, so the
numbers cannot drift out of step with the list. Quantities are fixed:
there is no serving multiplier in this version.

Dietary tags are deliberately only **Vegetarian** and **Vegan**. "Gluten
free" and "dairy free" are claims about safety this app is in no position
to make, so the ingredient list is the whole of what Cookbook says about
what is in a dish. A test cross-checks each tag against the ingredients
in both directions: a tagged recipe must contain nothing that
contradicts it, and an untagged one must contain something that does.

### Drawn, not photographed

Every card carries a small botanical sprig painted with Flutter
primitives: spring puts out new leaves and a bud, summer is broad-leaved
with something round ripening, autumn has a leaf on its way down, winter
is a bare twig with buds waiting. The four recipes in a collection lean
slightly differently, so a page of cards is not stamped. No photographs,
no assets, no network images.

Cards are the colour of their season even when it is not that season.
`season_illustration.dart` adds two illustration tokens to the theme —
`seasonWash` for the card ground and `seasonInk` for the sprig — both
derived from the same eight designed palettes and taken at the *active*
palette's time of day, so a winter card in midsummer is still winter but
is lit like the page it sits on. The wash backs its tint off in steps
until body text on it clears 4.5:1, and in the worst case is simply the
ordinary card colour; the ink is pushed to 3:1 against whatever wash it
lands on. `season_illustration_test.dart` holds both floors across all
eight palettes and all four seasons. There are no hex values in any
Cookbook widget.

The recipe page is calmer: a small sprig, then the description, then the
times and servings, then ingredients, then method. Nothing to scroll past
to reach the cooking.

### Accessibility

A card is one button saying everything it shows — "Pumpkin soup. Autumn
recipe. A simple warming soup, smooth and golden." Season chips carry a
real selected state plus a tick and a border, and the user's own season
says "Your season" in words, so nothing depends on noticing a tint. Each
method step is its own announcement ("Step 3. Add the pumpkin and the
stock."), and prep, cook and servings have spoken labels rather than bare
numbers. Recipe names wrap rather than truncate at 2× text. The sprigs
say nothing.

The one animation is a one-shot growth of the sprigs when a collection
appears; reduced motion draws them already grown. No ticker, no session,
no immersion.

## Garden

Given where I am, what time of year it is, and what I actually have
growing — what is worth doing now? Six chapters: **Sow · Plant · Tend ·
Harvest · Prune · My Garden**.

### The layering, which is the whole design

```
Environment            location, hemisphere, astronomical season, today
        ↓
GardeningGuide         a broad climate band — never a claim about a garden
        ↓
+ the plant book       static rules: month windows, methods, cautions
        ↓
GENERAL guide          Sow · Plant          — discovery, the whole book
        +
My Garden              what the user actually grows
        ↓
PERSONALISED guide     Tend · Harvest · Prune
```

That split is the feature. `generalGuideFor(guide, today)` never looks at
My Garden; `personalGuideFor(guide, today, garden)` cannot produce
anything that is not in it. Tomatoes are generally harvestable in
February — and if you do not grow tomatoes, Harvest does not mention
them. Both are pure functions of their arguments, which is what lets the
tests walk a year a month at a time.

Garden calculates no season, no hemisphere and no date of its own: it
reads `currentSeasonProvider`, `locationStateProvider`,
`resolvedHemisphereProvider` and `todayProvider`, the same values the
Environment screen shows. There is a test that greps the whole feature
for `DateTime.now`, `seasonAt(`, `ofLatitude` and `Geolocator` and fails
if any of them appear.

### Gardening regions

Latitude and longitude are not a gardening recommendation, so an explicit
band sits in between. Inside New Zealand's bounding box, coarse location
gives one of three, split at 38°S and 42°S:

| Band | Roughly | Offset |
|---|---|---|
| **Warm northern New Zealand** | Northland, Auckland, Coromandel, Bay of Plenty | a month earlier |
| **Temperate New Zealand** | Waikato to Wellington, Nelson, Marlborough | the baseline |
| **Cooler southern New Zealand** | most of the South Island | a month later |
| **General Southern / Northern Hemisphere guide** | no location shared | baseline / half a year across |

Every window in the plant book is written once, for the temperate middle,
and each band says how far it sits from that — which is how New Zealand
gardening advice is actually phrased ("a month earlier in the far north").
Rules anchored to the calendar rather than the season opt out: garlic goes
in around the shortest day wherever you are.

**What is deliberately missing.** NZ guides usually add an inland/cold
band for Central Otago and the high country. That band is defined by
elevation and shelter, not latitude — Alexandra and Dunedin share a
latitude and garden a month apart — and the app has coarse location and no
elevation. Inventing it would be inventing precision, so it is left out
and the cool-south guidance is written conservatively. Hamilton falling in
the warm band is the same limitation, and there is a test that says so out
loud rather than pretending otherwise.

Outside New Zealand there is no regional model yet, so a shared location
degrades honestly to the generic guide for that hemisphere.

### When location is off

Garden works. It uses the hemisphere the user chose, names it — "General
Southern Hemisphere guide" — and adds "Location is off, so these
suggestions are broader." It never asks for permission on arrival, and
there is a test asserting the location service is not called. No new
permission was added: coarse location only, as before.

Every page carries the honest limit: *"Based on your general area and the
time of year. Local conditions can shift planting and harvest times."*

### The plant book

57 plants — 24 vegetables, 13 fruit, 10 herbs, 10 flowers — carrying 166
structured rules between them. Static, bundled, offline; no plant API and
nothing to fetch.

A rule is data, not a sentence: an action, a month window, a region set, a
sowing method, the establishment state a plant must have reached, a broad
minimum age, and a caution. `GardeningRule.sow` requires a method;
`GardeningRule.tend` requires both an action and a state;
`GardeningRule.prune` requires a caution — the constructors make the
invariants unforgettable, and there are tests for each.

**Where the windows come from.** Each plant's months are the common ground
between the standard New Zealand home-gardening references — seed-packet
sowing charts, the month-by-month calendars the seed companies publish and
the regional planting guides — reconciled conservatively: where sources
disagreed the narrower window was kept, and a marginal month was left out.
They are broad on purpose. Nothing here is a day-level claim.

Pruning is the part of the dataset where bad timing does lasting damage,
so the tests pin the ones that matter: stone fruit are pruned in the warm
months and **not** in winter (silver leaf), pip fruit are pruned in
winter, lavender is never cut into old wood, and every pruning rule
carries a qualification.

### My Garden

A practical plant collection, not a virtual scene. Add from Sow — which
records the plant, today's date and "sown" without asking anything — or
add something already growing, which asks the one useful question: *"How
is it in your garden?"* Recently sown, seedling, or established. A date is
optional and **unknown stays unknown**; nothing is filled in with a guess.

One entry per plant type in this version. The model carries an
`instanceId` anyway, so allowing several later is a UI change rather than
a file-format change.

**Nothing derived is stored.** "Harvest now" is never persisted: it is
recomputed from the plant, the date and the band every time it is asked,
so the recommendations change as the year does. Persistence lives in a
dedicated `GardenStore` behind its own `garden.plants` key — never in
`UserSettings` — with one line per plant
(`plantId|added|state|sown|planted`) so a corrupt line costs its own entry
and nothing more. **No coordinates are ever stored**, and there is a test
that reads the data layer to prove it.

An id this version has never heard of is **kept in storage and left out of
what is shown**, so a garden written by a later version survives a
downgrade instead of being quietly deleted.

### Recommendations, not commands

"Can be sown now." "May be ready to harvest." "Typically pruned around
this time." Never "your tomatoes are ready" — the app cannot see the
plant. Each personalised item says why it is there in plain words:
*"Relevant now because: February · sown 19 weeks ago"*, or *"February ·
established in your garden"* when no date was recorded. A minimum age is
applied only when the user actually recorded a sowing date; with no date,
the calendar window carries the recommendation on its own rather than the
app pretending to know.

No points, streaks, levels, badges, achievements, rewards or completion
percentages. `plant_book_test.dart` reads every sentence the feature can
show against a list of promises ("guaranteed", "will grow", "perfect
conditions", "must") and a list of game words.

### Drawn, not photographed

Ten forms — leafy green, root, climber, fruiting, bulb, herb sprig, shrub,
tree, flower, vine — painted with Flutter primitives, with a small
deterministic variation per species so a page is not stamped. Sixty
hand-drawn portraits would be a painter layer bigger than the feature and
still would not be how anybody identifies a plant: the **name** does that,
and the name is always there in text. The marks are `ExcludeSemantics`.

One one-shot growth animation when a list appears; reduced motion draws
the marks already grown. No ticker, no `Timer.periodic`, no immersive
mode, no session.

### Accessibility

A chapter card is one button: "Harvest. What in your garden may be ready."
A plant in the book is "Pea. Vegetable. Sow outdoors." A My Garden entry
is "Apple. Established." A suggestion is "Tomato. Vegetable. May be ready
to harvest." Nothing depends on colour, an icon, a drawing or a season
tint. The way back sits *above* a chapter's list rather than below it — a
control at the far end of a long list is a control nobody can reach — and
every target clears 48 dp. Plant names wrap rather than truncate at 2×
text.

## Nature Log

What have I noticed around me, and what is happening in nature at this
place and time of year? Two routes and a way in: **Around now**, **My
observations**, and **Record something**.

The two halves never blur. *Around now* is the guide talking: what the
Nature Book says is often about this month, where the book has coverage.
*My observations* is what the user actually saw. A suggestion is never
counted as a sighting, and nothing in the log is ever inferred.

It is not a social network, a species list to complete, a citizen-science
upload, or an identifier. There is no camera, no photo recognition, no
birdsong recognition, no map, no geotag, no sharing and no rarity score.

### The coverage model, and why it is two states

Gardening bands are about climate: frost dates and season length, and
they shift a planting window by a month. What lives where is a different
and much harder question — kererū are nationwide, pōhutukawa is naturally
northern, and the line between them is not a latitude. So Nature Log
deliberately does **not** reuse `GardeningRegion`. It has its own
`NatureCoverage`, and that enum has exactly two values:

```
newZealand    'New Zealand guide'
unsupported   'No regional guide yet'
```

The bundled content is the common ground — species most people anywhere
in New Zealand can meet — so the honest model is "the guide covers this,
or it does not". Inventing ecological subregions from a coarse position
would be inventing precision.

`NatureGuide.resolve` takes a `LocationState` **and nothing else**:

| Input | Coverage | Source |
|---|---|---|
| Position inside a generous box around New Zealand (including Stewart Island and the Chathams) | `newZealand` | `location` |
| Position outside it | `unsupported` | `location` |
| No position resolved, whatever the hemisphere | `unsupported` | `noLocation` |

**A hemisphere is not evidence of a country.** This is the line the
feature holds, and it is worth stating precisely, because the two halves
look similar and are not:

- **Astronomical season can be known from hemisphere.** It is a fact
  about the sun and the date. The Environment, the Cookbook, the Garden
  and Nature Log's own context line all read it from
  `currentSeasonProvider`, which resolves through
  `resolvedHemisphereProvider`, and that is correct.
- **Ecological regional coverage cannot.** Somebody in Australia, Chile
  or South Africa can choose the southern hemisphere and decline
  location. Offering them New Zealand's birds would be claiming to know
  something the app has not been told. Nature Log follows the Almanac
  principle: *do not infer more environmental knowledge than we actually
  have.*

So the hemisphere is not a parameter of `resolve` — not merely unused,
but absent, so it cannot quietly become a fallback again. There is a
test that greps the file (comments stripped) for the word, and one that
asserts the two hemispheres with no position produce the *identical*
`NatureGuide` while still producing different seasons.

Coverage gates suggestions and nothing else. With no location the user
can still record something, browse the whole Nature Book, record from
it, write a custom observation, and view, edit, delete and clear their
log. Only Around now is unavailable, and the screen explains that once,
quietly, without a prompt and without a button:

```
Your Nature Book does not know which regional guide applies here yet.
You can still record whatever you notice — the log is yours, wherever
you are.
Location is off, so seasonal species suggestions are not being shown.
```

The third line appears only when the reason is that no position was
resolved (`isUnlocated`) — somebody with a London fix is outside the
coverage, not unlocated, and has nothing to be told about location. A
test asserts the page contains no "enable", "turn on" or "allow
location" wording anywhere.

**Browsing the book is not a claim about here.** The bundled New Zealand
catalogue stays fully browsable and recordable wherever the user is,
because reading a reference catalogue is a different act from being told
its species are around you now. The recording page says which it is —
"The whole Nature Book is here to read and record from, wherever you
are." — and that distinction is tested on both sides.

### The Nature Book

Fifty entries on five shelves: 16 birds, 15 plants, 11 insects, 5
fungi and 3 others (a skink, an eel and a spider — a spider is not an
insect, and nobody noticing one wants to be told so). Each entry has a
primary name, an optional alternate name, an optional scientific name, a
short description and one or two seasonal notes. The primary name is the
Māori one where there is one, and the model does not force an English
name to exist: "Pīwakawaka · Fantail", but also just "Tūī".

Seasonal notes are conservative by construction. A `NatureNote` carries a
`NatureNoteKind` — *Often flowering*, *Often fruiting*, *Often arriving*,
*Often more active*, *Worth listening for*, *Often appearing* — and a
`MonthWindow` that may wrap the year. The app knows the month and,
broadly, the country. It has not seen the tree, the weather or the bird.
So a note says what *often* happens around a time of year, and
`nature_content_test.dart` fails on "you will see", "guaranteed" or
anything else that turns an invitation into a promise.

The fungi shelf says what it is not, on every page it appears on: "This
is a guide to noticing, not to foraging. It says nothing about which
fungi are safe." No entry mentions edibility, toxicity, picking or
cooking, and there is a test for each of those words.

### Observations

```
NatureObservation   instanceId, date, category, label, order,
                    itemId?, note?, placeLabel?
```

`label` is always present, even for a book entry, and that is the
migration policy: the display name is written down at the moment of
saving. An observation of an entry this version of the app has never
heard of still reads as what the user saw rather than as a missing row,
so a Nature Book that changes underneath the log — or a log written by a
later version and read by an earlier one — costs nothing. An unknown
`itemId` is kept, not dropped.

The only thing recorded automatically is the calendar day, from the same
`todayProvider` Cycle and Garden read. A place is optional, typed by the
user in their own words, and never geocoded. **No coordinates are stored,
ever** — the store is grepped for `latitude`, `longitude` and
`GeoLocation` with its own comments stripped first, and a test records an
observation with a live Wellington fix and then reads the stored bytes.

Storage is a dedicated `NatureLogStore` behind its own
`natureLog.observations` key — never `UserSettings` — one line of JSON
per observation. JSON rather than the Garden's pipe-separated line
because these records hold free text: a note reading "on the fence | by
the shed" has to survive being written down. Still one line each, so a
line that will not parse is dropped on its own and costs nothing but
itself. "Clear my Nature Log" removes the key.

### No gamification

There are no streaks, badges, points, levels, challenges, goals,
rankings or celebrations, and nothing says "complete your log". The one
count anywhere is a single line — "5 things noticed this spring." — which
disappears at zero and is not a total anybody is asked to beat. A
free-text observation and a book one look identical in the list, because
they are worth the same.

### Drawn, not photographed

Seven painted forms — bird, leaf sprig, flower, insect, butterfly,
fungus and a fallback — with a small deterministic variation per entry
taken from its id, so the same entry always looks the same and a page is
not stamped. Nobody identifies a tūī from a forty-pixel drawing: the
**name** does that, and the name is always there in text. The marks are
`ExcludeSemantics`.

Nature moves; the interface stays still. There are no fluttering wings
and no drifting leaves. The one movement is a single settle when a list
first appears, reduced motion skips even that, and the screen tests
assert nothing is left ticking afterwards.

### Accessibility

A route card is one button: "Around now. What the guide says may be worth
noticing." A book entry is "Pīwakawaka, Fantail. Bird." A suggestion adds
its reason: "Tūī. Bird. Often busy around flowering kōwhai in spring." An
observation is "A moth. Insect. Recorded 15 October." The way back sits
*above* a page's list rather than below it, every target clears 48 dp,
and names wrap rather than truncate at 2× text.

## The Moon, inside the Environment

The moon on the Environment page opens a page about the moon. It is
**not** a feature: no tab, no `FeatureId`, no onboarding question, no
entry in the registry. It is a child route of the Environment's own shell
branch (`/environment/moon`), which is what gives it the right behaviour
for free — Back returns to the Environment, the navigation bar stays put
with the Environment still selected, and there is no second navigator.
The only change to the Environment screen itself was making its existing
moon section tappable; nothing moved.

The page is the reference implementation of the **detail-page rule**:
paper ground, one illustration, fine rules between passages, and mostly
space. No landscape, no flowers around the moon, no botanical wreath, no
forest, no seasonal background painting.

**The Environment changes with the world outside; the pages inside the
Almanac remain paper.** The ground is one fixed warm cream —
`AlmanacPaper.ground`, the single token — in every season and at every
hour. There is no night paper and no seasonal paper: opening a detail
page should feel like turning to a page of a physical almanac, not like
stepping outside again. `AlmanacPaperSurface` re-prints the active
palette onto that sheet (`AlmanacPaper.reprint`), so a page inside it
uses `Theme.of(context).textTheme` and `context.palette` exactly as any
screen does and gets paper ink for free — which is how Cycle, a recipe,
a plant or a Nature Log entry will share the same inner-page language
later. The season is still present in the accents, re-based by
`AlmanacPaper.accentOn` so a winter night's primary is legible on cream.
Tested: one ground across all eight palettes, unchanged between day and
night and across the four seasons, body text at 4.5:1 and every usable
accent at 3:1, and the paper colour written down nowhere but its token.

### Two layers

**What the moon is doing**, from `currentMoonProvider` — the same
astronomy the Environment page shows, not a second moon system. The
phase, the illuminated percentage, and whether it is waxing or waning,
with the lit side turned over for a southern observer. The timing of the
next major phase is **deliberately absent**: the existing calculation
resolves a phase at an instant rather than searching for the instant a
phase begins, and a guessed date would be worse than a gap.

**What somebody might do with it**, as eight structured reflections — a
theme, an explanation, four words, and a handful of practices. The
tradition is named **once**, at the top of the reflective passage — "In
some modern spiritual traditions, the phases of the moon are used as
moments for reflection." — and every phase underneath is then simply
written. There is no science disclaimer and no paragraph that opens by
apologising for itself: the two halves are told apart by tone, and the
screen reads like an almanac rather than a policy document.
`moon_content_test.dart` still fails on any causal biological, hormonal,
menstrual, fertility, emotional, personality or medical claim — the
exclusions hold, they are simply not something the reader is told
about.

**Astronomy and cycle records are separate things** and stay that way.
The moon's phase is the same for everybody on Earth tonight; a cycle is
something the user recorded. The Moon page does not mention a cycle at
all — there is a test — and the app never says one moves the other.

### Moon → Meditation

The first cross-feature pathway. When Meditation is part of the Almanac,
the Moon offers "Try a meditation →", which carries a
`MoonMeditationIntent` into the **normal** Meditation screen. There is no
duplicate screen, and none of the four practices — Focus, Sleep, Balance,
Release Tension — is removed or changed.

Meditation's answer is the smallest coherent one: each phase points at
**one of the four practices that already exist** plus one line saying why
it suits this moon. No ninth breathing pattern, no new engine. Arriving
from the Moon, the block is headed "For today's New Moon"; opening
Meditation from the navigation bar, the same suggestion appears under the
quieter "For today", because the context is true either way and only the
wording knows how you got there.

The intent is a hand-off, not stored state: it is taken on arrival and
emptied on the next frame, so leaving and returning never finds
yesterday's moon still waiting.

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

The full visual language — the rules a page is drawn to, not a mood
board — is [`docs/almanac_visual_language.md`](docs/almanac_visual_language.md).
The short version:

- **ENVIRONMENT IS OUTSIDE. DETAIL PAGES ARE THE BOOK.** The two worlds
  are separated in exactly one place, `screenForFeature`: every feature
  except the Environment is wrapped in `AlmanacPaperSurface` there, so a
  chapter cannot forget to be paper.
- **Two grounds, three inks, two rules** (`AlmanacPaper`). No pure black;
  the inset ground is darker than the paper, never lighter, because a
  lighter patch reads as a card floating above the page.
- **A screen asks for a role, never for a size** (`AlmanacTextRoles`):
  `pageTitle`, `eyebrow`, `sectionLabel`, `journalNote`, `valueText`,
  `navigationLabel` and the rest. No feature file constructs a
  `TextStyle`.
- **Two scaffolds, one composition**: `AppScaffold` opens a chapter,
  `AlmanacPage` is a page inside one with a way back. Both put the title
  over a short hairline and are tested at 2× text.
- **A label, some space and a rule** before a box. `AlmanacInset` is the
  only container, and it has no shadow.
- **Actions size to their content.** Three weights, quietest by default;
  48 dp minimum; selection never carried by colour alone.

### Fonts: bundled or nothing

The app previously depended on `google_fonts`, which **downloads its
faces from `fonts.gstatic.com` at first use** unless the files are also
bundled and runtime fetching is disabled — neither of which was true
here. In an app whose architecture is "no network, nothing leaves the
device", that was a real regression, and the source file next to it
claimed in prose that fonts were never fetched.

The dependency is gone. `lib/app/theme/almanac_fonts.dart` is the only
place a typeface is chosen, it currently resolves to the platform's own
serif and UI faces, and a test greps `pubspec.yaml` and `lib/` — with
comments stripped, so an explanation cannot be mistaken for a dependency
— to keep the claim and the code together.

**To ship the hand-lettered display face the references are set in:**
put the licensed files in `assets/fonts/`, complete the commented block
in `pubspec.yaml`, and set `AlmanacFonts.bundledDisplay`. Nothing else
changes. Body copy stays in the platform text face either way —
readability is not something the Almanac trades for character.

## Testing

```
flutter test
```

1,614 tests. The ones worth knowing about:

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
- `yoga_practice_test.dart` walks every practice second by second: step
  boundaries to the second, the countdown, the breath cue measured from
  the start of its own step, and the same code driving a practice that
  ships nowhere.
- `yoga_screen_test.dart` runs whole practices on the test clock —
  progression, the step timer, completion, stopping, backgrounding, a tab
  switch, reduced motion, double text size — and asserts nothing is left
  ticking afterwards.
- `chakra_content_test.dart` pins the seven, their order and their
  wording, including that nothing the feature can say sounds clinical or
  gamified.
- `chakra_accents_test.dart` checks every chakra colour in every palette
  and through a dusk blend: legible, recognisable, and distinguishable
  from the other six.
- `chakras_screen_test.dart` opens each of the seven in turn, writes and
  discards reflections, and checks the touch targets, the semantics, 2x
  text and that nothing is animating once the screen has arrived.
- `calendar_date_test.dart` checks date arithmetic across month, year and
  leap-year boundaries, and across both British daylight-saving changes.
- `cycle_calculator_test.dart` walks a whole cycle a day at a time, pins
  every phase boundary at 21, 28 and 40 days, and greps the domain for
  anything that predicts fertility or reads a clock.
- `cycle_bleeding_test.dart` is the model under test: three levels
  recorded, changed and cleared; the product's own example proving day 1
  is the 4th and not the 2nd; a month of spotting leaving the cycle
  exactly where it was; day 1 corrected in both directions without
  erasing a record; the override changing only what is displayed; and a
  restart keeping every level and flag.
- `cycle_migration_test.dart` seeds Step 11's keys and proves the
  migration: both starts preserved as day 1, one bleeding record each,
  **no invented following days**, the assumed length kept, idempotent
  across three reads and two store objects, and delete-all removing the
  legacy key too.
- `cycle_wheel_geometry_test.dart` is the mathematics, not a screenshot:
  28/29/30/31 positions, identical angular spacing all the way round,
  every centre at one radius, one moon diameter for every phase and for
  today, no overlap at any month length, spotting smaller than bleeding,
  heavy identical plus exactly one ring, and the legend reading the same
  specs as the wheel.
- `cycle_moon_test.dart` pins the classification both ways — new → White,
  full → Red, the three waxing → Pink, the three waning → Purple, all
  eight phases accounted for once — proves no type exists without a day
  1, that it changes when a later cycle begins under another moon, that
  nothing about it is persisted, and that the wheel and the type ask the
  one moon service at the same local-midday instant.
- `cycle_content_test.dart` reads every string the feature and its three
  answers can say: no detox, no seed cycling, no hormone-balancing foods,
  no guaranteed energy or mood, no fertility or pregnancy, no diagnosis,
  no moon-caused menstruation, no ideal alignment and no ranking of the
  four moon cycle types — and, in the other direction, that it does not
  bury the screen in disclaimers either.
- `cycle_navigation_test.dart` walks Cycle Syncing → Cookbook, → Yoga and
  → Meditation: the phase arrives, the destination's own answer is shown,
  every existing practice and recipe remains, the intent is consumed, and
  a later direct entry has current context rather than a stale journey.
- `cookbook_cycle_test.dart` proves the recipe mapping belongs to the
  Cookbook — Cycle names no recipe id and the Cookbook imports no Cycle —
  that every mapped id exists with no duplicates, and that every recipe
  in the menstrual collection genuinely carries lentils, beans,
  chickpeas, greens, eggs or meat rather than being there to fill a
  count.
- `cycle_screen_test.dart` drives all three layers through the real
  screens: home's simplicity (and that no food, movement or recipe copy
  is on it), the same paper by day and night and in all four seasons,
  five consecutive days entered without leaving the Calendar, the Day-1
  control present for bleeding and absent for spotting, all four phases
  of Cycle Syncing, and every doorway appearing and disappearing while
  the guidance stays put.
- `recipe_content_test.dart` reads all sixteen recipes: four to a season,
  stable ids, real quantities and units, numbered method steps, and no
  alcohol, peanuts, health claims, calorie language or diet talk — with
  its own regression group pinning both sides of every borderline case
  (red wine vinegar passes, white wine does not; butter beans pass,
  buttermilk does not).
- `season_illustration_test.dart` checks every recipe-card colour in
  every palette: body text legible on the wash, the sprig legible on the
  card, and the four seasons still distinguishable.
- `cookbook_screen_test.dart` opens all sixteen recipes through the real
  screens and checks that the "Your season" marker follows the
  hemisphere rather than the month.
- `garden_guide_test.dart` is the personalisation proof: tomatoes are not
  in Harvest until they are in My Garden, they leave when the month
  moves, and they stay in the garden either way. Same for Tend and
  Prune.
- `garden_environment_test.dart` checks Garden agrees with the
  Environment — hemisphere, season, date and band — that it never asks
  for location, and that it calculates none of those itself.
- `plant_book_test.dart` checks all 57 plants and 166 rules, including
  that stone fruit are not pruned in winter and that every pruning rule
  carries a caution.
- `garden_store_test.dart` drives the real store through a restart, drops
  malformed lines one at a time, preserves ids it does not recognise, and
  proves no coordinate is written.
- `nature_content_test.dart` reads all 50 Nature Book entries and every
  fixed string the feature can say: Māori-first naming, real month
  windows, no certainty language, no foraging language on the fungi
  shelf, no score-keeping, and no editorialising about introduced
  species.
- `nature_log_environment_test.dart` proves the shared seams are shared —
  `todayProvider` is the same provider object Cycle and Garden read —
  checks coverage for Wellington, Auckland, Dunedin, the Chathams, London
  and Sydney, that **no position means no guide in either hemisphere**
  (and that the two hemispheres then produce the identical guide while
  still producing different seasons), that opening the feature asks for
  no permission, that a live position still writes no coordinate, and
  that the feature calculates no date, season, hemisphere or position of
  its own.
- `nature_log_store_test.dart` drives the real store through a restart,
  drops nine kinds of malformed line one at a time, keeps an item id from
  a later version, and checks that free text with quotes, pipes and
  newlines survives a round trip.
- `almanac_context_test.dart` proves the seams are shared rather than
  merely in agreement: `todayProvider` is the same provider object Cycle,
  Garden and the Nature Log re-export, one season, one moon, feature
  availability that follows the persisted choices as they change, intents
  that are deterministic values, and a grep of `lib/core/context/`
  proving it calculates nothing and stores nothing.
- `moon_content_test.dart` reads all eight lunar reflections and every
  fixed string the Moon and its Meditation suggestion can say: no
  biological, hormonal, menstrual, fertility, emotional, personality or
  medical claim, every explanation hedged, and no score kept.
- `moon_screen_test.dart` opens the Moon from the Environment and checks
  what is there and what is not: the astronomy matches, the hemisphere
  still turns the light over, no timing is invented, one illustration and
  no landscape or wreath, Back returns to the Environment three times
  over with no stack left behind, and no Moon tab appears in the
  navigation bar. Its doorway group is the product rule under test — with
  Meditation on the door is there, with Meditation off every word of the
  guidance remains and the door is simply absent, and re-enabling brings
  it back with the user still standing on the page.
- `moon_context_test.dart` walks Environment → Moon → Meditation and
  checks the phase arrives, the suggestion suits it, all four practices
  are still offered, and the intent does not linger: leaving and
  re-entering finds no stale moon, and a direct entry never sees one.
- `paper_surface_test.dart` checks the inner-page paper: one warm cream
  across all eight palettes, identical between day and night and across
  the four seasons, never interpolated toward a night background, body
  and secondary ink at 4.5:1, every accent a page may use at 3:1, a night
  palette's accent re-based while a day palette's is left alone, and the
  colour written down nowhere outside its token.
- `nature_log_screen_test.dart` records from the book and in the user's
  own words through the real screens, edits, removes, cancels a removal,
  clears the log, and checks the empty state, the unsupported-region
  fallback, the semantics, 48 dp targets, 2× text and reduced motion. A
  whole group drives the no-location experience end to end: browsing the
  book, recording from it, recording a custom observation, editing and
  removing, that Around now offers nothing in *either* hemisphere, that
  the page never asks for location, and that no coordinate reaches
  storage.
