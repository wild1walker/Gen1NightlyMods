# Changelog

All notable changes to this mod are recorded here, newest first.

This mod exists only on the **nightly** channel and carries the channel's
version.

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
