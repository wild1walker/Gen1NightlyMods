#!/usr/bin/env python3
"""Every cart this channel ships, and where each one's cart.json lives.

    python3 tools/carts.py     list them

------- why the root one stays at the root

`cart.json` at the top of the repository is **Wild Green Nightly**, and it is
there rather than under `carts/` because two things outside this repository
read it by that exact path:

  * `cartkit pack .` resolves a cart directory and looks for `cart.json` in
    it (`resolve_cart_dir`), which is what the release workflow runs; and
  * the nightly index fetches `<repo>/cart.json` off the default branch to
    read a cart listing's pins, so a listing never carries a hand-copied pin
    array (`Gen1NightlyIndex/tools/build_index.py`, fetch_cart_json).

Moving it would break the second silently -- the listing would keep whatever
pins were committed and go stale without saying so -- so the first cart stays
where every reader already looks, and every cart AFTER it gets a directory.

------- and the second one gets a directory

    carts/<id>/cart.json

`cartkit` supports this already and needs no argument for it: `resolve_cart_dir`
takes any directory holding a `cart.json`, so `cartkit pack carts/<id>` packs
that cart with its own label art beside it.  A cart's label has to sit in its
own directory (cartkit refuses one that resolves outside), which is the other
reason a second cart is a folder rather than a second file at the root.

------- what this module is for

The three tools that used to know one cart -- bump, pack, check -- now ask
here instead, so adding a third cart is a directory and no edit to any of
them.
"""

from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CARTS = ROOT / "carts"
CART_FILE = "cart.json"


class Cart:
    """One cart: where its manifest is, and what is in it."""

    def __init__(self, path):
        self.path = path
        self.dir = path.parent
        self.data = json.loads(path.read_text(encoding="utf-8"))

    @property
    def id(self):
        return str(self.data.get("id", ""))

    @property
    def where(self):
        """The path as a finding should name it, relative to the repo."""
        return str(self.path.relative_to(ROOT))

    def label_path(self):
        """The label art's path, or None when the cart declares no art.

        A cart with no `label` is legal -- cartkit skips the whole check when
        the field is absent -- and the launcher draws the shell with no
        sticker on it.  That is the right state for a cart whose art has not
        been drawn yet and the wrong one to stay in.
        """
        label = self.data.get("label")
        if not label:
            return None
        return self.dir / label

    def dumps(self):
        return json.dumps(self.data, indent=2, ensure_ascii=False) + "\n"

    def write(self):
        self.path.write_text(self.dumps(), encoding="utf-8")


def cart_paths():
    """Every cart.json in the channel, the root one first.

    Root first because it is the one the index and `cartkit pack .` reach for
    by default, so it is the one a reader means when they say "the cart"
    without naming it.
    """
    found = []
    root = ROOT / CART_FILE
    if root.is_file():
        found.append(root)
    if CARTS.is_dir():
        for directory in sorted(p for p in CARTS.iterdir() if p.is_dir()):
            path = directory / CART_FILE
            if path.is_file():
                found.append(path)
    return found


def carts():
    return [Cart(path) for path in cart_paths()]


def main(argv):
    for cart in carts():
        pinned = ", ".join(str(m.get("id")) for m in cart.data.get("mods", []))
        print("%-24s %-28s base %-8s %s"
              % (cart.id, cart.where, cart.data.get("base"), pinned))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
