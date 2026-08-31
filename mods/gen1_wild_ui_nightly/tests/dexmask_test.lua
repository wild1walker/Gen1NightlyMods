-- A name the dex has not earned, and the one place that kept printing it.
--
-- The AREA screen is reachable for a POKeMON the dex has never met -- the
-- AREA ON UNSEEN row, and an evolution the entry screen is showing -- and its
-- header printed "CHARIZARD UNKNOWN" over the map.  The rest of that screen
-- is careful: the caption says EVOLVE CHARMELEON AT LV36 and names only what
-- you have already got.  The header handed over the answer.
--
-- So the token and the predicate live in the shared chrome, once, for every
-- screen that prints a species it might not have met.
--
-- Run:  luajit tests/dexmask_test.lua

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

package.preload["src.render.Font"] = function()
  return { draw = function() end, drawBox = function() end,
           drawCode = function() end, width = function(t) return #t * 8 end,
           split = function(t) local o = {} for i = 1, #t do o[i] = i end
                               return o end }
end

local function chunkOf(path)
  local handle = assert(io.open(path, "r"), path .. " is missing")
  local source = handle:read("*a")
  handle:close()
  return assert(load(source, "@" .. path))()
end

local mod = { options = { get = function() return true end },
              log = { warn = function() end, info = function() end } }
local C = chunkOf("modules/Gen1Dex/chrome.lua")(mod)

local data = { pokemon = {
  CHARMELEON = { name = "CHARMELEON", dex = 5 },
  CHARIZARD  = { name = "CHARIZARD",  dex = 6 },
} }

-- ---------------------------------------------------------------- the tests

io.write("a species you have met is named\n")
do
  local save = { pokedex = { seen = { CHARMELEON = true }, owned = {} } }
  eq(C.seenName(save, data, "CHARMELEON"), "CHARMELEON",
    "seen is enough -- you have stood in front of one")
end

io.write("and one you have not is not\n")
do
  local save = { pokedex = { seen = { CHARMELEON = true }, owned = {} } }
  eq(C.seenName(save, data, "CHARIZARD"), C.UNSEEN,
    "the AREA header said CHARIZARD UNKNOWN over the map; it says ????? now")
  eq(C.UNSEEN, "?????", "the same token the INSPECT list prints")
end

io.write("owning one counts as having met it\n")
do
  -- The dex sets both, but a save restored from an older build may carry only
  -- one -- and a POKeMON in the box is one you have met whatever seen says.
  local save = { pokedex = { seen = {}, owned = { CHARIZARD = true } } }
  eq(C.seenName(save, data, "CHARIZARD"), "CHARIZARD", "owned implies seen")
end

io.write("and a save with no dex has met nothing\n")
do
  eq(C.seenName({}, data, "CHARMELEON"), C.UNSEEN, "no pokedex table")
  eq(C.seenName(nil, data, "CHARMELEON"), C.UNSEEN, "no save at all")
end

io.write("a species the data does not know still answers\n")
do
  -- A mod's species, or a dex renumbered out from under a save: the id is
  -- the best name there is, and it is still masked until it is met.
  local save = { pokedex = { seen = { MISSINGNO = true }, owned = {} } }
  eq(C.seenName(save, data, "MISSINGNO"), "MISSINGNO",
    "the id stands in for a name the data has not got")
  eq(C.seenName({ pokedex = { seen = {}, owned = {} } }, data, "MISSINGNO"),
    C.UNSEEN, "and is masked when it has not been met")
  eq(C.seenName(save, nil, "MISSINGNO"), "MISSINGNO", "no data table either")
end

io.write(("\ndex mask: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
