-- Headless coverage of what an item icon does on dark paper.
--
-- The bug this is for: every one of the 106 shipped icons draws its line work
-- in PURE BLACK on transparency, and carries no white at all.  The art was
-- made to sit on the white page -- the page IS a POKe BALL's lower half, and
-- the black outline around it is what makes the shape.  0.6.0 painted the
-- cell the colour the page was about to be, so on a dark page the ball lost
-- its paper and kept an outline nobody could see against black.  It came out
-- a red blob.
--
-- The first attempt was a flood fill: find the transparent pixels the outline
-- encloses, make them white.  It does not work, and this is where that is
-- recorded so nobody tries it again -- the outlines are NOT CLOSED.  They
-- never had to be, because inside and outside were the same white page.  A
-- fill leaks straight through the gaps, which is why the shape below is the
-- real POKe BALL's lower edge rather than a tidy invented one.
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
-- Rows of characters, so the fixture below reads as the picture it is:
--   .  transparent      #  pure black (the line work)      r  a colour
local function imageData(rows)
  local h = #rows
  local w = #rows[1]
  local grid = {}
  for y = 1, h do
    grid[y] = {}
    for x = 1, w do
      local ch = rows[y]:sub(x, x)
      if ch == "." then grid[y][x] = { 0, 0, 0, 0 }
      elseif ch == "#" then grid[y][x] = { 0, 0, 0, 1 }
      else grid[y][x] = { 0.97, 0.32, 0.19, 1 } end
    end
  end
  local data = { grid = grid }
  function data:getDimensions() return w, h end
  function data:getPixel(x, y)
    local p = self.grid[y + 1][x + 1]
    return p[1], p[2], p[3], p[4]
  end
  function data:setPixel(x, y, r, g, b, a)
    self.grid[y + 1][x + 1] = { r, g, b, a }
  end
  function data:render()
    local out = {}
    for y = 1, h do
      local line = ""
      for x = 1, w do
        local p = self.grid[y][x]
        if p[4] == 0 then line = line .. "."
        elseif p[1] == 0 and p[2] == 0 and p[3] == 0 then line = line .. "#"
        elseif p[1] == 1 and p[2] == 1 and p[3] == 1 then line = line .. "W"
        else line = line .. "r" end
      end
      out[y] = line
    end
    return out
  end
  return data
end

-- ------- the kit
--
-- Only `inkSwapped` is under test, so the module is stood up with the
-- smallest `mod` and `love` it will load against.
love = { graphics = { newImage = function() return nil end,
                      setColor = function() end,
                      rectangle = function() end,
                      draw = function() end } }
package.preload["src.render.PaletteFX"] = function()
  return { markTrueColor = function() end }
end
package.preload["src.render.Assets"] = function() return {} end

local mod = {
  path = ".",
  options = { get = function() return nil end },
  log = { warn = function() end, info = function() end },
  theme = function() return nil end,
}
local C = chunkOf("modules/Gen1ModernBag/icons.lua")(mod)
ok(type(C) == "table" and type(C.inkSwapped) == "function",
   "the icon kit loads and exposes the swap")

-- ------- the real POKe BALL's lower half, traced off the shipped file
--
-- Note rows 12 and 13: the outline steps from (4,12) to (6,13) with nothing
-- between them.  That gap is why a flood fill leaks, and it is the reason
-- this test exists as a picture rather than as a number.
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

io.write("black line work is drawn white on dark paper\n")
do
  local data = imageData(BALL)
  eq(C.inkSwapped(data), true, "the swap reports that it changed something")
  local out = data:render()
  eq(out[3], "......WWWW......", "the top of the ball is white line work now")
  eq(out[13], "....W......W....", "and so is the bottom")
  eq(out[1], "................",
     "the margin around the item is untouched, so the icon still sits on "
     .. "whatever the screen puts behind it")
  eq(out[12], "...W.WW.....W...",
     "including the gaps a flood fill would have leaked through -- they are "
     .. "the page, and the page is the screen's business")
end

io.write("and every other pixel is left exactly as it was\n")
do
  local coloured = {
    "....",
    ".rr.",
    ".r#.",
    "....",
  }
  local data = imageData(coloured)
  C.inkSwapped(data)
  local out = data:render()
  eq(out[2], ".rr.", "a colour is a colour")
  eq(out[3], ".rW.", "and only the black becomes white")
end

io.write("art with no black in it is left alone entirely\n")
do
  local data = imageData({ "..", ".r" })
  eq(C.inkSwapped(data), false,
     "nothing swapped means no twin is built and the plain image is drawn")
  eq(data:render()[2], ".r", "...and the pixels are untouched")
end

io.write(("\nitem icons: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
