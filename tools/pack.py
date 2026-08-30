#!/usr/bin/env python3
"""Pack each nightly mod into the .zip the game installs, and pin the cart to it.

    python3 tools/pack.py             build dist/, then rewrite cart.json's pins
    python3 tools/pack.py --check     build and compare; fail if cart.json differs
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

Exits non-zero under --check if the committed cart.json is not what a build
produces, which is what CI wants.
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
CART = ROOT / "cart.json"

# One timestamp for every entry in every archive, forever.  Any fixed value
# does; this is the DOS epoch zipfile itself falls back to.
FIXED_TIME = (1980, 1, 1, 0, 0, 0)

# Files that are for the repository rather than for the game.  A mod's own
# tests and tools are the clearest case: they are how the source is kept
# honest and they are dead weight inside an archive the launcher unpacks.
SKIP_DIRS = {".git", "__pycache__", ".build-check", "dist"}
SKIP_SUFFIXES = {".pyc"}


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

    cart = json.loads(CART.read_text(encoding="utf-8"))
    before = json.dumps(cart, indent=2, ensure_ascii=False) + "\n"
    after = json.dumps(pin(cart, built), indent=2, ensure_ascii=False) + "\n"

    if args.check:
        if before != after:
            print("pack: cart.json does not pin what a build produces; run "
                  "python3 tools/pack.py", file=sys.stderr)
            return 1
        print("pack: cart.json pins exactly what a build produces")
        return 0

    if before != after:
        CART.write_text(after, encoding="utf-8")
        print("pack: rewrote %s" % CART.relative_to(ROOT))
    else:
        print("pack: %s already current" % CART.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
