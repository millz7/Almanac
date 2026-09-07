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
thing, the first day of a period, and counts quietly from it.
**Cookbook** is a small seasonal cookbook — sixteen recipes, four to a
season. **Garden** is a gardening almanac: what is worth sowing,
planting, tending, harvesting or pruning where you are, now, and a record
of what you actually grow. **Nature Log** is the last of them: a quiet
personal record of what you have noticed, beside a modest offline guide
to what is often about at this time of year.

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

Notice where you are in your cycle. It records one thing — the first day
of a period — and does arithmetic on it. The biggest thing on the screen
is **Cycle day 12**, not a chart.

### What it does not do

No fertility prediction, no probability of anything, no ovulation
diagnosis, no pregnancy, no contraception, no symptom tracker, no mood
log, no score, no streak, no notifications, no export, no sharing. It
makes no medical claim and never says a calculated date is certain.

`cycle_content_test.dart` reads every string the feature can show against
a list of clinical words and a list of gamified ones, and separately
against a list of over-claims ("you are ovulating", "guaranteed",
"accurate"). `cycle_calculator_test.dart` greps the domain itself for
anything that computes fertility, conception or pregnancy.

### Privacy, which is the whole architecture here

Cycle dates are the most sensitive thing the app holds, so they get their
own everything: their own store (`CycleStore`), their own two preference
keys under a `cycle.` prefix, their own serialisation, and their own
`deleteAll` that removes both keys so nothing is left to say anybody ever
used the feature. **They are never put in `UserSettings`.** The store is
opened on first use rather than at startup, so somebody who never opens
Cycle never has their cycle dates read into memory.

`CycleData.toString()` reports *how many* dates it holds and never which —
a `toString` is exactly how sensitive data ends up in a crash report — and
there is a test asserting no `debugPrint` in the feature interpolates
anything but a type name. Nothing about a cycle is shown anywhere else in
the app, and there is a test for that too.

Local only: no account, no cloud, no sync, no network, no analytics, no
external API, no location, no microphone, no camera, no background work
and no new permissions.

### Dates are dates, not instants

`CalendarDate` is a year, a month and a day, with no time and no zone. A
period began on the fifteenth of July wherever the phone happens to be,
and storing that as an instant is how a date ends up shifting to the day
before because somebody flew west or the clocks went back. Its arithmetic
goes through UTC internally, so adding a day is always exactly a day —
there is a test that walks it across both British daylight-saving
changes. Stored as `YYYY-MM-DD`; an unreadable stored value is dropped
rather than crashing the feature.

### The estimate, and the model

Everything past the recorded date is an estimate and is labelled as one.
The basis is stated on the screen — "Using a 28-day estimate" — and the
length is the user's own choice, 21 to 40 days, on a `+`/`−` stepper like
Meditation's duration. Changing it changes estimates only; the recorded
dates are passed through untouched, and the note under the stepper says
so.

The phase model is deliberately simple arithmetic, documented in full on
`phaseSpansFor`:

| Phase | 28-day cycle | Rule |
|---|---|---|
| Menstrual | days 1–5 | always, since bleeding length is not recorded |
| Follicular | days 6–13 | whatever is left before the window |
| Ovulatory | days 14–16 | three days from `length − 14` |
| Luteal | days 17–28 | the day after the window, to the end |

A window rather than a claimed day, because a single day would be a claim
this app cannot make. A day past the end of the estimate stays luteal and
says "This cycle is longer than the estimate so far. That is simply what
has been recorded." At the extremes of the allowed range the wording gets
more cautious still.

Every phase is announced as "Approximate follicular phase", and each
carries one reflective line — "Something is beginning to build." —
followed always by **"Your experience may be different."**

### Pure, and injected with today

`cycleMomentAt({today, data})` is a pure function: no clock, no random, no
side effects, no logging. `todayProvider` is the single place the clock
becomes a date, which is what lets a test walk a whole cycle a day at a
time and check every boundary. Observed cycle lengths are shown as
history — "Recorded cycle length: 28 days" — and never silently become the
estimate.

### The calendar

A hand-built seven-column grid, no calendar package. Recorded dates are
drawn as a filled disc; estimated ones as a ring of twelve short dashes —
a different *shape*, not a different colour — and each cell's semantics
says "Recorded period start" or "Estimated period start" in words. A
legend names both. With one date recorded there is no history to estimate,
so none is invented: estimates only ever run forwards. Tapping a recorded
date offers edit or delete; an estimate cannot be tapped, because there is
nothing there to change. The picker's `lastDate` is today, so a future
date cannot be chosen at all — and the controller refuses one anyway.

At a large text size the grid grows with the text and scrolls sideways
rather than squeezing the numbers, which is the same rule the navigation
bar has followed since Step 6.

### Deleting means deleting

Both deletions confirm first. "Delete your cycle history?" — "Your
recorded cycle dates will be removed from this device." — **Delete** /
**Keep**. Confirming clears memory and storage together and lands back on
the first-use screen, which the tests check by reopening the store.

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

`NatureGuide.resolve` reads the environment the rest of the app already
worked out. A shared position inside a generous box around New Zealand
(including Stewart Island and the Chathams) gets the guide, sourced from
`location`. A position outside it gets no guide, because the book has no
content for there. With no position at all the hemisphere is the only
signal: the southern hemisphere is offered the guide **marked
unconfirmed**, and says so on screen; the northern hemisphere is offered
nothing, since New Zealand species in a Vermont spring would be
nonsense.

Either way the log works. Coverage gates suggestions, never the user's
own record — somebody in London can record a robin, and the Nature Book
is still there to record from.

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

1,315 tests. The ones worth knowing about:

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
- `cycle_store_test.dart` drives the real preferences-backed store
  through the plugin's in-memory implementation: a restart keeps the
  dates, deleting removes both keys, and nothing lands outside the
  `cycle.` prefix.
- `cycle_screen_test.dart` records, edits and deletes dates through the
  real screens, and checks that an estimate never looks or sounds like a
  recorded date.
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
  checks coverage for Auckland, Dunedin, the Chathams, London and Sydney,
  that opening the feature asks for no permission, that a live position
  still writes no coordinate, and that the feature calculates no date,
  season, hemisphere or position of its own.
- `nature_log_store_test.dart` drives the real store through a restart,
  drops nine kinds of malformed line one at a time, keeps an item id from
  a later version, and checks that free text with quotes, pipes and
  newlines survives a round trip.
- `nature_log_screen_test.dart` records from the book and in the user's
  own words through the real screens, edits, removes, cancels a removal,
  clears the log, and checks the empty state, the unsupported-region
  fallback, the semantics, 48 dp targets, 2× text and reduced motion.
