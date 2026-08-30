#!/usr/bin/env python3
"""Find the nightly ids a promotion has not renamed yet.

    python3 tools/promote.py --check    fail if any nightly id is left

The fork carries an id of its own so it can sit beside its stable twin.  That
rename is the whole of promotion, and a half-done one fails SILENTLY: a
registry lookup that cannot find its mod does exactly what it is supposed to
do, which is nothing, quietly.  0.13.0 and 0.15.0 were both that mistake in the
forward direction -- see PROMOTING.md.

So this is a grep with an opinion.  It reads nightly.json for the fork map,
then reports every remaining mention of a forked id in the files that decide
who finds whom.  It is deliberately dumb: no rewriting, no guessing which
mentions are fine, just the list and a non-zero exit.

On the nightly channel itself every one of these is CORRECT, so a bare run
here reports them all and says so.  It is `--check`, run from a promotion
branch, that treats them as failures.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MODS = ROOT / "mods"

# Where an id decides behaviour rather than reads as prose.  A CHANGELOG that
# says "gen1_wild_ui_nightly" is a record of what happened and is left alone.
FILES = ("features.lua", "manifest.json")
ROOT_FILES = ("cart.json", "nightly.json")


def forks():
    """nightly id -> stable id, from nightly.json."""
    state = json.loads((ROOT / "nightly.json").read_text(encoding="utf-8"))
    out = {}
    for nightly, fork in (state.get("forks") or {}).items():
        upstream = fork.get("upstream_id")
        if upstream:
            out[nightly] = upstream
    return out


def hits(pairs):
    """(path, line number, line, nightly id) for every mention left."""
    found = []
    paths = [ROOT / name for name in ROOT_FILES]
    for mod in sorted(p for p in MODS.iterdir() if p.is_dir()):
        paths.extend(mod / name for name in FILES)
    for path in paths:
        if not path.is_file():
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8")
                                      .splitlines(), 1):
            for nightly in pairs:
                if nightly in line:
                    found.append((path.relative_to(ROOT), number,
                                  line.strip(), nightly))
    return found


def main(argv):
    checking = "--check" in argv
    pairs = forks()
    if not pairs:
        print("promote: nightly.json declares no forks", file=sys.stderr)
        return 1

    # The bench is not a fork of anything -- it has no stable twin and is not
    # pinned by a stable cart, so its id is never renamed.  See PROMOTING.md.
    found = hits(pairs)

    if not found:
        print("promote: no nightly ids left; the rename is complete")
        return 0

    for path, number, line, nightly in found:
        print("%s:%d: %s  (-> %s)" % (path, number, line, pairs[nightly]))

    print()
    print("%d mention(s) of %d forked id(s)" % (len(found), len(pairs)))
    if not checking:
        print("On the nightly channel every one of these is correct.")
        print("Run with --check from a promotion branch to treat them as "
              "failures.")
        return 0
    print("Each one has to become the stable id before this can be released.",
          file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
