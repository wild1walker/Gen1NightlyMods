<p align="center">
  <img src="label.png" alt="Wild Green Nightly" width="220">
</p>

# Gen1NightlyMods

**The nightly channel for [Wild Green][cart].** This is where changes are
written and tested before they reach the cart everybody else is playing.

The stable cart does not move. [Wild Green][cart] stays exactly where it is,
pinned to released mods, and nothing here can reach it — every mod in this
repository installs under an id of its own and **conflicts with its stable
twin on purpose**. Run one or the other, never both; your save, your settings
and your cartridge are untouched either way.

Nightlies are listed in [Gen1NightlyIndex][index]. Add that index in the game
under **MODS > FIND MODS** and the nightly cart and its mods show up beside the
stable ones, with `NIGHTLY` on the cartridge and a dark purple shell so you can
tell at a glance which one you are opening.

## What is in it

| | What it is | Forked from |
|---|---|---|
| **[Wild Green Nightly](mods/wild_green_nightly)** | the player in green, the names, and `WILD GREEN VERSION` on the title screen | [Gen1MakeItGreen][green] |
| **[Gen1WildUI Nightly](mods/gen1_wild_ui_nightly)** | the visual half of the suite: backdrops, battle menus, the Pokédex, the box, the party menu, the bag, the mod manager — and `UI THEME` | [Gen1WildUI][ui] |
| **[Gen1WildQOL Nightly](mods/gen1_wild_qol_nightly)** | the quality-of-life half: sprinting, autosave, auto continue, followers, all 151, EXP share, menu layout | [Gen1WildQOL][qol] |
| **[Test Bench](mods/gen1_bench_nightly)** | **nightly only.** A `BENCH` row on the START menu with everything this channel is changing on one screen | — |
| **[`cart.json`](cart.json)** | the **Wild Green Nightly** cart: the four above, plus Crystal animated sprites pinned as it is | — |
| **[`carts/wild_crystal_nightly`](carts/wild_crystal_nightly)** | the **Wild Crystal Nightly** cart: the two bundles and the bench, on Crystal | — |

### Two carts, one channel

`Wild Crystal Nightly` is the same suite on the other base game, and it is
where Gen 2 bug testing happens — which is why it pins the **test bench** and
the stable cart it previews will not.

It does not pin `wild_green_nightly`. That mod is Red's player, Red's names
and Red's title screen, and its manifest says `"games": ["red"]`; a Crystal
cart has no use for it. Nor does it pin Crystal animated sprites, which is a
Gen 1 mod bringing Crystal's art to Red and has nothing to bring here.

The cartridge is **dark blue** where the Red nightly is dark purple, and
neither number was picked by eye: both are a `TITLE_SUITS` shadow from
`tools/palette.py`, chosen so all three cartridges in the family are the same
darkness in three of the palette's own colours. `tools/check.py` holds each
cart to its own.

**Its label art is not drawn yet**, so the launcher draws a bare cartridge in
that blue. `check.py` says so as a note on every run rather than as a failure:
a cart with no `label` is legal — cartkit skips the check when the field is
absent — and it is the right state for art that has not been drawn and the
wrong one to stay in.

Where each cart's manifest lives, and why the first one stays at the root, is
written down in [`tools/carts.py`](tools/carts.py). The short version: two
readers outside this repository fetch `<repo>/cart.json` by that exact path,
so the first cart never moves and every cart after it gets a directory.

### The bench ships on no release

The test bench is a **mod of its own**, and that is the whole design. Gutting
the testing weight out of a release is not a refactor, an option to switch off,
or a flag somebody has to remember: it is *not pinning this mod*. The stable
cart pins four mods and this is not one of them, so no release carries a line
of it.

The price is that the bench cannot see the insides of anything — every row goes
through what another mod publishes, and a row whose mod is missing reads `--`.
That is the right price: a bench wired into a mod's locals breaks the mod every
time the mod is edited, and this channel edits them constantly.

## How a nightly is built

The whole channel shares **one version**, and that is the design rather than a
convenience. cartkit resolves a pin by looking for the tag `v<version>` and, on
it, an asset named exactly `<mod id>-<version>.zip` — so several mods can ride
one release, be told apart by asset name, and go out together with the carts
that pin them. `tools/check.py` fails if any manifest disagrees.

Every cart rides that same release, one `.g1rcart` each, named the same way:
`<cart id>-<version>.g1rcart`. That naming is what lets the index tell them
apart, and the index refuses to resolve a cart listing to a cartridge that is
not named for it rather than handing somebody the wrong game.

```
python3 tools/check.py       everything below, in one command
python3 tools/pack.py        build mods/ into dist/, re-pin every cart to it
python3 tools/carts.py       list the carts the channel ships
python3 tools/make_label.py  redraw the cartridge
python3 tools/bump.py        cut the next version, everywhere it is written
python3 tools/rebase.py      bring a fork up to a newer stable release
```

Cutting a nightly is `tools/bump.py`, `tools/pack.py`, and a push: the release
workflow tags `v<version>`, publishes every mod's `.zip` and the cart's
`.g1rcart` on it, and then validates the pins the way a player's launcher will.

### The forks are forks, not builds

The stable bundle assembles `modules/` out of `upstream/` submodules with
`tools/build.py`, and `tools/sync.py` moves the pins. A fork has been edited on
purpose, so replacing its tree would throw away the thing the channel exists
for. `tools/rebase.py` is what it has instead: it fetches the release the fork
was taken from and the one it is moving to, and does a real three-way merge —
upstream's changes go in, this channel's stay, and conflict markers appear only
where both sides moved the same lines. `nightly.json` records which release
each fork stands on.

## What is in this nightly

Everything below is written up properly in each mod's own `CHANGELOG.md`.

### Autosave had never written a file on Gold

Not "sometimes", not "in the wrong place" — never, on any Gen 2 boot since
the bundle started claiming one, and with no error, no warning and the row
reading ON the whole time.

Every question autosave asks about the map was asked as `game.overworld`.
That is Red's `OverworldState` singleton, and Gold does not have one: its
world lives at `game.world` and is not a stack state at all, so an EMPTY
stack is free roam there. `writeWindow` opens with `if not (ow and
ow.player)`, so it answered false on every frame of every playthrough, and
`screenOver` — "is a screen standing over the world" — asked `top ~= ow`
against a world that is never on the stack, which is backwards on the map and
backwards inside every menu.

The six questions are spelled once now, in one block, and nothing below it
knows which game it is on. The veil pair needed the same treatment for the
same reason: Gold's fades are not stack states either. A door, a warp and the
ride back out of a battle are all `World:runMapSetup`, whose ramp is
`world.fade` with `world.fadeLevel` under it — so the covered write, which
is the whole design, had no screen to take. It has the thirteen frames of
held white the cart loads a map under now, fifteen through a warp.

### Auto continue did nothing at all on Gold

The copyright card, the GAME FREAK splash, the attract movie, the title, the
CONTINUE menu and the save panel: all of them, with the row on. The mod knew
one boot. `isGen1Title` asks for `openMenu` and `toMenu`, which Gold's title
has neither of; `isIntro` matched `IntroMovie` and `YellowIntro`, which are
not Gold's cards. Both refusals were right — they are what kept the mod from
erroring there — and both together are a feature that reads ON and is not
there.

Gold's boot is a different set of screens end to end, so it has an arm of its
own. `SKIP INTRO` ends all four cards of the cinema **in one update** rather
than one card per update, because each card's `onDone` pushes the next and
ending them one at a time draws each one for a frame on the way past. `START`
and `A` answer the menu from inside the title's own `onContinue` — the one
place the menu exists and the frame has not been drawn — so the CONTINUE
menu is never seen, and neither is the save panel and the second press it
waits for. What runs is the menu's own payload with the save the menu read
for itself. `B` and `SELECT` mean what they mean on Red.

### `DARK` reaches the START menu, the lift and every line of dialogue

The walk that decides whether a frame is a *page* was written to the Gen 1
arm's rule, and that rule does not cross.

The START menu and the lift panel were left out for being boxes over the
world, which is exactly why Red's START menu is left out on Gen 1 — and
there the reason is real: the box takes its four colours from the SGB zone the
map is wearing, so reversing them reverses the map. Here the world is drawn
from its own tile palettes and never reads the box palette at all, so the
reversal lands on the box and stops.

The dialogue box was stepped over as an overlay and came out white over the
map while the menu the player had just closed was black. The walk tells two
kinds of thing apart now: FURNITURE is drawn through this very palette, a VEIL
draws through nothing. Both are stepped over on the way down, so a confirm
over the PACK still leaves the PACK themed; they differ only at the bottom of
the walk, where a veil over the map is the map and a box over the map is a
box. A box that comes out of a battle still finds a picture under it.

### The white YES/NO box, and the wrong reason it was left

0.32.25 left one box white under `DARK` and wrote it off as an engine gap that
could not be closed without drawing. The second half was true and the first
half was not.

`src/ui/ChoiceBox.lua` is shared between the generations and paints like a
Gen 1 screen, so it reads none of the four numbers the Gen 2 theme rewrites.
But `Chrome.paletteBox` IS `Font.drawBox` with a palette shader around it, and
`printThrough` and `cursorThrough` are `Font.draw` and `Font.drawCode` with
the same one. The "black glyphs on transparent, so they come out black
whatever the color is" note that made this look impossible is about tinting
with `setColor`, not about the palette pass — which is how every other Gold
box already themes. Its own sibling proves it: Gold's dialogue box takes that
fold, and the choice box standing on top of it never got it.

So it is a fold rather than a redesign, and `runtime/choicebox2.lua` is that
fold: the same box, in the same place, out of the same glyphs, through the
live box palette. It is a file of its own because it DRAWS, which is the one
thing the theme promises never to do. It is on under `LIGHT` too, where it
paints Gold's own four numbers and the box is what it always was — a patch
that engages only under one setting is exercised only by the players who chose
it.

The other half of the same bug was worse than the box: the choice box was not
furniture in the walk, so it ended the walk one state early and took the page
under it with it. A confirm over a dark PACK flipped the PACK to white for as
long as the question was up. A question asked inside a battle still finds a
picture under it and is left alone.

### `AREA BANNER` is Gen 1 only

Gold ships this sign. `src/world/gen2/MapNameSign.lua` is the cart's own,
drawn on every map entry that earns one, and it knows the six landmarks that
get none and the park gates that get one late. Every line of the feature's own
design note names Gold as the thing being copied, so on Gold the copy was a
second sign in the same corner saying the same name as the one underneath it.
The arm is removed rather than switched off: it was the only caller of a
monkey-patch on `World.draw`, and a patch on the engine's own draw that exists
to be skipped is a patch that will one day not be.

### The white block over the party screen's message box

Pick the POKéMON already out when a trainer offers you the switch and the "is
already out!" box came up with a hole punched through it. A true-colour mark is
blitted *raw*, and the engine's message box stands at `y=96` — which is under
the engine's own last party row and, since this suite added a header box, a row
and a half *into* ours. The sixth icon's mark was blitting the box's own paper
back un-inverted. A covered row loses its matte and its mark together now.

### Autosave no longer saves a trainer battle as un-won

Beat a trainer, let the autosave take its window, load that save — and the
trainer wanted to fight again. `battle.ended` fires while the battle is still
tearing down; what writes the *win* is the battle's `onFinish`, which runs as
the return transition's onDone, well after. The covered frames the save aims at
are all before the win exists, which is why it happened every time rather than
sometimes.

Neither write path will spend a frame between the two now. Delaying the
*request* — which is all 0.32.2 did — was not enough on its own: a save is very
often already owed when a battle ends, and the return hold is the most covered
screen this mod ever sees, so it got spent there anyway.

### The battle UI came back

0.32.3 shipped with no battle UI at all — no buttons, no panel, no XP bar, and
no vanilla menu underneath either. `battle.overlay` called a function fifty
lines above the `local` that declares it, which in Lua is not that local but a
*global*, and that global is nil: every frame of every battle called nil and
raised, on the one line of the hook not wrapped in a `pcall`. The mod had
already claimed the battle menu, so nothing drew the vanilla one instead.

It compiled, and no test ran a frame. `tools/check.py` now fails on a local
read above its own declaration — `luajit -bl` shows the read as a global fetch,
so a name a file both reads as a global and declares as a local is a forward
reference, always.

### The top of the move panel's `PP` line

Two bugs on one line, found one at a time.

The XP bar was showing through the panel to the right of the numbers: it is
drawn first and the panel covers it, but a true-colour mark re-blits its region
*raw* after the pass is composed, so it came back on top of the panel that had
just covered it. Covering settles the pixels, not the mark — the bar stops at
the panel's edge now and marks only what it drew.

The cut top of `PP` itself was something else. The type name above it is marked
so its colour can leave the palette pass, and the theme rings every mark by a
pixel — with both ends of that ring black. The panel's lines are eight pixels
apart in an eight-pixel cell, so the ring had nowhere to go but the line below,
landing on its first pixel row: ink mapped to black on a black page. The marked
row is a pixel shorter now, which puts the ring in the blank row that already
separates the two lines.

### Every voxel mod, and none of them required

A [voxel mod][voxel] redraws the overworld as a 3D diorama and can draw the
battle over the map instead of over white paper. Nothing in this channel
requires one and nothing changes if you have none.

There is not one of them. The original Dramatic Shape is defunct and three
maintained forks have grown out of it — absol89's `BATTLE_ART_VOXEL_FORK`,
`DRAMALESS_SHAPE`, and `potato_voxel` for low-end devices — each under an id of
its own, because only one may run at a time. The suite knew one of the six ids.

**The forks disagree about one thing, and it is the thing that matters.** The
Dramatic Shape lineage lifts the battle HUDs out of the flat 160x144 frame and
composites them into its world canvas; the other two override the world
*behind* the frame and leave the HUDs where the engine drew them. That decides
where anything drawn next to a HUD has to go, and it is asked per frame now,
through the fork's own `snapHUDs` — with **no** as the default, so a fork with
no handshake at all never reports snapped.

It read the other way round before, so under those two forks the caught marker
was drawn onto a window-sized canvas at coordinates meant for a 160x144 one.

### The XP bar has its 3D-battle path back

Dropped in the move into Gen1WildUI rather than carried half-way, because the
half that decides whether to take it at all is that handshake. It is in place
now, and where the bar lands is read out of the fork's *own* published
geometry rather than copied from its arithmetic — so the bar keeps finding the
HUD when the fork retunes its layout, which its `HUD SCALE` row does.

[voxel]: https://gen1recomp.org/voxel-mod

### The title screen is the right colour in every display mode

`WILD GREEN VERSION` read yellow-green on pale yellow, half the POKE BALL was
skin-coloured and so was the highlight on the copyright line. All three were
the same bug: those colours were named-palette overrides, and two display modes
never consult the palette registry — `OG RED` short-circuits every name to the
boot-ROM pair and `ADVANCED` reads `data/palettes_gbc`, whose own `LOGO1` and
`MEWMON` are exactly that yellow and that skin tone. The two bands are now
recoloured in the frame's zone list as well, which every mode reads.

`MEWMON` was also the wrong four of ours: it covers the mon, the ball and the
copyright line as well as the standing figure, and shade 2 is a light on all of
them and a face on none, so it takes the portrait ramp now instead of the
overworld one whose shade 2 is skin.

### The version ribbon follows `PLAYER`

It used to stay green in every suit, on the grounds that `WILD GREEN VERSION`
is the game's name and not the character's jacket. In front of a player who has
just put the character in purple, that reads as a setting that did not take.
The words still say `GREEN`; only the ink moves.

### `PLAYER` takes effect where you are standing

No relaunch. The recipe already writes all nine suits at install, so switching
colour repoints the record and rebuilds the renderers that had read out of it.
`PORTRAIT SKIN` moves with it. The ribbon's *artwork* and the name list are boot
data and still wait for a restart — the ribbon's *colour* does not.

### Autosave stopped landing in the middle of the fade out of a battle

Two mistakes about the same blind spot: the mod knew a fade is an animation,
and only knew it about the *overworld's* fades. The end of a battle is a stack
state with a veil of its own, and both of the overworld's flags are false the
whole way through it — so the frames of the fade every player watches all the
way through were treated as the quietest in the game, and the expensive half of
a sync cycle ran over them.

And the write itself was taken on the worst frame of the outro. `BLACK OUTRO`
is a linear ramp that was at full black for exactly one frame — the cut, where
it pops itself off the stack, runs the engine's own `finish` and pushes itself
back — so that was the only frame anything looking for a covered one could
find. The outro now holds at the cut for the ten frames the engine's own return
holds, and the save has to see the veil hold before it spends a frame under it.

### No more white bar above a wide arena

A battle asks the renderer for a white surround, which is right when the field
is white paper and wrong when it is a picture: the surround stops disappearing
and becomes a bright frame around the art — and a wide battle is 304x144, so
the bars above and below it are the biggest thing on the screen. The backdrop's
own edge is now stretched into them, so the picture runs off the screen instead
of stopping at a rectangle. `EDGE TO EDGE` turns it off.

### `UI THEME`: `LIGHT`, `DARK`

`START > OPTION > UI THEME`. `LIGHT` is the default and is what every build
before this one looked like.

Every page the suite draws is black and white on purpose — the art is the
game's own four DMG shades, and the colour arrives afterwards from the SGB
pass. So a theme swaps the four colours a zone carries and nothing else.
Nothing is redrawn, no screen is edited, and a theme that cannot move a glyph
cannot move a glyph off the screen.

**`DARK`** reverses every zone on the page: paper black, ink white, the shades
between them exchanged.

There were three. `COLORFUL` — a saturated tint per screen, a band across a
header, a card per Pokémon in its own species colour — was taken out at 0.8.0
rather than finished, and this page went on describing it for rather longer
than that. The history has it if it is ever wanted back.

On Gold, Silver and Crystal the same two themes arrive by a different route;
see below.

## Gold, Silver and Crystal

The two bundles run on Gen 2 as of 0.32.23. Install either from the index on a
Gold, Silver or Crystal boot and it loads in full.

The **cart** does not move. Wild Green Nightly is a Red cart (`"base": "red"`)
and stays one, because Wild Green itself is Red's player, Red's names and Red's
title screen. What claims Gen 2 is `Gen1WildUI Nightly`, `Gen1WildQOL Nightly`
and the test bench, installed on their own.

**Nearly all of the quality-of-life half runs there unchanged**, because it was
written against hooks rather than modules and Gold raises the same hooks under
the same names. Sprinting is the clearest case: `movement.speed` is raised by
both worlds, so holding B to run needed not one line. Four features are Gen 1
only — `ALL 151`, whose placement table is Kanto research; `TRAINER REMATCH`,
which on Gold is the POKéGEAR; `NPC WALK`, because Gold's NPCs already walk
at the player's pace; and `AREA BANNER`, because Gold ships that sign itself.

"Runs against hooks" is not the same as "runs", and `AUTO SAVE` and
`AUTO CONTINUE` are what that distinction cost: both installed, both raised
their hooks, both read ON in the menu, and neither did anything at all until
0.32.25. What a hook hands a mod is the LIVE GAME, and the live game is a
different object on Gold — so a mod can be perfectly hook-shaped and still
ask it for a field it does not have. Both are fixed above, and both are the
same mistake: Red's name for something Gold also has.

**Most of the visual half stands down there, and that is the honest answer
rather than a shortfall.** This bundle exists to give Red the screens Gold
already shipped. Gold's battle menu is a 2x2 grid and its battle has an XP bar.
Its Bill's PC is a real box with the mon, the level and the gender beside the
list. Its PACK has pockets and prints an item's description under them. Its
lift is a small panel with the car still on screen behind it. Drawing our
versions of those over the cart's would be work spent to arrive back where Gold
started.

What does run there is `BACKDROPS`, `POKEDEX`, `BAG`, `PARTY MENU`,
`MENU LAYOUT`, `MOD MANAGER` and `UI THEME`.

`POKEDEX` is three extra pages on the cart's own entry screen rather than a
replacement dex: Gold's list, search and AREA map are already good, and what it
has no answer for is base stats, evolutions and the learnset. They go where the
cart already has a control that means "next page" — `PAGE` counts on past its
two into STATS, EVOLVES and MOVES. Six stats, because Gen 2 split Special; all
five Gen 2 evolution methods; and an unseen evolution still masked.

`PARTY MENU` is there for two reasons. Gold has the same bug Red does —
`drawIcon` colours every row out of one palette, so six Pokémon share one set
of colours — and each one wears its own there now, out of the cart's own
`monColors`, so a CHARMANDER in the party is the orange it is in a fight.

And, as of 0.32.28, the page has the set's own frame. Everything ON Gold's
party list was already better than Red's: animated icons, a held-item marker
that replaces a quadrant rather than sitting beside it, an HP bar and a level
and a status tag on every row. What it had was no frame at all —
`drawPanel` opens with `Chrome.clear()` and the rows stand on bare paper with
the prompt box at the bottom as the only chrome on the screen. That is
faithful to the cart, and it made the party the one page in this suite you
could open next to the Pokédex and see a different game.

So the frame moved and the columns did not: the six rows step down two tile
rows to make room for a header box, the footer becomes the set's three, and
every second-line coordinate — status at 5, level at 8, the bar at 11 —
stays exactly the ASM's. The one column that moves is the name, and only
because `RULED ICONS` now runs here too: Gold slides the selected icon eight
pixels right, into the very gap between the art and the first letter, so the
row you are looking at is the one row where they touch.

`CANCEL` is in the header, opposite the title. It is a real row on Gold where
Red's party has none, and six two-row mons plus a three-row header plus a
three-row footer is eighteen rows out of eighteen — there is no row left for
it. The alternatives were five visible slots and a scroll, which the Gen 1
screen's own note rejects on a page whose job is showing you the party at
once, or a CANCEL that moves into the header only when the party is full,
which is worse than either. Nothing about how it is reached changed: the index
past the last mon is still the engine's, and B still cancels.

Only `drawPanel` is replaced. Input, the seven flavours of the list, the
submenu, switching, SOFTBOILED and the item result are the cart's and are
never reached from the frame — the same discipline the Gen 1 arm keeps, and
what makes this safe on a screen a player cannot walk out of. A frame that
raises hands the cart's own back, once, and stops trying.

`UI THEME` gets there by a different mechanism, because Gold gives it no
choice. Red colours a page *after* it is drawn, by blitting the frame through
an SGB zone's four colours; Gold is a CGB game whose colour is already in the
picture. So on Gold the theme rewrites `Chrome.DEFAULT_BOX_PALETTE` — the four
colours every box, every string and every fill reads when it is handed none —
in place, once a frame, before the frame draws. Same two themes, same stored
row, same promise that a theme which cannot move a glyph cannot move one off
the screen.

`BACKDROPS` runs there too, and needed no new art — see below.

`BAG` adds SORT, SEARCH and PIN to the cart's own PACK rather than replacing
it: Gold already has the pockets and the item descriptions, so what is left is
how a pocket's list is built. The capacity limit needed nothing at all — that
patch is on the shared `src.inventory.Bag`, which Gold's PACK uses too.
FAVOURITES is the one thing that did not port, because on Red it is a virtual
*pocket* and Gold's tab strip is four fixed ones.


Every one of those verdicts is written next to the feature it belongs to in
each bundle's `features.lua`, with what was checked to reach it.

### The backdrops were never Kanto art

This one is worth its own note, because the name misleads. Every backdrop in
the pack is a FireRed **terrain** scene — grass, forest, cave, sea, pond,
beach, craggy, snow, ice cave, desert, volcano — and Johto is made of the same
terrain. What was Kanto-specific was the *assignment*, and that is a table.

Six of the twenty are named after Kanto bosses only because FireRed assigned
them that way, and three of those six belong to people who are not in this
game at all. So they are re-dealt:

| scene | Kanto | Gold, Silver and Crystal |
|---|---|---|
| 14 Snow | Giovanni | **RED**, at the top of Mt Silver |
| 15 Snow Cave | Lorelei | **KAREN** — and the **ICE PATH**, which is what it is a painting of |
| 16 Snow Mountain | Bruno | Bruno, who is in both |
| 17 Desert | Agatha | **KOGA** |
| 18 Volcano | Lance | Lance, who is the Champion here |
| 19 Space | the Champion | **WILL**, the psychic |

All twenty scenes are reached on a Gen 2 boot.

The one thing that changed rather than moved is the **tower**. `tower.png` is
not a picture of a tower — it is the generic interior with GRAYMON baked in,
and GRAYMON is Red's rule for its CEMETERY tileset. Gold has no CEMETERY, no
GRAYMON and no per-tower palette at all, so Sprout Tower and the Tin Tower take
the plain interior. That is the transcription, not a downgrade: on Gold those
walls really are the same palette a Poké Center's are.

**Town colours are generated, not drawn.** A town variant has always been a
recolour: the art's only two saturated warm colours are the roof browns, and a
variant remaps them onto that town's own roof pair out of the game's data.
Gold keeps the same two colours one level up — `RoofPals`, indexed by map
group — so all twenty-one towns across both regions come out of the same two
passes:

```sh
python3 tools/make_gen2_towns.py <save-dir>/data/generated/palettes.lua
```

All twenty-one are committed, the same as Red's eleven, so nothing has to be
run to play. The script is here because the art is a function of the game's
own numbers and ought to be rebuildable from them — `palettes.lua` comes from
your own cartridge import and is the one thing that cannot be committed.

## Licence

MIT, like everything it is forked from. See [LICENSE](LICENSE).

[cart]: https://github.com/wild1walker/Gen1WildGreen
[index]: https://github.com/wild1walker/Gen1NightlyIndex
[green]: https://github.com/wild1walker/Gen1MakeItGreen
[ui]: https://github.com/wild1walker/Gen1WildUI
[qol]: https://github.com/wild1walker/Gen1WildQOL
