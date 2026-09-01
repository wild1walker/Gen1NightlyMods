-- A page drawn over a WIDE battle is themed where it is drawn.
--
-- A classic 160x144 screen opened over a wide battle is CENTRED by the engine
-- before the render.zones hook sees anything: Game.lua computes
-- classicOffset = (uiWidth - 160) / 2 and runs centerClassicZones over the
-- zone owner's list, unless that owner is itself a wide battle.  So a page's
-- own whole-screen zone arrives at x = 72 on a 304-wide frame, not at x = 0.
--
-- theme.lua's `isWhole` demanded x == 0.  Every such page therefore failed the
-- test, pageZones threw the real list away, and the zone it synthesised in its
-- place was built at x = 0 because nothing told it otherwise -- so the page was
-- THEMED at 0..160 while it was DRAWN at 72..232.  Its right third kept the
-- light palette and a dark strip was laid over the battle to its left.
--
-- Run:  luajit tests/widezone_test.lua

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

local Theme = load_("runtime/theme.lua")

-- The engine's own arithmetic, quoted (src/core/Game.lua): the offset a
-- classic screen is centred by on a frame of `width` pixels.
local function classicOffset(width) return math.floor((width - 160) / 2) end

io.write("finding the GB frame wherever the engine put it\n")

eq(classicOffset(304), 72, "a wide battle centres a classic screen by 72")
eq(classicOffset(160), 0, "and a classic frame does not move it at all")

do
  local atOrigin = { x = 0, y = 0, w = 160, h = 144 }
  local centred = { x = 72, y = 0, w = 160, h = 144 }

  -- Asserted through isWhole first, and deliberately: it is the function the
  -- shipped theme already had, so a build without the fix FAILS this line
  -- rather than erroring on a name it has never heard of.  A guard that
  -- crashes is a guard that reports the wrong thing.
  ok(Theme.isWhole(atOrigin), "the frame at the origin is the whole frame")
  ok(Theme.isWhole(centred),
     "and so is the centred one -- which is the whole of the fix")

  -- The offset itself, for the callers that need to rebuild at it.
  ok(type(Theme.wholeAt) == "function", "wholeAt is published")
  eq(Theme.wholeAt and Theme.wholeAt(atOrigin), 0, "found at 0")
  eq(Theme.wholeAt and Theme.wholeAt(centred), 72, "and found at 72")

  eq(Theme.wholeAt and Theme.wholeAt({ x = 0, y = 0, w = 304, h = 144 }), nil,
     "a wide battle's own zone is not a classic frame")
  eq(Theme.wholeAt and Theme.wholeAt({ x = 0, y = 8, w = 160, h = 136 }), nil,
     "nor is a band inside one")
  eq(Theme.wholeAt and Theme.wholeAt({ x = 0, y = 0, w = 160 }), nil,
     "nor a zone missing a side")
  eq(Theme.wholeAt and Theme.wholeAt(nil), nil, "and nothing is nothing")
end

io.write("a page keeps its own list rather than a synthesised one\n")
do
  -- basePage is the other reader: "a list that opens on whole-screen greys is
  -- a black-and-white page whoever built it".  A centred page is still one.
  local GREYS = { { 255, 255, 255 }, { 170, 170, 170 }, { 85, 85, 85 },
                  { 0, 0, 0 } }
  ok(Theme.isGreys(GREYS), "the four DMG greys are greys")

  local centredPage = { { colors = GREYS, x = 72, y = 0, w = 160, h = 144 } }
  ok(Theme.isWhole(centredPage[1]),
     "so a page centred over a wide battle is recognised as a page")
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
