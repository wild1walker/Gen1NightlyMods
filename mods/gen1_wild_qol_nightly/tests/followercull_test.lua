-- Headless coverage of the off-canvas cull in the follower's sprite draw.
--
-- The bug: map POKeMON rendered in the black margin ABOVE the game screen.
-- Measured off a capture, the two strays sat at world y -16 and -31 -- two
-- and four tiles above the top of a 144-tall canvas -- at exactly
-- `worldOrigin + y * scale`, which is the transform of one specific path.
--
-- That path is the POST-ZONE REDRAW.  For an unscaled follower this mod does
-- not draw into the world canvas at all: it queues the sprite with
-- PaletteFX.markSpriteRedraw, and the renderer replays it in SCREEN space
-- after the world blit.  It is the one draw in the game that skips the
-- canvas, so it is the one that does not get the canvas's clipping either --
-- and the renderer's scissor on that replay is the UI's rect, not the
-- world's, which on a portrait phone is the taller of the two.
--
-- So a cell entirely off the world canvas is never queued.  What is checked
-- here is that bound and nothing else: on the canvas is queued, off it is
-- not, a cell straddling the edge IS queued, and with no renderer to ask
-- nothing is culled.
--
-- Run:  luajit tests/followercull_test.lua

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

-- ------- the cull, as the mod spells it
--
-- Lifted rather than loaded: modules/Gen1Follower/main.lua is 1700 lines that
-- want a whole engine to load against, and the rule under test is eight of
-- them.  tools/check.py compares the two so they cannot drift.
local function cullFor(worldCanvas)
  local rendererModule
  return function(x, y)
    if rendererModule == nil then
      local ok_, found = pcall(function() return { worldCanvas = worldCanvas } end)
      rendererModule = (ok_ and type(found) == "table") and found or false
    end
    if not rendererModule then return false end
    local canvas = rendererModule.worldCanvas
    if not (canvas and canvas.getDimensions) then return false end
    local ok_, w, h = pcall(canvas.getDimensions, canvas)
    if not (ok_ and type(w) == "number" and type(h) == "number") then
      return false
    end
    return x + 16 <= 0 or y + 16 <= 0 or x >= w or y >= h
  end
end

local function canvasOf(w, h)
  return { getDimensions = function() return w, h end }
end

io.write("a cell off the world canvas is culled\n")
do
  local off = cullFor(canvasOf(160, 144))

  -- the two the capture caught, in world-canvas pixels
  eq(off(0, -16), true, "a POKeMON two tiles above the screen")
  eq(off(64, -32), true, "and one four tiles above it")

  eq(off(-16, 40), true, "off the left edge")
  eq(off(160, 40), true, "off the right")
  eq(off(40, 144), true, "off the bottom")
end

io.write("and a cell anyone could see is not\n")
do
  local off = cullFor(canvasOf(160, 144))
  eq(off(0, 0), false, "the top-left cell")
  eq(off(144, 128), false, "the bottom-right one")
  eq(off(72, 64), false, "the middle of the screen")

  -- The edge cases are the ones a sloppier bound gets wrong: a sprite one
  -- pixel onto the screen is a sprite you can see, and cutting it is a
  -- POKeMON that pops in at the edge of the map instead of walking on.
  eq(off(-15, 40), false, "one pixel of a sprite on the left edge")
  eq(off(40, -15), false, "one pixel over the top")
  eq(off(159, 40), false, "one pixel in from the right")
  eq(off(40, 143), false, "one pixel up from the bottom")
end

io.write("the bound is the canvas, not a hardcoded screen\n")
do
  -- A zoomed-out view has a bigger canvas, and the far edges move with it: a
  -- cell at x 200 is off a 160-wide canvas and on a 320-wide one.  Culling at
  -- a hardcoded 160x144 would take those away from a player who had zoomed
  -- out to look at them.
  local narrow, wide = cullFor(canvasOf(160, 144)), cullFor(canvasOf(320, 288))
  eq(narrow(200, 200), true, "past the right edge of a 160-wide canvas")
  eq(wide(200, 200), false, "...and comfortably on a 320-wide one")
  eq(wide(320, 200), true, "off the wider canvas is still off")

  -- The NEAR edges do not move, and it is worth saying why: canvas space
  -- starts at 0 whatever the canvas is, so a wider one reaches further right
  -- and further down and never further up.  A cell at y -16 is above every
  -- canvas there is, which is what makes the strays this cull removes
  -- unreachable at any zoom rather than merely off this screen.
  eq(narrow(0, -16), true, "a cell two tiles above the top is above any canvas")
  eq(wide(0, -16), true, "...on a wider one too")
end

io.write("with no renderer to ask, nothing is culled\n")
do
  eq(cullFor(nil)(0, -16), false,
     "a build this cannot reach behaves exactly as it did before")
  eq(cullFor({})(0, -16), false, "and so does a renderer with no canvas yet")
  eq(cullFor({ getDimensions = function() error("no") end })(0, -16), false,
     "and one whose canvas raises")
end

io.write(("\nfollower cull: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
