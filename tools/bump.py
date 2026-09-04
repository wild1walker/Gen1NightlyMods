#!/usr/bin/env python3
"""Cut the next nightly: one version, everywhere.

    python3 tools/bump.py            the next minor (0.1.0 -> 0.2.0)
    python3 tools/bump.py 0.4.0      a version you name
    python3 tools/bump.py --patch    the next patch (0.1.0 -> 0.1.1)

The channel ships as ONE release with several archives on it, and that is what
makes this a command rather than an edit: cartkit resolves a github pin by
looking for the tag `v<version>` and, on it, an asset named exactly
`<mod id>-<version>.zip`, so every mod on the release has to carry the same
version or it is looking for a tag nobody cut.  Four files say that version --
`nightly.json`, `cart.json` and each mod's `manifest.json` -- and a bump that
moved three of them would fail `tools/check.py`, which is the safety net rather
than the plan.

Each mod's CHANGELOG gets a heading for the new version if it has not got one,
because its own checks require it; the words under it are yours to write.

Then `python3 tools/pack.py` re-pins the cart to the archives the new version
produces, and the release workflow does the rest on the next push to main.

Minor by default rather than patch: a nightly is a build, not a fix, and a
channel that numbered every build a patch would say "0.1.47" about work that
has changed the game a dozen times.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from datetime import date

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import carts  # noqa: E402  (after sys.path, like every tool here)
MODS = ROOT / "mods"
STATE = ROOT / "nightly.json"

SEMVER = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def write_json(path, document):
    path.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8")


def next_version(current, part):
    match = SEMVER.match(current)
    if not match:
        raise SystemExit("bump: %s is not X.Y.Z" % current)
    major, minor, patch = (int(g) for g in match.groups())
    if part == "patch":
        return "%d.%d.%d" % (major, minor, patch + 1)
    if part == "minor":
        return "%d.%d.0" % (major, minor + 1)
    return "%d.0.0" % (major + 1)


def stamp_changelog(path, version):
    """A heading for the new version, if the file has not got one."""
    if not path.is_file():
        return False
    body = path.read_text(encoding="utf-8")
    if re.search(r"^##\s*\[?" + re.escape(version) + r"\]?", body, re.M):
        return False
    heading = "## [%s] - %s\n\n_Write what changed._\n\n" % (
        version, date.today().isoformat())
    # after the preamble, immediately above the newest existing entry
    at = body.find("\n## ")
    if at < 0:
        body = body.rstrip("\n") + "\n\n" + heading
    else:
        body = body[:at + 1] + heading + body[at + 1:]
    path.write_text(body, encoding="utf-8")
    return True


def main(argv):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("version", nargs="?", help="the version to cut")
    parser.add_argument("--patch", action="store_const", const="patch",
                        dest="part", help="the next patch instead of the next minor")
    parser.add_argument("--major", action="store_const", const="major",
                        dest="part")
    args = parser.parse_args(argv[1:])

    document = json.loads(STATE.read_text(encoding="utf-8"))
    current = str(document.get("version", ""))

    if args.version:
        if not SEMVER.match(args.version):
            raise SystemExit("bump: %s is not X.Y.Z" % args.version)
        version = args.version
    else:
        version = next_version(current, args.part or "minor")

    print("nightly %s -> %s" % (current, version))

    document["version"] = version
    write_json(STATE, document)
    print("  nightly.json")

    for cart in carts.carts():
        cart.data["version"] = version
        cart.write()
        print("  %s" % cart.where)

    for directory in sorted(p for p in MODS.iterdir() if p.is_dir()):
        manifest_path = directory / "manifest.json"
        if not manifest_path.is_file():
            continue
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["version"] = version
        write_json(manifest_path, manifest)
        print("  mods/%s/manifest.json" % directory.name)
        if stamp_changelog(directory / "CHANGELOG.md", version):
            print("  mods/%s/CHANGELOG.md   (write what changed)"
                  % directory.name)

    print("\nNow: python3 tools/pack.py  (re-pins the cart), then check.py.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
