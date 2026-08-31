# Changelog

This is the **nightly** fork of [Gen1WildUI][stable]. Its versions are the
nightly channel's, not the stable bundle's; `1.21.0` below is where the fork
was taken from.

[stable]: https://github.com/wild1walker/Gen1WildUI

## [0.31.10] - 2026-08-31

### Fixed

- **The white bar across the copyright, and the black one before it, were the
  same bug.** The title's copyright row was left white on the canvas and
  turned over in the palette, so the strip read black with white letters. It
  did — until the true-colour rect over the mon reached it. The engine rounds
  a `colors == false` scissor **outward**, that rect re-blits the canvas
  **raw**, and raw at row 136 was the white paper: a white bar under the mon
  and under the figure both. Painting the row black to hide it is the other
  report — a black bar through the words — and clipping the ring so it paints
  nothing there just lets the white through again. There is no third answer
  while raw and shaded disagree about that row.

  So they are made to agree. The ground is painted black **all the way down**,
  the copyright art is inverted so its letters are light on it, and the strip
  carries the plain greys — the identity palette, where what the shader
  writes is what the canvas already holds. Raw and shaded are the same pixels,
  and the spill has nothing left to show.

- **The trainer lost his colour.** 0.31.8 baked the pad from
  `state.playerPath` — a *path* — and installed the result. On this cart the
  figure is not the file at that path: Wild Green swaps `state.player` for its
  green derived copy from a wrapper outside this one, and Crystal Animated
  Sprites does the same for the mon. Baking the path put the red figure back
  over the green one.

  The pad is now baked from the **picture**, whoever put it there. LÖVE 11
  does not keep an `Image`'s `ImageData`, so it comes back off the GPU: the
  image is drawn to a canvas of its own size under `"replace"` — which writes
  source RGBA instead of blending it — and that canvas is read. Once per
  image, cached weakly, with the canvas, shader, blend mode, colour, scissor
  and transform all put back.

- **The POKe BALL had no pad.** Its eight-by-eight cell sits at (0,16) in the
  gap the trainer's middle slice leaves, and every pixel around it inside the
  sheet belongs to the trainer — so a pad baked in place had nowhere to grow.
  The cell is now cut into an image a pixel larger on every side, stickered
  there, and substituted for that one draw at `(x - 1, y - 1)` so it lands
  exactly where the bare ball would have.

  `tests/titleart_test.lua` is 26 (was 9), driving the readback through a
  headless canvas: a coloured figure keeping its colour through the bake, the
  ball's pad growing outside the cell it was cut from and being drawn a pixel
  up and left, and the copyright turning over. `tests/matte_test.lua` is 47,
  holding the single black fill.

## [0.31.9] - 2026-08-31

### Fixed

- **INSPECT never said there was more of the list below.** Six rows fill the
  box's interior exactly, so a location with a seventh species showed six and
  nothing else — a player counted them and took that for the whole of ROUTE 7.

  The marker is the engine's own `Theme.moreArrow` (`$EE`), drawn while
  `top + 6` is still short of the end. It cannot go on the line under the last
  row the way the item list's and the option screen's do, because there is no
  such line here; it goes where the engine puts a continuation arrow in a
  twenty-tile box instead — x 144, four pixels up into the bottom border — 
  which is clear of the last row's caught ball (136..143) and of the right
  border (152 on). Down only and not blinking: vanilla has no "more above"
  glyph, and a blinking arrow belongs to a text box, not a menu.

  `tests/inspect_test.lua` is 59 (was 52), holding the arrow's absence on a
  list that fits, its presence on one that does not, its two coordinates, and
  its going again once the last row is on screen.

## [0.31.8] - 2026-08-31

### Fixed

- **The skirt was painting over the copyright line.** The title screen is
  black to row 135 and white from 136 — that strip is the one thing left light
  on purpose. The mon is drawn at `y = 136 - h` and the figure's box ends on
  the same line, so the bottom bar of both their rings landed exactly on row
  136: a black bar straight through the copyright, and an `ART_PAGE` zone over
  it mapping that row's ink to black as well.

  Both halves of the skirt now stop at a clip row. `matte.lua` names it while
  it paints the dark ground; the ring and the zone are clipped to it; and it is
  taken with the rects at `render.zones`, so it is one frame's fact and no
  other screen carries it — everywhere else the page is dark all the way down
  and a ring at the bottom of it is exactly what is wanted.

### Changed

- **The POKeMON logo has white in it again, and so do the figure and the
  mon.** 0.31.2 keyed the paper that was *connected to the border* and kept
  every enclosed pixel, on the theory that a highlight inside a letter is not
  reachable from the edge. For this logo that theory is simply false: POKeMON
  is grey letter faces inside a black outline on white, and of its 4381
  near-white pixels **every single one** is border-connected. The flood took
  all of them. The logo had no white to keep.

  What was asked for by name is the item icons' treatment, and the icons do
  not key paper — they **grow** it. `Gen1ModernBag/icons.lua` dilates the line
  work by a pixel, floods the outside of the grown shape, and paints whatever
  the flood could not reach opaque white: paper of the art's own *shape*, a
  sticker rather than a box. The same three steps now run on the title's art,
  and the only thing that differs per image is what counts as line work — the
  logo is printed *on* paper, so its ink is what is not paper; the figure and
  the mon are sprites on transparency, so their ink is every opaque pixel and
  the pad is a one-pixel outline.

  The figure is a sheet drawn in pieces — three full-width slices with the
  POKe BALL tucked into the gap at (0,16) — so the bake runs once per quad,
  read off the quads the state built. A halo grown across the whole sheet
  would put a pixel of the trainer's edge on the ball, and land it on screen
  nowhere near him. The mon has no field to swap at all (it is cached per
  species behind `currentSprite`), so the wrapper goes on that call and bakes
  the file it resolves, once per species.

  The **ribbon is deliberately not stickered**. The logo is one connected mass
  of line work, so a pixel of pad round it is an outline — 417 white pixels on
  a 128x56 sheet. The ribbon is eight pixels of letters with a pixel between
  them: pad every letter and the pads meet, and what comes out is a white
  plate with words on it, which is the white box behind WILD GREEN VERSION
  this whole line of work started from. Its paper goes, all of it, counters
  included.

  `tests/titleart_test.lua` is new: 9 assertions driving the bake through a
  headless `love.image` — the logo's face keeping its white while the field
  goes, the ribbon losing its paper outright, the figure outlined per quad,
  OG RED left with the figure it always had (that mode rebuilds the image from
  `playerPath` through the OBP tables and never reads the field), and the mon
  reached through `currentSprite` only while the ground is dark.
  `tests/titlepage_test.lua` is 73 (was 66), holding the clip.

## [0.31.7] - 2026-08-31

### Fixed

- **The skirt was cutting through the title art.** A black box appeared round
  the player and the ball, eating the POKeMON behind them — the guard against
  the hairline doing far more damage than the hairline ever did.

  One piece of art is not always one rectangle. `TitleState`'s
  `markVisibleTrueColor` splits the mon's mark around the player standing in
  front of it — a strip above, a strip below, a strip each side — because the
  player's own art must not be re-blitted with the mon's. A strip can be two
  pixels tall, and a one-pixel ring on both sides of a two-pixel strip is not
  a hairline guard, it is a black bar through the middle of a POKeMON.

  Each bar of the ring is now drawn minus every **other** marked rect on the
  frame. Adjacent rects touch without overlapping, so a ring pixel on a shared
  edge lies inside its neighbour and is skipped; what survives is the outside
  of the union — which is the only boundary the engine's outward scissor
  rounding can spill across in the first place.

## [0.31.6] - 2026-08-31

### Fixed

- **The hairline under the title figure, properly this time.** 0.31.2 put the
  skirt and its zone in the same place; this is the other half. Wild Green
  marks the figure **before** calling `TitleState:draw`, because that draw
  reads `self.player` at its top and the mark has to name a rectangle the art
  is about to land in — and the draw **opens with a full-screen fill**, which
  wipes the skirt that mark just painted a line later.

  That is why the figure kept its line and the mon, whose mark is emitted from
  inside the draw, did not. The rings are laid down again once the screen has
  finished, which is safe by construction: a ring is entirely outside the
  rectangle its art occupies, so a second coat cannot touch the art.

- **The version ribbon came out speckled with white.** Keying only the paper
  *reachable from the border* is right for the logo, whose enclosed white is a
  highlight inside a letter. The ribbon has no highlights — it is green
  letters with a black outline on a white field — so the white shut inside an
  `e` or an `o` is paper the flood cannot reach, and it turned into a scatter
  of specks the moment colour 0 stopped being pinned. The ribbon keys every
  near-white pixel now; the logo still floods from the edge.

## [0.31.5] - 2026-08-31

### Fixed

- **The AREA map's header still named the POKeMON.** `CHARIZARD UNKNOWN`
  across the top of Kanto, on a screen whose caption is carefully saying only
  `EVOLVE CHARMELEON AT LV36` — the rest of it names nothing you have not got,
  and the header handed over the answer.

  That screen is reachable for a species the dex has never met by two roads:
  the AREA ON UNSEEN row, and an evolution the entry screen is showing. Both
  print the header, so masking one road would have left the other.

  The token and the predicate now live in the dex's shared chrome — one
  `?????`, one "have I met this", used by the AREA header and by the INSPECT
  list that opens it. Owning counts as meeting even when the seen flag is
  missing: the dex sets both, an older save may carry one, and a POKeMON in
  the box is one you have stood in front of. New suite
  `tests/dexmask_test.lua`.

## [0.31.4] - 2026-08-31

### Fixed

- **The INSPECT list's last row was drawn on the box's border.** `Font.drawBox`
  spends its first and last tile row on the frame, so the interior is y 48 to
  135. Six rows at a sixteen-pixel step fit that exactly — but they started at
  56, which put the sixth at 136. That is the border, and the sixth name came
  out sliced in half.

  They start at 48 now, which is the first interior line, and the six fit with
  nothing left over. The geometry is named rather than written into the draw,
  and `tests/inspect_test.lua` asserts both halves of it: the last row ends
  inside the interior, and one more row would not — so the box is neither
  overflowing nor being wasted. That is arithmetic, and it should never have
  needed a screenshot to answer.

## [0.31.3] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.2] - 2026-08-31

### Fixed

- **The hairline came back along the bottom edge of the title sprites**, and
  it was mine. 0.30.4's skirt has two halves — the black paint round the art,
  and the zone that maps black to black — and they were living in different
  places. Both bundles carry `theme.lua`; the wrapper marks `PaletteFX` so the
  second copy does not wrap the wrapper, so the copy that *paints* is whichever
  loaded first while the copy that *emits the zone* is whichever won the
  theme's claim. When those differ, the paint lands and the zone never does:
  black skirt under a palette that maps black to the page's **ink**.

  Invisible almost everywhere, because a dark page's ink is where the art
  already sits. It showed in exactly one place — the title screen's copyright
  row, the one strip deliberately left light — as a white line under the mon
  and the figure. The rects live on the shared table the wrapper already marks
  now, so either copy reads what either copy wrote.

- **The POKeMON logo has its white back.** Pinning colour 0 to black took the
  field off the logo and the ribbon, which is what a black ground needs, and
  took the white out of the **art** with it: the paper the logo is printed on
  and the highlights inside its letters are the same shade, and no palette can
  tell them apart.

  The art can. This is the item icons' trick: key the paper that is
  **connected to the border** out to transparency and leave every enclosed
  pixel alone. The field goes, so the black page shows through it; a highlight
  inside a letter is not reachable from the edge and stays exactly the white
  it was drawn. Colour 0 is then left alone.

  The theme asks whether that took rather than assuming it — a build that
  cannot read the art keeps the pin and keeps its flat logo, which is
  worse-looking and still correct rather than a white box.

## [0.31.1] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.31.0] - 2026-08-31

### Added

- **A on an INSPECT row opens that POKeMON's AREA map.** The list answers
  "what lives here"; A asks the other half — "where else does this live" —
  and it opens the dex's own AREA screen rather than a second map of its own,
  so the two are one screen reached two ways.

  Only for a species you have seen. The list will tell you something rare
  lives in this grass; pinning its nests across Kanto for a POKeMON you have
  never met is the spoiler the question marks exist to avoid, so an unseen row
  does not answer.

- **The dex stops naming evolutions you have not met.** A caught BULBASAUR
  printed `EVOLVES / LEVEL 16 / IVYSAUR`, which hands over the next two names
  of every line in the game the moment you catch the first. An unseen target
  is masked now, the same way the INSPECT list masks one, and the row still
  says how and when — `EVOLVES / LEVEL 16 / ?????`.

### Fixed

- **The INSPECT header ran through its own frame.** `Lv11 VERY RARE GRASS` is
  twenty glyphs and the box holds eighteen, so it was drawn over the border.
  The name carries the level band and the tier carries the method now — two
  lines that fit by construction, with the ten-glyph name and a two-ended band
  coming to exactly eighteen at worst. Every rod is a `ROD`; which one is a
  detail the header was never the place for. The bound is enforced where the
  strings are built rather than only where they are drawn, so a mod that
  registers a longer encounter group cannot reopen it.

- **The caught balls sat on the list box's border.** The dex list can put its
  ball at x=150 because its own frame ends further right; this box is the full
  twenty tiles, so its border owns 152 onward and the ball was drawn through
  it. Moved inside.

## [0.30.4] - 2026-08-31

### Fixed

- **The white hairline round every piece of true-colour art.** Box icons,
  party icons, bag icons, dex icons, a move's type name — fourteen call sites
  across three mods, one cause.

  `Renderer.scissorClamped` rounds every zone's scissor **outward** to whole
  framebuffer pixels. That is deliberate and correct: on a fractional DPI a
  truncated scissor loses up to a pixel a side, two neighbouring SGB zones
  stop sharing an edge, and the letterbox clear shows through as a seam at
  every boundary. Letting neighbours overlap by a row instead is harmless when
  both are *shaded* — the same canvas twice, differing only in palette.

  It is not harmless for a `colors == false` zone. That one draws the canvas
  **raw**, so its overlap paints unshaded canvas over correctly shaded pixels.
  Just outside a matte the canvas is the white page — and white is what shades
  *to* black — so on a dark screen the overlap is a one-pixel white rectangle.
  It has been there since the marks existed; on white paper raw-white and
  shaded-white are the same colour, so nothing showed until dark mode.

  **No matte colour can fix it.** Reversing a four-shade palette is an
  involution with no fixed point (255↔0, 170↔85), so there is no canvas
  colour that renders the same raw as it does shaded; insetting the mark,
  insetting the matte, and growing both only move which side is wrong.

  So the palette changes instead of the paint. Each mark now gets a zone of
  its own, one pixel larger than the rect, **black at both ends**, and a
  one-pixel black skirt is painted around the art on the canvas. In that ring
  the canvas is black and the palette maps black to black, so raw and shaded
  agree and the overlap is invisible. Inside the mark the engine splices its
  own true-colour rect after ours, so the art is still drawn raw and untouched.

  One wrapper on `markTrueColor` does all fourteen at once — including sites
  in the other bundles, and any added later — and the two halves cannot drift
  apart because the same call makes both. UI pass only: a world-pass mark is
  the follower and the map's characters, and in ADVANCED the world canvas
  blits raw with no shader over it, so there is no seam to hide there and a
  skirt would be a black outline drawn round a character on a lit map.

  The upstream fix is one condition in the engine — a bare zone should round
  its scissor inward, having no seam to protect — and this stands in until
  that lands.

## [0.30.3] - 2026-08-31

### Changed

- **Type colours are vivid now, not washed.** 0.29.3 mixed each ink halfway
  to white to make it legible on a black button, and legible is all it was: a
  GRASS move came out the colour of sage rather than of grass.

  Mixing toward white is the wrong move because it takes the **saturation**
  out — every ink converges on the same pale wash, which is exactly the
  complaint. Scaling to the brightest channel does the opposite: the ratios
  between the three channels are what the hue *is*, so multiplying all three
  by one gain leaves the hue exactly where it was and spends the headroom on
  vividness. GRASS's 46/125/50 becomes 94/255/102 — the green of the type
  charts rather than a tint of it — and the dark end of the table gains the
  most, which is where it was needed.

### Fixed

- **The location banner no longer flashes white on its way out.** `drawBox`
  takes tile coordinates and the plaque slides under a `translate`, so the
  recorder logged where the box was about to be rather than where it landed.
  At rest the two agree and nothing shows; the moment it slid away the panel
  stayed parked and the box left it.

  The recorder asks the transform now — `transformPoint`, the engine's own
  answer to "where does this land", and the identity on every frame that does
  not translate. It fixes a second case in the same stroke: a classic state
  inside a wide battle draws under a centring translate, and its panels have
  been off by that offset for as long as this file has existed, because
  `centerClassicZones` runs before `render.zones` and never saw them.

## [0.30.2] - 2026-08-31

### Fixed

- **EDGE TO EDGE stopped smearing.** The bars around a battle were filled with
  the backdrop's one-pixel edge, stretched outward — the left column into the
  left bar, the top row into the top bar, a corner pixel into each corner.

  That is exact where the bars are thin: the colour at the seam is the colour
  the field ends on, so there is no line. It falls apart where they are not.
  On a landscape phone the bars are wider than the surface between them, and a
  backdrop with sky, hill and grass in it becomes a field of horizontal
  stripes — one band per source row, six screen pixels tall, across two thirds
  of the window.

  The bars now show the **same picture, scaled to cover the window**, each one
  showing the part of it that falls where that bar is. Two things follow, and
  the second is why this is the right answer rather than merely a different
  one:

  - the bars carry real detail instead of a smear of one column;
  - the cover scale is `max(ww/iw, wh/ih)` and the surface's is `vpw/iw`, so
    **as the bars shrink the two converge and the seam closes by itself**. A
    thin-bar window looks exactly as continuous as it used to; a wide one
    degrades into a zoomed backdrop rather than stripes.

  Cover means cover, so every bar's source rectangle is inside the picture and
  there is nothing to clamp. Quads rather than a scissor, because a scissor is
  in physical pixels and this pass is not the only thing deciding the
  transform. Cut once per picture and window rather than once per frame.

## [0.30.1] - 2026-08-31

### Fixed

- **The town map had the sea where Kanto is.** Under DARK the map came up with
  the land and water swapped and the coastline wrapped in trees.

  Reversing a palette turns all four colours over. That is right when the
  middle two are steps of a paper-to-ink ramp — which on almost every screen
  in this game they are, because almost every screen is ink on paper and uses
  the two between for a shadow. The town map's are not a ramp, they are a
  **legend**: colour 1 is the sea and colour 2 is the land, so turning all
  four over trades them.

  The map is still a page — its header is ink on paper and wants inverting
  like every other page's — so now only the **ends** turn over and the two in
  the middle stay exactly where they are. Sea stays blue, land stays green,
  the header goes white on black with the rest of the suite.

  `Theme.KEYED_PAGES` names the one class this applies to, so the rule is a
  list with a reason beside it rather than a special case buried in the
  transform. Any picture that uses its middle colours to mean something can
  join it.

## [0.30.0] - 2026-08-31

### Added

- **INSPECT on the town map**: stand on a place and ask what lives in it.

  A on a location now opens a small menu rather than doing one fixed thing.
  FLY already owned that press when the map was opened by the field move, and
  a second thing on the same button needs somewhere to choose between them —
  so both live in one menu, and the map opened from the BAG gets the same menu
  with INSPECT alone in it. B closes it and nothing has happened.

  INSPECT lists what lives there, **richest share first**. That order is a
  real number rather than a guess: Gen 1 rolls one byte and walks ten
  cumulative thresholds, so a slot's share is the width of its bucket and a
  species' share of a map is the sum of the buckets it sits in. Same buckets
  and the same tier cuts the dex's AREA strip uses, so a COMMON in one means a
  COMMON in the other — this is the AREA walk read backwards.

  A location is often several maps (a route and its gate, a town and its
  shore), so shares are pooled and then **rescaled by the maps that actually
  carried encounters**. Without that a species owning half the one patch of
  grass in a town would be called VERY RARE because the town's three gates
  have none.

  Each row carries the dex's own caught ball, in the dex's own column, because
  this answers the same question the dex list answers and a ball that moved
  between the two would read as a different mark.

  **It will not name what you have not seen.** A species you have never met
  prints as question marks — and so does the header, which is the half that
  would have made the rest pointless. The row keeps its place in the order, so
  the screen still says "something common lives in this grass", which is what
  anyone walking in it would work out. It just does not say what.

  New row **MAP INSPECT** under the Pokédex options, on by default. Off leaves
  A exactly as it was.

## [0.29.4] - 2026-08-31

### Added

- **`themeProbe` export**: what the theme's last frame saw — boxes recorded,
  panels produced, zones handed in. For the nightly bench's SPRITE PROBE and
  nothing else. A build with no theme answers three zeroes rather than
  nothing, so a caller never has to know whether the theme installed.

## [0.29.3] - 2026-08-31

### Fixed

- **Type colours came back grey on a dark battle box.** TACKLE, RAZOR LEAF,
  LEECH SEED and VINE WHIP all printed in the same light grey; three of those
  are GRASS and should be green.

  The ink was never wrong. A type ink is a real RGB colour drawn onto the
  canvas by a tint shader, and it survived for as long as it did because a
  classic battle hands the renderer **no zone list at all** — with nothing to
  colorize, the canvas is blitted raw and the letters keep their colour.
  0.27.0's dark battle UI ended that: it paints a panel over every box a
  battle draws, which is how the command grid goes dark in the first place,
  and a panel is a four-shade palette. The letters were then read as four
  shades off their red channel and repainted, so every type landed on
  whichever grey its own red channel picked.

  No four-colour palette can carry an arbitrary colour, so the fix leaves the
  palette pass rather than trying to survive it. A coloured label now claims
  its own rectangle: the theme's matte is painted into it, the ink is lifted
  halfway to white (the table is deliberately dark — it was written for
  black-on-white, and those inks on a black button are unreadable), and the
  rectangle is marked true colour so the raw re-blit shows what was drawn.

  ADVANCED only, and deliberately: a true-colour mark is discarded in every
  other mode, so painting a matte there would put a black plate through the
  shade pass and punch a hole in the button. Elsewhere the letters go through
  the palette as they do today — legible, just not coloured. Under LIGHT
  nothing changes at all: the box is white and the dark inks are what they
  were written for.

## [0.29.2] - 2026-08-31

_No changes in this release; the channel ships one version across every
mod, so this is here to match it._

## [0.29.1] - 2026-08-30

### Fixed

- **The logo and the version ribbon had white boxes behind them.** 0.29.0
  painted the title screen's page black and pinned colour 3 — what a black
  page reads as — while leaving colour 0 alone, on the reasoning that the
  page was the only white on the screen. It is not. The logo and the ribbon
  are drawn from images that carry their own **opaque white field**, painted
  over the page by the draw itself, so the screen came up with two white
  rectangles on it: one around POKeMON and one around WILD GREEN VERSION,
  each exactly the size of its art.

  Both ends of the ramp are pinned now. Every shade-0 pixel on this screen is
  paper — the page under the art and the art's own paper — so colour 0 goes
  black with colour 3, and the letters, which are colours 1 and 2, are
  untouched: the logo keeps its yellow and its grey drop shadow, the ribbon
  keeps its green.

  The paint is still doing its job and is not made redundant by this. A
  true-colour rectangle re-blits raw and never reaches the shader, so what
  sits under the mon and the player figure has to actually BE black pixels.
  The palette handles the shaded paper; the paint handles the raw.

## [0.29.0] - 2026-08-30

### Added

- **A dark title screen, done the other way round.** 0.24.0 made the title a
  themed page — reverse its palettes, black paper, white ink — and three
  things went wrong on screen; 0.28.0 backed it out. This is the second
  attempt, and it does not reverse anything.

  The screen's page is **painted** black instead. `TitleState:draw` opens with
  a white fill of the whole screen; that one fill is served as a black page
  with the bottom row left white, and everything after it draws on top
  exactly as it did before. Which means:

  - the logo, the ribbon and the mon keep colours 0, 1 and 2 — **their own
    colours**, not a reversal of them. Only colour 3, which is what a black
    page reads as, is pinned to black so the ground is black whatever palette
    the cart ships.
  - **no white boxes.** The mon and the player figure are marked true colour,
    so their rectangles are re-blitted raw from the canvas — and the canvas
    under them is now black. There is nothing to repair, which is just as
    well: a matte cannot fix this screen, because its second pass would begin
    by filling the page white again.
  - it works in **every display mode**, not only ADVANCED. It is the page, not
    a true-colour mark.

  The copyright line is black ink, and black ink on a black page is not there,
  so its row is the one strip left white and reversed on its own — white
  letters on black, the same trade every dialogue box here makes.

  With the CONTINUE menu open none of this runs. `TitleState:draw` fills white
  and returns, there is no art on the screen, and the frame is an ordinary
  page that `Theme.COVERED_PAGES` reverses like any other — a painted ground
  under that would reverse to a white one.

  The two halves are kept in step by a flag the painter sets on the state for
  exactly the frame it painted on, so a build where the patch did not take
  gets the screen it always had rather than half of a dark one. And the fill
  is served from inside whichever wrapper is innermost, so it does not matter
  whether Wild Green's own title wrap ends up outside this one or under it.

## [0.28.0] - 2026-08-30

### Fixed

- **The location banner is themed.** It is a `Font.drawBox` from an overlay
  hook with no state behind it, so there was no rectangle for a state to
  describe and nothing earlier in the frame for the drawn-box closure to hang
  it on. It stayed white over a dark map for as long as panels came only from
  the stack.

  The rule is simpler now, and one rule instead of three: **when the frame's
  owner is not a page, every box drawn on it is a panel.** The map is tiles and
  draws no boxes of its own, so every box on an overworld frame is UI. A page
  is the other case and keeps the closure — its own boxes are already inside
  its own colours and taking them again would be a second coat over its
  content.

  That also settles the wide battle, which I flagged as untested at 0.27.0.
  It is the one battle layout with a zone list, so it never reached the bare
  frame path and came out with a dark command menu over a light dialogue box.
  Both layouts agree now.

### Reverted

- **The dark title screen is out** (added 0.24.0). Three things went wrong on
  screen and they are not one fix:

  - the `POKéMON` logo's outline is shade 3, and the ground transform swaps
    paper and ink, so a dark outline came back white;
  - the mon and the character flashed white frames — they are true-colour
    rectangles marked from **two** code paths on different frames, and only one
    of those (`currentSprite`, called from inside the draw) can paint under a
    rectangle. On the frames the other one marks, nothing mattes it;
  - slivers of those rectangles were left unpainted as lines beside both
    sprites.

  The `CONTINUE` menu is dark exactly as it was from 0.20.0: the title is a
  picture when it is alone and a page when that menu is standing on it. I put
  the risk about the logo in the 0.24.0 notes and shipped anyway; the sprite
  frames I did not foresee, and three visible defects on the first screen of
  the game is not something to iterate on in front of you.

  Doing it properly means getting both of those marks under one roof before
  touching the palette at all, which is its own piece of work rather than a
  transform.

## [0.27.0] - 2026-08-30

### Fixed

- **The battle UI is dark, and the battle keeps its colours.** 0.26.0 stopped
  the battle scene going black and white behind a themed box, and the price it
  paid was that no box over a battle was themed at all — the command grid,
  the dialogue and the `YES` / `NO` all stayed white. That price did not have
  to be paid.

  Both halves are the same fact about the renderer:

  ```lua
  local shader = zoneList and zoneList[1] and PaletteFX.shader() or nil
  if not shader then ... draw the canvas RAW ...
  ```

  An empty zone list is not "colour nothing", it is *"run no shader and blit
  this frame as it was drawn"* — and `BattleState:sgbPalettes` returns `nil`
  for every layout but the wide one. Appending a panel turns the shader on for
  everything; appending nothing leaves the boxes light.

  The way out is in the engine's own comment, one screen further down the same
  function: *"a `colors == false` zone is the trueColor opt-out: its rect draws
  with no shader at all."* So a frame that arrived with no zones gets a
  whole-screen `colors = false` zone — which reproduces exactly what an empty
  list did — and the panels go after it. The backdrop and the POKéMON are
  blitted raw in their own colours; the boxes on top are themed.

  **Every box on such a frame is taken**, not only the ones a state described.
  On a frame where nothing is themed there is no half-and-half to avoid: it is
  every box or none, and the battle's own command grid, its dialogue and its
  `YES` / `NO` are all the same UI. A bare frame with no boxes drawn on it is
  still handed straight back untouched.

  Nothing in `Gen1BattleUI` changed. Its boxes are `Font.drawBox` like every
  other box in the game — white paper, black glyphs — and the panel maps them
  the same way it maps a menu's. That matters because the border glyphs are
  black bitmaps on transparency: `Font.drawBox`'s own comment says they "come
  out black whatever the color is", so no amount of `setColor` in our own
  drawing code could have inverted them. Only a palette can.

  `tests/savescreen_test.lua` is 49 assertions, standing up a battle with its
  command grid, its dialogue and its `YES` / `NO`, and holding the raw zone
  first, one panel per box, and no duplicate for a box a state also described.

## [0.26.0] - 2026-08-30

### Fixed

- **A box over a battle no longer repaints the battle.** In DARK, the moment
  `Will WILD change POKéMON?` came up the entire battle behind it went black
  and white — backdrop, mon and all.

  `Renderer:blitCanvas` opens with

  ```lua
  local shader = zoneList and zoneList[1] and PaletteFX.shader() or nil
  if not shader then ... draw the canvas RAW ...
  ```

  So an **empty zone list is not "colour nothing"** — it is *"run no shader at
  all and blit this frame in the colours it was drawn in"*. And a battle is
  exactly that: `BattleState:sgbPalettes` returns `nil` for every layout but
  the wide one.

  Appending a single panel to that list turns the shader **on for the whole
  frame**, and every pixel no zone covers — which is the entire battle — goes
  through the palette pass instead of being left alone. One dark dialogue box
  cost the whole screen its colour.

  Panels are only ever added to a frame that already had zones now. The map
  has a list, so everything over the overworld is themed exactly as before;
  a battle has none, so nothing is added to it.

  **What that gives up, plainly:** a dialogue box or `YES` / `NO` over a battle
  stays light in DARK. There is no zone this suite can add to a frame with no
  zone list without repainting everything behind it, so the box and the battle
  cannot both be right this way. Themed battle boxes need a different
  mechanism — a whole-screen `colors = false` zone under the panels would do it
  on paper — and that is worth trying in the game rather than shipping on a
  guess, having just shipped one.

  This was reachable from 0.6.0 for any `Menu` or `ChoiceBox` over a battle and
  became common in 0.23.0, when `TextBox`'s own spelling of its rect started
  being read.

  `tests/savescreen_test.lua` is 38 assertions, holding both a nil list and an
  empty one handed straight back, and the map still getting its panels.

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

### Added

- **The title screen has a dark mode, and keeps its colours.**

  Reversed like an ordinary page it would come out wrong twice over: the
  `POKéMON` logo's colours would swap into something nobody chose, and the
  version ribbon — `Wild Green Version`, lettered in the character's own outfit
  colour over four releases of getting that number right — would come out in
  whatever the reversal made of it. Left alone it is a white screen in a dark
  game, and the first thing a dark boot puts in front of you.

  So a page in the new `Theme.GROUND_PAGES` has its **ground moved out from
  under it** instead of being inverted. Paper goes to the same black the menus
  use, ink takes the paper's old white, and **the two midtones are not touched
  at all** — which is where every coloured thing on that screen lives. The logo
  keeps its colours on black, the ribbon keeps its green, and `GAME FREAK inc.`
  along the bottom, which the engine draws in shade 3, flips to white instead
  of going black on black.

  The same rule covers the `CONTINUE` menu the title opens into, so
  `Theme.COVERED_PAGES` — which existed for that one case since 0.20.0 — is
  gone and its member moved here. Those boxes are DMG greys, and grounding
  greys is paper black and ink white, which is what a menu wants.

### Fixed

- **No white boxes around the mon or the character.** Both are true-colour
  rectangles, and a marked rect is re-blitted **raw** — so on a dark title they
  would be the same white boxes 0.22.0 fixed on the bag's icons, for the same
  reason.

  `runtime/matte.lua` exists for exactly this on screens the suite does not
  own, but its two-pass wrapper cannot reach this one: `TitleState:draw` opens
  with a white fill of the **whole** screen, so a matte painted between the
  passes is wiped by the second pass's own fill before any art lands on it.

  The paint has to happen *inside* that draw — after the fill, before the
  sprite — and there is exactly one seam in there. `currentSprite` is called
  from the middle of `draw`, on the line before the mon is drawn, and that is
  where both rectangles are grounded now. Both rects are the engine's own
  arithmetic quoted rather than guessed: the mon at
  `40 + (56 - w) / 2 + monOffset` by `136 - h`, the figure at the flat `82, 80`
  the engine draws and marks it at.

  **One case this does not reach, named rather than hidden:** `draw` skips
  `currentSprite` entirely while `scrollPhase` is `"ball"`, so for the few
  frames of that phase the figure and the ball keep their white. The seam is
  not there to be used in that phase.

  `tests/matte_test.lua` is 42 assertions (both rects, `monOffset` sliding the
  mon's, a sprite the engine will not mark, the menu frame, and `LIGHT` paying
  nothing); `tests/titlepage_test.lua` is 27, holding the midtones surviving
  and a `colors = false` rectangle being handed back untouched.

## [0.23.0] - 2026-08-30

### Fixed

- **Dialogue over the map is themed with the `YES` / `NO` beside it.** In DARK,
  `That will be ¥450. OK?` came up on white paper with a black `YES` / `NO`
  sitting next to it. Two boxes on one screen, one of them themed.

  A panel is read off the four numbers a state keeps its box in, and the engine
  has **two spellings of those four numbers**. `src/ui/Menu.lua` computes
  `tx`/`ty`/`tw`/`th` in `Menu.new` and `src/ui/ChoiceBox.lua` takes the same
  names; `src/render/TextBox.lua` keeps its box as
  `boxTx`/`boxTy`/`boxTw`/`boxTh`. Only the first was read.

  The drawn-box closure could not cover for it here either, and the reason is
  worth writing down: dialogue is drawn **first** and the `YES` / `NO` after it,
  and the closure only ever looks backwards at boxes it has already accepted.
  That direction is deliberate — it is what stops a menu stacked over a battle
  from reaching back and repainting the battle's own boxes — so the fix is to
  read the rect the state was describing all along, not to loosen the closure.

  Both spellings now, `tx` first. That is every box in the engine that names
  its rect on the instance: `Menu`, `ChoiceBox` and `TextBox` are the three,
  and every other `Font.drawBox` in `src/ui` passes literals, which is the
  ad-hoc case the closure was built for.

  **It does not reach into a battle.** A battle draws its own dialogue and
  command box directly (`BattleState.lua:6546-6547`) rather than pushing a
  `TextBox` state, so there is no `TextBox` above it to find. The one battle
  that does push one — the nickname prompt after a catch — already had its
  `YES` / `NO` themed and its box not, which is the same split this fixes.

  `tests/savescreen_test.lua` stands the prompt up over the map and holds both
  boxes dark, plus a state carrying both spellings being read once. 34
  assertions; the new ones fail against 0.22.0.

## [0.22.0] - 2026-08-30

### Fixed

- **The white square behind an item icon, for real this time.** 0.14.0 baked
  the paper into the art as the icon's own silhouette and took the matte out,
  on the grounds that the icon now carried its own. It does — and the **cell
  around it** does not.

  `markTrueColor` hands the renderer a 16×16 rect, and a marked rect is
  re-blitted **raw** from the canvas. So whatever the screen cleared that cell
  to comes back with it, and every screen these icons appear on clears to
  white. The square returned, sourced from the page instead of from a rectangle
  this file drew — which is exactly why the bake looked like it had never
  worked.

  Both halves now, in this order: **the matte is the cell, the bake is the
  paper.** The cell is painted the colour that spot is going to end up, the
  icon goes on top carrying its own silhouette-shaped white, and only then is
  the rect marked. What is left is a sticker on a page, which is what it was
  meant to be two releases ago.

  This is the same rule 0.21.0 wrote down one screen over, read the other way:
  a marked rect is raw, so everything inside it has to be put there on purpose
  — the art *and* the ground under it.

  `tests/itemicons_test.lua` covers the order now as well as the bake — matte,
  icon, mark, over the same rect — plus a build with no theme and an icon that
  is not there. 30 assertions, and the new ones fail against 0.21.0.

- **`maintained/Gen1ItemInfo/icons.lua` had drifted from `modules/`.** The
  0.14.0 bake landed in the shipped copy only, so the tree's own source for
  that module was three releases behind the file it is the source of. Both
  carry this fix and are identical again.

## [0.21.0] - 2026-08-30

Nothing in this mod changed for 0.21.0; the channel ships as one release, so
it carries the version.

## [0.20.0] - 2026-08-30

### Fixed

- **The `CONTINUE` menu is dark all the way into the corners.** In DARK it was
  a black `CONTINUE` / `NEW GAME` box in the top left, a black
  `PLAYER` / `BADGES` / `POKéDEX` / `TIME` box under it, and white paper in the
  corners neither of them reached. The boxes were themed and the page they sit
  on was not.

  The title screen owns its frame and is not in `Theme.PAGES`, quite rightly:
  for most of its life it is the logo, the mon and the version ribbon, and
  reversing that would be vandalism. But `TitleState:draw` opens with a white
  fill of the whole screen and then `if self.menuOpen then return end` —
  MainMenu's own `ClearScreen`, which wipes the logo, the mon and the sprites
  before the border goes down. From the moment that menu opens there is no art
  on that screen at all: it is blank paper with two boxes on it, and it is the
  first thing a dark-mode boot puts in front of you.

  So the rule is the stack rather than the class. `Theme.COVERED_PAGES` names a
  frame owner that is **a page when something is stacked on it and a picture
  when it is alone**. Nothing is pushed over the title but that menu, and the
  menu is exactly when the art is gone, so the two questions have the same
  answer and this one can be asked without the engine's own `menuOpen` being
  reachable from a mod.

- **And the rest of the sweep, since one of these has now come up twice.**
  Twenty-four states in the engine own a frame. The theme names twelve of them
  as pages. Each of the other twelve was read:

  - the overworld and a battle — correctly declined; a map that goes dark is a
    map you cannot read
  - the intro, the Yellow intro, Oak's speech, the Hall of Fame, the evolution
    and trade animations, the slots, the surfing minigame — pictures, correctly
    declined
  - `PaletteScreen` — the colour picker itself, which has to show colours as
    they are
  - `TitleState` — the one false negative, fixed above

  So one gap, and it was the one in the screenshot. `tests/titlepage_test.lua`
  holds both halves of the title's double life plus a picture that stays a
  picture and a map that stays a map, and asserts that no class is ever in both
  lists.

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
