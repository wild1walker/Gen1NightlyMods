# Promoting a nightly to stable

This channel is a **fork**, not a branch. Every mod in it carries an id of its
own so it can sit beside its stable twin without either one winning, and that
rename is the thing promotion has to undo. Nothing here is hard; all of it is
easy to half-do, and a half-done rename fails **silently** — a registry lookup
that cannot find its mod does exactly what it is supposed to do, which is
nothing, quietly.

Two releases have already been spent on exactly that mistake in the *forward*
direction:

* **0.13.0** — `features.lua` still named `gen1_wild_qol` as the UI bundle's
  partner. Every lookup across the pair failed, and `MENU LAYOUT` could not
  arrange the `SELECT` menu.
* **0.15.0** — `shared.owner` still named `gen1_wild_ui`. On a build where no
  engine module can hold the claim table, **both** bundles stand down and
  `MENU LAYOUT` and `MOD MANAGER` go missing entirely.

Going back the other way is the same edit with the same failure mode. Run
`python3 tools/promote.py --check` from a promotion branch and it fails on
every nightly id it can still find.

## What differs, in full

| | nightly | stable |
|---|---|---|
| bundle ids | `gen1_wild_ui_nightly`, `gen1_wild_qol_nightly`, `wild_green_nightly` | `gen1_wild_ui`, `gen1_wild_qol`, `wild_green` |
| `features.lua` → `spec.id` | the nightly id | the stable id |
| `features.lua` → `spec.paired_bundle` | the *other* nightly id | the other stable id |
| `features.lua` → `shared.owner` (×2 per bundle) | `gen1_wild_ui_nightly` | `gen1_wild_ui` |
| `manifest.json` → `id`, `name` | nightly | stable |
| `cart.json` → `id`, `title` | `wild_green_nightly`, `Wild Green Nightly` | `wild_green`, `Wild Green` |
| `cart.json` → `shell` | `#54377e` (purple) | `#14571f` (green) |
| `cart.json` → `load_order` | five entries, `gen1_bench_nightly` last | four, no bench |
| cart label art | carries `NIGHTLY` | does not |
| versions | one channel version, `0.x` | each mod's own |

`shared.storage` is **not** in that table and must not be renamed:
`gen1_wild_shared` is deliberately bundle-independent so a player's menu layout
does not move when the other half wins the claim.

## The bench

`gen1_bench_nightly` is a mod of its own and the stable cart does not pin it.
There is nothing to gut and no flag to remember — see the README section
*"The bench ships on no release"*. Promotion just does not carry it.

Two pieces of bench-facing code **do** live in shipping mods, and neither can
move into the bench (the bench consumes them; it cannot see any mod's
internals, which is the whole design):

* `wild_green/main.lua` publishes `suits()`, `suit()` and `setSuit()` —
  about twenty lines of public API for driving `PLAYER`. Nothing requires them.
* `modules/Gen151/bench.lua` is a debug screen behind a `TEST BENCH` row that
  defaults off. It is **upstream Gen151's own** and ships on stable today;
  promotion neither adds nor removes it.

## Checklist

1. `git fetch` each upstream and confirm the fork's `base` in `nightly.json` is
   still the release you forked from; rebase with `tools/rebase.py` first if it
   is not.
2. Rename the ids in the table above. `tools/promote.py --check` finds the
   ones you missed.
3. Set each mod's version to the stable line it is joining — the channel's
   single `0.x` does not travel.
4. Drop `gen1_bench_nightly` from `load_order`; put the shell, title and label
   back to green.
5. Run every suite in every bundle and each bundle's own `tools/check.py`.
6. Install the built cart and open `START` > `OPTION` > `MENU MANAGER`, then
   `LEFT` to the `SELECT MENU` page. If it lists rows, the pairing survived the
   rename; if it says `NOTHING TO ARRANGE`, one of the ids is still wrong.
   That one screen is the fastest end-to-end proof there is.
