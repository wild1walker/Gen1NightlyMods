# Wild Green Nightly

**The player wears green, he is called GREEN, and the title screen says so.**
That is the whole mod.

> This is the **nightly** build. It is the same mod as
> [Wild Green](https://github.com/wild1walker/Gen1MakeItGreen) with changes
> that have not been cut into a stable release yet, it installs under its own
> id (`wild_green_nightly`) and it conflicts with the stable one on purpose —
> run one or the other, never both. The stable cart is untouched. See
> [the channel's README](../../README.md).

It is the identity half of the [Wild Green][cart] cart: the cart
pins [Gen1WildUI](https://github.com/wild1walker/Gen1WildUI) and
[Gen1WildQOL](https://github.com/wild1walker/Gen1WildQOL) for everything a
playthrough actually does, and this supplies the one thing a pinned mod set
cannot — a game that looks like its own version rather than like Red with
things added.

It works on its own too. Nothing here depends on either bundle.

## What it changes

| | | how |
|---|---|---|
| the overworld walker | `SPRITE_RED`, and the `BICYCLE` sheet where the import wrote one | the `sprites` registry |
| the battle back pic | the one drawn at 2x until "Go!" | the `player.sprite` hook |
| the front pic | Oak's intro, the trainer card, the Hall of Fame | the `player.sprite` hook |
| the credits and intro pics | where the import wrote them | the `player.sprite` hook |
| the town map marker | the figure marking where you stand, on AREA and FLY | a wrap on `TownMap.new` |
| the title screen | the version ribbon | `field.boot.title` |
| the title figure | the standing player on that screen | the `MEWMON` palette, and a bake of its own under `ADVANCED` |
| the default name | `GREEN` where the game offered `RED` | `field.boot.playerName` |
| the name list | `WILD / GREEN / VERSION`, and the rival's `Thanks / For / Playing!` | `field.boot.namePresets` |

The two battle pics go through the **hook** rather than a registry write, and
that is not a style choice. `Sprites.playerPath` resolves them through
`FieldDefaults.fieldValue`, not `data.field` — so `field:get("playerPics")`
hands back nothing, and a patch built out of it patches nothing at all. That
is what 1.0.0 did, and why the player stayed red everywhere but the
overworld. The hook runs over the already-resolved path, so it needs no guess
about where the vanilla art lives.

The ribbon is one continuous strip reading **WILD GREEN VERSION**, where the
vanilla art is two fragments the title code repositions. It is drawn by
[`tools/make_ribbon.py`](tools/make_ribbon.py) on the importer's four
grey shades, and the green arrives from the `LOGO1` palette this mod
overrides — the SGB palette the title's ribbon band wears.

## The four rows

In the mod manager, or in `OPTION > MODS`:

```
WILD GREEN
  PLAYER              GREEN     <- or RED, ORANGE, BLUE, PURPLE,
                                   YELLOW, PINK, BLACK, WHITE, GREY
  PORTRAIT SKIN       ON
  TITLE RIBBON        ON
  TITLE FIGURE        ON
  GREEN NAME LIST     ON
```

- **`PLAYER`** is the character's colour, and there are ten of them.

  `GREEN` is the default and is what the cart is named after. `RED` is the
  switch back: the vanilla character everywhere, no recolor applied at all,
  and the vanilla art was never overwritten to begin with. The other eight —
  `ORANGE`, `BLUE`, `PURPLE`, `YELLOW`, `PINK`, `BLACK`, `WHITE`, `GREY` —
  are the same recipe over a different outfit.

  Only the **outfit** changes between them. The skin, the lips, the paper and
  the black outline are the same in all nine recoloured suits, which is the
  whole reason the recipe learned to tell a face from a jacket in the first
  place. It covers everything: the overworld walker and the `BICYCLE` sheet,
  the battle back pic, the trainer card, Oak's intro, the credits, the Hall
  of Fame, the town-map marker and the figure on the title screen.

  Every suit is written to disk at install, so the row is a path change and
  switching colour costs nothing at run time — and, since 0.1.0, costs no
  relaunch either. Turning the row repoints the folded `sprites` record and
  rebuilds the renderers that had already read out of it, so the walker
  changes colour where he is standing.

  `WHITE` is deliberately low-contrast — a white outfit on white paper is
  carried by vanilla's own black outline, the way a white shirt is in any
  four-shade art. The version ribbon on the title screen stays green in every
  suit: that is the game's name, not the character's jacket.
- **`PORTRAIT SKIN`** paints the face on the big pictures — the battle back
  pic, the trainer card, Oak's intro, the credits, the Hall of Fame — the
  character's own skin instead of the light green. Off is the flat green
  those pictures wore in 1.4.0. It has a row of its own because the rule
  that finds the face is a guess about art this mod never sees; see below.
- **`TITLE RIBBON`** is the branding. Off gives back the imported ribbon and
  the imported band colour. On, the title says `WILD GREEN VERSION` whichever
  colour the character is — the words are the game's name — but the **ink
  follows `PLAYER`**. It used to stay green in every suit, and in front of a
  player who had just put the character in purple that read as a setting that
  did not take.
- **`TITLE FIGURE`** colours the standing player on the title screen. In
  most display modes that is the `MEWMON` zone palette, which takes the
  `GAME FREAK` line with it — see below for why the two cannot be separated.
  Under `ADVANCED` the zone pass does not reach him at all and he is baked
  instead, so there the copyright line is untouched. Off gives that screen
  back to the base game either way.
- **`GREEN NAME LIST`** is the names the game *offers*. The fallback a save
  gets when you type nothing is `GREEN` rather than `RED`
  (`field.boot.playerName`), and both lists on the naming screen's
  `NEW NAME` page are replaced (`field.boot.namePresets`): the player's
  reads **WILD / GREEN / VERSION** where vanilla's reads RED / ASH / JACK,
  and the rival's reads **Thanks / For / Playing!** where vanilla's reads
  BLUE / GARY / JOHN. Each is meant to be read straight down the cursor.
  `Playing!` is eight characters, one past what the screen lets you *type* —
  a preset is picked from the menu instead, so the limit never applies, and
  eight is exactly what the box holds before it would have to widen. It has
  a row of its own because a name is the one thing here that ends up
  written into a save, and
  it follows `PLAYER`: switch the character back to red and the names go
  back with him.

### The title screen, in every colour mode

Two of the engine's display modes do not resolve named palettes through the
mod registry at all: `OG RED` short-circuits every name to the boot-ROM pair,
and `ADVANCED` reads `data/palettes_gbc`. So the two overrides this mod makes
— `LOGO1` for the ribbon band and `MEWMON` for the band below it — were
simply not consulted there, and under `ADVANCED` the title screen wore that
pack's own colours: the ribbon lettered yellow-green on pale yellow, and a
skin tone across the POKE BALL and the copyright line at the bottom.

`MEWMON` was also the wrong four of ours. It covers tile rows 10-17, which is
the cycling mon, the ball and the copyright line as well as the figure, and
shade 2 there is a light on all of them and a face on none — so it takes the
portrait ramp now rather than the overworld one, whose shade 2 is skin.

Both bands are recoloured in the frame's **zone list** as well, through
`render.zones`, which is handed the finished list after every name has been
resolved. The three deliberately monochrome modes (`OG`, `OG INV`, `CLASSIC`)
substitute the whole screen downstream and are left alone.

**A new version needs a relaunch to load at all** — mods are loaded once, at
boot, so installing over a running game leaves the old code running until
you restart. That part is the engine's, not this mod's.

What *is* this mod's is the first launch after that. The transform writes
its pictures at install time and the title screen is one of the earliest
things drawn, so the recipe's copy of the figure can arrive a moment after
the screen does. The title draw keeps asking for it — rarely, and only while
it hasn't got it — rather than settling on the flat bake for the life of the
screen. So the first load shows the drawn figure, not a faceless one.

## No green pixel ships

The player's four pictures are the vanilla ones, so this mod may not ship
them ([Art Pipeline](https://github.com/bryanthaboi/gen1recomp/wiki/Guide-Art-Pipeline),
"The rule"). Derived art travels as a recipe, and the pixels come from your
own imported cache. [`transforms.lua`](transforms.lua) is that recipe: it
runs once on install, and again only when the cache is re-imported or the
recipe changes.

The recipe and the hook name the **same eight pictures**, in the same order,
and `tools/check.py` fails the build if they drift apart. That is not
tidiness: a swap to a green file the recipe never wrote does not fall back to
the red one — the image fails to load and the draw shows nothing at all.

Its outputs go under a prefix named for the suit — `green/`, `blue/`,
`grey/` — rather than over the cache paths they were read from. Writing
`sprites/red.png` would make the player green everywhere, always, and would
take the `PLAYER` row away; there would be no red art left to switch back to.
Under a suit prefix they shadow nothing, every set exists the whole time, and
`main.lua` points the records at whichever one the row names.

## The palette

Four colours, in [`tools/palette.py`](tools/palette.py), and the same
four everywhere they appear — the sprite recolor, the ribbon lettering, the
cart's shell and the cart's label:

**The overworld character**, in shade order:

| | | |
|---|---|---|
| paper | `#ffffff` | stays pure white: the battle back pic mattes on it |
| skin | `#f0a363` | **the face and hands** — sampled off the reference sprite |
| outfit | `#65ba3f` | the cap and clothes — the reference green |
| ink | `#000000` | outline and hair |

and two colours that are not shades at all:

| | | |
|---|---|---|
| mouth | `#ec4d29` | the lips — vanilla's own, sampled off red Red |
| bill | `#e6f4dc` | the cap's bill — a green-tinted white |

**The other eight suits.** Three values each, and only three: the outfit, the
portrait's light shade and the bill. Skin, mouth, paper and ink do not move —
the face is the face in every colour.

Green's three are sampled by hand. The other eight are green's own rule over a
different outfit: the portrait light is the outfit mixed 45% toward white, the
bill 83% toward white — which reproduces green to within five values of 255 on
every channel. Above 0.70 relative luminance (`YELLOW` and `WHITE`; green sits
at 0.62) the bill goes 35% toward **black** instead, because a near-white bill
on a near-white cap is no edge at all.

| suit | outfit | portrait light | bill |
|---|---|---|---|
| `GREEN` | `#65ba3f` | `#a8dd8a` | `#e6f4dc` |
| `ORANGE` | `#e2681c` | `#efac82` | `#fae5d8` |
| `BLUE` | `#3f7bd8` | `#95b6ea` | `#dee9f8` |
| `PURPLE` | `#8a5bd0` | `#bfa5e5` | `#ebe3f7` |
| `YELLOW` | `#e8c53a` | `#f2df93` | `#978026` |
| `PINK` | `#ee7bb8` | `#f6b6d8` | `#fce9f3` |
| `BLACK` | `#3d3d45` | `#949499` | `#dededf` |
| `WHITE` | `#cdd3da` | `#e4e9ee` | `#85898e` |
| `GREY` | `#8b9199` | `#bfc2c7` | `#ebecee` |

`tools/check.py` holds this table against the copies in `transforms.lua` and
`main.lua`. Neither can import it — the recipe runs in a sandbox with no
`require` at all — so a suit that differs between the two would be a title
screen in one colour and a player in another.

**The trainer art** — the battle back pic, and the front pic Oak's intro,
the trainer card and the Hall of Fame share — takes a different four, because
shade 2 does not mean the same thing there:

| | | |
|---|---|---|
| paper | `#ffffff` | |
| light | `#a8dd8a` | the light for **everything**: the cap's front, the shirt's shading, the knees |
| outfit | `#65ba3f` | |
| ink | `#000000` | |

On the 16×16 sprite shade 2 is only ever the face. On the 56×56 portrait it
is the light on every surface. Vanilla gets away with one shade for both
because its ramp is monochrome red — white, light red, red, black — and light
red happens to look like skin; painting that shade a skin tone put orange
blotches on the hat and the knees. The portrait gets the same trick in green,
and neither of the overworld position rules, because a face-sized rule on
face-sized art is noise.

### Finding the skin when skin is not one shade

Vanilla's ramp on this art is monochrome, so a pixel's shade never says
whether it is a cheek or a sleeve — and skin is not one shade anyway. The
face is shade 2 with its brow and mouth in shade 3, and the **hands are
shade 3 alone**, the same shade as the trousers and the cap. Every rule
before 1.9.0 looked only at shade 2, so the hands and the ear were
unreachable by all of them, and what those rules did find on the arms was
the jacket's own shading.

Read back out of the game, the card's four skin parts are:

| | |
|---|---|
| the face | one patch of shade 2, 22px, high in the figure |
| the ear | **one** pixel of shade 2 beside it, with one of shade 3 under it |
| the hands | two patches of **shade 3** — 6px at the left hip, 7px at the right |
| the detail | small pieces of shade 3 inside or against skin: brow, mouth, the ear's shadow |

and the four things that look like them and are not: the cap's shading
(19px of shade 2, sealed inside the cap), the jacket's shoulder and sleeve
shading (shade 2, and one pixel from a hand on every local count), the
collar (6px of shade 3 — a hand's size and a hand's profile), and the
shirt's hem (4px of shade 3, out past the shirt's edge like a hand).

So nothing is decided by size or colour alone. Every rule is about **where**
a patch sits relative to the figure and to the biggest mass of ink in it,
which is his shirt front:

- **The face** — the biggest patch of shade 2 high in the figure with paper
  against it. The cap's shading is bigger and sits up there too, but it is
  sealed inside the cap and touches no paper at all.
- **The ear** — a speck of shade 2 *beside* the face, level with its upper
  half. Beside, because inside is the face already; upper half, because that
  is where an ear is and the collar is not.
- **The hands** — small patches of shade 3 reaching *past* the shirt's edge,
  low enough to be at the hip rather than the shoulder, and ringed by
  outline. The collar fails the height; the hem fails the outline; a hole in
  the shirt fails the edge.
- **The detail** — shade 3 sealed inside skin, or a speck of it against
  skin. Those take `#ad7547`, the skin's own shadow, so the brow and the
  ear are not green freckles on a skin-coloured face.

**Which** skin a pixel gets is which pass found it, not its own shade. Skin
is `#f0a363`; the shadow `#ad7547` is for what the detail pass picks out —
the brow, the mouth, the ear's underside, the temple under the hat, and the
speck sealed inside a hand, which is the crease between two fingers rather
than a highlight on them. A hand itself is skin: 1.11.0 coloured by shade
instead, which made both hands shadow throughout, and on this art that reads
as a hand in shadow rather than as a hand.

It still fails closed: no face found, nothing is painted anywhere — not even
something shaped like a hand. The battle back pic used to be that case, and
came out one green shape from the cap to the boots; it carries a table of its
own now, below.

Checked against the real card region by region: face, ear and both hands
come out skin; cap shading, jacket shoulder, sleeves, collar, hem, trousers
and shoes stay green.

The recipe writes **both** copies of every portrait — `green/` and
`greenskin/` — and the row picks between two files that already exist, rather
than deciding a recolour. That is what makes it a switch you can flip in a
menu instead of one that needs a release to undo.

### Two pictures are painted, not reasoned about

Two pictures do not go by rules at all. Of the 95 pixels that are not plain
ramp on the title screen's figure, **fourteen come from the paper shade** —
the lit side of his face, the back of a hand — and eight go to ink. Nothing
in the recipe touches white, and inventing a rule to fit one sprite is a
drawing with extra steps. So it is a drawing: a table of *row, column, the
shade that must be under it, and the tone*, authored by eye against that
figure.

It ships no pixels of the vanilla art — the art stays in the player's cache
like everything else here, and the other 2,200 pixels of that picture are
still whatever their import wrote. What it carries is where a face is. **The
shade is the guard**: every entry has to find the shade it was drawn
against, and a cache whose figure differs — a translation, a conversion, a
different rip — fails those checks and falls through to the ordinary rules
rather than being painted at coordinates that mean nothing there.

A table is matched at its own coordinates first, and only if that fails is it
slid over the picture to find the offset it *does* fit at. A list of
coordinates otherwise finds its art only where it sat, so the same sprite one
pixel over — an importer that pads differently, a rip on a larger sheet, a
canvas that is not 32×32 — failed every guard at once when the pixels were
identical. Placement is the one thing that varies without the art changing.
It cannot wander: a run still has to clear the same threshold, and the best
offset has to be the only best one, because two equal readings are not a
reading.

Art whose **pixels** differ is still left alone, on purpose, and there is no
rule underneath to fall back to. On the back pic the hand cannot be told from
the sleeve's own white by size, by height, or by reaching past the body — the
sleeve does all three — and the neck's skin is three patches of 6, 2 and 1
pixels against thirteen single-pixel patches of the same shade that must stay
green. A rule tuned tight enough to separate those would *be* the table, and
would fail open on art it has never seen.

The **Poké Ball** is not in the table. The engine lifts an 8×8 out of that
file at `(0,16)` and throws it on a y of its own while the title animates,
so in a screenshot it is never where it lives — but the rect is an engine
constant, so the ball keeps vanilla's red by rect rather than by coordinate.
It is a ball, not the player; the same argument the overworld `MOUTH` rule
makes.

The **battle back pic** is the second, and it is the same argument again. It
had no skin on it at all — he was one green shape from the cap to the boots,
because `skinMask` is built around finding a face and gives up the moment it
cannot, and the ear, the hands, the glint and the temple are all placed
relative to the face's own bounds. There is no face on the back of his head.
What *is* skin on it is his **neck and jaw** below the cap and his **hand and
forearm** at the lower right — and of those 33 pixels, **eleven come from the
paper shade**, because the back of the hand is drawn in white. It is one
fixed 32×32 picture, not a sheet of frames a rule has to generalise over, so
it gets a table on the same terms as the title figure: 33 coordinates out of
489 drawn ones, guarded by the shade each was authored against.

Because the two copies of that picture used to come out identical, `PORTRAIT
SKIN` did nothing to it. It is a real switch on the back pic now.

The title screen's standing figure **is** covered by all this, in one mode. In
every other mode his rectangle is painted by shade — the colour a file
carries is thrown away before it reaches the screen — so `MEWMON` does that
work. Under `ADVANCED` the zone pass never reaches him, and `main.lua` hands
that draw the recipe's own copy of `title/player.png`, so the same face, ear
and hands the trainer card gets come with it. A cache with no such file
falls back to `main.lua`'s flat bake.

Not covered: that one is baked
from the grey art at draw time (see below), not read from a file, and it
keeps the flat green.

That second row is the one this mod got wrong twice. Shade 2 is not clothing;
it is the skin. 1.0.0 recoloured shades 2 and 3 both, which turned the face
green with the cap and read as one green blob. 1.1.0 made it `#f8d8a8` and
the face read as a washed-out cream nothing. Under `trueColor` these pixels
are drawn exactly as written and no palette pass follows to make a face out
of them, so shade 2 has to be a real skin tone — and the one that works is
the one measured off the reference, not the one picked from the middle of
the ramp.

### The title figure is coloured, not recoloured

`markVisibleTrueColor` cuts the player's rectangle *out* of the true-colour
region on purpose, so the mon cycling behind him keeps its palette. What is
left is painted **by shade**, and the colour a file carries is thrown away
before it reaches the screen. Handing that draw recoloured art does nothing;
it has to be coloured at the other end.

So the figure keeps the vanilla grey art and **`MEWMON`**, its zone palette,
is overridden instead. That zone is tile rows 10–17, which is not free:

- The **`GAME FREAK` line goes green** with him. That is the cost.
- The **cycling Pokémon is untouched** while its art is true-colour, because
  `markVisibleTrueColor` marks the mon and cuts the figure out of it — the
  palette reaches one and not the other. That holds with any sprite mod on,
  including the one the cart pins. Switch them all off and the title mon
  goes green too, which is what the `TITLE FIGURE` row is for.

### …except under `ADVANCED`, where he is baked

`ADVANCED` (`PaletteFX.mode` `redpp`) does not run the zone pass over that
rectangle, so `MEWMON` never reaches him — and the cart's own
[Crystal Animated Sprites][crystal] marks the rectangle true-colour there
and luminance-bakes his grey art to Red's white / skin / red / navy, so he
is not left raw grey. That bake is downstream of every seam this mod has,
which is why the figure stayed red on that screen through 1.3.0 no matter
what was done to the art or the palette.

1.4.0 does the same bake in this mod's four. It wraps
`TitleState.currentSprite` from *outside* — this mod is priority 1300 and
loads last, so its wrapper goes on over theirs — captures the untouched grey
art on the way in, before the red bake happens, and paints that green on the
way out, in the same white / light green / green / black the trainer card
uses. Out of `ADVANCED` it hands the grey art back and `MEWMON` has him
again.

Reading those pixels back is not one call: under LÖVE 11 a graphics `Image`
does not keep the `ImageData` it was built from, so the art is drawn into a
canvas of its own size and read back from there, with the canvas, blend
mode, draw colour and transform stack all put back afterwards — that draw
can happen mid-frame. 1.4.0 called `getData`, gave up when it was not there,
and changed nothing on screen; 1.6.0 is where the figure actually turns
green.

It is the mod's one engine internal, and the reason it declares
`engine_internals` — `src.ui.TitleState`, `src.render.PaletteFX` and
`src.render.Assets`, whose `resolve` is what turns an
`assets/generated/...` path into the derived file a transform wrote. Every step of it is guarded: without the module, without
`love.graphics`, without a clonable `ImageData`, the figure is exactly what
it was before, and nothing else in the mod is affected.

[crystal]: https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals

### Replacing a list, in a registry that appends them

The two naming lists are `field.boot.namePresets`, and writing them is not
one patch. The field registry's semantics are `deep`
(`src/mods/Schemas.lua`), and under deep semantics `Merge.deepMerge`
**concatenates** arrays instead of replacing them. So a single patch
carrying three names appends them to vanilla's three, and the `NEW NAME`
page offers six — `RED / ASH / JACK / WILD / GREEN / VERSION`, with ours at
the back. That is what 1.19.0 shipped.

`mod.DELETE` unsets a key. Unsetting `namePresets` in one op and writing it
in the next lands the write on an absent list, which the merge copies
wholesale rather than extending — `Registry.fold` walks a mod's ops in
order, so two patches to the same id stay in the order they were made.

The test stub used to record the last payload handed to `patch()`, which
meant every assertion read what this mod *meant* rather than what the game
would get. It folds now, with vanilla's own lists seeded underneath, and
asserts the whole list rather than its first entry — the old assertions
passed happily on a six-name menu because `presets[1]` was still `WILD`.

### The sideburn does not flicker

Vanilla draws the tip of the hair between the cap and the ear as one pixel,
and does not draw it the same in both forward-facing walk frames — skin in
the one with his arms out, ink in the other. In the grey art that is a light
pixel alternating with a black one against a grey cap, which reads as
shading. Here shade 2 is flesh and shade 3 is a green cap, so the same two
pixels swing between orange and black and read as the hair flickering as he
walks.

So it is held to skin in both frames. Nothing is darkened: the frame that
already draws them skin is untouched, and only the frame that draws them ink
is repainted.

Telling that pixel from the hairline above the eye in the *profile* frames —
which is hair and must stay black — takes eleven conditions, because the
obvious ones are true of both: ink, cap above, face below, ink either side.
What is only true of the sideburn is the **ear**. On the row below, looking
outward, there is an outline pixel, then one pixel of skin, then outline
again; and the cheek runs the *other* way for at least four pixels, which is
what says this is the head's outer edge rather than somewhere in the middle
of it. Both halves are load-bearing: the test sheet carries a hairline with a
cheek and no ear, and an ear with no cheek behind it, and drop either half of
the rule and one of them turns to flesh.

### The mouth is not clothing, and the bill is not skin

Red's overworld mouth is one block of the *cap's* colour sitting in the
middle of his face, so a flat shade remap paints it with the clothes — green
lips. It cannot be told apart by shade, because it is the same shade; only by
where it sits. A shade-3 pixel with skin on both sides of it in the same row
is enclosed by face and is not clothing.

**In profile that is not true of it.** Read off the walking frames, the
sideways mouth is a single pixel with skin on one side and the silhouette's
own outline on the other, so the both-sides test missed it and the lips came
out green whenever he faced left or right. What is still true there is what
sits *above*: cheek. The cap is never under skin, and the collar has the
chin's black above it rather than the chin. The one exception is the hat's
own bill, which is skin and sits directly over the cap's bottom row, so a
bill pixel does not count as a face — the test fixture has exactly that
pixel, with skin beside it too.

Either way it is painted in the lips'
colour instead. That colour is vanilla's own: Red's mouth is drawn in the
*cap's* shade, which is why it comes out red and reads as lips at all.
Painting it skin, as 1.1.2 did, does not fix it so much as delete it. The cap
and the clothes are bounded by black, never by skin, so they are never caught
by the rule.

The bill of the cap is the same problem the other way round. Vanilla draws it
in the *face's* shade — on red Red the bill and the face are the same colour
and nobody notices, but put a green cap above it and the hat reads as having
no bill. A shade-2 pixel sitting directly under a shade-3 one is the bill,
and it goes with the hat.

It is found by **region**: a small patch of the face's shade, touching the
cap, high in its frame. All three, because any two of them catch something
else — small-and-touching is also the hands, touching-and-high is also the
top of the face, small-and-high is whatever else is up there.

And it is painted a green-tinted white rather than the cap's green. Vanilla's
own colour reads as nothing; the cap's green merges it into the hat. This
gives it an edge against both.

The rule runs on the overworld sheets only, where the frames really are a
16px stack and the cap is a handful of pixels. On the 56×56 trainer card
there are dozens of small shade-2 regions touching shade 3 that are shading
rather than a bill.

### The town map draws its own marker, and bakes it

`TownMap` never draws the player. It builds a marker of its own: it reads
`game.data.sprites[field.playerSprites.walk]` and bakes *that* record's image
through `SpriteRenderer.obpImage` (`src/ui/TownMap.lua` `markerSheet`). Two
things follow from that, and both were wrong on this cart.

It never asks the `player.sprite` hook — the thing that makes the walker green
everywhere else — so the marker was the red art on a map where the player is
green in every other frame.

And `obpImage` keys OBJ colour 0 to alpha: `r > 0.83` becomes transparent,
matching real GBC hardware, where sprite palette index 0 unconditionally is.
Wild Green's skin is `0xf0a363` — red channel `0xf0`, over that line — so the
face and the hands came out as holes with the map showing through them.

Neither is a bake this art wants. It is authored full colour and drawn as
written everywhere else — that is what `trueColor` buys — so the marker is
simply the file: `Assets.image` on the green twin of the record's path, a
16x16 quad cut for it, and both handed to the same two fields the engine drew
from. `markPlayerRedraw` replays through those same fields, so the replay over
the map's palette pass follows without a second edit.

A record that is *already* green is passed through rather than declined: the
`sprites` registry patch reaches that record on some datasets, and `greenOf`
returns nil for a path already under the green prefix — so declining would
have fallen back to the engine's bake on exactly the carts where the patch
worked. And a map the engine drew no marker on keeps none: it draws a small
square there instead, and putting a walker where it chose not to is a change
this has no business making.

### The hook has to sit at priority 940

`Hooks:call` walks the chain **highest priority first**, and a link that
returns without calling `next()` ends the chain there. [Crystal Animated
Sprites][crystal] wraps `player.sprite` at **930** and does exactly that:
when its `PLAYER SPRITE` option names a portrait it returns its own file and
never calls `next()`.

At the default priority of `0` this mod's link sat downstream of a chain that
never reached it, which is why the battle back pic, the trainer card, Oak's
intro and the Hall of Fame stayed red through every release from 1.0.0 to
1.1.4. It wraps at **940** now, and computes the swap from the path it is
handed rather than from what downstream answers.

The cost belongs to the `PLAYER` row: on `GREEN` a portrait chosen in
`CRYSTAL SPRITES > PLAYER SPRITE` no longer applies to the player. `RED`
hands it back. Opponent portraits, the animated battle sprites and the shiny
work are untouched either way — this link only ever answers for the player.

[crystal]: https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals

**The title band** is lettering on white, not a sprite, so it gets its own —
but it is lettered in the character's own green, because the words sit
directly above the character wearing it:

| | | |
|---|---|---|
| letter | `#65ba3f` | the `VERSION` lettering — the outfit itself |
| shadow | `#14571f` | one pixel down and right, **and the cartridge shell** |

Two tones rather than one, the way the vanilla ribbon is built. The letter on
its own is about 2.4:1 against white paper, which is thin for 8px type; the
shadow under it is 8.7:1, and that edge is what the eye reads the stroke by.
Through 0.3.0 the two were the other way round — the word in `#14571f` and a
lighter green above it — and the version line came out visibly darker than the
character standing beneath it.

In the other eight suits the letter is that suit's outfit, capped so it is
never paler than green's; the cap binds on `YELLOW` and `WHITE` only.

They are written out three times — once in Python, twice in Lua — because
none of the three can import from the others: the transform runs in a sandbox
with no `require`, an entry chunk cannot require its own files, and the tools
are Python. [`tools/check.py`](tools/check.py) fails the build if they drift
apart.

`tools/palette.py` and `tools/ribbon.py` are carried in the [cart's repo][cart]
too, because the cartridge's shell and the label's version line are drawn from
the same four numbers and the same 5×7 face. Change one, change both.

## Alongside other mods

`crystal_animated_sprites_with_shiny_visuals` is an optional dependency, not
a fork. It ships its own player portraits and its own `PLAYER SPRITE` row;
this mod does not touch them, and with both installed you get its Crystal
artwork with this mod's overworld and title work around it.

More generally, a walker whose art is not the vanilla path is left where it
points. If another mod has already reskinned the player, this one declines
rather than fighting it.

## Tests

```sh
python3 tools/check.py             # the palettes agree, the ribbon is current
luajit tests/wild_green_test.lua   # what the mod actually does
```

Stands up the loader's `mod` table and the asset sandbox's `ctx`, runs the
real files against them, and checks everything settled before a pixel is
drawn — including that `PLAYER = RED` writes no character patch at all.

## Credits

- **distilledorion-sketch** — [Crystal Animated Sprites with Shiny
  Visuals](https://github.com/distilledorion-sketch/crystal_animated_sprites_with_shiny_visuals),
  which this is meant to sit beside rather than replace.
- **Gen1Recomp** — the mod API, the asset-transform sandbox this recolor runs
  in, and the title screen it draws on.
- **pret** — the disassemblies underneath all of it.

## Licence

MIT, same as the rest of the suite. See [LICENSE](LICENSE).

[cart]: https://github.com/wild1walker/Gen1WildGreen
