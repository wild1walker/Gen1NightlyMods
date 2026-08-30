-- The bars around a battle, and the arithmetic that fills them.
--
-- A battle asks the renderer for a WHITE surround: Renderer:endFrame clears
-- the void to PaletteFX.paperShade for any state that sets `letterboxWhite`,
-- and a battle sets it.  That is right for the game it was written for -- the
-- field is white paper, so a white surround makes the paper look like it runs
-- off the screen instead of stopping at a rectangle.
--
-- Put a BACKDROP in the field and the reasoning inverts.  The paper is gone,
-- the surround is the only white left, and instead of disappearing it becomes
-- a bright frame around the art.  A WIDE battle is 304x144 -- very wide and no
-- taller -- so in an ordinary window the bars above and below it are the
-- biggest thing on the screen.  That is the white bar at the top of a wide
-- arena, and Gen1Arena now bleeds the backdrop's own edge into it.
--
-- What can be wrong here is arithmetic: a bar an edge short, a corner left as
-- paper, a rectangle with a negative width.  None of that needs a window, so
-- bleedRects is pure and this drives it directly.
--
-- Run:  luajit tests/arenableed_test.lua

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

-- ------------------------------------------------------------- the harness

-- Gen1Arena reads love.graphics.rectangle at chunk scope -- it shims that call
-- to swap the battle's field fill for a backdrop -- so `love` has to exist for
-- the file to load at all.  A stub, because nothing under test draws: the
-- geometry is bleedRects and it returns numbers.
_G.love = _G.love or { graphics = {} }
love.graphics.rectangle = love.graphics.rectangle or function() end
love.graphics.setColor = love.graphics.setColor or function() end
love.graphics.getColor = love.graphics.getColor or function() return 1, 1, 1, 1 end
love.graphics.getCanvas = love.graphics.getCanvas or function() return nil end
love.graphics.setCanvas = love.graphics.setCanvas or function() end
love.graphics.clear = love.graphics.clear or function() end
love.graphics.newQuad = love.graphics.newQuad
  or function(x, y, w, h) return { x = x, y = y, w = w, h = h } end
love.graphics.draw = love.graphics.draw or function() end

-- Gen1Arena installs at chunk scope off `local mod = ...`, so this is the
-- only other thing it needs.
local mod = {
  id = "gen1_wild_ui_nightly",
  exports = {},
  stored = {},
  hooked = {},
  events_on = {},
}
mod.options = {
  define = function() end,
  get = function(_, key) return mod.stored[key] end,
  set = function(_, key, value) mod.stored[key] = value end,
}
mod.log = {}
for _, level in ipairs({ "info", "warn", "error", "debug" }) do
  mod.log[level] = function() end
end
mod.hooks = { wrap = function(_, name, fn) mod.hooked[name] = fn end }
mod.events = { on = function(_, name, fn) mod.events_on[name] = fn end }
mod.assets = { path = function(_, p) return p end }
mod.storage = { writeBytes = function() return true end }
mod.content = {}

load_("modules/Gen1Arena/main.lua", mod)

local bleedRects = mod.exports.bleedRects
ok(type(bleedRects) == "function", "bleedRects is exposed")
ok(mod.hooked["render.letterbox"] ~= nil,
  "and the mod takes the seam the engine documents for void art")

local function by(rects)
  local out = {}
  for _, r in ipairs(rects or {}) do out[r.slice] = r end
  return out
end

-- Every pixel of the window is either the surface or exactly one bar.
local function covers(rects, view)
  local area = 0
  for _, r in ipairs(rects or {}) do
    if r.w <= 0 or r.h <= 0 then return false, "a rectangle with no area" end
    area = area + r.w * r.h
  end
  local want = view.ww * view.wh - view.vpw * view.vph
  if area ~= want then
    return false, ("bars cover %d of the %d that are not the surface")
      :format(area, want)
  end
  return true
end

-- ---------------------------------------------------------------- the bars

io.write("a wide battle in an ordinary window\n")
do
  -- 304x144 blown up to 912x432 and centred in a 1000x700 window: the bars
  -- above and below are 134 tall, which is the complaint.
  local view = { ww = 1000, wh = 700, ox = 44, oy = 134, vpw = 912, vph = 432 }
  local rects = bleedRects(view)
  local b = by(rects)

  ok(b.top, "there is a bar above the battle")
  eq(b.top.y, 0, "starting at the top of the window")
  eq(b.top.h, 134, "as tall as the gap")
  eq(b.top.x, view.ox, "and only as wide as the surface")
  eq(b.top.w, view.vpw, "...which the corners finish off")

  eq(b.bottom.y, view.oy + view.vph, "the bar below starts where it ends")
  eq(b.bottom.h, view.wh - (view.oy + view.vph), "and runs to the window")

  eq(b.left.w, 44, "the side bars are the horizontal remainder")
  eq(b.right.x, view.ox + view.vpw, "the right one starting past the surface")
  eq(b.right.w, view.ww - (view.ox + view.vpw), "and running to the edge")

  ok(b.tl and b.tr and b.bl and b.br, "all four corners are filled")
  eq(b.tl.w, view.ox, "a corner is as wide as the side beside it")
  eq(b.tl.h, view.oy, "and as tall as the bar above it")

  local whole, why = covers(rects, view)
  ok(whole, "and between them they leave no paper: " .. tostring(why))
end

io.write("a surface that fills the window edge to edge\n")
do
  local view = { ww = 912, wh = 432, ox = 0, oy = 0, vpw = 912, vph = 432 }
  local rects = bleedRects(view)
  eq(#rects, 0, "no bars, and none drawn -- not eight empty rectangles")
end

io.write("a surface as wide as the window but not as tall\n")
do
  -- the usual wide case on a 16:9 display
  local view = { ww = 960, wh = 540, ox = 0, oy = 43, vpw = 960, vph = 454 }
  local rects = bleedRects(view)
  local b = by(rects)
  ok(b.top and b.bottom, "a bar above and below")
  ok(not b.left and not b.right, "and none at the sides, because there is no gap")
  ok(not b.tl and not b.tr, "nor corners")
  local whole, why = covers(rects, view)
  ok(whole, "still no paper anywhere: " .. tostring(why))
end

io.write("a view that says nothing useful\n")
do
  eq(bleedRects(nil), nil, "no view at all")
  eq(bleedRects({}), nil, "an empty one")
  eq(bleedRects({ ww = 100, wh = 100, vpw = 0, vph = 0 }), nil,
    "a surface with no size: there is nothing to bleed from")
  eq(bleedRects({ ww = 0, wh = 0, vpw = 10, vph = 10 }), nil,
    "and a window with no size has nowhere to put it")
end

io.write("a surface hanging off the edge of the window\n")
do
  -- The renderer clamps, but the hook is handed numbers rather than promises:
  -- a negative remainder must produce no bar rather than a rectangle drawn
  -- backwards across the screen.
  local view = { ww = 200, wh = 200, ox = -20, oy = -20, vpw = 300, vph = 300 }
  local rects = bleedRects(view)
  for _, r in ipairs(rects) do
    ok(r.w > 0 and r.h > 0, r.slice .. " has a positive size or is not there")
  end
  eq(#rects, 0, "which here means no bars at all")
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
