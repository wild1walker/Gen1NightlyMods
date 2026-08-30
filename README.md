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
| **[`cart.json`](cart.json)** | the **Wild Green Nightly** cart: the nightly mods pinned together with the stable [Gen1WildQOL][qol] and Crystal animated sprites | — |

The quality-of-life half is not forked. Nothing in the current work touches it,
and a fork with no changes in it is a fork that only rots — the nightly cart
pins the released [Gen1WildQOL][qol] exactly as the stable cart does.

## How a nightly is built

The whole channel shares **one version**, and that is the design rather than a
convenience. cartkit resolves a pin by looking for the tag `v<version>` and, on
it, an asset named exactly `<mod id>-<version>.zip` — so several mods can ride
one release, be told apart by asset name, and go out together with the cart
that pins them. `tools/check.py` fails if any manifest disagrees.

```
python3 tools/check.py       everything below, in one command
python3 tools/pack.py        build mods/ into dist/, re-pin cart.json to it
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

### `UI THEME`: `LIGHT`, `DARK`, `COLORFUL*`

`START > OPTION > UI THEME`. `LIGHT` is the default and is what every build
before this one looked like.

Every page the suite draws is black and white on purpose — the art is the
game's own four DMG shades, and the colour arrives afterwards from the SGB
pass. So a theme swaps the four colours a zone carries and nothing else.
Nothing is redrawn, no screen is edited, and a theme that cannot move a glyph
cannot move a glyph off the screen.

**`DARK`** reverses every zone on the page: paper black, ink white, the shades
between them exchanged. **`COLORFUL`** tints each page by what the screen is —
the Pokédex red, the box blue, the party green, the bag leather — and colours
the suite's own cards by what they open. It wears an asterisk because it is not
finished: the battle command grid's four buttons sit over a battle rather than
over a black-and-white page, which is a different mechanism, and they are next.

## Licence

MIT, like everything it is forked from. See [LICENSE](LICENSE).

[cart]: https://github.com/wild1walker/Gen1WildGreen
[index]: https://github.com/wild1walker/Gen1NightlyIndex
[green]: https://github.com/wild1walker/Gen1MakeItGreen
[ui]: https://github.com/wild1walker/Gen1WildUI
[qol]: https://github.com/wild1walker/Gen1WildQOL
