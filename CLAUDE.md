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
  to build the "new & noteable" section in settings. **Has to stay inside
  `Furling/`**; the folder is a synchronized group, so anything in it is
  bundled automatically, and a copy at the repo root would not be.

## Decisions worth not relitigating

- **Distance is read directly from HealthKit** (`distanceWalkingRunning`),
  never derived from steps × stride. This was the founding requirement.
- **`DistanceStore.Reading`** is a three-state enum: `.live`, `.stale`
  (cached from earlier today), `.unavailable`. The widget shows a real number
  in all three cases and signals the state through the SF Symbol instead:
  `hare` / `clock.arrow.circlepath` / `exclamationmark.triangle`.
  A placeholder zero must never look like a measured zero.
- **App Group `UserDefaults`** caches the last good reading, because HealthKit
  is unreadable between a reboot and the first unlock.
- Inline widgets get one line, system font, one symbol, and a system-applied
  monochrome tint. Colour and font choices there are discarded.

## Gotchas already paid for

- Both targets need HealthKit + App Groups capabilities, same team.
- Info.plist needs `NSHealthShareUsageDescription`, and also
  `NSHealthUpdateUsageDescription` even though the app never writes — upload
  validation demands it whenever the HealthKit entitlement is present.
- `ITSAppUsesNonExemptEncryption` = Boolean NO, or every upload asks.
- App icon must be 1024×1024 RGB with **no alpha channel**. Source SVG is in
  `icon/`; render with cairosvg and `.convert('RGB')`.
- Grouped `List` section headers uppercase by default. `.textCase(nil)` is
  what keeps "widget symbols" lowercase.
- The App Store tab's icon slot stays a placeholder grid forever — it only
  populates from a build selected for submission. TestFlight → Builds is the
  one that matters.

## Current state

Build 3. Internal TestFlight group "kuniklaro". Working.

Open threads:
- The widget-lag note currently lives in the "Live reading" row of
  `SettingsView`; it arguably belongs in the section footer, since it applies
  to all three states.
- `Color.furlingBackground` is parked at the top of `TodayView.swift`. Wants
  its own file if a second colour appears.
- A local archive-and-upload script was discussed but never written.
  `xcodebuild archive` → `-exportArchive` with `destination: upload`, auth via
  an App Store Connect API key `.p8`. Needs a name before it gets built.

## Working with Adam

- Direct and practical. Dry wit welcome. Skip the sympathy.
- **Never use the word "just".**
- Settle on names *before* building anything — files, scripts, projects. He
  dislikes rework on names.
- Capitals start sentences, and nothing else. A label, heading or fragment —
  "live reading", "added", "build 3", "new & noteable" — stays lowercase, and
  only a full sentence gets its capital. Proper nouns keep theirs wherever
  they appear. System chrome is exempt — a navigation title or a standard
  button ("Settings", "Done", "Refresh") keeps the capital iOS gives it.
  Flag capitalisation choices as they come up rather than deciding silently.
- Grams for weight, never cups.
- Markdown over .docx.
