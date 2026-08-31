-- INSPECT: what lives here, read off the live encounter tables.
--
-- ------- the shape of it
--
-- The town map already answers WHERE a species lives -- that is the AREA
-- screen, and area.lua walks the encounter tables to build it.  This is the
-- same walk read backwards: stand on a place and ask what is in it.
--
-- A on a location opens a small menu rather than acting straight away.  FLY
-- already owned that press when the map was opened from the field move, and
-- a second thing on the same button needs somewhere to choose between them --
-- so both live in one menu, and the map opened from the BAG gets the same
-- menu with INSPECT alone in it.  B closes it and nothing has happened.
--
-- ------- rarity, which is the whole ordering
--
-- Gen 1 rolls one byte and walks ten cumulative thresholds
-- (wild_encounters.asm); a slot's share is the width of its bucket, and a
-- species' share of a map is the sum of the buckets it sits in.  That is a
-- real number out of 256 rather than a guess, so the list is ordered by it
-- and the tiers are named off it with the same cuts area.lua uses -- a
-- COMMON here and a COMMON in the AREA strip mean the same thing.
--
-- A location can be several maps (a town and its gate, a route and its two
-- halves), so the shares are pooled and then rescaled by how many maps
-- actually carried encounters.  Pooling without that would call a species
-- that owns half of one map "VERY RARE" because the other three maps in the
-- location have no grass at all.
--
-- ------- what it will not tell you
--
-- A species you have never seen prints as question marks, in its rarity
-- position, and so does the header.  The place still says "something common
-- lives in this grass" -- which is what a player standing there could work
-- out by walking in it -- but not what.  Anything else is the dex filling
-- itself in from a menu.
--
-- The caught ball is the dex's own, in the dex's own column (x 150), because
-- this list answers the same question the dex list answers and a ball that
-- moved between the two would read as a different mark.

return function(mod, C)
  local Font = mod.ui.Font
  local Inspect = {}

  -- Gen 1's ten cumulative slot thresholds out of 256 (wild_encounters.asm).
  -- The dataset carries its own under constants.encounterBuckets; this is the
  -- fallback for a stub that does not, and it is the same list area.lua
  -- falls back to so the two screens never disagree about a share.
  local BUCKETS = { 51, 102, 141, 166, 191, 216, 229, 242, 253, 256 }

  local METHODS = {
    grass = "GRASS",
    water = "SURF",
    old_rod = "OLD ROD",
    good_rod = "GOOD ROD",
    super_rod = "SUPER ROD",
  }

  -- The same cuts area.lua names its tiers with.
  local function tierFor(share)
    if share >= 51 then return "COMMON" end
    if share >= 25 then return "UNCOMMON" end
    if share >= 10 then return "RARE" end
    return "VERY RARE"
  end

  local UNKNOWN = "?????"

  -- ------- the data

  -- Every map id that shares a town-map location.  The town map builds one
  -- `loc` table and points several map ids at it (byMap), so identity is the
  -- test rather than the name -- two places can be called the same thing.
  function Inspect.mapsFor(byMap, loc)
    local out = {}
    if type(byMap) ~= "table" or loc == nil then return out end
    for mapId, entry in pairs(byMap) do
      if entry == loc then out[#out + 1] = mapId end
    end
    table.sort(out)
    return out
  end

  -- What lives across `mapIds`, richest share first.
  --
  -- Pure but for the dex flags: hand it a data table and a save and it
  -- answers, which is what lets tests/inspect_test.lua drive it with neither
  -- a town map nor a window.
  function Inspect.roster(data, save, mapIds)
    data = data or {}
    local buckets = (data.constants or {}).encounterBuckets or BUCKETS
    local encounters = data.encounters or {}
    local pooled, order, carried = {}, {}, 0

    for _, mapId in ipairs(mapIds or {}) do
      local record = encounters[mapId]
      local any = false
      if type(record) == "table" then
        for group, entry in pairs(record) do
          local previous = 0
          for index, slot in ipairs(type(entry) == "table" and entry.slots or {}) do
            local edge = buckets[index]
            local width = edge and (edge - previous) or 0
            if edge then previous = edge end
            local species = slot.species
            if species then
              any = true
              local row = pooled[species]
              if not row then
                row = { species = species, share = 0, methods = {},
                        seenMethod = {} }
                pooled[species] = row
                order[#order + 1] = row
              end
              row.share = row.share + width
              local level = tonumber(slot.level)
              if level then
                row.lo = math.min(row.lo or level, level)
                row.hi = math.max(row.hi or level, level)
              end
              if not row.seenMethod[group] then
                row.seenMethod[group] = true
                row.methods[#row.methods + 1] = METHODS[group]
                  or tostring(group):upper()
              end
            end
          end
        end
      end
      if any then carried = carried + 1 end
    end

    if carried == 0 then return {} end

    local pokemon = data.pokemon or {}
    local dex = type(save) == "table" and save.pokedex or nil
    local savedSeen = (type(dex) == "table" and dex.seen) or {}
    local savedOwned = (type(dex) == "table" and dex.owned) or {}

    for _, row in ipairs(order) do
      -- Rescaled by the maps that actually carried encounters, so a species
      -- that owns a fifth of the one map with grass in it is COMMON rather
      -- than being diluted by the three gates that have none.
      row.share = row.share / carried
      row.tier = tierFor(row.share)
      row.owned = savedOwned[row.species] and true or false
      row.seen = row.owned or (savedSeen[row.species] and true or false)
      local def = pokemon[row.species]
      row.realName = (def and def.name) or tostring(row.species)
      row.name = row.seen and row.realName or UNKNOWN
      row.dex = def and def.dex or nil
      table.sort(row.methods)
    end

    -- Richest first; ties by dex number so the order is stable between
    -- visits, and by id when a mod's species has no number.
    table.sort(order, function(a, b)
      if a.share ~= b.share then return a.share > b.share end
      if (a.dex or 0) ~= (b.dex or 0) then return (a.dex or 0) < (b.dex or 0) end
      return tostring(a.species) < tostring(b.species)
    end)
    return order
  end

  -- The header's second and third lines for the highlighted row.  Masked the
  -- same way the list is: a name here would undo the list's whole point.
  function Inspect.detail(row)
    if type(row) ~= "table" then return UNKNOWN, "" end
    local band = ""
    if row.lo and row.hi then
      band = row.lo == row.hi and ("Lv%d"):format(row.lo)
        or ("Lv%d-%d"):format(row.lo, row.hi)
    end
    local how = row.methods and row.methods[1] or ""
    local line = band
    if row.tier then line = (line ~= "" and (line .. " ") or "") .. row.tier end
    if how ~= "" then line = (line ~= "" and (line .. " ") or "") .. how end
    return row.name or UNKNOWN, line
  end

  Inspect.UNKNOWN = UNKNOWN
  Inspect.tierFor = tierFor

  -- ------- the screen

  local ROWS = 6                 -- text rows the list box holds
  local BALL_X, BALL_R = 150, 3.5
  local NAME_X = 16

  local function drawBall(y)
    local by = y + 4
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", BALL_X, by, BALL_R)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", BALL_X - BALL_R, by - 0.5, BALL_R * 2, 1)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.circle("fill", BALL_X, by, 1.2)
    love.graphics.setColor(1, 1, 1, 1)
  end

  function Inspect.screen(game, place, rows)
    local self = {
      game = game,
      place = place or "",
      rows = rows or {},
      index = 1,
      top = 1,
      isOpaque = true,
      -- one of the suite's own pages, so it goes dark with the rest of it
      gen1wildTheme = "settings",
    }

    function self:sgbPalettes(g)
      local ok, PaletteFX = pcall(require, "src.render.PaletteFX")
      if ok and PaletteFX and PaletteFX.wholeNamed then
        return PaletteFX.wholeNamed(g.data, "MEWMON")
      end
      return nil
    end

    local function clamp()
      if #self.rows == 0 then self.index, self.top = 1, 1 return end
      if self.index < 1 then self.index = #self.rows end
      if self.index > #self.rows then self.index = 1 end
      if self.index < self.top then self.top = self.index end
      if self.index > self.top + ROWS - 1 then self.top = self.index - ROWS + 1 end
      if self.top < 1 then self.top = 1 end
    end

    function self:update()
      local input = self.game.input
      if not input then return end
      if input:wasPressed("b") or input:wasPressed("a") then
        require("src.core.Sound").play(self.game.data, "Press_AB")
        self.game.stack:pop()
        return
      end
      if input:wasPressed("up") then self.index = self.index - 1; clamp()
      elseif input:wasPressed("down") then self.index = self.index + 1; clamp()
      end
    end

    function self:draw()
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", 0, 0, 160, 144)
      love.graphics.setColor(0, 0, 0, 1)

      Font.drawBox(0, 0, 20, 5)
      Font.draw(self.place, 8, 8)
      local row = self.rows[self.index]
      local name, detail = Inspect.detail(row)
      Font.draw(name, 8, 16)
      Font.draw(detail, 8, 24)

      Font.drawBox(0, 5, 20, 13)
      if #self.rows == 0 then
        Font.draw("NOTHING LIVES HERE", NAME_X, 56)
        love.graphics.setColor(1, 1, 1, 1)
        return
      end
      for i = 0, ROWS - 1 do
        local entry = self.rows[self.top + i]
        if entry then
          local y = 56 + i * 16
          if self.top + i == self.index then
            Font.drawCode(require("src.ui.Theme").cursor or 0xED, 8, y)
          end
          Font.draw(entry.name, NAME_X, y)
          if entry.owned then drawBall(y) end
        end
      end
      love.graphics.setColor(1, 1, 1, 1)
    end

    clamp()
    return self
  end

  -- ------- the press

  -- Wrapped once and idempotently: this mod's chunk runs again on every hot
  -- reload and every profile switch, and a second wrap would swallow the A
  -- press twice.  Same marker trick area.lua uses on TownMap.new.
  local MARK = "__gen1dex_inspect"

  local function offerable(state)
    -- The AREA screen is a TownMap with a species pinned to it and its own
    -- meaning for A; it is not a place to ask what lives here.
    if state.nestSpecies then return false end
    return mod.options:get("map_inspect") ~= false
  end

  local function openMenu(state)
    local game = state.game
    local loc = state.locs and state.locs[state.sel]
    if not loc then return end
    local items = {}

    if state.fly and state.flyMapIds and state.flyMapIds[state.sel] then
      local mapId = state.flyMapIds[state.sel]
      items[#items + 1] = { label = "FLY", onSelect = function()
        game.stack:pop()                  -- the map, as LoadTownMap_Fly does
        if state.onFly then state.onFly(mapId) end
      end }
    end

    items[#items + 1] = { label = "INSPECT", onSelect = function()
      local mapIds = Inspect.mapsFor(state.byMap, loc)
      local rows = Inspect.roster(game.data, game.save, mapIds)
      game.stack:push(Inspect.screen(game, loc.name or "", rows))
    end }

    require("src.core.Sound").play(game.data, "Press_AB")
    game.stack:push(mod.ui.Menu.new(game, items,
      { tx = 10, ty = 0, cancelable = true }))
  end

  function Inspect.install()
    local TownMap = require("src.ui.TownMap")
    if type(TownMap) ~= "table" or rawget(TownMap, MARK) then return end
    local base = TownMap.update
    if type(base) ~= "function" then return end
    TownMap.update = function(state, ...)
      local input = state.game and state.game.input
      if input and input.wasPressed and input:wasPressed("a")
          and offerable(state) then
        local ok, problem = pcall(openMenu, state)
        if not ok then
          mod.log:warn("map inspect stood down: %s", tostring(problem))
          return base(state, ...)
        end
        return
      end
      return base(state, ...)
    end
    rawset(TownMap, MARK, true)
  end

  return Inspect
end
