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
  location and solar services. The single source of truth the theme (and
  later, features) read from.
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
