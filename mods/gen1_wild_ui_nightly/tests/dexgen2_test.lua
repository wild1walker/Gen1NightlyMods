-- Headless coverage of the Pokedex's Gold arm.
--
-- Two halves, and both are things a harness can actually check.
--
-- dexdata.lua is pure -- no require, no love, no engine module -- so the Gen 2
-- reading of a species is driven directly: six base stats instead of five,
-- `into` instead of `species` on an evolution row, `levelMoves` instead of
-- `learnset`, and a label for each of Gold's five evolution methods.  That is
-- where a Gen 2 port of a data reader goes wrong, and none of it needs a
-- screen.
--
-- gen2.lua's page arithmetic is the other half: which page PAGE goes to, how
-- many rows a page has, and where the scroll clamps.  The DRAWING needs a
-- window and is not tested here.
--
-- Run:  luajit tests/dexgen2_test.lua

package.path = "./?.lua;" .. package.path

local passed, failed = 0, 0
local function ok(condition, description)
  if condition then
    passed = passed + 1
  else
    failed = failed + 1
    io.write("  FAIL  ", description, "\n")
  end
end
local function eq(actual, expected, description)
  local same = actual == expected
  if not same then
    description = ("%s (got %s, wanted %s)")
      :format(description, tostring(actual), tostring(expected))
  end
  ok(same, description)
end

local function load_(path, ...)
  local handle = assert(io.open(path, "r"), path .. " is missing")
  local source = handle:read("*a")
  handle:close()
  return assert(load(source, "@" .. path))(...)
end

local DexData = load_("modules/Gen1Dex/dexdata.lua")
local Gen2Dex = load_("modules/Gen1Dex/gen2.lua")

-- ------------------------------------------------------ the six base stats

do
  io.write("six base stats, not five\n")

  local gen1Def = {
    baseStats = { hp = 45, attack = 49, defense = 49, speed = 45,
                  special = 65 },
  }
  local gen2Def = {
    baseStats = { hp = 45, attack = 49, defense = 49, speed = 45,
                  specialAttack = 65, specialDefense = 65 },
  }

  eq(#DexData.statKeys(gen1Def), 5, "a Gen 1 block asks for five keys")
  eq(#DexData.statKeys(gen2Def), 6, "a Gen 2 block asks for six")

  -- Asked of the DATA, not of the game version, so a hand-built table gets
  -- the right answer without pretending to be a cart.
  eq(DexData.statKeys({}), DexData.statKeys(gen1Def),
     "and a def with no stats at all falls to the Gen 1 five rather than "
     .. "guessing")

  local gen1 = DexData.stats({}, gen1Def)
  eq(#gen1.stats, 5, "five rows out of a Gen 1 def")
  eq(gen1.bst, 253, "and its total")

  local gen2 = DexData.stats({}, gen2Def)
  eq(#gen2.stats, 6, "six rows out of a Gen 2 def")
  eq(gen2.bst, 318, "and a total that counts both specials")

  local keys = {}
  for _, s in ipairs(gen2.stats) do keys[#keys + 1] = s.key end
  eq(table.concat(keys, " "), "HP ATK DEF SPD SP.A SP.D",
     "in the cart's own order, with the two specials told apart")

  local byKey = {}
  for _, s in ipairs(gen2.stats) do byKey[s.key] = s.value end
  eq(byKey["SP.A"], 65, "special attack reads its own field")
  eq(byKey["SP.D"], 65, "and special defense its own")
  eq(byKey.SPD, 45, "and SPD is still SPEED, not a special")
end

-- ------------------------------------------------------- the five methods

do
  io.write("Gold's five evolution methods\n")

  local data = {
    pokemon = {
      IVYSAUR = { name = "IVYSAUR" },
      VAPOREON = { name = "VAPOREON" },
      MACHAMP = { name = "MACHAMP" },
      UMBREON = { name = "UMBREON" },
      HITMONLEE = { name = "HITMONLEE" },
    },
    items = {
      WATER_STONE = { name = "WATER STONE" },
      KINGS_ROCK = { name = "KING'S ROCK" },
    },
  }

  local function labelOf(evo)
    -- No save, so nothing is masked and the row is read as-is.
    local out = DexData.stats(data, { evolutions = { evo } })
    return out.evolutions[1]
  end

  local level = labelOf({ method = "EVOLVE_LEVEL", level = 16,
                          into = "IVYSAUR" })
  eq(level.label, "LEVEL 16", "a level")
  eq(level.name, "IVYSAUR",
     "and the target read off `into`, which is what Gold's extractor writes")
  eq(level.species, "IVYSAUR", "carried on as `species` for the drawer")

  eq(labelOf({ method = "EVOLVE_ITEM", item = "WATER_STONE",
               into = "VAPOREON" }).label, "WATER STONE",
     "a stone names itself")

  eq(labelOf({ method = "EVOLVE_TRADE", into = "MACHAMP" }).label, "TRADE",
     "a plain trade")
  eq(labelOf({ method = "EVOLVE_TRADE", item = "KINGS_ROCK",
               into = "MACHAMP" }).label, "TRADE + KING'S ROCK",
     "and one that wants a held item says which")

  eq(labelOf({ method = "EVOLVE_HAPPINESS", time = "ANYTIME",
               into = "UMBREON" }).label, "HAPPINESS", "happiness, any time")
  eq(labelOf({ method = "EVOLVE_HAPPINESS", time = "NITE",
               into = "UMBREON" }).label, "HAPPY NITE", "...and at night")
  eq(labelOf({ method = "EVOLVE_HAPPINESS", time = "MORNDAY",
               into = "UMBREON" }).label, "HAPPY MORN/DAY", "...and by day")

  -- TYROGUE, and only TYROGUE.
  eq(labelOf({ method = "EVOLVE_STAT", level = 20, comparison = "ATK_GT_DEF",
               into = "HITMONLEE" }).label, "LEVEL 20 ATK>DEF",
     "the stat comparison keeps BOTH the level and which stat won")

  -- A method nobody has taught this file about is still true, and never blank.
  eq(labelOf({ method = "EVOLVE_SOMETHING", into = "IVYSAUR" }).label,
     "EVOLVE_SOMETHING", "an unknown method falls back to its own id")

  -- The registry still wins, on either of its two names, so a content mod
  -- that describes its own method gets that description here.
  local withRegistry = {
    pokemon = data.pokemon,
    gen2EvolutionMethods = {
      EVOLVE_LEVEL = { describe = function() return "A DIFFERENT WAY" end },
    },
  }
  local described = DexData.stats(withRegistry,
    { evolutions = { { method = "EVOLVE_LEVEL", level = 16,
                       into = "IVYSAUR" } } })
  eq(described.evolutions[1].label, "A DIFFERENT WAY",
     "the gen2EvolutionMethods registry outranks this file's own words")
end

-- ------------------------------------------------------------ the spoiler

do
  io.write("an unseen evolution is still masked\n")
  local data = { pokemon = { IVYSAUR = { name = "IVYSAUR" } } }
  local def = { evolutions = { { method = "EVOLVE_LEVEL", level = 16,
                                 into = "IVYSAUR" } } }
  local save = { pokedex = { seen = {}, owned = {} } }
  local out = DexData.stats(data, def, save)
  eq(out.evolutions[1].name, "?????",
     "a target you have never met is masked on Gold exactly as on Red -- the "
     .. "mask reads `into` too")
  eq(out.evolutions[1].label, "LEVEL 16", "but HOW is still printed")

  save.pokedex.seen.IVYSAUR = true
  local seen = DexData.stats(data, def, save)
  eq(seen.evolutions[1].name, "IVYSAUR", "and it is named once you have met one")
end

-- --------------------------------------------------------- the level-up list

do
  io.write("the learnset, under Gold's name for it\n")
  local data = { moves = { TACKLE = { name = "TACKLE", type = "NORMAL" } } }

  local gen1 = DexData.moves(data, { learnset = { { level = 1,
                                                    move = "TACKLE" } } })
  eq(#gen1.learned, 1, "Gen 1 stores it as `learnset`")

  local gen2 = DexData.moves(data, { levelMoves = { { level = 1,
                                                      move = "TACKLE" } } })
  eq(#gen2.learned, 1, "Gold stores it as `levelMoves`, and both are read")
  eq(gen2.learned[1].name, "TACKLE", "with the same row shape either way")
  eq(gen2.learned[1].level, 1, "level included")

  -- A def carrying neither is empty rather than an error.
  eq(#DexData.moves(data, {}).learned, 0, "a def with no list at all is empty")
end

-- ---------------------------------------------------------- the page cycle

do
  io.write("PAGE counts on past the cart's two\n")

  eq(Gen2Dex.LAST_PAGE, 5, "two pages of the cart's, then three of ours")
  eq(Gen2Dex.FIRST_OURS, 3, "and ours start at three")
  eq(Gen2Dex.PAGES[1], "dex", "page one is the cart's")
  eq(Gen2Dex.PAGES[2], "dex", "and so is page two")
  eq(Gen2Dex.PAGES[3], "stats", "then STATS")
  eq(Gen2Dex.PAGES[4], "evolves", "then EVOLVES")
  eq(Gen2Dex.PAGES[5], "moves", "then MOVES")

  eq(Gen2Dex.nextPage(1), 2, "1 -> 2, which is what the cart does")
  eq(Gen2Dex.nextPage(2), 3, "2 -> 3, which is where ours begin")
  eq(Gen2Dex.nextPage(3), 4, "3 -> 4")
  eq(Gen2Dex.nextPage(4), 5, "4 -> 5")
  eq(Gen2Dex.nextPage(5), 1, "and 5 wraps back to the cart's first")

  -- The wrap has to cope with a page nobody set: the cart writes `page` and a
  -- save loaded mid-entry could carry anything.
  eq(Gen2Dex.nextPage(nil), 2, "no page reads as page one")
  eq(Gen2Dex.nextPage(0), 1, "and one below the range wraps to the start")
  eq(Gen2Dex.nextPage(99), 1, "as does one above it")
end

-- ------------------------------------------------------------- the scroll

do
  io.write("scrolling a page longer than its panel\n")

  local content = {
    evolutions = { {}, {}, {}, {}, {} },          -- EEVEE, on this cart
    moveRows = { {}, {}, {}, {}, {}, {}, {}, {} },
  }

  eq(Gen2Dex.rowCount("stats", content), 0,
     "the stats page never scrolls: six stats and a total fit exactly")
  eq(Gen2Dex.rowCount("evolves", content), 5, "EVEE has five evolutions here")
  eq(Gen2Dex.rowCount("moves", content), 8, "and eight rows of moves")
  eq(Gen2Dex.rowCount("moves", {}), 0, "a species with nothing reads zero")

  -- Four visible rows, so a five-row page has exactly one step in it.
  eq(Gen2Dex.clampScroll(0, 5, 4), 0, "the top")
  eq(Gen2Dex.clampScroll(1, 5, 4), 1, "one step down")
  eq(Gen2Dex.clampScroll(2, 5, 4), 1, "and no further -- the last row is shown")
  eq(Gen2Dex.clampScroll(-1, 5, 4), 0, "nor above the top")
  eq(Gen2Dex.clampScroll(3, 4, 4), 0,
     "a page that exactly fills its panel does not scroll at all")
  eq(Gen2Dex.clampScroll(9, 3, 4), 0, "nor one shorter than it")
  eq(Gen2Dex.clampScroll(nil, 8, 4), 0, "an unset scroll is the top")
end

-- ------------------------------------------------- what the mod publishes

do
  io.write("the pure surface survives the generation branch\n")

  package.loaded["src.core.GameVersion"] = {
    generation = function() return 2 end,
    get = function() return "gold" end,
    isYellow = function() return false end,
  }

  -- The list and the chrome it draws from reach these three.  Stubbed rather
  -- than skipped: without them chrome.lua does not build, the install logs a
  -- warning and moves on, and the registration this block is about would be
  -- missing for a reason that has nothing to do with the code under test.
  local noop = function() end
  package.loaded["src.render.Font"] = {
    draw = noop, drawCode = noop, drawBox = noop, BORDER = {},
  }
  package.loaded["src.ui.Theme"] = { cursor = 0, cursorHollow = 0 }
  package.loaded["src.core.Strings"] = setmetatable(
    { source = function(s) return s end },
    { __call = function(_, s, ...)
        if select("#", ...) > 0 then return string.format(s, ...) end
        return s
      end })

  local mod = {
    id = "gen1_wild_ui_nightly", path = "modules/Gen1Dex",
    exports = {}, stored = {},
  }
  mod.options = {
    define = function(_, schema) mod.defined = schema end,
    get = function(_, key) return mod.stored[key] end,
  }
  mod.log = {}
  for _, level in ipairs({ "info", "warn", "error", "debug" }) do
    mod.log[level] = function() end
  end
  mod.read = function(_, name)
    local handle = io.open("modules/Gen1Dex/" .. name, "r")
    if not handle then return nil, "no such sibling" end
    local body = handle:read("*a")
    handle:close()
    return body
  end
  mod.content = { screens = { registered = {},
    register = function(s, id, v) s.registered[id] = v end } }
  mod.hooks = { wrapped = {},
    wrap = function(self, name, fn) self.wrapped[name] = fn end }
  mod.events = { on = function() end }

  local install = load_("modules/Gen1Dex/main.lua")
  local ranOk = pcall(install, mod)
  ok(ranOk, "the Gold arm installs")

  -- The LIST is this suite's now (gen2list.lua, registered over the cart's
  -- own id).  Everything it does not draw is still the cart's, and is reached
  -- by building that screen and pointing it at a species -- so there is
  -- exactly one registration here, not four.
  eq(mod.content.screens.registered["Gen2PokedexMenu"] ~= nil, true,
     "the list is registered over the cart's dex id")
  local registrations = 0
  for _ in pairs(mod.content.screens.registered) do
    registrations = registrations + 1
  end
  eq(registrations, 1,
     "and it is the only one: the entry, the AREA map, SEARCH and UNOWN MODE "
     .. "stay the cart's")

  -- ...but the pure surface is still there, because it is generation-agnostic
  -- and other mods are built on it.
  for _, name in ipairs({ "buildList", "buildMoves", "buildMoveRows",
                          "buildStats", "buildDescription", "seenSpecies" }) do
    eq(type(mod.exports[name]), "function",
       ("%s is published on Gold too"):format(name))
  end

  -- And only the rows that can do something on Gold.
  local keys = {}
  for _, row in ipairs(mod.defined or {}) do keys[row.key] = true end
  ok(keys.gen2_pages, "EXTRA DEX PAGES is offered")
  ok(keys.gen2_list, "so is DEX LIST, which is what puts it there")
  -- The START menu is on both cartridges, so this row always meant something
  -- here.  It was registered BELOW the generation branch, so a Gold boot
  -- returned before reaching it and the row was neither offered nor installed.
  ok(keys.dex_label, "and START SAYS DEX, which the START menu can honour")
  ok(mod.hooks.wrapped["ui.start_menu.items"] ~= nil,
     "and the hook that renames the row is actually installed on Gold")
  ok(not keys.area_hints,
     "AREA HINTS is not: that screen is the cart's here, and a row that "
     .. "cannot do anything is worse than a missing one")
  -- SELECT VIEWS and LIST WRAPS DO mean something now: they are the list's
  -- own rows, and the list is this mod's.
  ok(keys.view_cycle, "SELECT VIEWS is offered, because the list is ours")
  ok(keys.wrap, "and LIST WRAPS with it")
  ok(not keys.nickname_backdrop, "nor NAME IN PLACE")
end

io.write(("dex gen2: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
