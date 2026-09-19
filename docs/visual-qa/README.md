# Visual QA — the Environment, with the supplied artwork

Evidence only. These are **not** design references and nothing in the app
reads them.

## How they were produced

The real app — `AlmanacApp`, the same widget `main.dart` runs — launched
through `lib/dev/visual_qa_main.dart`, which overrides the clock, the
position, the time zone and the settings store the way a widget test
does. Everything below those overrides is production code, including the
real NOAA sunrise/sunset calculation, so the times on screen are the
times a user in London would see.

**Platform: Flutter web (CanvasKit) in headless Chromium on Linux.**
There is no macOS, no Xcode and no iOS Simulator in this environment, and
no KVM for an Android emulator — see the Step 18 QA report. The iPad
frame below is an iPad-sized *viewport*, not an iPad.

  phone   390 × 844 logical, DPR 3   (iPhone 14/15 class)
  tablet  834 × 1194 logical, DPR 2  (11-inch iPad Pro class)

Captured at those device pixel ratios and saved down to the logical size,
so a 31 MB folder of painted plates does not live in the repository.

## States

All at London, 51.5074 / −0.1278, Europe/London.

  spring-day       2025-04-20 12:00 BST
  summer-day       2025-07-15 12:00 BST
  autumn-day       2025-10-15 12:00 BST
  winter-day       2025-01-15 12:00 GMT
  summer-sunrise   2025-07-15 05:05 BST   ("The light is coming back")
  autumn-sunset    2025-10-15 18:15 BST   ("The light is going")
  winter-night     2025-01-15 22:00 GMT   ("Dark, and the world is resting")

## What these show

Each shot is the real plate from `assets/environment/`, selected by the
real season and the real day/night phase and shown as supplied. Nothing
is drawn over it: the sun and moon in the pictures are painted, and the
app's own sunrise, sunset and moon phase are stated in words underneath.
The page around the painting is the same cream in all fourteen shots.

## Observed, not fixed

**A dark strip down the left edge of ten plates.** It is in the supplied
files, not in the app: it is the left bezel of the phone mock-up the
artwork was extracted from. Measured on the assets themselves, as a mean
column brightness over the full height (0–255):

    autumn_day        black  0–40 px
    autumn_sunrise    black  0–24 px
    autumn_sunset     black  0–56 px
    spring_sunrise    black  0–24 px
    spring_sunset     black  0–56 px
    summer_day        black  0–44 px
    summer_sunrise    pale 0–20 px, then black 28–84 px
    summer_sunset     pale 0–28 px, then black 48–112 px
    winter_day        pale 4–12 px, then black 12–68 px
    winter_sunrise    pale 0–20 px, then black 28–80 px
    winter_sunset     pale 0–28 px, then black 48–112 px

    spring_day, spring_night, summer_night, autumn_night and
    winter_night are clean.

The right, top and bottom edges of all sixteen are clean. It shows on a
phone as a hairline of black against the cream page, and it is most
visible on `autumn_sunset` and `summer_day`. It is **reported, not
repaired**: cropping or painting over it would be editing the supplied
artwork, which this step forbids. Replacement plates without the bezel
would fix it with no code change, since the file names are the contract.
