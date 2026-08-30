#!/usr/bin/env python3
"""Draw label.png: the Wild Green Nightly cartridge art.

    python3 tools/make_label.py

The label is the picture the launcher puts on the cartridge, so it is the one
place the cart says what it is -- and for a nightly build, saying what it is
matters more than it does for a release.  Somebody with both installed has two
cartridges on the shelf and has to be able to tell at a glance which one they
are about to open.

So this is the stable cart's own artwork with two things done to it:

  * the green swirl behind the wordmark is rotated to the channel's purple
    and darkened, which is what makes the cartridge read as the other one at
    thumbnail size; and
  * NIGHTLY is drawn under WILD GREEN VERSION, which is what says which one
    it is when you are close enough to read it.

Everything else is left exactly where it was.  The Gen1Wild wordmark keeps its
yellow and its blue outline, and WILD GREEN VERSION keeps its white -- this is
the same cart, on a different channel, and a label that recoloured the branding
too would be advertising a different game.

The recolour is by HUE WINDOW, not by replacing a colour.  The swirl is a
gradient of dozens of greens with soft edges, so nothing here can name them;
what it can say is which hues are the swirl (58 to 155 degrees, at any
saturation worth calling a colour) and which are not.  The wordmark's yellow
sits at 45.6 degrees and its outline blue at 218, so both fall outside the
window and neither is touched -- and the white lettering has no saturation to
speak of and falls out on that test instead.

`NIGHTLY` is lettered with the mod's own 5x7 face
(`mods/wild_green_nightly/tools/ribbon.py`), the same one that draws
WILD GREEN VERSION on the title screen, so the two say the word the same way.
It is scaled by an integer factor with nearest-neighbour, outlined by dilating
its own mask, and filled white on the channel's dark purple -- which is how
the lettering above it is drawn, and is what keeps it legible against a swirl
that is light in places and dark in others.

Determinism: one pass over a committed PNG with no randomness, an integer-scaled
blit, one LANCZOS resize and a fixed encoder setting.  tools/check.py re-runs
this and compares the bytes, so a label that no longer matches its source fails
CI rather than shipping.
"""

import colorsys
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

try:
    from PIL import Image
except ImportError:                                    # pragma: no cover
    raise SystemExit("make_label needs Pillow: pip install pillow")

# The channel palette first, and only then the mod's tools on the path: both
# directories hold a `palette.py`, and this way the one already imported is
# the one that stays imported.  tools/palette.py loads the mod's copy by path
# for the same reason and says so.
from palette import NIGHTLY_HUE, NIGHTLY_INK           # noqa: E402

sys.path.insert(0, str(ROOT / "mods" / "wild_green_nightly" / "tools"))
import ribbon                                          # noqa: E402

ART = ROOT / "art" / "wild_green_nightly_label_source.png"
OUT = ROOT / "label.png"

SIZE = 256          # the launcher draws the label square

# The swirl, and nothing else: the wordmark's yellow is at 45.6 degrees and
# its outline blue at 218, so both sit outside; the white lettering fails the
# saturation test instead.
HUE_LOW, HUE_HIGH = 58.0, 155.0
MIN_SATURATION = 0.18

# How far down the swirl goes.  A nightly cartridge should read as the darker
# of the two on a shelf, and the stable shell is already a dark green -- so the
# purple is taken below it rather than merely beside it.
VALUE_SCALE = 0.62
SATURATION_SCALE = 1.05

WORD = "NIGHTLY"
WORD_SCALE = 13                 # 5x7 glyphs at 13x: a 546px word on a 1254px label
WORD_BOTTOM_MARGIN = 116        # pixels of swirl left under it


def recoloured(image):
    """The swirl in the channel's purple, everything else untouched."""
    width, height = image.size
    source = image.load()
    out = Image.new("RGB", (width, height))
    target = out.load()
    hue = NIGHTLY_HUE / 360.0
    for y in range(height):
        for x in range(width):
            r, g, b = source[x, y]
            h, s, v = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
            degrees = h * 360.0
            if HUE_LOW <= degrees <= HUE_HIGH and s > MIN_SATURATION:
                nr, ng, nb = colorsys.hsv_to_rgb(
                    hue, min(1.0, s * SATURATION_SCALE), v * VALUE_SCALE)
                target[x, y] = (int(nr * 255 + 0.5), int(ng * 255 + 0.5),
                                int(nb * 255 + 0.5))
            else:
                target[x, y] = (r, g, b)
    return out


def word_mask(text):
    """The word as a set of (x, y) cells, and the grid it fills."""
    placed, width = ribbon.layout(text)
    cells = set()
    for x0, glyph in placed:
        for row, bits in enumerate(glyph):
            for col, bit in enumerate(bits):
                if bit == "#":
                    cells.add((x0 + col, row))
    return cells, width, ribbon.GLYPH_H


def outlined(cells):
    """The one-cell ring around a mask, which is where the dark goes."""
    ring = set()
    for x, y in cells:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                neighbour = (x + dx, y + dy)
                if neighbour not in cells:
                    ring.add(neighbour)
    return ring


def stamp(image, text):
    """Letter `text` across the bottom of the label, white on the dark purple."""
    cells, width, height = word_mask(text)
    ring = outlined(cells)

    scale = WORD_SCALE
    label_w, label_h = image.size
    left = (label_w - width * scale) // 2
    top = label_h - WORD_BOTTOM_MARGIN - height * scale

    pixels = image.load()

    def block(cx, cy, colour):
        x0, y0 = left + cx * scale, top + cy * scale
        for y in range(y0, y0 + scale):
            if y < 0 or y >= label_h:
                continue
            for x in range(x0, x0 + scale):
                if 0 <= x < label_w:
                    pixels[x, y] = colour

    # the ring first, so a letter sits on top of its own outline rather than
    # having to be drawn around it -- the same order tools/ribbon.py draws in
    for cx, cy in sorted(ring):
        block(cx, cy, NIGHTLY_INK)
    for cx, cy in sorted(cells):
        block(cx, cy, (255, 255, 255))
    return image


def main():
    if not ART.exists():
        raise SystemExit("no cartridge art at %s" % ART)

    art = Image.open(ART).convert("RGB")
    if art.width != art.height:
        raise SystemExit("make_label: %s is %dx%d; the label is square"
                         % (ART.name, art.width, art.height))

    art = stamp(recoloured(art), WORD)
    art.resize((SIZE, SIZE), Image.LANCZOS).save(OUT, optimize=True)
    print("wrote %s  %dx%d  %d bytes"
          % (OUT.relative_to(ROOT), SIZE, SIZE, OUT.stat().st_size))
    return 0


if __name__ == "__main__":
    sys.exit(main())
