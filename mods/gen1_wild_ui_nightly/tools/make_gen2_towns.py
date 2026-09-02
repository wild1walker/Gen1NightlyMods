#!/usr/bin/env python3
"""Recolour the battle backdrops for Gold, Silver and Crystal's towns.

    python3 tools/make_gen2_towns.py <palettes.lua> [backdrops-dir]

`<palettes.lua>` is `data/generated/palettes.lua` from a Gen 2 import -- the
file the engine writes into its save directory when you import a Gold, Silver
or Crystal cartridge.  It is not in this repository and cannot be: it is
derived from your own ROM.  The engine's own launcher prints where its save
directory is; the file lands under `data/generated/` inside it.

`[backdrops-dir]` defaults to the arena's committed art
(`modules/Gen1Arena/assets/backdrops`).  Output goes to `og/gen2/<town>/`.

------- why this exists, and why it is not new art

A town variant in this mod has never been a drawing.  It is a RECOLOUR: the
FireRed art has exactly two saturated warm colours in it -- the two roof
browns -- and a town variant remaps those onto that town's own roof pair, read
out of the game's data.  Nothing else moves.  That is not a stylistic choice,
it is what the cartridge does: the roofs change from town to town and nothing
else does.

The Gen 1 pipeline (`recolor.py` in the standalone Gen1Arena repo) reads
`world.roofByMapIndex` out of the engine's shipped `data/palettes_gbc.lua`,
which is keyed by Red's eleven city maps.

Gold keeps the same two colours in the same job, one level up: `RoofPals` is
indexed by MAP GROUP and holds a morn/day pair and a night pair, copied over
PAL_BG_ROOF's colours 1 and 2 (`Palettes.bgSet`'s roof block, and
`src/import/RomExtractorGen2.lua:718-726`).  Gold has 26 groups and 22 of them
contain a named town -- which is every town in both regions, because Gold
carries Kanto too.

So all twenty-two variants are generated, by the same two passes, from the
game's own numbers.  No backdrop is drawn for this and none needs to be.

------- why Kanto is regenerated rather than shared

Gold repaints Kanto.  Its Cerulean roof pair is not Red's Cerulean roof pair,
so pointing a Gen 2 boot at the eleven folders this repo already carries would
put Red's roofs on Gold's town.  The Gen 2 set is written under `gen2/` and
the mod looks there on a Gen 2 boot only.

------- the morn/day pair

Gold carries two pairs per group and swaps them at dusk.  This uses the
morn/day one, because a backdrop is loaded once and cached for the run while
the overworld's roofs change under the clock -- so a night pair would be right
for a few hours and wrong for the rest.  The day roofs are also the ones the
art was corrected against.

The two passes below are the same two `recolor.py` runs, kept here rather than
imported because that script lives in another repository and this one has to
be able to rebuild its own art.
"""

from __future__ import annotations

import colorsys
import os
import subprocess
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    sys.exit("this needs Pillow: pip install pillow")

HERE = Path(__file__).resolve().parent
DEFAULT_ART = HERE.parent / "modules" / "Gen1Arena" / "assets" / "backdrops"

# Map group -> the folder its town's art goes in.  The four groups with no
# town in them (9, 15, 19, 20 -- route and dungeon groups) have no entry and
# get no variant, which is right: there is no town there to be the colour of.
GROUP_TOWNS = {
    # Johto
    24: "new_bark", 26: "cherrygrove", 10: "violet", 8: "azalea",
    11: "goldenrod", 4: "ecruteak", 1: "olivine", 22: "cianwood",
    2: "mahogany", 5: "blackthorn",
    # Kanto -- Gold's own roofs, not Red's
    13: "pallet", 23: "viridian", 14: "pewter", 7: "cerulean",
    12: "vermilion", 21: "celadon", 17: "fuchsia", 25: "saffron",
    6: "cinnabar", 18: "lavender", 16: "indigo",
}

# Which slots take which pass.  Identical to the Gen 1 pipeline's.
TOWN_SLOTS = ["town", "trainer_town", "plateau"]
GYM_SLOTS = ["gym", "leader", "trainer_gym"]

# Gen 2 never draws the wide battle: Gold's battle is 160x144 inside
# `Chrome.withPanel` whatever the window is doing, so only `og` is generated.
LAYOUTS = ["og"]

# The art's own roof shades, measured: (206,132,66) light, (140,74,41) dark.
ROOF_HUE = (12, 40)
ROOF_MIN_SAT = 0.55
ROOF_LO, ROOF_HI = 74.0, 152.0
WALL_ROWS = 62


# ---------------------------------------------------------- reading the data
#
# Through luajit rather than a regular expression.  `palettes.lua` is a
# generated file whose exact spacing is the writer's business, and a parser
# that guesses at it breaks the first time the writer is tidied.  Running it is
# exact, and luajit is already required to run this repo's tests.

# The path comes through the environment, not through `...`: a chunk run with
# `luajit -e` gets no script arguments, so `...` is nil there and `loadfile(nil)`
# quietly reads STDIN and hangs.
LUA_DUMP = r"""
local path = assert(os.getenv("GEN2_PALETTES"), "GEN2_PALETTES is not set")
local chunk = assert(loadfile(path))
local data = chunk()
local roofs = data and data.roofs
if type(roofs) ~= "table" then
  io.stderr:write("no `roofs` table in that file\n")
  os.exit(1)
end
for group, entry in pairs(roofs) do
  local pair = entry and entry.mornDay
  local light, dark = pair and pair[1], pair and pair[2]
  if light and dark then
    io.write(("%d\t%d,%d,%d\t%d,%d,%d\n"):format(group,
      light[1], light[2], light[3], dark[1], dark[2], dark[3]))
  end
end
"""


def roof_pairs(palettes: Path):
    env = dict(os.environ, GEN2_PALETTES=str(palettes))
    try:
        out = subprocess.run(
            ["luajit", "-e", LUA_DUMP],
            capture_output=True, text=True, check=True,
            stdin=subprocess.DEVNULL, env=env).stdout
    except FileNotFoundError:
        sys.exit("this needs luajit on PATH to read the generated palettes")
    except subprocess.CalledProcessError as problem:
        sys.exit("could not read %s: %s" % (palettes, problem.stderr.strip()))

    pairs = {}
    for line in out.splitlines():
        group, light, dark = line.split("\t")
        town = GROUP_TOWNS.get(int(group))
        if town:
            pairs[town] = (
                tuple(int(v) for v in light.split(",")),
                tuple(int(v) for v in dark.split(",")),
            )
    return pairs


# ------------------------------------------------------------- the two passes

def luminance(rgb):
    return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]


def gbc_quantize(rgb):
    return tuple(min(255, round(round(v / 255 * 31) / 31 * 255)) for v in rgb)


def recolour_roofs(img, pair):
    """Remap the roof browns onto this town's roof light/dark pair."""
    light, dark = pair
    out = img.convert("RGBA")
    px = out.load()
    w, h = out.size
    cache = {}
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            key = (r, g, b)
            m = cache.get(key)
            if m is None:
                hh, ss, _vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
                deg = hh * 360
                if ROOF_HUE[0] <= deg <= ROOF_HUE[1] and ss >= ROOF_MIN_SAT:
                    t = (luminance(key) - ROOF_LO) / (ROOF_HI - ROOF_LO)
                    t = max(0.0, min(1.0, t))
                    m = gbc_quantize(tuple(
                        round(dark[k] + (light[k] - dark[k]) * t)
                        for k in range(3)))
                else:
                    m = key
                cache[key] = m
            px[x, y] = (m[0], m[1], m[2], a)
    return out


def recolour_walls(img, pair):
    """Rotate the gym wall's reds to the town's roof hue.

    Floor and Poke Ball stay: a whole-scene tint would drag both with it, and
    the ball should read as the same ball in every gym.  The wall separates on
    hue (planks 324-360/0-5, floor 24-31); the row guard exists only because
    the ball's red is the wall's red.
    """
    light = pair[0]
    th, ts, _ = colorsys.rgb_to_hsv(*[v / 255 for v in light])
    sat_scale = min(1.0, ts * 1.15) if ts > 0.05 else 0.12

    out = img.convert("RGBA")
    px = out.load()
    w, h = out.size
    wall = round(WALL_ROWS * h / 144)
    cache = {}
    for y in range(min(wall, h)):
        for x in range(w):
            r, g, b, a = px[x, y]
            key = (r, g, b)
            m = cache.get(key)
            if m is None:
                hh, ss, vv = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
                deg = hh * 360
                if (deg >= 300 or deg <= 12) and ss > 0.30:
                    m = gbc_quantize(tuple(round(c * 255) for c in
                        colorsys.hsv_to_rgb(th, min(1.0, ss * sat_scale), vv)))
                else:
                    m = key
                cache[key] = m
            px[x, y] = (m[0], m[1], m[2], a)
    return out


# --------------------------------------------------------------------- main

def main() -> int:
    if len(sys.argv) < 2:
        sys.exit(__doc__.strip().splitlines()[2].strip())
    palettes = Path(sys.argv[1])
    if not palettes.is_file():
        sys.exit("no such file: %s\n"
                 "this is data/generated/palettes.lua from a Gen 2 import"
                 % palettes)
    root = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_ART
    if not root.is_dir():
        sys.exit("no backdrops at %s" % root)

    pairs = roof_pairs(palettes)
    if not pairs:
        sys.exit("that file carried no roof pairs for any town group -- is it "
                 "a Gen 2 import's palettes.lua?")

    missing = sorted(set(GROUP_TOWNS.values()) - set(pairs))
    written = 0
    for town, pair in sorted(pairs.items()):
        for layout in LAYOUTS:
            srcdir = root / layout
            if not srcdir.is_dir():
                continue
            dstdir = srcdir / "gen2" / town
            dstdir.mkdir(parents=True, exist_ok=True)
            n = 0
            for slot in TOWN_SLOTS:
                f = srcdir / ("%s.png" % slot)
                if f.exists():
                    recolour_roofs(Image.open(f), pair).save(dstdir / f.name)
                    n += 1
            for slot in GYM_SLOTS:
                f = srcdir / ("%s.png" % slot)
                if f.exists():
                    recolour_walls(Image.open(f), pair).save(dstdir / f.name)
                    n += 1
            written += n
            print("  %-12s roof %s / %s  (%d files)"
                  % (town, pair[0], pair[1], n))

    print("\n%d file(s) into %s/og/gen2/" % (written, root))
    if missing:
        print("no roof pair in that import for: %s" % ", ".join(missing))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
