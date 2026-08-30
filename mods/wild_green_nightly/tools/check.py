#!/usr/bin/env python3
"""Check the things that can quietly drift apart in the mod.

    python3 tools/check.py

Three copies of the Wild Green palette exist in this tree, and they have to
agree:

    tools/palette.py    RAMP, PIC_RAMP and TITLE_RAMP, and what the label
                        is drawn from
    transforms.lua      WILD_GREEN and WILD_GREEN_PIC, what the player's art
                        is recolored to
    main.lua            WILD_GREEN, what MEWMON is overridden with;
                        WILD_GREEN_PIC, what the title figure is baked to;
                        WILD_GREEN_TITLE, what LOGO1 is overridden with

The character ramp and the title ramp are different on purpose: the character
is a sprite whose second shade is skin, and the ribbon is lettering on white.

They are copies rather than one file because none of the three can import
from either of the others: the transform runs in a sandbox with no require,
an entry chunk cannot require its own files, and the tools are Python.  So
the duplication is the design, and this is what makes it safe.

Also checked: `assets/title/wild_green_version.png` is still what
`tools/make_ribbon.py` draws, and it still fits the 160 px screen.

`tools/palette.py` and `tools/ribbon.py` are carried in the cart's repo too
(wild1walker/Gen1WildGreen).  Nothing here can reach that copy; the cart's
own check compares them while the two trees are together.

Exits non-zero on any finding, which is what CI wants.
"""

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from palette import (EXTRA, PIC_RAMP, RAMP, SUITS, SUIT_ORDER,  # noqa: E402
                     TITLE_RAMP, TITLE_SUITS, hexof)

# (file, the table in it, what tools/palette.py says it must be)
RAMPS = (
    ("transforms.lua", "local WILD_GREEN =", RAMP),
    ("transforms.lua", "local WILD_GREEN_PIC", PIC_RAMP),
    ("main.lua", "local WILD_GREEN =", RAMP),
    ("main.lua", "local WILD_GREEN_PIC", PIC_RAMP),
    ("main.lua", "local WILD_GREEN_TITLE", TITLE_RAMP),
)
RIBBON = ROOT / "assets" / "title" / "wild_green_version.png"

# a { 0xff, 0xff, 0xff } row of a Lua colour table
ROW = re.compile(r"\{\s*(0x[0-9a-fA-F]{2})\s*,\s*(0x[0-9a-fA-F]{2})\s*,"
                 r"\s*(0x[0-9a-fA-F]{2})\s*\}")

findings = []


def fail(where, message):
    findings.append("%s: %s" % (where, message))


def lua_ramp(path, marker):
    """The four colours of the table that follows `marker` in a Lua file."""
    text = path.read_text(encoding="utf-8")
    at = text.find(marker)
    if at < 0:
        fail(path.name, "no %r table to check" % marker)
        return None
    rows = ROW.findall(text[at:at + 400])[:4]
    if len(rows) != 4:
        fail(path.name, "the %r table has %d colours, not 4"
             % (marker, len(rows)))
        return None
    return [tuple(int(c, 16) for c in row) for row in rows]


def check_palettes():
    for name, marker, expected in RAMPS:
        ramp = lua_ramp(ROOT / name, marker)
        if ramp is None:
            continue
        if ramp != expected:
            fail(name, "%s is %s; tools/palette.py says %s"
                 % (marker.split()[-1],
                    " ".join(hexof(c) for c in ramp),
                    " ".join(hexof(c) for c in expected)))


def check_extras():
    """The colours that are not shades: MOUTH, told apart by position."""
    text = (ROOT / "transforms.lua").read_text(encoding="utf-8")
    for name, want in EXTRA.items():
        at = text.find("local " + name)
        if at < 0:
            fail("transforms.lua", "no %s to check" % name)
            continue
        found = ROW.findall(text[at:at + 200])
        got = tuple(int(c, 16) for c in found[0]) if found else None
        if got != want:
            fail("transforms.lua", "%s is %s; tools/palette.py says %s"
                 % (name, got and hexof(got), hexof(want)))


def check_suits():
    """The nine suits, in all three files.

    PLAYER offers nine colours and each is three numbers -- the outfit, the
    portrait's light shade and the cap's bill.  The other four of a suit's
    ramp (paper, skin, ink) are shared and are checked above, which is what
    keeps "only the outfit changes" true rather than merely intended.

    transforms.lua writes the files and main.lua colours MEWMON and the title
    bake, so a suit that differs between the two is a title screen in one
    colour and a player in another.  Neither can import tools/palette.py --
    the recipe runs in a sandbox with no require at all -- so this is the
    thing that holds them together.
    """
    listed = re.compile(
        r'\{\s*"([a-z]+)"\s*,\s*' + r"\s*,\s*".join([ROW.pattern] * 3) + r"\s*\}")
    keyed = re.compile(
        r"([a-z]+)\s*=\s*\{\s*" + r"\s*,\s*".join([ROW.pattern] * 3) + r"\s*\}")

    for name, pattern in (("transforms.lua", listed), ("main.lua", keyed)):
        text = (ROOT / name).read_text(encoding="utf-8")
        at = text.find("local SUITS")
        if at < 0:
            fail(name, "no SUITS table to check")
            continue
        found = {}
        for match in pattern.finditer(text[at:at + 4000]):
            groups = match.groups()
            found[groups[0]] = tuple(
                tuple(int(c, 16) for c in groups[1 + i * 3:4 + i * 3])
                for i in range(3))
        if sorted(found) != sorted(SUITS):
            fail(name, "SUITS names are %s; tools/palette.py says %s"
                 % (" ".join(sorted(found)) or "(none)",
                    " ".join(sorted(SUITS))))
            continue
        for suit in SUIT_ORDER:
            if found[suit] != SUITS[suit]:
                fail(name, "suit %s is %s; tools/palette.py says %s"
                     % (suit,
                        " ".join(hexof(c) for c in found[suit]),
                        " ".join(hexof(c) for c in SUITS[suit])))


def check_title_suits():
    """The ribbon band's nine pairs, in main.lua and in tools/palette.py.

    Two colours per suit rather than three -- the shadow and the letter -- and
    a fourth table to keep honest, for the same reason as the other three:
    main.lua cannot import the Python, the Python cannot read the Lua, and a
    pair that drifts is a title screen lettered in one colour on a cart named
    after another.

    Only main.lua carries a copy.  transforms.lua does not: the band is
    lettering on white and no picture is recoloured to it, so the recipe has
    no business knowing these numbers.
    """
    pair = re.compile(
        r"([a-z]+)\s*=\s*\{\s*" + r"\s*,\s*".join([ROW.pattern] * 2) + r"\s*\}")
    text = (ROOT / "main.lua").read_text(encoding="utf-8")
    at = text.find("local TITLE_SUITS")
    if at < 0:
        fail("main.lua", "no TITLE_SUITS table to check")
        return
    found = {}
    for match in pair.finditer(text[at:at + 3000]):
        groups = match.groups()
        found[groups[0]] = tuple(
            tuple(int(c, 16) for c in groups[1 + i * 3:4 + i * 3])
            for i in range(2))
    if sorted(found) != sorted(TITLE_SUITS):
        fail("main.lua", "TITLE_SUITS names are %s; tools/palette.py says %s"
             % (" ".join(sorted(found)) or "(none)",
                " ".join(sorted(TITLE_SUITS))))
        return
    for suit in SUIT_ORDER:
        if found[suit] != TITLE_SUITS[suit]:
            fail("main.lua", "title suit %s is %s; tools/palette.py says %s"
                 % (suit,
                    " ".join(hexof(c) for c in found[suit]),
                    " ".join(hexof(c) for c in TITLE_SUITS[suit])))


ENTRY = re.compile(r'\{\s*"([^"]+)"\s*,\s*(true|false)\s*\}')


def check_pics():
    """The recipe's list and the hook's list are the same list.

    They have to be, name and flag both.  A swap to a green file the recipe
    did not write does not fall back to the red one -- the image fails to
    load and the draw shows nothing at all -- so the hook must only ever name
    a picture the recipe covers.

    The flag is `field`: true is an overworld sheet, false is a portrait.
    The recipe writes a skinned twin for every portrait and the hook points
    PORTRAIT SKIN at exactly those, so a picture the two files disagree about
    is a row that silently does nothing on it, or points at a file that is
    not there.
    """
    recipe = ENTRY.findall(
        (ROOT / "transforms.lua").read_text(encoding="utf-8"))
    text = (ROOT / "main.lua").read_text(encoding="utf-8")
    block = re.search(r"local RECOLOURED = \{(.*?)\n  \}", text, re.S)
    if block is None:
        fail("main.lua", "no RECOLOURED list to compare")
        return
    hook = ENTRY.findall(block.group(1))
    if recipe != hook:
        fail("PICS", "the recipe recolours %s but the hook swaps %s"
             % (recipe, hook))


def check_generated():
    """A rebuild has to produce the bytes that are committed."""
    if not RIBBON.is_file():
        fail("make_ribbon.py", "%s is missing; run it" % RIBBON.name)
        return
    before = RIBBON.read_bytes()
    run = subprocess.run([sys.executable, str(ROOT / "tools" / "make_ribbon.py")],
                         capture_output=True, text=True, cwd=ROOT)
    if run.returncode != 0:
        fail("make_ribbon.py", "exited %d: %s"
             % (run.returncode, run.stderr.strip()))
        return
    if RIBBON.read_bytes() != before:
        fail("make_ribbon.py", "%s is stale; the committed file is not what "
                               "the tool draws" % RIBBON.name)


def main():
    check_palettes()
    check_suits()
    check_title_suits()
    check_extras()
    check_pics()
    check_generated()
    for finding in findings:
        print("check: %s" % finding)
    if findings:
        return 1
    print("check: palettes and all %d suits agree (outfit and band both), "
          "the ribbon is current" % len(SUITS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
