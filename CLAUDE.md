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

- `Furling/OctoberOrnament.swift` — the candy corn on the main screen. Shown
  only in October, by checking the date, so nothing needs removing afterwards
  and it comes back every year. The main screen also gets a soft orange
  background all month (`furlingOctoberBackground`), because the cream tip of
  a candy corn vanishes on the usual off-white. One slice fills per day, 31 in
  all. On Halloween, and only then, the wedge becomes touchable: a small candy
  corn pulses in it after two idle seconds, a touch sets off confetti across
  the whole screen, and it also bursts each time the app opens. Long-pressing
  the caption pretends it is Halloween, so all of that can be tried before the
  day. That is **in the shipped app on purpose**, as a hidden extra — it is
  not announced in the changelog, so leave it out. The date logic is plain
  functions so it can be tested.
- `Furling/NovemberLeaves.swift` — leaves falling down the main screen in
  November, over a muted wheat (light) or rust (dark) background. Day N drops
  N fallers each time the app opens, over about eight seconds; every fifth is
  a rabbit, so six by the 30th — `hare` or `hare.fill` at random, always in
  one of the leaf colours, never white. Four hand-drawn leaves — maple,
  oak, birch, elm — kept as SVG-style path strings. Along the bottom is
  `NovemberHedge`, Adam's own photo of a hedge (asset `NovemberHedge`), cut
  along the top of the greenery by an edge traced from the photo and stored
  as fractions in `NovemberHedge.edge`; replacing the photo means retracing
  that. Dimmed in dark mode. Leaves pile on that edge in landing order, each
  on whatever is highest beneath it, sinking only part way onto a leaf below
  so none is hidden, and slipping sideways to lower ground nearby rather than
  balancing on a peak. They stay until the app leaves the foreground, and
  are cleared then (bag and all) so it reopens on a bare hedge rather than
  flashing the old pile from iOS's snapshot. Leaves land lying
  on their side, never stood on end; rabbits tumble on the way
  down but land on their feet, level.
  A brown paper yard bag, tall, its top folded into a crumpled cuff,
  stands in front of the middle of the hedge. Nothing comes to rest behind
  it: a faller whose path would overlap it hops off to the nearer side
  (`Rest.bounce`) and settles there, rolling down the heap rather than
  stacking against it — or to the far side, if the near one has piled up
  well above it. It was first near the right-hand edge, where the gap was
  too narrow and late arrivals had to hop the whole width of the bag to
  the left. The bag is drawn behind the leaves, so one mid-bounce shows
  in front. As each faller lands, rabbits
  included, the number printed on it counts up and a burnt-orange fill
  rises a thirtieth of the way, so the number ends on the date and the bag
  is full on the 30th. Full stops short of the cuff (`Bag.fullLine`),
  leaving bare paper under its shadow. On the 30th, once the last faller
  is in, the bag overflows (`Bag.heap`, `Bag.overspill`): a heap of leaves
  rises out of its mouth behind the cuff, then four tip over the rim, two
  caught on the cuff's corners and two partway down the sides. Then it
  keeps overflowing for five seconds (`Bag.sprayTime`): seventy leaves and
  rabbits (`Spray`) thrown up out of the mouth to either side, falling off
  the bottom of the screen rather than joining the pile. Under
  Reduce Motion it shows the day's total from the start, overflowing
  already on the 30th, with no spray.
  All month a fixed spacer at the bottom of the main screen keeps the number
  centred in the open space above the hedge. It is a spacer rather than
  padding on the status line because that line is usually empty, and an
  empty view's padding disappears with it. On US Election Day (the Tuesday after the first
  Monday, `isElectionDay`) the leaves are broad ballot leaves reading VOTE,
  landing the right way up. On Thanksgiving (the fourth Thursday,
  `isThanksgiving`) the rabbits are turkeys instead. SF Symbols has none, so
  `Turkey` is drawn to match `hare` / `hare.fill`: side-on, one leaf
  colour, outline or filled at random, half as big again as a rabbit. A
  multicoloured front-on turkey was tried first and read as more leaves.
  They tumble and land upright like the rabbits. On Black Friday
  (the day after, `isBlackFriday`) they are Amazon-style boxes, hand-drawn
  front-on (`ShippingBox`), outline or filled, always the brown leaf
  colour as cardboard, the same size as the turkeys so the smile reads,
  and the smile centred. Shopping bags were tried alongside and dropped;
  so was the `shippingbox` symbol, whose perspective put the smile
  off-centre. Each kind of stand-in is a `StandIn` case. The falling
  is skipped under Reduce Motion; the hedge stays. The rabbits and their
  Thanksgiving and Black Friday stand-ins are a surprise: the changelog
  mentions only leaves, so leave them out.
- `FurlingTests/` — unit tests for `Changelog.parse` and for the date logic in
  `OctoberOrnament` and `NovemberLeaves` (Election Day, Thanksgiving, Black
  Friday). The
  source files are compiled into this target directly
  (the same way `DistanceStore.swift` is shared with the widget), so there is
  no host app.
  Run with `xcodebuild test -project Furling.xcodeproj -scheme Furling
  -destination 'platform=iOS Simulator,name=iPhone 17'`, or Cmd-U in Xcode.
  One test reads the real `Furling/changelog.md` and fails if any build
  heading in it is silently dropped.

## Decisions worth not relitigating

- **Distance is read from HealthKit** (`distanceWalkingRunning`) whenever it
  can be, and never derived from steps × stride. That was the founding
  requirement. **Revised 2026-10-22:** HealthKit is unreadable whenever the
  phone is locked, so on a phone with Face ID the widget was almost never
  current — the one tester "seldom" saw a live number. When HealthKit fails,
  `DistanceStore.reading()` now asks `CMPedometer` for today's distance: the
  motion coprocessor's own estimate, readable while locked. It is iPhone-only
  (no Apple Watch miles), so the fallback never reports less than the total
  already cached today. Needs Motion & Fitness permission, requested by the
  app; `NSMotionUsageDescription` is set on both targets. Confirmed on device
  2026-10-23 with Face ID on: the locked widget stays current.
- **`DistanceStore.Reading`** is a three-state enum: `.live` (HealthKit, or
  the pedometer while locked), `.stale` (cached from earlier today),
  `.unavailable`. The widget shows a real number
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

Build 12 distributed. Internal TestFlight group
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
- **Run the tests yourself, but only when the changelog parser is involved.**
  He does not want to think about it, and he does not want them run for
  anything else. Run the suite after a change to `Changelog.swift`, and say so
  in a line, plainly, if a test fails rather than working around it. Do not
  run it for edits to `changelog.md` alone — decided 2026-11-15, after he
  stopped the run twice for changelog wording — nor for view, layout or
  ornament changes. (The suite also covers
  `OctoberOrnament`'s date functions; whether an edit to those should trigger
  a run has not been decided.)
- Grams for weight, never cups.
- Markdown over .docx.
