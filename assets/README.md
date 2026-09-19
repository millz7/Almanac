# Asset strategy

This folder holds the app's bundled artwork. Everything here ships inside
the APK: nothing is fetched from a network, a CDN or an image API at
runtime, and nothing is generated on a server.

- `environment/` — **the Environment's sixteen approved plates**, the only
  populated folder. One painting per season per light state, named
  `<season>_<light>.webp` (`spring_sunrise`, `spring_day`,
  `spring_sunset`, `spring_night`, and the same four for summer, autumn
  and winter). They are the supplied production artwork and are shown
  exactly as delivered — not recreated, redrawn, reinterpreted or
  re-exported. The file names are the contract: `EnvironmentArtwork`
  builds a path from a season and a light state, and a test asserts that
  the sixteen files on disk and the sixteen paths the app can ask for are
  the same set. Renaming one breaks that test rather than silently
  showing nothing.

The folders below are structure ahead of the artwork that will fill them:

- `illustrations/` — custom botanical/atmospheric illustrations (moon
  phases, mountains, ocean, flora, fauna, chakras, Wheel of the Year, yoga
  poses, seasonal scenes). Expected to be SVG or PNG, organised in
  subfolders per feature once that feature starts (e.g. `illustrations/moon/`).
- `images/` — photographic or raster imagery that isn't part of the
  illustration system (e.g. onboarding backgrounds).
- `icons/` — custom icon assets that go beyond Material's built-in icon set.

When assets are added, declare their folders under `flutter: assets:` in
`pubspec.yaml` and reference them through a small constants class — as
`EnvironmentArtwork` does — rather than inline string paths, so a renamed
or moved file only needs updating in one place.
