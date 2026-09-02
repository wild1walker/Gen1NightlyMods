-- TEST BENCH -- a nightly-only row on the START menu.
--
-- The channel exists so changes can be played before they reach the cart, and
-- playing a change means finding it: the UI theme is two menus in, the
-- player's colour is three, the display mode is somewhere else again, and
-- checking a battle backdrop means walking into grass.  So all of it is on one
-- screen, one press from START.
--
-- ------- it ships on no release, by construction
--
-- This is a MOD OF ITS OWN rather than a feature inside the bundles, and that
-- is the whole design.  Gutting the testing weight out of a release is not a
-- refactor, an option to switch off, or a flag to remember: it is not pinning
-- this mod.  The stable cart pins four mods and this is not one of them, so
-- there is no version of a release that carries a line of it -- not the rows,
-- not the screen, not the START entry, not the strings.
--
-- What that costs is that the bench cannot see the insides of anything.  It
-- reaches the other mods only through what they publish (see rows.lua), which
-- is the right price: a bench wired into a mod's locals is a bench that breaks
-- the mod every time the mod is edited, and this one is meant to be edited
-- constantly.
--
-- ------- what is in here
--
-- Only the screen and the door.  Everything the rows actually DO is rows.lua,
-- because that is the part that reaches five other mods and can be wrong; this
-- file is the engine's own OptionRows idiom and a hook on the START menu.

local ROWS = "rows.lua"

-- ------- the two chromes
--
-- Red's OPTION screen is four 20x4 boxes and Gold's is one 18x16 one, so the
-- bench draws itself twice rather than drawing Red's over Gold.  Which arm is
-- picked is decided once, at build, and `screen.draw` is set to it.
--
-- `src.ui.OptionRows` is named in exactly one place below and reached lazily
-- through a pcall, because a Gold boot must never resolve it: it is on the
-- loader's Gen 1-only list with no Gen2Compat adapter
-- (src/mods/Loader.lua:115-117), and a require for one of those from a mod's
-- chunk puts a line on the boot error feed the player sees in MODS.  Nothing
-- on the Gold arm reaches it; the pcall is there so that a future edit that
-- does degrades to a blank page instead of a red line.
--
-- `modkit gen2check` still reports that literal as MK402.  It scans every
-- file in the package, so a branch it can see is never taken is still a
-- branch it can see; the finding is expected.
local GEN2_VISIBLE_ROWS = 7
-- Gold's own OptionsMenu puts its value column at 11, which suits ON and
-- STEREO.  The bench's values are longer, so they start earlier -- the same
-- number the suite's own menus use, for the same reason.
local GEN2_VALUE_TX = 4

local optionRows, optionRowsAsked

local function engineOptionRows()
  if optionRowsAsked then return optionRows end
  optionRowsAsked = true
  local ok, module = pcall(require, "src.ui.OptionRows")
  optionRows = (ok and type(module) == "table") and module or nil
  return optionRows
end

local function detectGen2()
  local ok, GameVersion = pcall(require, "src.core.GameVersion")
  if not ok or type(GameVersion) ~= "table" then return false end
  if type(GameVersion.generation) ~= "function" then return false end
  local okCall, generation = pcall(GameVersion.generation)
  return okCall and generation == 2
end

return function(mod)
  local isGen2 = detectGen2()

  -- A mod cannot require its own files; mod:read + load is the supported
  -- route, and this one file is the whole of it.
  local Rows
  do
    local source, why = mod:read(ROWS)
    if not source then
      mod.log:error("cannot read %s (%s) -- reinstall the bench", ROWS,
        tostring(why))
      return
    end
    local chunk, problem = load(source, "@" .. tostring(mod.path) .. "/" .. ROWS)
    if not chunk then
      mod.log:error("%s did not compile: %s", ROWS, tostring(problem))
      return
    end
    local ok, value = pcall(chunk)
    if not ok or type(value) ~= "table" then
      mod.log:error("%s did not return its rows: %s", ROWS, tostring(value))
      return
    end
    Rows = value
  end

  local SCREEN_ID = "Gen1BenchNightly"

  -- What the rows share and keep between visits: which opponent is selected,
  -- what the last press said, and the host's own mod.find so a row can reach
  -- a sibling without knowing how a bundle publishes one.
  local context = {
    find = function(name)
      if type(mod.find) ~= "function" then return nil end
      local ok, handle = pcall(mod.find, name)
      if ok and handle then return handle end
      local okSelf, handleSelf = pcall(mod.find, mod, name)
      if okSelf then return handleSelf end
      return nil
    end,
  }

  mod.content.screens:register(SCREEN_ID, {
    new = function(game)
      local screen = {
        game = game,
        rows = Rows.build(context),
        index = 1,
        scroll = 0,
        isOpaque = true,
        -- One of the suite's own, as far as its theme is concerned: the bench
        -- is a page of the suite's furniture and should go dark with the rest
        -- of it rather than being the one white screen in a dark game.
        gen1wildTheme = "settings",
      }

      function screen:sgbPalettes(g)
        local ok, PaletteFX = pcall(require, "src.render.PaletteFX")
        if ok and PaletteFX and PaletteFX.wholeNamed then
          return PaletteFX.wholeNamed(g.data, "MEWMON")
        end
        return nil
      end

      -- The engine's OptionRows wants { id, label, value(game) }; built fresh
      -- each frame so a row reflects a press made on this one.
      local function drawable()
        local out = {}
        for i, row in ipairs(screen.rows) do
          out[i] = {
            id = row.id,
            label = row.label,
            value = function()
              if type(row.value) ~= "function" then return "" end
              local ok, text = pcall(row.value, screen.game)
              return (ok and type(text) == "string") and text or Rows.DASH
            end,
          }
        end
        return out
      end

      function screen:update()
        local input = self.game.input
        local row = self.rows[self.index]
        if not row then self.game.stack:pop() return end

        if input:wasPressed("up") then
          self.index = (self.index - 2) % #self.rows + 1
          context.said = nil
        elseif input:wasPressed("down") then
          self.index = self.index % #self.rows + 1
          context.said = nil
        elseif input:wasPressed("left") then
          if type(row.step) == "function" then
            pcall(row.step, self.game, -1)
          end
        elseif input:wasPressed("right") then
          if type(row.step) == "function" then
            pcall(row.step, self.game, 1)
          end
        elseif input:wasPressed("a") then
          if type(row.activate) == "function" then
            pcall(row.activate, self.game)
          elseif type(row.step) == "function" then
            pcall(row.step, self.game, 1)
          end
        elseif input:wasPressed("b") then
          self.game.stack:pop()
          return
        end

        if isGen2 then
          -- Gold's chrome has no clampScroll of its own -- every Gen 2 screen
          -- keeps its own window -- so the bench keeps one too, on the seven
          -- rows a full-screen textbox has room for.
          if self.index <= self.scroll then
            self.scroll = self.index - 1
          elseif self.index > self.scroll + GEN2_VISIBLE_ROWS then
            self.scroll = self.index - GEN2_VISIBLE_ROWS
          end
          self.scroll = math.max(0, math.min(self.scroll,
            math.max(0, #self.rows - GEN2_VISIBLE_ROWS)))
        else
          local OptionRows = engineOptionRows()
          if OptionRows and OptionRows.clampScroll then
            self.scroll = OptionRows.clampScroll(
              self.index, self.scroll, #self.rows, nil)
          end
        end
      end

      -- The bottom line is the help for the row the cursor is on, or what the
      -- last press said.  A bench with no explanation on it is a bench you
      -- have to read the source of.
      local function footerFor(self)
        local row = self.rows[self.index]
        return context.said or (row and row.help) or "B:BACK"
      end

      local function drawGen1(self)
        local OptionRows = engineOptionRows()
        if not (OptionRows and OptionRows.draw) then return end
        OptionRows.draw(self.game, drawable(), self.index, self.scroll,
                        footerFor(self), nil)
      end

      -- The same rows in Gold's own idiom: one full-screen textbox, a label
      -- and its value two tiles apart, the cart's own cursor glyph.  The
      -- bench is a testing tool and it is tested THROUGH, so it reads in the
      -- game it is standing in rather than painting Red's four 20x4 option
      -- boxes over a Gold screen -- which is what src.ui.OptionRows would do
      -- if the loader let a Gold boot have it (src/mods/Loader.lua:115-117
      -- says so in as many words).
      local function drawGen2(self)
        local Chrome = require("src.ui.gen2.Chrome")
        Chrome.textbox(0, 0, Chrome.SCREEN_W - 2, Chrome.SCREEN_H - 2)
        local rows = drawable()
        for slot = 1, math.min(GEN2_VISIBLE_ROWS, #rows) do
          local row = rows[slot + self.scroll]
          if row then
            local labelY = 2 + (slot - 1) * 2
            Chrome.print(row.label, 2, labelY)
            Chrome.print(":", GEN2_VALUE_TX - 1, labelY + 1)
            Chrome.print(row.value() or "", GEN2_VALUE_TX, labelY + 1)
          end
        end
        Chrome.cursor(1, 2 + (self.index - self.scroll - 1) * 2)
        Chrome.print(footerFor(self), 1, Chrome.SCREEN_H - 2)
      end

      screen.draw = isGen2 and drawGen2 or drawGen1

      return screen
    end,
  })

  -- ------- the door
  --
  -- A row on the START menu, added rather than taking anything over: the
  -- suite already retargets MODS there, and a bench that displaced somebody
  -- else's entry would be a testing tool changing the thing under test.
  mod.hooks:wrap("ui.start_menu.items", function(nextLink, game, items)
    local out = nextLink(game, items)
    if type(out) ~= "table" then return out end
    for _, item in ipairs(out) do
      if item and item.id == "bench" then return out end
    end
    local row = {
      id = "bench",
      label = "BENCH",
      onSelect = function() mod.ui.push(game, SCREEN_ID) end,
    }
    -- Second to last, so it sits above EXIT rather than under it: EXIT is the
    -- one entry a player reaches for without reading, and a row that pushes
    -- it down is a row that gets pressed by accident.  An empty menu is not a
    -- menu this can be second-to-last in, so it simply goes on the end.
    if #out < 1 then
      out[1] = row
    else
      table.insert(out, #out, row)
    end
    return out
  end)

  -- ------- the sprite probe's two halves
  --
  -- The row is in rows.lua and is just a boolean; the measuring is here,
  -- because it patches an engine class and hooks a frame, and rows.lua is the
  -- half that is pure enough to test.  Both halves are inert while the row
  -- says OFF: one boolean test per sprite draw, and an early return in the
  -- hook.
  --
  -- The counter is the OUTERMOST wrapper on SpriteRenderer.draw, deliberately.
  -- It counts draws ISSUED by the world pass rather than draws that reached
  -- the engine, so a wrapper below it that returns without drawing -- which is
  -- one of the three things this is trying to tell apart -- still shows up in
  -- the count.
  do
    local ok, SpriteRenderer = pcall(require, "src.render.SpriteRenderer")
    if ok and type(SpriteRenderer) == "table"
        and type(SpriteRenderer.draw) == "function" then
      local inner = SpriteRenderer.draw
      SpriteRenderer.draw = function(self, ...)
        if context.probe then context.drawn = (context.drawn or 0) + 1 end
        return inner(self, ...)
      end
    else
      mod.log:warn("sprite probe cannot count: SpriteRenderer did not load")
    end
  end

  -- ------- and how many of them the LOOP reached
  --
  -- The counter above is on SpriteRenderer.draw, which is the bottom of the
  -- stack: a wrapper above it that returns without drawing, or draws the
  -- sprite itself, never reaches it.  Gen1Follower does both -- it suppresses
  -- a follower with no mon and it draws map POKeMON with its own code -- so a
  -- low S cannot tell "the loop never reached them" from "the loop reached
  -- them and something above swallowed the draw".
  --
  -- NPC.draw is the other end: one call per NPC that the overworld's entity
  -- loop actually got to.  D against S is the whole question.  D10 S1 means
  -- the loop ran and ten draws were swallowed above the engine; D0 means the
  -- loop never ran at all and the branch that skipped it is the bug.
  do
    local ok, NPC = pcall(require, "src.world.NPC")
    if ok and type(NPC) == "table" and type(NPC.draw) == "function" then
      local inner = NPC.draw
      NPC.draw = function(self, ...)
        if context.probe then context.npcDrawn = (context.npcDrawn or 0) + 1 end
        return inner(self, ...)
      end
    else
      mod.log:warn("sprite probe cannot count NPC draws: NPC did not load")
    end
  end

  -- Whether a battle transition is what is on top.  Resolved once and compared
  -- by metatable, the way the suite's theme names an engine class, so a state
  -- that merely looks like one is not mistaken for it.
  local transitionClass
  do
    local ok, class = pcall(require, "src.render.BattleTransition")
    if ok and type(class) == "table" then transitionClass = class end
  end

  mod.hooks:wrap("render.hud", function(next, game, viewport)
    local result = next(game, viewport)
    if not context.probe then
      context.drawn, context.npcDrawn = 0, 0
      return result
    end
    local ow = game and game.overworld
    local entities = (type(ow) == "table" and type(ow.entities) == "table")
      and #ow.entities or -1
    -- ------- and how far a WALK down that list gets
    --
    -- E is `#`, which on a table with a hole in it is allowed to return any
    -- border -- with a nil at 2 and values at 3..11 both 1 and 11 are correct
    -- answers, and Lua's binary search usually gives the larger.  The draw
    -- loop is `ipairs`, which stops dead at the first nil.
    --
    -- So I is the number that matters: E11 I1 is a list with a hole one entry
    -- in, and a draw loop that quits after the player.  E11 I11 says the list
    -- is whole and the branch that skipped the loop is the bug instead.
    local walked = 0
    if type(ow) == "table" and type(ow.entities) == "table" then
      for _ in ipairs(ow.entities) do walked = walked + 1 end
    end
    local npcs = (type(ow) == "table" and type(ow.npcs) == "table")
      and #ow.npcs or -1
    -- ------- and whether a mod owns the world pass
    --
    -- With the list whole (I == E) and no NPC draw at all, the entity loop
    -- did not run -- and there is exactly one branch of OverworldState:
    -- drawWorld that skips it: `if override then -- the pipeline owns the
    -- whole frame; nothing else draws into the world`.  The tilt path still
    -- calls NPC.draw through its billboards, so it cannot be that one.
    --
    -- W says whether a registered world pipeline is eligible this frame.  W1
    -- with D0 means a pipeline is rendering the world and is not drawing the
    -- NPCs; W0 means the branch is not the explanation and the reading needs
    -- another look.
    local pipeline = 0
    do
      local okP, Pipelines = pcall(require, "src.render.Pipelines")
      if okP and type(Pipelines) == "table"
          and type(Pipelines.worldPipeline) == "function" then
        local okW, id = pcall(Pipelines.worldPipeline)
        if okW and id then pipeline = 1 end
      end
    end

    local states = game and game.stack and game.stack.states
    local top = type(states) == "table" and states[#states] or nil
    local inTransition = (transitionClass and top
      and getmetatable(top) == transitionClass) and 1 or 0
    -- And what the theme's last frame saw, through the bundle's own export
    -- rather than by reaching into it: B boxes RECORDED, P panels PRODUCED,
    -- Z zones handed in.  A box that stays white with B0 was never recorded
    -- and the bug is in the recorder; one with B1 P0 was recorded and never
    -- panelled, and the bug is in the rule.  Two different files.
    local boxes, panels, zoneCount = 0, 0, 0
    local ui = context.find("gen1_wild_ui_nightly")
    local probe = type(ui) == "table" and type(ui.exports) == "table"
      and ui.exports.themeProbe or nil
    if type(probe) == "function" then
      local okProbe, b, p, z = pcall(probe)
      if okProbe then boxes, panels, zoneCount = b or 0, p or 0, z or 0 end
    end
    -- ------- and the frame that matters, kept rather than shown
    --
    -- The sprites pop on the FIRST frame a battle transition exists, which is
    -- one frame out of a wipe that lasts a second: catching it in a
    -- screenshot means filming the screen and scrubbing. So the numbers from
    -- that exact frame are snapshotted on the 0 -> 1 edge and held, and the
    -- bench shows them as an ordinary row afterwards. Walk into a battle,
    -- open the bench, read LAST BATTLE.
    if inTransition == 1 and not context.inTransition then
      context.lastBattle = ("E%d I%d N%d S%d D%d W%d")
        :format(entities, walked, npcs, context.drawn or 0,
                context.npcDrawn or 0, pipeline)
    end
    context.inTransition = inTransition == 1

    local line = ("E%d I%d N%d S%d D%d W%d T%d  B%d P%d Z%d")
      :format(entities, walked, npcs, context.drawn or 0,
              context.npcDrawn or 0, pipeline, inTransition,
              boxes, panels, zoneCount)
    context.drawn = 0
    context.npcDrawn = 0
    -- Screen space, top left, over everything: this is a tool status line and
    -- is meant to be readable in a screenshot rather than to fit the game.
    local x = (type(viewport) == "table" and tonumber(viewport.x) or 0) + 4
    local y = (type(viewport) == "table" and tonumber(viewport.y) or 0) + 4
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", x - 2, y - 2, 370, 18)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(line, x, y)
    return result
  end)

  mod.log:info("test bench on the START menu -- nightly only, %d rows",
    #Rows.build(context))
end
