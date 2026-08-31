# Cutting a nightly

Six steps, and the last two are the ones that get forgotten: the release can
be perfect on GitHub and still be invisible to the game.

## The sequence

1. **Bump.** `python3 tools/bump.py` for the next minor, `--patch` for a fix,
   or name the version. One version across `nightly.json`, `cart.json` and all
   four `manifest.json` files — anything less fails step 3.

2. **Write the changelogs.** Every mod gets a heading; the one that changed
   gets the words. The others say so rather than being left as the stub the
   bump wrote, because a heading with `_Write what changed._` under it is the
   only evidence that a release was cut in a hurry.

3. **Pack and check.** `python3 tools/pack.py` re-pins `cart.json` to the
   archives the new version produces, then `python3 tools/check.py` proves the
   versions agree, the Lua compiles, each mod's own checks pass, and the pins
   match what a build actually makes.

4. **Commit and push** to the working branch, then fast-forward `main` and
   push that. The tag and the release are the workflow's job, not yours.

5. **Verify the release.** When `v<version>` appears, read the release's asset
   digests and compare them to what `pack.py` printed in step 3. They are the
   same four numbers or something rebuilt differently than you did.

6. **Rebuild the index, and confirm the feed moved.** Dispatch `index.yml` on
   `wild1walker/Gen1NightlyIndex`, then read `site/data/index.json` on that
   repo's `main` and check every mod says the new version.

## Why step 6 is written down

Between 0.29.2 and 0.30.2 six releases were cut and none of them was
dispatched. Every one built, every one published, every digest matched — and
the feed sat on 0.29.1 the whole time, so the cart's updater offered none of
them. A test bench probe shipped to answer an open bug could not be reached
from the game it was built for.

Nothing warns about this. The release workflow's token is scoped to this
repository and cannot start a workflow in the index repo, the checks all pass
because they are about this repo's contents, and the feed is a separate
repository whose scheduled rebuild is slow enough to hide the gap for a long
time. The only thing standing between a release and a player is remembering,
which is why it is a numbered step rather than a habit.

If it is worth automating: a repository secret holding a token with
`actions: write` on the index repo would let this repo's release workflow
dispatch `index.yml` itself as a final step. That is a key the maintainer has
to make, so it is offered here rather than assumed.
