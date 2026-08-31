-- What the bench can drive, as a list of rows.
--
-- Every row is the same four things -- an id, a label, what it currently says,
-- and what a press does -- and nothing here draws or reads input.  That is the
-- point of the split: the screen is thirty lines of the engine's own
-- OptionRows idiom and needs no test, and this is the part that reaches into
-- five other mods and does, so tests/bench_test.lua drives it with the reaches
-- stubbed out.
--
-- ------- reaching the other mods
--
-- A row never touches another mod's storage.  It goes through what that mod
-- publishes, and stands down where nothing answers:
--
--   Gen1WildUI Nightly    exports optionValue / optionWrite, which is the
--                         bundle's own reader and writer over its merged
--                         schema -- so UI THEME, BACKDROPS, EDGE TO EDGE and
--                         FIELD TEST are read and written exactly the way the
--                         suite's own menu reads and writes them.
--   Wild Green Nightly    exports suits / suit / setSuit, added for this.
--   Gen1WildQOL Nightly   exports the autosave's own request and status.
--   the engine            COLORS and BATTLE LAYOUT are save options, and the
--                         battle is BattleState.newWild.
--
-- A row whose mod is not installed reports `--` and does nothing when
-- pressed, rather than disappearing: a bench that silently drops a row is a
-- bench that cannot tell you the mod is missing, and "the theme row is gone"
-- is exactly the thing worth being told.

local Rows = {}

local DASH = "--"

-- ------- the reaches, each one guarded
--
-- `find` is the host's mod.find.  Everything below assumes it may answer
-- nothing at all: a bench is installed beside whatever happens to be there.

local function exportsOf(find, name)
  if type(find) ~= "function" then return nil end
  local ok, handle = pcall(find, name)
  if not ok or type(handle) ~= "table" then return nil end
  local exports = handle.exports
  if type(exports) ~= "table" then return nil end
  return exports
end

-- A FEATURE inside one of the bundles, which is a second hop.
--
-- `mod.find` answers with the bundle, and the bundle's exports are the
-- bundle's: `optionValue`, `optionWrite`, and the alias table every feature in
-- it is registered under.  A feature's own exports are one level further in,
-- which is exactly the shape the paired bundle reads across (runtime/
-- registry.lua, acrossBundles), so this reads it the same way rather than
-- inventing a route.
--
-- Aliases are lowercased in that table, and a feature answers to every name it
-- ever went by -- its folder, its upstream id, its title.  The caller passes
-- the folder name and this lowercases it.
local function featureExports(find, bundle, feature)
  local exports = exportsOf(find, bundle)
  local features = exports and exports.features
  if type(features) ~= "table" then return nil end
  local handle = features[tostring(feature):lower()]
  if type(handle) ~= "table" then return nil end
  if type(handle.exports) == "table" then return handle.exports end
  -- a bundle released before handles were introduced publishes the exports
  -- table itself
  return handle
end

local function engine(name)
  local ok, module = pcall(require, name)
  if ok and type(module) == "table" then return module end
  return nil
end

local function options(game)
  return game and game.save and game.save.options or nil
end

-- ------- cycling
--
-- One helper, because every value row on this screen is a ring: find where we
-- are in a list, step, wrap.  A value the list does not contain starts from
-- the beginning rather than refusing to move, which is what a bench wants
-- when a mod has been updated under it.
local function cycled(list, current, direction)
  local at = 0
  for index, entry in ipairs(list) do
    if entry == current or (type(entry) == "table" and entry[2] == current) then
      at = index - 1
      break
    end
  end
  local next_ = list[(at + (direction or 1)) % #list + 1]
  if type(next_) == "table" then return next_[2] end
  return next_
end

-- ------- the rows

-- The suite's UI theme.  Read and written through the bundle's own reader, so
-- the bench and START > OPTION > UI THEME are the same setting rather than two
-- that agree until they do not.
local THEMES = { "light", "dark" }
local THEME_LABELS = { light = "LIGHT", dark = "DARK" }

local function themeRow(context)
  return {
    id = "theme",
    label = "UI THEME",
    help = "THE SUITE'S SCREENS: LIGHT OR DARK.",
    value = function()
      local ui = exportsOf(context.find, "gen1_wild_ui_nightly")
      if not (ui and ui.optionValue) then return DASH end
      local ok, current = pcall(ui.optionValue, "ui_theme")
      return (ok and THEME_LABELS[current]) or THEME_LABELS.light
    end,
    step = function(game, direction)
      local ui = exportsOf(context.find, "gen1_wild_ui_nightly")
      if not (ui and ui.optionValue and ui.optionWrite) then return false end
      local ok, current = pcall(ui.optionValue, "ui_theme")
      if not ok then current = "light" end
      pcall(ui.optionWrite, "ui_theme", cycled(THEMES, current, direction), game)
      return true
    end,
  }
end

-- The player's colour, which this channel made live.  The row is here because
-- "live" is exactly the claim worth being able to check: turn it and watch the
-- walker, without opening three menus first.
local function playerRow(context)
  return {
    id = "player",
    label = "PLAYER",
    help = "THE CHARACTER'S COLOUR. IT CHANGES WHERE YOU ARE STANDING.",
    value = function()
      local green = exportsOf(context.find, "wild_green_nightly")
      if not (green and green.suit) then return DASH end
      local ok, current = pcall(green.suit)
      return (ok and type(current) == "string" and current:upper()) or DASH
    end,
    step = function(_, direction)
      local green = exportsOf(context.find, "wild_green_nightly")
      if not (green and green.suit and green.suits and green.setSuit) then
        return false
      end
      local ok, current = pcall(green.suit)
      local okList, list = pcall(green.suits)
      if not (ok and okList and type(list) == "table" and list[1]) then
        return false
      end
      pcall(green.setSuit, cycled(list, current, direction))
      return true
    end,
  }
end

-- The display mode.  On the OPTION screen already, and on the bench because
-- the title screen's colours differ between modes and checking that means
-- flipping this one and looking -- which is two screens apart otherwise.
local function colorsRow()
  return {
    id = "colors",
    label = "COLORS",
    help = "THE DISPLAY MODE. THE TITLE SCREEN'S BANDS DIFFER BETWEEN THEM.",
    value = function(game)
      local PaletteFX = engine("src.render.PaletteFX")
      local o = options(game)
      if not (PaletteFX and o) then return DASH end
      local ok, label = pcall(PaletteFX.modeLabel, o.colors or "gbc")
      return ok and label or DASH
    end,
    step = function(game, direction)
      local PaletteFX = engine("src.render.PaletteFX")
      local o = options(game)
      if not (PaletteFX and o and PaletteFX.MODES) then return false end
      o.colors = cycled(PaletteFX.MODES, o.colors or "gbc", direction)
      pcall(PaletteFX.applyOptions, o)
      if game and type(game.writeOptions) == "function" then
        pcall(function() game:writeOptions() end)
      end
      return true
    end,
  }
end

-- OG or WIDE.  The engine's own row, mirrored, because the backdrop bug this
-- channel is chasing only shows in one of them.
local function layoutRow()
  return {
    id = "layout",
    label = "BATTLE LAYOUT",
    help = "OG IS 160X144. WIDE IS 304X144, WHICH IS WHERE THE BARS ARE.",
    value = function(game)
      local o = options(game)
      if not o then return DASH end
      return o.battleLayout == "wide" and "WIDE" or "OG"
    end,
    step = function(game)
      local o = options(game)
      if not o then return false end
      o.battleLayout = o.battleLayout == "wide" and "og" or "wide"
      if game and type(game.writeOptions) == "function" then
        pcall(function() game:writeOptions() end)
      end
      return true
    end,
  }
end

-- The three arena rows, all of them the bundle's own options under the
-- feature's prefix.  One builder, because they differ only by key and words.
local function arenaToggle(context, key, label, help)
  return {
    id = key,
    label = label,
    help = help,
    value = function()
      local ui = exportsOf(context.find, "gen1_wild_ui_nightly")
      if not (ui and ui.optionValue) then return DASH end
      local ok, current = pcall(ui.optionValue, key)
      if not ok then return DASH end
      return current ~= false and "ON" or "OFF"
    end,
    step = function(game)
      local ui = exportsOf(context.find, "gen1_wild_ui_nightly")
      if not (ui and ui.optionValue and ui.optionWrite) then return false end
      local ok, current = pcall(ui.optionValue, key)
      if not ok then return false end
      pcall(ui.optionWrite, key, current == false, game)
      return true
    end,
  }
end

-- Where the game thinks it is, which is the first question a backdrop that
-- picked the wrong slot raises.
local function whereRow()
  return {
    id = "where",
    label = "MAP",
    help = "THE MAP THE BACKDROP IS PICKED FROM.",
    value = function(game)
      local ow = game and game.overworld
      local id = ow and (ow.mapId or (ow.map and ow.map.id))
      if type(id) ~= "string" then return DASH end
      return id:upper()
    end,
  }
end

-- A wild battle, on demand.  Everything above is checked by fighting
-- something, and hunting for grass to check a fade is the reason a bench
-- exists.
local BENCH_SPECIES = { "PIDGEY", "RATTATA", "GEODUDE", "TENTACOOL",
                        "ZUBAT", "ONIX", "GYARADOS", "MEWTWO" }

local function speciesRow(context)
  return {
    id = "species",
    label = "OPPONENT",
    help = "WHAT THE BATTLE ROW BELOW SENDS OUT.",
    value = function() return context.species end,
    step = function(_, direction)
      context.species = cycled(BENCH_SPECIES, context.species, direction)
      return true
    end,
  }
end

local function levelRow(context)
  return {
    id = "level",
    label = "LEVEL",
    help = "AND AT WHAT LEVEL.",
    value = function() return tostring(context.level) end,
    step = function(_, direction)
      local next_ = context.level + (direction or 1) * 5
      if next_ < 5 then next_ = 100 elseif next_ > 100 then next_ = 5 end
      context.level = next_
      return true
    end,
  }
end

local function battleRow(context)
  return {
    id = "battle",
    label = "START A BATTLE",
    help = "PRESS A. THE BENCH CLOSES AND THE BATTLE OPENS.",
    activate = function(game)
      local BattleState = engine("src.battle.BattleState")
      local ow = game and game.overworld
      if not (BattleState and BattleState.newWild and ow
              and type(ow.pushBattle) == "function") then
        context.said = "NO BATTLE FROM HERE"
        return false
      end
      local ok, battle = pcall(BattleState.newWild, game,
                               context.species, context.level)
      if not ok or type(battle) ~= "table" or battle.dead then
        context.said = "NO HEALTHY POKEMON"
        return false
      end
      -- The bench is over the overworld and the battle wants the overworld
      -- under it, so this leaves before it pushes.
      if game.stack and game.stack.pop then game.stack:pop() end
      local pushed = pcall(ow.pushBattle, ow, battle)
      if not pushed then context.said = "THE BATTLE DID NOT OPEN" end
      return pushed
    end,
  }
end

-- Autosave: ask for one, and say what happened to the last.  The write itself
-- waits for a covered frame, which is the whole thing being tested -- so this
-- row asks, and the value says whether it has landed yet.
local function saveRow(context)
  return {
    id = "save",
    label = "ASK FOR A SAVE",
    help = "PRESS A. IT LANDS ON THE NEXT COVERED FRAME, NOT NOW.",
    value = function()
      local qol = featureExports(context.find, "gen1_wild_qol_nightly",
                                 "Gen1AutoSave")
      if not (qol and qol.autosaveStatus) then return DASH end
      local ok, status = pcall(qol.autosaveStatus)
      if not ok or type(status) ~= "table" then return DASH end
      if status.due then return status.dirty and "DUE" or "DUE, CLEAN" end
      return status.dirty and "PENDING" or "IDLE"
    end,
    activate = function()
      local qol = featureExports(context.find, "gen1_wild_qol_nightly",
                                 "Gen1AutoSave")
      if not (qol and qol.autosaveRequest) then
        context.said = "NO AUTOSAVE INSTALLED"
        return false
      end
      pcall(qol.autosaveRequest)
      context.said = "ASKED"
      return true
    end,
  }
end

-- ------- the list

-- ------- the sprite probe
--
-- Not a setting: an instrument, for one open bug.
--
-- The report is that the follower and every NPC pop away the moment a battle's
-- start animation begins, while the player stays -- in ADVANCED, under LIGHT
-- as well as DARK, for wild battles and trainer battles alike.  Reading the
-- code eliminated most of the ways that could happen and did not find the one
-- that did, so this stops guessing and measures instead.
--
-- ON draws one line over the game:
--
--   E<n>  how many things are in ow.entities -- the draw list itself
--   N<n>  how many are in ow.npcs
--   S<n>  how many SpriteRenderer draws were ISSUED last frame
--   T<n>  1 while a battle transition is on the stack
--
-- The three numbers separate the three possible causes on sight.  If E falls
-- to 1 when the transition starts, the draw list is being emptied and the
-- question is who empties it.  If E holds and S falls, the draws are being
-- suppressed one sprite at a time, somewhere below the loop.  If E and S both
-- hold while the screen shows nothing, they were drawn and the canvas they
-- were drawn onto is what went.
--
-- It costs a boolean test per sprite draw while it is off, which is the price
-- of it being available in a build a player is already running rather than a
-- build they have to be sent.
local function probeRow(context)
  return {
    id = "probe",
    label = "SPRITE PROBE",
    help = "E ENTITIES  N NPCS  S SPRITE DRAWS  T IN TRANSITION.",
    value = function() return context.probe and "ON" or "OFF" end,
    step = function()
      context.probe = not context.probe
      return true
    end,
  }
end

function Rows.build(context)
  context.species = context.species or BENCH_SPECIES[1]
  context.level = context.level or 5
  return {
    themeRow(context),
    playerRow(context),
    colorsRow(),
    layoutRow(),
    arenaToggle(context, "arena_enabled", "BACKDROPS",
      "THE PICTURE BEHIND A BATTLE."),
    arenaToggle(context, "arena_bleed", "EDGE TO EDGE",
      "OFF LEAVES THE WHITE BARS ROUND A WIDE BATTLE."),
    arenaToggle(context, "arena_field_test", "FIELD TEST",
      "MAGENTA MEANS THE PATCH RAN AND THE PICTURE WAS LOST."),
    whereRow(),
    speciesRow(context),
    levelRow(context),
    battleRow(context),
    saveRow(context),
    probeRow(context),
  }
end

Rows.featureExports = featureExports
Rows.SPECIES = BENCH_SPECIES
Rows.THEMES = THEMES
Rows.cycled = cycled
Rows.DASH = DASH

return Rows
