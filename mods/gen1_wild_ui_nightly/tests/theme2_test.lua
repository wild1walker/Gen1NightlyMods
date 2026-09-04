-- Headless coverage of UI THEME's Gold arm (runtime/theme2.lua).
--
-- The engine is not here, so nothing about how a frame LOOKS can be tested.
-- What can be, and is the whole of what this arm does, is the four numbers:
-- that DARK writes the reversal into Gold's own box palette, that LIGHT puts
-- back exactly what Gold shipped, that both happen IN PLACE so a screen
-- holding the table by identity still reads the live value, and -- the part
-- with the most ways to be wrong -- that the palette only moves for a page.
--
-- That last one is the test that matters.  Gold's battle field is
-- `Chrome.clear()`, which reads this same table, so a theme that did not ask
-- what was on the screen would paint every battle's field black.
--
-- Run:  luajit tests/theme2_test.lua

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

-- ---------------------------------------------------------------- harness

local function chunkOf(path)
  local handle = assert(io.open(path, "r"), path .. " is missing")
  local source = handle:read("*a")
  handle:close()
  return assert(load(source, "@" .. path))()
end

-- Gold's Chrome, reduced to the one field this file touches.  A fresh table
-- per test run, because the arm rewrites it and a shared one would carry the
-- last test's colours into the next.
local Chrome
local function freshChrome()
  Chrome = {
    DEFAULT_BOX_PALETTE = {
      { 255, 255, 255 }, { 255, 255, 255 }, { 255, 255, 255 }, { 0, 0, 0 },
    },
  }
  package.loaded["src.ui.gen2.Chrome"] = Chrome
  return Chrome
end

-- The page classes, as distinct tables standing in for engine modules.  Only
-- their identity matters: the arm matches a state by `getmetatable`.
local PartyMenuClass = {}
local BattleStateClass = {}
local TextBoxClass = {}
local StartMenuClass = {}
local ElevatorMenuClass = {}
local MenuFadeClass = {}

package.loaded["src.ui.gen2.PartyMenu"] = PartyMenuClass
package.loaded["src.ui.gen2.BattleState"] = BattleStateClass
package.loaded["src.render.TextBox"] = TextBoxClass
package.loaded["src.ui.gen2.StartMenu"] = StartMenuClass
package.loaded["src.ui.gen2.ElevatorMenu"] = ElevatorMenuClass
package.loaded["src.ui.gen2.MenuFade"] = MenuFadeClass

local Theme2 = chunkOf("runtime/theme2.lua")

-- A stand-in for the bundle context: the two things Theme2.new reads.
local function fakeContext(stored)
  local generation = 0
  local mod = {
    id = "gen1_wild_ui_nightly",
    logged = {},
    log = {
      info = function(_, ...) end,
      warn = function(self, fmt, ...) end,
    },
    hooks = {
      wrapped = {},
      wrap = function(self, name, fn) self.wrapped[name] = fn end,
    },
  }
  local optionset = {
    owned = nil,
    generation = function() return generation end,
    read = function(_, key) return stored[key] end,
    write = function(_, key, value)
      stored[key] = value
      generation = generation + 1
      return true
    end,
    own = function(row) optionsetOwned = row end,
  }
  optionset.own = function(row) optionset.owned = row end
  return { mod = mod, optionset = optionset }, mod, optionset
end

-- A stack whose top is `state`, with `state` given `class` as its metatable.
local function stackOf(...)
  local states = {}
  for _, entry in ipairs({ ... }) do
    local state = entry.state or {}
    if entry.class then setmetatable(state, entry.class) end
    states[#states + 1] = state
  end
  return { stack = { states = states } }
end

local function paletteOf(chrome)
  local out = {}
  for i = 1, 4 do
    local c = chrome.DEFAULT_BOX_PALETTE[i]
    out[i] = ("%d,%d,%d"):format(c[1], c[2], c[3])
  end
  return table.concat(out, " | ")
end

local WHITE_PAGE = "255,255,255 | 255,255,255 | 255,255,255 | 0,0,0"
local DARK_PAGE = "0,0,0 | 0,0,0 | 0,0,0 | 255,255,255"

-- ---------------------------------------------------------------- the row

do
  local stored = {}
  local context, mod, optionset = fakeContext(stored)
  local theme = Theme2.new(context)

  theme.defineRow()
  local row = optionset.owned
  ok(type(row) == "table", "defineRow owns a row")
  eq(row and row.key, "ui_theme",
     "and it is the SAME key the Gen 1 arm owns, so the setting survives a "
     .. "save moving between generations")
  eq(row and row.type, "choice", "a choice row")
  eq(row and row.default, "light", "defaulting to LIGHT, as on Gen 1")
  eq(row and #row.choices, 2, "with the same two choices")

  eq(theme.read(), "light", "an unset row reads LIGHT")
  eq(theme.label(), "LIGHT", "and labels itself LIGHT")

  theme.write("dark")
  eq(theme.read(), "dark", "a write is read back")
  eq(theme.label(), "DARK", "and relabels")

  theme.write("puce")
  eq(theme.read(), "dark", "a value that is not a theme is refused")

  theme.step(1)
  eq(theme.read(), "light", "step wraps DARK -> LIGHT")
  theme.step(1)
  eq(theme.read(), "dark", "and LIGHT -> DARK")
end

-- ---------------------------------------------------------- what a page is

do
  eq(Theme2.pageOf(nil), nil, "no game is not a page")
  eq(Theme2.pageOf({}), nil, "no stack is not a page")

  -- Gold's overworld is not a stack state at all, so the plain overworld is
  -- an EMPTY stack -- and that has to read as "not a page" rather than as
  -- "nothing said no".
  eq(Theme2.pageOf(stackOf()), nil,
     "an empty stack is the overworld, and the overworld is not a page")

  local page = stackOf({ class = PartyMenuClass })
  ok(Theme2.pageOf(page) ~= nil, "Gold's party menu is a page")

  local battle = stackOf({ class = BattleStateClass })
  eq(Theme2.pageOf(battle), nil,
     "a battle is NOT a page -- its field is Chrome.clear, and theming it "
     .. "would paint every battle black")

  -- One of ours needs no entry in the class list: the marker is enough.
  local ours = stackOf({ state = { gen1wildTheme = "settings" } })
  ok(Theme2.pageOf(ours) ~= nil, "a screen this suite registered is a page")

  -- An overlay is stepped over, so a confirm box on top of a page leaves the
  -- page themed...
  local boxOverPage = stackOf({ class = PartyMenuClass },
                              { class = TextBoxClass })
  ok(Theme2.pageOf(boxOverPage) ~= nil,
     "a text box over a page leaves the page themed")

  -- ...and a text box over the OVERWORLD is the page itself.  It is drawn
  -- through DEFAULT_BOX_PALETTE and the map under it is not, so the reversal
  -- lands on the box and nothing else -- and this is Gold's most-seen box, so
  -- leaving it out was leaving every line of dialogue in the game white on a
  -- dark boot.
  local boxOverWorld = stackOf({ class = TextBoxClass })
  eq(Theme2.pageOf(boxOverWorld), boxOverWorld.stack.states[1],
     "a text box over the overworld IS the page")

  -- A veil over the overworld is not, and that is the difference between the
  -- two kinds of thing that stand on top: a fade draws through nothing.
  local fadeOverWorld = stackOf({ class = MenuFadeClass })
  eq(Theme2.pageOf(fadeOverWorld), nil,
     "a fade over the overworld is not a page")

  -- The box that comes out of a BATTLE still finds a picture under it.
  local boxOverBattle = stackOf({ class = BattleStateClass },
                                { class = TextBoxClass })
  eq(Theme2.pageOf(boxOverBattle), nil,
     "a text box over a battle is not a page: the field behind it is "
     .. "Chrome.clear and cannot go dark with it")

  -- The two pages 0.32.23 left white.  Both are boxes standing over the
  -- world, which is the reason Red's START menu is excluded on Gen 1 -- and
  -- the reason does not cross, because Gold's world reads no box palette.
  local startMenu = stackOf({ class = StartMenuClass })
  ok(Theme2.pageOf(startMenu) ~= nil, "Gold's START menu is a page")

  local lift = stackOf({ class = ElevatorMenuClass })
  ok(Theme2.pageOf(lift) ~= nil, "and so is Gold's lift panel")

  -- The START menu with a submenu over it is still one themed frame.
  local partyOverStart = stackOf({ class = StartMenuClass },
                                 { class = PartyMenuClass })
  ok(Theme2.pageOf(partyOverStart) ~= nil,
     "the party menu opened from the START menu is a page")

  -- And an unknown full-screen owner ends the walk rather than being stepped
  -- over: whatever is under it is not what is on the screen.
  local unknownOverPage = stackOf({ class = PartyMenuClass },
                                  { class = BattleStateClass })
  eq(Theme2.pageOf(unknownOverPage), nil,
     "a picture standing on a page ends the walk")
end

-- ------------------------------------------------------------ the palette

do
  freshChrome()
  local stored = {}
  local context, mod = fakeContext(stored)
  local theme = Theme2.new(context)
  theme.install()

  local frame = mod.hooks.wrapped["core.update"]
  ok(type(frame) == "function",
     "the arm rides core.update, which runs BEFORE the frame is drawn")

  local ran = 0
  local function tick(game)
    return frame(function() ran = ran + 1 end, game, 1 / 60)
  end

  local page = stackOf({ class = PartyMenuClass })
  local battle = stackOf({ class = BattleStateClass })
  local world = stackOf()

  -- LIGHT
  tick(page)
  eq(paletteOf(Chrome), WHITE_PAGE, "LIGHT over a page leaves Gold's four")
  eq(ran, 1, "and the frame still runs")

  -- DARK, on a page
  theme.write("dark")
  tick(page)
  eq(paletteOf(Chrome), DARK_PAGE, "DARK over a page reverses them")

  -- DARK, on a battle -- the case the whole page test exists for
  tick(battle)
  eq(paletteOf(Chrome), WHITE_PAGE,
     "DARK over a BATTLE puts Gold's four back, so the field is not painted "
     .. "black")

  -- DARK, on the overworld
  tick(page)
  tick(world)
  eq(paletteOf(Chrome), WHITE_PAGE, "DARK over the overworld likewise")

  -- and back
  tick(page)
  eq(paletteOf(Chrome), DARK_PAGE, "and it comes back on the next page frame")

  -- LIGHT restores
  theme.write("light")
  tick(page)
  eq(paletteOf(Chrome), WHITE_PAGE, "LIGHT puts back exactly what Gold shipped")
end

-- ------------------------------------------------------------- in place

do
  freshChrome()
  local held = Chrome.DEFAULT_BOX_PALETTE
  local stored = { ui_theme = "dark" }
  local context, mod = fakeContext(stored)
  local theme = Theme2.new(context)
  theme.install()

  local frame = mod.hooks.wrapped["core.update"]
  frame(function() end, stackOf({ class = PartyMenuClass }), 1 / 60)

  ok(rawequal(held, Chrome.DEFAULT_BOX_PALETTE),
     "the table is rewritten IN PLACE, never replaced")
  eq(paletteOf({ DEFAULT_BOX_PALETTE = held }), DARK_PAGE,
     "so a screen holding it by identity -- TrainerCard passes it to "
     .. "seventeen calls -- reads the live colours")
end

-- -------------------------------------------------------- standing down

do
  freshChrome()
  local stored = { ui_theme = "dark" }
  local context, mod = fakeContext(stored)
  local warned = 0
  mod.log.warn = function() warned = warned + 1 end
  local theme = Theme2.new(context)
  theme.install()

  -- A read that raises stands in for anything going wrong mid-frame.
  local boom = true
  local realRead = theme.read
  theme.read = function() if boom then error("nope", 0) end return realRead() end

  local frame = mod.hooks.wrapped["core.update"]
  local ran = 0
  local ok1 = pcall(frame, function() ran = ran + 1 end,
                    stackOf({ class = PartyMenuClass }), 1 / 60)
  ok(ok1, "a theme that raises does not take the frame down with it")
  eq(ran, 1, "and the frame still runs")
  eq(paletteOf(Chrome), WHITE_PAGE, "with Gold's own four put back")
  eq(warned, 1, "it says so once")

  boom = false
  pcall(frame, function() ran = ran + 1 end,
        stackOf({ class = PartyMenuClass }), 1 / 60)
  eq(warned, 1, "and does not say it again")
  eq(paletteOf(Chrome), WHITE_PAGE,
     "having stood down for the session, it stays stood down")
end

-- ---------------------------------------------------------------- helpers

do
  local a = { { 1, 2, 3 }, { 4, 5, 6 }, { 7, 8, 9 }, { 10, 11, 12 } }
  local b = { { 1, 2, 3 }, { 4, 5, 6 }, { 7, 8, 9 }, { 10, 11, 12 } }
  ok(Theme2.same(a, b), "same() compares by value, not identity")
  b[3][2] = 0
  ok(not Theme2.same(a, b), "and notices one changed channel")
  ok(not Theme2.same(a, nil), "and copes with a missing palette")
end

io.write(("theme2: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
