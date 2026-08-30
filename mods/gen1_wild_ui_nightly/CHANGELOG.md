# Changelog

This is the **nightly** fork of [Gen1WildUI][stable]. Its versions are the
nightly channel's, not the stable bundle's; `1.21.0` below is where the fork
was taken from.

[stable]: https://github.com/wild1walker/Gen1WildUI

## [0.17.0] - 2026-08-30

Nothing in this mod changed for 0.17.0; the channel ships as one release, so
it carries the version.

## [0.16.0] - 2026-08-30

### Fixed

- **`START` > `SAVE` came out split down the middle in DARK.** Everything
  right of tile 9 was dark and everything left of it was light — across the
  save panel, across the START menu behind it and across the dialogue at the
  bottom, on a line that was not the edge of any of them.

  The line *was* the edge of something: the START menu's box. `SAVE` leaves
  that menu open behind the panel (`start_sub_menus.asm:641-647`), and a menu
  wide enough for `POKéDEX` and the mod rows sits at tile 9, eleven wide and
  the full eighteen tall. It has `tx`/`ty`/`tw`/`th`, so it got a panel — and a
  panel does not draw anything, it hands the blit four colours **for a
  rectangle**. Every pixel inside is remapped through them, including the
  pixels of whatever was drawn on top. Neither box on top had a panel of its
  own: the save panel is an ad-hoc table with a `draw` function and no
  rectangle at all, and `src/render/TextBox.lua` keeps its box in
  `boxTx`/`boxTy`/`boxTw`/`boxTh` rather than the four names this read.

  Reading `boxTx` too would have fixed those two and not the next two. The
  stack is the wrong place to ask: what is on the screen is not what the states
  say about themselves, it is what they **drew**. So that is what is asked now.
  Every box in this game is drawn by `Font.drawBox` — `Menu`, `TextBox`,
  `ChoiceBox`, `ListMenu`, a battle's own boxes, an ad-hoc panel inside a
  state's draw, a mod's window — so the theme wraps that one function and has
  the whole screen, in painting order, whoever drew it. A box drawn over a
  panel is a panel too.

  The order is free and it is the half that makes this safe. `src/core/Game.lua`
  draws every state *before* it collects the zone list and raises
  `render.zones`, so the list is complete and bottom-box-first by the time it
  is read — and the closure only ever runs forwards. A battle draws its own
  boxes and then stacks a command menu on top; the battle's boxes are earlier
  in the list, so the menu's panel cannot reach back and repaint them. Nothing
  here can theme a screen that was not already being themed one box at a time.

  `tests/savescreen_test.lua` stands the real screen up — the same five states
  and the same four `Font.drawBox` calls — and holds the battle case, the
  transitive one, and the recorder's own draining. Against the old panel list
  it produces exactly three zones: the map, the START menu and the `YES`/`NO`,
  which is the screenshot.

## [0.15.0] - 2026-08-30

### Fixed

- **The editor's `SELECT MENU` page is only there when there is a SELECT
  menu.** `MENU LAYOUT` arranges three menus, and the third one is not this
  suite's: `EASY HM USE` builds the overworld `SELECT` popup and hands its rows
  round through a registry the manager joins. On a build without that feature
  there is no such menu — not an empty one, an absent one — and the page was in
  the cycle anyway.

  What that looked like from the player's chair is the whole bug. `LEFT` off
  the `PC` page landed on a page reading `NOTHING TO ARRANGE` and
  `PRESS SELECT FIRST`; pressing `SELECT` there did nothing, because an empty
  page answers only the keys that leave it; and pressing `SELECT` in the
  overworld did nothing either, because the mod that puts a menu there was not
  installed. Two dead keys and a page that can never be filled reads as the
  menu manager being broken, and was reported as exactly that.

  The page is out of the cycle until the registry is actually joined, and a
  request to open the editor on it lands on `START MENU` instead. Join the
  registry and nothing changes: the page is there, with the catalog's rows on
  it before that menu has ever been opened. `tests/selectpage_test.lua` holds
  all three cases — no registry, a registry with a catalog, and an older one
  without.

- **`shared.owner` named a bundle this channel does not have.** The fork
  renamed both halves and left this field pointing at the stable `gen1_wild_ui`
  — the same stale id as the `paired_bundle` 0.13.0 fixed, one field over.

  It is the fallback used when no engine module can hold the claim table: the
  two bundles cannot talk, so one of them is named statically as the one that
  installs a shared feature anyway. With a name neither half answers to, BOTH
  stand down and `MENU LAYOUT` and `MOD MANAGER` go missing entirely — on
  exactly the builds that had no way to notice. `tools/check.py` now fails on
  an owner neither bundle carries.

## [0.14.0] - 2026-08-30

### Changed

- **An item icon sits on a paper blob of its own shape**, not a white square.

  The paper is baked into the art at load, as the icon's own silhouette:

  1. every opaque pixel grows by one in all eight directions — that is the
     sticker edge, and it is also what **closes the outline**;
  2. the outside of the grown shape is flooded in from the border;
  3. anything the flood could not reach is inside the item, and is painted
     opaque white.

  Step 1 is the one that makes it work. These outlines are **not closed** —
  on white paper they never had to be — so a bare flood leaks straight out
  through the gaps: run over the real POKé BALL it caught six pixels of 256
  and left the ball exactly as broken as it was. Growing first closes them.

  **One pixel of growth and not two.** Two closes bigger gaps but swells the
  shape until several icons fill their whole cell, which is the square this
  is here to stop being. At one, none of the 106 fills its cell and the median
  covers about 70% of it, so every icon keeps a shape of its own.

  Baked rather than drawn behind: one image, one draw, the light page cannot
  tell the difference (white on white), and the icon kit no longer has to know
  a theme exists — `matte` and its reach into `mod.theme()` are both gone.

  This is the fourth answer to the same question and the previous three are
  written down beside it, in the code and in `tests/itemicons_test.lua`,
  because each of them looks like the obvious one: paint the cell the page's
  colour (0.6.0), invert the line work (0.9.0), give it a white square
  (0.13.0).

## [0.13.0] - 2026-08-30

### Fixed

- **The two bundles could not see each other.** `features.lua` still named
  `gen1_wild_qol` as this bundle's partner — the **stable** id, which the
  nightly cart does not install. Every lookup from this side across to that
  one failed, and a registry lookup that cannot find its mod does what it is
  supposed to do: nothing, quietly.

  What that broke, visibly: **`MENU LAYOUT` could not arrange the SELECT
  menu.** The row registry for that menu is published over in the QOL bundle
  by `EASY HM USE`, under the alias `FieldMenu`, and the manager joins it by
  asking the paired bundle for it. It never found it, so the editor had no
  catalog — which is why it said `NOTHING TO ARRANGE / PRESS SELECT FIRST`,
  and why pressing SELECT could not help: that hint asks you to make the menu
  show its rows so the editor can learn them, and the catalog exists precisely
  so you do not have to.

  The other half was already right — the QOL bundle names
  `gen1_wild_ui_nightly` — so this was one line, wrong since the fork.

- **`tools/check.py` had been reporting this on every run and I misread it.**
  "Gen1WildQOL not on disk; cross-check skipped" reads like a single-bundle
  checkout. It was the check looking for the partner by the **stable repo
  folder name**, which a renamed channel does not have, so the cross-check has
  never run here.

  It now resolves the partner by the id `features.lua` **declares**, falling
  back to the old names — so the skip message names the id you actually wrote,
  and the cross-check runs on this channel for the first time. And a sibling
  that names *this* bundle as its partner while this one names somebody who is
  not there is now an **error**, not a shrug: that is a mismatch, not a
  checkout.

- **Screens this suite registers are themed.** `SELECT MENU`, the layout
  editor and every other screen the bundle adds stayed white in a dark game.
  The theme knows a page two ways — a marker on the instance, or one of the
  engine's own UI classes — and a mod-registered screen is neither: a plain
  table with no class to match. The facade now marks them as they are
  registered, so the list cannot rot.

  Only an **opaque** screen is marked, and that limit is the safety of it: the
  marker tells the theme "this state is the page", and a page that declares no
  palettes has a whole-screen one synthesised for it — right for a screen that
  covers the display, wrong for a box over the map, where it would take the
  map with it.

- **Item icons keep their paper.** They are pictures drawn *on* paper: all 106
  draw their line work in pure black on transparency and carry no white at
  all, so the page is a POKé BALL's lower half and the gap inside a BICYCLE's
  frame. An icon now sits on a white cell whatever the theme is.

  0.9.0 drew the line work white on a dark cell instead, on the theory that
  black on transparency is an *outline* and an outline inverts. For a ball it
  does. For a BICYCLE it does not — **69% of that icon's opaque pixels are
  pure black, because the black is the bicycle** — and flipping it turns the
  subject into white scribble. A dozen of the 106 are more than half black.

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

### Fixed

- **Item icons came out broken in `DARK`.** A POKé BALL was a red blob, a
  GREAT BALL a scatter of blue and red. This was a regression 0.6.0 shipped
  and it is worth being exact about why.

  All 106 shipped icons draw their line work in **pure black on
  transparency** and carry **no white at all**. The art was made to sit on the
  white page: the page *is* the ball's lower half, and the black outline
  around it is what makes the shape. 0.6.0 painted the cell the colour the
  page was about to be — correct for a mon sprite, whose transparency really
  is margin — so on a dark page the ball lost its paper and kept an outline
  nobody could see against black.

  On dark paper each icon is now drawn from a **twin built at load with its
  pure-black pixels white**, and every other pixel left exactly as it is. A
  ball keeps its red dome and reads as a white outline over the dark page,
  which is what a line drawing inverts to and what the rest of the screen has
  already done. Which paper it is on is asked of `theme.matte()` rather than
  of the theme's name, so the question is the one that matters.

  **A flood fill was tried first and does not work**, and that is recorded in
  the code and in `tests/itemicons_test.lua` so nobody tries it again: fill the
  transparent pixels the outline encloses and you find the outlines are **not
  closed**. They never had to be, because inside and outside were the same
  white page. A POKé BALL's lower edge is a few disconnected strokes and a fill
  leaks straight through them.

`tests/itemicons_test.lua` is new — 10 assertions over the real POKé BALL
shape, traced off the shipped file, including the gaps that defeated the fill.

## [0.8.0] - 2026-08-30

### Removed

- **`COLORFUL`.** `UI THEME` is `LIGHT` and `DARK` now, and the row no longer
  wears an asterisk because there is nothing unfinished left on it.

  What went with it, rather than being left dormant: `Theme.TINTS` (eleven
  four-colour ramps), `Theme.band`, `theme.tint`, the
  `state:gen1wildThemeZones(tint, theme)` contract and the zone-splice that
  existed to serve it, the party screen's header/footer bands and its card per
  Pokémon, and the suite menu's card-per-group colours. `theme.matte()` lost
  its hint argument, `Theme.PAGES` lost its tint column and is a plain list of
  classes, and `state.gen1wildTheme` is now a marker rather than a tint name —
  the theme takes any state that carries one.

  Carrying a half-built third option through the one file that every frame of
  the game runs through is a worse trade than looking it up in the history. The
  work is at `v0.7.0` if it is ever wanted back.

Nothing else changed. `DARK` reaches exactly what it reached in 0.7.0 — the
same pages, the same panels over the map, the same matte behind true-colour art
— and `LIGHT` is still the identity, handing back the list it was given by
reference.

`tests/runtime_test.lua` is 217 assertions (was 303: the tint-ramp, band and
COLORFUL blocks are gone), `tests/partytheme_test.lua` 7 (was 31, and now
covers the marker and the screen's own icon and HP-bar zones rather than the
cards that sat under them), `tests/matte_test.lua` 27 (was 29).

## [0.7.0] - 2026-08-30

### Fixed

- **The rest of the white boxes — the ones on screens this suite does not
  own.** 0.6.0 fixed the party menu, the box, the Pokédex list and the bag by
  painting a matte into each true-colour rectangle before the art went in.
  That left the trainer card's portrait, the summary screen's Pokémon, the
  Hall of Fame PC and the diploma, because there is no line of ours in any of
  them to put that paint on.

  [`runtime/matte.lua`](runtime/matte.lua) handles those. It wraps the class's
  `draw` and runs it **twice**: once with `PaletteFX.markTrueColor` swapped for
  a recorder, which draws the frame and collects the rectangles instead of
  marking them; then the matte, painted into each; then the real draw, which
  puts the art back on top and marks the rectangles properly. Recording
  *suppresses* the marks rather than doubling them, so the renderer still sees
  each rectangle once.

  Twice is the price of not knowing where the art goes until the screen has
  drawn it. It is only ever paid when a theme is on **and** the mode is
  `ADVANCED` **and** the screen actually marked something; a `LIGHT` boot, an
  `SGB` boot, or a screen with no true-colour art on it never reaches the first
  pass. It patches a method on an engine class, which is a heavier hand than
  anything else in this bundle — that is stated at length at the top of the
  file, along with why there is no lighter seam.

  The suite's own dex **entry** screen was also missing its matte behind the
  scaled species sprite. It has one now.

### Changed

- **`ADVANCED` is the mode this is built for and documented against**, and the
  README says so instead of naming `SGB` first. That is not a preference, it is
  where the work actually lives: `Renderer`'s `withTrueColor` begins `if not
  PaletteFX.honorsTrueColor() then return zoneList end`, and on a Gen 1 game
  `honorsTrueColor` is `PaletteFX.mode == "redpp"`. True-colour art — and
  therefore every white box in this changelog and the last — exists in
  `ADVANCED` and in no other mode.

  Earlier advice here said to switch `COLORS` to `SGB` if a theme looked like
  it had done nothing. That was wrong-headed: the flat modes (`OG`, `OG INV`,
  `CLASSIC`) are the ones a theme cannot reach, and `ADVANCED` was never one of
  them.

`tests/matte_test.lua` is new: 29 assertions covering the two passes, the
single mark, the rectangle and colour painted under each of the three themes,
the three ways the wrapper declines (no theme, `LIGHT`, a mode that is not
`ADVANCED`), a screen that marks nothing, a screen that raises part way
through, and that `markTrueColor` is restored to the engine's own afterwards.

## [0.6.0] - 2026-08-30

### Fixed

- **The white box behind every icon on a dark screen.** The party menu, the
  box, the Pokédex and the bag all came out black with a bright white square
  around each Pokémon and each item.

  `PaletteFX.markTrueColor` is the engine's opt-out from the shade pass: a
  marked rectangle is blitted **raw**, so an animated sprite or a coloured item
  icon keeps its own colours instead of being read as four shades. Raw means
  raw. The page the screen cleared to white is white inside that rectangle too,
  and it stays white when everything around it goes black.

  Every screen in the suite that marks a rectangle now paints `theme.matte()`
  into it before the art goes in — the colour that spot is going to *end up*,
  which is black under `DARK`, the screen's paper under `COLORFUL`, and white
  under `LIGHT`. On the party screen the hint is the Pokémon's own card ramp,
  because a party icon sits on its Pokémon's card and not on the page.

  Only ever inside a rectangle about to be marked: a dark rectangle anywhere
  else is shade-3 pixels, which the theme would map to the page's ink and put a
  hole in the page.

  **Not fixed:** engine screens this suite does not replace still show a light
  box around their true-colour art — the trainer card's portrait and badges 5-8
  are the visible case. Those need the screen's draw replaced, which is its own
  piece of work.

- **The START menu never changed.** Nor did the bag's windows, or any other box
  drawn over the map.

  A menu box owns no palettes. The engine hands the zone list to the topmost
  state that has some, a menu box has none, so the **map** answered for the
  whole frame — and the map is not a page, quite rightly, so the theme declined
  the frame and the menu with it. Inverting the frame to catch the menu would
  have inverted the map with it.

  So a box is now themed by its own rectangle and nothing else. Two ways to
  find one: `state:gen1wildThemePanels()` for a screen that draws several boxes
  and knows where they are, and failing that `tx`/`ty`/`tw`/`th` read straight
  off the state. That second one is not a guess — `src/ui/Menu.lua` is every
  menu box in this game and it computes those four in `Menu.new`, and the
  suite's own windows are built to the same four. Which means the START menu,
  the PC menu, field-move lists, the bag's windows and boxes nobody has taught
  this file about all theme, over a map that does not move.

  Deliberately narrow: `src/render/TextBox.lua` carries no box rect, so
  dialogue is not a panel and battles are not touched. Panels are also only
  ever taken from states **above** whatever owns the frame — a page is themed
  as a page, and painting its own box again would be a second coat at best.

### Added

- `theme.matte(hint)` and `mod.theme()` — a feature reaches the bundle's theme
  through a function rather than a field, because the theme is built *after*
  the features are (its hook has to sit outside theirs) and a field captured at
  install time would be nil forever.

23 new assertions in `tests/runtime_test.lua` cover both: the panel rect and
its palette, panels declared by a screen, a page not panelling its own box, a
screen whose panels raise, and the matte under each of the three themes.

## [0.5.0] - 2026-08-30

### Changed

- **`COLORFUL` is actually colourful.** 0.2.0 built every tint to a rule that
  turned out to be the wrong rule: each ramp held the DMG ramp's own lightness
  to within a few values — paper at 246 against the greys' 255 — so that a
  tint would be "not intrusive". Held that tightly, a tint is not perceptible.
  Paper at 246 *is* white, and `COLORFUL` came out as `LIGHT` with a rumour of
  a hue on it.

  The rule is contrast now, not sameness. Every screen's ramp is a light,
  clearly coloured **paper** (black type reads on it at 9:1 or better), a
  **mid**, a **deep** (white type on it at 4.5:1 or better), and an **ink**.
  The test that measured drift against the DMG ramp is gone; in its place one
  that measures chroma and reads the ramp both ways — the assertion the old
  ramps would fail.

### Added

- **A band, and a card per Pokémon, on the party screen.** `Theme.band(tint)`
  turns any tint into a header strip — the deep shade where the paper was,
  white where the ink was — built from the tint so a band can never be a
  different colour from the page it caps.

  The party screen uses it across its header and footer rows, and gives every
  member a card the full width of its row in that Pokémon's **own species
  colour**: the colour `SPECIES COLOURS` has always put on the icon cell,
  brought out to the whole card. The species' light shade is the paper and
  shade 3 is left alone, so the name, the level and the HP numbers stay black
  on it.

- **A screen's own zones now splice in above the page and below its own**,
  where they used to be appended after everything. That is what lets a card be
  a *ground*: the icon keeps its full species palette and the HP bar keeps its
  green, instead of both being painted over by the card behind them. A green
  bar that turns the colour of its card is information taken away to add
  decoration.

  `tests/partytheme_test.lua` is new and covers this against the real
  `screen.lua` and `chrome.lua`: which tile rows each band and card lands on,
  which palette each carries, and that the icon and bar zones still claim
  their own cells. 31 assertions.

### Still WIP

The bag, the box, the dex list and the battle command grid do not paint
themselves yet — they take their screen's tint and nothing more. `COLORFUL`
keeps its asterisk until they do.

## [0.4.0] - 2026-08-30

Nothing changed in this mod. It carries the channel's version so every archive
on the `v0.4.0` release is one version, which is how the cart's pins resolve.

## [0.3.0] - 2026-08-30

### Fixed

- **`UI THEME` did nothing.** The row cycled, the setting stored and reloaded,
  the OPTION screen said `DARK` — and the screen behind it stayed white. It
  was not a near miss: `DARK` was declining every screen in the game.

  The gate was the bug. This file decided which frames were the UI's by
  looking at what the frame asked for rather than at what was on the screen —
  *a zone list that opens on one whole-screen zone of the four DMG greys is a
  black-and-white page* — on the theory that a page drawn in the game's own
  four shades asks for the identity palette. It does not. Every UI screen in
  the engine asks for a **named** palette and lets the SGB pass colour it,
  which is what the pass is for:

  | screen | asks for |
  |---|---|
  | `OptionsMenu`, `ListMenu`, `ManagerState`, `NamingScreen`, `TrainerCard`, `Diploma` | `MEWMON` |
  | `PokedexMenu`, `DexEntryMenu` | `BROWNMON` |
  | `PartyMenu` | `GREENBAR`, then a zone per party row |
  | `TownMap` | `TOWNMAP` |

  Not one of those is the four greys, so the test never passed and the theme
  never fired. The rule that read as a definition was a guess about the
  engine, and it was wrong.

  A page is now recognised by **whose the frame is**: the topmost state that
  either says what it is (`state.gen1wildTheme`) or is one of the engine UI
  classes in `Theme.PAGES`. A state that owns the frame's palettes and is
  neither — the overworld, a battle, the title screen — ends the search, so
  those are still never touched. An overlay that owns no palettes is stepped
  over, so a confirm box on top of a menu leaves the menu themed. The old
  zone-shape rule is kept as a third way in, for a mod's screen that really
  does open on whole-screen greys.

  Two consequences worth naming:

  - A page whose state declares no palettes at all inherits whatever is
    underneath it, and is opaque — so those zones are colouring a map nobody
    can see. Transforming them would invert the world. A whole-screen page is
    **made** for such a screen instead.

  - `DARK` reverses the page's own palette rather than painting a black
    rectangle, so the Pokédex stays faintly red and the party menu faintly
    green under it. That only works because every SGB background palette in
    the pack ends dark; a page whose reversal would not actually be dark
    (this suite's own screens open on the player's outfit ramp) falls back to
    plain black paper. Measured, not listed, so a palette added later is
    judged on what it is.

  What `DARK` now reaches: the OPTION screen, the mod manager, the Pokédex and
  its entries, the party menu, the summary, the naming screen, the town map,
  the trainer card and diploma, the Hall of Fame PC, and every list the engine
  builds through `ListMenu` — the bag, the shops, Bill's box and the PC.

  One limit, stated rather than worked around: a theme changes the colours a
  zone carries, so it works in the display modes that use them (`SGB`,
  `SGB INV`, `ADVANCED`, `OG RED`). The flat modes — `OG`, `OG INV`,
  `CLASSIC`, a custom ramp — are the player asking for one palette over the
  whole game and `PaletteFX.effectiveColors` replaces every zone to give it to
  them. `OG INV` already is a dark mode for the whole screen.

  `tests/runtime_test.lua` gained the coverage this needed and did not have:
  the OPTION screen themed through a real class match, a page synthesised for
  a screen that declares nothing, the walk stopping at the overworld and
  stepping over an overlay, and the darkness proof.

## [0.2.0] - 2026-08-30

### Fixed

- **The white bar above a wide arena.** A battle asks the renderer for a
  *white surround*: `Renderer:endFrame` clears the void around the blit to
  `PaletteFX.paperShade` for any state that sets `letterboxWhite`, and a battle
  sets it. That is right for the game it was written for — the field is white
  paper, so a white surround makes the paper look like it runs off the edges of
  the screen instead of stopping at a rectangle.

  Put a BACKDROP in the field and the reasoning inverts. The paper is gone, the
  surround is the only white left, and instead of disappearing it becomes a
  bright frame around the art. A WIDE battle is 304x144 — very wide and no
  taller — so in an ordinary window the bars above and below it are the biggest
  thing on the screen. That is the bar.

  Gen1Arena now carries the backdrop into them, through `render.letterbox` —
  the seam the engine documents for exactly this ("SGB borders / custom void
  art in the bars around the 160x144 (or world) blit"), which runs after the
  void is cleared and before the game canvas, so the playfield still lands on
  top and nothing here can cover the battle.

  By **edge clamp**, not by scaling the picture up to the window: a magnified
  copy behind a 1:1 copy meets at a visible seam — two different scales of the
  same tree. Stretching the outermost row of pixels gives the bars the colour
  the field already has where it meets them, so sky continues as sky and ground
  as ground. `EDGE TO EDGE` is a row of its own, and `OFF` is the white bars
  back. `BATTLE BG = world` and `FAITHFUL RATIO`'s mobile lock both stand it
  down — the first has no bars, and the second promises they stay black.

- **`BLACK OUTRO` holds at the cut.** It went straight from the last frame of
  the fade out to the first of the fade in, so it was at full black for exactly
  one frame — and that frame is the one that does all the work: it pops the
  fade off the stack, runs the engine's own `finish`, and pushes it back.

  It was also the only frame the whole outro was fully covered on, which made
  it the only one anything looking for a covered frame could find.
  Gen1WildQOL's autosave asks exactly that question, found that frame, and
  wrote its save into the middle of the cut — every battle. The two halves of
  that are fixed together; see Gen1WildQOL Nightly 0.2.0.

  Ten frames, which is the engine's own pause before `GBFadeInFromWhite`
  (`home/overworld.asm:351-352`) — the fade this one replaces. So the outro
  now reads the way the return it stands in for does, the work has a frame to
  itself, and a covered moment is a moment rather than an instant.

### Changed

- **Gen1Arena's `DIAGNOSTIC` and `FIELD TEST` rows are always here.** Upstream
  they exist only when the loader was started with developer mode on. The
  nightly channel *is* the developer build, and a toggle that only exists under
  a flag nobody running a nightly has set is a toggle nobody running a nightly
  can use. On a release build the line reads `mod.developer == true` and both
  rows go with it.

## [0.1.0] - 2026-08-30

Forked from Gen1WildUI 1.21.0.

### Added

- **`UI THEME` on the game's own OPTION screen: `LIGHT`, `DARK` or
  `COLORFUL*`.** One row, `START > OPTION > UI THEME`, cycling with left and
  right like every other value row on that screen and taking effect on the
  next frame. `LIGHT` is the default and is what every build before this one
  looked like.

  It is not a repaint. Every full-screen page this suite draws is black and
  white on purpose — the art is the game's own four DMG shades, the boxes are
  the game's own border glyphs, and the colour arrives afterwards from the SGB
  pass, which blits the finished frame once per zone through a shader that
  maps those four shades onto that zone's palette. So a theme here swaps the
  four colours a zone carries and nothing else: `runtime/theme.lua` wraps
  `render.zones`, which is handed the finished list on the way to the blit.
  Nothing is redrawn, no screen is edited, and no feature learns that themes
  exist — which is why a theme cannot move a glyph off a screen.

  **Which frames are ours** is decided by what the frame is already asking
  for, not by what state is on top: *a zone list that opens with one
  whole-screen zone of the four DMG greys is a black-and-white UI page*. That
  is the definition rather than a guess — `{ P.whole(P.GRAYS) }` is what a
  full-screen menu in this engine returns, and it is the identity through the
  shade shader, which is how a page keeps white paper and black ink while the
  display mode colours everything else. The overworld returns per-map terrain
  palettes, a battle returns named battle palettes and the title screen
  returns its three lettered bands, so none of the three is touched. It also
  means a screen nobody here has heard of is themed on the day it arrives, and
  a mod's screen that draws in colour is left alone on the day it arrives.

  The suite's own settings screens are the one exception, and they opt in by
  name (`gen1wildTheme` on the instance): they open on the `MEWMON` palette
  rather than on the greys, deliberately, and would otherwise be the only
  screens in the suite a dark mode did not reach.

- **`DARK`: black and white, swapped.** Every zone on the page is reversed,
  lightest for darkest — paper black, ink white, and the two shades between
  them exchanged. The panels inside the page go with it: a species colour
  behind a party icon, the HP bar's own green. Leaving those alone would put a
  white-grounded icon on a black page, which reads as a hole rather than as an
  icon; reversed, the icon sits on the page's black and reads light-on-dark in
  its own colour. That is what the engine's own `SGB INV` display mode does to
  the whole game, and doing it per zone is what keeps it to the menus.

  Art is not inverted. A `colors == false` zone is the engine's opt-out from
  the shade shader — an animated mon sprite, an item icon — and painting it
  would undo the art it was cut out for.

- **`COLORFUL`, marked as work in progress.** The page takes a tint chosen by
  what the screen *is*: the Pokédex reads red because a Pokédex is a red
  device, the box blue, the party the green of a full HP bar, the bag leather,
  the mart gold, the trainer card slate, the settings violet. A screen the
  suite registered names its own tint; a screen the suite *replaced* is
  identified by its class instead, which is exact — those replacements keep
  the engine's own instance and swap only its draw methods, so
  `getmetatable(state)` is still `src.ui.PartyMenu`.

  Every tint is the DMG ramp with a hue laid over it and its **lightness
  held**: all four land at relative luminance 246 / 170 / 85 / ~6 against the
  greys' 255 / 170 / 85 / 0. That is the whole of "not intrusive" — a
  background you notice after the words rather than before them, and never one
  that makes a word harder to read. `tests/runtime_test.lua` measures all four
  of every ramp against it, so a colour added later cannot be added by eye.

  Only the page is retinted. The panels on it are already colour and already
  mean something — a party icon is the species' own colour, an HP bar is green
  because it is nearly full — and repainting those would be taking information
  away to add decoration.

  On the suite's own screens the cards are coloured **by what they open**:
  `BATTLES` on the battle paper, `ITEMS` on the bag's, `YOUR POKEMON` on the
  party's. A card is a button and a button should be the colour of the thing
  it chooses, so a player picks one by colour before they have read the word.
  That is done with zones over the four 4-tile boxes `src.ui.OptionRows` lays
  down the screen, so nothing here draws a box and nothing here can move one.

  **What is still to do**, and why the row wears an asterisk: the battle
  command grid's four buttons (`FIGHT` / `PKMN` / `ITEM` / `RUN`) are the
  clearest buttons in the suite and are not coloured yet. They sit over a
  battle, whose zone list is the battle's own named palettes rather than a
  black-and-white page, so colouring them means adding zones to a frame this
  theme currently declines to touch — a different mechanism, and one that has
  to be got right around the battle's own colorisation before it ships.

### Changed

- **`modules/` is the source now, not a build product.** The stable bundle
  assembles `modules/` from `upstream/` submodules and `maintained/` with
  `tools/build.py`, and `tools/sync.py` moves the pins. A fork has nothing to
  sync from and nothing to assemble, so both are gone and the tree is what the
  game reads. `tools/check.py` knows the third case and counts it separately;
  `tools/rebase.py` at the channel's root is what a fork has instead of
  `sync.py` — it fetches two stable releases and offers the diff between them,
  rather than overwriting a tree that has diverged on purpose.

- **The bundle installs under `gen1_wild_ui_nightly`** and conflicts with
  `gen1_wild_ui`. Its settings live in a bucket of its own, so running the
  nightly does not disturb what the stable one remembers.

## 1.21.0

**`PLAYER` is a row at the top of the menu.** Wild Green's player recolour is
the reason the cart is called what it is, and reaching it read
`WILD GREEN > OTHER MODS > MAKE IT GREEN > PLAYER` — three doors deep, behind
the repository's name rather than the setting's. It is now
`WILD GREEN > PLAYER`, first in the list, above the cards and above the
manager. `OTHER MODS` goes back to meaning what a player installed themselves.

The mechanism is `spec.adopted`: mods the cart pins that the suite gives a door
of their own, named for what the settings are. Both halves declare the same
list, for the same reason both declare the same cards — either can end up
hosting the merged menu.

## 1.20.1

**Pokemon evolve again.** With the bundle installed, nothing ever did — not
the starter at level 16, not anything else — and there was nothing on screen
to say why.

BLACK OUTRO fades the battle out by wrapping the one place a battle ends,
`BattleState:finish`. But the engine calls that more than once: a battle that
levelled somebody hands the battle screen to the evolutions and *returns*,
coming back through `finish` a second time once they have played
(`end_of_battle.asm:42-45`). The fade took that first call for the ending. It
ran the engine's finish at its own midpoint, at full black — so the evolution
started behind the black — then, finding the battle still up because that call
had not left, popped what was on top of it and finished the battle for real.
What it popped was the evolution.

The hand-off is a false start, the same as the PAY DAY pickup the fade already
steps aside for. It steps aside for this one now, so the evolution plays on the
battle screen where the ROM puts it and the fade takes the call that actually
leaves. `tests/battleoutro_test.lua` stands both calls up and holds it there.

## 1.20.0

**Your settings survive a reboot again.** Wild Green is a sealed cart, and a
sealed cart's per-mod options are not the player's: the loader rebuilds them on
every boot out of what the cart pins and discards the stored values. Unsealing
is not the answer — online play requires the seal — so the bundle remembers
what you chose in its own cache, which that merge does not touch, and puts it
back as it installs, before anything reads it.

It restores into the same table the mod manager reads, so the manager, this
suite's menu and the mods themselves cannot disagree. Nothing touches the cart
file, which is what online matches on.

## 1.19.2

**Three things the layout editor drew that were not true** (Gen1MenuManager
0.3.2).

Its empty page ran off its own box — `NOTHING TO ARRANGE` is exactly eighteen
glyphs and the interior is eighteen tiles, so starting it a column in put the
last two on the border. Its title carried `<` and `>`, which are not in the
Game Boy font, so they drew as nothing and only pushed the title right; the
page count (`1/3`) says the same thing in glyphs the font has. And a row the
menu is not offering read `ON`, when switching it on cannot put it there —
those read `----` now, the same as a pin you have not unlocked.

## 1.19.1

**The layout editor drew a hint over its own frame** (Gen1MenuManager 0.3.1).
1.19.0 put the `< >:MENU` hint on the row below the existing one — which is the
box's bottom border, not an interior row — so it smeared across the frame. The
arrows are on the title now: `< START MENU >`.

## 1.19.0

**`A` on the AREA map flies you there** (Gen1Dex 1.9.0). The AREA screen *is*
the town map: if the party can `FLY` and the cursor is over somewhere flyable,
closing it to open the START menu and pick `FLY` to reach the same picture
again is the screen being pedantic about which door you came in by. With the
hint down, `A` over a flyable town is the flight.

Which towns qualify is the game's own rule — visited, has a fly warp, is a fly
town — so a town this says yes to is one the `FLY` screen would have offered.
No `FLY` in the party, indoors, the cursor on somewhere unflyable: any of them
and `A` closes the screen the way it always did. New row: `FLY FROM AREA`.

**And the menu editor walks between three menus** (Gen1MenuManager 0.3.0). The
overworld `SELECT` field menu can be arranged now, alongside the START and PC
menus; `LEFT` and `RIGHT` step between them in the editor.

## 1.18.0

**FLY is a map, not a list drawn on a map** (Gen1Dex 1.8.0).

The FLY screen already shows the whole of Kanto with a bird on the town you
have selected — and then walked that selection with `UP` and `DOWN` through the
fly order. The picture said "pick a place"; the controls said "scroll".

It is steered by direction now, like the other two town maps. Open the map,
move to the town you want, press `A` to go there.

Which towns are reachable does not change: that set is the game's own, already
narrowed to the towns you have visited, so everywhere the cursor can reach is
somewhere `A` can take you.

## 1.17.0

**The town map moves by direction, not by the story's visit order**
(Gen1Dex 1.7.0).

`UP` and `DOWN` fell back to the engine's list walk whenever there was nothing
in the direction pressed — so a press off any edge of Kanto, and there are four
edges' worth of those, jumped the cursor to wherever the **cursor order** went
next. That order is the order the towns come up in the story, not where they
are, so the cursor leapt across the map for reasons nothing on screen could
explain. That is what reads as the map cycling a list: for those presses it
was. A key with nothing in front of it now leaves the cursor where it is.

**And the map you open from the bag is steered the same way.** Same screen,
same picture, and until now a different d-pad: the engine walks its cursor
along the visit order with `UP` and `DOWN` and ignores `LEFT` and `RIGHT`
entirely. One map should navigate one way however it was opened.

Only the d-pad. `B` still closes both, the banner is still the engine's, and
`FLY` is left alone — its cursor cycles the visited destinations in fly order
and `A` flies to the one it is on, so direction is not what that d-pad means.

## 1.16.1

**The AREA screen ends on the map** (Gen1Dex 1.6.2).

1.16.0 hid the `AREA UNKNOWN` slab while the hint strip was up and put it back
when `A` dismissed the strip. That was backwards: dismissing the strip is a
request to *see the map*, and a slab across the middle is the one thing that
request cannot have. The route is `DEX`, then `<NAME> UNKNOWN`, then the map —
and the map is where it ends. The slab is gone from every frame of that screen
now.

**And your marker is on it.** The player marker lives in the same branch the
slab was the other half of: with no nests to mark, vanilla puts the slab up
*instead* of marking where you are standing. That trade made sense while the
slab covered the map; with it gone the screen is a plain town map, and a plain
town map has you on it.

Also narrows the stand-in that hides the slab so it catches the slab and only
the slab — it was matching on screen position alone, which was a net over every
path the engine's draw can take.

## 1.16.0

**The `AREA UNKNOWN` slab is gone from the AREA screen** (Gen1Dex 1.6.0).

With no nests to mark, vanilla puts a 17x4 box across the middle of the map.
On this screen that was the third thing saying so at once: the header above it
already reads `<NAME> UNKNOWN`, and the strip below carries the half worth
reading — `EVOLVE CHARMELEON AT LV36`, or whichever answer the species has. So
a screen that *has* an answer was covering half its own map to say it has none.

Only while the strip is up. `A` puts the hint away for a look at the bare map,
and with the strip gone that box is the only thing left saying why the map is
empty — so there it stays, and `START` brings both back together.

## 1.15.1

**The Pokédex side menu has a box again** (Gen1Dex 1.5.3). A on a POKéMON you
had met came up as four bare words -- `DATA`, `CRY`, `AREA` -- floating over
the list, with `QUIT` printed across the SEEN and OWN counts and past the
bottom of the screen. A on one you had *not* met opened a properly boxed
two-row menu, which is what made this look like the discovered entries were
the broken ones.

Both were the same omission. The vanilla dex prints those four labels
permanently into the block down the right of its screen, so the engine's side
menu draws the labels and the cursor and nothing else -- there is already a
block under them. This list has no such block: the right of the screen is
where the names run, and SEEN / OWN moved into a footer box.

The engine's menu is now taken and put in a box of the mod's own, bottom
aligned on the last row of the list. Nothing about what a press does changes:
the rows are the engine's own, not copies of them. The row the menu was opened
on also reads as hollow underneath it now, the way the vanilla list draws it.

## 1.15.0

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
`BATTLE`, not work out which invented phrase covers battles.

Both halves declare the same six cards in the same order, because either half
can end up hosting the merged menu; the suites on both sides check that.
Nothing moved that a setting depends on -- the option keys are unchanged, so
every switch keeps the value it had.

## 1.14.1

**The white box behind a battler is gone** (Gen1Arena 0.21.0), and it was two
bugs standing on top of each other.

The first: the scratch canvas `MON PAPER` measures a sprite in takes the
window's DPI scale unless it is told not to. On a phone that is 3, so a 56x56
request is a 168x168 canvas with the sprite in it three times the size — and
the measurement then read the sprite's own 56x56 out of that, which is its
top-left *eighteen* pixels, magnified. A corner has few enough colours to look
like four-shade art and is empty enough to look eaten, so both of the tests
that decide whether a sprite needs paper passed, and the paper went down in a
box measured off a corner. On the enemy side that is 14x24 hard against the
right edge of the pic, which is exactly what the screenshot showed. At DPI
scale 1 none of it happens, which is why it shipped twice.

The second: the test for "this sprite lost something" was how much of its
bounding box is not ink, which reads an awkward *shape* as a damaged one. A
Crystal Koffing is solid on all nine of its frames, but the three that put its
gas plume out measure 0.51 empty against 0.26 for the other six — so a healthy
sprite crossed the line three times per animation cycle and the paper blinked
on and off behind it. What the paper is for is a window *through* the mon, so
that is what is measured now, and every frame of that Koffing scores 0.00 to
0.05 by it.

## 1.14.0

**Everything the suite can change is now one row on the game's own OPTION
screen**, nested in folder cards, and the other half of the suite's settings
are on it too.

Everything was reachable before this and almost none of it was findable. The
bundle deliberately put no row on the OPTION screen -- the reasoning was that a
mod's settings live under `MODS` -- so the Pokedex's own settings were at
`MODS > GEN1WILD UI > OPTIONS > POKEDEX`: three screens deep, behind a name
that is a repository rather than a thing, and with a fifty-fifty guess about
which half of the suite owned them. Installing both halves gave you two
separate lists to guess between.

### The door

One row on the `OPTION` screen, next to `MODS`. It is named after the cart when
a cart is running -- `WILD GREEN`, which is what was installed and what the
launcher calls it -- and after this bundle when one half is installed on its
own, where calling it `WILD GREEN` would be naming something that is not there.

Both halves add that row under one shared id, so the first one there wins and
the second finds it already present: one door, not two identical ones. The
`MODS > GEN1WILD UI > OPTIONS` route still lands on the same screens for anyone
who learned it.

### The cards

Behind the door are folder cards -- which is how the game's own OPTION screen
has nested since it grew `SPEED`, `VIDEO` and `AUDIO` pages. Each says how many
of its rows are on.

| Card | Rows |
| --- | --- |
| `OUT IN THE WORLD` | `ELEVATOR PANEL`, and Gen1WildQOL's `SPRINT`, `EASY HM USE`, `AREA BANNER` |
| `YOUR POKEMON` | `POKEDEX`, `POKEMON BOX`, `PARTY MENU`, and Gen1WildQOL's `FOLLOWERS`, `REMEMBER MOVES`, `ALL 151` |
| `BATTLES` | `BACKDROPS`, `BATTLE INTRO`, `BATTLE MENUS`, and Gen1WildQOL's `EXP SHARE`, `CAUGHT MARKER` |
| `ITEMS AND BAG` | `BAG`, `ITEM INFO` |
| `SAVING AND SOUND` | Gen1WildQOL's `AUTO SAVE`, `AUTO CONTINUE`, `SOUND` |
| `MOD SETUP` | `MENU LAYOUT`, `MOD MANAGER` |
| `OTHER MODS` | every other loaded mod that has settings |

Four rows fit on a screen, which is the point of the exercise: eleven features
flat was three screenfuls of scrolling to reach one row, and six cards is one
and a half with three or four rows behind each.

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

### `BACKDROPS` came forward

**Gen1Arena 0.20.2.** `MON PAPER` was turning pale battle sprites into a white
box. It reads a sprite's pixels by drawing it into a scratch canvas, and it was
doing that from inside the battle's own draw -- under the battle's transform,
its scissor and its scale -- so the sprite landed off the canvas entirely. What
came back was a nearly empty image, which passed both of the tests meant to
catch bad art: few enough colours to look like flat paper, and hollow enough to
look like line art. The read resets the transform and the scissor now, and its
tests model the battle transform so a read that forgets it fails there.

## 1.13.0

Three bundled mods come forward, two of them with bugs you could see.

- **`POKéDEX` to 1.5.2 — the starter you could not pick.** Oak's lab shows the
  dex entry for a starter *before* it asks whether you want it, and the script
  blocks until that screen closes itself. The entry's A key advanced DEX →
  STATS → MOVES and round to DEX again, forever, so a player pressing A at the
  CHARMANDER they had just been offered got a third page and then the first one
  back, and nothing ever asked them anything. A now walks the entry once and
  leaves it. The Safari Zone's signs and the S.S. Anne's Snorlax had the same
  problem.

  It also fixes a crash: the `AREA` map's cursor called a `moveGrid` on the
  engine's town map that no version of it has ever had, so the first d-pad
  press there took the game down. That feature had never worked.

- **`BACKDROPS` to 0.20.1 — some POKéMON went invisible in battle.** Gen 1 pics
  are matted by flooding white in from the edge of the image, and the flood
  stops only at ink, so wherever a POKéMON's own white reaches the edge it
  pours into the body and hollows it out. Against the white field that is
  invisible; against a backdrop it is a window, and a pale POKéMON — Mew's back
  pic keeps 145 of the 400 pixels in its own bounding box — read as a bare
  outline with the scenery showing through it. The new `MON PAPER` row lays the
  field shade back under any pic that actually lost something. A sprite mod's
  true-colour replacement art carries its own alpha and is left alone, so a
  Crystal front and a vanilla back in the same battle are each handled
  correctly.

  `DIAGNOSTIC` and `FIELD TEST` are developer-only rows now. They are
  maintenance tools, and the second paints the battlefield flat magenta with
  nothing on the row to say so.

- **`BAG` to 1.11.1 — the settings are in the game's voice.** `Opening
  Pocket`, `Hold Scroll Speed` and `Item Icons` were the only rows in the suite
  written in Title Case. They are capitals now, values with them, and the
  pocket names match the tabs they select. Display text only; no stored setting
  moves.

## 1.12.0

**A rule between the item icons and the names, and room either side of it.**

An icon sat flush against the first letter of the word beside it, which made
the picture read as part of the name rather than as its own column. There is a
tile of air between them now, with a one-pixel black rule down the middle of
it: three pixels clear of the icon, four clear of the word.

The rule is drawn a row at a time, the full height of a row, so consecutive
rows join into one continuous line and the line stops where the list does — a
mart shelf of two items gets two rows of rule, not a rule down an empty
half-screen. Every row gets one, `CANCEL` included: it divides two columns
rather than decorating an item, and a rule with gaps in it where a row happens
to have no picture reads as damage.

The mart's and the item PC's lists already had that tile — the icon sits at
x = 16 and the name at x = 40 — so there the rule is all that is new. `BAG`
follows Gen1ModernBag to 1.11.0, where the bag's window grows a second tile at
the left to make the same room: tiles 2,2–19,12 rather than 3,2–19,12, with the
cursor at x = 24, the icon from x = 32 and the rule at x = 51. It is still the
pop-up over the overworld it has always been, two tiles in from the screen edge
rather than four, and every column that predates the icons — the name, the
quantity, the more-arrow, the pocket name and the money — is still exactly
where it was.

Either `ITEM ICONS` off is still that screen as 1.10.4 drew it: no rule, no
icons.

---

## 1.11.1

**The item icons line up with the words now.**

A list row is sixteen pixels and so is an icon, so 1.11.0 drew each one at its
row's own y and filled the row exactly. But a row holds two lines — the item's
name on its top eight pixels and its price or count underneath — and a Gen 1
glyph inks rows 0 to 6 of its cell, so the name's ink was centred on `y + 3`
and the icon's on `y + 7.5`. Every item read as floating above its own picture.

What a reader pairs is the name and the icon, not the whole cell and the icon,
so the icon is centred on the name: four pixels up puts the two centres within
half a pixel of each other. Four rather than the exact five, because five
would put the mart list's top icon on the header box's bottom border.

Icons are still sixteen apart, so the column shifts as a whole and no two of
them come any closer together. `BAG` follows Gen1ModernBag to 1.10.1 for the
same fix in the bag's own window.

---

## 1.11.0

**Every item has a picture now — in the bag, at the mart, and in the item PC.**

Gen 1 shows a name and a number and nothing else. A POTION and a MAX POTION
are the same row twice; five evolution stones are five rows that differ by one
word; and a TM pocket is fifty-five rows that all read `TMnn`. The suite has
had a sentence for each of them since 1.5.0 — ITEM INFO's descriptions — and a
sentence tells you what a thing is once you have found it. A picture is what
finds it.

So every row in the two mart lists, the item PC's three, and the bag now
carries a 16x16 icon in the column left of its name. A machine carries a disc
in the colour of the type of the move it teaches — read off the move, not off a
table, so a mod that retunes what TM26 teaches recolours its disc with it.

The art is **Pokémon Polished Crystal's**, recolored from that project's own
palette data and scaled to the sixteen pixels a Gen 1 list row is high. It is
not this project's work. `modules/Gen1ItemInfo/CREDITS.md` says who it belongs
to, and says what they ask of anyone who ships it; the same file is in
Gen1ModernBag. Three icons in the set are not theirs: the TM and HM discs, the
LINK CABLE (their ESCAPE ROPE in red — Gen151 sells a cable and nothing
anywhere has drawn one, and a coiled rope is the shape a cable has), and the
GOLD TEETH.

**The mart's and the PC's rows put their number underneath.** An icon takes
two tile columns, and a name that starts after one has 112 pixels to the right
margin — which a `¥2100` and its clearance take fifty of, leaving eight glyphs
and cutting SUPER POTION in half. The price and the count drop to the row's
second line instead, which is where the game itself puts a number when a list
has an icon-sized gap on the left; it is what the bag has always done with a
quantity. Nothing on any of those five screens is truncated any more, which
was not true before the icons.

**The bag's window is one tile wider.** Same problem, different window: the
engine's item box has exactly one spare column, and spending it on a picture
would have cost every twelve-glyph name its last letter — `SUPER POTION`,
`HYPER POTION`, `FULL RESTORE`, `THUNDERSTONE`, `HELIX FOSSIL`, `BIKE VOUCHER`
and `OAK's PARCEL`, which is most of a starting bag. The window grows at the
left instead, tiles 3,2–19,12 rather than 4,2–19,12, and the cursor moves with
it. It is the same pop-up over the overworld it always was, two tiles in from
the screen edge rather than four, and the name column, the quantity column,
the more-arrow, the pocket name and the money have not moved a pixel.

**Two switches, both on.** `ITEM INFO > ITEM ICONS` is the mart's and the item
PC's; `BAG > ITEM ICONS` is the bag's, because the bag draws its own window
and a row under ITEM INFO could not reach it. Either one off is that screen
exactly as 1.10.4 drew it, on the next frame rather than the next boot.

An item may name its own icon: `data.items[id].icon`, if it is a string, is a
path and wins over the shipped set — the same shape `description` has, so a
sprite pack or a mod that adds an item can hand its art to every screen in the
suite without either mod being told. `ITEM INFO` publishes `icon` and
`drawIcon`, and `BAG` publishes `itemIcon` and `drawItemIcon`, for a sibling
with somewhere to put one.

`tools/make_item_icons.py` rebuilds the whole folder from a checkout of the
Polished Crystal pack, and is where the choice of which of their icons stands
for which Gen 1 item is written down. The SURFBOARD is the one placeholder:
nothing anywhere has ever drawn Gen 1's, so the script draws a board-shaped
thing in the set's own idiom — black outline, two shades, lit from the top
left — rather than borrowing an icon that means something else.

**BAG follows Gen1ModernBag to 1.10.0**, which is where the bag half of this
lives. It also fixes the money being printed twice: gen1recomp's item-box path
now opens the standard full-width text box under the window for any list
carrying a footer, and the bag parked the amount there while also drawing it
on the window's border — so the bag had grown back the box Gen1ModernBag 1.2.0
removed, with the same number in it.

---

## 1.10.4

**POKEDEX follows Gen1Dex to 1.5.1, and the overlay that stood in for it goes.**

1.10.3 carried the Pokédex crash fix as `overlays/Gen1Dex/list.lua`, laid over
a submodule pinned at 1.5.0 — because the fix belonged upstream and was not
there yet. It is there now: [Gen1Dex
1.5.1](https://github.com/wild1walker/Gen1Dex/releases/tag/v1.5.1) is the same
fix at its source, with the mod's own suite driving the real screen through the
cursor keys, SELECT, both ends of the wrap and a held key's repeat.

So the pin moves and the overlay is deleted in the same change, which is the
whole of its intended life. `modules/Gen1Dex/list.lua` is upstream's file again
and `tools/build.py --check` agrees; the only thing that reaches the game
differently is four lines of comment that said, from inside the bundle, that
the crash was not a bundle question.

`overlays/` is empty now and the mechanism stays documented in
`tools/build.py`, for the next tracked mod that needs a fix before its own
release carries one.

Nothing about the feature changes. A player on 1.10.3 already had the fix.

## 1.10.3

**The POKEDEX crashed the moment the cursor moved.**

`src/ui/PokedexMenu.lua:116: attempt to call method 'rows' (a number value)`,
in the engine's own `syncScroll`, on the first press of UP or DOWN after the
list came up.

The vanilla dex was a `ListMenu` until gen1recomp rewrote it as a screen of
its own, and the two shapes disagree about the one field this feature has
always written. A `ListMenu` carries `rows` as a number — this list wants six
where vanilla shows seven, because the header and footer boxes took a tile row
each end — and the screen that replaced it carries `rows()` as a method its
own scroll clamp calls. Writing the six over the method left the engine
calling a number.

Which shape the engine has is now asked once, and the six rows are handed over
the way that shape asks for them. Nothing about the screen changes on a build
that still has the list.

It was never a bundle question. Installing GEN1WILD UI without GEN1WILD QOL is
where it happened to be found, but the two halves have nothing to do with this
one: the dex is carried here alone, the other half never touches
`PokedexMenu`, and the standalone
[Gen1Dex](https://github.com/wild1walker/Gen1Dex) hits it the same way. The
suite's halves stand alone, and this was the engine moving underneath all
three of them at once.

### Three settings that had gone quiet with it

The same rewrite took `wrap`, `keyRepeat` and `onSelectKey` with it — they
were `ListMenu` opts, and the screen's own update reads none of them. So
SELECT VIEWS, LIST WRAPS and HOLD TO SCROLL were three rows on the menu that
did nothing, and LEFT/RIGHT paged by the engine's seven over a list showing
six, stepping past an entry each press and never reaching the last one.

All four are answered again, as a layer over the engine's update rather than a
replacement for it: A, B and the side menu never reach it, and every key it
does take is one the engine leaves unbound here or one whose press it would
have spent doing nothing.

### How it is carried

`overlays/Gen1Dex/list.lua`, laid over the pinned submodule on the way into
`modules/` by `tools/build.py`. The fix belongs upstream and should land
there; until it does, an overlay is what keeps this bundle from shipping a
Pokédex that crashes, without editing a submodule this repository does not
own. The next sync that carries the upstream fix should delete it.

`tests/dexlist_test.lua` stands both shapes of the engine screen up headless —
the screen's `rows`/`syncScroll`/`pageScroll`/`update` arithmetic copied
rather than approximated — and drives the list through them. It fails with
exactly the reported error against the code this release fixes.

## 1.10.2

**The lift panel loses its FLOOR header.**

It earned nothing. A box of floor numbers that opens when you read a lift's
button plate, in a lift, is not ambiguous — the word only ever said what the
rows already said, and it was the most expensive thing on the box: it set the
width (nine tiles rather than the six the floors need), and it needed a run of
the top rule knocked out to make room for itself.

Without it the panel is as wide as its widest floor and no wider, which is
what a panel against the edge of the screen should be. Nothing else moves:
same two-tile row pitch, same blank row under the top border, same place
against the right edge, same scrolling for SILPH CO.

`tests/iteminfo_test.lua` now draws the panel rather than only measuring it —
a stub `love.graphics` and a recording `Font`, then assertions on what
actually reached the screen: one box, six tiles wide, five floors printed and
nothing else, sixteen pixels apart, with the cursor a column left of the
labels. It is the guard for the header coming back and for the row pitch
collapsing again, both of which the code believed it had right until someone
looked at it.

## 1.10.1

Three fixes to what 1.10.0 shipped, all found by looking at the screen.

### The lift panel was spaced wrong

Three separate mistakes, all of them the same mistake: it was drawn to a
layout of its own instead of to `src/ui/Menu.lua`'s, which is what every
boxed choice in this game is drawn by.

- **Rows were one tile apart**, not two. Nothing else in the game is spaced
  that way, and it read as a list that had been squashed to fit.
- **Choices ran from the top**, so the slack fell at the bottom. Gen 1
  anchors them to the last interior row and lets the blank row fall under the
  top border — that blank row is what keeps the first choice off the title.
- **The FLOOR label knocked out the whole top rule.** The knock-out was padded
  by a tile at each end, which is right for a sixteen-tile pocket header and,
  in a box this narrow, erased everything between the corners — leaving FLOOR
  floating between two ornaments with no frame attached to it.

The box is now sized so the word keeps a column of rule on each side of it,
and the knock-out is exactly the glyphs, the way `Menu` titles its own box.
Every floor still fits without scrolling anywhere but SILPH CO.

### The LINK CABLE had no description

It is [Gen151](https://github.com/wild1walker/Gen151)'s, registered from
Gen1WildQOL, so nothing in this bundle's table had a line for it — and it
sits on the Celadon 4F shelf beside the four stones, every one of which
explains itself. A row whose neighbours all speak and it does not looks
broken.

It is described here now. Safe either way: only ids the game actually has are
described, and Gen1WildQOL loads first, so the cable is either registered by
then or was never going to be.

### The item PC printed the menu underneath it

`WITHDRAW / DEPOSIT / TOSS / LOG OFF` is pushed **over** the Pokémon Center's
own PC menu, which stays on the stack so `B` comes back to it — and, being a
menu rather than a screen, kept drawing. Both boxes start in the same corner
and are the same width, so for as long as they were the same height nobody
saw it.

They are not the same height. The PC menu sizes itself to its rows and grows
one for `PROF.OAK's PC`, another for `<PK><MN>LEAGUE` once there is a HALL OF
FAME to read, and another for anything `MENU LAYOUT` pins there, while the
item PC's box is a fixed ten tiles. Past four rows the menu underneath
printed its last rows out from under the box on top of it, with a second
bottom border under those: a `LOG OFF` row below a `LOG OFF` row.

The covered menu is now hidden rather than drawn over, through the engine's
own `screen.render_visible`. It keeps its place on the stack and its place in
the `B` chain and comes back the moment the item PC closes — and because
nothing is painted over it, the overworld still shows around the box. The
bedroom PC, which opens with no menu under it at all, is untouched.

This one predates 1.10.0; it is what the PC has always done. It is fixed here
because ITEM INFO is what owns those screens now.

## 1.10.0

**Every item says what it is now**, and four screens that had nowhere to say it
are redrawn.

Two new features, both maintained here rather than tracked:

- **ITEM INFO** — a description for every item in the game, on the item
  itself. The mart's BUY and SELL lists carry it in the clerk's box, following
  the cursor, which is what finally replaces *Take your time.* The item PC's
  WITHDRAW, DEPOSIT and TOSS lists carry it in the same box. And the bag's item
  menu grows an **ABOUT** row that prints it.
- **ELEVATOR PANEL** — the lift's `WHICH FLOOR?` full-screen list becomes a
  small panel against the right edge with every floor on it at once, and the
  car you are standing in stays on the screen behind it.

Both ship on and both switch off live, with no relaunch.

### Where the descriptions live

On `data.items[id].description` — the field Gen 2's own extractor writes for
Gold and Crystal, under the name it writes it under. So this is not a private
table only ITEM INFO can read: anything that wants to show an item description
reads it off the item the way it would on a Gen 2 cart, whether or not this
bundle is the thing that put it there. Item records are extensible by design,
so nothing is taken away — an item gains a field and keeps every one it had.

Eighty-one are written by hand, two lines and eighteen glyphs each, which is
what a Gen 1 text box holds. The fifty-five machines are described from the
move they carry rather than by hand, so a mod that retunes what TM26 teaches
does not leave a description lying. `tests/iteminfo_test.lua` holds the line
budget: a description that would wrap to a third line is a failing build, not
a truncated sentence, because the box shows the last two lines of what it is
given and a third line would eat the first one silently.

### The chrome

The four lists get the frame the rest of the suite uses: a header box with the
title in it (and the money at a mart, where the vanilla screen floats a
separate box in the corner), the rows ruled to the same margins Gen1Dex and
Gen1Party keep, a mark at each end when there is more above or below, and the
game's own text box along the bottom.

Nothing about how any of them *works* changed. Each list is built exactly as
the engine builds it and then has `draw` and `update` swapped; the input, the
scrolling, the quantity selector, the yes/no confirm, what a purchase costs
and what a toss refuses are all the engine's own code, untouched. The mart's
BUY / SELL / QUIT counter keeps the shop showing around it, because that
screen was never opaque and seeing the room you are standing in is the best
thing about it.

## 1.9.0

The status tint is removed from the party list and the box, at the author's
request, along with the rest of the status colour work across the suite.

- **PARTY MENU** → [Gen1Party](https://github.com/wild1walker/Gen1Party) 1.7.0
- **POKEMON BOX** → [Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox)
  1.5.0

Icons draw as they always did and the palette zone under them is the species
colours again. Both mods' source is byte-identical to the release before the
tint went in, so nothing else moved with it.

`mod.publish` is gone from this bundle's runtime too. It was added for the
feature that is being removed, it never had another caller here, and the two
bundles keep their runtime byte-identical.

## 1.8.1

The status tint on a POKéMON reaches **full-colour icon art** now, in the party
list and the box.

- **PARTY MENU** → [Gen1Party](https://github.com/wild1walker/Gen1Party) 1.6.0
- **POKEMON BOX** → [Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox)
  1.4.0

It rode a palette zone, and a palette zone only reaches art that goes through
the shade-remap pass -- which full-colour art sits out **by design**, since both
mods mark their icon rect trueColor precisely so the pass does not repaint it
off its red channel. So the tint coloured nothing at all for anyone running a
full-colour icon pack. The icon is now drawn in the condition's colour as well,
which reaches both kinds of art.

The colour comes from `drawColour` in **STATUS COLOURS**
([Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL) 1.8.0), so the party,
the box and the overworld keep agreeing. **Without Gen1WildQOL 1.8.0 or later
installed there is no tint**, exactly as before.

## 1.8.0

A POKéMON in the party list or the box wears its condition: poisoned is purple,
fainted is grey, and the rest of the statuses have their own colour -- over the
species colours those cells already wear, so a poisoned CHARMANDER still reads
as a CHARMANDER.

- **PARTY MENU** → [Gen1Party](https://github.com/wild1walker/Gen1Party) 1.5.0
- **POKEMON BOX** →
  [Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox) 1.3.0, on the
  grid and on the party column beside it

The colours are not defined in either. They come from **STATUS COLOURS**, the
feature in [Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL) 1.7.0 that
turns the overworld purple while you walk poisoned, and which owns one table of
what each condition looks like so these two and the stats page agree instead of
drifting apart. Both ask it; **without Gen1WildQOL installed there is no tint**
and the cells are the species colours exactly as before.

It rides the per-POKéMON zone each screen already builds, so it costs nothing
extra to draw, and full-colour art still sits out the pass untouched.

The Pokédex is deliberately not in that list: a dex entry is a page about a
*species*, so there is no condition there to show.

## 1.7.0

**This bundle no longer puts a row on the game's OPTION screen.** Its settings
live where a mod's settings live: `MODS` > `Gen1WildUI` > `OPTIONS`, which lands
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

## 1.6.4

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

## 1.6.3

Follows [Gen1BattleUI](https://github.com/wild1walker/Gen1BattleUI) to 1.5.2,
which fixes a bug that only appears when **both bundles are installed**.

- **The level-up stat box came up over a blank text box again if
  [Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL)'s `EXP SHARE` was
  on** — the exact picture 1.4.0 of that mod was written to fix, back for
  anyone running the pair. It was a hook priority rather than the retiming.
  `EXP SHARE` wraps `battle.exp_award` at priority 90 and, in every mode but
  `OFF`, awards the exp itself and returns *without calling through*. The
  engine runs the highest-priority link outermost, so `BATTLE MENUS` sat inside
  it and never ran: the rows were queued exactly as vanilla queues them and
  never re-marked, which is the engine's own two screens — the line prompts, it
  clears, and the stat box arrives over an empty box.
- `BATTLE MENUS` is now the outermost link on that hook. It has to be: it calls
  through and then *reads* what the chain queued, and an inner link cannot read
  a queue built by an outer one that never called through. It costs `EXP SHARE`
  nothing — the award is still theirs, through the engine's own `applyShare`,
  so the rows are the same rows and the retiming finds them.
- A miss no longer fails silently: it logs how many level-up lines were joined,
  how many were expected, and the text it could not match. "Reached and found
  nothing" and "never reached at all" produced the same blank box and neither
  said which.

## 1.6.2

Follows [Gen1BattleUI](https://github.com/wild1walker/Gen1BattleUI) to 1.5.1,
which drops the `gen1_wild_ui` entry from its own `optional_dependencies` —
an optional dependency on this bundle that could never be satisfied, since
this bundle carries that mod as `BATTLE MENUS` and lists it in `conflicts`,
so the engine will not have both installed for it to resolve against.

No module content changed: the rebuild is byte-identical and the whole diff is
the pin and the version map `mod.find` hands out. Nothing in the menu moved.

## 1.6.1

Adds the `LICENSE` this repository never had. Every standalone mod in the suite
ships one and both bundles did not, while the index entry claimed MIT on their
behalf -- so the claim is now in the repository making it, and in the zip.

It is scoped rather than blanket: MIT over the bundling -- the loader, the
feature registry, the runtime, the adapters, the tools, the suites -- and no
claim at all over the mods carried under `modules/`, each of which keeps its
own licence file where the build put it. `BATTLE INTRO` is maintained here and
its original states no terms, so the file says that plainly and leaves them to
its author rather than assigning any.

No code changed.

## 1.6.0

Follows one of its mods; everything else here is already on its newest release.
Its three new rows appear in the menu on their own — the bundle reads every
feature's schema at load — so nothing here needed the edit. No key was renamed
or removed.

- **BATTLE MENUS** → [Gen1BattleUI](https://github.com/wild1walker/Gen1BattleUI)
  1.5.0. **The ball you throw is coloured as itself.** Under `COLORS =
  ADVANCED` every battle sprite took its colour from the SGB zone underneath
  it, so a GREAT BALL and an ULTRA BALL came out the same colour as each other
  and as the grass behind them. The toss, the wobbles and the ball resting
  through the caught text are now each ball's own — red, blue, gold, purple,
  olive — and the Pokémon Center's heal machine lights each ball in the colours
  of the ball that POKéMON was *caught* in rather than painting all six the
  same. The mono colour modes have no per-sprite colour to give and are passed
  straight through, so this is off in them whatever the rows say.
  New rows: `BALL COLOUR`, `BALL BAND` and `CENTER BALLS`, all on.

### Worth knowing before you turn CENTER BALLS on

It is the one thing in either bundle that writes to your save. Gen 1 records
nothing about what caught a POKéMON — the party struct has no ball in it, and
neither does Gen 2's — so the machine can only be told by a field the mod
invents: `mon.caughtBall`, written onto the POKéMON at catch time, only when
that field is empty and never over a value already there. It goes where the
POKéMON goes, through the box and through a trade, and it stays in the save
after an uninstall. It maps to no byte in the real Gen 1 format, so an export
to a `.sav` drops it and a round trip lights every ball red until the party
turns over. Anything caught before this installed heals as a POKE BALL.

Only-if-absent is the rule Pokeball Colors set for that field, which the
feature is ported from and can share a save with.

## 1.5.0

Follows one of its mods; everything else here is already on its newest release.
The new row appears in the menu on its own — the bundle reads every feature's
schema at load — so nothing here needed the edit. No key was renamed or removed.

- **PARTY MENU** → [Gen1Party](https://github.com/wild1walker/Gen1Party) 1.4.0.
  The popup's `SWITCH` becomes `MOVE`, and moving a POKéMON is the box's answer
  rather than the engine's: A lifts the member the cursor is on, it flashes,
  and UP and DOWN carry it through the list a row at a time with the party
  reordered under it as it goes. A lets go; B walks it home. A run of steps is
  an insertion, not an exchange — carry the fourth member to the top and the
  three it passed keep the order they had. The *battle* popup's `SWITCH` is
  left alone: there it means *send this one out*. New row: `MOVE NOT SWITCH`,
  on — off restores the engine's two picks and one exchange exactly.

## 1.4.0

Follows two of its mods; everything else here is already on its newest release.
Each brings one new row, and each appears in the menu on its own — the bundle
reads every feature's schema at load, so an upstream that adds an option needs
no change here. No key was renamed or removed.

- **BATTLE MENUS** → [Gen1BattleUI](https://github.com/wild1walker/Gen1BattleUI)
  1.4.0. The level-up stat box no longer comes up over a blank chat box: the
  line announcing the level was being dismissed and cleared before the window
  was pushed, so the second screen had nothing on it saying what the numbers
  belonged to. New row: `LEVEL-UP BOX`, on.
- **POKEDEX** → [Gen1Dex](https://github.com/wild1walker/Gen1Dex) 1.5.0. A new
  catch asks for its nickname over the dex entry rather than over a blank white
  screen. New row: `NAME IN PLACE`, on.

## 1.3.0

Follows [Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox) to **1.2.0**
(from 1.1.1). Everything else here is already on its newest release.

1.2.0 publishes an `actions` provider registry on the box popup, which is what
lets another mod hang a row there. `REMEMBER MOVES`, over in
[Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL) 1.4.0, is the first
thing to use it — so its `BOX REMEMBER` row needs this version of this bundle.

### Fixed

- **`mod.find` handed back the wrong shape, and cross-mod integrations went
  quietly dead.** The engine's own returns a handle — `{ id, version, exports }`
  — and mods read it that way. The bundle's registry answered with the exports
  table itself, so `box.exports` was nil and the integration simply did nothing
  rather than failing. Handles now match the engine's, `tools/build.py` writes
  the version map they carry, and the shape is pinned by a test.
- `tools/check.py` crashed instead of reporting when a Lua file's bytecode
  listing carried a non-UTF-8 byte.

## 1.2.5

**BATTLE MENUS** (Gen1BattleUI 1.2.2 → 1.3.0) — the **XP bar moves into this
bundle**, from Gen1WildQOL. It is a battle UI feature and this is the battle
UI half, and the move is what finally stops the bar lying across the move
panel: over there it was drawn by a wrapper around `battle.draw`, which runs
after every `battle.overlay` link whatever priority they carry, so it could
not be drawn over and clipped itself to `x=88` — where the *vanilla* panel
ends, while Gen1BattleUI's ends at 112. Now the bar and the grid are drawn by
one function, bar first, so the panel covers it and keeps covering it if its
width ever changes. Its row is `XP BAR`, on, under `BATTLE MENUS`.

**Update Gen1WildQOL to 1.3.0 alongside this.** That is the release that drops
its own copy; run 1.2.x of it with this and both bars draw, with the old one
back on top of the panel.

Also from that release: `panelRect` is published for anything that draws after
the battle menus and must not be drawn over, and the mod's published tile
geometry is now the table its drawing actually reads rather than a stale copy
of it.

## 1.2.4

**BATTLE MENUS** (Gen1BattleUI 1.2.1 → 1.2.2) — the type colour is in the
letters now instead of on a chip behind them, and the move names on the
buttons are coloured by their own type as well, so the grid reads as four
types at a glance and the panel says which one the cursor is on. A tile glyph
is black on transparent and `setColor` cannot reach one; a shader throws each
glyph's RGB away and keeps only its alpha, which turns the glyph into a
stencil to fill with the type's colour — the game's own font throughout, in a
different ink. The palette is darker than the familiar type colours because
these are letters on a white box rather than a field behind them. `TYPE
COLOUR` turns it off, and a host with no shaders draws them black.

## 1.2.3

**BATTLE MENUS** (Gen1BattleUI 1.2.0 → 1.2.1) — the move panel reads the name
whole again and is three rows: name, type, PP. Fourteen tiles wide, which is
the narrowest that never cuts a Gen 1 move name, and 48 pixels short of the
full width it used to run to. The EXP bar no longer lies across it: the
overlay hook now carries a priority that draws this mod's layer last. The
move's type sits on a chip in that type's own colour, and `FULL NAMES`
defaults off, so the buttons are the game's own font as before.

## 1.2.2

**BAG** (Gen1ModernBag 1.9.3 → 1.9.4) — `Hold Scroll Speed` now defaults to
`OFF`. 1.2.1 moved it from `FAST` to `NORMAL`, which halved the rate and kept
the thing that made it feel wrong: a threshold. A press either crosses it or
does not, so the same press is one row or a run of them depending on how long
a finger rests — which reads as the list moving by itself rather than as a
speed being too high. `OFF` means a press is a row; the three speeds are all
still there.

**BATTLE MENUS** (Gen1BattleUI 1.1.2 → 1.2.0) — move names print whole. The
tile font is 8 pixels a glyph and a classic cell is seven of them, against
Gen 1's twelve-glyph names, so a move menu that will not fit is drawn in Plain
Pixel — the TTF the engine already ships for its translation mode — at the
largest size whose twelve glyphs still fit the cell. A grid takes it for all
four names or none, so a party whose names all fit is unchanged, and the wide
layout never reaches for it. `FULL NAMES` turns it off.

## 1.2.1

Follows two upstream fixes, both to things a player hits in a battle.

**BAG** (Gen1ModernBag 1.9.2 → 1.9.3) — `Hold Scroll Speed` defaults to
`NORMAL` rather than `FAST`. `FAST` starts repeating after 10 frames held and
then moves a row every 2, so a press about a sixth of a second long stopped
being one step and became thirty rows a second; whether a press crossed that
threshold was a matter of how long a finger rested, which is why it read as
the Bag scrolling by itself. `NORMAL` is Gen1Recomp's own `ListMenu` cadence.
A saved choice is untouched — this moves only players who never set one.

**BATTLE MENUS** (Gen1BattleUI 1.1.0 → 1.1.1) — the move panel no longer
covers the player's own HP. It was drawn twenty tiles wide across rows 8–11,
and `DrawPlayerHUDAndHPBar` puts the name, level, HP bar, HP numbers and
underline across rows 7–11 from x=72 rightwards. It now keeps the footprint of
the vanilla `TYPE/PP` box it stands in for, which is also what keeps anything
else drawn on that side of the screen clear of it.

## 1.2.0

Adds **BATTLE MENUS**, from
[Gen1BattleUI](https://github.com/wild1walker/Gen1BattleUI) — the battle command
and move menus as four buttons in a 2x2 grid instead of a list. Tracked as a
submodule pinned to 1.1.0, like the other seven Wild mods here. It ships on.

It was the one mod in the index that was in neither bundle, which is why
installing it alongside Gen1WildUI raised no conflict: there was nothing to
conflict with. Now that the bundle carries it, `Gen1BattleUI` is in the
manifest's `conflicts` and the two are mutually exclusive, the same way the
other eight features are.

| Row | Ships |
|---|---|
| `MOVE PANEL` — the highlighted move's full name, type and PP above the grid | on |

`BATTLE MENUS` takes a relaunch to switch. The mod has no off switch of its own
to donate — `MOVE PANEL` is a setting within the grid, not a switch for it — so
the bundle gates it at load and the menu marks the row.

## 1.1.0

Adds **BATTLE INTRO**, from
[gen1recomp-widescreen-battle-intro](https://github.com/ShaneMcGovernIE/gen1recomp-widescreen-battle-intro)
by ShaneMcGovernIE — maintained in this repository from here on, like the two
in Gen1WildQOL. It ships on.

The battle intro's flash plays across the whole window instead of inside a
centred 4:3 square, and the out-of-battle poison pulse with it. Two settings
come with it, on the bundle's own screen rather than the engine's OPTIONS
screen:

| Row | Ships |
|---|---|
| `FLASHLESS INTROS` — every battle opens on the Champion fight's outward spiral | off |
| `BLACK OUTRO` — a battle ends on a slow fade to black instead of the white flash | on |

Both are the mod's own defaults, unchanged.

## 1.0.0

First release. The visual half of the Gen1Wild index, consolidated into one
installable mod.

### Features

Each of these is a row in `OPTION > GEN1WILD UI`, switched on or off by
itself, with its own settings one press of A away:

| Feature | From | Ships |
|---|---|---|
| BACKDROPS | [Gen1Arena](https://github.com/wild1walker/Gen1Arena) | on |
| POKEDEX | [Gen1Dex](https://github.com/wild1walker/Gen1Dex) | on |
| POKEMON BOX | [Gen1BillsBox](https://github.com/wild1walker/Gen1BillsBox) | on |
| PARTY MENU | [Gen1Party](https://github.com/wild1walker/Gen1Party) | on |
| BAG | [Gen1ModernBag](https://github.com/wild1walker/Gen1ModernBag) | on |
| MENU LAYOUT † | [Gen1MenuManager](https://github.com/wild1walker/Gen1MenuManager) | on |
| MOD MANAGER † | [Gen1ModMenu](https://github.com/wild1walker/Gen1ModMenu) | on |

† Carried by Gen1WildQOL as well. With both bundles installed exactly one sets
it up, and its settings live under a shared id so they do not move when the
other bundle is the one that wins.

### Notes

- Nothing here changes what any of these mods do. The source is vendored
  unmodified from each mod's own repository and re-read on every sync.
- `POKEDEX` and `POKEMON BOX` are registered before `PARTY MENU`, which reads
  both when they are present — the same order they resolve in when installed
  separately.
- `MOD MANAGER` sets three of its own rows through the engine's mod manager,
  which writes them unprefixed. The runtime keeps both spellings in step so
  those rows behave the same whether they are set from its quick menu or from
  this bundle's.
- Features in this bundle can still be found by features in
  [Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL): `Gen151` hangs
  catch hints off `Gen1Dex`, and that lookup crosses the split.
