-- The POKeDEX list on Gold: this suite's screen, over the cart's id.
--
-- Red's list is a DECORATOR -- `List.new` calls the engine's own PokedexMenu
-- and rewrites `rows`, `items`, `draw` and `onSelectKey` on what comes back,
-- because Red's dex IS a ListMenu.  Gold's is not: it is one screen with a
-- `view` field and its own model for each of list / entry / area / search /
-- unown, with no `items` and no `rows` to decorate.  So the list is drawn
-- rather than decorated, off the same chrome.lua and the same DexData.
--
-- What this file pins is the part that is easy to get wrong when a screen is
-- rewritten rather than ported: that it reads Gold's save shape, that it
-- hands back to the cart for everything it does not draw, and that A on a
-- POKeMON you have never met opens the AREA map rather than refusing.
--
-- Run:  luajit tests/dexlist_gen2_test.lua

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
  if actual ~= expected then
    description = ("%s (got %s, wanted %s)")
      :format(description, tostring(actual), tostring(expected))
  end
  ok(actual == expected, description)
end

-- ---- enough LOVE and engine for the screen to build and draw

local noop = function() end
_G.love = {
  graphics = setmetatable({}, { __index = function() return noop end }),
  filesystem = { getInfo = function() return nil end, read = function() return nil end },
  timer = { getTime = function() return 0 end },
  audio = {},
  window = { getMode = function() return 160, 144 end },
}
for _, name in ipairs({ "getColor", "getShader", "getCanvas", "getScissor", "getFont" }) do
  love.graphics[name] = function() return nil end
end
love.graphics.newQuad = function() return {} end

local drawn = {}
package.loaded["src.render.Font"] = {
  draw = function(text, x, y) drawn[#drawn + 1] = { text = text, x = x, y = y } end,
  drawCode = function(code, x, y) drawn[#drawn + 1] = { code = code, x = x, y = y } end,
  drawBox = noop,
  BORDER = {},
}
package.loaded["src.ui.Theme"] = { cursor = "CURSOR", cursorHollow = "HOLLOW" }
package.loaded["src.core.Strings"] = setmetatable({
  source = function(s) return s end,
}, { __call = function(_, s, ...)
  if select("#", ...) > 0 then return string.format(s, ...) end
  return s
end })

local iconCalls = {}
package.loaded["src.ui.gen2.PartyMenu"] = {
  drawIcon = function(_, mon, px, py)
    iconCalls[#iconCalls + 1] = { species = mon and mon.species, x = px, y = py }
  end,
}

local pushed = {}
local builtScreens = {}
package.loaded["src.ui.Screens"] = {
  build = function(_game, id, _opts)
    local screen = { screenId = id, view = "list", index = 1,
                     order = function() return { "BULBASAUR", "CHARMANDER" } end }
    builtScreens[#builtScreens + 1] = screen
    return screen
  end,
}

local function slurp(path)
  local handle = assert(io.open(path))
  local text = handle:read("*a")
  handle:close()
  return text
end
local function chunkOf(path)
  return assert(load(slurp(path), "@" .. path))()
end

local mod = {
  path = "modules/Gen1Dex",
  log = { info = noop, warn = noop, error = noop },
  options = { get = function(_, key)
    if key == "wrap" then return true end
    if key == "view_cycle" then return true end
    return nil
  end },
}

local DexData = chunkOf("modules/Gen1Dex/dexdata.lua")
local C = chunkOf("modules/Gen1Dex/chrome.lua")(mod)
local List = chunkOf("modules/Gen1Dex/gen2list.lua")(mod, DexData, C)

ok(type(List.new) == "function", "the Gold list builds")

-- ---- a Gold save
--
-- Gold keeps the dex under `save.pokedex`, not at the top level the way Red
-- does.  A list that read the Gen 1 shape would mask every entry on the cart
-- it was written for.

local DATA = {
  constants = { dexSize = 4, dexDigits = 3 },
  pokemon = {
    BULBASAUR  = { id = "BULBASAUR",  dex = 1, name = "BULBASAUR" },
    IVYSAUR    = { id = "IVYSAUR",    dex = 2, name = "IVYSAUR" },
    CHARMANDER = { id = "CHARMANDER", dex = 3, name = "CHARMANDER" },
    SQUIRTLE   = { id = "SQUIRTLE",   dex = 4, name = "SQUIRTLE" },
  },
}

local function scene()
  drawn, iconCalls, pushed, builtScreens = {}, {}, {}, {}
  local game = {
    data = DATA,
    save = { pokedex = { seen = { CHARMANDER = true }, owned = { BULBASAUR = true } } },
    input = { wasPressed = function() return false end },
    stack = { push = function(_, s) pushed[#pushed + 1] = s end,
              pop = function() end },
  }
  game.stack.push = function(self, s) pushed[#pushed + 1] = s end
  return List.new(game, {}), game
end

do
  local screen = scene()
  eq(screen.screenId, "Gen2PokedexMenu",
     "it answers to the id Gold's START menu pushes")
  eq(#screen.items, 4, "every slot is a row, met or not")
  eq(screen.seen, 2, "SEEN counts the owned one too")
  eq(screen.owned, 1, "OWN counts only the caught")
end

-- ---- the rows say what has been met and what has not

do
  local screen = scene()
  eq(screen.items[1].label, "001 BULBASAUR", "a caught POKeMON is named")
  ok(screen.items[1].ball, "and carries the ball")
  eq(screen.items[3].label, "003 CHARMANDER", "a seen one is named")
  ok(not screen.items[3].ball, "with no ball")
  eq(screen.items[2].label, "002 -----",
     "one never met is masked, and still holds its slot")
  ok(not screen.items[2].seen, "and knows it has not been met")
  eq(screen.items[2].species, "IVYSAUR",
     "while still carrying the species, so AREA can open on it")
end

-- ---- SELECT cycles the three views

do
  local screen = scene()
  eq(screen.mode, "num", "it opens on the numbered view")
  screen:cycleView()
  eq(screen.mode, "alpha", "SELECT goes to A-Z")
  eq(#screen.items, 2, "which lists only what has been met")
  screen:cycleView()
  eq(screen.mode, "caught", "then to caught")
  eq(#screen.items, 1, "which lists only what has been caught")
  screen:cycleView()
  eq(screen.mode, "num", "and round")
end

-- An empty view would strand SELECT: an empty list answers nothing but A and
-- B, so there would be no way back out of it.
do
  drawn, iconCalls, pushed, builtScreens = {}, {}, {}, {}
  local game = {
    data = DATA,
    save = { pokedex = { seen = {}, owned = {} } },
    input = { wasPressed = function() return false end },
    stack = { push = noop, pop = noop },
  }
  local screen = List.new(game, {})
  screen:cycleView()
  eq(screen.mode, "num", "a view with nothing in it is not entered")
end

-- ---- A hands back to the cart, in the right view

do
  local screen = scene()
  screen.index = 1                       -- BULBASAUR, caught
  screen:choose()
  eq(#builtScreens, 1, "A builds the cart's own screen")
  eq(builtScreens[1].screenId, "Gen2PokedexMenu", "which is the cart's dex")
  eq(builtScreens[1].view, "entry", "opened on the ENTRY for one you have met")
  eq(builtScreens[1].index, 1, "pointed at the POKeMON the cursor was on")
  eq(#pushed, 1, "and pushed over this list")
end

do
  local screen = scene()
  screen.index = 2                       -- IVYSAUR, never met
  screen:choose()
  eq(builtScreens[1].view, "area",
     "A on one you have never met opens the AREA map rather than refusing")
end

do
  local screen = scene()
  screen.index = 2
  screen:open("search")
  eq(builtScreens[1].view, "search",
     "and SEARCH is the cart's own, not re-implemented here")
end

-- ---- the cursor walks and wraps

do
  local screen = scene()
  screen:move(1)
  eq(screen.index, 2, "DOWN steps a row")
  screen.index = 1
  screen:move(-1)
  eq(screen.index, 4, "UP off the top wraps to the end")
  screen:move(1)
  eq(screen.index, 1, "and DOWN off the end wraps back")
end

-- ---- it draws: an icon per row, and the footer

do
  local screen = scene()
  screen:draw()
  eq(#iconCalls, 4, "an icon is drawn for every row on screen")
  eq(iconCalls[1].species, "BULBASAUR", "the first row's own species")
  eq(iconCalls[2].species, "IVYSAUR",
     "including one never met -- it is drawn as a silhouette, not skipped")

  local footer
  for _, d in ipairs(drawn) do
    if type(d.text) == "string" and d.text:find("SEEN") then footer = d.text end
  end
  eq(footer, "SEEN   2  OWN   1",
     "the footer counts the whole dex in fixed three-digit fields")
end

io.write(("dexlist_gen2: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
