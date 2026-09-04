#!/usr/bin/env python3
"""Pack each nightly mod into the .zip the game installs, and pin the cart to it.

    python3 tools/pack.py             build dist/, then re-pin every cart
    python3 tools/pack.py --check     build and compare; fail if a cart differs
    python3 tools/pack.py --no-pin    build only

Two jobs, together because the second needs the first's bytes.

------- the archives

`mods/<id>/` becomes `dist/<id>-<version>.zip`, with every file at the archive
root and `manifest.json` among them.  That is one of the two shapes the game
accepts on `MODS > Import mod .zip` (`src/mods/LauncherMods.lua` locateRoot:
a manifest at the root, or inside a single top-level folder), and it is the
one the stable mods' own release workflow writes, so a nightly installs by
hand exactly the way a release does.

The archives are byte-for-byte reproducible: names sorted, one fixed
timestamp, one fixed compression level, no extra attributes.  That is not
tidiness -- it is what makes the pins below mean anything.  A zip whose bytes
depend on the machine that built it has a different sha256 every run, and a
cart pinned to it would be re-pinned on every release whether or not a single
mod file had changed.

------- the pins

A cart is a manifest: `cart.json` names each mod, the version it wants, and
the sha256 of the archive that version IS.  In the stable cart those archives
live in other repositories and cartkit resolves them over the network.  Here
the cart and the mods are the same repository and are released together, so
the digest is computed from the file this script just wrote, and the release
workflow runs this before it packs the cart.

The nightly channel gives every mod in it ONE version -- the channel's --
which is why all of them can share a release tag.  cartkit resolves a github
pin by looking for the tag `v<version>` and, on it, an asset named exactly
`<mod id>-<version>.zip`, so several mods on one tag are told apart by asset
name and never collide.

Every cart the channel ships is re-pinned, not only the root one: they ride
one release and therefore one set of archives, so a cart left behind would
pin a version that exists to bytes that do not.  tools/carts.py is the list.

Exits non-zero under --check if a committed cart is not what a build produces,
which is what CI wants.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
MODS = ROOT / "mods"
DIST = ROOT / "dist"

sys.path.insert(0, str(ROOT / "tools"))

import carts  # noqa: E402  (after sys.path, like every tool here)

# One timestamp for every entry in every archive, forever.  Any fixed value
# does; this is the DOS epoch zipfile itself falls back to.
FIXED_TIME = (1980, 1, 1, 0, 0, 0)

# Files that are for the repository rather than for the game.  A mod's own
# tests and tools are the clearest case: they are how the source is kept
# honest and they are dead weight inside an archive the launcher unpacks.
#
# That sentence has been here since the channel was stood up and the set below
# did not act on it: `tests`, `tools` and `maintained` all rode every release
# from 0.3.0 to 0.24.0.  Measured on 0.24.0 it was 137 KB of the UI bundle's
# 1178, 80 of QOL's 769, 35 of Wild Green's 112 and 3 of the bench's 15 --
# about a quarter of a megabyte per release of files the launcher unpacks onto
# a phone and nothing ever opens.
#
#   tests/       every suite in the channel.  Run from the repo, by CI and by
#                hand; there is no runner inside the game to run them.
#   tools/       check.py, the packers, the art recipes.  Python, in a Lua
#                sandbox that cannot execute it.
#   maintained/  the SOURCE of a module the tree owns.  `modules/` is the copy
#                the bundle loads (runtime/bundle.lua builds every entry path
#                as `modules/<dir>/<entry>`), so shipping both ships it twice.
#   upstream/    submodules: somebody else's mod at a pin, vendored into
#                modules/ the same way.
#
# The line to hold: if the game can reach a file through `mod:read`, it is not
# in this set.  Every path any feature reads is under modules/ or assets/,
# which is what tools/check.py's "reads:" line already verifies on every run.
SKIP_DIRS = {".git", "__pycache__", ".build-check", "dist",
             ".github", "tests", "tools", "maintained", "upstream"}
SKIP_SUFFIXES = {".pyc"}

# And one file, by the same rule and for the same reason the paragraph above
# was written: nothing in the game can reach a CHANGELOG.  It is the only
# shipped file that grows without bound -- 148 KB of the UI bundle at 0.31.18,
# more than every PNG in Gen1Dex put together, and a few KB longer after every
# release -- and it is read by people, on GitHub, where the releases already
# publish it.
#
# README.md stays.  It is twenty kilobytes, it does not grow, and a mod folder
# somebody has unzipped should say what it is.
#
# The CREDITS and THIRD_PARTY_NOTICES files stay too, and would even if they
# were larger: those are licence terms travelling with the code they cover.
SKIP_FILES = {"CHANGELOG.md"}


def mod_dirs():
    if not MODS.is_dir():
        return []
    return sorted(p for p in MODS.iterdir()
                  if p.is_dir() and (p / "manifest.json").is_file())


def manifest_of(directory):
    return json.loads((directory / "manifest.json").read_text(encoding="utf-8"))


def files_of(directory):
    """Everything the archive carries, in one sorted order on every machine."""
    out = []
    for path in directory.rglob("*"):
        if not path.is_file():
            continue
        parts = path.relative_to(directory).parts
        if any(part in SKIP_DIRS for part in parts):
            continue
        if path.suffix in SKIP_SUFFIXES:
            continue
        # at the mod's root only: a module that ships its own CHANGELOG is
        # somebody else's file travelling with their code, and stays
        if len(parts) == 1 and parts[0] in SKIP_FILES:
            continue
        out.append(path)
    # by POSIX path, so a case-insensitive filesystem cannot reorder them
    return sorted(out, key=lambda p: p.relative_to(directory).as_posix())


def pack_one(directory):
    manifest = manifest_of(directory)
    mod_id = str(manifest.get("id", ""))
    version = str(manifest.get("version", ""))
    if not mod_id or not version:
        raise SystemExit("%s: manifest has no id/version" % directory.name)
    if mod_id != directory.name:
        raise SystemExit("%s: manifest id is %r; the directory must be named "
                         "after the mod so an asset name can be derived from "
                         "either" % (directory.name, mod_id))

    DIST.mkdir(exist_ok=True)
    out = DIST / ("%s-%s.zip" % (mod_id, version))
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in files_of(directory):
            name = path.relative_to(directory).as_posix()
            info = zipfile.ZipInfo(name, FIXED_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            zf.writestr(info, path.read_bytes())

    digest = hashlib.sha256(out.read_bytes()).hexdigest()
    return {"id": mod_id, "version": version, "asset": out.name,
            "sha256": digest, "size": out.stat().st_size}


def pin(cart, built):
    """Point every same-repo pin at what was just built.  Returns the cart."""
    by_id = {entry["id"]: entry for entry in built}
    for entry in cart.get("mods", []):
        found = by_id.get(entry.get("id"))
        if not found:
            continue                       # a mod from somebody else's repo
        entry["version"] = found["version"]
        entry["sha256"] = found["sha256"]
    return cart


def main(argv):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true",
                        help="fail if cart.json is not what a build pins")
    parser.add_argument("--no-pin", action="store_true",
                        help="build the archives and leave cart.json alone")
    args = parser.parse_args(argv[1:])

    directories = mod_dirs()
    if not directories:
        print("pack: no mods under %s/" % MODS.relative_to(ROOT))
        return 1

    built = []
    for directory in directories:
        result = pack_one(directory)
        built.append(result)
        print("  %-28s %8d bytes  %s"
              % (result["asset"], result["size"], result["sha256"][:16]))

    if args.no_pin:
        return 0

    # Every cart in the channel, not just the root one: they share a release
    # and therefore share the archives these digests are of, so a cart left
    # un-repinned would pin a version that exists to bytes that do not.
    stale = []
    for cart in carts.carts():
        before = cart.dumps()
        pin(cart.data, built)
        after = cart.dumps()
        if before == after:
            if not args.check:
                print("pack: %s already current" % cart.where)
            continue
        stale.append(cart.where)
        if not args.check:
            cart.write()
            print("pack: rewrote %s" % cart.where)

    if args.check:
        if stale:
            print("pack: %s does not pin what a build produces; run "
                  "python3 tools/pack.py" % ", ".join(stale), file=sys.stderr)
            return 1
        print("pack: every cart pins exactly what a build produces")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
