-- INSPECT: what lives here, and what it refuses to say.
--
-- The list is ordered by a real number rather than a guess: Gen 1 rolls one
-- byte and walks ten cumulative thresholds (wild_encounters.asm), so a slot's
-- share is the width of its bucket and a species' share of a map is the sum
-- of the buckets it sits in.  Same buckets and same tier cuts as the dex's
-- AREA strip, so a COMMON in one is a COMMON in the other.
--
-- The two rules that are not arithmetic:
--
--   A location is often several maps, so shares are pooled and then rescaled
--   by the maps that CARRIED encounters.  Without that, a species owning half
--   the one patch of grass in a town is called VERY RARE because the town's
--   three gates have none.
--
--   A species never seen prints as question marks, in its rarity position,
--   and the header says the same.  The place still tells you something common
--   lives in the grass -- which anyone standing in it could work out -- but
--   not what.
--
-- Run:  luajit tests/inspect_test.lua

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

local function chunkOf(path)
  local handle = assert(io.open(path, "r"), path .. " is missing")
  local source = handle:read("*a")
  handle:close()
  return assert(load(source, "@" .. path))()
end

local warned = {}
local mod = {
  ui = { Font = { draw = function() end, drawBox = function() end,
                  drawCode = function() end } },
  options = { get = function() return true end },
  log = { warn = function(_, text) warned[#warned + 1] = text end,
          error = function() end, info = function() end },
}

local Inspect = chunkOf("modules/Gen1Dex/inspect.lua")(mod, {})

-- ------- a cartridge, as much of one as this touches

-- The ten cumulative thresholds, so a slot's width is derivable here rather
-- than copied: 51, 51, 39, 25, 25, 25, 13, 13, 11, 3.
local BUCKETS = { 51, 102, 141, 166, 191, 216, 229, 242, 253, 256 }

local function slots(...)
  local out = {}
  for i, species in ipairs({ ... }) do
    out[i] = { species = species, level = 3 + i }
  end
  return { slots = out }
end

local data = {
  constants = { encounterBuckets = BUCKETS },
  pokemon = {
    PIDGEY   = { name = "PIDGEY",   dex = 16 },
    RATTATA  = { name = "RATTATA",  dex = 19 },
    ODDISH   = { name = "ODDISH",   dex = 43 },
    TENTACOOL = { name = "TENTACOOL", dex = 72 },
  },
  encounters = {
    ROUTE_8 = {
      grass = slots("PIDGEY", "PIDGEY", "RATTATA", "ODDISH", "PIDGEY",
                    "RATTATA", "ODDISH", "ODDISH", "ODDISH", "ODDISH"),
    },
    ROUTE_8_GATE = {},                     -- a gate, and no grass in it
    ROUTE_8_WATER = { water = slots("TENTACOOL") },
  },
}

local save = { pokedex = { seen = { PIDGEY = true, ODDISH = true },
                           owned = { PIDGEY = true } } }

-- ---------------------------------------------------------------- the tests

io.write("a location's maps are found by identity, not by name\n")
do
  local here, elsewhere = { name = "ROUTE 8" }, { name = "ROUTE 8" }
  local byMap = { ROUTE_8 = here, ROUTE_8_GATE = here, VIRIDIAN = elsewhere }
  local ids = Inspect.mapsFor(byMap, here)
  eq(#ids, 2, "both of this location's maps")
  eq(ids[1], "ROUTE_8", "sorted, so the list does not shuffle between visits")
  eq(ids[2], "ROUTE_8_GATE", "...and the other one")
  eq(#Inspect.mapsFor(byMap, elsewhere), 1,
    "a second place with the SAME NAME is a different location and keeps its "
    .. "own maps")
  eq(#Inspect.mapsFor(nil, here), 0, "no map, no maps")
end

io.write("the order is the share of the encounter table, richest first\n")
do
  local rows = Inspect.roster(data, save, { "ROUTE_8" })
  eq(#rows, 3, "three species live here")
  -- PIDGEY holds slots 1, 2 and 5: 51 + 51 + 25 = 127.
  eq(rows[1].species, "PIDGEY", "PIDGEY owns half the table")
  eq(rows[1].share, 127, "...127 of 256")
  eq(rows[1].tier, "COMMON", "which is COMMON")
  -- ODDISH holds 4, 7, 8, 9 and 10: 25 + 13 + 13 + 11 + 3 = 65.
  eq(rows[2].species, "ODDISH", "then ODDISH")
  eq(rows[2].share, 65, "...65")
  -- RATTATA holds 3 and 6: 39 + 25 = 64.  One less than ODDISH, and that is
  -- the whole reason the order is computed rather than read off slot one.
  eq(rows[3].species, "RATTATA", "and RATTATA last, by one point")
  eq(rows[3].share, 64, "...64")
end

io.write("a location's empty maps do not dilute the ones with grass in\n")
do
  -- ROUTE_8_GATE carries no encounters at all.  Pooling across both maps and
  -- dividing by two would halve every share and call PIDGEY UNCOMMON.
  local rows = Inspect.roster(data, save, { "ROUTE_8", "ROUTE_8_GATE" })
  eq(rows[1].share, 127, "the gate is not counted against the route")
  eq(rows[1].tier, "COMMON", "so PIDGEY is still COMMON")

  local pooled = Inspect.roster(data, save, { "ROUTE_8", "ROUTE_8_WATER" })
  local byId = {}
  for _, row in ipairs(pooled) do byId[row.species] = row end
  eq(byId.PIDGEY.share, 63.5, "two maps that BOTH carry encounters do share")
  -- One water slot is the top bucket, 51, halved across the two maps.
  eq(byId.TENTACOOL.share, 25.5, "and the water map's own slots are pooled in")
  eq(byId.TENTACOOL.methods[1], "SURF", "named by how you would meet it")
end

io.write("the tiers are the AREA strip's cuts, on the same numbers\n")
do
  eq(Inspect.tierFor(51), "COMMON", "a whole top bucket is COMMON")
  eq(Inspect.tierFor(50), "UNCOMMON", "one short of it is not")
  eq(Inspect.tierFor(25), "UNCOMMON", "a middle bucket")
  eq(Inspect.tierFor(24), "RARE", "under that is RARE")
  eq(Inspect.tierFor(10), "RARE", "down to ten")
  eq(Inspect.tierFor(9), "VERY RARE", "and below it, VERY RARE")
end

io.write("what you have not seen, it will not name\n")
do
  local rows = Inspect.roster(data, save, { "ROUTE_8" })
  local byId = {}
  for _, row in ipairs(rows) do byId[row.species] = row end

  eq(byId.PIDGEY.name, "PIDGEY", "a species you own is named")
  eq(byId.PIDGEY.owned, true, "and wears the ball")
  eq(byId.ODDISH.name, "ODDISH", "a species you have merely seen is named")
  eq(byId.ODDISH.owned, false, "and wears no ball")
  eq(byId.RATTATA.name, "?????", "one you have never seen is not")
  eq(byId.RATTATA.seen, false, "...because it has not been seen")
  eq(byId.RATTATA.realName, "RATTATA",
    "though the row still knows, so a caller that has earned it can ask")

  -- The position is not hidden.  "Something lives in this grass, one point
  -- rarer than the ODDISH" is what a player walking in it would learn anyway.
  eq(rows[3].species, "RATTATA", "and it keeps its place in the order")
end

io.write("the header is masked the same way, or it is a spoiler\n")
do
  local rows = Inspect.roster(data, save, { "ROUTE_8" })
  local byId = {}
  for _, row in ipairs(rows) do byId[row.species] = row end

  -- Three pieces, not one string: the header is eighteen glyphs wide and
  -- "Lv11 VERY RARE GRASS" is twenty, which is how it came to be drawn
  -- through the box's own right border.
  local name, band, tail = Inspect.detail(byId.RATTATA)
  eq(name, "?????", "the header says nothing the list would not")
  ok(tail:find("GRASS", 1, true) ~= nil, "but it does say how")
  ok(band:find("Lv", 1, true) ~= nil, "and roughly what level")
  ok(#name + 1 + #band <= 18, "the name line fits its box")
  ok(#tail <= 18, "and so does the tier line")

  local ownedName = Inspect.detail(byId.PIDGEY)
  eq(ownedName, "PIDGEY", "a seen species is named in the header")

  local blank = Inspect.detail(nil)
  eq(blank, "?????", "and an empty list has nothing to say either")

  -- The worst case the header can be handed: a ten-glyph name, a two-ended
  -- level band, the longest tier and the longest method.
  local worst = { name = "NIDORAN\194\185", lo = 22, hi = 25,
                  tier = "VERY RARE", methods = { "SUPER ROD" } }
  local wn, wb, wt = Inspect.detail(worst)
  ok(#wb <= 7, "a two-ended band is seven glyphs at most")
  ok(#wt <= 18, "and the tier line stays inside the box")
end

io.write("a place with nothing in it says so rather than raising\n")
do
  eq(#Inspect.roster(data, save, { "ROUTE_8_GATE" }), 0, "a gate is empty")
  eq(#Inspect.roster(data, save, {}), 0, "so is no map at all")
  eq(#Inspect.roster(data, save, { "NOWHERE" }), 0, "so is a map that is not there")
  eq(#Inspect.roster(nil, nil, { "ROUTE_8" }), 0, "and a build with no data")
end

io.write("a save with no dex is a save that has seen nothing\n")
do
  local rows = Inspect.roster(data, {}, { "ROUTE_8" })
  eq(rows[1].name, "?????", "every name is masked")
  eq(rows[1].owned, false, "and no ball is drawn")
  eq(#rows, 3, "but the shape of the place is still the shape of the place")
end

io.write(("\ninspect: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
