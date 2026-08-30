-- Headless coverage of the paper an item icon sits on.
--
-- These icons are pictures drawn ON PAPER.  All 106 shipped ones draw their
-- line work in pure black on transparency and carry no white at all -- the
-- page is a POKe BALL's lower half, the white of a TOWN MAP, the gap inside a
-- BICYCLE's frame -- so the paper is part of the picture rather than a
-- background it happens to be sitting on.  So the paper is baked into the art
-- at load, as the icon's own silhouette: grow every opaque pixel by one, flood
-- the outside of the grown shape in from the border, and paint white whatever
-- the flood could not reach.
--
-- Three answers were shipped before this one, and each looks like the obvious
-- one, so all three are recorded here:
--
--   0.6.0 painted the whole cell the colour the page was about to be.  On a
--   dark page that takes the paper away and a POKe BALL comes out a red blob.
--
--   0.9.0 kept the dark cell and drew the line work white instead, on the
--   theory that black on transparency is an OUTLINE and an outline inverts.
--   For a ball it does.  For a BICYCLE it does not -- 69% of that icon's
--   opaque pixels are pure black, because the black IS the bicycle -- and
--   flipping it turns the subject into white scribble.
--
--   0.13.0 gave every icon a white square.  Correct, and a row of white tiles
--   down a dark list.
--
-- The GROW is what makes the flood work at all, and is the part worth
-- guarding: these outlines are not closed -- on white paper they never had to
-- be -- and a bare flood leaks straight out through the gaps.  Over the real
-- POKe BALL a plain fill caught six pixels of 256.
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

-- ------- a stand-in for love's ImageData
--
-- Rows of characters, so the fixtures read as the pictures they are:
--   .  transparent      #  opaque ink      W  opaque white
local function imageData(rows)
  local h, w = #rows, #rows[1]
  local grid = {}
  for y = 1, h do
    grid[y] = {}
    for x = 1, w do
      local ch = rows[y]:sub(x, x)
      if ch == "." then grid[y][x] = { 0, 0, 0, 0 }
      elseif ch == "W" then grid[y][x] = { 1, 1, 1, 1 }
      else grid[y][x] = { 0, 0, 0, 1 } end
    end
  end
  local data = {}
  function data:getDimensions() return w, h end
  function data:getPixel(x, y)
    local p = grid[y + 1][x + 1]
    return p[1], p[2], p[3], p[4]
  end
  function data:setPixel(x, y, r, g, b, a)
    grid[y + 1][x + 1] = { r, g, b, a }
  end
  function data:render()
    local out = {}
    for y = 1, h do
      local line = ""
      for x = 1, w do
        local p = grid[y][x]
        if p[4] == 0 then line = line .. "."
        elseif p[1] == 1 and p[2] == 1 and p[3] == 1 then line = line .. "W"
        else line = line .. "#" end
      end
      out[y] = line
    end
    return out
  end
  return data
end

love = {
  graphics = {
    setColor = function() end,
    rectangle = function() end,
    draw = function() end,
    newImage = function() return { setFilter = function() end } end,
  },
}
package.preload["src.render.PaletteFX"] = function()
  return { markTrueColor = function() end }
end

local mod = {
  path = ".",
  options = { get = function() return nil end },
  log = { warn = function() end, info = function() end },
}
local C = chunkOf("modules/Gen1ModernBag/icons.lua")(mod)
ok(type(C) == "table" and type(C.bakePaper) == "function",
   "the icon kit loads and exposes the bake")

-- ------- the real POKe BALL, traced off the shipped file
--
-- Rows 12 and 13 are the ones that matter: the outline steps from (4,12) to
-- (6,13) with nothing between them.  That gap is why a bare flood leaks, and
-- why the grow has to come first.
local BALL = {
  "................",
  "................",
  "......####......",
  "....########....",
  "...##########...",
  "...##.#######...",
  "..############..",
  "..############..",
  "..############..",
  "..###..#######..",
  "...##..######...",
  "...#.##.....#...",
  "....#......#....",
  "......####......",
  "................",
  "................",
}

io.write("the ball gets its lower half back\n")
do
  local data = imageData(BALL)
  eq(C.bakePaper(data), true, "the bake reports that it painted something")
  local out = data:render()
  -- the open area inside the ball's lower outline is paper now
  eq(out[12], "..W#W##WWWWW#W..",
    "the row a bare flood leaked through is paper between its strokes now")
  eq(out[13], "..WW#WWWWWW#WW..", "and so is the one under it")
  -- and the sticker edge: one row of white above the topmost ink
  eq(out[2], ".....WWWWWW.....",
    "the shape grows by one, which is the sticker edge and is also what "
    .. "closes the outline")
  eq(out[1], "................",
    "two rows out is still the page, so the icon keeps a shape of its own")
end

io.write("and the ink is never touched\n")
do
  local data = imageData({
    "....",
    ".##.",
    ".##.",
    "....",
  })
  C.bakePaper(data)
  local out = data:render()
  eq(out[2], "W##W", "the grow reaches the edge of this little cell")
  eq(out[3], "W##W", "...on both rows, and the ink in the middle is still ink")
  -- the ink itself is still ink
  local r, g, b, a = data:getPixel(1, 1)
  eq(a, 1, "the opaque pixel is still opaque")
  eq(r + g + b, 0, "and still black -- the bake only ever fills transparency")
end

io.write("a shape with nothing enclosed is only given its edge\n")
do
  -- A single dot: the grow gives it a ring, and there is no interior to fill
  -- beyond that.  What matters is that the flood still reaches the corners,
  -- so the cell does not become a square.
  local data = imageData({
    ".....",
    ".....",
    "..#..",
    ".....",
    ".....",
  })
  C.bakePaper(data)
  local out = data:render()
  eq(out[1], ".....", "the top row is still the page")
  eq(out[2], ".WWW.", "the ring around the dot is paper")
  eq(out[3], ".W#W.", "with the dot itself in the middle of it")
  eq(out[5], ".....", "and the bottom row is still the page")
end

io.write(("\nitem icons: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
