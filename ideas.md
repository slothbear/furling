# ideas

CLAUDE.md points here rather than carrying this list itself, so that file can
stay about how the project works.

Each entry says why, not only what — in six months the what is obvious and the
why is gone. Finished entries get deleted rather than ticked off; what shipped
is recorded in `changelog.md`.

## next

Intended for the build in progress. If this list stops being short it has
stopped being true.

- **Fill the tinted icon variant.** `Contents.json` declares the slot but
  leaves it empty, so iOS derives one by desaturating the light icon.
  *Why now:* `icon/render.sh` already renders two variants, so a third is
  mostly a colour decision rather than work.

- **Correct build 5's changelog date before cutting.** The `## [build 5]`
  heading carries the day the section was opened, not the day it ships.
  *Why:* the date is the one part of an entry that is wrong by default.

## decisions

Blocked on a choice rather than on effort — nothing here can start until it
gets an answer.

- **A name for the archive-and-upload script.** The shape is settled:
  `xcodebuild archive` → `-exportArchive` with `destination: upload`,
  authenticating with an App Store Connect API key `.p8`. It has been
  discussed more than once and never written, purely because it has no name.

## open

Started or half-decided, and unfinished.

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
- **GitHub Issues for this list.** A browser round-trip and ceremony for an
  app with two users; `gh` isn't installed, so it can't be read or written
  from a session without a token; and the repository is public, so half-formed
  ideas would be too. A file in the repo is versioned alongside the code it
  describes.

