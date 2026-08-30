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

return function(mod)
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

        local ok, OptionRows = pcall(require, "src.ui.OptionRows")
        if ok and OptionRows and OptionRows.clampScroll then
          self.scroll = OptionRows.clampScroll(
            self.index, self.scroll, #self.rows, nil)
        end
      end

      function screen:draw()
        local ok, OptionRows = pcall(require, "src.ui.OptionRows")
        if not (ok and OptionRows and OptionRows.draw) then return end
        local row = self.rows[self.index]
        -- The bottom line is the help for the row the cursor is on, or what
        -- the last press said.  A bench with no explanation on it is a bench
        -- you have to read the source of.
        local footer = context.said or (row and row.help) or "B:BACK"
        OptionRows.draw(self.game, drawable(), self.index, self.scroll,
                        footer, nil)
      end

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

  mod.log:info("test bench on the START menu -- nightly only, %d rows",
    #Rows.build(context))
end
