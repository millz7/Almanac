# Asset strategy

This folder is organised ahead of the illustrations and imagery described in
the app concept. Nothing is populated yet — no placeholder graphics have
been added — but the structure and `pubspec.yaml` wiring are ready so real
assets can be dropped in without further setup.

- `illustrations/` — custom botanical/atmospheric illustrations (moon
  phases, mountains, ocean, flora, fauna, chakras, Wheel of the Year, yoga
  poses, seasonal scenes). Expected to be SVG or PNG, organised in
  subfolders per feature once that feature starts (e.g. `illustrations/moon/`).
- `images/` — photographic or raster imagery that isn't part of the
  illustration system (e.g. onboarding backgrounds).
- `icons/` — custom icon assets that go beyond Material's built-in icon set.

When assets are added, declare their folders under `flutter: assets:` in
`pubspec.yaml` (see the commented example there) and reference them through
a small `AppImages`/`AppIllustrations` constants class rather than inline
string paths, so a renamed or moved file only needs updating in one place.
