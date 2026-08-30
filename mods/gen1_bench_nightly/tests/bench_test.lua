-- What the bench's rows do, with the five mods they reach standing in for.
--
-- The screen is not tested and does not need to be: it is the engine's own
-- OptionRows idiom, thirty lines of cursor and scroll.  What CAN be wrong is
-- everything in rows.lua -- a row that writes to the wrong key, a row that
-- crashes because the mod it drives is not installed, a cycle that will not
-- wrap -- and none of that needs a window.
--
-- The important case is the LAST one: a bench is installed beside whatever
-- happens to be there, and every row has to survive its mod being absent.  A
-- testing tool that takes the game down when a mod it wanted is missing is
-- worse than no testing tool.
--
-- Run:  luajit tests/bench_test.lua

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

local Rows = load_("rows.lua")

-- ------------------------------------------------------------- the stand-ins

-- The UI bundle, as `mod.find` hands it over: a handle whose exports carry
-- the bundle's own reader and writer plus the alias table its features are
-- registered under.
local function uiBundle(store)
  return {
    id = "gen1_wild_ui_nightly",
    exports = {
      optionValue = function(key) return store[key] end,
      optionWrite = function(key, value) store[key] = value return value end,
      features = {},
    },
  }
end

local function greenMod(state)
  return {
    id = "wild_green_nightly",
    exports = {
      suits = function()
        return { "green", "red", "orange", "blue", "purple",
                 "yellow", "pink", "black", "white", "grey" }
      end,
      suit = function() return state.suit end,
      setSuit = function(name) state.suit = name return true end,
    },
  }
end

local function qolBundle(state)
  return {
    id = "gen1_wild_qol_nightly",
    exports = {
      features = {
        gen1autosave = {
          id = "Gen1AutoSave",
          exports = {
            autosaveRequest = function() state.asked = (state.asked or 0) + 1 end,
            autosaveStatus = function() return state end,
          },
        },
      },
    },
  }
end

local function finder(mods)
  return function(name) return mods[name] end
end

local function rowsBy(context)
  local out = {}
  for _, row in ipairs(Rows.build(context)) do out[row.id] = row end
  return out
end

local function fakeGame(options)
  return {
    save = { options = options or {} },
    writeOptions = function() end,
  }
end

-- ------------------------------------------------------------------ cycling

io.write("the ring every value row turns on\n")
do
  local list = { "a", "b", "c" }
  eq(Rows.cycled(list, "a", 1), "b", "right goes forward")
  eq(Rows.cycled(list, "c", 1), "a", "and wraps")
  eq(Rows.cycled(list, "a", -1), "c", "left goes back, and wraps the other way")
  eq(Rows.cycled(list, "nonsense", 1), "b",
    "a value the list has never heard of starts from the beginning rather "
    .. "than refusing to move")
  eq(Rows.cycled({ { "GREEN", "green" }, { "RED", "red" } }, "green", 1), "red",
    "a list of label/value pairs cycles on the value")
end

-- ------------------------------------------------------------------ the rows

io.write("UI THEME is the same setting the OPTION screen turns\n")
do
  local store = { ui_theme = "light" }
  local context = { find = finder({ gen1_wild_ui_nightly = uiBundle(store) }) }
  local rows = rowsBy(context)
  local game = fakeGame()

  eq(rows.theme.value(game), "LIGHT", "it reads the bundle's own row")
  rows.theme.step(game, 1)
  eq(store.ui_theme, "dark", "and writes through the bundle's own writer")
  eq(rows.theme.value(game), "DARK", "which the row then reads back")
  rows.theme.step(game, 1)
  eq(store.ui_theme, "light", "and it wraps -- two values, not three")
end

io.write("PLAYER turns the row the mod publishes\n")
do
  local state = { suit = "green" }
  local context = { find = finder({ wild_green_nightly = greenMod(state) }) }
  local rows = rowsBy(context)

  eq(rows.player.value(), "GREEN", "the current colour, in the menu's voice")
  rows.player.step(nil, 1)
  eq(state.suit, "red", "one press moves it")
  rows.player.step(nil, -1)
  eq(state.suit, "green", "and back")
end

io.write("the three arena rows are the bundle's own options\n")
do
  local store = { arena_enabled = true, arena_bleed = true,
                  arena_field_test = false }
  local context = { find = finder({ gen1_wild_ui_nightly = uiBundle(store) }) }
  local rows = rowsBy(context)
  local game = fakeGame()

  eq(rows.arena_bleed.value(game), "ON", "EDGE TO EDGE starts on")
  rows.arena_bleed.step(game)
  eq(store.arena_bleed, false, "and turning it writes the bundle's key")
  eq(rows.arena_bleed.value(game), "OFF", "...which is the white bars back")

  eq(rows.arena_field_test.value(game), "OFF", "FIELD TEST starts off")
  rows.arena_field_test.step(game)
  eq(store.arena_field_test, true, "and is a toggle like the rest")
end

io.write("COLORS and BATTLE LAYOUT are the engine's own save options\n")
do
  local context = { find = finder({}) }
  local rows = rowsBy(context)
  local options = { battleLayout = "og" }
  local game = fakeGame(options)

  eq(rows.layout.value(game), "OG", "the layout reads the save")
  rows.layout.step(game)
  eq(options.battleLayout, "wide", "and writes it")
  eq(rows.layout.value(game), "WIDE", "which is where the bars are")
  rows.layout.step(game)
  eq(options.battleLayout, "og", "and back again")
end

io.write("the opponent the battle row sends out\n")
do
  local context = { find = finder({}) }
  local rows = rowsBy(context)

  eq(rows.species.value(), Rows.SPECIES[1], "a species is chosen to start with")
  rows.species.step(nil, 1)
  eq(context.species, Rows.SPECIES[2], "and the row cycles the list")

  eq(rows.level.value(), "5", "the level starts low")
  rows.level.step(nil, 1)
  eq(rows.level.value(), "10", "and moves in fives")
  for _ = 1, 18 do rows.level.step(nil, 1) end   -- 10 up to 100, in fives
  eq(rows.level.value(), "100", "up to a hundred")
  rows.level.step(nil, 1)
  eq(rows.level.value(), "5", "and wraps rather than stopping")
  rows.level.step(nil, -1)
  eq(rows.level.value(), "100", "left the other way")
end

io.write("ASK FOR A SAVE goes through the autosave's own request\n")
do
  local state = { due = false, dirty = true, asked = 0 }
  local context = { find = finder({ gen1_wild_qol_nightly = qolBundle(state) }) }
  local rows = rowsBy(context)

  eq(rows.save.value(), "PENDING", "something to save, not asked for yet")
  rows.save.activate(fakeGame())
  eq(state.asked, 1, "the row asks exactly once")
  eq(context.said, "ASKED", "and says so on the bottom line")

  state.due = true
  eq(rows.save.value(), "DUE",
    "a save that is due has not been written: it waits for a covered frame, "
    .. "which is the whole thing being tested")
  state.dirty = false
  eq(rows.save.value(), "DUE, CLEAN", "and says when there is nothing in it")
end

-- ------------------------------------------------- the case that matters

io.write("every row survives its mod not being there\n")
do
  local context = { find = finder({}) }     -- nothing installed at all
  local rows = Rows.build(context)
  local game = fakeGame()

  ok(#rows > 0, "the rows are still built")
  for _, row in ipairs(rows) do
    if type(row.value) == "function" then
      local fine, text = pcall(row.value, game)
      ok(fine, row.id .. " reads without raising")
      ok(type(text) == "string", row.id .. " still says something")
    end
    if type(row.step) == "function" then
      ok(pcall(row.step, game, 1), row.id .. " steps without raising")
    end
    if type(row.activate) == "function" then
      ok(pcall(row.activate, game), row.id .. " activates without raising")
    end
  end

  -- And every one of them says the same thing about it.  A dash rather than a
  -- plausible default: "LIGHT" would read as the theme being light, which is
  -- a different fact from there being no theme mod installed, and telling
  -- those two apart is most of what a bench is for.
  local by = rowsBy(context)
  eq(by.theme.value(game), Rows.DASH, "the theme row says the mod is missing")
  eq(by.player.value(game), Rows.DASH, "so does the player row")
  eq(by.arena_bleed.value(game), Rows.DASH, "and the arena rows")
end

io.write("a mod that answers with nonsense is not believed\n")
do
  local liar = {
    id = "wild_green_nightly",
    exports = { suit = function() error("boom") end },
  }
  local context = { find = finder({ wild_green_nightly = liar }) }
  local rows = rowsBy(context)
  eq(rows.player.value(), Rows.DASH, "an export that raises reads as absent")
  ok(pcall(rows.player.step, nil, 1), "and pressing it does nothing worse")
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
