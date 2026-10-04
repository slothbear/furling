# ideas

CLAUDE.md points here rather than carrying this list itself, so that file can
stay about how the project works.

Each entry says why, not only what — in six months the what is obvious and the
why is gone. Finished entries get deleted rather than ticked off; what shipped
is recorded in `changelog.md`.

## next

Intended for the build in progress. If this list stops being short it has
stopped being true.

Nothing — build 5 is cut. Next cycle's items go here.

## decisions

Blocked on a choice rather than on effort — nothing here can start until it
gets an answer.

- **A name for the archive-and-upload script.** The shape is settled:
  `xcodebuild archive` → `-exportArchive` with `destination: upload`,
  authenticating with an App Store Connect API key `.p8`. It has been
  discussed more than once and never written, purely because it has no name.

## open

Started or half-decided, and unfinished.

- **The widget's symbol reports provenance, not age.** `getTimeline` builds a
  single entry and WidgetKit shows it until the next refresh lands, so the
  symbol describes the moment that entry was generated rather than now. A hare
  rendered at nine still shows a hare at noon with a three-hour-old number,
  while a clock may be two minutes old and nearly right. The icon that looks
  like it means stale actually means "came from the cache", and the one that
  looks live is often the older of the two.
  *Observed 2026-10-04:* opening the app forces a live render, and the hare
  then persists across locking; a refresh landing while locked gives a clock
  that persists after unlocking. Both behave as designed — the design is the
  problem.
  *Preferred fix:* have the timeline carry its own aging. Return several
  entries instead of one — the reading now with the hare, the same number at
  +20 minutes with the clock, later still with the warning. WidgetKit renders
  future entries without waking the extension, which suits the real constraint
  that refreshes are rationed.
  *Alternatives:* bound the cache's age, which disciplines the clock but
  leaves the hare just as capable of being hours stale; or change nothing and
  reword the settings legend, which currently explains provenance accurately
  and freshness not at all.
  *Waiting on:* what Adam's tester actually sees day to day, which decides
  whether this is a real annoyance or a purist's itch.

- **Widget-lag note placement.** The note about lock screen widgets updating
  on iOS's schedule lives in the "live reading" row of `SettingsView`, but it
  applies to all three states. It arguably belongs in a section footer.
  *Why it stalled:* an earlier pass folded the standalone footer into the rows
  deliberately, so putting one back needs a reason beyond tidiness.

## someday

No commitment. Anything sitting here a year from now is telling you something.

- **`Color.furlingBackground` wants its own file.** It's parked at the top of
  `TodayView.swift`. *Trigger:* the first time a second colour appears — one
  colour in a file of its own is worse than one colour where it's used.
- **Colour coherence in the sign.** The light icon's panel moved to a grass
  green but its border is still a greyer `#5d7a6a`, and the dark variant's
  board is blue-grey against a green night field. *Why it's parked:* both read
  fine, and the blue-grey helps the dark board separate from the moonlit grass.

## declined

Kept so the same idea doesn't come round again. Decisions about how the code
works live in CLAUDE.md instead; these are the ones about what to do.

- **A second install of the app for testing**, under a bundle identifier like
  `com.morganthall.Furling.dev`, so a development build could sit alongside
  the TestFlight one. It would need its own App Group, HealthKit entitlement
  and widget extension — a lot of duplicated signing setup for a two-person
  app. The build number on the main screen tells you which one is installed,
  which covers the actual need.
- **A hand-drawn tinted icon variant.** `Contents.json` leaves the tinted slot
  empty, so iOS derives one from the light icon by mapping its luminance onto
  the user's tint. Tried on device across several tints and it holds up — a
  dark hare against a bright sky is already the high-contrast silhouette that
  tinting wants. A custom variant would also have cost `render.sh` a
  per-variant exception to the alpha-flattening rule, since a tinted icon
  needs transparency while the primary icon must not have it. Permanent
  complexity for a marginal gain. Candidates were built and compared: the hare
  alone beat the hare plus mile marker, which turned illegible at 60pt — worth
  knowing if this ever comes back.

- **GitHub Issues for this list.** A browser round-trip and ceremony for an
  app with two users; `gh` isn't installed, so it can't be read or written
  from a session without a token; and the repository is public, so half-formed
  ideas would be too. A file in the repo is versioned alongside the code it
  describes.

