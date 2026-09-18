# Visual QA — Step 18 Environment rebuild

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

## States

All at London, 51.5074 / −0.1278, Europe/London.

  spring-day       2025-04-20 12:00 BST
  summer-day       2025-07-15 12:00 BST
  autumn-day       2025-10-15 12:00 BST
  winter-day       2025-01-15 12:00 GMT
  summer-sunrise   2025-07-15 05:05 BST   ("The light is coming back")
  autumn-sunset    2025-10-15 18:15 BST   ("The light is going")
  winter-night     2025-01-15 22:00 GMT   ("Dark, and the world is resting")
