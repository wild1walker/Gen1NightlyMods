#!/usr/bin/env python3
"""Bring a fork up to a newer release of the mod it was forked from.

    python3 tools/rebase.py                       where each fork stands
    python3 tools/rebase.py <mod>                 ...to the newest release
    python3 tools/rebase.py <mod> --to 1.27.0     ...to a named one
    python3 tools/rebase.py <mod> --dry-run       report, change nothing

This is what the channel has instead of the stable bundle's `tools/sync.py`,
and it is a different job.  `sync.py` moves a submodule pin and rebuilds: the
tracked source is somebody else's and is never edited, so the new copy simply
replaces the old one.  A fork has been edited on purpose, so replacing it would
throw away the thing the channel exists for.

So this does a real three-way merge, the way a vendor branch is merged:

    BASE     the upstream release this fork was taken from (nightly.json)
    THEIRS   the upstream release being moved to
    OURS     mods/<id>/ as it stands

For a file in all three, `git merge-file` merges THEIRS' changes into OURS and
leaves conflict markers where both sides moved the same lines -- which is
exactly where a human is needed and nowhere else.  A file only THEIRS has is
copied in.  A file THEIRS deleted is deleted here too, unless this fork has
changed it, in which case it is left alone and reported: a fork that edited a
file upstream then removed has a decision to make and it is not this script's.

Binary files (the item icons, the backdrops) are compared rather than merged:
identical is nothing to do, and different is THEIRS unless this fork changed
it, which is reported the same way.

Nothing is committed and nothing is pushed.  Read the diff, resolve whatever
came back with markers, run `python3 tools/check.py`, then commit.

The upstream release is the same archive a player installs -- fetched from the
GitHub release, not from a branch -- so a fork is always rebased onto something
that shipped.
"""

from __future__ import annotations

import argparse
import filecmp
import io
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
MODS = ROOT / "mods"
STATE = ROOT / "nightly.json"

SEMVER = re.compile(r"^v?(\d+\.\d+\.\d+)$")

# The fork's own scaffolding, which upstream has no opinion about: a file
# under one of these is never merged, added or deleted from upstream.
OURS_ONLY = ("README.md", "CHANGELOG.md", "mod.card", "manifest.json")


def api(url):
    request = urllib.request.Request(url, headers={
        "Accept": "application/vnd.github+json",
        "User-Agent": "gen1-nightly-rebase",
    })
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if token:
        request.add_header("Authorization", "Bearer " + token)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def state():
    return json.loads(STATE.read_text(encoding="utf-8"))


def releases(slug):
    try:
        found = api("https://api.github.com/repos/%s/releases?per_page=50" % slug)
    except urllib.error.HTTPError as problem:
        hint = ""
        if problem.code in (401, 403, 429):
            hint = ("; the unauthenticated API is rate-limited and some "
                    "networks refuse it outright -- set GITHUB_TOKEN")
        raise SystemExit("rebase: GitHub %d listing %s's releases%s"
                         % (problem.code, slug, hint))
    out = []
    for release in found:
        if release.get("draft"):
            continue
        match = SEMVER.match(str(release.get("tag_name") or ""))
        if match:
            out.append((match.group(1), release))
    return out


def newest(slug):
    found = releases(slug)
    if not found:
        raise SystemExit("rebase: %s has no vX.Y.Z release" % slug)
    def key(entry):
        return tuple(int(part) for part in entry[0].split("."))
    return max(found, key=key)[0]


def fetch(slug, version, mod_id, into):
    """The published archive for one release, unpacked into `into`."""
    for tag in ("v" + version, version):
        try:
            release = api("https://api.github.com/repos/%s/releases/tags/%s"
                          % (slug, tag))
            break
        except urllib.error.HTTPError as problem:
            if problem.code != 404:
                raise SystemExit("rebase: GitHub %d reading %s %s"
                                 % (problem.code, slug, tag))
            release = None
    if release is None:
        raise SystemExit("rebase: %s has no release tagged v%s" % (slug, version))

    wanted = "%s-%s.zip" % (mod_id, version)
    assets = [a for a in release.get("assets", []) if a.get("name")]
    asset = next((a for a in assets if a["name"] == wanted), None)
    if asset is None:
        zips = [a for a in assets if str(a["name"]).lower().endswith(".zip")]
        if len(zips) != 1:
            raise SystemExit("rebase: %s %s has no %s to install"
                             % (slug, version, wanted))
        asset = zips[0]

    request = urllib.request.Request(asset["browser_download_url"], headers={
        "User-Agent": "gen1-nightly-rebase"})
    with urllib.request.urlopen(request, timeout=120) as response:
        body = response.read()

    into.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(body)) as archive:
        archive.extractall(into)

    # the two shapes the game accepts: a manifest at the root, or inside one
    # top-level folder
    if not (into / "manifest.json").is_file():
        entries = [p for p in into.iterdir()]
        if len(entries) == 1 and entries[0].is_dir():
            return entries[0]
    return into


def relative_files(root):
    out = set()
    for path in root.rglob("*"):
        if path.is_file() and ".git" not in path.parts:
            out.add(path.relative_to(root).as_posix())
    return out


def is_text(path):
    try:
        path.read_text(encoding="utf-8")
        return True
    except (UnicodeDecodeError, OSError):
        return False


def merge_one(name, base, theirs, ours, report):
    """Three-way merge one file.  Returns True if a human is needed."""
    in_base = (base / name).is_file()
    in_theirs = (theirs / name).is_file()
    in_ours = (ours / name).is_file()

    if in_theirs and not in_ours:
        if in_base:
            report.append(("left deleted", name))     # we removed it on purpose
            return False
        (ours / name).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(theirs / name, ours / name)
        report.append(("added", name))
        return False

    if not in_theirs and in_ours:
        if in_base and filecmp.cmp(base / name, ours / name, shallow=False):
            (ours / name).unlink()
            report.append(("deleted", name))
        elif in_base:
            report.append(("upstream deleted, we changed it -- LEFT ALONE", name))
            return True
        return False

    if not (in_theirs and in_ours):
        return False

    if filecmp.cmp(theirs / name, ours / name, shallow=False):
        return False

    if not in_base or not (is_text(theirs / name) and is_text(ours / name)):
        if in_base and filecmp.cmp(base / name, ours / name, shallow=False):
            shutil.copy2(theirs / name, ours / name)
            report.append(("taken from upstream", name))
            return False
        report.append(("differs, cannot merge -- LEFT ALONE", name))
        return True

    if filecmp.cmp(base / name, ours / name, shallow=False):
        shutil.copy2(theirs / name, ours / name)
        report.append(("taken from upstream", name))
        return False

    run = subprocess.run(
        ["git", "merge-file", "-L", "nightly", "-L", "base", "-L", "upstream",
         str(ours / name), str(base / name), str(theirs / name)],
        capture_output=True, text=True)
    if run.returncode == 0:
        report.append(("merged", name))
        return False
    if run.returncode < 0:
        report.append(("merge-file failed -- LEFT ALONE", name))
        return True
    report.append(("MERGED WITH %d CONFLICT(S)" % run.returncode, name))
    return True


def rebase(fork, info, target, dry_run):
    slug = info["upstream"]
    upstream_id = info["upstream_id"]
    base_version = info["base"]
    target = target or newest(slug)

    print("%s: %s %s -> %s" % (fork, slug, base_version, target))
    if target == base_version:
        print("  already on it; nothing to do")
        return 0
    if dry_run:
        print("  --dry-run: not fetching")
        return 0

    ours = MODS / fork
    if not ours.is_dir():
        raise SystemExit("rebase: no mods/%s" % fork)

    with tempfile.TemporaryDirectory() as scratch:
        scratch = pathlib.Path(scratch)
        base = fetch(slug, base_version, upstream_id, scratch / "base")
        theirs = fetch(slug, target, upstream_id, scratch / "theirs")

        names = sorted(relative_files(base) | relative_files(theirs)
                       | relative_files(ours))
        report, needs_hand = [], 0
        for name in names:
            if name in OURS_ONLY:
                continue
            if merge_one(name, base, theirs, ours, report):
                needs_hand += 1

    for what, name in report:
        print("  %-42s %s" % (what, name))
    if not report:
        print("  nothing changed between the two releases")

    info["base"] = target
    document = state()
    document["forks"][fork]["base"] = target
    STATE.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n",
                     encoding="utf-8")
    print("  nightly.json now records %s as the base" % target)

    if needs_hand:
        print("\n  %d file(s) need a human.  Resolve them, then run "
              "python3 tools/check.py" % needs_hand)
        return 1
    print("\n  clean.  Run python3 tools/check.py, read the diff, then commit.")
    return 0


def main(argv):
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("mod", nargs="?", help="which fork, e.g. wild_green_nightly")
    parser.add_argument("--to", default=None, help="the release to move to")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args(argv[1:])

    forks = state()["forks"]

    if not args.mod:
        print("forks, and the release each was taken from:\n")
        for fork, info in sorted(forks.items()):
            # Reading the far side is a courtesy, not the answer: what this
            # repository knows for certain is which release it forked from, and
            # a network that will not serve the API should not stop it saying so.
            try:
                latest = newest(info["upstream"])
                behind = ("" if latest == info["base"]
                          else "   (upstream is %s)" % latest)
            except SystemExit as problem:
                behind = "   (%s)" % str(problem).split(": ", 1)[-1]
            print("  %-24s %-34s %s%s"
                  % (fork, info["upstream"], info["base"], behind))
        print("\nRun `python3 tools/rebase.py <fork>` to move one.")
        return 0

    if args.mod not in forks:
        raise SystemExit("rebase: no fork called %r; nightly.json knows %s"
                         % (args.mod, ", ".join(sorted(forks))))
    return rebase(args.mod, forks[args.mod], args.to, args.dry_run)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
