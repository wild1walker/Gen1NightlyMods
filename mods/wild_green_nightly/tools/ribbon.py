#!/usr/bin/env python3
"""The WILD GREEN VERSION lettering: a 5x7 face and the strip it draws.

A library, not a command.  Two things set this wording and they are in two
repositories: the title screen's version ribbon, which is an asset in the
Wild Green mod, and the version line on this cart's label.  They are the
same words in the same face because they come from the same file -- so this
file is carried in both, and each repo's tools/check.py fails if the copies
drift.

Everything here is drawn on the importer's four grey shades (255 / 170 / 85
/ 0) rather than in colour, because the title screen's ribbon band is an SGB
palette zone: `TitleState:sgbPalettes` colours tile rows 8-9 with LOGO1 and
the shader remaps by shade.  Green pixels would be read as shades and
remapped to something else entirely.  Callers that want colour -- the label,
which is a picture and not a palette zone -- map the shades themselves.

No font file is loaded and nothing is measured off the host, so a rebuild on
any machine produces byte-identical output.

    twin: wild1walker/Gen1WildGreen tools/ribbon.py
"""

import struct
import zlib

# Mixed case, because the screen it sits on is: "Red Version".
TEXT = "Wild Green Version"

# the importer's four shades (src/import/ImageWriter.lua), lightest first
PAPER, LIGHT, DARK, INK = 255, 170, 85, 0

# ------- the title face
#
# Traced, pixel for pixel, off the game's own version ribbon.
#
# `Version_GFX` is 80x8 1bpp in the ROM (tools/build_rom_data.py:
# raw_1bpp("Version_GFX", 80, 8, "title/red_version.png")), and the extractor
# writes it to assets/generated/title/red_version.png.  Switching TITLE RIBBON
# off puts that art back on the title screen, which is how these shapes were
# read: a capture at 7x, sampled back down to game pixels.
#
# Three things about it that the face this mod used to draw got wrong, and
# they are the whole of "that is not the right font":
#
#   MIXED CASE.  The game says "Red Version", not "RED VERSION".  This mod
#   shouted its name in a screen that does not shout.
#
#   FIVE ROWS, not seven.  The lettering sits on rows 67-71 of the screen with
#   nothing above or below it inside the band -- checked against the raw
#   pixels rather than a threshold, so it is five and not six.
#
#   VARIABLE WIDTH.  `i` is two columns and `V` is six.  A fixed 5-wide cell
#   cannot draw this face at all.
#
# The letters below marked TRACED are the ROM's, exactly.  W, G and l are not
# in "Red Version" and are drawn here to match: 2-pixel strokes, 1-pixel
# counters, cap height five and x-height four, and V's own way of stepping a
# diagonal inward a row at a time.
TITLE_H = 5

TITLE_FONT = {
    # TRACED
    "R": ("####.", "##.##", "####.", "##.##", "##.##"),
    "V": ("##..##", "##..##", "##..##", ".####.", "..##.."),
    "d": ("...##", ".####", "##.##", "##.##", ".####"),
    "e": ("....", ".###", "##.#", "###.", ".###"),
    "i": ("##", "..", "##", "##", "##"),
    "n": ("....", "###.", "##.#", "##.#", "##.#"),
    "o": (".....", ".###.", "##.##", "##.##", ".###."),
    "r": ("....", "####", "##..", "##..", "##.."),
    "s": (".....", ".####", "###..", "..###", "####."),
    # DRAWN to match -- not in "Red Version"
    #   W is V doubled: the same stems, the same inward step, sharing the
    #   middle pair, which is what puts W's vertex at the top where it belongs.
    "W": ("##..##..##", "##..##..##", "##..##..##", ".########.", "..##..##.."),
    #   G is the cap bowl with a bar into it on the third row.
    "G": (".####.", "##....", "##.###", "##..##", ".####."),
    #   l is i without the dot, which is how this face builds a stem.
    "l": ("##", "##", "##", "##", "##"),
}

# Between letters, and between words: both measured off the ROM art.  R ends
# at column 60 and e starts at 62, so a letter gap is one column; d ends at 71
# and V starts at 80, so a word is worth eight.
TITLE_GAP = 1
TITLE_SPACE = 8

GLYPH_W, GLYPH_H = 5, 7
GAP = 1          # between glyphs
SPACE = 3        # a word gap, on top of the glyph gap
HEIGHT = 8       # 1 blank row, 5 glyph rows, 2 blank -- which is the
                 # height Version_GFX itself is

FONT = {
    "A": (".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"),
    "B": ("####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."),
    "C": (".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."),
    "D": ("####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."),
    "E": ("#####", "#....", "#....", "####.", "#....", "#....", "#####"),
    "F": ("#####", "#....", "#....", "####.", "#....", "#....", "#...."),
    "G": (".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."),
    "H": ("#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"),
    "I": ("#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"),
    "J": ("..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."),
    "K": ("#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"),
    "L": ("#....", "#....", "#....", "#....", "#....", "#....", "#####"),
    "M": ("#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"),
    "N": ("#...#", "##..#", "##..#", "#.#.#", "#..##", "#..##", "#...#"),
    "O": (".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."),
    "P": ("####.", "#...#", "#...#", "####.", "#....", "#....", "#...."),
    "Q": (".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"),
    "R": ("####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"),
    "S": (".####", "#....", "#....", ".###.", "....#", "....#", "####."),
    "T": ("#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."),
    "U": ("#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."),
    "V": ("#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."),
    "W": ("#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"),
    "X": ("#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"),
    "Y": ("#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."),
    "Z": ("#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"),
}


def layout(text):
    """(x, glyph) for every letter, and the width the strip needs."""
    placed, x = [], 0
    for ch in text:
        if ch == " ":
            x += SPACE
            continue
        glyph = FONT.get(ch)
        if glyph is None:
            raise SystemExit("ribbon: no glyph for %r" % ch)
        placed.append((x, glyph))
        x += GLYPH_W + GAP
    # the trailing gap is not part of the ribbon; the shadow column is
    return placed, x - GAP + 1


def title_layout(text=TEXT):
    """Where each glyph goes, and how wide the strip is, in the title face."""
    placed, x = [], 0
    for ch in text:
        if ch == " ":
            x += TITLE_SPACE
            continue
        glyph = TITLE_FONT.get(ch)
        if glyph is None:
            raise SystemExit("ribbon: no title glyph for %r" % ch)
        placed.append((x, glyph))
        x += len(glyph[0]) + TITLE_GAP
    # the trailing gap is not part of the ribbon, and there is no shadow
    # column to keep any more
    return placed, x - TITLE_GAP


def draw(text=TEXT):
    """The strip as (width, rows of shade values)."""
    placed, width = title_layout(text)
    grid = [[PAPER] * width for _ in range(HEIGHT)]

    def put(x, y, shade):
        if 0 <= x < width and 0 <= y < HEIGHT:
            grid[y][x] = shade

    # ONE INK, no shadow -- which is the ROM's own construction and not a
    # simplification of it.  Version_GFX is 1bpp: two colours, and a third is
    # not expressible.  The face this mod used to draw had a letter and a
    # shadow under it, and at seven rows that read as weight; at five it reads
    # as smear, because the shadow is a fifth of the letter's height rather
    # than a seventh and it closes the counters.
    #
    # The letter goes in shade 2, which the band's palette paints the
    # character's own outfit colour (see tools/palette.py).  Shade 3 is left
    # unused by the art now; the palette still carries it because the
    # cartridge shell is that number.
    for x0, glyph in placed:
        for row, bits in enumerate(glyph):
            for col, bit in enumerate(bits):
                if bit == "#":
                    put(x0 + col, 1 + row, LIGHT)
    return width, grid


def png_bytes(width, height, grid):
    """An 8-bit RGB PNG of a grid of shade values."""
    raw = bytearray()
    for row in grid:
        raw.append(0)
        for shade in row:
            raw += bytes((shade, shade, shade))

    def chunk(tag, body):
        return (struct.pack(">I", len(body)) + tag + body
                + struct.pack(">I", zlib.crc32(tag + body) & 0xffffffff))

    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
            + chunk(b"IEND", b""))
