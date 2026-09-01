#!/usr/bin/env python3
"""The channel's own checks: the things that go wrong in a monorepo of mods.

    python3 tools/check.py [--quiet]

Each mod under `mods/` already checks itself -- its own `tools/check.py` is
carried in the fork and is run from here, so a palette that has drifted or a
changelog with no heading still fails.  What that cannot see is anything ABOUT
the channel, and this is that list:

  * a mod with no checks of its own has every Lua file compiled here, so a
    mod written for this channel is not the one thing nothing looks at.
  * every mod in `mods/` carries the CHANNEL's version.  The nightly ships as
    one tag with one release on it and several archives, which is what lets
    the cart and every mod it pins go out together; cartkit resolves a github
    pin by looking for the tag `v<version>` and, on it, an asset named exactly
    `<mod id>-<version>.zip`.  A mod on a version of its own would be looking
    for a tag nobody cut.
  * `cart.json`'s version is that version too, for the same reason.
  * `cart.json`'s shell is the palette's `SHELL`.  The cartridge is the colour
    of the channel's purple because they are the same number, not because
    somebody matched them by eye once.
  * `cart.json` pins exactly what a build of `mods/` produces -- the same
    check `tools/pack.py --check` makes, run here so one command covers the
    tree.
  * `label.png` is what `tools/make_label.py` draws.  A committed PNG the tool
    no longer produces is a picture nobody can regenerate, and the index
    serves this same file as the cart's card thumbnail.
  * every id in `load_order` is a mod the cart actually pins, and every pin
    that names this repository is a directory under `mods/`.
  * every mod's directory is named after its id, which is what makes an asset
    name derivable from either.

Exits non-zero on any finding, which is what CI wants.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
MODS = ROOT / "mods"
CART = ROOT / "cart.json"
LABEL = ROOT / "label.png"

sys.path.insert(0, str(ROOT / "tools"))

from palette import SHELL  # noqa: E402

REPO = "wild1walker/Gen1NightlyMods"

findings: list[str] = []


def fail(where, message):
    findings.append("%s: %s" % (where, message))


def mod_dirs():
    if not MODS.is_dir():
        return []
    return sorted(p for p in MODS.iterdir()
                  if p.is_dir() and (p / "manifest.json").is_file())


def read_cart():
    try:
        return json.loads(CART.read_text(encoding="utf-8"))
    except (OSError, ValueError) as problem:
        fail("cart.json", "could not be read: %s" % problem)
        return None


def check_versions(cart, quiet):
    """One version for the whole channel, in every manifest and in the cart."""
    directories = mod_dirs()
    if not directories:
        fail("mods/", "no mods; a channel with nothing in it releases nothing")
        return

    versions = {}
    for directory in directories:
        try:
            manifest = json.loads(
                (directory / "manifest.json").read_text(encoding="utf-8"))
        except (OSError, ValueError) as problem:
            fail(directory.name, "manifest.json: %s" % problem)
            continue
        if manifest.get("id") != directory.name:
            fail(directory.name,
                 "manifest id is %r; the directory must be named after the "
                 "mod, because the release asset name is derived from it"
                 % manifest.get("id"))
        versions[directory.name] = str(manifest.get("version", ""))

    wanted = str(cart.get("version", "")) if cart else ""
    for name, version in sorted(versions.items()):
        if version != wanted:
            fail(name, "is version %s; the channel is at %s, and every mod on "
                       "a nightly release shares its tag" % (version, wanted))

    if not quiet and versions:
        print("  versions:   %d mod(s) at %s" % (len(versions), wanted))


def check_shell(cart):
    if cart.get("shell") != SHELL:
        fail("cart.json", "shell is %s; tools/palette.py says %s"
             % (cart.get("shell"), SHELL))
    label = cart.get("label")
    if not label:
        fail("cart.json", "no label; the launcher draws a blank cartridge")
    elif not (ROOT / label).is_file():
        fail("cart.json", "label %r is not in the cart directory" % label)


def check_pins(cart):
    pinned = [entry.get("id") for entry in cart.get("mods", [])]
    for entry in cart.get("mods", []):
        if entry.get("repo") == REPO and not (MODS / str(entry.get("id"))).is_dir():
            fail("cart.json", "pins %r out of this repository, but there is "
                              "no mods/%s" % (entry.get("id"), entry.get("id")))
    for name in cart.get("load_order", []):
        if name not in pinned:
            fail("cart.json", "load_order names %r, which the cart does not "
                              "pin" % name)
    for directory in mod_dirs():
        if directory.name not in pinned:
            fail("cart.json", "does not pin mods/%s; a mod the channel builds "
                              "and the cart ignores is a mod nobody gets"
                 % directory.name)


def rerun(what, argv, cwd):
    """Run a tool and report its output as one finding if it fails."""
    run = subprocess.run(argv, capture_output=True, text=True, cwd=str(cwd))
    if run.returncode != 0:
        detail = (run.stdout + run.stderr).strip().splitlines()
        fail(what, "\n    ".join(["failed:"] + detail[-12:]))
        return False
    return True


def check_generated():
    """A rebuild has to produce the bytes that are committed."""
    if not LABEL.is_file():
        fail("make_label.py", "label.png is missing; run it")
        return
    before = LABEL.read_bytes()
    if not rerun("make_label.py",
                 [sys.executable, str(ROOT / "tools" / "make_label.py")], ROOT):
        return
    if LABEL.read_bytes() != before:
        fail("make_label.py", "label.png is stale; the committed file is not "
                              "what the tool draws")


def check_packed():
    rerun("pack.py",
          [sys.executable, str(ROOT / "tools" / "pack.py"), "--check"], ROOT)


# ------- and a local that is read before it is declared
#
# `luac -p` and `luajit -bl` both accept it: a name used above its `local` is
# valid syntax, it is just not that local.  It compiles to a GLOBAL read, which
# is nil, and calling nil raises at run time on whatever frame reaches it.
# That shipped once and took a whole battle UI with it; see the same block in
# each bundle's own tools/check.py.
GGET = re.compile(r'\bGGET\b[^;]*;\s*"([A-Za-z_][A-Za-z0-9_]*)"')
DECLARES = re.compile(
    r'^[ \t]*local[ \t]+(?:function[ \t]+)?([A-Za-z_][A-Za-z0-9_]*)(.*)$', re.M)


def forward_locals(listing, source):
    """Names this file reads as globals and also declares as locals."""
    read = set(GGET.findall(listing))
    if not read:
        return []
    declared = set()
    for name, rest in DECLARES.findall(source):
        # `local x = x or ...` reads the global on purpose and is not this.
        if name in read and re.search(r'\b' + re.escape(name) + r'\b', rest):
            continue
        declared.add(name)
    return sorted(read & declared)


def lua_binary():
    for candidate in ("luajit", "lua5.1", "lua"):
        if shutil.which(candidate):
            return candidate
    return None


def check_lua(directory, quiet):
    """Every Lua file in a mod compiles.

    Only for a mod with no checks of its own.  The two forked bundles run a
    syntax pass as the first thing their own check.py does, so doing it again
    here would be doing it twice; a mod written for this channel has no
    check.py and would otherwise have nothing at all standing between a typo
    and a release.
    """
    binary = lua_binary()
    if binary is None:
        fail(directory.name, "no lua interpreter found, so nothing was "
                             "compiled")
        return
    flag = "-bl" if binary == "luajit" else "-p"
    files = sorted(path for path in directory.rglob("*.lua")
                   if ".git" not in path.parts)
    for path in files:
        run = subprocess.run([binary, flag, str(path)],
                             capture_output=True, text=True)
        if run.returncode != 0:
            fail(directory.name, "%s: %s"
                 % (path.relative_to(directory),
                    (run.stderr or run.stdout).strip()))
            continue
        if binary == "luajit":
            source = path.read_text(encoding="utf-8", errors="replace")
            for name in forward_locals(run.stdout, source):
                fail(directory.name,
                     "%s: `%s` is read above the `local` that declares it, so "
                     "it is a global there and nil at run time"
                     % (path.relative_to(directory), name))
    if not quiet:
        print("  %-22s %d lua file(s) compile" % (directory.name, len(files)))


def check_each_mod(quiet):
    """Every mod's own checks, from its own directory."""
    for directory in mod_dirs():
        own = directory / "tools" / "check.py"
        if not own.is_file():
            check_lua(directory, quiet)
            continue
        ok = rerun(directory.name + "/tools/check.py",
                   [sys.executable, "tools/check.py"], directory)
        if not quiet and ok:
            print("  %-22s its own checks pass" % directory.name)


def main(argv):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--quiet", action="store_true")
    args = parser.parse_args(argv[1:])

    if not args.quiet:
        print("checking the nightly channel")

    cart = read_cart()
    if cart is not None:
        check_versions(cart, args.quiet)
        check_shell(cart)
        check_pins(cart)
    check_generated()
    check_packed()
    check_each_mod(args.quiet)

    for finding in findings:
        print("check: %s" % finding)
    if findings:
        print("\n%d problem(s)." % len(findings))
        return 1
    if not args.quiet:
        print("\nall checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
