-- UI THEME on a Gen 2 boot: the same two themes, through Gold's own colour.
--
-- ------- why this is a second file and not a branch in theme.lua
--
-- runtime/theme.lua works by rewriting the SGB zone list: Red draws every
-- page in four DMG shades and the colour arrives afterwards, from a pass that
-- blits the finished frame once per rectangle through that rectangle's own
-- four colours.  Swapping those four is why DARK cannot move a glyph.
--
-- Gold is a CGB game and has no such pass.  `render.zones` is still raised at
-- the same instant (src/core/Game2.lua:1551) and a mod may still return a zone
-- list, but Gold computes none of its own unless CLASSIC is on -- the comment
-- there says it plainly: "Gold is a CGB game whose colour is already IN the
-- picture".  There is nothing to reverse.  A theme built on that hook would
-- have exactly the failure the Gen 1 file's own history warns about: it would
-- never fire.
--
-- ------- the seam Gold does have
--
-- Gold's colour goes on while the page is DRAWN, per tile, out of a palette
-- the drawing routine is handed.  Nearly every one of them is handed nothing
-- and falls back to one table:
--
--     Chrome.DEFAULT_BOX_PALETTE   (src/ui/gen2/Chrome.lua:137)
--
-- `Chrome.box`, `Chrome.textbox`, `Chrome.print`, `Chrome.printRight`,
-- `Chrome.clear`, `Chrome.paletteFill` and `Chrome.letterbox` all read it,
-- all read it AT CALL TIME, and fifty-two files under src/ draw through them.
-- It is the same four numbers a Gen 1 zone carries, in the same order --
-- colour 0 the paper, colour 3 the ink -- doing the same job one step earlier
-- in the frame.
--
-- So this file is the Gen 1 file's mechanism moved one step earlier: rewrite
-- those four, in place, once a frame.  Nothing is redrawn, no screen is
-- edited, no feature learns that themes exist, and a theme that cannot move a
-- glyph cannot move a glyph off the screen -- the property the whole design
-- is for, kept for the same reason and by the same means.
--
-- ------- in place, and why that matters
--
-- The four entries are overwritten inside the existing table rather than the
-- table being replaced.  Two things depend on it.  `src/ui/gen2/TrainerCard.
-- lua` passes `Chrome.DEFAULT_BOX_PALETTE` explicitly to seventeen calls, so
-- identity has to keep holding or the card would be the one page that stayed
-- light.  And anything that captured the table at load -- a third-party Gold
-- mod, a future engine screen -- keeps reading the live value instead of a
-- snapshot of white.
--
-- ------- when
--
-- `core.update`, which main.lua raises once a frame on both generations
-- (src/core/PlatformHooks.lua:11) and which runs BEFORE the frame is drawn.
-- `render.zones` is the wrong end: by the time it fires the page has already
-- been painted in whatever the palette said a moment ago.
--
-- The decision is per frame rather than per page because on Gold one frame is
-- one page: the top state owns the picture, and an overlay stacked on it -- a
-- text box over the overworld -- is drawn through this same chrome and wants
-- the same answer.  That is the one visible difference from Gen 1, and it is
-- the right one: under DARK, Gold's own message boxes go dark with the menus
-- instead of staying white over a dark page.
--
-- ------- what is NOT themed
--
-- Everything that hands Chrome a palette of its own, which is Gold's way of
-- saying "these colours are the content": the pack's pocket tabs, the dex's
-- inverted page, the trainer card's badges, every mon and item sprite, the
-- battle HUD.  They keep their own colours exactly as they are, and the text
-- and chrome around them themes -- which is the same split the Gen 1 file
-- draws between a page and the true-colour art sitting on it, arrived at from
-- the other side.
--
-- And, as on Gen 1, the frames that are PICTURES rather than pages: the
-- overworld, a battle, the title screen, the intros and the animations.
--
-- That exclusion is the one thing this arm has to do real work for, and it is
-- worth saying why rather than leaving it as a list.  On Gen 1 a battle is
-- excluded for free: it never asks for the four greys, so the zone rule never
-- claims it.  Here it is the opposite -- Gold's battle field is literally
-- `Chrome.clear()`, the first line of `BattleState:drawPanel`
-- (src/ui/gen2/BattleState.lua:4246), which is a whole-screen fill through
-- this very table.  Left alone, DARK would paint every battle's field black.
--
-- So the page has to be identified before the palette is set, and it is
-- identified exactly the way the Gen 1 arm identifies one: the topmost state
-- that either says it is ours (`state.gen1wildTheme`, set on every screen
-- this suite registers) or is one of the engine classes in `Theme2.PAGES`.
-- Gold's overworld is not a stack state at all, so a plain overworld frame
-- finds nothing and is left alone -- and so is a text box standing over it,
-- which is the same answer Gen 1 gives for the same frame.

local PAGE_MODULES = {
  -- The menus and text pages.  Every one of these is a full-screen box-and-
  -- text page in the same sense Red's OPTION screen is, which is the test the
  -- Gen 1 list applies.
  "src.ui.gen2.PokedexMenu",
  "src.ui.gen2.PartyMenu",
  "src.ui.gen2.SummaryMenu",
  "src.ui.gen2.TrainerCard",
  "src.ui.gen2.PackMenu",
  "src.ui.gen2.MartMenu",
  "src.ui.gen2.OptionsMenu",
  "src.ui.gen2.Pokegear",
  -- Bill's PC and the four other things a PC is on Gold.
  "src.ui.gen2.PcMenu",
  "src.ui.gen2.BoxMenu",
  "src.ui.gen2.CenterPcMenu",
  "src.ui.gen2.ItemPcMenu",
  "src.ui.gen2.MailboxMenu",
  -- MAIL, the day-care, the held-item row, decorations, the trade desk.
  "src.ui.gen2.MailMenu",
  "src.ui.gen2.MailRead",
  "src.ui.gen2.MailCompose",
  "src.ui.gen2.DayCareMenu",
  "src.ui.gen2.HeldItemMenu",
  "src.ui.gen2.DecorationMenu",
  "src.ui.gen2.TradeMenu",
  -- The move screens.
  "src.ui.gen2.MoveDeleter",
  "src.ui.gen2.MoveTutor",
  -- The START menu, and the lift panel that is the same idea on a smaller
  -- box.  Both stand OVER the world rather than replacing it, and that is
  -- exactly why the Gen 1 arm leaves Red's START menu alone -- there, the
  -- box takes its four colours from the zone the map is wearing, so
  -- reversing them reverses the map with it.  Here nothing of the sort is
  -- true: the world is drawn from its own tile palettes and never reads this
  -- table (there is not one `Chrome.` call in src/world/gen2/World.lua),
  -- while the box, its rows and its cursor are `Chrome.box` / `Chrome.print`
  -- and read nothing else.  So the reversal lands on the box and stops
  -- there, and the reason Red's is excluded does not survive the crossing.
  "src.ui.gen2.StartMenu",
  "src.ui.gen2.ElevatorMenu",
  -- Naming, and the boot menu behind the title.
  "src.ui.gen2.NamingScreen",
  "src.ui.gen2.NamePick",
  "src.ui.gen2.MainMenu",
  "src.ui.gen2.SaveMenu",
  "src.ui.gen2.InitClock",
  "src.ui.gen2.GenderSelect",
  -- The desks and counters: Mom's bank, the prize counters, the contest sign
  -- up, the radio, the Battle Tower, Buena's password.
  "src.ui.gen2.BankOfMom",
  "src.ui.gen2.PrizeMenu",
  "src.ui.gen2.ContestMenu",
  "src.ui.gen2.MapRadio",
  "src.ui.gen2.BattleTowerMenu",
  "src.ui.gen2.BuenaPassword",
  "src.ui.gen2.ScriptMenu",
  -- The mod manager, which is the same class on both generations and is
  -- already named in the Gen 1 arm's list for the same reason.
  "src.mods.ManagerState",
}

-- Left out deliberately, and each was read before being left out.
--
-- The pictures: `BattleState` (its field is `Chrome.clear`, see above --
-- except on the frames BACKDROPS has replaced that call with art, which the
-- walk asks the instance about),
-- `TitleState`, `GoldSilverIntro`, `CrystalIntro`, `CopyrightSplash`,
-- `CrystalSplash`, `GameFreakPresents`, `Credits`, `HallOfFame`, `Diploma`,
-- `EvolutionAnim`, `EggHatchAnim`, `TradeAnim`, `SlotMachine`, `CardFlip`,
-- `UnownPuzzle`, `UnownPrinter`, `PhotoStudio`, `MagnetTrainRide`.
--
-- The transitions, which are a fade and nothing else: `BattleTransition`,
-- `MenuFade`, `BlankScreen`, `WaitPlaySFX`.
--
-- `OakSpeech`, and this one differs from Gen 1 on purpose.  The Gen 1 arm
-- themes it and gets away with it because Red's portraits are true-colour
-- rectangles the shade pass never touches, with runtime/matte.lua painting
-- the page colour underneath them.  Gold has neither: the portraits are drawn
-- into the picture in their own colours, and there is no matte because there
-- is nothing raw to repair.  Reversing the box palette there would put a
-- lit white portrait on a black page with a white seam around it, which is
-- worse than the light screen it replaced.
--
-- ------- the one box that is not reached by four numbers
--
-- The YES/NO box (`src/ui/ChoiceBox.lua`) is shared between the generations
-- and paints like a Gen 1 screen: `Font.drawBox` for the box, `Font.draw` and
-- `Font.drawCode` for the labels and the cursor.  None of those reads the
-- table this file rewrites, so no swap of four numbers can move it, and it
-- stayed white under DARK while every box around it went black.
--
-- 0.32.25 said that could not be closed without drawing.  The second half of
-- that is true and the first half was wrong: `Chrome.paletteBox` IS
-- `Font.drawBox` with a palette shader around it, so drawing the same box out
-- of the same glyphs through the same four numbers is a fold, not a redesign.
-- runtime/choicebox2.lua is that fold, and it is a file of its own precisely
-- because it draws -- which is the one thing this file promises never to do,
-- and the promise is worth more than the convenience of putting them
-- together.
--
-- What is left here is the walk: the box is FURNITURE below, so a question
-- standing on a page leaves the page themed.  It was not, and that cost more
-- than the box's own colours -- see the note on the list itself.
local Theme2 = {}
Theme2.PAGES = PAGE_MODULES

-- What Gold ships (src/ui/gen2/Chrome.lua:137).  Held by value, because the
-- table itself is the one being rewritten and LIGHT has to put it back.
local VANILLA = {
  { 255, 255, 255 }, { 255, 255, 255 }, { 255, 255, 255 }, { 0, 0, 0 },
}

-- DARK, and it is the reversal rather than a second design: paper black, ink
-- white, and the two between them exchanged -- the same transform
-- runtime/theme.lua applies to a Gen 1 zone, applied to the same four
-- numbers.  Gold's default has three whites and a black, so the reversal is
-- one white and three blacks, and a glyph's own anti-aliased midtones come
-- out light on dark instead of dark on light.
local DARK = {
  { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 }, { 255, 255, 255 },
}

Theme2.VANILLA = VANILLA
Theme2.DARK = DARK

-- Same two names, same order, same default as the Gen 1 arm.  A player who
-- moves a save between the two generations finds the row where they left it,
-- because it is stored under the same key with the same values.
Theme2.ORDER = { "light", "dark" }
Theme2.LABELS = { light = "LIGHT", dark = "DARK" }
Theme2.DEFAULT = "light"

-- Copy `from` over `into` without changing which table `into` is.
local function overwrite(into, from)
  for i = 1, 4 do
    local c = from[i]
    into[i] = { c[1], c[2], c[3] }
  end
end

Theme2.overwrite = overwrite

-- Whether two palettes carry the same four colours, so a frame that would
-- write what is already there writes nothing.  Twelve compares beats twelve
-- table allocations every frame of the game.
local function same(a, b)
  if type(a) ~= "table" or type(b) ~= "table" then return false end
  for i = 1, 4 do
    local x, y = a[i], b[i]
    if type(x) ~= "table" or type(y) ~= "table" then return false end
    if x[1] ~= y[1] or x[2] ~= y[2] or x[3] ~= y[3] then return false end
  end
  return true
end

Theme2.same = same

-- The page classes, resolved to the class tables themselves so a state can be
-- matched by `getmetatable`.  Built on the first frame that needs them rather
-- than at load, because a require is cheap but not free and a LIGHT boot
-- never asks.  A module this build does not carry -- the three Crystal-only
-- screens on a Gold cart, say -- resolves to nothing and simply has no entry.
local pageClasses

local function classes()
  if pageClasses then return pageClasses end
  pageClasses = {}
  for _, path in ipairs(PAGE_MODULES) do
    local ok, class = pcall(require, path)
    if ok and type(class) == "table" then pageClasses[class] = true end
  end
  return pageClasses
end

-- Is this frame a page of ours?
--
-- Top of the stack downwards, and the first state that answers ends the walk:
-- a state that says it is ours, or is one of the classes above, is the page;
-- anything else that is a full-screen owner is a picture and the frame is not
-- a page.  Unlike the Gen 1 arm there is no `sgbPalettes` to ask "do you own
-- this frame's colours", because on Gold nothing does -- so the test is
-- simply the topmost state, plus a step over the overlays that are not pages
-- in their own right.
--
-- Gold's overworld is not a stack state, so an empty stack is the world: not
-- a page, and left alone.  That is also what makes a text box over the
-- overworld come out unthemed, which is the answer Gen 1 gives for the same
-- frame.
-- Two kinds of thing stand on top of a page, and they want opposite answers
-- when there is no page underneath.
--
-- FURNITURE is drawn through this very table: Gold's dialogue box asks for
-- `Chrome.paletteBox(..., Chrome.DEFAULT_BOX_PALETTE)` and takes its glyph
-- colours out of the same four (src/render/TextBox.lua:669-678).  So a
-- message box is not something standing in front of the page -- on the frames
-- it is the only box on the screen it IS the page, in the only sense this
-- file means the word: the thing whose colours these four numbers are.
--
-- A VEIL is drawn through nothing.  MenuFade, BlankScreen and WaitPlaySFX are
-- a rectangle and a wait; reversing the palette under one changes no pixel
-- while it is up and the wrong pixels the frame it comes off.
--
-- Both are stepped over on the way down -- a confirm box over the PACK leaves
-- the PACK themed, which is the answer either kind wants there.  They differ
-- only at the bottom of the walk, and that difference is the overworld: a
-- veil over the map is the map, and the map is a picture; a message box over
-- the map is a box, and every box in this game is ours to colour.
--
-- That is a change from 0.32.23, which treated the two alike and so left
-- Gold's most-seen box -- every line of dialogue in the game -- white on a
-- dark boot, while the menu it had just come out of was black.  The header
-- above already promised the opposite ("Gold's own message boxes go dark with
-- the menus"); this is the walk finally saying it.
local FURNITURE_MODULES = {
  "src.render.TextBox",
  -- The YES/NO box, which stands on top of the text box that asked the
  -- question -- so leaving it out did not merely leave IT unthemed, it ended
  -- the walk one state early and took the page underneath with it: answer a
  -- `yesorno` on a dark PACK and the PACK went white for as long as the
  -- question was up.  It is furniture for the same reason the text box is,
  -- once runtime/choicebox2.lua has it drawing through this table.
  "src.ui.ChoiceBox",
}

local VEIL_MODULES = {
  "src.ui.gen2.MenuFade",
  "src.ui.gen2.BlankScreen",
  "src.ui.gen2.WaitPlaySFX",
}

local function resolver(paths)
  local resolved
  return function()
    if resolved then return resolved end
    resolved = {}
    for _, path in ipairs(paths) do
      local ok, class = pcall(require, path)
      if ok and type(class) == "table" then resolved[class] = true end
    end
    return resolved
  end, function() resolved = nil end
end

local furniture, forgetFurniture = resolver(FURNITURE_MODULES)
local veils, forgetVeils = resolver(VEIL_MODULES)

-- Below all three resolvers, because it calls all three.  A `local` read
-- above its own declaration is a GLOBAL read and therefore nil, which is the
-- mistake that took the battle UI out in 0.32.3; tools/check.py fails on it
-- now, and this is the shape it looks for.
Theme2.forgetClasses = function()
  pageClasses = nil
  forgetFurniture()
  forgetVeils()
end

function Theme2.pageOf(game)
  local stack = game and game.stack
  local states = stack and stack.states
  if type(states) ~= "table" then return nil end
  local pages, boxes, fades = classes(), furniture(), veils()
  -- The topmost piece of furniture stepped over, kept in case the walk
  -- reaches the bottom without finding a page under it.
  local carried
  for i = #states, 1, -1 do
    local state = states[i]
    if type(state) == "table" then
      -- One of ours: every screen this suite registers is marked on the way
      -- out of runtime/facade.lua, so a feature's own page needs no entry in
      -- the list above and no edit here when a new one is added.
      if state.gen1wildTheme then return state end
      local class = getmetatable(state)
      if class and pages[class] then return state end
      -- A battle standing on a BACKDROP, which is the one exclusion below
      -- that stops being true under a condition rather than never.
      --
      -- The reason a battle is not a page is exact: Gold's field is
      -- `Chrome.clear()`, a whole-screen fill through this very table, so
      -- theming one would paint every field black.  BACKDROPS replaces that
      -- call with a picture, and when it does the fill never happens -- so
      -- there is no field for four numbers to reach and the boxes, the HUD
      -- plates and the message box can go dark with the rest of the game.
      --
      -- Set by Gen1Arena on the instance, per frame, and only for the frames
      -- it actually took (`consumed`): a battle it found no backdrop for is
      -- still the cart's white field and still not a page.  Read one frame
      -- behind, because the theme runs before the draw that sets it -- which
      -- costs the first frame of a battle its theme and nothing after it.
      if state.gen1wildArenaField then return state end
      if class and boxes[class] then
        -- stepped over, but remembered: if there is a page under it that
        -- page is what is on the screen, and if there is not, this is.
        carried = carried or state
      elseif not (class and fades[class]) then
        -- Anything else is a picture and ends the walk, because whatever is
        -- under it is not what is on the screen.  A battle's own message box
        -- comes out here rather than themed, which is right: the field
        -- behind it is `Chrome.clear` and cannot go with it.
        return nil
      end
    end
  end
  -- The bottom of the stack, which on Gold is the overworld.  A veil there
  -- leaves nothing carried and the map is left alone; a box there is the one
  -- thing on the screen wearing these four colours.
  return carried
end

function Theme2.new(context)
  local mod = context.mod
  local optionset = context.optionset
  -- The SAME key the Gen 1 arm owns.  One row, one stored value, both
  -- generations -- see the ORDER note above.
  local KEY = "ui_theme"

  local self = {}

  -- ------- read once a frame
  --
  -- Same cache, same reason, same invalidation as runtime/theme.lua's: the
  -- read walks the live game's save, the mod's option store and the row's
  -- fallbacks behind two pcalls, and it is asked on every frame.  Kept
  -- against `optionset.generation()` so a write made through the other
  -- bundle's menu or the bench -- neither of which comes through this file --
  -- still lands on the next frame.
  local answer, answerAt

  function self.read()
    local now = optionset.generation and optionset.generation() or nil
    if answer and answerAt == now then return answer end
    local value = optionset.read(mod, KEY)
    if not Theme2.LABELS[value] then value = Theme2.DEFAULT end
    answer, answerAt = value, now
    return value
  end

  function self.forget()
    answer, answerAt = nil, nil
  end

  function self.write(value, game)
    if not Theme2.LABELS[value] then return end
    self.forget()
    return optionset.write(mod, KEY, value, game)
  end

  function self.label(value)
    return Theme2.LABELS[value or self.read()] or Theme2.LABELS[Theme2.DEFAULT]
  end

  function self.step(direction, game)
    local current = self.read()
    local at = 1
    for index, name in ipairs(Theme2.ORDER) do
      if name == current then at = index end
    end
    local next_ = Theme2.ORDER[((at - 1 + (direction or 1)) % #Theme2.ORDER) + 1]
    self.write(next_, game)
    return next_
  end

  function self.defineRow()
    optionset.own({
      key = KEY,
      type = "choice",
      label = "UI THEME",
      choices = {
        { Theme2.LABELS.light, "light" },
        { Theme2.LABELS.dark, "dark" },
      },
      default = Theme2.DEFAULT,
    })
  end

  -- The palette this theme wants on the frame about to be drawn.
  function self.palette()
    return self.read() == "dark" and DARK or VANILLA
  end

  -- What a screen of ours should paint behind a picture, in the same shape
  -- the Gen 1 arm's `matte` answers: the page's own paper colour, or nil when
  -- there is nothing to match.  LIGHT is white paper, which is what an
  -- unpainted box already is, so it answers nil and nothing is painted.
  function self.matte()
    if self.read() ~= "dark" then return nil end
    return { 0, 0, 0 }
  end

  -- Gold's art is not blitted raw past a shade pass the way a Gen 1
  -- true-colour mark is, so there is no hairline to skirt and nothing here
  -- has to paint one.  Present and answering nil so a caller written against
  -- the Gen 1 arm needs no generation test of its own.
  function self.skirt()
    return nil
  end

  -- ------- what the bench reads
  --
  -- Same three names the Gen 1 arm publishes, so the bench's rows need no
  -- generation branch.  Boxes and panels are Gen 1 ideas -- this arm records
  -- neither, because it never has to find a box to repaint -- so they answer
  -- zero, and `zones` answers how many frames this theme has actually
  -- painted, which is the number that says whether it is running.
  local painted = 0

  function self.probe()
    return 0, 0, painted
  end

  function self.artProbe()
    return 0, self.label(), painted > 0
  end

  function self.install()
    local Chrome = require("src.ui.gen2.Chrome")
    local live = Chrome.DEFAULT_BOX_PALETTE
    if type(live) ~= "table" or type(live[4]) ~= "table" then
      error("src.ui.gen2.Chrome has no DEFAULT_BOX_PALETTE to theme", 0)
    end

    -- What Gold actually shipped, read off the module rather than trusted
    -- from the constant above: an engine that retunes its default, or another
    -- mod that has already recoloured it, is what LIGHT has to put back.
    -- Taken once, at install, before this file has written anything.
    local vanilla = {}
    overwrite(vanilla, live)

    -- Guarded and reported once, for the reason the Gen 1 arm gives at the
    -- same place: this runs on every frame of every screen, a theme is
    -- decoration, and the right outcome for a broken one is the frame it was
    -- handed in the colours it already had -- not a crash in the middle of
    -- somebody's game over a tint.  After the first failure it stands down
    -- for the session and puts the vanilla four back.
    local broken = false

    mod.hooks:wrap("core.update", function(nextLink, game, dt)
      -- the frame boundary, here rather than inside `apply` so a theme that
      -- has stood down still forgets what it read
      self.forget()
      if not broken then
        local ok, problem = pcall(function()
          -- Both halves of the decision, in the order that makes the cheap
          -- one first: LIGHT wants the vanilla four whatever is on the
          -- screen, so a light boot never walks the stack at all.
          local wanted = vanilla
          if self.read() == "dark" and Theme2.pageOf(game) then
            wanted = DARK
          end
          if not same(live, wanted) then
            overwrite(live, wanted)
          end
          if wanted ~= vanilla then painted = painted + 1 end
        end)
        if not ok then
          broken = true
          overwrite(live, vanilla)
          mod.log:warn("UI THEME stood down for this session: %s",
                       tostring(problem))
        end
      end
      return nextLink(game, dt)
    end)

    mod.log:info("UI THEME is on Gold's box palette")
  end

  return self
end

return Theme2
