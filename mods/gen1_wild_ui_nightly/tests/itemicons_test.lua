-- Headless coverage of what an item icon sits on.
--
-- These icons are pictures drawn ON PAPER.  All 106 shipped ones draw their
-- line work in pure black on transparency and carry no white at all -- the
-- page is a POKe BALL's lower half, the white of a TOWN MAP, the gap inside a
-- BICYCLE's frame -- so the paper is part of the picture rather than a
-- background it happens to be sitting on.  An icon therefore keeps its paper
-- whatever the page does: a white cell behind it, always.
--
-- Two other answers were shipped first, and both are recorded here because
-- each looks like the obvious one:
--
--   0.6.0 painted the cell the colour the page was about to be.  On a dark
--   page that takes the paper away and a POKe BALL comes out a red blob.
--
--   0.9.0 kept the dark cell and drew the line work white instead, on the
--   theory that black on transparency is an OUTLINE and an outline inverts.
--   For a ball it does.  For a BICYCLE it does not -- 69% of that icon's
--   opaque pixels are pure black, because the black IS the bicycle -- and
--   flipping it turns the subject into white scribble.
--
-- Run:  luajit tests/itemicons_test.lua

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

local function chunkOf(path)
  local handle = assert(io.open(path, "r"), path .. " is missing")
  local source = handle:read("*a")
  handle:close()
  return assert(load(source, "@" .. path))()
end

-- ------- the engine, as much of it as this touches

local calls = {}
love = {
  graphics = {
    setColor = function(r, g, b, a)
      calls[#calls + 1] = { what = "colour", r = r, g = g, b = b, a = a }
    end,
    rectangle = function(_, x, y, w, h)
      calls[#calls + 1] = { what = "rect", x = x, y = y, w = w, h = h }
    end,
    draw = function() calls[#calls + 1] = { what = "image" } end,
    newImage = function() return { setFilter = function() end } end,
  },
}
local marks = {}
package.preload["src.render.PaletteFX"] = function()
  return {
    markTrueColor = function(x, y, w, h)
      marks[#marks + 1] = { x = x, y = y, w = w, h = h }
    end,
  }
end

-- The theme is present and set to DARK, which is the case that used to change
-- what an icon sat on.  It must not any more.
local mod = {
  path = ".",
  options = { get = function() return nil end },
  log = { warn = function() end, info = function() end },
  theme = function()
    return { read = function() return "dark" end,
             matte = function() return { 0, 0, 0 } end }
  end,
}
local C = chunkOf("modules/Gen1ModernBag/icons.lua")(mod)
ok(type(C) == "table" and type(C.matte) == "function",
   "the icon kit loads and exposes the cell it paints")

io.write("an icon sits on white paper, whatever the page is\n")
do
  calls = {}
  C.matte(24, 40, 16, 16)
  local colour, rect
  for _, c in ipairs(calls) do
    if c.what == "colour" then colour = c end
    if c.what == "rect" then rect = c end
  end
  ok(colour ~= nil and rect ~= nil, "it sets a colour and fills a rectangle")
  eq(colour and colour.r, 1, "white")
  eq(colour and colour.g, 1, "...on every channel")
  eq(colour and colour.b, 1, "...including blue")
  eq(rect and rect.x, 24, "over the cell it was given")
  eq(rect and rect.w, 16, "...at the cell's size")

  -- The theme above says DARK.  0.6.0 would have painted black here, which is
  -- the bug this file exists for.
  ok(not (colour and colour.r == 0),
    "and DARK does not change it, because the paper is part of the picture")
end

io.write("the paper goes down before the art, inside the marked rectangle\n")
do
  calls, marks = {}, {}
  C.draw({}, 8, 16)
  local order = {}
  for _, c in ipairs(calls) do
    if c.what == "rect" then order[#order + 1] = "paper" end
    if c.what == "image" then order[#order + 1] = "art" end
  end
  eq(order[1], "paper", "the cell is filled first")
  eq(order[2], "art", "and the icon drawn onto it")
  eq(#marks, 1, "the rectangle is marked true-colour exactly once")
  eq(marks[1] and marks[1].x, 8, "at the icon's own position")
  eq(marks[1] and marks[1].w, 16, "and the icon's own size, which the "
    .. "paper shares -- one rectangle, not two")
end

io.write(("\nitem icons: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
