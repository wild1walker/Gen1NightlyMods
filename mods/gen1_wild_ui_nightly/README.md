# Gen1WildUI Nightly

**The visual half of the [Gen1Wild](https://github.com/wild1walker/Gen1Wild)
suite, as one mod.** Nine features from nine sources.

> This is the **nightly** build. It is
> [Gen1WildUI](https://github.com/wild1walker/Gen1WildUI) with changes that
> have not been cut into a stable release yet, it installs under its own id
> (`gen1_wild_ui_nightly`) and it conflicts with the stable one on purpose —
> run one or the other, never both. Its settings live in a bucket of its own,
> so running the nightly does not disturb what the stable one remembers, and
> the stable cart is untouched. See
> [the channel's README](../../README.md).

Where the stable bundle assembles `modules/` out of `upstream/` submodules and
`maintained/`, this fork carries **`modules/` as its source**: there is nothing
to sync from and nothing to assemble, so `tools/build.py` and `tools/sync.py`
are not here. `tools/rebase.py` in the channel's root is what a fork has
instead — it fetches two stable releases and offers the diff between them for
merging, rather than overwriting a tree that has diverged on purpose.

## UI THEME

`START > OPTION > UI THEME` cycles **`LIGHT`** (the default, and what every
build before this one looked like), **`DARK`** and **`COLORFUL*`**.

Every page this suite draws is black and white on purpose: the art is the
game's own four DMG shades and the colour arrives afterwards, from the SGB
pass. So a theme swaps the four colours a zone carries and nothing else —
`runtime/theme.lua` wraps `render.zones` and hands the same pixels a different
palette. Nothing is redrawn, no screen is edited, and no feature knows themes
exist.

Which frames it answers for is decided by **whose the frame is**: the topmost
state on the stack that either says what it is (`state.gen1wildTheme`, which
this suite's own screens set) or is one of the engine UI classes named in
`Theme.PAGES` is the page. A state that owns the frame's palettes and is
neither — the overworld, a battle, the title screen — ends the search, so none
of those is ever touched; an overlay that owns no palettes, like a text box or
a fade, is stepped over, so a confirm box on top of a menu leaves the menu
themed.

That covers the OPTION screen, the mod manager, the Pokédex and its entries,
the party menu, the summary, the naming screen, the town map, the trainer card
and diploma, the Hall of Fame PC, and every list the engine builds through
`ListMenu` — which is the bag, the shops, Bill's box and the PC. Screens that
are pictures rather than pages (the intro, Oak's speech, the credits, the
slots, the trade animation, the title screen) are deliberately left out, and so
is the COLORS picker, which has to show colours as they are.

**Menu boxes are themed by their own rectangle.** A box drawn *on* a screen —
the START menu over the map, the bag's windows, a field-move list — owns no
palettes, so the engine hands the frame to whatever is underneath and the theme
correctly declines it. Those are themed as **panels** instead: a state that
carries `tx`/`ty`/`tw`/`th` (which is every `src/ui/Menu.lua` box, and the
suite's own windows) gets a zone over exactly that rectangle, so a white menu
goes black over a map that does not move. A screen with several boxes can say
where they are with `state:gen1wildThemePanels()`.

**True-colour art gets a matte.** `PaletteFX.markTrueColor` blits a rectangle
raw so a coloured icon keeps its own colours — and raw means the white page
under it stays white when everything around it goes black. Every screen in the
suite that marks a rectangle now paints `theme.matte(hint)` into it first, so
the box behind an icon goes with the page. Under `LIGHT` that colour is white,
which is what those screens always drew.

Engine screens that draw true-colour art and that this suite does not replace —
the trainer card's portrait and its badges — still show a light box. Fixing
those means replacing those screens' draw, which has not been done yet.

One honest limit: this works by changing the colours a zone carries, so it
works in the display modes that use them — `SGB`, `SGB INV`, `ADVANCED`,
`OG RED`. The flat modes (`OG`, `OG INV`, `CLASSIC`, and a custom ramp) are the
player asking for one palette over the whole game, and `PaletteFX` replaces
every zone's colours to give it to them. A theme cannot outrank that and does
not try — `OG INV` already is a dark mode for the whole screen.

`COLORFUL` is saturated on purpose. Each screen has a four-colour ramp — a
light, clearly coloured **paper** that black type reads on at 9:1 or better, a
**mid**, a **deep** that carries white type at 4.5:1 or better, and an **ink** —
and a screen that knows what its rows *are* paints them itself through
`state:gen1wildThemeZones(tint, theme)`:

- the **party screen** gets a band across its header and footer in the page's
  deep shade, and every Pokémon a card the width of its row in that Pokémon's
  own species colour — the colour `SPECIES COLOURS` already puts on its icon,
  brought out to the whole card. The icon cell and the HP bar keep their own
  palettes: a screen's zones splice in *above the page and below its own*, so
  a full bar is still green rather than the colour of the card behind it.
- the suite's **own menu screens** colour each card by what it opens.

It still wears an asterisk because the **bag**, the **box**, the **dex list**
and the battle command grid do not paint themselves yet. See
[CHANGELOG.md](CHANGELOG.md).

Its other half is [Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL),
which carries the quality-of-life features. The two know about each other: a
feature in one can still find a feature in the other.

## What is in it

Everything here is a row in `OPTION > GEN1WILD UI`, switched on or off by
itself. Nothing is all-or-nothing.

| Feature | From |
|---|---|
| **BACKDROPS** | [Gen1Arena](https://github.com/wild1walker/Gen1Arena) — 2D backdrops behind battles, picked by map, tileset and how the encounter started |
| **BATTLE MENUS** | [Gen1BattleUI](https://github.com/wild1walker/Gen1BattleUI) — the battle command and move menus as four buttons in a 2x2 grid instead of a list |
| **BATTLE INTRO** ‡ | originally [widescreen-battle-intro](https://github.com/ShaneMcGovernIE/gen1recomp-widescreen-battle-intro) — the intro flash across the whole window instead of a centred 4:3 square, plus flashless intros and a fade to black |
| **POKEDEX** | [Gen1Dex](https://github.com/wild1walker/Gen1Dex) — a Pokémon beside every entry, base stats, evolutions, the full movelist, and an AREA screen |
| **POKEMON BOX** | [Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox) — Bill's PC as the box it stood in for: party left, twenty slots right |
| **PARTY MENU** | [Gen1Party](https://github.com/wild1walker/Gen1Party) — every Pokémon in its own species colours instead of six sharing one |
| **BAG** | [Gen1ModernBag](https://github.com/wild1walker/Gen1ModernBag) — seven pockets, an icon on every row, auto-sorting, favorites, search, no capacity limit |
| **MENU LAYOUT** † | [Gen1MenuManager](https://github.com/wild1walker/Gen1MenuManager) — reorder the START and PC menus, hide rows, pin field moves |
| **MOD MANAGER** † | [Gen1ModMenu](https://github.com/wild1walker/Gen1ModMenu) — the mod manager redrawn in the game's own OPTION-screen idiom |
| **ITEM INFO** ‡ | what every item is, and a picture of it, in the mart, in the item PC and on an ABOUT row in the bag — and those screens redrawn to have somewhere to put it |
| **ELEVATOR PANEL** ‡ | the lift's WHICH FLOOR? list as a small panel against the edge, with the car still on the screen behind it |

All eleven ship on.

† Also in [Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL). These two
are not really visual overhauls — they are the furniture everything else is
reached through — so both halves carry them and neither loses them. Install
both bundles and exactly one of them sets it up; see
[Features in both bundles](#features-in-both-bundles).

‡ Maintained in this repository rather than tracked. The source is under
`maintained/`, edits go straight in, and nothing syncs it from anywhere. For
`BATTLE INTRO`, which began as somebody else's mod, the credit for what it
does still belongs to the person named in [Credits](#credits); `ITEM INFO` and
`ELEVATOR PANEL` were written here.

## The menu

```
OPTION
  WILD GREEN          11 MODS            <- in place of the MODS row
    POKEMON           ALL 3 ON
      POKEDEX         ON (CONFIGURE)     <- LEFT/RIGHT switches it
        SPECIES COLOURS  ON              <- A opens this
        AREA HINTS    ON
        ...
      PARTY MENU      ON (CONFIGURE)
      POKEMON BOX     ON (CONFIGURE)
    BATTLE            ALL 3 ON
      BACKDROPS       ON (CONFIGURE)
      ...
    ITEMS             ALL 2 ON
    INTERFACE         ALL 3 ON
    OTHER MODS        2 MODS             <- anything else that is loaded
    MOD MANAGER       11 INSTALLED       <- the engine's own MODS screen
```

The top row takes the OPTION screen's own `MODS` row rather than sitting next
to it, and `START > MODS` opens the same screen. It is named after the cart
when one is running — `WILD GREEN` — and after the bundle (`GEN1WILD UI`) when
one half is installed on its own. The engine's mod list is `MOD MANAGER` at the
bottom, one press further in.

The cards are the same six in both halves and in the same order, so the menu
reads the same way round whichever half you opened. A card with nothing in it
is not drawn.

`LEFT`/`RIGHT` switches a feature or changes a setting, `A` opens a card, a
feature's settings, or an explanation of the row, `B` goes back. Every feature
screen ends in `RESET DEFAULTS`.

A row marked `*` needs a relaunch to take effect, and the footer says so. Every
feature here except `BACKDROPS` is in that category: their upstream mods have
no off switch of their own, so the bundle gates them at load rather than
pretending to switch something already installed.

## What is different from the standalone mods

Nothing about what they do. The source is vendored unmodified from each mod's
own repository and re-read on every sync; the bundle only decides which of them
load and where they are configured.

Two things are worth knowing:

- **`PARTY MENU` reads `POKEDEX` and `POKEMON BOX`** when they are on, the same
  way it does when the three are installed separately. Switching either off
  changes what it can show.
- **`BATTLE INTRO` is configured here.** It keeps `FLASHLESS INTROS` and
  `BLACK OUTRO` in the save's own options and used to add them to the engine's
  OPTIONS screen; the bundle rebuilds those two rows on its own screen instead,
  so each setting has one home. Their defaults are the mod's own, unchanged.
- **`MOD MANAGER` sets three of its own rows** (`SORT`, `HIDE OFF`,
  `W/OPTIONS`) through the engine's mod manager, which writes them without the
  bundle's prefix. The runtime keeps both spellings in step, so those rows
  behave the same whether they are set from its own quick menu or from this
  bundle's.

## Features in both bundles

`MENU LAYOUT` and `MOD MANAGER` are in Gen1WildQOL too. They are how every
other feature is reached — the START menu, the PC menu, the mod manager itself
— so neither half is the right place to put them and neither half should go
without.

Both bundles would install them twice, and neither mod guards against that:
Gen1ModMenu would wrap the manager screen around its own wrapper, and
Gen1MenuManager would apply its row order to an order it had already applied.
So the two bundles agree on who does it. The first to load claims the feature
through a table parked on a shared engine module; the second sees the claim and
stands down, and its menu row says where the settings are:

```
GEN1WILD UI
  MOD MANAGER     ON (SET UP IN GEN1WILD QOL)
```

The switch on that row is still the real switch — settings for a shared feature
are stored under `gen1_wild_shared` rather than under either bundle, so both
menus read and write the same values, and installing the other half later does
not reset anything.

Which bundle wins does not matter and is not forced: both carry the same mod
pinned at the same version. `tools/check.py` cross-checks the declaration
against the other repo when it is checked out beside this one, because getting
it wrong in one of them fails silently.

## Installing

**MODS > Import mod .zip**, using the `.zip` from
[Releases](https://github.com/wild1walker/Gen1WildUI/releases/latest). Or copy
this folder into the game's `mods/` directory.

Uninstall the standalone versions of anything above first — the manifest
declares them as conflicts, because they install the same hooks. Settings do
not carry over: they are stored under this bundle's id.

## How it stays up to date

Source lives in one of two places, and which one says who looks after it:

| | |
|---|---|
| `upstream/<Repo>/` | A submodule pinned to a release. Somebody else's mod, tracked, never edited here. |
| `maintained/<Dir>/` | Source this repository looks after itself. Edited here; nothing syncs it. |

`tools/build.py` copies from whichever applies into `modules/`, which is what
the game reads. `tools/check.py` fails if a feature is in both, in neither, or
declared as one and sitting in the other.

For the tracked eight:

```sh
git submodule update --init --recursive   # first time
python3 tools/sync.py                     # move every pin to its newest release
python3 tools/sync.py Gen1Dex             # or just one
python3 tools/sync.py --dry-run           # report, change nothing
```

`sync.py` moves the pins and rebuilds `modules/`, which is what the game reads.
Then look at the diff and commit it:

```sh
git diff --stat modules upstream
python3 tools/check.py
git add upstream modules && git commit
```

An upstream that **adds an option row** needs nothing: the schema is read at
load, so the row appears in the menu on its own. An upstream that **adds a
whole feature**, **renames an option key** or **moves its entry file** needs an
edit to `features.lua` — and `tools/check.py` fails loudly if it does.

## Layout

```
main.lua              bootstrap; loads the runtime and gets out of the way
features.lua          what is in the bundle and how each piece is switched
runtime/              how a bundle hosts a mod written to be standalone
  loader.lua            reading and loading a bundled mod's own files
  facade.lua            the `mod` object each feature is handed instead
  optionset.lua         one options table for mods that each expected to own it
  registry.lua          mod.find, across features and across both bundles
  claims.lua            who installs a feature that is in both bundles
  menu.lua              the OPTION screens
  bundle.lua            the order all of the above happens in
adapters/             per-feature bundle glue, run after a feature installs
upstream/<Repo>/      submodules; tracked, never edited here
maintained/<Dir>/     source this repository looks after itself
modules/<Dir>/        built by tools/build.py; what the game loads
tools/                build.py, sync.py, check.py
tests/                headless coverage of the runtime seam
```

`modules/` is committed rather than built at install time, because a mod is
installed by copying a folder and nothing runs a build. CI rebuilds it and
fails if it differs from what is committed, so the two cannot drift.

`runtime/` is byte-identical to Gen1WildQOL's. The two bundles are the same
machine with different feature registries.

## How it works

Seven mods that were each written believing they owned the options table is the
whole problem. Two of them call a row `species_colours`; across both bundles
five call their master switch `enabled`. Merged naively they would share
storage, and turning off one feature would turn off another.

So no feature is given the real `mod` object. Each gets a facade that keeps its
assumptions true from the inside:

| It asks for | It gets |
|---|---|
| `mod:read("chrome.lua")` | `modules/<Feature>/chrome.lua` |
| `mod.options:get("species_colours")` | `<feature>_species_colours` |
| `mod.save:get("last_pocket")` | `<feature>.last_pocket` |
| `mod.cache:read("layout")` | `<feature>.layout` |
| `mod.find("Gen1Dex")` | the sibling's exports, in either bundle |

Anything the facade does not name falls through to the real mod untouched, so
hooks, events, world, UI and content behave exactly as they always did — and a
feature that starts using a new engine API keeps working without the facade
being taught about it.

`mod.find` is the interesting one. `Gen151` — over in the QOL bundle — asks for
`Gen1Dex` to hang catch hints off the Pokédex. A lookup goes to this bundle
first, then to the paired bundle through its exports, then out to the engine,
so the optional-dependency graph survives being cut in half.

There is a headless test for each of those seams:

```sh
luajit tests/runtime_test.lua
```

## Credits

Everything here is somebody's work, and mostly not mine:

- **FAFF0x** — *Modern Bag*, which `Gen1ModernBag` is a derivative of, taken at
  upstream 1.6.0. Nearly all of what that feature does is FAFF0x's work; the
  MIT notice travels with it.
- **LibertyTwins, princess-phoenix, carchagui, aveontrainer, WesleyFG,
  kWharever, worldslayer608** and **knizz** — the *Battle Backgrounds Patch FR*
  art `BACKDROPS` draws. None of it was made for this mod, and its authors ask
  that the names travel with it.
- **[ShaneMcGovernIE](https://github.com/ShaneMcGovernIE/gen1recomp-widescreen-battle-intro)**
  — *Widescreen Battle Intro*, essentially whole. `BATTLE INTRO` is their mod
  with the bundle's menu around it. Maintained here now, theirs by origin.
- **[Pokémon Polished Crystal](https://github.com/Rangi42/polishedcrystal)**,
  maintained by **Rangi** (Rangi42), and its graphics contributors — the item
  icons `ITEM INFO` and `BAG` draw, recolored from that project's own palette
  data and scaled to the sixteen pixels a Gen 1 list row is high. None of that
  art was made for this bundle and none of it is mine; that project ships no
  licence file, so what it asks for is credit and a word before a wide
  release. [`modules/Gen1ItemInfo/CREDITS.md`](modules/Gen1ItemInfo/CREDITS.md)
  is the full attribution and the terms — read it before you redistribute the
  assets.
- **[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp)** and
  **[pret](https://github.com/pret)** — the engine and the disassemblies all of
  it stands on.

The bundling is MIT -- see [LICENSE](LICENSE), which says what that does
and does not cover. Each vendored mod keeps its own licence file under
`modules/<Feature>/`, and those are the terms for that feature.

Contributions belong in the mod's own repository, behind its link above. Fixes
to the bundling itself belong here.
