# Changelog


This is the **nightly** fork of [Gen1WildQOL][stable]. Its versions are the
nightly channel's, not the stable bundle's; `1.26.0` below is where the fork
was taken from.

[stable]: https://github.com/wild1walker/Gen1WildQOL

## [0.32.64] - 2026-09-05

### Changed

- Version moved with the nightly channel; nothing in this bundle changed.

## [0.32.63] - 2026-09-05

### Changed

- Version moved with the nightly channel; nothing in this bundle changed.

## [0.32.62] - 2026-09-05

### Changed

- Version moved with the nightly channel; nothing in this bundle changed.

## [0.32.61] - 2026-09-05

### Changed

- Version moved with the nightly channel; nothing in this bundle changed.

## [0.32.60] - 2026-09-05

### Changed

- Version moved with the nightly channel; nothing in this bundle changed.

## [0.32.59] - 2026-09-05

### Fixed

- **Gold's overworld POKéMON on the four GENERIC sheets now wear this suite's
  art.** Reported as "the NPC Pokémon still haven't changed", and the reason
  is a claim in this mod's own comment that was simply wrong:

  > Gold's are not generic — each has its own sheet — and the sprite is NAMED
  > after what it is.

  It isn't. `spriteOrder` [76]–[79] are `SPRITE_MONSTER`, `SPRITE_FAIRY`,
  `SPRITE_BIRD` and `SPRITE_DRAGON` — the same four generic creature sheets
  Red has. They sit *below* the `SPRITE_POKEMON` block, so the extractor gives
  them no species, and their names aren't species either. Every POKéMON
  standing on one kept the cart's art. One sheet really does serve several
  species: `SPRITE_MONSTER` is Joey's RATTATA on Route 30 and Jasmine's
  AMPHAROS in the Olivine lighthouse.

  Which is the exact case Red needed a written table for, so Gold gets one
  too — read off pret/pokecrystal's `maps/*.asm` rather than recalled. Nine
  POKéMON across seven maps:

  | Map | Cell | Sheet | Species |
  |---|---|---|---|
  | Route 30 | 5,24 · 5,25 | MONSTER | RATTATA ×2 |
  | Olivine Lighthouse 6F | 9,8 | MONSTER | AMPHAROS |
  | Ilex Forest | 14,31 | BIRD | FARFETCH'D |
  | Violet Nickname Speech House | 5,2 | BIRD | PIDGEY |
  | Mt Moon Square | 6,6 · 7,6 | FAIRY | CLEFAIRY ×2 |
  | Mahogany Mart 1F | 3,6 | DRAGON | DRAGONITE |
  | Team Rocket Base B2F | 9,13 | DRAGON | DRAGONITE |

  Thirteen objects use these sheets; the other four are **dolls** — three in
  the Copycat's house, one in the Fan Club — and they are deliberately absent,
  for the same reason the big Snorlax, Lapras and Onix dolls are. A real
  CLEFAIRY where a Clefairy doll should be is worse art and a worse joke.

  Matching is on map *and* cell *and* sheet, so a doll's cell is not a row and
  one `SPRITE_MONSTER` cannot be mistaken for another. Each species gets one
  cloned record rather than a rewrite of the shared sheet, so Amphy cannot end
  up wearing the Rattata's art.

- **FARFETCH'D and MR. MIME resolve on Gold without waiting for the game
  data.** The two cartridges spell them differently — Gold writes the
  apostrophe and full stop as underscores (`FARFETCH_D`, `MR__MIME`, the
  second with two) — so a lookup before the game's data was up answered nil
  and the POKéMON silently kept the cart's art. Both spellings are named now.
  The suite caught this one: the table said `FARFETCHD` and the cart's own
  species list disagreed.

## [0.32.58] - 2026-09-05

### Changed

- Version moved with the nightly channel; nothing in this bundle changed.

## [0.32.57] - 2026-09-05

### Changed

- Version moved with the nightly channel; nothing in this bundle changed.

## [0.32.56] - 2026-09-05

### Fixed

- **Wild Crystal keeps its own save.** Launching the cart loaded — and then
  overwrote — the regular Crystal playthrough. The engine scopes a cart's
  saves by cart id and the launcher lists them from that scope, but Gold,
  Silver and Crystal save through `src/core/gen2/Save.lua`, which builds its
  filename out of the *version* alone and never asks whether a cart is
  active. Gen 1 saves through `SaveData`, which is already cart-scoped, which
  is why only the Crystal cart showed it.

  Worse than sharing: the first save inside the cart registered a slot in the
  base game's registry and made it active, so the cart's playthrough turned
  up in the launcher's Crystal list and the player's own Crystal save was
  what the cart then wrote over.

  The bundle now states the rule the engine already keeps everywhere else —
  *while a Gen 2 cart is active, the base version's slot resolution and save
  paths are the cart's* — at the three public slot calls and the one
  filesystem seam the Gen 2 save layer reaches them by. Saves land in
  `saves/cart_<id>/<slot>.lua`, exactly where the launcher looks; no phantom
  slot is added to the base game; and the whole thing stands down on its own
  the moment the game hands back to the launcher.

  A save already written into the base game's file stays there — it is a
  Crystal save now, and the launcher's Crystal list is where to find it.

## [0.32.55] - 2026-09-05

**The day-care pair wear this mod's sheets.** They were the one overworld
POKéMON the arm could never have reached, however right its timing (0.32.48)
and its table (0.32.50) got.

`World:breedmonSpriteDef` builds their sprite record **on the fly** and caches
it on the world rather than in `data.gen2Sprites` -- their species is whatever
is being bred, so there is no fixed `SPRITE_*` row for them to have. Every pass
over the sprite table missed them by construction. The record it hands back is
the same shape every other mon record has (`spriteType = "POKEMON_SPRITE"` and
a `species`), so it is repointed on the way out instead.

The saved original is kept **by species, not by id**: every breedmon shares the
id `SPRITE_DAY_CARE_MON`, so keying on that would have restored one POKéMON's
cart icon onto another's record the moment the pair changed.

The per-record rewrite is now one function, used by both the table pass and
this, so a record cannot be repointed two different ways.

## [0.32.54] - 2026-09-05

No change. Version-only, released alongside the UI bundle.

## [0.32.53] - 2026-09-05

No change. This release is four fixes to Gold's POKéDEX list, in the UI bundle;
the two halves ship together and share a version.

## [0.32.52] - 2026-09-05

No change. This release is two fixes to Gold's POKéDEX list, in the UI bundle;
the two halves ship together and share a version.

## [0.32.51] - 2026-09-05

**The other half of Gold's overworld POKéMON.** 0.32.50 got the sheets into the
right table; this covers the POKéMON that were never in it.

Gold's sprite ids come in two blocks. The `SPRITE_POKEMON_*` block from `$80`
up is the mon dolls -- SpriteMons rows that already name a species, and the arm
so far rewrote those. The **OverworldSprites half below `$60` carries POKéMON
too** -- SUDOWOODO on Route 36 among them -- as ordinary walking sheets with no
`species` field at all. They kept the cart's art because nothing looked at them.

Red needed a hand-written table of fifty-three names for this, and it had to:
its objects share five *generic* sheets, so a single "monster" is Mewtwo and a
Machop at once and the species is genuinely lost. Gold's are not generic -- each
has its own sheet -- and **the sprite is named after what it is**. So the name is
the answer. Asking `data.pokemon` whether the rest of the id is a species covers
every name in the cart's block without this mod enumerating one, and it cannot
fire on a person or a prop, because YOUNGSTER and POKE_BALL are not species.

**Three are deliberately excluded**, and they are the reason this is not a bare
name match:

- `SPRITE_BIG_SNORLAX`, `SPRITE_BIG_LAPRAS`, `SPRITE_BIG_ONIX` -- the bedroom
  and Pokémon Center **dolls**. They are drawn through `SetFacingBigDoll` as
  two-by-two dolls with a mirrored half, so they are neither 16×16 nor
  creatures, and the joke -- as with the three in Red's Copycat's house -- is
  that they *are* dolls. A sixteen-pixel Snorlax standing where a doll should be
  is worse art and a worse joke.

A species this mod has no sheet for is left alone rather than drawn as the
fallback: the cart's own art beats the wrong POKéMON. And the `walker` flag now
follows the sheet -- a doll keeps `false` and shows its first frame, one off the
walking half gets `true`, which is the pairing these six-frame sheets are built
for.

## [0.32.50] - 2026-09-05

**The map POKéMON sheets were going into the wrong table.** 0.32.48 fixed *when*
the records are rewritten and they still wore the cart's icons, because the
rewrite was landing on a table nothing draws from.

A Gen 2 boot has **two** sprite tables holding the same data:

- `data.sprites` -- what `src/core/Data.lua` loads, under the Gen 1 key.
- `data.gen2Sprites` -- what `Game2` loads separately at `:1044`, and the
  comment beside it says why: *"namespaced so nothing collides with the Gen 1
  keys of the same idea"*.

They are **different tables**. `World:dataTable("gen2Sprites", ...)` and
`PartyMenu.new` both read the second, so the second is what every overworld NPC
and every party icon is actually built from. This mod's chooser preferred
`sprites`, so on Gold it had been writing our sheets into a copy since the arm
was written -- and no amount of fixing the timing could have helped.

**The follower is what hid it.** It never depended on the record reaching the
world: `syncLiveFollowerDef` rebuilds its `SpriteRenderer` straight from the
image path. So the one thing that bypassed the record looked right while
everything that goes through it looked wrong.

The chooser now prefers `gen2Sprites` on a Gen 2 boot and `sprites` on Gen 1,
each falling back to the other so neither arm goes blind if its own key is
missing.

The test that shipped with 0.32.48 could not have caught this -- it stubs the
refresh, so it never reached the real chooser, and its fake `game.data` carried
only `gen2Sprites`, which is not the shape a real boot has. The shipped chooser
is now lifted out and asked directly with **both** tables present, which is the
case that was wrong.

*If a specific POKéMON still shows the cart's art after this, it is a different
case: Gold draws a few of them as ordinary walking sprites (`SPRITE_SUDOWOODO`
and the like) rather than as the `SPRITE_POKEMON_*` records this arm rewrites,
and those need a name-to-species table the way Red's fifty-three did. Name one
and it can be added.*

## [0.32.49] - 2026-09-05

No change. This release is Gold's POKéDEX list, in the UI bundle; the two halves
ship together and share a version.

## [0.32.48] - 2026-09-05

**The POKéMON standing on Gold's maps wear this mod's sheets.** The arm for it
was already there and already the right shape -- Gold's overworld POKéMON are
`SPRITE_POKEMON_*` records that name a species, so the record itself can carry
our art. What was wrong was *when* it ran.

The rewrite went off the follower's `onMapEntered` wrapper, whose own comment
says it happens "before the map's own objects are built". That is true on Red.
On Gold, `Follower.onMapEntered` is called from the **tail** of `World:setMap`
-- after `rebuildPeople`, which is the thing that builds the map's people -- and
`NPC.new(mapId, obj, spriteDef)` calls `SpriteRenderer.new` on the spot. The
sheet is baked at construction. So every map POKéMON was already wearing the
cart's party-menu icon by the time the record changed underneath it.

That is also exactly why the **follower** looked right and they did not:
`onMapEntered` is what builds the follower, so it is the one entity in the game
made *after* the rewrite.

Two changes, and the second is not optional:

- **The refresh moved to the front of `rebuildPeople`**, so an NPC built there
  is built from our sheet.
- **A resync runs behind it**, for the ones a rebuild does not rebuild.
  `World:pooledNpc` keys NPCs by map and object index and hands back the *same
  instance* on a revisit, and `NPC:setSpriteDef` early-returns when handed a def
  it already holds -- which ours always is, because the rewrite is in place. So
  a pooled POKéMON would have kept a renderer built from the cart's icon however
  many times you walked back onto its map.

Flipping **MAP POKÉMON** off now reaches the POKéMON already standing on the
map, rather than waiting for the next one: Gold rebuilds nothing on an option
change, and its NPCs bake the sheet at construction, so the live ones are
re-pointed directly.

Gen 1 is untouched -- its own path swaps the renderer per NPC and always ran at
the right moment.

## [0.32.47] - 2026-09-05

**The follower crosses a route boundary as one continuous walk on Gold.**
Walking off the edge of a route made it vanish and reappear standing *on* the
player, then trail back out -- a jump at every seam, on a crossing that is
otherwise seamless.

Crossing an edge is not a map *entry*. Nothing loads and nothing warps: the
world swaps its map data underneath a step that is still running, which is why
`World:tryConnection` passes `{ seamless = true }` and parks the player one cell
short of the landing so the same world pixels stay on screen. Red does the
follower's half of that too, in three lines:

1. take the **live** follower before the swap,
2. hand it through `setMap` as `keepPikachu`, so the map-entry hook adopts it
   instead of destroying it and spawning a new one, and
3. `rebase` it -- and the cell it is chasing -- by the same translation the
   player just took, sliding both into the new map's frame.

Gold's `tryConnection` does none of the three. It calls `setMap` with a bare
`{ seamless = true }`, and `setMap` calls `Follower.onMapEntered(..., true)` --
`viaMapLoad` **true for every load, connection included** -- whose whole meaning
is "a fresh load parks it under the player and it walks out as the trail opens".
That is right for a door and wrong for an edge.

Both engine parts already existed and neither had a caller: `Follower.rebase` is
written for exactly this and says so ("slide into a connected map's frame by the
seam's delta"), and `onMapEntered` already honours `opts.keepFollower`. So this
supplies Red's three lines rather than inventing a mechanism -- the same
instance crosses the seam, translated, and keeps walking.

It is scoped tightly. The adoption is armed only for the length of one
`tryConnection` call, and it will not adopt a follower unless that call armed it
**and** the load is seamless **and** nobody has already named one -- so every
other map load in the game still takes the engine's own path, doors and warps
included. A rebase happens only on a crossing that actually succeeded; an edge
with no neighbour, or one the step could not land on, translates nothing.

Because it is a translation rather than a re-placement, whatever offset the
follower had is what comes out the other side -- so one caught mid-step, or
standing off to one side, crosses looking exactly as it did.

Gen 1 already did this correctly and is untouched.

## [0.32.46] - 2026-09-05

No change. This release is the POKéGEAR's dark mode, in the UI bundle; the two
halves ship together and share a version.

## [0.32.45] - 2026-09-05

No change. This release is Gold's PACK search and box sort, in the UI bundle;
the two halves ship together and share a version.

## [0.32.44] - 2026-09-05

**TRAINER REMATCH now runs on Gold, Silver and Crystal.** It was gated to Gen 1
on two claims, and neither survived being checked.

The first was that Gold already has this through the POKéGEAR -- a trainer takes
your number and calls when they want to go again. The *cartridge* does. This
engine does not, yet: the rematch flag is set by the `.WantsBattle` branch of
`engine/phone/scripts/trainers.asm`, that bank is unextracted, `WantsBattle`
appears in the port only inside a comment, and nothing outside `Phone.lua` ever
calls `Phone.setRematchReady`. So there was no second rematch system to compete
with -- there was no rematch on Gold at all.

The second was that neither seam exists there. `world.talk` really is Gen 1's,
but `World:interactBody` is a method and this suite patches engine methods
everywhere; and `BattleState.newTrainer` has no Gen 2 counterpart because Gold
has something better -- `World:startScriptedBattle` is the battle, the
transition, the music and the prize with **none** of the trainer's own script.
That is exactly the line a rematch has to draw, and on Red it had to be drawn by
hand. So no badge is handed out twice, no after-battle text replays, and no
`disappear` fires again.

The feature is the same one Red has, and the same three rows drive it:

- **The offer sits on the end of the conversation.** Talk to a trainer you have
  beaten, read their line to the end, press on -- "Want to battle again?". B out
  of the line is nothing at all, exactly as on Red: the press that closed the
  last page is still that frame's when the script goes idle.
- **The gate is Gold's, and it is a better one.** Red asks the stack whether the
  engine has finished speaking. Gold's talk is a script, so this asks the VM --
  plus nothing over the world: no box, no menu, no battle, no fade. A gym leader
  still handing over a TM, a script walking somebody off, a queued phone call:
  all of them keep the VM busy, and none of them gets a question hung off it.
- **MATCH LEVELS and REMATCH PRIZE work as they do on Red.** Levels ride the
  `trainer.party` hook, which Gold raises, armed only for this feature's own
  battle. The price is the class's base reward times the last party row's level,
  halved -- read off the roster rows, which is the same arithmetic the battle
  will do when it pays out.

`modules/Gen1Rematch/gen2.lua` is a second file rather than a fifth branch in
`main.lua`: the feature is shared, every seam is different, and writing both
games into one function would have left neither readable. 43 assertions cover
the Gold arm, including every shape that must *not* produce an offer.

While writing them a latch came out that would have switched the feature off for
the rest of a session if an offer ever failed part-way. It was redundant -- the
armed talk is cleared before the question is asked and set only by a fresh talk,
so nothing could re-enter anyway.

## [0.32.43] - 2026-09-05

No change. This release is BATTLE INTRO's two settings reaching Gold, in the UI
bundle; the two halves ship together and share a version.

## [0.32.42] - 2026-09-05

- **START > MODS reaches the suite on Gold.** `runtime/menu.lua` ships in both
  halves and had the same bug in both: the retarget installed a callback beside
  the `value` Gold's rows carry, and `StartMenu:choose` only runs a callback
  when there is no value, so MODS still opened the cart's own list. Fixed and
  tested in both copies. See the UI bundle's changelog for the long version.

## [0.32.41] - 2026-09-05

No change. This release is Gold's follower icons, in the UI bundle; the two
bundles ship together and share a version.

## [0.32.40] - 2026-09-05

- No change. The release is Gen1WildUI's: three fixes to the Gold box
  -- a reachable header, `START` opening the actions, and a party
  cursor that points at the party.

## [0.32.39] - 2026-09-05

- **`ON QUIT` never fired on Gold: it doesn't ask you to save before quitting.**

  The two games shape a START menu row differently, and this hook only knew
  one of them.

  Red's rows are **callbacks**. `src/ui/StartMenu.lua` builds QUIT as
  `{ label, onSelect = function() ... end }`, so wrapping `onSelect` is the
  whole of the interception.

  Gold's rows are **values**. `StartMenu:visibleItems` builds
  `{ label, value = "quit", desc, translateLabel }` and `StartMenu:choose`
  dispatches on the value — there is no `onSelect` to wrap. The hook tested
  `type(item.onSelect) == "function"` and skipped the row, so on Gold the
  offer never came up and the last thing you did before quitting was never
  written.

  Taking the row over on Gold means taking the **value off it**: the cart's
  own arm for a mod row is `item.onSelect and item.value == nil`, so the two
  are exclusive there. Which hands the cart's own confirm back to this mod,
  and the fallback reproduces the arm the value would have reached —
  `phase = "confirm"` with `NO` preselected — so a frame where there is
  nothing to offer is the cart's QUIT exactly, box and default and all.

  Everything after the press was already generation-agnostic and is unchanged:
  a clean save or a sync conflict still declines to offer, `YES` still holds
  the quit behind *"Now saving…"* until the write and its upload are done, and
  `QUIT_WAIT` still bounds the wait so a save that cannot finish is not
  something to strand you in front of.

  Matched on `value` rather than on the label, because the label at hook time
  is the source string the engine translates afterwards — matching it alone
  would work in this language and no other.

## [0.32.38] - 2026-09-05

- No change. The release is Gen1WildUI's: `POKEMON BOX` runs on Gold,
  replacing the storage list with the grid and the carry cursor.

## [0.32.37] - 2026-09-05

- No change. The release is Gen1WildUI's: the trainer card's tiles go
  dark with its text under `DARK`, leaving the portrait and the leader
  faces as the art they are.

## [0.32.36] - 2026-09-05

- `MENU LAYOUT` gains `ROW HINTS` on Gold — the START menu's per-row
  description box, off by default. Gen1WildUI owns the feature, so that is
  where it is written up; this bundle carries the same module.

## [0.32.35] - 2026-09-05

- No change. The release is Gen1WildUI's: under `DARK`, the six Gold
  screens that print through a palette of their own no longer leave a
  white box behind every string.

## [0.32.34] - 2026-09-05

- **`MENU LAYOUT`'s module is the same code in both bundles again.**
  Gen1WildUI owns the feature -- `shared.owner` -- so its copy is the
  one that installs, and three releases of START-menu fixes had gone
  into this one, which never runs. Nothing here behaves differently;
  the fixes now reach the game.

- `check.py` fails when a shared feature's module differs between the
  two bundles, from either side, naming the file and which bundle
  installs it.

## [0.32.33] - 2026-09-05

- **`MENU LAYOUT` no longer leaves Gold with a START menu you cannot get out
  of.**

  0.32.27 fixed one half of this — re-opening through `Game2:openStartMenu`,
  which is the only call that supplies `onChoose` and `onClose`. The other
  half was still there, and it is a difference between the two games that this
  mod had inherited an assumption about:

  > **Red's `Menu` pops itself before it runs a row's `onSelect`. Gold's
  > `StartMenu:choose` does not** — it runs `onSelect` and returns.

  So on Gold the editor opened *on top of* a live START menu, and the re-open
  put a second one behind it. Two identical menus stacked: B pops one and the
  other is still there, which is exactly what "you can't close it" looks like.
  The stale one is dropped first now — popped rather than reused, because the
  menu under the editor was built from the layout the player had just
  **changed**, so reusing it would show the old order.

  Two more things went in with it, because a START menu that cannot be left is
  the worst thing this mod can do to a save and one fix for it is not enough:

  - the **fallback push** carries the two callbacks now, synthesized the way
    the engine's own Gen 1 facade synthesizes them, so the path taken when
    `openStartMenu` is missing or raises cannot build an inert menu either;
  - and **every** Gold START menu is checked on the way past. This mod's hook
    runs on construction, so one reaches it whoever pushed it; if it arrives
    with neither callback, the two nils are filled in and the repair is
    logged. There is no route left that produces a menu with no way out.

## [0.32.32] - 2026-09-05

- No change. The release is Gen1WildUI's: the battle HUD on Gold keeps
  the cart's own ink under `DARK`, an attack no longer drags the
  backdrop with it, and the move menu joins the command menu in the
  four boxes with the type's colour in the letters.

## [0.32.31] - 2026-09-05

- No change. The release is Gen1WildUI's: the battle HUD on Gold
  loses the box that was behind it, the pics get paper in their own
  shape rather than a rectangle, and `BATTLE MENUS` draws the four
  command buttons there.

## [0.32.30] - 2026-09-04

- No changes; the channel ships as one version.

## [0.32.29] - 2026-09-04

- No changes; the channel ships as one version.

## [0.32.28] - 2026-09-04

- No changes; the channel ships as one version.

## [0.32.27] - 2026-09-04

- **The autosave POKe BALL was a third of its size on Gold.**

  `viewport.scale` does not mean the same thing on the two games, and this is
  the one place in the mod where that shows up as a size rather than a
  position.

  On Red it is **Sp**: framebuffer pixels per GB pixel, while
  `gameX`/`gameY`/`gameWidth`/`gameHeight` beside it are LOVE units --
  `r.Sp, r.Sx, r.Sy = Sp, Sp / dpiX, Sp / dpiY` (src/render/Renderer.lua:818).
  Drawing at Sp inside a unit-space transform multiplies by the DPI factor, so
  the unit scale there is `scale/dpi`, and that is what this did.

  On Gold it is **already** the unit scale. `Game2:viewport` builds the whole
  payload out of `Chrome.fitScale(w, h)`, which is computed from the window's
  LOVE units, and publishes `gameWidth = 160 * scale` beside it. There is no
  Sp anywhere in it. Dividing by the DPI there divides a second time, and the
  indicator came out at 1/dpi of its size -- right on a plain 1x desktop, a
  third of a POKe BALL on a phone, which is exactly how it was reported.

  Both arms are written out rather than derived from the payload, because the
  two CAN agree by accident -- at DPI 1, or on a widescreen frame where Red's
  own UI width is `160 * dpi` -- and a rule that reads the right answer off a
  coincidence is wrong the first time the coincidence breaks. The SAVED text
  and TEXT BOX indicators took the same scale and are the same size again with
  it.

- **After MENU LAYOUT, Gold's START menu opened nothing and would not close.**

  The editor is reached from the START menu and puts it back on the way out,
  and that one call is the whole bug.

  Red's `StartMenu.new(game)` takes the game and nothing else: it builds every
  row's `onSelect` itself, and the engine's own way in is a bare
  `Screens.push(Game, "StartMenu")`. So pushing the learned screen id was not
  a shortcut there -- it was the engine's own call spelled out.

  Gold's is `StartMenu.new(game, opts)`, and `onChoose` and `onClose` are
  **push options**: `Game2:openStartMenu` supplies both. The same bare push
  builds a menu with neither, and the menu that came back was inert in exactly
  the two ways it was reported -- `choose` ends in `if self.onChoose then` so
  nothing opened, `close` ends in `if self.onClose then` so B and START did not
  shut it. The rows drew, the cursor moved, and the only way out was a soft
  reset.

  So the mod asks the GAME to open its own menu where there is a method for
  it, and falls back to the learned id where there is not. The fallback is
  Red's path and is unchanged; the method is Gold's, and it also does the two
  things a re-open there owes the world -- cancelling the map-name sign and
  stopping the player -- which the bare push skipped as well.

- **The MENU LAYOUT editor stayed white in a dark game.**

  The theme knows a page two ways: a marker on the instance, or one of the
  engine's own UI classes. A screen a mod registers is neither, so the visual
  half's facade marks every opaque screen the suite registers on the way past.

  That marking lived only in the half that carries the theme -- and MENU
  LAYOUT and MOD MANAGER are `shared`. Both bundles carry them, the **first to
  load claims them**, and the quality-of-life half is first in the cart's load
  order. So on every cart the editor is registered through THIS facade and
  never reaches the other one's. It stayed white for that reason and no other:
  the marking lived where the theme does, and the screen is registered where
  the theme is not.

  This half marks screens now too. The mark is a field nothing here reads, so
  a player running this half alone is unaffected, and one running both gets a
  themed editor whichever bundle happened to win the claim.

## [0.32.26] - 2026-09-04

- No changes; the channel ships as one version.

## [0.32.25] - 2026-09-04

- **AUTO SAVE had never written a file on Gold, Silver or Crystal.**

  Not "sometimes", not "in the wrong place" -- never, on any Gen 2 boot since
  the bundle started claiming one. No error, no warning, nothing on the boot
  feed, and the row reading ON with its INTERVAL and AFTER EVENTS rows under
  it. The mod installed, ran its timer, marked the save dirty after every
  battle and every door, and then refused every frame it was ever offered.

  **Every question it asks about the map was asked as `game.overworld`.**
  That is Red's `OverworldState` singleton. Gold does not have one: its world
  lives at `game.world`, and it is not a stack state at all -- an EMPTY stack
  is free roam there, which `src/core/Game2.lua:pipelineGate` says outright.
  So `writeWindow` opened with `if not (ow and ow.player) then return false
  end` and answered false on every frame of every playthrough;
  `writeUnderCover` returned before it looked at anything; and `screenOver`,
  which asks whether a screen is standing over the world, answered `top ~= ow`
  against a world that is never on the stack -- backwards on the map and
  backwards inside every menu.

  **The six questions are spelled once now**, in one block at the top of the
  mod, and nothing below it knows which game it is on: where the world is,
  whether the player is mid-step, whether a direction is held, whether a
  script has the controls, whether a fade is running, and whether a screen is
  standing over the map. Each has an answer in both games and every one of
  them is spelled differently.

  **The veil questions grew a second arm for the same reason.** `fullyVeiled`
  and `veilStepping` looked for a stack state with an `alpha()`, and Gold's
  fades are not states: a door, a warp and the ride back out of a battle are
  all `World:runMapSetup`, whose ramp is `world.fade` with `world.fadeLevel`
  from 0 to 1 under it. So the covered write -- the whole design, a save taken
  on a screen nobody can see -- had no screen to take. It has thirteen frames
  of held white to take it on now, fifteen through a warp, which is the same
  hold the cart loads the map under.

  A mod's own fade is still a state on either game and is still asked first,
  so Gen1WildUI's BLACK OUTRO keeps the hold it was given in 0.32.20.

  Nothing about Red changed. `tests/autosave_gen2_test.lua` drives both
  generations through the same questions, including the two whose answer is
  *reversed* between them -- an empty stack is "no menu is open" on Red and
  "the player is standing on the map" on Gold.

- **AUTO CONTINUE did nothing at all on Gold, Silver and Crystal.**

  Reported as the intro cutscene, the copyright card and the whole continue
  flow still playing with the row on, and that is exactly what was happening.
  The mod knew one boot: `isGen1Title` asks for `openMenu` and `toMenu`, which
  Gold's title has neither of, and `isIntro` matched `IntroMovie` and
  `YellowIntro`, which are not Gold's cards. Both refusals were *correct* --
  they are what kept the mod from erroring on Gold -- and both together are a
  feature that reads ON and is not there.

  **Gold's boot is a different set of screens end to end**, so this is a
  second arm rather than a branch:

  - `SKIP INTRO` now ends all four cards of the cinema -- the copyright card,
    the GAME FREAK splash (the Ditto one on Crystal) and the attract movie --
    **in one update**, not one card per update. Each card's `onDone` pushes
    the next, so ending them one at a time would have drawn each one for a
    frame on the way past; drained in one update, the title is the first thing
    the boot ever draws. The copyright card is the awkward one: it has neither
    a `finish` nor a `skip`, and ends by running its own `onDone` behind its
    own latch. The two splashes hand their `skipped` flag to
    `Game2:showGameFreak`, which reads it as "go straight to the title" -- so
    ending the splash as skipped takes the attract movie with it, which is the
    cart's own answer to a button press there.
  - `START` / `A` loads the save. The menu Gold builds is answered from inside
    the title's own `onContinue`, which is the one place where the menu exists
    and the frame has not been drawn yet -- so the CONTINUE menu is never seen,
    and neither is the save panel and the second A press it waits for. What
    runs is the menu's OWN payload with the save the menu read for itself;
    nothing here goes looking for a file.
  - `B` runs the menu's own EXIT GAME row, and `SELECT` leaves the ordinary
    menu up. Both are dead inputs on Gold's title, the same as on Red's.

  With no save, or a build whose menu carries no CONTINUE, the ordinary menu
  is what the player gets -- which is what a first boot wants.

- **AREA BANNER is Gen 1 only, and its Gen 2 arm is gone.**

  Gold ships this sign. `src/world/gen2/MapNameSign.lua` is the cart's own,
  drawn on every map entry that earns one, and it already knows the six
  landmarks that get none and the park gates that get one late. Every line of
  this feature's design note names Gold as the thing being copied -- a plaque
  sized to the name rather than a dialogue box, anchored top-left, slid on and
  off -- so on Gold the copy was a SECOND sign: same corner, same frames, same
  name as the one underneath it.

  The arm is removed rather than switched off. It was the only caller of a
  monkey-patch on `World.draw`, and a patch on the engine's own draw that
  exists to be skipped is a patch that will one day not be.

## [0.32.24] - 2026-09-03

- **TRAINER REMATCH stopped answering for the engine, and gym leaders became
  rematchable in the same change.**

  The wrap on `world.talk` used to ANSWER the A press itself for any beaten
  trainer with an `after` line -- print the line, then offer the fight. But
  that line is the last thing `talkTo` reaches. A hand-ported map script wins
  first (`OverworldController.lua:3152`, "hand-ported scripts always win"),
  then an item ball, then a static encounter, and only then the trainer
  branches. The wrap ran before all of it. The offer was not sitting on the
  end of a conversation; it was replacing one.

  **The ROCKET on `ROCKET_HIDEOUT_B4F` is what that cost.** His hand-ported
  talk is the only thing in the game that puts the LIFT KEY on the floor: the
  ball starts hidden in the map objects and the first talk after the win is
  what reveals it (`CheckAndSetEvent EVENT_ROCKET_DROPPED_LIFT_KEY` /
  `ShowObject ROCKETHIDEOUTB4F_LIFT_KEY`). With the row on, that talk never
  ran. You got a rematch prompt instead, the ball stayed hidden, and the lift
  stayed locked -- no SILPH SCOPE, no POKeMON TOWER, no GIOVANNI. A run that
  reads as a feature the whole way down and ends unfinishable.

  **The fix is that the engine says the line now, and the question goes on
  the end of it.** `next()` runs first and in full, so whichever line the
  engine would have printed is the line you get and every side effect it
  carries still happens. All this mod adds is `Want to battle again?` on the
  box the engine pushed -- and only when that box was the end of it.

  **Which is asked of the stack, not of a list of names:** the talk pushed
  exactly one plain box, and when it closes the engine's own `onDone` leaves
  the stack where the talk found it. Then the engine had one line to say and
  has said it. Anything else is the engine still working, and there is no
  offer on that talk.

  That one rule is the whole of the behaviour you asked for. A gym leader who
  still owes you a TM -- your bag was full at the victory, so talking to them
  re-runs the hand-over -- answers with a *chain* of boxes, each pushing the
  next from its own `onDone`, so the stack is deeper when we look and nothing
  is offered. Take the TM and the same leader answers with one advice line,
  which ends where it started: rematch. The ROCKET drops the LIFT KEY on the
  floor and *then* asks you if you want to go again. Same rule, no names, and
  the trainer nobody has thought of yet is behind it too.

  **Gym leaders are rematchable at all for the first time.** They carry no
  `def_trainers` header, so the old path -- which needed one for its `after`
  line -- could never offer a leader a rematch, whatever the module's own
  comment said. Letting the engine speak means there is no header to look up:
  a leader you have taken everything from is an ordinary beaten trainer with
  an ordinary line. The badge still stays exactly once yours; nothing about
  the victory path runs on a rematch.

  `tests/rematch_test.lua` is 115 assertions, on a fake that now models the
  state stack and the engine's own talk: the chain that owes you a TM, the
  advice line that does not, the LIFT KEY revealed before anything is asked,
  a menu, a box already asking a question, a box that closes on a timer, and
  a script that pushes nothing at all.

## [0.32.23] - 2026-09-02

- **ALL 251: the Johto placement table, and the spawn layer that reads it.**

  What is missing turned out to be derivable rather than recalled.
  tools/gapset2.py parses both pret disassemblies and closes the renewable set
  up over evolution and DOWN over the Day-Care, since the engine implements
  breeding. GOLD and SILVER each cannot renewably produce 72 of the 251,
  CRYSTAL 68, sixty missing from all three. Six babies that look missing are
  not, and placing them would have invented work.

  The sixteen version exclusives are GENERATED by tools/build_placements2.py,
  which places a species on the map its SIBLING CARTRIDGE keeps it on -- the
  strongest authority available. The sixteen decisions cite something in every
  row, and where no game has ever put a species in a wild table the row says
  so and argues from habitat and gate instead.

  Substitution, never appending, and not by preference: Gold picks a grass
  slot off a fixed seven-entry ladder, so an eighth slot can never be drawn.
  That makes this layer simpler than Gen 1's -- nothing to append, no vanilla
  slot count to record, nothing to trim before stage one. A map with nothing
  placed on it draws ZERO extra random numbers.

  The statics stay until they are caught, and the event flag is never
  touched. Gen151 clears EVENT_BEAT_<SPECIES>; here that would be a bug. Gen
  2's EVENT_FOUGHT_* flags gate unrelated progression -- SUDOWOODO's the
  GOLDENROD flower shop, SNORLAX's a VICTORY ROAD GATE object, SUICUNE's the
  TIN TOWER entrance and therefore HO-OH's whole chain -- so clearing one to
  return a SUICUNE could take a HO-OH away. Each object carries its own
  visibility flag instead, and that is what goes back. RAIKOU and ENTEI are
  refilled in the save from the roster, at full health. SUDOWOODO is
  restored too, sprite slot and all -- the reason it was once excluded was a
  misreading of `variablesprite`, which swaps the SHEET and nothing else, so
  the object keeps SudowoodoScript and that script reads the SQUIRTBOTTLE
  rather than the fought flag. CRYSTAL's SUICUNE genuinely cannot be
  un-hidden -- its object does nothing when talked to, and the scene that
  battles it sits behind EVENT_GOT_RAINBOW_WING -- so it is put back where
  GOLD and SILVER keep it: the roamers' third slot, which the cart's own
  CheckEncounterRoamMon already rolls. LAPRAS was never a gap at all, being
  on a daily flag that puts it back every Friday.

  The ten trade evolutions get a RULE rather than an item. Gen151 sells a
  consumable cable because a level-up rule would evolve every KADABRA you own
  whether you wanted it or not; Gen 2 ships the EVERSTONE, which is that
  objection answered by the cartridge. Gold's trade check is already complete
  -- Everstone, held item, Time Capsule -- and the only clause one save cannot
  satisfy is the link, so that is the only thing supplied. The held item is
  not consumed, because the hook returns one boolean and a predicate that eats
  a METAL COAT when something merely asks is a worse bug than a coat that
  survives.

  `--check` proves three things against the cartridges: that the generated
  half has not drifted, that every map named actually carries a table of the
  method its row claims, and that every gap on all three is answered by a
  placement, the cable or a static.

- **GS BALL: Crystal's own CELEBI event, switched back on.**

  Crystal ships the entire event and cannot reach it. The receptionist in the
  Goldenrod POKeCENTER who hands over the ball, KURT taking it away and giving
  it back outside his house, the shrine in ILEX FOREST, the forest going quiet,
  the level 30 CELEBI -- every piece is in the cartridge, and the engine
  implements both specials the shrine calls. What gates it is `sGSBallFlag`,
  written by nothing but the Mobile Adapter GB. No adapter, no flag, and eleven
  scripts sit there as dead data on every cartridge sold outside Japan.

  So this writes the flag and stops. Not an item, not a script, not an NPC, not
  a map, not a line of text: everything the player then sees is the cartridge's
  own event in its own words, in the order its authors wrote it. The event was
  never missing, only unreachable, and a key is a more honest fix than a
  reimplementation of eleven scripts that already work.

  Idempotent, which is the part with teeth. The byte also reads `given` and
  `used`; overwriting either would send the receptionist after a player who has
  already finished the event, so a flag that is already set is left exactly as
  it is. tests/celebi_test.lua drives all three states.

  GOLD and SILVER get nothing, because there is nothing there to get: the GS
  BALL, the shrine script and the event are absent from those two cartridges
  entirely -- not gated, not unused, absent. It is the bundle's first feature
  that installs on Gen 2 and on nothing else.


- **The quality-of-life half runs on Gold, Silver and Crystal**, and nearly all
  of it runs unchanged. `manifest.json` claims `gen1` and `gen2`; sixteen of
  the nineteen features install there.

  Most of them needed nothing at all, because they were already written against
  hooks rather than modules and Gold raises the same hooks under the same
  names. SPRINT is the clearest case: `movement.speed` is raised from
  `src/world/gen2/World.lua` as well as `src/world/Player.lua`, so holding B to
  run works on Gold with not one line changed. AUTOSAVE, AUTO CONTINUE, SOUND,
  EXP SHARE and the MOVE REMINDER are the same story.

- **Three are Gen 1 only, each for its own reason.**

  **ALL 151** is a Gen 1 fact, not a Gen 1 implementation. It is a researched
  placement table -- species, Kanto map, method, level, rarity and a
  justification per row -- written against the version-exclusive and
  trade-evolution gaps Red and Blue actually have. Gold's dex is 251, its maps
  are Johto, and its gaps close by breeding, time of day and the phone. The
  honest Gen 2 answer is a Johto placement table, which is somebody's research
  rather than a port.

  **TRAINER REMATCH** is a feature Gold shipped. A rematch there is the
  POKéGEAR: the trainer takes your number and calls when they are ready. Both
  of this mod's seams are Red's anyway -- `world.talk` is raised from
  `OverworldController` and nowhere else, and `BattleState.newTrainer` has no
  Gen 2 backing.

  **NPC WALK** is one number, and Gold already has the right one. Red's NPC
  crosses a cell in 32 frames against the player's 16, so its walk cycle fits
  twice in a tile and an escort hops; Gold's is 16, the same as its player's.
  Installing it there would not have been a no-op: `src.world.NPC` is an
  *alias* to Gold's real class rather than a facade over it, so the replacement
  would have landed, swapped a correct `walkPhase` for one derived for a cell
  twice the length, and -- because `textBoxUp` reads `top.isOverworld` off a
  stack Gold's world is not on -- stopped every NPC on the map animating.

- The two features that already carried `games = { "gen1" }` internally, FORGET
  HM and REUSABLE TMS, are unchanged; the bundle's own gate now says the same
  thing one level up, where the menu can read it.

- The `src.ui.OptionRows` consolidation in `runtime/menu.lua`, as described in
  the visual half's entry for this version -- the two runtimes are kept in step
  deliberately.

- `tests/gen2gate_test.lua`, shared with the visual half.


## [0.32.22] - 2026-09-02

Two rules about machines, as two rows of their own. Both ship **on**, both are
live -- the code reads its row on the frame it would act, so OFF is the
cartridge back with nothing to relaunch -- and both are Gen 1 only.

- **REUSABLE TMS** (`OPTION > GEN1WILD QOL > ITEMS`). A TM is kept when it is
  used, the way an HM always has been.

  The engine answers a machine with one of two verdicts and the only
  difference between them is whether the bag spends the item: `learn`
  consumes, `learnkept` does not, and `BagMenu` calls `consume` inside
  `if result == "learn"` -- twice, because a POKeMON with four moves goes
  through the forget list first and the TM is only spent if the swap actually
  happened. So this answers the verdict an HM would have answered, and both
  call sites are simply never reached. Nothing is re-implemented and no
  purchase is refunded after the fact, which is the version of this that would
  have got the forget-list case wrong.

  Every refusal is still the engine's: a species that cannot learn the move is
  still refused with its `SFX_DENIED`, and a POKeMON that already knows it is
  still told so.

- **FORGET HM MOVES** (`OPTION > GEN1WILD QOL > POKEMON`). An HM move can be
  replaced when a POKeMON learns a fifth, which is the only way to remove a
  move in this generation.

  `MoveLearnMenu:update` checks the row against `IsMoveHM` before it swaps and
  prints `HM techniques can't be deleted!` instead. That table is a file-local
  in the engine, so the refusal cannot be switched off from outside -- but it
  can be arrived at first. The wrapper answers the one frame the engine would
  have refused and runs the engine's own three lines in its place, so a
  forgotten HM reads exactly like a forgotten anything else. Every other frame
  falls through untouched, and `REMEMBER MOVES` routes its relearn through the
  same screen so it is covered without knowing about it.

  It cannot strand a save. An HM is never used up -- which is the rule the row
  above is named after -- so the move can always be taught back from the same
  one.

## [0.32.21] - 2026-09-02

- No changes; the channel ships as one version.

## [0.32.20] - 2026-09-02

- No changes; the channel ships as one version.

## [0.32.19] - 2026-09-02

- No changes; the channel ships as one version.

## [0.32.18] - 2026-09-02

- No changes; the channel ships as one version.

## [0.32.17] - 2026-09-02

_Write what changed._

## [0.32.16] - 2026-09-02

_Write what changed._

## [0.32.15] - 2026-09-02

_Write what changed._

## [0.32.14] - 2026-09-02

_Write what changed._

## [0.32.13] - 2026-09-02

_Write what changed._

## [0.32.12] - 2026-09-02

- **The autosave hold does not let go inside the next battle.** `OUTCOME_CAP`
  is the promise that a hold which never clears cannot switch autosave off for
  the rest of the session. It was firing blind, and `held` covers three things
  -- a battle, a screen over the map, a running script -- of which only the
  last two can wedge. A battle ends on its own.

  So a player who finished one fight and walked straight into another that ran
  longer than the cap had the hold from the FIRST battle release in the middle
  of the SECOND one, and a save written there: mid-fight, with the party and
  the field in a state the overworld never sees. The hatch now stays shut while
  a battle is up and opens again the moment it is over.

  Found by Gen1AutoSave's own `test_on_load.lua` while porting this change down
  to the standalone mod. This channel's suite had no equivalent check and
  passed the whole time; it has one now, and it fails against the blind cap.

- **Voxel support is a work in progress.** It works best with **potato voxel**
  right now. The other forks -- Battle Art Voxel, Dramatic Shape and its
  variants, and Dramaless Shape -- run on the same code path and should work,
  but are less proven. No voxel mod is required: with none installed, nothing
  about the suite changes.

## [0.32.11] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.10] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.9] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.8] - 2026-09-01

- Two counts published for the bench's `SAVE AFTER` row: how many trainers the
  save calls beaten when a battle ends, and how many when the post-battle save
  is written. Counted rather than looked up by id, because the id is not on the
  battle — the engine closes over the npc inside `onFinish` and never publishes
  it, and a count answers the only question being asked: did anything get
  recorded between those two frames.

  Nothing about when a save is taken changes.

## [0.32.7] - 2026-09-01

- **Autosave stopped appearing after a battle at all — that was 0.32.6's
  doing, and it is fixed.**

  0.32.6 held the save until the post-battle world settled, which was right,
  and put nothing in place of the window it took away, which was not. Under the
  **default** options the idle write path is off entirely — `writeWindow`
  refuses unless `on_load` is explicitly false — so every save goes through a
  covered screen, and the battle's return hold was the only covered screen a
  battle has. Blocking it left nothing behind it: no post-battle save until the
  next door or warp.

  The release is the window now. It is the frame the last text box closed,
  which is a screen changing anyway, and it is the earliest frame on which the
  outcome is certainly written — which was the whole point of holding. Every
  other guard still applies: due, dirty, twenty seconds since the last save,
  sync settled, nobody walking.

  Two smaller things went with it: the hold no longer requires the player to be
  standing still (walking has nothing to do with whether the defeat was
  recorded, and requiring it made the hold sticky for anyone who walks off as
  the dialogue closes), and releasing now counts as the game handing control
  back, so the save gets the full settle window rather than what was left of
  it.

  The test asserts the save **lands** now, not merely that the hold released.
  That is the assertion 0.32.6 was missing, and it fails against it.

## [0.32.6] - 2026-09-01

- **Autosave and the trainer who challenges you again — the third attempt, and
  the first one aimed at the right thing.**

  0.32.2 delayed the *request*. 0.32.5 waited for the battle's `onFinish` to
  return. Both were guesses about which callback records the defeat, and the
  reported case is the one neither covers.

  **Which thing writes the outcome depends on how the battle started:**

  | how it started | what records the defeat |
  |---|---|
  | a line-of-sight trainer | `onFinish` sets `defeatedTrainers[npc.id]` directly |
  | a **scripted** trainer | `onFinish` only *starts a script runner*; the script records it later, past its own text boxes |
  | a static wild encounter | `onFinish` again, on a third branch |

  A Rocket in a hideout is the middle row. `onFinish` returning there means the
  script has *begun*, so 0.32.5's hold released while the thing that writes the
  defeat had not run yet.

  So this stops guessing. The hold is released by an **observable state of the
  world** instead of by a callback: the battle is over, no script is running,
  nothing is on the screen, and the player has had control for three quarters
  of a second. Whatever recorded the outcome has finished by then, whichever of
  the three it was, because all of them run before the game hands the pad back.

  The cost is the post-battle covered window — a save owed at the end of a
  battle now waits for the dialogue to finish rather than landing in the return
  hold. That window was the feature and it was also the bug: it is earlier than
  every one of those writes. Every other covered screen — a door, a warp, a
  cave mouth — is untouched.

  A ten-second cap releases the hold regardless, so a script that never ends
  cannot switch autosave off for the session.

## [0.32.5] - 2026-09-01

- **Autosave saving a trainer battle as un-won, properly this time.** 0.32.2
  fixed half of it and the half it fixed was the rarer one.

  That release delayed the *request*: `battle.ended` no longer marks a save due
  until the battle's `onFinish` has run, which is what writes
  `save.defeatedTrainers[npc.id]`. True, and not enough. `due` is very often
  **already** true when a battle ends -- a catch, an evolution, a map entered
  on the way to the fight -- and the covered-screen write asks only for `due`
  and `dirty`. The battle's return hold is the most covered screen this mod
  ever sees, so a save that was already owed landed there regardless of what
  `battle.ended` asked for: in the gap between the last hit and the defeat
  being recorded.

  So the guard is on the **write** now, where it should have been. From
  `battle.ended` until that `onFinish` returns, neither write path will spend a
  frame -- the same refusal `state.inBattle` already earns, extended over the
  gap where the fight is over and its outcome is not written yet.

  A wild battle carries no `onFinish`, has no outcome pending, and holds
  nothing -- holding every battle would push every post-battle save off the one
  window this mod was built around.

  And a dead man's handle: control being back for a second releases the hold
  anyway. If a teardown ever reaches the overworld without running `onFinish`,
  the failure that leaves is "one save may be early", not "autosave silently
  stopped for the session".

## [0.32.4] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.3] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.2] - 2026-09-01

- **Autosave no longer saves a trainer battle as un-won.** Beat a trainer, let
  the autosave take the window at the end of the battle, then load that save:
  the trainer was standing there wanting to fight again.

  `battle.ended` is emitted while the battle is still tearing down, and the
  thing that writes the **outcome** runs later -- `BattleState` hands the
  battle's `onFinish` to the battle-return transition as its *onDone*, and a
  trainer's `onFinish` is what sets `save.defeatedTrainers[npc.id]` and the
  map's event flag.

  So the ten covered frames at the front of that return -- which is exactly
  the window a post-battle save aims at, and the reason it lands reliably --
  are frames on which the win does not exist yet. The good window is what made
  this happen every time instead of sometimes.

  The save now waits for the outcome call to return. Nothing is lost by
  waiting: `onFinish` **is** the return's onDone, so the frame it runs on is
  the frame the game hands control back, which is already a window in its own
  right -- the player standing where the battle left them, not yet moved. A
  wild battle carries no `onFinish`, has no outcome pending, and is due at once
  as before.

## [0.32.1] - 2026-09-01

- No changes; released alongside the UI mod.

## [0.32.0] - 2026-09-01

- **Every voxel mod, and none of them required.** A voxel mod redraws the
  overworld as a 3D diorama and can draw the battle over the map instead of
  over white paper. There is not one of them: the original Dramatic Shape is
  defunct and three maintained forks have grown out of it -- absol89's
  `BATTLE_ART_VOXEL_FORK`, `DRAMALESS_SHAPE`, and `potato_voxel` for low-end
  devices -- each under an id of its own, because only one may run at a time.
  This bundle knew one of the six ids and now knows all of them.

  Nothing here requires any of them, and nothing changes if you have none.

- **The caught marker no longer lands away from the foe's name under two of
  the forks.** This is the bug the id list was hiding.

  The forks disagree about one thing: where the battle HUDs end up. The
  Dramatic Shape lineage lifts them out of the flat 160x144 frame and
  composites them into its world canvas, and publishes `snapHUDs` to say
  whether it managed it on a given frame. `DRAMALESS_SHAPE` and `potato_voxel`
  do not do this at all -- they override the world *behind* the frame and
  leave the HUDs, the text box and the menus exactly where the engine drew
  them.

  The overlay host asked the wrong question. It looked for a `snapHUDs` wrap
  having recorded a **no**, so a fork with no `snapHUDs` to wrap recorded
  nothing, and nothing read as **yes**: the marker was drawn onto a
  window-sized canvas at coordinates meant for a 160x144 one. Two of the four
  forks, every wild battle. It now asks whether the HUDs are on the canvas,
  which answers no unless something said yes -- so a fork without the
  handshake, a platform where the handshake declined (iOS does), and the
  frames before a battle's first snap are all the ordinary in-frame draw.

- The follower's billboard hook missed `potato_voxel` for the same reason,
  and a follower there kept the engine's own mount size instead of its
  scaled one.

- The forks are declared as optional dependencies, which is what puts a voxel
  mod ahead of this bundle in the load order without any of them becoming
  required.

## [0.31.33] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.32] - 2026-08-31

- The black box round the overworld character on the way into a battle. A
  full-colour sprite marks itself out of the colorize pass -- a sentence about
  the WORLD canvas, where it is drawn. The same draw runs with the **UI** pass
  current during a battle transition, and the UI theme rings every UI-pass
  rectangle with a one-pixel black skirt, so the mark came out as a ring round
  the character's head with the sprite's own white raw inside it. It marks
  only in the world pass now.

  Carried from Gen1Follower 1.6.2.

## [0.31.31] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.30] - 2026-08-31

- No changes; released alongside the UI mod.

## [0.31.29] - 2026-08-31

- A black square outline no longer forms around the overworld character on the
  way into a battle. A full-colour sprite marks a rectangle to be re-blitted
  raw, out of the colorize pass, and it was rounded OUTWARD twice -- once here
  and again by `Renderer.scissorClamped`, which does that to every zone on
  purpose so two SGB zones share an edge. The margin it gains is background,
  and background left out of the pass is invisible until the ground changes:
  the battle wipe takes the ground and leaves the ring. `ADVANCED` and `LIGHT`
  only, which is what named the cause.

  Carried from Gen1Follower 1.6.1, which is where the file lives now.

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

_No changes in this release; the channel ships one version across every
mod._

## [0.31.22] - 2026-08-31

### Fixed

- **Closing a menu, or standing still, no longer takes an autosave.** Two
  windows used to open on the route: `STILL_FOR` seconds of standing still,
  and `SETTLE_GRACE` seconds after a menu or a conversation handed control
  back. Both are in plain sight -- the player is standing on the overworld
  looking at it -- and the second is the frame they have been *waiting* for,
  so the hitch lands in the first stride out of a menu rather than in the
  pause before it.

  This file already knew. `quietFrame` refuses the grace window while SAVE ON
  LOADS is on, and the paragraph over `writeWindow` says why: "with SAVE ON
  LOADS on there is no reason to take it -- a screen the player cannot see is
  coming." `writeWindow` never drew that line, so on the default build a save
  landed the moment a menu closed. It draws it now, in the same place and the
  same words, and it covers the real-stop window too.

  On the default build the route has **no** window: not a settled frame, not a
  real stop. Every write goes under a screen that is already a solid colour --
  a door's fade, a warp, the ride back out of a battle. With SAVE ON LOADS
  **off** the route is the only place a save can go and both windows come
  back, unchanged.

  Nothing is written less often, only somewhere else: `loadScreenWrite` asks
  for the same three things the route path did -- due, dirty, and `MIN_GAP`
  since the last write -- so a save that was going to happen still happens, at
  the next covered screen. The honest cost is that a long walk with no door,
  warp or battle waits longer for one; the events that mark the file dirty are
  mostly the ones that lead to a fade soon after, so in practice that wait is
  short.

  `tests/autosave_veil_test.lua` is 26 (was 22), driving `writeWindow` through
  both settings of the row.

## [0.31.21] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

## [0.31.20] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod._

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

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.5] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.4] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.3] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.2] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.1] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.0] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.30.4] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.30.3] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

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

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.29.3] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.29.2] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

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

- **A rematch builds nothing until you say yes.** 0.18.0 read the price off a
  `BattleState` built to be asked and thrown away on a `NO` — exact, and a live
  battle object constructed on the overworld and held across the prompt for as
  long as somebody took to answer it, with the first mon of a trainer you
  walked away from marked `SEEN` for the trouble.

  The price comes off the trainer's own roster now, with `MATCH LEVELS` applied
  to it the same way the hook applies it on the way in — the same arithmetic on
  the same numbers, so the quote and the prize still cannot disagree. The
  battle is built on the `YES` and not a frame before it.

  What this gives up, stated plainly: if another mod rewrote a trainer's party
  through `trainer.party`, the quote would no longer follow it. Nothing else in
  this cart does.

  This is also the one thing the rematch did that nothing else in the game
  does, and a trainer's overworld sprite vanishing before the battle starts was
  reported against it. I could not reproduce that headlessly or find the
  mechanism in the engine, so **this is not filed as the fix** — it is the
  removal of the likeliest cause, and it is worth doing either way.

  `tests/rematch_test.lua` is 87 assertions, and now holds that a `NO`, a price
  quote and an unaffordable rematch each build no battle at all.

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

### Added

- **`MATCH LEVELS`** — a rematch is fought at your levels, not the ones you
  beat them at.

  Their party moves so its top mon meets the top of yours, keeping the spread
  between their own mons exactly: a 12 / 14 / 16 gym leader met with a level 40
  party is 36 / 38 / 40, still stepping up to the same ace. An offset rather
  than a multiplier, because multiplying 12 / 14 / 16 up to a top of 40 would
  spread them to 30 / 35 / 40 and flatten the lead-in. It moves down as well as
  up, so a leader you left behind is a fair practice fight rather than a
  formality.

  Their mons learn what they would know at the level they arrive at
  (`Pokemon.movesAtLevel`), so a scaled opponent is a coherent one and not an
  old moveset on a bigger body. Parties that carry an explicit move list — the
  designed boss teams — keep theirs.

  **Rematches only, and enforced by construction rather than promised.** The
  scaling rides `trainer.party`, which is a hook the whole game runs through,
  so the wrap is armed for exactly the length of this module's own call to
  `newTrainer` and is otherwise a straight pass through. There is no state in
  which a first encounter, a rival, an arena battle or anybody else's trainer
  sees a level this file touched — `tests/rematch_test.lua` calls the hook
  from outside a rematch with a level 80 party standing by and asserts the
  party comes back the same table, at the same levels.

  The party handed to the battle is a copy. `partyDef` is the trainer's own row
  in the shared data table, and writing a level into it would rewrite that
  trainer for the rest of the session.

  Off is the fight you already had, at the levels you had it.

### Changed

- **The price follows the levels**, with nothing added to make it. Both the
  prize and the price are `baseMoney × the last mon's level`, and 0.18.0
  already read the price off the battle as built rather than off the data
  table — so scaling the party moves them together. A rematch that is worth
  more to win costs proportionally more to enter.

  The invariant that makes the whole thing safe: the price is `floor(prize/2)`
  and the win pays `prize`, so a win returns `ceil(prize/2)` — never less than
  the stake, and strictly more for every prize above zero. The test walks it
  across eight levels from 1 to 100 rather than asserting two numbers.

## [0.18.0] - 2026-08-30

### Changed

- **A rematch costs half of what it pays.** The engine's win branch adds
  `baseMoney × level` inside the battle, and the rematch now asks for half of
  that before it starts — so a win nets you the other half and a loss costs
  you the stake. A repeatable battle that paid full price would be a money
  printer; one that paid nothing would be a trip for exp alone. Half is the
  fight being worth making and worth losing.

  The price is quoted before you are charged, in the words the game already
  uses for a price: the prompt is two pages now, `Want to battle again?` and
  then the mart's own `That will be ¥1200. OK?`, with the `YES`/`NO` after it.
  Short of the money, you get the mart's `You don't have enough money.` and
  nothing is taken.

  It is read off the battle that is about to be fought rather than off the
  trainer's data table, and that is deliberate: `baseMoney × level` uses the
  level of the **last** mon in the party as the battle actually built it, so
  anything that rewrites a trainer's party on the way in — a difficulty mod
  through `trainer.party`, this suite's own or somebody else's — moves the
  prize and the price together with nothing here having to know it happened.
  The cost is that the battle is built to be asked and thrown away on a `NO`;
  the only trace that leaves is the first mon marked `SEEN`, which it was when
  you beat them.

  **`REMATCH PRIZE` off takes both halves out**: nothing is staked, the prompt
  is asked with no price on it, and the prize the engine paid is put back
  afterwards. Off is a rematch with no money in it at all, in either
  direction.

  `tests/rematch_test.lua` is 47 assertions now: the stake on entry, the net
  on a win, the stake lost on a blackout, one yen short and exactly enough,
  and that a `NO` pushes no battle and is charged nothing.

## [0.17.0] - 2026-08-30

### Added

- **`TRAINER REMATCH`** — talk to a trainer you have beaten, read them out
  with `A`, and fight them again.

  The offer sits where the conversation already ends. Every trainer has an
  after-battle line, and walking up to a beaten one prints it; that is the
  whole of what talking to them does today. So:

  - `A` through the line → `Want to battle again?` → `YES` / `NO`
  - `B` out of the line → nothing, exactly as before

  Which button ended the box is the entire interface. No new row on any menu,
  no prompt for anyone who did not ask, and it is the reading both buttons
  already have everywhere else: `A` is "go on then", `B` is "I am done here".
  The engine does not distinguish them — `TextBox` advances and closes on
  either, faithfully to `home/text_script.asm:96` — but it does not have to.
  `onDone` runs inside the same update that saw the press, one line after the
  box pops, so the press is still this frame's and can still be read.

  **A rematch is the battle and nothing else.** The victory path a first win
  takes — `defeatedTrainers`, the header's event flag, `checkVictoryRewards` —
  is not run, so no badge is handed out twice, no gift item reappears, and no
  map's `onVictory` script fires again. A gym leader is an ordinary trainer
  here and can be fought again for the practice; the badge stays exactly once
  yours. The battle also carries no `checkpointOrigin`, deliberately: the
  engine's restore path re-runs that whole first-win branch on anything it
  brings back, so a restored rematch would award the badge a second time.
  Without an origin the checkpoint declines to restore it, which is the
  failure worth having.

  The team is the one you beat, at the levels you beat it. Nothing scales — a
  rematch whose levels move is a different feature, and it would want to say
  so on screen before the battle starts.

  **`REMATCH PRIZE`** (on) decides whether the win pays. The engine adds
  `baseMoney × level` inside the battle's own win branch, downstream of
  anything a mod can reach, so off does not suppress the prize: it reads your
  money before the battle and puts it back after. That also takes back a
  `PAY DAY` used in a rematch, which is the honest reading of the row rather
  than a hole in it — this fight pays nothing.

  `tests/rematch_test.lua` holds the branching: both ways out of the line, a
  frame carrying both buttons, `NO` at the prompt, the four kinds of NPC that
  are handed straight back to the engine, the absent checkpoint origin, and
  the purse on a win and on a blackout.

## [0.16.0] - 2026-08-30

Nothing in this mod changed for 0.16.0; the channel ships as one release, so
it carries the version.

## [0.15.0] - 2026-08-30

### Fixed

- **The editor's `SELECT MENU` page is only there when there is a SELECT
  menu.** `MENU LAYOUT` is carried by both halves of the suite and installed by
  whichever loads first, so this is the same fix as Gen1WildUI Nightly's: a
  page that arranges a menu the build does not have is out of the editor's
  cycle, rather than sitting in it saying `NOTHING TO ARRANGE` and
  `PRESS SELECT FIRST` while `SELECT` does nothing.

  This bundle is the one that publishes that menu — `EASY HM USE` builds the
  overworld `SELECT` popup — so with both halves installed the page is there as
  before, catalog and all.

- **`shared.owner` named a bundle this channel does not have.** The fork
  renamed both halves and left this field pointing at the stable
  `gen1_wild_ui`. It is the fallback used when no engine module can hold the
  claim table, and with a name neither half answers to BOTH bundles stand down
  and `MENU LAYOUT` and `MOD MANAGER` go missing entirely. `tools/check.py` now
  fails on an owner neither bundle carries.

## [0.14.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.14.0` release is one version, which is how the cart's pins resolve.

## [0.13.0] - 2026-08-30

### Fixed

- **`tools/check.py` finds the paired bundle by the id `features.lua`
  declares**, falling back to the old repo names. The nightly fork renamed
  both bundles and the check kept looking for `Gen1WildUI` on disk, so its
  cross-check has never run on this channel — and it printed "not on disk;
  cross-check skipped" on every run while the other half pointed at a mod the
  cart does not install.

  A sibling that names *this* bundle as its partner while this one names
  somebody who is not there is now an error rather than a skip.

  This bundle's own `paired_bundle` was already correct; the fix is the check.

## [0.12.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.12.0` release is one version, which is how the cart's pins resolve.

## [0.11.0] - 2026-08-30

### Fixed

- **Map Pokémon still rendered above the game screen.** 0.10.0 culled the ones
  whose cell was **entirely** off the world canvas, and that was half a fix.

  Measured off the second capture, the remaining stray's art ran from world y
  **-9 to 0** — hanging over the top edge by nine pixels. A cell straddling
  the edge is not entirely off, so it was still queued, and the replay still
  drew all sixteen of its rows into the black margin. A cull cannot reach that
  case by construction.

  Two changes:

  - **`ADVANCED` does not queue at all now.** The post-zone replay exists for
    the modes that would otherwise repaint this art through the shade shader.
    `ADVANCED` has a better answer to the same problem — `markTrueColor`,
    which exempts the rectangle in place — and `PaletteFX.honorsTrueColor()`
    *is* that mode for a Gen 1 game and nothing else. So the sprite falls
    through to the draw the scaled followers already use: it marks its
    rectangle and goes onto the world canvas like everything else on the map,
    and **the canvas clips it, per pixel, for free**. At scale 1 that draw is
    the same pixels the queue would have produced — the anchor and origin
    cancel out exactly, which the tests work through for both mirrors — so
    nothing is lost by taking it.

  - **A straddling cell takes the canvas draw in every other mode too.** The
    replay cannot clip and the canvas can, so `SGB` and `OG RED` send that one
    case down the same path. The trade is the few pixels at the very edge
    going through the colorize pass rather than round it, against a Pokémon
    drawn outside the screen.

  Three bounds now, not one: entirely off (drop it), wholly on (queue it),
  straddling (draw it). `tests/followercull_test.lua` covers all three, the
  rule that decides whether the replay is wanted, and the arithmetic that
  makes the fall-through equivalent — 67 assertions, up from 20.

  Still not a nightly regression: `modules/Gen1Follower` has never been edited
  on this channel other than by these two fixes.

## [0.10.0] - 2026-08-30

### Fixed

- **Map Pokémon rendered outside the game screen** — floating in the black
  margin above it, on a phone in portrait.

  Measured off a capture, the two strays sat at world-canvas y **-16** and
  **-31** — two and four tiles above the top of a 144-tall canvas — at exactly
  `worldOrigin + y * scale`. That transform belongs to one path and one only:
  the **post-zone redraw**.

  For an unscaled follower this mod does not draw into the world canvas at
  all. It queues the sprite with `PaletteFX.markSpriteRedraw`, and the
  renderer replays it in **screen space** after the world blit. That is what
  puts an OG RED sprite's object colours back on top of the zone pass, and it
  is the one draw in the game that skips the canvas — so it is the one that
  does not get the canvas's clipping for free either.

  The renderer *does* scissor that replay, but to the **UI's** rect rather
  than the **world's**, and on a portrait phone the UI rect is the taller of
  the two. Anything drawn in the gap between them comes through. That part is
  the engine's to fix; this is ours: **a sprite whose cell lies entirely off
  the world canvas is not queued at all.**

  Safe because it cannot remove anything anyone could see. The bound is the
  canvas's own size rather than a hardcoded 160x144, so a zoomed-out view
  whose canvas reaches further right and down still draws what it reveals —
  and canvas space starts at 0 whatever the canvas is, so a cell at y -16 is
  above every canvas there is. With no renderer to ask, nothing is culled and
  the draw behaves exactly as it did before.

  Not a nightly regression: `modules/Gen1Follower` has never been edited on
  this channel, so this is a stable bug too.

`tests/followercull_test.lua` is new — 20 assertions on the bound, including
the two strays from the capture and the one-pixel-on-screen edges a sloppier
bound would cut. It lifts the rule rather than loading 1700 lines that want a
whole engine, and `tools/check.py` now compares the two spellings so they
cannot drift.

## [0.9.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.9.0` release is one version, which is how the cart's pins resolve.

## [0.8.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.8.0` release is one version, which is how the cart's pins resolve.

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

Forked from Gen1WildQOL 1.26.0.

### Fixed

- **Autosave no longer lands in the middle of the fade out of a battle.**
  Two separate mistakes, both about the same blind spot: the mod knew that a
  fade is an animation, and only knew it about the *overworld's* fades.

  **The sync plan was let loose during the fade.** `quietFrame` is what holds
  the expensive half of a sync cycle out of any frame the screen is moving in,
  and it asked the overworld: `ow.transitioning or ow.teleportOut`. The end of
  a battle is neither. It is a stack STATE with a veil of its own — the
  engine's white `Transition.battleReturn`, and Gen1WildUI's `BLACK OUTRO` on
  top of it — and both of the overworld's flags are false the whole way
  through. So `screenOver` called those frames the quietest in the game, the
  hold came off, and the plan the write had just woken ran over the fade.
  Every battle, and it is the one fade a player watches all the way through.

  A state says how covered it is itself: `alpha()` is the strength of its own
  veil. Full means the picture cannot change and a long frame costs nothing;
  anything *between* means the veil is on its way somewhere and every frame of
  it was supposed to move. So a partial veil is now exactly as busy as a walk
  and is answered the same way. A FULL one is untouched — at alpha 1 a
  transition is still the best frame in the game to spend, which is the whole
  point of `fullyVeiled`.

  **And the write itself was taken on the worst frame of the outro.**
  `fullyVeiled` asked whether the screen is a solid colour *this* frame; the
  comment above it asks for more than that — "and will it still be one on the
  next?" — and for the engine's own fades the two are the same question,
  because those are palette staircases and a step is eight frames long. A
  mod's fade need not be, and the one on this cart is not: `BLACK OUTRO` is a
  linear ramp that touches alpha 1 on exactly ONE frame — the cut, where it
  pops itself off the stack, runs the engine's own `finish`, and pushes itself
  back. That was already the most expensive frame of the outro, it was the only
  frame that answered yes, and so it was the frame every post-battle write
  landed on.

  The veil now has to have been full on the frame before as well, which is the
  rest of the question the comment was already asking. On a staircase it costs
  nothing — the write moves from the first frame of a hold to the second. On a
  ramp it correctly finds no window at all, because a ramp has no covered
  moment to give. (Gen1WildUI Nightly gives `BLACK OUTRO` a real hold at the
  cut in the same release, so the window comes back.)

### Changed

- **The bundle installs under `gen1_wild_qol_nightly`** and conflicts with
  `gen1_wild_qol`. Its settings live in a bucket of its own, so running the
  nightly does not disturb what the stable one remembers.

- **`modules/` is the source now, not a build product** — the same change the
  UI half's fork made, for the same reason. `tools/build.py` and
  `tools/sync.py` are gone; `tools/rebase.py` in the channel's root is what a
  fork has instead.

## 1.26.0

### Changed
- **`PLAYER` is a row at the top of the menu.** Wild Green's player recolour
  is the reason the cart is called what it is, and reaching it read
  `WILD GREEN > OTHER MODS > MAKE IT GREEN > PLAYER` -- three doors deep,
  behind the repository's name rather than the setting's. It is now
  `WILD GREEN > PLAYER`, first in the list, above the cards and above the
  manager. `OTHER MODS` goes back to meaning what a player installed
  themselves.

  The mechanism is `spec.adopted`: mods the cart pins that the suite gives a
  door of their own, named for what the settings are. The card opens the same
  screen `OTHER MODS` would have and writes through the same loader; only
  where it sits and what it is called have changed. An adopted mod that is not
  loaded is simply not a row.

### Fixed
- **The youngster no longer hops his way to Brock's gym** (Gen1Sprint 0.3.1).
  0.3.0 fixed half of this; the other half was the half the escorts read.
  `stepFramesCur` is the engine's "how long is the step in flight", and the
  escort scripts read it as "how fast does the player move" to pin an NPC's
  own step to it. An escort begun with **B held** pinned its guide to the
  *sprinting* length while the escort's own scripted steps refused the sprint
  and ran at the *walking* one -- so the guide darted a tile in half the
  frames and stood frozen for the other half, a tile at a time, the whole way
  there. A sprinted step no longer outlives its step.

## 1.25.0

### Added
- **`NPC WALK`.** An NPC who walks you somewhere moved its legs twice as fast
  as it covered ground, which beside a walking player does not read as walking
  at all -- it reads as a hop. It was two constants that were the same number
  for the player and not for anyone else: a player's tile takes sixteen frames
  and the walk cycle is sixteen frames long, so one step per tile; an NPC's
  tile takes thirty-two (NPCs move at half the player's speed in Gen 1) and
  the cycle was still sixteen. Two steps per tile.

  The cycle is tied to the step now, so one walk cycle fits whatever an
  entity's own tile length is, and the foot alternates once per tile. Oak's
  walk to the lab pins his step to the player's and was already right; it is
  byte for byte unchanged, and the suite holds that. It also fixes the other
  end of the same mismatch: with `SPRINT` on, a pinned escort's tile is eight
  frames against a sixteen-frame cycle, so the escort lifted a leg once every
  two tiles and slid the rest of the way.

### Fixed
- **Every autosave now lands on a frame nobody can see** (Gen1AutoSave 1.17.0).
  The mod used to pick its moments by asking *where* the player was, and each
  of those places was reported as a stutter in turn: the first frame of a
  door's fade (where the map is still fully drawn, so what freezes is the
  world), `map.entered` at the far end of it (where the transition has already
  popped, so the game arrives somewhere and stops dead), and a beat after a
  menu closes (which is the frame you have been waiting for, so the hitch
  lands in your first stride out of it).

  There is one window now, and it is asked directly: is the screen a solid
  colour this frame, and will it still be one on the next? That is the last
  eight frames of a warp fade -- `GBFadeOutToBlack` is a four-step palette
  staircase and only the fourth step is black -- the ten frames of hold at the
  front of a battle's return, and the black a script fade holds. A pause on
  any of those changes nothing on screen; the black is simply longer.

  A door also no longer leaves a save owing after its own black has taken one,
  which was the mechanism producing the hiccup it was meant to prevent.

## 1.24.0

### Changed
- **AUTO SAVE no longer writes going INTO a battle** (Gen1AutoSave 1.16.0).
  The intro wipe is as covered a screen as the game has, which is why it was
  a save window -- but it is the only covered screen you watch for a cue
  rather than wait out: it opens onto a menu you are already reaching for, on
  the most frequent transition in the game, so the hitch read as the battle
  being slow to start every single encounter. Nothing is lost -- the end of
  the same battle writes the same route with the outcome in it as well.

### Fixed
- **And coming OUT of one no longer stutters the fade.** `battle.ended` fires
  in a gap: the engine pops the battle screen, emits, and only then pushes the
  return transition -- so on that frame nothing is covering anything, and the
  write was a freeze between the last battle frame and the first frame of the
  fade. The transition opens with ten frames at full opacity before the
  palette starts stepping; the write goes there now, so the hitch lands on a
  solid colour and every step of the fade plays after it.

## 1.23.1

### Fixed
- **The follower stops walking out of doors into the building** (Gen1Follower
  1.5.1). The engine tells its follower routine whether a map is being
  ENTERED -- a warp, a door, the boot -- or whether this is a mid-map respawn,
  and the two put the follower in different squares: an entry parks it on the
  player's own cell so it comes out of the doorway behind him, a respawn takes
  the cell behind his facing. The mod's wrapper was dropping that argument, so
  every door was treated as a respawn, and stepping outside the player faces
  down -- putting the follower on the cell he had just come through.

  It also no longer arrives on top of an NPC. The spawn rule asks the map
  whether a cell is walkable, which somebody standing on it does not change;
  an occupied cell now hands the follower back to the player's own.

## 1.23.0

### Fixed

- **Your settings survive a reboot again.** Wild Green is a sealed cart, and a
  sealed cart's per-mod options are not the player's: the loader rebuilds them
  on every boot out of what the cart pins and discards the stored values. Every
  setting in the suite reset on the next launch — and `PLAYER` could never take
  effect at all, because the overworld walker is a record read at load and the
  load is exactly when the choice was being thrown away.

  Unsealing is not the answer: online play requires the seal, and requires it
  to be exactly `sealed`. So the bundle remembers what you chose in its own
  cache — which that merge does not touch — and puts it back as it installs,
  before anything reads it. It is first in the cart's load order, which is what
  puts the restore ahead of the mod whose option is read at load time.

  It restores into the same table the mod manager reads, so there is no second
  source of truth: the manager, this suite's menu and the mods themselves all
  see one value.

  The cart's pins become defaults rather than locks — a pinned value is what
  you get until you choose otherwise. Nothing here touches the cart file, which
  is what online matches on, so the seal keeps every guarantee the arena asks
  of it.

## 1.22.0

### Fixed

- **`MAP` had two switches and only one of them worked.** The layout editor
  listed `MAP` on the `SELECT` menu, said `ON`, and toggling it did nothing —
  because what was actually keeping the row off was `MAP ON SELECT`, an option
  two screens away. A row that reads `ON` and is not there is worse than a row
  you did not ask for.

  `MAP ON SELECT` is gone. The town map is offered outdoors like every other
  row on that menu, and the layout is the switch: hide it in the editor and it
  is gone. Without the editor installed it is simply a row on the menu.

- **The editor's empty page ran off its own box**, and its title carried two
  characters the Game Boy font cannot draw. `NOTHING TO ARRANGE` is exactly
  eighteen glyphs and the box's interior is eighteen tiles, so starting it a
  column in put the last two on the border; and `<` and `>` are not in
  `charmap.asm`, so the arrows drew as nothing and only pushed the title right.
  The page count (`1/3`) says the same thing in glyphs the font has.

- **A row the menu is not offering no longer reads `ON`.** Switching on a
  catalog row cannot put it on the menu when what keeps it off is the game and
  not the layout — no `FLY` in the party, no repel in the bag, daylight. Those
  read `----` now, the same as a pin you have not unlocked.

  (Gen1MenuManager 0.3.2.)

## 1.21.1

### Fixed

- **The layout editor drew a hint over its own frame.** 1.21.0 put the
  `< >:MENU` hint on the row below the existing one — which is the box's bottom
  border, not an interior row — so it came out as a smear across the frame.
  There is one line for hints and it was already full. The arrows are on the
  title now (`< START MENU >`), where there is room and where the thing they
  move is already named. (Gen1MenuManager 0.3.1.)

- **The `SELECT` menu's editor listed only rows it had already seen.** That
  menu's rows appear only where they are usable — `FLY` outdoors, `FLASH` in
  the dark, a repel while one is in the bag — so arranging `FLY` would have
  meant standing outdoors, with `FLY` in the party, holding the editor open.
  A menu whose editor shows one row is not an editor.

  `EASY HM USE` now publishes a catalog of every row that menu can *ever* show
  — `FLY`, `TELEPORT`, `FLASH`, `DIG`, `MAP`, a repel, `CANCEL`, plus whatever
  another mod declares — and the editor lists the ones that are not on screen
  right now anyway, so they can be ordered and switched off in advance, the way
  a pinned row is. A provider declares its own rows alongside its handler:

  ```lua
  qol.exports.fieldMenu.provide(fn, mod.id, { { id = "mine", label = "MINE" } })
  ```

## 1.21.0

**The `SELECT` field menu is arrangeable** (Gen1MenuManager 0.3.0).

`MENU LAYOUT` could arrange the START menu and the PC menu. The overworld
`SELECT` menu — `FLY`, `TELEPORT`, `FLASH`, `DIG`, a repel, and now `MAP` —
was the one menu in front of you it could not touch, because that menu is not
the engine's and has no hook to wrap.

It joins the row registry 1.20.0 published instead. Same arrangement as
everywhere else, in the other direction: everywhere else the manager runs
outermost on a hook so it sees the finished list; here the registry hands it
the finished list directly.

There are three menus now and one row on the OPTION screen, so **LEFT and RIGHT
walk between them in the editor** — the only keys it was not already using.
They do nothing while a row is grabbed. `CANCEL` is locked on the field menu:
`B` closes it too, but a way out you can *see* is not the same as one you have
to know about.

New row: `SELECT ROW` puts `MENU MGR` on that menu. Off by default, unlike the
START and PC rows — that menu earns its place by being short, and it is
arrangeable from the OPTION screen without it.

## 1.20.0

### Added

- **`MAP ON SELECT`** puts the town map on the `SELECT` field-move menu,
  outdoors. Off by default — that menu earns its place by being short and by
  being only what is usable where you are standing, so a row nobody asked for
  is worse than no row. Under `EASY INTERACTIONS`, with the rest of that
  menu's settings.

- **Other mods can put rows on that menu.** It is built fresh on every press
  out of what is usable *right now* — `FLY` only outdoors, `FLASH` only in the
  dark, a repel only while one is in the bag — and until now this file was the
  only thing allowed an opinion about what was on it.

  ```lua
  local qol = mod.find("Gen1WildQOL")
  qol.exports.fieldMenu.provide(function(game, ow, rows)
    rows[#rows + 1] = { id = "mine", label = "MINE", onSelect = ... }
    return rows
  end, mod.id)
  ```

  A registry rather than a hook, because `mod.hooks` gives a mod `wrap` and no
  way to emit one of its own; Gen1Dex's `area.provide` is the same answer to
  the same problem. Rows land above `CANCEL`, which stays the floor of the
  menu. A provider that raises is skipped and said so once — a menu that fails
  to open because somebody else's row threw is a worse bug than a missing row.
  Gating is the provider's business; this only promises that what *it* put
  there is usable here.

### Changed

- **Every row on that menu carries an `id`.** A label is what a row says, and
  it moves with the language and with which repel is in the bag. An id is what
  the row *is* — and anything that wants to reorder the list, hide a row or add
  one needs a name for a row that is not on screen at the moment.

## 1.19.0

**`AUTO SAVE` no longer writes while a menu is up** (Gen1AutoSave 1.15.0).

The widest window it had was anything over the overworld: a text box while
somebody talks, the START menu, the bag, the party, a PC, a mart, a Centre's
heal. The reasoning was that you cannot move under one and the map behind is a
still picture, so a dropped frame there is a frame nobody sees.

Nobody sees it. You feel it. A menu is not a pause in the playing — it is the
part with the most presses per second in it, and a frame lost there is an
*input* lost there. A stutter mid-stride is ugly; a swallowed `A` press is the
game not listening.

So a screen over the overworld is a refusal now, and the doors are the three
they always were: a warp, the end of a battle, and actually stopping. The
moment a menu *closes* is still one of them — by then it is gone and you are
standing on the route with nothing pressed. Closing is the moment, not opening.

Writes that go under a screen you cannot press through — a warp's black screen,
a battle's return hold — are unaffected.

## 1.18.0

**The autosave goes at the start of the door's fade, not the end of it**
(Gen1AutoSave 1.14.0). The black screen plays out now.

`map.entered` is the *end* of a warp's animation. The fade to black has already
played by the time it fires, and the fade back is zero steps long -- the map
simply appears. So the write had the whole cost of a save in front of it and no
animation left to hide under, and what you saw was the door popping you
through. Two rounds of clamping the frame afterwards could not fix that,
because there was nothing left after it to clamp.

The first frames of the same black screen are on the other side of it, with all
thirty-two steps of the fade still to come. The write goes there instead: the
oversized frame is absorbed as one logic step, and the palette then walks down
to black one step per drawn frame. **The black screen is longer by exactly what
the write cost. The animation is not.** `map.entered` stays as the fallback for
a warp whose fade was never writable -- inside the minimum gap, a sync
mid-answer, a script still running -- and records the far side instead.

And the gate the *ordinary* due save goes through had the same ordering bug
that was fixed a version ago in its twin: it asked "is something over the
overworld?" before it asked "is that something a transition?", and a transition
is something over the overworld. So a save that was merely due could land in
the middle of a fade as well.

## 1.17.1

**The black screen plays out when you walk through a door** (Gen1AutoSave
1.13.1). 1.16.1 fixed half of this and shipped with the other half still in.

The remaining half was `AUTO SAVE` calling the warp fade the quietest frame it
could ask for. That was exactly backwards. A fade is an animation: thirty-two
logic steps of the palette walking down to black, and freezing for a fifth of a
second in the middle of one is a stall you can watch happen. The mod now treats
a transition as a frame it must not take, and it checks that *before* the test
that says "there is a screen over the overworld, go ahead" -- because a
transition is such a screen and was being waved through by it.

The clamp that keeps the frame after a save from being paid back as a burst of
logic steps is also armed properly now. It used to look for the sync reply's
expensive frame by watching a queue empty over the call; the plan that runs on
that frame refills the queue before the call returns, so the check compared two
identical values and never once fired. It times the call instead.

## 1.17.0

**`OPTIONS > MODS` is now `OPTIONS > WILD GREEN`.** The suite's door used to
sit next to the engine's `MODS` row; it takes that row's place instead.

Two rows on one screen that both mean "the mods" is a choice the player has no
way to make. `MODS` opens a list of installed zips, which is the answer to a
question almost nobody is asking: with this suite installed, nearly everything
behind it is this suite's, and what they came for is a setting. So the door
takes the slot, named after the cart when a cart is running -- `WILD GREEN` --
and after the bundle when one half is installed on its own.

`START > MODS` follows it. The entry keeps its name and its place in the menu
and lands on the same screens, so the route somebody already knows still works
and no longer arrives somewhere different from the one on `OPTIONS`.

The mod manager is not lost, it is one press further in: `MOD MANAGER` is a row
of its own at the bottom of the suite menu, reading how many mods are
installed. Turning mods on and off was always a trip past the settings, and now
it is. `tools/check.py` fails the build if the door takes the `MODS` row
without that row being there to catch it.

**The folder cards say what is on them.** `OUT IN THE WORLD`, `YOUR POKEMON`,
`BATTLES`, `SAVING & SOUND` and `MOD SETUP` are now `GENERAL`, `POKEMON`,
`BATTLE`, `ITEMS`, `SAVE` and `INTERFACE`. A card is a signpost, and a signpost
that has been written to sound like something is one the player has to read
twice: somebody looking for the battle settings should find a card called
`BATTLE`, not work out which invented phrase covers battles. `AUTO CONTINUE`
moves to `SAVE`, where picking up where you left off belongs.

Nothing moved that a setting depends on -- the option keys are unchanged, so
every switch keeps the value it had.

## 1.16.1

**The warp's black screen is no longer cut short** (Gen1AutoSave 1.13.0). A
save landing under it made you pop into the new map instead of fading in.

That is not the save being slow — it is what the engine does with the frame
afterwards. Logic advances in whole 1/60 steps out of an accumulator, so a
frame that took 60 ms hands the next update a `dt` of 60 ms and the accumulator
pays it back as four logic steps in a row before anything is drawn again. Four
steps of a fade in one frame is not a fade, it is a cut.

The engine has a remedy for its own hitches — `FixedStep:discardCatchup`, which
absorbs the oversized frame as a single step so the animation plays out and
simply takes a little longer. Its own comment notes that only the map-seam path
calls it and that *"warps go through Transition instead"*, so a hitch under a
warp's fade had nothing arming the clamp. `AUTO SAVE` now arms it after
anything of its own that costs a frame: every write, and the frame a sync reply
lands on.

The loading screen is a little longer. It is not skipped.

## 1.16.0

**A save is finished when it reaches your account, not when it reaches the
disk** (Gen1AutoSave 1.12.0).

`AUTO SAVE` used to pace uploads: one autosave-woken upload every five minutes,
every other write's upload **disarmed**, the file left for the engine's own
sweep to carry up whenever it next came round. It was written when a sync cycle
meant a visible stall, and it bought cheapness at the cost of the save being
current — the newest file could sit on one device for minutes while a second
device was still handed the old one.

The reason it existed is gone. The stall was never the sync; it was the
collector burst, removed in 1.14.1. So the cost is *placed* now rather than
avoided — a write only happens in a window you cannot move in, and the sync
plan is held out of any frame the screen is moving in.

**The upload now goes with every save, and it goes immediately.** The engine's
five-second debounce exists to coalesce a burst of writes, and there are no
bursts here — the floor between any two saves is already twenty seconds. Those
five seconds only moved the request off the black screen it could have left
from and into the middle of the next corridor. Pulled forward, it leaves while
that screen is still black. **The loading screen is a little longer for it**,
which is the trade.

## 1.15.0

**`AUTO SAVE` no longer treats a route seam as a door** (Gen1AutoSave 1.11.0).

Every map change was being treated as a warp — worth saving for, and a free
frame to save in. Neither is true of the ones with no screen in front of them.
Walking from Route 1 into Viridian is seamless: the routes are stitched
together, the map scrolls on, and you are mid-stride the whole way across. So
the save landed in the exact frame this mod exists to avoid, for a crossing
that is not progress worth stopping for.

The engine already says which is which, and this was not asking. `map.entered`
carries a `via`: `warp` and `fly` have a screen; `connection` (a route seam),
`reload` (a mod rebuilding the map underfoot), `boot` and `continue` do not.
Only the first two count now, for both jobs at once — **a seam neither writes a
save nor asks for one.**

A save that was already due survives the crossing and goes at the next real
window: a door, a battle, a conversation, a menu, or a real stop.

## 1.14.1

**The stutter at an autosave is gone** (Gen1AutoSave 1.10.0), and it was the
mod's own doing rather than the engine's.

Not the write — the collector burst fired straight after one. `AUTO SAVE` ran
up to 12 collector steps of 4096 KB, which is up to **48 MB** of allocation
credit: on any heap this game has, that is a complete collection cycle, in one
frame, after every single save.

Measured under LuaJIT on a 45 MB heap, 30 save cycles with twenty seconds of
ordinary frames between them — median frame the save lands in:

| | save frame |
| --- | --- |
| 12 × step 4096 (what it was) | **53.0 ms** |
| no nudge at all | 14.3 ms |
| 2 × step 512 (what it is now) | **10.5 ms** |

And it bought almost nothing: the worst frame in the twenty seconds *after* a
save is 4.1 ms with the burst, 5.9 ms with the small nudge. Forty milliseconds
a save, spent to move at most six off some later frame — and on a phone every
number is three to five times larger.

The premise was wrong, and the engine says so in its own source: `Game:update`
already ends on `collectgarbage("step", 1)` every rendered frame, precisely so
the collector never batches into a visible pause. What a save needs is a little
extra credit for one unusually hungry frame, not a cycle's worth.

Also measured and documented rather than changed: `SAVE BACKUPS` roughly
triples what a save costs. It is off by default, and its help row says so now.

## 1.14.0

**`AUTO SAVE` saves in the moments you could not move anyway** (Gen1AutoSave
1.9.0), and it no longer confuses a pause with a stop.

Standing still was one frame of not walking. Letting go of the pad to change
direction, lining up on a doorway, thinking for a second — all of those look
identical to a stop and none of them is one, so the write went into a pause in
the middle of a walk and read as a hitch in the middle of a walk. A stop is
**three unbroken seconds** now, or the moment a menu closed or a conversation
ended and you have not started moving again.

That floor would have made a save wait a long time if a warp and the end of a
battle were still the only other windows. They are not. **Any moment you could
not move if you wanted to** is now a window:

| Window | |
| --- | --- |
| A warp | Already behind a black screen |
| A battle starting | Behind its own intro |
| A battle ending | The return hold, before the fade back |
| A text box, while an NPC talks | The conversation is holding you still |
| The START menu, the bag, the party, a PC, a mart, a Center's heal | Same — anything over the overworld |
| Standing still | A real stop |

Nothing there is a list of named events: something over the overworld is
something holding you still, so the middle rows are all one rule — including
the ones the table does not name.

Two are held back on purpose. **Inside** a battle nothing is written (Gen 1 has
no save there, and the file would record the overworld the fight started from),
and **part-way through a script** nothing is written either — a script that has
set some of its flags and not the rest is not a state to write down. The moment
a script *ends* is a window, and by then it is finished and you are standing
where it left you.

And the save and the sync are no longer one errand. The write is cheap and
wants the first window it can get; the sync cycle it wakes is expensive and
does not arrive for another few seconds. So they ask different questions and
take different windows — the save goes down at the door, and the cycle takes
whatever comes next.

## 1.13.2

**The stutter a few seconds *after* a save is gone too** (Gen1AutoSave 1.8.0).
1.13.1 stopped writing a save into a stride, and that held — but the write is
the cheap half. The expensive half is the sync cycle the write wakes, which
arrives a few seconds later on network time and decodes every save slot of
every game version through a character-at-a-time parser.

`QUIET SYNC` has held that out of walking frames since it was added, and it was
leaking through the same two holes the write had. Its idle test read the
player's `moving` flag, which drops for the single frame between two strides —
so walking a long route without stopping offered it an opening several times a
second. And the hold was capped at three seconds, which counted to three
without checking that you had stopped and then ran the plan wherever it landed.
Between the two, the stall a moment after every save was not an edge case, it
was the ordinary path.

A held direction counts as walking now, and the cap is gone: the reply is
already in hand, the engine's clock stops with the hold, and letting go of the
pad releases it on the next frame. Any menu, text box, battle or doorway
releases it immediately too. The collector's debt after a cycle waits for the
same kind of frame, since the transfer that follows the plan finishes on
network time and answers to nothing.

## 1.13.1

**`AUTO SAVE` never writes into a stride now** (Gen1AutoSave 1.7.0). 1.13.0
moved a due save onto the screens the game already blacks out -- a warp's fade,
a battle's return hold -- and that part worked. Two things in it still put a
write on a moving screen, which is the whole thing it was meant to stop.

The first was a 45-second cap on the waiting: a save that had not found a black
screen in that long was written on the route instead, on the reasoning that a
player who had not warped or fought in three quarters of a minute was standing
somewhere quiet. It never checked that they had *stopped*. So it waited out the
one window where the write would have been free and then gave up and wrote into
the walk.

The second is older, and is why this was reported in the first place. The write
was refused while the player was `moving`, and that flag drops for the single
frame between two strides -- so somebody walking a long route without stopping
satisfied "not moving" several times a second, and that gap is precisely where
a dropped frame is seen.

Idle means standing still now. A held direction says the next stride begins on
the next frame, so nothing is written into it. With that in place the cap is
not needed and is gone: a due save waits for as long as the walking lasts and
leaves by one of three doors -- a warp, the end of a battle, or you stopping.
There is no fourth.


## 1.13.0

**Everything the suite can change is now one row on the game's own OPTION
screen**, nested in folder cards, and the other half of the suite's settings
are on it too.

Everything was reachable before this and almost none of it was findable. The
bundle deliberately put no row on the OPTION screen -- the reasoning was that a
mod's settings live under `MODS` -- so the run button was at
`MODS > GEN1WILD QOL > OPTIONS > SPRINT`: three screens deep, behind a name
that is a repository rather than a thing, and with a fifty-fifty guess about
which half of the suite owned it. Installing both halves gave you two separate
lists to guess between.

### The door

One row on the `OPTION` screen, next to `MODS`. It is named after the cart when
a cart is running -- `WILD GREEN`, which is what was installed and what the
launcher calls it -- and after this bundle when one half is installed on its
own, where calling it `WILD GREEN` would be naming something that is not there.

Both halves add that row under one shared id, so the first one there wins and
the second finds it already present: one door, not two identical ones. The
`MODS > GEN1WILD QOL > OPTIONS` route still lands on the same screens for
anyone who learned it.

### The cards

Behind the door are folder cards -- which is how the game's own OPTION screen
has nested since it grew `SPEED`, `VIDEO` and `AUDIO` pages. Each says how many
of its rows are on.

| Card | Rows |
| --- | --- |
| `OUT IN THE WORLD` | `SPRINT`, `EASY HM USE`, `AREA BANNER`, and Gen1WildUI's `ELEVATOR PANEL` |
| `YOUR POKEMON` | `FOLLOWERS`, `REMEMBER MOVES`, `ALL 151`, and Gen1WildUI's `POKEDEX`, `POKEMON BOX`, `PARTY MENU` |
| `BATTLES` | `EXP SHARE`, `CAUGHT MARKER`, and Gen1WildUI's `BACKDROPS`, `BATTLE INTRO`, `BATTLE MENUS` |
| `ITEMS AND BAG` | Gen1WildUI's `BAG` and `ITEM INFO` |
| `SAVING AND SOUND` | `AUTO SAVE`, `AUTO CONTINUE`, `SOUND` |
| `MOD SETUP` | `MENU LAYOUT`, `MOD MANAGER` |
| `OTHER MODS` | every other loaded mod that has settings |

Four rows fit on a screen, which is the point of the exercise: thirteen
features flat was four screenfuls of scrolling to reach one row, and six cards
is one and a half with three or four rows behind each.

### Both halves, one menu

Gen1WildQOL and Gen1WildUI are one suite split in two for the index's sake, and
that split was leaking into the menu. Each bundle now publishes a description
of its own menu and draws the other's rows beside its own, delegating the
switch to the bundle that owns it and opening that bundle's own settings screen
on `A`. **Whichever half you open, you see the whole suite.**

With one half installed the lookup finds nothing and the menu is that half's
own, exactly as before. A sibling released before this exists is also a miss,
so the two can be updated in either order.

### The rest of what is installed

The last card is every other mod that is loaded and has settings of its own --
the rest of what a cart pins, plus anything installed by hand. Those rows are
built from the schema the mod registered, and written back through the same
tables and the same `mod.options_changed` event the mod manager uses, so a row
set here and a row set there are the same row.

### Three bundled mods came forward

- **`AUTO SAVE` writes on a loading screen** (Gen1AutoSave 1.6.0). The write was
  never the expensive part -- the collector catching up on what it threw away
  is -- and what made it *felt* was where that frame landed: a stutter in the
  middle of walking, the one place a dropped frame shows. A save that is due
  now waits for a screen the game is already blacking out (a warp's fade, a
  battle's return hold) and goes there, so the cost lands on a loading screen
  you were already waiting through. After three quarters of a minute with no
  warp and no battle it writes where it stands rather than not at all.

- **`FOLLOWERS` are drawn at the size their art was drawn at** (Gen1Follower
  1.5.0). The sheets are 16x16 and that is the whole detail budget; the scale
  floor was `0.6875`, so every small species was resampled down to 11px and
  lost five rows and five columns -- 67 of Bulbasaur's 138 opaque pixels. What
  survived read as a flat two-colour blob rather than a small Bulbasaur. The
  floor is `1.0` now and `POKEDEX SIZES` ships off, so nothing is drawn below
  native size unless you ask for it.

- **`SPRINT` stands down while a script is walking you** (Gen1Sprint 0.3.0).
  Oak's walk to the lab pins his step length to yours once, at the start;
  sprint made your step length depend on what you are holding, so Oak was left
  stepping at a length you no longer had and hopped -- step, pause, step, pause
  -- the whole way there.

## 1.12.0

**The option screen is grouped the way somebody looking for a setting reads
it**, and three bundled mods come forward with fixes.

The thirteen rows were in the order the mods happened to be added. `SPRINT`
was first, but `EASY HM USE` -- the other row about walking around -- was
thirteenth; `EXP SHARE`, which decides how the whole party levels and is the
row most likely to be changed before a new save is started, was tenth, *below*
the mod manager. The furniture sat in the middle here and last in
[Gen1WildUI](https://github.com/wild1walker/Gen1WildUI), so the two halves read
differently from each other.

They are grouped now, and the furniture is last in both halves:

| | Rows |
| --- | --- |
| getting around | `SPRINT`, `EASY HM USE`, `AREA BANNER` |
| your POKéMON | `FOLLOWERS`, `REMEMBER MOVES` |
| battles | `EXP SHARE`, `CAUGHT MARKER` |
| catching everything | `ALL 151` |
| saving | `AUTO SAVE`, `AUTO CONTINUE` |
| sound | `SOUND` |
| the furniture | `MENU LAYOUT`, `MOD MANAGER` |

**Nothing installs in a different order.** That is worth saying plainly,
because it nearly did: declaration order was doing two jobs at once, both the
menu's order and the tie-break for features sharing a load priority, so moving
a row up the list would have silently reordered installation among eight
features. Each feature now carries an `install_seq` fixing its load rank, and
the two orders move independently. A test reads the shipped `features.lua` and
asserts both, and fails if a future reorder drops a rank.

### The mods inside it

- **`AUTO SAVE` to 1.5.0** — a sync cycle no longer lands its stall in the
  frames you are mid-step in. The expensive part of a sync is built against the
  server's *reply*, so it arrived on network time with no relation to anything
  you did, which is why it read as the game hiccupping. New `QUIET SYNC` row.
- **`ALL 151` to 1.5.2** — `TEST BENCH` is a developer row now rather than one
  sitting in a shipped cart's options inviting a player to find out what it
  does.
- **`FOLLOWERS` to 1.3.3** — a dead option read removed. No behaviour change.

## 1.11.1

**The Pokémon standing on the maps stop flipping on the spot**, following
[Gen1Follower](https://github.com/wild1walker/Gen1Follower) to 1.3.2.

1.11.0's map Pokémon mirrored themselves left-to-right and back as you walked
around them, looking like they were trying to play a walk animation without
going anywhere. FOLLOWERS draws those sprites itself, because it sizes them
from the Pokédex, and its copy of the engine's pose rules mirrored an up- or
down-facing sprite whenever it was handed `stepFlip`. The engine mirrors only
on the stepping half of a stride — and `stepFlip` is not a stride, it is a flag
an NPC toggles when a step *ends* and then stands there holding.

The pose follows the engine rule for rule now. The follower carried the same
latent flip, hidden because it walks in step with the player; it is fixed too.

Nothing else moved: the other eight tracked mods are pinned where 1.11.0 left
them, no option key changed, and no save key changed.

## 1.11.0

**FOLLOWERS now covers the Pokémon standing on the maps**, following
[Gen1Follower](https://github.com/wild1walker/Gen1Follower) to 1.3.1.

Gen 1 draws every Pokémon that is part of a map from one of five shared
sheets — a "monster", a "bird", a "fairy", a "seel" and the one Snorlax. A
single monster is Mewtwo, a Meowth, a Machop and a Kangaskhan at once, and one
fairy is the Pokémon Fan Club's Pikachu as readily as it is a Clefairy. So the
follower walking behind you came from a set of 251 sheets while every Pokémon
you walked past did not, and the two never matched.

Fifty map objects across Red, Blue and Yellow now draw from the same sheet the
follower would use for that species, at the same Pokédex-proportional size:
the Fan Club's Pikachu and Seel, both sleeping Snorlax, Mewtwo, Articuno,
Zapdos and Moltres, Bill's fused form, Melanie's three, every Pokémon Center's
Chansey, and the rest. Each is picked by the map object's own name rather than
by its sprite id, so a Pidgey stays a Pidgey and a Pidgeot a Pidgeot.

Three are deliberately untouched: the monster, bird and fairy in the Copycat's
room are dolls and her joke is that they are, and the Power Plant's Voltorb and
Electrode wear the item-ball sprite because they are pretending to be item
balls. Bill is the one entry no game data settles — he only says he "got
combined with a #MON" — and he is drawn as a Kabuto by choice.

- A new row, `MAP POKEMON`, appears under FOLLOWERS in the bundle menu on its
  own; it is on by default and turning it off puts the cart's sprites back
  without a map reload. No existing option key moved, and no save key moved.
- FOLLOWERS' menu description says what the feature covers now.

Nothing else in the bundle changed: the other eight tracked mods are pinned
where 1.10.1 left them, and the four features maintained here are untouched.

## 1.10.1

**ALL 151 was switching itself off on every install.** The whole feature: no
substituted encounters, no version exclusives, no gift or fossil mons, no MEW
event -- and no LINK CABLE on the Celadon Dept. Store 4F shelf, which is the
symptom that got it noticed.

The cause was in this repository's build, not in Gen151. `tools/build.py`
dropped `build.lua` on the way in, along with the rest of what it reads as
repository furniture. `build.lua` is not furniture: Gen151 loads it at install
through `mod:read`, and gives up on the feature when it is not there --

```lua
if not (Rarity and Roll and Build and Placements and Hints) then return end
```

-- so every copy of the bundle ever built shipped a Gen151 that logged one
line and returned, while its options row still said ALL 151 was on. Standalone
[Gen151](https://github.com/wild1walker/Gen151) was never affected; it ships
its own files.

- `build.lua` and `bench.lua` are no longer excluded, in both bundles. A `.lua`
  file in a mod's root is mod code. A real build script in these repositories
  is Python under `tools/`, which the directory and suffix rules already drop.
- `modules/Gen151/` carries both files again, so ALL 151 installs and the BENCH
  option has something to switch on.
- `tools/check.py` grew the check that would have caught it: every Lua file a
  module names in its own code has to exist in `modules/`. It fails the build
  rather than leaving a feature to log its way out.

Nothing else changed. No option moved, no save key moved, and no other feature
is touched.

## 1.10.0

**STATUS COLOURS is removed**, at the author's request -- every part of it.

- The feature and its source are gone: no overworld tint, no colour on a
  POKéMON's picture anywhere, and thirteen rows fewer in this bundle's menu.
- `mod.exports.statusColours` is gone with it. It existed only to serve this,
  and nothing else read it.
- `mod.publish` is gone from the bundle runtime for the same reason. It was
  added so this feature could hand its table to the party and the box, it never
  had another caller, and a mechanism with no user is the one that quietly
  stops working.

Settings a player saved under `STATUS COLOURS` stay in the save as dead keys,
the way any removed mod's do. Nothing reads them and nothing writes them.

[Gen1Party](https://github.com/wild1walker/Gen1Party) 1.7.0 and
[Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox) 1.5.0 drop their
half in the same pass; both are byte-identical to the releases before the tint
went in.

Nothing else in this bundle changed. Every other feature is untouched, and the
runtime is back to exactly what it was before this feature existed.

## 1.9.0

**The world tint is a colour filter over the finished frame now, which is what
it should have been from the start.**

Three mechanisms have been tried and the first two were invisible in the game
while being correct against the seam they used:

1. **SGB palette zones.** A map drawn from a full-colour GBC atlas has no
   four-colour palette to shift -- `sgbWorldZones` returns an empty list
   outright under RED++ -- so there was nothing to tint.
2. **A rectangle inside the overworld's own draw.** The overworld draws into a
   canvas of its own and the multiply did not survive the composite.

Both went *through* the rendering. This goes **over** it. `render.hud` is the
engine's own hook for "draw over the completed render pipeline"
(`src/core/Game.lua:699`): it runs after every pass, in screen space, and is
handed the playfield's exact geometry. So there is no canvas to guess at, no
blend mode to match, and no colour mode that can opt out of it -- a coloured
lens over the picture rather than a change to how the picture is made.

It covers the playfield only. The margins and the on-screen pad are untouched,
because the viewport says where the game actually is.

Unchanged: it is still off in battles and under a full-screen menu, still
swallows the poison tick's black flash and deepens instead, and still tops out
near the 0.45 alpha the vanilla flash used, so the strongest it gets is about
as strong as the thing it replaced.

### Still true, and still the one gap

A POKéMON's own picture on the **stats page** tints through the picture's
palette, which a full-colour sprite pack sits out by design. Painting a
rectangle there was tried in 1.8.1 and reverted: the zone covers the picture
*well*, so it turned the white square behind the POKéMON into a lavender block.
The party list and the box do not have this problem -- they tint the icon at
draw time, through
[Gen1Party](https://github.com/wild1walker/Gen1Party) 1.6.0 and
[Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox) 1.4.0, which need
**Gen1WildUI 1.8.1 or later** installed.

## 1.8.2

Two fixes, and the second undoes something 1.8.1 got wrong.

### The world tint is alpha-blended, and now actually appears

It was multiplied. That worked on an opaque menu and did **nothing** on the map
-- the overworld draws into a canvas of its own, and a multiply against it does
not survive the composite the way a straight alpha blend does. The screenshots
showed exactly that split: the stats page changed, the overworld did not.

The thing being replaced was never multiplied either. The engine's own poison
flash is `setColor(0, 0, 0, 0.45)` and a rectangle in the **default** blend
mode, which is the one blend proven to land where this paints. So this is that
rectangle in a colour, held instead of pulsed, with its alpha scaled off the
tint depth and topping out near the same 0.45 -- the strongest it ever gets is
about as strong as the thing it took away, in colour, and never a blackout.

### The stats page goes back to shifting the picture's palette

1.8.1 painted a rectangle over the picture and that was wrong: the zone covers
the picture **well**, background included, so the white square behind the
POKéMON became a lavender block. It shifts the four colours the picture is
drawn through again -- the well's background is colour 0 of the species
palette, an off-white, so it stays an off-white.

The cost of that is honest and unchanged: a picture drawn from full-colour art
sits the shade-remap pass out by design, so this tints nothing for such a pack.
A lavender box for everyone is worse than no tint for some. Tinting the sprite
and not its background needs a seam to set a colour around the sprite's own
draw, and the engine does not offer one on that screen.

## 1.8.1

The stats page picture is **painted** rather than palette-shifted, which closes
the last surface that only tinted for four-colour art. Every place STATUS
COLOURS colours something now works the same way, and works whatever your
`COLORS` mode and whatever art you have installed.

The rect is not hard-coded. `SummaryMenu:sgbPalettes` already answers with an
HP-bar palette over the whole screen plus one zone over the picture, so the
picture's rect is the one zone that is *not* the whole screen. Reading it back
from the screen itself means the engine can move the picture without this
having an opinion about where it went -- and it is also why the HP bar is left
alone: that is the whole-screen entry, and it is skipped.

The engine's own draw still runs first and in full; this only paints over the
rect afterwards.

## 1.8.0

Publishes the condition as a **draw colour**, so the party list and the box can
tint a POKéMON whose art is full-colour.

The tint on a POKéMON's picture rode a palette zone, and a palette zone reaches
only art that goes through the shade-remap pass. A full-colour icon or sprite
pack sits that pass out **by design** -- Gen1Party marks its rect trueColor
precisely so the pass does not repaint it off its red channel -- so the tint
found nothing to colour for anyone running one. Same shape of mistake as the
world tint in 1.7.2, one layer up.

`mod.exports.statusColours.drawColour(mon)` answers with the colour to set
before drawing, or nil for "draw it as it is". Multiplied by the art, so white
is untouched and the colour shifts the hue while keeping the art's own light and
dark. [Gen1Party](https://github.com/wild1walker/Gen1Party) 1.6.0 and
[Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox) 1.4.0 use it.

It lives here rather than in each screen so the three surfaces keep agreeing --
and so the arithmetic is under test in one place instead of copied twice.

The stats page still tints through its palette zone. That screen's picture is
the engine's own draw and there is no seam to set a colour around just the
picture, so under a full-colour sprite pack it stays untinted.

## 1.7.2

**The world tint now works in every colour mode.** 1.7.0 and 1.7.1 both built it
on SGB palette zones, and that could never work for anyone running full-colour
art: `OverworldState:sgbWorldZones` returns an **empty list** outright when
`PaletteFX.usesGbcPack()` and the map has a `gbcAtlas`, so under RED++ there was
no four-colour palette to shift and the tint had nothing to bite on. The screen
stayed exactly as it was.

The thing being replaced was never a palette change either. The engine's own
poison flash is a rectangle drawn over the world:

```lua
love.graphics.setColor(0, 0, 0, 0.45)
love.graphics.rectangle("fill", 0, 0, 160, 144)
```

So this is that rectangle in a colour, held instead of pulsed. It is painted on
the end of the overworld's own draw, which puts it over the map and **under**
everything drawn after it -- text boxes, the START menu, every full-screen menu
-- because those are later states in the stack. That is why the menu keeps its
own colour without a single check for one.

It multiplies rather than washing: the rectangle's colour is lerped from white
toward the tint, so bright grass stays bright, dark tiles stay dark, and the
hue shifts across all of it. A tint of zero multiplies by white, which is the
untouched frame.

### Why it shipped twice

Every test drove the feature file directly, so a feature that installs
correctly and reaches the player doing nothing looked green. There is now a
test that starts where the game does -- the real `features.lua`, the real
`runtime/bundle.lua` -- and asserts a poisoned party ends with a rectangle
painted over the world. Both of the previous mechanisms fail it.

### Still palette-based, and worth knowing

The tint on a POKéMON's own picture -- party list, box, stats page -- still
rides the per-POKéMON palette zone those screens build. A **full-colour icon or
sprite pack sits that pass out by design**, so if your art is full-colour those
will not tint either. Same root cause, same fix available; say the word.

## 1.7.1

**The tint was on the wrong surface.** 1.7.0 turned the START menu purple and
left the map exactly as it was -- the opposite of the feature. Fixed.

The engine keeps two zone lists and they are not interchangeable. The
`render.zones` hook hands a mod the **UI pass**: 160x144 space, the menus and
text boxes. The map is drawn through a **different** list, in world-canvas
pixels, which the engine asks the overworld for a few lines after that hook
runs:

```lua
if worldDrawn and self.overworld.sgbWorldZones then
  worldZones = self.overworld:sgbWorldZones()
end
```

So tinting what the hook handed over could only ever colour the menu. The map
is `sgbWorldZones`, and that is what the feature wraps now. The hook is kept
because it runs once a frame with the game in hand, immediately before that
call, which makes it the right place to work out what colour the frame wants
and to swallow the poison tick -- but the list it hands over goes back
untouched. A tinted menu is not a subtler flash; it is a menu that has gone the
wrong colour.

The tests agreed with the bug, which is why it shipped: they asserted the hook's
list came back tinted, which was exactly the wrong thing to want. They now
assert both halves -- the UI list comes back *identical*, and the map's list
carries the colour -- so this cannot come back quietly.

Nothing else moved. The party list, the box and the stats page were always
right: those screens are drawn in the UI pass, which is the list their own
zones belong to.

### Known limits of the world tint

- A map whose own zone list is empty or absent gets no tint. That happens under
  the GBC pack with a full-colour atlas, where there is no four-colour palette
  to move, and on a map with no palette at all. Nothing is invented in
  world-canvas space to cover it.

## 1.7.0

STATUS COLOURS reaches the POKéMON themselves, and the world now reacts to
everything that takes HP rather than to poison alone.

- **`WORLD REACTS TO` defaults to `DAMAGING`** -- poison, bad poison and burn.
  Gen 1 runs the three of them through one routine,
  `HandlePoisonBurnLeechSeed`, and taking HP is the honest line to draw: a
  colour that means "this is costing you" is worth wearing, and one that means
  "this will be awkward in your next battle" is not. Only poison ticks in the
  field, so only poison deepens; a burn shows its colour while you walk and
  does its damage in battle. `POISON` narrows it back to the old default and
  `ANY STATUS` opens it to all five.
- **A POKéMON's own picture wears its condition** on the stats page -- the one
  screen that shows the full picture with the status printed beside it. Only
  the picture is tinted, not the page: the screen's full-screen HP-bar palette
  is left alone, or the bar would stop meaning what it means.
- **The party list and the box** tint too, through
  [Gen1Party](https://github.com/wild1walker/Gen1Party) 1.5.0 and
  [Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox) 1.3.0, which ask
  this mod rather than carrying their own copy of the colours. The tint rides
  the per-POKéMON zone each already builds, over the species colours, so a
  poisoned CHARMANDER still reads as a CHARMANDER.

### The Pokédex is not in that list, on purpose

A dex entry is a page about a *species*. Gen1Dex never touches a POKéMON
instance and never reads the party, so there is no condition there to show:
RATTATA is not poisoned, your RATTATA is. Tinting it would have meant inventing
a status for a catalogue.

### Fixed

- **`LOW HP` could never have fired in a real game.** It read `mon.maxHP`;
  this engine keeps maximum HP in `mon.stats.hp` (`src/pokemon/Pokemon.lua`).
  The stub POKéMON in 1.6.0's tests carried the field the code was looking for,
  so the tests agreed with the bug. They now use the real shape, and the other
  two spellings are still accepted for a battler or a serialized POKéMON.

### For mod authors

A bundled feature can now publish an API on the bundle's own exports with
`mod.publish(name, value)`, which is how the party and the box reach this one:

```lua
local qol = mod.find("gen1_wild_qol")
local api = qol and qol.exports and qol.exports.statusColours
```

Two features cannot publish the same name -- the second is refused rather than
silently winning, which would make the answer depend on feature order.

## 1.6.0

New feature: **STATUS COLOURS**, on by default.

**The overworld stops flashing black when a POKéMON is poisoned.** It wears
purple instead, for as long as the poison lasts, and the tick that takes the HP
deepens the colour for a moment rather than blacking the screen out. Gen 1's
flash fires twice every fourth step, for as long as you stay poisoned, and what
it communicates -- "someone lost a point" -- fits in a colour. The state is now
visible the whole time instead of announced twice a second, which is gentler to
look at and strictly more information.

It is a palette change, not an overlay. The feature answers `render.zones`, the
hook the engine offers for "custom colorization", so the four colours the frame
is blitted through are what move -- the same thing a Super Game Boy palette
swap does. Nothing is layered over the picture and nothing is dimmed: the
screen keeps its full range of light and dark and simply changes hue, so text
over the map stays exactly as readable as it was.

- **`WORLD REACTS TO`** is `POISON` by default, meaning poison and bad poison.
  Poison is the condition that is doing something to you while you walk, which
  is why it is the one the game already interrupts for. `ANY STATUS` opens it
  to the rest -- worth knowing that paralysis lasts until a town, so that
  setting will paint the world yellow for a long time to say something no step
  changes.
- **`DEPTH`** is `SUBTLE`, `NORMAL` or `STRONG`. Even `STRONG` at the peak of a
  tick stays well short of opaque; going all the way would be the blackout
  again in a different colour.
- **`REPLACE FLASH`** off keeps the resting tint and hands the vanilla flash
  back, for anyone who wants the colour and still wants to be told.
- **A row for each state**, all on: `POISON`, `BAD POISON` (deeper purple --
  Gen 1 keeps Toxic as poison plus a counter, so the colour is what tells them
  apart), `BURN`, `FREEZE`, `PARALYSIS`, `SLEEP`, `FAINTED GREY` and `LOW HP`.
  A party carrying several wears the one that matters most: fainted outranks
  poison, poison outranks the rest, and low HP ranks under every status because
  a poisoned mon at low HP is poisoned first.
- `LOW HP` uses a fifth of max HP, the same threshold as the engine's own
  low-health alarm, so the colour and the sound agree.

### Not in this release

The tint is the **world** only. Colouring a POKéMON's own picture in the dex,
party and box -- purple when poisoned, grey when fainted -- needs each of those
screens to say where it drew that POKéMON, and the three that draw them here
are `Gen1Dex`, `Gen1Party` and `Gen1BillsBox` in the other bundle. The engine's
two sprite hooks only swap which file is loaded; they cannot tint one. So that
half is a change to those three mods and it is next, not forgotten. This
release publishes what the world is wearing through `mod.exports.statusColours`
so they have one answer to read rather than three copies of this table.

## 1.5.0

**This bundle no longer puts a row on the game's OPTION screen.** Its settings
live where a mod's settings live: `MODS` > `Gen1WildQOL` > `OPTIONS`, which lands
on the same nested screens it always did -- every feature, each with its own
page. Nothing was removed from the menu and nothing moved inside it; only the
way in changed, and there is now one of them instead of two.

The OPTION screen is the game's own, and a bundle of a dozen mods was spending
a line of it on something the mod manager already lists.

Also follows both shared menu features:

- **MENU LAYOUT** ->
  [Gen1MenuManager](https://github.com/wild1walker/Gen1MenuManager) 0.2.8. Its
  `MENU MANAGER` row now sits at the **top** of the OPTION screen, above
  `SPEED`.
- **MOD MANAGER** -> [Gen1ModMenu](https://github.com/wild1walker/Gen1ModMenu)
  0.9.0, which is what makes that possible. Since the engine grouped the OPTION
  screen it lays out the rows its own order names first and appends everything
  else behind them, so no mod could reach the front however it anchored itself.
  A row may now ask by carrying `top`, and rows that ask are lifted. It
  reorders what is drawn, never the flat list the hook built, and it runs
  whatever `STYLE` and `HIDE CANCEL` are set to.

The OPTION screen now reads `MENU MANAGER`, `SPEED`, `VIDEO`, `GRAPHICS`,
`AUDIO`, `PERFORMANCE`, `RULESET`, `BATTLE OPTIONS`, `EXTRAS`, `MODS`, then the
platform rows.

## 1.4.3

Fixes the OPTION screen. Both of the shared menu features moved.

- **MOD MANAGER** -> [Gen1ModMenu](https://github.com/wild1walker/Gen1ModMenu)
  0.8.2. **The screen was showing the wrong rows.** With `STYLE = MODERN` and
  `HIDE CANCEL` on -- both defaults, so this was everyone -- the arrow sat on
  one row while the press edited another, and `MODS` looked like it had been
  taken off the screen entirely. The engine grouped that screen and now keeps
  two lists: the flat one the `ui.options.rows` hook builds, and the one on
  screen, where a group's members collapse into a single opener. The cursor
  counts the second; this mod's `CANCEL`-hiding decoration drew the first, so
  the two disagreed from the top row down. `MODS` is ninth in the view and
  thirtieth in the flat list, which is where it was being drawn. Both halves
  read the view now.
- **MENU LAYOUT** ->
  [Gen1MenuManager](https://github.com/wild1walker/Gen1MenuManager) 0.2.7. Its
  `MENU MANAGER` row is anchored to `MODS` rather than appended, so it sits
  with the other mod rows instead of last of all, behind `CONTROLS`, `DATE
  FORMAT` and the platform rows. Grouping runs after the hook and appends
  whatever the engine's own order does not name, which is what stranded it.

The top level now reads `SPEED`, `VIDEO`, `GRAPHICS`, `AUDIO`, `PERFORMANCE`,
`RULESET`, `BATTLE OPTIONS`, `EXTRAS`, `MODS`, and then the mod rows together:
`Gen1WildUI`, `Gen1WildQOL`, `MENU MANAGER`.

## 1.4.2

Adds the `LICENSE` this repository never had. Every standalone mod in the suite
ships one and both bundles did not, while the index entry claimed MIT on their
behalf -- so the claim is now in the repository making it, and in the zip.

It is scoped rather than blanket: MIT over the bundling -- the loader, the
feature registry, the runtime, the adapters, the tools, the suites -- and no
claim at all over the mods carried under `modules/`, each of which keeps its
own licence file where the build put it. `EXP SHARE` and the three `QUALITY OF
LIFE` features are maintained here and neither original states any terms, so
the file says that plainly and leaves them to their authors rather than
assigning any.

No code changed.

## 1.4.1

Follows two of its mods; everything else here is already on its newest release.
No option key was added, renamed or removed, so nothing in the menu moves.

- **FOLLOWERS** → [Gen1Follower](https://github.com/wild1walker/Gen1Follower)
  1.2.1. Followers now darken with the rest of an unlit cave instead of walking
  around Rock Tunnel in full colour while everything else is a silhouette.
- **REMEMBER MOVES** → [Gen1Remember](https://github.com/wild1walker/Gen1Remember)
  1.0.1. The popup drops its heading: the row you pressed already said REMEMBER
  and the box opens over it, so the title repeated the word back at you.

## 1.4.0

Adds **REMEMBER MOVES**, from
[Gen1Remember](https://github.com/wild1walker/Gen1Remember) — teach a Pokémon a
move it has forgotten, from the popup you already open on it. Tracked as a
submodule pinned to 1.0.0. It ships on, and `Gen1Remember` joins the manifest's
conflicts, so the bundle and the standalone are mutually exclusive.

| Row | Ships |
|---|---|
| `PARTY REMEMBER` | on |
| `BOX REMEMBER` | on |
| `PRE-EVO MOVES` | on |
| `HIDE WHEN EMPTY` | on |

`REMEMBER MOVES` takes a relaunch to switch: `PARTY REMEMBER` and `BOX REMEMBER`
are two surfaces rather than a switch for the mod, so there is no row to donate
as its master and the bundle gates it at load.

`BOX REMEMBER` hangs its row in Gen1BillsBox's popup, and Gen1BillsBox lives in
[Gen1WildUI](https://github.com/wild1walker/Gen1WildUI). That lookup crosses the
split, and needs Gen1WildUI 1.3.0 or newer — the version whose Gen1BillsBox
publishes the provider registry. Without it the party row still works.

### Fixed

- **`mod.find` handed back the wrong shape, and cross-mod integrations went
  quietly dead.** The engine's own returns a handle — `{ id, version, exports }`
  — and mods read it that way. The bundle's registry answered with the exports
  table itself, so `dex.exports` was nil and the integration simply did nothing
  rather than failing. Gen151's Pokédex catch hints had never registered inside
  this bundle. Handles now match the engine's, `tools/build.py` writes the
  version map they carry, and the shape is pinned by a test.

## 1.3.0

**`BATTLE XP BAR` has moved out of this bundle.** It is `XP BAR` in
[Gen1BattleUI](https://github.com/wild1walker/Gen1BattleUI) now, which ships in
[Gen1WildUI](https://github.com/wild1walker/Gen1WildUI) — a battle UI feature,
in the battle UI mod.

The move is a bug fix, not a tidy-up. From here the bar was drawn by a wrapper
around `battle.draw`, which runs after **every** link on `battle.overlay`
however high a priority they carry — so it could not be drawn over by anything
and had to clip itself instead. It clipped to `x=88`, which is where the
*vanilla* move panel ends; Gen1BattleUI draws a fourteen-tile panel that ends
at 112, and the twenty-four pixels between were a blue line lying across that
panel's PP row every time a move menu was open. Raising Gen1BattleUI's hook
priority did nothing, because priority was never what decided the order.

Inside Gen1BattleUI the bar and the panel are drawn by one function, bar
first, so the panel covers it the way it covers anything else beneath it — and
a panel that changes width takes the covering with it, which no clip could
have done.

- If you run **Gen1WildUI**, the bar is there and on by default, as it was
  here. Its row is `XP BAR` under `BATTLE MENUS`.
- If you run **this bundle alone**, the bar is gone. That is the cost of the
  move and it is a real one.
- `qol_exp_bar` is retired rather than reused. A key that means something new
  to a save that already has it set is worse than a key that is absent.
- The 3D-battle path is **not** carried over. It drew into another mod's
  canvas through a handshake with that mod's `snapHUDs`, and the handshake
  decided whether the path was taken at all; ported without it, the path would
  be taken whenever that mod was loaded, which is worse than not having it.
- The faint guard moved with the feature — the bar still stops when your
  Pokémon goes down and the engine clears the HUD from under it.

## 1.2.0

Follows [Gen1AutoSave](https://github.com/wild1walker/Gen1AutoSave) to **1.4.0**
(from 1.3.4). Everything else is already on its newest release.

It brings one new row, which appears under `AUTO SAVE` on its own — the bundle
reads each feature's schema at load, so an upstream that adds an option needs
no change here:

| Row | Ships |
|---|---|
| `HEAL CONFLICTS` | on |

No option key was renamed or removed, and `enabled` — the row this bundle uses
as AUTO SAVE's master switch — is still honoured, so the switch keeps working.

### Fixed

- CI ran each vendored mod's own test suite from the wrong directory. Several
  reach their subject with a relative `loadfile("../main.lua")`, so they failed
  on a nil call wherever else they were invoked from, and the step reported
  warnings that said nothing about the mod. Gen1AutoSave's five all pass from
  their own directory.

## 1.1.0

### Fixed

- **The shared-EXP line no longer collides with the continue arrow.** Gen 1's
  battle box draws character *i* at `x = 8 + (i-1)*8`, so the eighteenth lands
  on x=144 — and the blinking arrow is drawn at exactly that column. The line
  read `amongst the party!`, which is eighteen characters, so the bang and the
  arrow rendered as one blob in the corner. It is now `amongst the party`.

- **`EASY HM USE` did nothing when switched on.** It — and `BATTLE XP BAR` and
  `CAUGHT MARKER` with it — had *two* switches: the bundle's, which only
  decided whether to install the feature, and the feature's own row, which
  decided whether it did anything. Turning the feature on installed something
  still set to OFF, and the row that actually mattered sat one screen down
  saying the opposite. Each feature's own row is now its master, the way
  `AREA BANNER`'s already was, so there is one switch — and a live one, with
  no relaunch.

### Changed

Four features that shipped off now ship on:

| Feature | Was | Now |
|---|---|---|
| `BATTLE XP BAR` | off | **on** |
| `CAUGHT MARKER` | off | **on** (`ON (Gen2)`) |
| `AREA BANNER` | off | **on**, 3 seconds |
| `EASY HM USE` | off | **on** |

These only affect a save that has never carried the setting; a stored choice,
including OFF, is untouched. All four switch live now — none of them are among
the rows the menu marks with an asterisk. `EASY HM USE`'s sub-rows are unchanged — `WATER
INTERACTION` already shipped `FISH FIRST`, `REPEL PROMPT` already shipped on,
and `CUT GRASS` inherits the master until it is set.

## 1.0.0

First release. The quality-of-life half of the Gen1Wild index, consolidated
into one installable mod.

### Features

Each of these is a row in `OPTION > GEN1WILD QOL`, switched on or off by
itself, with its own settings one press of A away:

| Feature | From | Ships |
|---|---|---|
| SPRINT | [Gen1Sprint](https://github.com/wild1walker/Gen1Sprint) | on |
| AUTO SAVE | [Gen1AutoSave](https://github.com/wild1walker/Gen1AutoSave) | on |
| AUTO CONTINUE | [Gen1AutoContinue](https://github.com/wild1walker/Gen1AutoContinue) | on |
| SOUND | [Gen1SoundQOL](https://github.com/wild1walker/Gen1SoundQOL) | on |
| FOLLOWERS | [Gen1Follower](https://github.com/wild1walker/Gen1Follower) | on |
| ALL 151 | [Gen151](https://github.com/wild1walker/Gen151) | on |
| EXP SHARE ‡ | originally [exp_share](https://github.com/ShaneMcGovernIE/exp_share) | on, GEN 5+ |
| BATTLE XP BAR ‡ | originally [Quality of Life](https://github.com/unxpected-uxp/pokemon-gen1-recomp-mod-qol) | off |
| CAUGHT MARKER ‡ | Quality of Life | off |
| AREA BANNER ‡ | Quality of Life | off |
| EASY HM USE ‡ | Quality of Life | off |
| MENU LAYOUT † | [Gen1MenuManager](https://github.com/wild1walker/Gen1MenuManager) | on |
| MOD MANAGER † | [Gen1ModMenu](https://github.com/wild1walker/Gen1ModMenu) | on |

‡ Maintained in this repository rather than tracked upstream: the source is
under `maintained/` and edits go straight in. The credit for what these do
still belongs to their original authors, named in the README.

† Carried by Gen1WildUI as well. With both bundles installed exactly one sets
it up, and its settings live under a shared id so they do not move when the
other bundle is the one that wins.

### Changed from upstream

- **EXP SHARE defaults to GEN 5+** rather than OFF. The fighters keep their
  full experience and every living bench Pokémon gains half a fighter's share.
  Seeded once, on a save that has never carried the setting; a stored choice is
  never overwritten.
- **AREA BANNER is redrawn.** Upstream's banner is the dialogue box's exact
  geometry — twenty tiles wide, four tall, flush with the bottom of the screen
  — with one line of text in it. It is now a plaque sized to the name it
  carries, anchored top-left by default, sliding in and out from its edge.
  `POSITION` moves it; `BOTTOM` restores upstream's placement.
- **The XP bar stops drawing when your Pokémon faints.** Upstream's keeps
  going: the engine clears the player HUD the moment the mon goes down, but
  the bar's guards (`safari`, `demo`, `showPlayerBack`, the intro slide) are
  all still false, so it carries on painting a blue stripe over the empty
  space the HUD was cleared from. The caught-indicator feature in the same mod
  already guards its own side with `not battle.enemy.fainted`; this is the
  matching predicate for the player side, applied without editing the vendored
  file.
- **The four Quality of Life features are separate rows** rather than one
  submenu, because wanting easy HM use is no reason to want an XP bar.
- **EXP SHARE is configured in the bundle menu**, not on the engine's own
  OPTIONS screen, so every feature in this bundle has one home.
