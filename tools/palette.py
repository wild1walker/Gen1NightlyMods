#!/usr/bin/env python3
"""The nightly channel's own colours, on top of the mod's.

The stable cart carries its palette twice -- once in `wild1walker/Gen1WildGreen`
and once in `wild1walker/Gen1MakeItGreen` -- because neither repository can
import from the other, and its `tools/check.py` fetches the far copy over the
network to prove the two have not drifted.

This channel does not have that problem.  The cart and the mod are in the same
tree, so this file IMPORTS the mod's palette rather than copying it, and there
is no twin to keep honest:

    mods/wild_green_nightly/tools/palette.py    the one copy

What is added here is the two colours that belong to the CHANNEL rather than
to the character -- the nightly cartridge's shell, and the purple its label art
is recoloured to.

    python3 tools/palette.py     print them
"""

import importlib.util
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOD = ROOT / "mods" / "wild_green_nightly"
TWIN = MOD / "tools" / "palette.py"

# By path and under a name of its own, not by putting the mod's tools on
# sys.path: that directory holds a `palette.py` too -- the one being imported
# -- and adding it would leave two modules answering to `palette`, with which
# one won decided by import order.  This way the name says which file it is.
_spec = importlib.util.spec_from_file_location("wild_green_palette", TWIN)
if _spec is None or _spec.loader is None:              # pragma: no cover
    raise SystemExit("tools/palette.py: no mod palette at %s" % TWIN)
mod_palette = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mod_palette)

INK = mod_palette.INK
OUTFIT = mod_palette.OUTFIT
PAPER = mod_palette.PAPER
PIC_RAMP = mod_palette.PIC_RAMP
RAMP = mod_palette.RAMP
SKIN = mod_palette.SKIN
SUITS = mod_palette.SUITS
SUIT_ORDER = mod_palette.SUIT_ORDER
TITLE_LETTER = mod_palette.TITLE_LETTER
TITLE_SHADOW = mod_palette.TITLE_SHADOW
TITLE_RAMP = mod_palette.TITLE_RAMP
TITLE_SUITS = mod_palette.TITLE_SUITS
WORDMARK_BLUE = mod_palette.WORDMARK_BLUE
WORDMARK_YELLOW = mod_palette.WORDMARK_YELLOW
hexof = mod_palette.hexof
suit_ramp = mod_palette.suit_ramp
suit_pic_ramp = mod_palette.suit_pic_ramp
title_ramp = mod_palette.title_ramp

# ------- the nightly cartridge
#
# A nightly build has to be tellable from the stable one across a shelf of
# cartridges, and the launcher draws a cart as its shell colour with its label
# on it -- so the shell is the whole of that signal and it should not be a
# shade of the same green.
#
# It is not picked by eye either.  `TITLE_SUITS["purple"]`'s shadow is already
# in the palette: it is the colour that sits under PLAYER = PURPLE's version
# ribbon, derived by the same rule every other suit's is, and its relative
# luminance is 0.260 against the green shell's 0.269.  So the nightly
# cartridge is exactly as dark as the stable one, in the palette's own purple,
# and neither number was chosen for this.
#
# The pair is (letter, shadow) and the shadow is the second of the two, which
# is where the stable shell reads its own number from as well.  0.4.0 changed
# what the FIRST of the two is -- the letter became the character's own outfit
# -- and deliberately left the second alone, so no cartridge changed colour.
NIGHTLY_INK = TITLE_SUITS["purple"][1]
NIGHTLY_MID = TITLE_SUITS["purple"][0]

SHELL = "#%02x%02x%02x" % NIGHTLY_INK

# The hue the label art's green swirl is rotated to, in degrees.  Read off
# NIGHTLY_INK rather than typed, so the plastic and the sticker cannot end up
# two different purples.
def _hue(rgb):
    r, g, b = (channel / 255.0 for channel in rgb)
    high, low = max(r, g, b), min(r, g, b)
    span = high - low
    if span == 0:
        return 0.0
    if high == r:
        return (60 * ((g - b) / span)) % 360
    if high == g:
        return 60 * (2 + (b - r) / span)
    return 60 * (4 + (r - g) / span)


NIGHTLY_HUE = _hue(NIGHTLY_INK)

if __name__ == "__main__":
    print("%-12s %s" % ("OUTFIT", hexof(OUTFIT)))
    print("%-12s %s" % ("TITLE_LETTER", hexof(TITLE_LETTER)))
    print("%-12s %s   (the stable cart's shell)"
          % ("TITLE_SHADOW", hexof(TITLE_SHADOW)))
    print("%-12s %s" % ("NIGHTLY_MID", hexof(NIGHTLY_MID)))
    print("%-12s %s" % ("NIGHTLY_INK", hexof(NIGHTLY_INK)))
    print("%-12s %s" % ("SHELL", SHELL))
    print("%-12s %.1f deg" % ("NIGHTLY_HUE", NIGHTLY_HUE))
