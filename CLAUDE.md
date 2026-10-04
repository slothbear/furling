# Furling

Lock screen widget showing today's walking distance in miles. iOS 17+, SwiftUI.
Personal app, distributed to two people via internal TestFlight. Not going to
the App Store.

Name is a pun: furlong (distance unit) + the Furlings from Stargate.

## Structure

- `Furling/` — app target. Exists mainly to hold the HealthKit permission the
  widget depends on, plus a settings sheet.
- `FurlingWidget/` — widget extension. `.accessoryInline` only, the strip
  beside the lock screen date.
- `DistanceStore.swift` — shared. **Must be in both target memberships.**
- `Furling/changelog.md` — release notes, read at runtime by `Changelog.swift`
  to build the "new & noteworthy" section in settings. **Has to stay inside
  `Furling/`**; the folder is a synchronized group, so anything in it is
  bundled automatically, and a copy at the repo root would not be.

- `FurlingTests/` — unit tests, currently only for `Changelog.parse`.
  `Changelog.swift` is compiled into this target directly (the same way
  `DistanceStore.swift` is shared with the widget), so there is no host app.
  Run with `xcodebuild test -project Furling.xcodeproj -scheme Furling
  -destination 'platform=iOS Simulator,name=iPhone 17'`, or Cmd-U in Xcode.
  One test reads the real `Furling/changelog.md` and fails if any build
  heading in it is silently dropped.

## Decisions worth not relitigating

- **Distance is read directly from HealthKit** (`distanceWalkingRunning`),
  never derived from steps × stride. This was the founding requirement.
- **`DistanceStore.Reading`** is a three-state enum: `.live`, `.stale`
  (cached from earlier today), `.unavailable`. The widget shows a real number
  in all three cases and signals the state through the SF Symbol instead:
  `hare` / `clock.arrow.circlepath` / `exclamationmark.triangle`.
  A placeholder zero must never look like a measured zero.
- **App Group `UserDefaults`** caches the last good reading. HealthKit's store
  is protected and reads fail **whenever the phone is locked**, not only
  between a reboot and the first unlock. The cache is readable once the phone
  has been unlocked at least once since boot, so it covers the case that
  actually recurs: widget timeline refreshes landing while the phone sits
  locked. Before the first unlock after a reboot both are dark, so the warning
  triangle there is correct rather than a bug — nothing can produce a number.
  Confirmed on device 2026-10-04: with Require Passcode set to Immediately, a
  locked phone's widget showed the clock symbol and the cached mileage, so iOS
  does refresh lock screen widgets while the device is locked and protected
  rather than deferring until unlock.
- Inline widgets get one line, system font, one symbol, and a system-applied
  monochrome tint. Colour and font choices there are discarded.

## Gotchas already paid for

- Both targets need HealthKit + App Groups capabilities, same team.
- Info.plist needs `NSHealthShareUsageDescription`, and also
  `NSHealthUpdateUsageDescription` even though the app never writes — upload
  validation demands it whenever the HealthKit entitlement is present.
- `ITSAppUsesNonExemptEncryption` = Boolean NO, or every upload asks.
- App icon must be 1024×1024 RGB with **no alpha channel**. Source is
  `icon/furling.svg`; run `icon/render.sh`, which rasterises with headless
  Chrome and flattens with CoreGraphics. Both ship with the machine — cairosvg
  was dropped because it drags in Homebrew's cairo for no gain.
- The icon's hare is the system `hare.fill` symbol, the same one the widget
  shows, rendered from SF Symbols at run time rather than kept in the repo.
  Note Apple's SF Symbols licence does not permit symbols in app icons; this
  is a deliberate exception for an app that never goes near review.
- `render.sh` inlines the SVG into its page rather than loading it through an
  `<img>` tag. An SVG embedded as an image runs in secure static mode, cannot
  load `hare.png`, and the hare silently vanishes with no error.
- Grouped `List` section headers uppercase by default. `.textCase(nil)` is
  what keeps "widget symbols" lowercase.
- The App Store tab's icon slot stays a placeholder grid forever — it only
  populates from a build selected for submission. TestFlight → Builds is the
  one that matters.

## Current state

Build 5 distributed, build 6 in progress. Internal TestFlight group
"kuniklaro". Source lives at github.com/slothbear/furling, public, pushed over
SSH; distribution builds are tagged `build_N` at the point they are uploaded,
not when the number is bumped.

Open threads, ideas and anything noticed in passing live in `ideas.md`. Read
it when picking up work; it is not loaded automatically the way this file is.

## Working with Adam

- Direct and practical. Dry wit welcome. Skip the sympathy.
- **Never use the word "just".**
- Settle on names *before* building anything — files, scripts, projects. He
  dislikes rework on names.
- Capitals start sentences and proper names, nothing else. A label, heading or
  fragment — "live reading", "added", "build 3", "new & noteworthy" — stays
  lowercase, and only a full sentence gets its capital. Names keep their
  capitals wherever they fall, including inside an otherwise lowercase label:
  Apple Health, HealthKit, GitHub, Furling, TestFlight. System chrome is exempt — a navigation title or a standard
  button ("Settings", "Done", "Refresh") keeps the capital iOS gives it.
  Flag capitalisation choices as they come up rather than deciding silently.
- **Run the tests yourself.** He does not want to think about it. Run the
  suite after any change to `Changelog.swift`, `changelog.md` or `FurlingTests/`,
  and before saying a build is ready to tag. Report the result in a line;
  say so plainly if a test fails rather than working around it.
- Grams for weight, never cups.
- Markdown over .docx.
