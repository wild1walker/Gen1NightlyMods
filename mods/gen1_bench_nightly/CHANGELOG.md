# Changelog

All notable changes to this mod are recorded here, newest first.

This mod exists only on the **nightly** channel and carries the channel's
version.

## [0.32.15] - 2026-09-02

_Write what changed._

## [0.32.14] - 2026-09-02

_Write what changed._

## [0.32.13] - 2026-09-02

_Write what changed._

## [0.32.12] - 2026-09-02

_Write what changed._

## [0.32.11] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.10] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.9] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.8] - 2026-09-01

- A `SAVE AFTER` row: **did the post-battle save land after the defeat was
  recorded, or before it?**

  The instrument for the one bug three releases have now gone after and missed.
  Each attempt was a theory about *which* callback records a trainer's defeat —
  and the answer turns out to depend on how the battle started, which is why
  two of them fixed a case that was not the reported one.

  So this row does not theorise. It reports the two numbers that settle it: how
  many trainers the save calls beaten when the battle ends, and how many it
  calls beaten on the frame the post-battle save is actually written.

  | reading | what it means |
  |---|---|
  | `12>13 OK` | something was recorded between the two — the save is sound |
  | `12>12 EARLY` | nothing was — this is the bug, caught in the act |
  | `12>-- NO SAVE` | the hold released and no save landed, which is a different fault |
  | `12>.. HOLDING` | the hold is still on; no verdict yet |
  | `WILD 12` | a wild battle, which records no defeat and proves nothing |

  Take the reading straight after beating somebody **new**: a trainer already
  beaten has nothing to record, so the count cannot move and it reads `EARLY`
  correctly.

## [0.32.7] - 2026-09-01

- No changes; released alongside the QOL mod.

## [0.32.6] - 2026-09-01

- No changes; released alongside the QOL mod.

## [0.32.5] - 2026-09-01

- No changes; released alongside the QOL mod.

## [0.32.4] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.3] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.2] - 2026-09-01

- No changes; released alongside the UI and QOL mods.

## [0.32.1] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.0] - 2026-09-01

- A `VOXEL` row: which voxel mod is installed, and whether that one moves the
  battle HUDs onto its world canvas.

  Two facts because they are different questions, and only the second decides
  anything. `SNAP` means the XP bar and the caught marker should be following
  the HUDs there; `FRAME` means they should not, which is what two of the four
  forks want and is not a fault. `NONE` is almost everybody. The row asks both
  bundles and shows both readings if they disagree -- only one voxel mod can be
  installed at a time, so a disagreement is itself the finding.

## [0.31.33] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.32] - 2026-08-31

- No changes; released alongside the QOL mod.

## [0.31.31] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.30] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.29] - 2026-08-31

- No changes; released alongside the QOL mod.

## [0.31.28] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.27] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.26] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.25] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.24] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.23] - 2026-08-31

### Changed

- **ART RECTS reads `<count> <THEME> <PAGE|BARE>`**, and all three come from
  the same frame -- the last one that carried true-colour rectangles. The
  first cut paired the current frame's count with an older frame's theme,
  which on the bench meant it always read `0`.

## [0.31.22] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.21] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.20] - 2026-08-31

### Added

- **ART RECTS**, under LAST BATTLE: the number of true-colour rectangles the
  last frame that carried any produced, and what the UI theme called itself on
  that frame. For chasing a black ring that appears round every icon on Bill's
  PC under LIGHT and vanishes under DARK. It survives walking from the box to
  the bench, so it can be read at leisure.

## [0.31.19] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.18] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.17] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.16] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.15] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.14] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.13] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.12] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.11] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.10] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.9] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.8] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.7] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.6] - 2026-08-31

### Changed

- **The probe reports whether a mod owns the world pass.** `E11 I11 N10 S1
  D0` says the draw list is whole — `ipairs` walks all eleven — and that the
  entity loop nonetheless never ran, because not one NPC draw happened.

  There is exactly one branch of `drawWorld` that skips that loop: `if
  override then -- the pipeline owns the whole frame; nothing else draws into
  the world`. The tilt path still calls `NPC.draw` through its billboards, so
  it cannot be that one, and a hole in the list is ruled out by `I11`.

  `W` says whether a registered world pipeline is eligible this frame. `W1`
  with `D0` means a pipeline is rendering the world and is not drawing the
  NPCs — a mod outside this channel, since none of these four registers one.
  `W0` means that branch is not the explanation and the reading needs another
  look.

## [0.31.5] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.4] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.3] - 2026-08-31

### Changed

- **The probe walks the draw list as well as measuring it.** `E11 N10 S1 D0`
  said the list holds eleven, ten of them NPCs, that one sprite drew and that
  **no NPC draw happened at all**. One sprite and no NPC draws is the player —
  the player is not an NPC — so the loop drew entity 1 and never reached
  entity 2.

  `E` is `#`, and `#` on a table with a hole is allowed to return any border:
  with a nil at index 2 and values at 3..11, both 1 and 11 are correct answers
  and Lua's binary search usually gives the larger. The draw loop is `ipairs`,
  which stops dead at the first nil. So `E` and the loop can disagree, and the
  reading is consistent with a hole one entry into the list.

  `I` counts how far `ipairs` actually gets. `E11 I1` proves the hole and
  turns this into a hunt for whoever punches it; `E11 I11` says the list is
  whole and the branch that skipped the loop is the bug instead.

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
