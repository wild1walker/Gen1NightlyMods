# Test Bench

**One screen with everything this channel is changing on it, one press from
START.** It ships on no release.

`START > BENCH`:

```
  UI THEME          DARK          the suite's screens
  PLAYER            PURPLE        the character's colour, live
  COLORS            ADVANCED      the display mode
  BATTLE LAYOUT     WIDE          OG is 160x144; WIDE is 304x144
  BACKDROPS         ON            the picture behind a battle
  EDGE TO EDGE      ON            off leaves the white bars round a wide battle
  FIELD TEST        OFF           magenta = the patch ran, the picture was lost
  MAP               ROUTE_1       what the backdrop is picked from
  OPPONENT          GEODUDE
  LEVEL             25
  START A BATTLE                  press A
  ASK FOR A SAVE    DUE           press A; it lands on the next covered frame
```

Left and right turn a row, A presses one, B goes back. The bottom line says
what the row under the cursor does, or what the last press did.

## Why it is a mod of its own

Because that is what makes gutting it free.

Taking the testing weight out of a release is not a refactor, an option to
switch off, or a flag somebody has to remember: it is **not pinning this mod**.
The stable cart pins four mods and this is not one of them, so no release
carries a line of it — not the rows, not the screen, not the START entry, not
the strings.

The price is that the bench cannot see the insides of anything. Every row goes
through what another mod *publishes* and stands down where nothing answers:

| Row | Reached through |
|---|---|
| `UI THEME`, `BACKDROPS`, `EDGE TO EDGE`, `FIELD TEST` | Gen1WildUI Nightly's `optionValue` / `optionWrite` — the bundle's own reader and writer over its merged schema, so the bench and `START > OPTION` are the same setting |
| `PLAYER` | Wild Green Nightly's `suits` / `suit` / `setSuit` |
| `ASK FOR A SAVE` | Gen1WildQOL Nightly's autosave, through the bundle's feature table |
| `COLORS`, `BATTLE LAYOUT`, `START A BATTLE` | the engine: save options, and `BattleState.newWild` |

That is the right price. A bench wired into a mod's locals breaks the mod every
time the mod is edited, and this channel edits them constantly.

A row whose mod is missing reads `--` and does nothing when pressed, rather
than disappearing — "the theme row is gone" is exactly the thing worth being
told, and a bench that silently drops a row cannot tell you.

## What it deliberately will not do

**Write a save now.** `ASK FOR A SAVE` calls the same `request` every
checkpoint calls, so a bench-asked save takes the same windows and the same
refusals as any other. A button that forced a write would be testing a code
path that does not exist in the game.

## Licence

MIT. See [LICENSE](LICENSE).
