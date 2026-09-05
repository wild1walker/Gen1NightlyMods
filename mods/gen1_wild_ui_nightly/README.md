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
build before this one looked like) and **`DARK`**.

Every page in this game is drawn in black and white on purpose: the art is the
game's own four DMG shades and the colour arrives afterwards, from the SGB
pass. So a theme swaps the four colours a zone carries and nothing else —
`runtime/theme.lua` wraps `render.zones` and hands the same pixels a different
palette. Nothing is redrawn, no screen is edited, and no feature knows themes
exist.

Which frames it answers for is decided by **whose the frame is**: the topmost
state on the stack that either says so (`state.gen1wildTheme`, which this
suite's own screens set) or is one of the engine UI classes named in
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

**True-colour art gets a matte**, which is an `ADVANCED` concern and only an
`ADVANCED` one. `PaletteFX.markTrueColor` blits a rectangle raw so a coloured
icon keeps its own colours — and raw means the white page under it stays white
when everything around it goes black. But `Renderer`'s `withTrueColor` opens
with `if not PaletteFX.honorsTrueColor() then return zoneList end`, and on a
Gen 1 game that is `PaletteFX.mode == "redpp"` — `ADVANCED`, nothing else. In
every other mode the marks are discarded, the art goes through the shade pass
with the rest of the screen, and there is no box.

Screens this suite owns paint `theme.matte()` into the rectangle before the art
goes in. Screens it does not own — the trainer card's portrait, the summary
screen's Pokémon, the Hall of Fame PC, the diploma — are handled by
[`runtime/matte.lua`](runtime/matte.lua), which wraps the class's `draw` and
runs it twice: once with `markTrueColor` swapped for a recorder to learn where
the art goes, then the matte, then the real draw on top of it. That costs a
second draw of a static screen, and it is only ever paid when a theme is on
**and** the mode is `ADVANCED` **and** the screen actually marked something.

**Item icons swap their ink.** All 106 shipped item icons draw their line work
in pure black on transparency and carry no white at all — the art was made to
sit on the white page, and the page *is* a Poké Ball's lower half. Matting the
cell dark takes that paper away and leaves a black outline nobody can see, so
on dark paper each icon is drawn from a twin built at load with its pure-black
pixels white. Everything else is left exactly as it is, so a ball keeps its red
dome and reads as a white outline over the dark page.

Not a flood fill of the enclosed transparency, which was tried first and does
not work: the outlines are **not closed**. They never had to be, because inside
and outside were the same white page.

**Which display modes this works in.** `ADVANCED` is the one it is built for
and tested against. `SGB`, `SGB INV` and `OG RED` work too — all four pass a
zone's colours through to the blit. The flat modes (`OG`, `OG INV`, `CLASSIC`,
and a custom ramp) do not, and cannot: they are the player asking for one
palette over the whole game, and `PaletteFX.effectiveColors` replaces every
zone's colours to give it to them. A theme cannot outrank that and does not try
— `OG INV` already is a dark mode for the whole screen.

**There were three.** `COLORFUL` — a saturated tint per screen, a band across a
header, a card per Pokémon in its own species colour — was taken out at 0.8.0
rather than finished. Carrying a half-built third option through the file that
every frame of the game runs through is a worse trade than looking it up in the
history if it is ever wanted back.

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

## Standing beside a voxel mod

A [voxel mod][voxel] redraws the overworld as a 3D diorama and can draw the
battle over the map instead of over white paper. **None of them is required
here and nothing changes if you have none** — which is almost everybody, and is
why this is worth writing down: the work is invisible until it is wrong.

There is not one of them. The original Dramatic Shape is defunct and three
maintained forks have grown out of it, each under an id of its own because only
one may run at a time:

| Mod | Id | The battle HUDs |
|---|---|---|
| [DramaticShapeVoxelMod][fork] (absol89) | `BATTLE_ART_VOXEL_FORK` | onto its world canvas |
| [DRAMALESS_SHAPE][dramaless] (artyrambles) | `DRAMALESS_SHAPE` | left in the frame |
| [potato_voxel][potato] (ShaneMcGovernIE) — tuned for low-end devices | `potato_voxel` | left in the frame |
| Dramatic Shape, defunct | `DRAMATIC_SHAPE`, `dramatic_shape_brick`, `ds_fp_ceiling` | onto its world canvas |

All six ids are optional dependencies, so a voxel mod loads ahead of this
bundle without any of them becoming required, and all four forks are reached
the same way — `exports.lib.require(name)`, which every one of them publishes.
So the id list is only about *finding* the mod; nothing downstream branches on
which one was found. A fifth fork appearing is one line in
[`runtime/voxel.lua`](runtime/voxel.lua).

### The one thing they disagree about

The right-hand column. The Dramatic Shape lineage lifts the battle HUDs out of
the flat 160x144 frame and composites them into its world canvas at the
battle's own scale; the other two override the world *behind* the frame and
leave the HUDs, the text box and the menus exactly where the engine drew them.

That decides where anything drawn **next to** a HUD has to go, and it is not a
property of the mod — the snapping lineage declines on iOS, and has not
snapped anything on the frames before a battle's first one. So it is asked per
frame, through the fork's own `snapHUDs`, and **the answer is no unless
something said yes**. A fork with no handshake at all never reports snapped,
which is exactly right for it.

Getting that default the wrong way round is not a subtle failure: the world
canvas is window-sized, so an overlay drawn onto it at 160x144 coordinates
lands nowhere near the HUD.

[voxel]: https://gen1recomp.org/voxel-mod
[fork]: https://github.com/absol89/DramaticShapeVoxelMod
[dramaless]: https://github.com/artyrambles/DRAMALESS_SHAPE
[potato]: https://github.com/ShaneMcGovernIE/potato_voxel

### What it costs here

The XP bar. It sits under the player's HUD, so when that HUD moves onto the
world canvas the bar goes with it — at the HUD's own scale, which the fork
gives its own setting (`HUD SCALE`) and which the rest of the battle does not
share. Where it lands is read out of the fork's published `HUD_RECT` and
`snapRects` rather than copied from its arithmetic: one is the other
transformed, so the bar keeps finding the HUD when the fork retunes its layout.
A fork that snaps the HUDs but publishes no geometry gets no bar rather than a
guessed one.

## Gold, Silver and Crystal

The bundle claims `gen1` and `gen2`, and on a Gen 2 boot seven of its eleven
features install: **BACKDROPS**, **POKEDEX**, **BAG**, **PARTY MENU**,
**MENU LAYOUT**, **MOD MANAGER** and **BATTLE MENUS**, plus **UI THEME**.
Most of them install whole; **BATTLE MENUS** installs one part of itself, for
the reason under the table.

The other four stand down, and for the most part that is the honest answer
rather than a shortfall. This bundle exists to give Red the screens Gold
already shipped:

| feature | why not on Gold |
|---|---|
| **POKEMON BOX** | Gold's Bill's PC is already a box — the name in its own panel, five nicknames down the right, and the mon, level, gender and species of whatever the cursor is on. |
| **ITEM INFO** | Gold's PACK and MART already print an item's description under the list, with a TM showing the move's. The text is the cart's own. |
| **ELEVATOR PANEL** | Gold's lift is already a small panel against the right edge with the car on screen behind it. |
| **BATTLE INTRO** | Gold's battle already draws edge to edge, and its intro is the cart's animated wipe. |


Each verdict is written next to its feature in `features.lua`, with what was
checked to reach it.

### BATTLE MENUS on Gold: the frame, and nothing else

This one was on the table above for six releases, and the reasoning held right
up to the part that mattered. Gold's command menu really is a 2x2 already —
`col = ((i-1)%2)*spacing`, `row = floor((i-1)/2)*2` — its battle really does
have an XP bar with the cart's own fill sound, and its move list really does
carry the type and PP panel that Red's arm has to build for itself.

What Gold does not have is the **frame**. Its four commands are four words in
one box across the right of the strip; Red's arm draws four boxes, one per
command. That is the difference between a block of text and four buttons, and
it is the one the report was about.

So the Gold arm is that and nothing else: four 10x3 boxes tiling rows 12–17 —
the same `CLASSIC_BOXES` the Gen 1 arm draws, because Gold's bottom strip is
the same twenty tiles by six — with the cart's own labels and the cart's own
hand in them. Nothing about what the menu *does* is touched: `menuIndex` is
still the cart's and is still moved by the cart's own input handling. The move
list, the bug contest's menu and every message keep the cart's own box.
`COMMAND GRID` turns it off.

### BACKDROPS on Gold

The seam is cleaner than Red's. Gold's battle field is one `Chrome.clear()`
call — the first line of `BattleState:drawPanel`, and the only one in the file
— so the backdrop goes in ahead of that instead of behind Red's
geometry-matched `love.graphics.rectangle` shim. There is no wide arm either:
Gold's battle is 160x144 inside `Chrome.withPanel` whatever the window does.

**No new art was needed, and the reason is that there never was any Kanto
art.** All twenty backdrops are FireRed *terrain* scenes. Six carry Kanto boss
names only because FireRed assigned them that way, and Giovanni, Lorelei and
Agatha are not in this game — so their snowfield, ice cave and desert are free,
and Johto has an immediate use for them:

| scene | Kanto | here |
|---|---|---|
| 14 Snow | Giovanni | RED, on Mt Silver |
| 15 Snow Cave | Lorelei | KAREN, and the **ICE PATH** |
| 16 Snow Mountain | Bruno | Bruno, in both games |
| 17 Desert | Agatha | KOGA |
| 18 Volcano | Lance | Lance, the Champion here |
| 19 Space | the Champion | WILL |

All twenty scenes are reached. Two *files* are not, and neither is a picture:
`museum.png` is byte-identical to `indoor.png`, and `tower.png` is that same
image with GRAYMON baked into it.

#### The tower, and why it does not use the tower

`tower.png` is not a picture of a tower. The pack's own Pokémon Tower scene is
slot 13, and its author drew 13 as an outdoor plaza under open sky — so this
mod gave 13 to `town` and built the tower out of **10 Indoors**, the same art
as `indoor`, `club`, `mansion`, `museum` and `ship`, with one thing done to it:
GRAYMON at 0.80 strength.

And GRAYMON is a Gen 1 fact. Red routes its tower by
`FieldDefaults.byTileset = { CEMETERY = "GRAYMON" }` — the Pokémon Tower wears
a mourning palette rather than Lavender's roofs.

Gold has no CEMETERY tileset, no GRAYMON, and no per-tower palette at all: its
map colours come from `environments[environment][daytime]`, shared by every
INDOOR map on the cart. Crystal's `specialTilesets` — the list of tilesets the
game *does* give their own colours to — is six long and has no tower on it.

So Sprout Tower, the Tin Tower and the Tin Tower's floors take the plain
interior here. That is not a downgrade, it is the transcription: on Gold those
walls really are the same palette a Poké Center's are. The Burned Tower's
basement is the exception and takes the cave, because it is a collapsed pit
rather than a room.

Two of the three selection inputs are also *better* here than on Red, because
Gold's map header carries what Red made this mod guess:

- **`environment`** — TOWN / ROUTE / INDOOR / CAVE / GATE / DUNGEON, straight
  off the header. Red has no such field, so its arm has to infer from the
  tileset whether an unmapped map is a room. Here an unmapped tileset still
  gets a right answer.
- **the roofs** — in the data, so a town variant is generated rather than
  hand-listed.

One thing the header cannot say is which maps are gyms: Gold has no GYM
tileset, so a gym sits on its town's tileset and the sixteen are named
explicitly. So are the S.S. Aqua's decks and `SILVER_CAVE_OUTSIDE`, each of
which is the wrong shape for its tileset — the same class of override the Gen 1
arm keeps for the S.S. Anne.

#### Town colours

Generated, not drawn — as they always have been. Gold's `RoofPals` is indexed
by **map group** (Red's `roofByMapIndex` is per city map), so every map in a
group shares one roof pair and a group is a town's colour. Twenty-one of Gold's
twenty-six groups contain a town, which is every town in both regions:

```sh
python3 tools/make_gen2_towns.py <save-dir>/data/generated/palettes.lua
```

All twenty-one folders are committed under `og/gen2/`, so a Gen 2 boot has its
town roofs with nothing to run. The script is kept because the art is a
function of the game's own numbers and should be rebuildable from them;
`palettes.lua` comes from your own cartridge import and is the one input that
cannot live here. Kanto is regenerated rather than shared with Red's eleven
folders, because Gold repaints Kanto — its Cerulean is not Red's Cerulean.

### BAG on Gold

Three additions to the cart's PACK, not a replacement bag.

Gold's PACK already has the two biggest things this mod gives Red's: pockets,
with the cart's own tab strip, and a description under the list with a TM
showing its *move's* description rather than the TM's. Red has neither.

What is left is how a pocket's list is **built**, and that is one method —
`PackMenu:rebuild`, which reads `save.inventory` through `Bag.order` and writes
`self.rows`. Everything here happens after that and before the draw: filter,
sort, float the pinned. The cart keeps the selection, the quantity flow, the
tab strip and every pixel of the drawing.

**The capacity limit needed nothing at all.** That patch wraps `Bag.add` and
`Bag.capacity`, and `src/inventory/Bag.lua` is *shared* — Gold's own PackMenu
requires it and orders its rows through it. So it was already
generation-agnostic, and it lifts a *check* rather than changing a layout:
`save.inventory` is an id-to-count table on both carts either way.

**The keys.** Gold's PACK reads left/right, up/down, A, B and SELECT (the
cart's own item move). START is the only key it does not read, so START opens
SORT and SEARCH. PIN goes on the item submenu instead, because it is a thing
you do to one item and that menu is the cart's idiom for exactly that — and
only one row is added, which is a limit rather than a preference: the submenu
box is drawn upward at two rows an entry, so six is the last that fits and the
cart already uses five.

Search is typed on Gold's own naming screen — the cart's keyboard, rather than
a text field of ours.

**FAVOURITES is the one thing that did not port.** On Red it is a virtual
*pocket*; Gold's tab strip is four fixed pockets from the cart's own table, and
a fifth would mean replacing the strip, which is the one thing this arm exists
to avoid. PIN does the half of it that fits: an item you want at hand sits at
the top of the pocket it already lives in.

### POKEDEX on Gold

Three extra pages on the cart's own entry screen, not a replacement dex.

Gold's Pokédex is good, and already carries two of the three things this mod
was built to add to Red's: an AREA screen with blinking nests, and a working
search with NEW / OLD / A-Z on SELECT. Registering over `Gen2PokedexMenu` would
mean re-implementing both to stand still.

What Gold has no answer for is the third — its entry is two pages of flavour
text and nothing else. So the Gold arm adds **STATS**, **EVOLVES** and
**MOVES**, and puts them where the cart already has a control that means "next
page": `PAGE` counts on past its two into ours, and back round to one.

That is deliberately not a new key. `DexEntryScreen_MenuActionJumptable` gives
the entry four actions along row 17 and PAGE is already one of them, already
labelled, already on screen. `A` is not intercepted to do it either: PAGE is
the only one of the four that moves `self.page`, so the cart is left to run the
press and the page is read afterwards.

Everything above the entry's divider — the pic, the name, the number, the
footprint, the height and the weight — stays the cart's on every page, so these
read as more of the same entry rather than a second screen wearing its frame.
Only the description panel changes: rows 11 to 15, eighteen columns. Row 11 is
the page's own name, because Gold's page marker is two tiles of "P" over a
digit and its sheet has no digit past 2.

**Six stats, and no bars.** Gen 2 split Special in two, so the stats page
prints six where Red's prints five — in two columns of three with the total
underneath, which is exactly what four content rows hold. There are no bars
here for the same reason the Gen 1 page gives for having none: a bar wide
enough to read costs room the column has not got, and a number you can compare
is worth more than a bar you cannot. That argument is stronger on an
eighteen-tile panel, not weaker.

**All five Gen 2 evolution methods.** A level, a stone, a trade (with its held
item named when there is one), happiness with its time band, and TYROGUE's
attack-versus-defence comparison with the level it happens at. A method a
content mod adds and describes still wins, through the `gen2EvolutionMethods`
registry. An evolution target you have never met is masked `?????` exactly as
on Red — the mask reads Gold's `into` field as well as Red's `species`.

`UP` and `DOWN` scroll the two pages that can outrun their panel — the movelist,
and EEVEE's five evolutions. Both are unbound on Gold's entry view, so nothing
is taken away.

The reading is `dexdata.lua`, which is pure and shared: the Gold arm and the
Gen 1 arm cannot drift apart about what a base stat is or which evolution a
species has.

### PARTY MENU on Gold

The one feature here that Gold needs as much as Red does.
`PartyMenu:drawIcon` colours every row out of `palettes.partyMenu[1]`, so six
Pokémon share one palette — which is Red's single MEWMON zone over all six
rows, written in CGB instead of SGB.

The Gold arm hands `drawIcon` a palettes table whose `partyMenu[1]` is that
mon's own pair from `Palettes.monColors`, for the length of one call. Nothing
is redrawn: the icon, the bob, the held-item marker and the cursor offset are
all still the cart's. `START: PARTY` comes with it; `RULED ICONS` and `MOVE NOT
SWITCH` do not, because they are settings for the Gen 1 screen and a row that
cannot do anything is worse than a missing one.

### UI THEME on Gold

Red draws a page in four DMG shades and the colour arrives afterwards from the
SGB pass, so the Gen 1 theme rewrites that pass's zone list. Gold is a CGB game
whose colour is already in the picture — `render.zones` is still raised there,
but it carries nothing to reverse, so a theme built on it would never fire.

So the Gold arm moves one step earlier, to `Chrome.DEFAULT_BOX_PALETTE`: the
four colours every box, every string and every fill reads when it is handed
none, which fifty-two files under `src/` draw through. They are rewritten in
place, once a frame, from `core.update` — before the frame draws. Same two
themes, same stored row, same promise that a theme which cannot move a glyph
cannot move a glyph off the screen.

In place rather than replaced, because `TrainerCard` passes that exact table to
seventeen calls and identity has to keep holding.

And scoped to pages the way the Gen 1 arm is — which here takes real work
rather than none. Gold's battle field is `Chrome.clear()`, reading this same
table, so an unscoped `DARK` would paint every battle black. The topmost state
decides, over an allow-list of Gold's own page classes plus anything this suite
registered; the overworld is not a stack state on Gold, so a plain overworld
frame finds nothing and is left alone.

The mattes do not load on Gold, and that is not a gap either: a matte paints
the page colour under a true-colour rectangle because Red blits one raw past
the shade pass and brings the white page back with it. Gold has no such pass.

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
