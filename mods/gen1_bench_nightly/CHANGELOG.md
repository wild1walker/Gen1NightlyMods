# Changelog

All notable changes to this mod are recorded here, newest first.

This mod exists only on the **nightly** channel and carries the channel's
version.

## [0.31.2] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.1] - 2026-08-31

### Changed

- **The probe counts NPC draws too.** `E11 N10 S1` from the last reading said
  the draw list was full — player plus ten NPCs — and that exactly one sprite
  draw was issued. That kills every theory about the list being emptied, but
  it cannot tell *where* the other ten stop.

  `SpriteRenderer.draw` is the bottom of the stack: a wrapper above it that
  returns without drawing, or that draws the sprite with its own code, never
  reaches it. Gen1Follower does both — it suppresses a follower with no mon,
  and it draws map POKeMON itself. So a low `S` is ambiguous.

  `NPC.draw` is the other end: one call per NPC the overworld's entity loop
  actually got to. `D` against `S` settles it — `D10 S1` means the loop ran
  and ten draws were swallowed above the engine, `D0` means the loop never ran
  and the branch that skipped it is the bug. Two different files.

## [0.31.0] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.30.4] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.30.3] - 2026-08-31

### Added

- **LAST BATTLE**, a row that reads the frame you cannot screenshot.

  The follower and the NPCs vanish on the *first* frame a battle transition
  exists — one frame out of a wipe that lasts a second, so reading it off the
  overlay means filming the screen and scrubbing to it. The probe now
  snapshots `E`, `N` and `S` on that edge and holds them; walk into any
  battle with SPRITE PROBE on, come back to the bench, and read the row.

## [0.30.2] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.30.1] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.30.0] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.29.4] - 2026-08-31

### Changed

- **SPRITE PROBE reports the theme's frame too.** The line gains `B` boxes
  recorded, `P` panels produced and `Z` zones handed in, read through the UI
  bundle's own published export rather than by reaching into it.

  It is for the route banner, which is still white on a dark map after 0.28.0
  was supposed to have taken it. Every branch of the theme should darken it
  and reading the code has not found the one that does not, so the three
  numbers partition the answer: `B0` means the box was never recorded and the
  bug is in the recorder; `B1 P0` means it was recorded and never panelled and
  the bug is in the rule; `B1 P1` and still white means the zone list is not
  reaching the blit. Three different files.

## [0.29.3] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.29.2] - 2026-08-31

### Added

- **SPRITE PROBE**, a row that measures instead of guessing.

  The open bug: the follower and every NPC pop away the moment a battle's
  start animation begins, while the player stays - in ADVANCED, under LIGHT as
  well as DARK, for wild battles and trainer battles alike. Reading the code
  eliminated most of the ways that could happen and did not find the one that
  did, so the bench now carries the instrument.

  ON draws one line over the game: `E` how many things are in the overworld's
  draw list, `N` how many NPCs, `S` how many sprite draws were issued last
  frame, `T` whether a battle transition is on the stack. Screenshot it as the
  battle starts and the three numbers separate the three possible causes on
  sight - the draw list being emptied, the draws being suppressed one sprite
  at a time, or the sprites being drawn onto a canvas that then goes.

  Off by default, and inert while it is off: one boolean test per sprite draw
  and an early return in the frame hook.

## [0.29.1] - 2026-08-30

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.29.0] - 2026-08-30

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.28.0] - 2026-08-30

Nothing in this mod changed for 0.28.0; the channel ships as one release, so
it carries the version.

## [0.27.0] - 2026-08-30

Nothing in this mod changed for 0.27.0; the channel ships as one release, so
it carries the version.

## [0.26.0] - 2026-08-30

Nothing in this mod changed for 0.26.0; the channel ships as one release, so
it carries the version.

## [0.25.0] - 2026-08-30

### Changed

- **Tests, tools and sources stop riding the release.** `tools/pack.py` has
  said since this channel was stood up that "a mod's own tests and tools are
  the clearest case: they are how the source is kept honest and they are dead
  weight inside an archive the launcher unpacks" — and its skip list did not
  act on it. `tests/`, `tools/`, `maintained/` and `upstream/` were in every
  archive from 0.3.0 to 0.24.0.

  Measured on 0.24.0 that was 137 KB of the UI bundle's 1178, 80 of QOL's 769,
  35 of Wild Green's 112 and 3 of the bench's 15 — about a quarter of a
  megabyte per release of files a phone unpacks and nothing ever opens.
  `maintained/` was the worst of it: it is the **source** of a module the tree
  owns and `modules/` is the copy the bundle loads, so every one of those
  modules shipped twice.

  Nothing the game can reach through `mod:read` is in the skip list, and every
  path a feature reads is under `modules/` or `assets/` — which each bundle's
  own `check.py` already verifies on every run.

## [0.24.0] - 2026-08-30

Nothing in this mod changed for 0.24.0; the channel ships as one release, so
it carries the version.

## [0.23.0] - 2026-08-30

Nothing in this mod changed for 0.23.0; the channel ships as one release, so
it carries the version.

## [0.22.0] - 2026-08-30

Nothing in this mod changed for 0.22.0; the channel ships as one release, so
it carries the version.

## [0.21.0] - 2026-08-30

Nothing in this mod changed for 0.21.0; the channel ships as one release, so
it carries the version.

## [0.20.0] - 2026-08-30

Nothing in this mod changed for 0.20.0; the channel ships as one release, so
it carries the version.

## [0.19.0] - 2026-08-30

Nothing in this mod changed for 0.19.0; the channel ships as one release, so
it carries the version.

## [0.18.0] - 2026-08-30

Nothing in this mod changed for 0.18.0; the channel ships as one release, so
it carries the version.

## [0.17.0] - 2026-08-30

Nothing in this mod changed for 0.17.0; the channel ships as one release, so
it carries the version.

## [0.16.0] - 2026-08-30

Nothing in this mod changed for 0.16.0; the channel ships as one release, so
it carries the version.

## [0.15.0] - 2026-08-30

Nothing in this mod changed for 0.15.0; the channel ships as one release, so
it carries the version.

## [0.14.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.14.0` release is one version, which is how the cart's pins resolve.

## [0.13.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.13.0` release is one version, which is how the cart's pins resolve.

## [0.12.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.12.0` release is one version, which is how the cart's pins resolve.

## [0.11.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.11.0` release is one version, which is how the cart's pins resolve.

## [0.10.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.10.0` release is one version, which is how the cart's pins resolve.

## [0.9.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.9.0` release is one version, which is how the cart's pins resolve.

## [0.8.0] - 2026-08-30

### Changed

- **`UI THEME` on the bench is two values, not three**, following the suite:
  `COLORFUL` was removed rather than finished.

## [0.7.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.7.0` release is one version, which is how the cart's pins resolve.

## [0.6.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.6.0` release is one version, which is how the cart's pins resolve.

## [0.5.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.5.0` release is one version, which is how the cart's pins resolve.

## [0.4.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.4.0` release is one version, which is how the cart's pins resolve.

## [0.3.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.3.0` release is one version, which is how the cart's pins resolve.

## [0.2.0] - 2026-08-30

New.

### Added

- **A `BENCH` row on the START menu**, second to last so it does not push
  `EXIT` down, opening one screen with every setting this channel is changing
  on it: the UI theme, the player's colour, the display mode, the battle
  layout, and the three arena rows.

- **A battle on demand.** Pick an opponent and a level and press A. Looking at
  a backdrop, a fade or the black outro otherwise means finding grass first,
  which is most of the time it takes to check any of them.

- **The autosave's own request, and a reading of whether it has landed.**
  There is deliberately no write-it-now: a save takes the same windows a save
  always takes, and that is the thing being tested. The row asks; the value
  says `PENDING`, `DUE` or `IDLE`.

- **`MAP`**, which is what a backdrop that picked the wrong slot raises first.
