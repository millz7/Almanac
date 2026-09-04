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
- `lib/core/widgets/` — small reusable UI building blocks shared across
  features (`AppScaffold`, `AppCard`, `SectionHeader`, `PrimaryButton`,
  `EmptyState`, `FeaturePlaceholderScreen`).
- `lib/features/<feature>/presentation/` — one folder per top-level tab
  (today, wellbeing, rhythms, nature, food). `data/` and `domain/`
  subfolders will be added to a feature once it has real business logic.

State management is [Riverpod](https://riverpod.dev); navigation is
[go_router](https://pub.dev/packages/go_router) with a
`StatefulShellRoute` powering the five-tab bottom navigation.

## Design system

All colour, typography, spacing, radius, elevation, motion and icon-size
values are centralised in `lib/app/theme/`. Widgets should reference
these tokens (via `Theme.of(context)` or the `App*` token classes)
rather than hard-coding values.

## Testing

```
flutter test
```
