-- The white squares around Gold's pictures: the trainer card's portrait, the
-- eight gym leaders on its BADGES page, and the #DEX's pic.
--
-- runtime/matte.lua says Gold needs no counterpart -- "its art is drawn in the
-- picture like everything else, so there is no white box to repair".  Three
-- screenshots say otherwise, and the note was right about the mechanism and
-- wrong about the conclusion: Red re-blits a true-colour rectangle past the
-- shade pass, Gold instead ships full-colour art with the white field BAKED
-- INTO THE PIXELS and draws it raw, because there is no palette to remap it
-- through.  A shade substitution has nothing to substitute.
--
-- Two shapes, and both are read off the engine below rather than restated:
-- `TileSheet:draw` takes the un-remapped `body()` whenever `colors` is nil,
-- and the trainer card blits its pictures TILE BY TILE out of a sheet -- so a
-- block is cut by recording the engine's own blits and replaying them, and
-- never by re-deriving where they went.
--
-- Run:  luajit tests/cutout2_test.lua
--       (needs an engine tree; SKIPs without one)

package.path = "./?.lua;" .. package.path

local passed, failed = 0, 0
local function ok(condition, description)
  if condition then passed = passed + 1
  else failed = failed + 1; io.write("  FAIL  ", description, "\n") end
end
local function eq(actual, expected, description)
  if actual ~= expected then
    description = ("%s (got %s, wanted %s)")
      :format(description, tostring(actual), tostring(expected))
  end
  ok(actual == expected, description)
end

local ENGINE do
  local candidates = { os.getenv("GEN1RECOMP") }
  for _, prefix in ipairs({ "../../..", "../../../..", "../..", "../../../../.." }) do
    for _, name in ipairs({ "gen1recompog", "gen1recomp", "bryanthaboi/gen1recomp" }) do
      candidates[#candidates + 1] = prefix .. "/" .. name
    end
  end
  for _, dir in ipairs(candidates) do
    if dir then
      local probe = io.open(dir .. "/src/ui/gen2/TrainerCard.lua")
      if probe then probe:close(); ENGINE = dir; break end
    end
  end
end
if not ENGINE then
  io.write("cutout2: SKIPPED -- no engine tree found "
    .. "(set GEN1RECOMP to a gen1recomp checkout)\n")
  os.exit(0)
end

local function slurp(path)
  local handle = io.open(path)
  if not handle then return nil end
  local t = handle:read("*a") handle:close() return t
end

local src = assert(slurp("runtime/cutout2.lua"))

-- ---- why a shade substitution cannot reach this, read off the cart

local sheetSrc = assert(slurp(ENGINE .. "/src/ui/gen2/TileSheet.lua"))
ok(sheetSrc:find("if colors and GbcPalette.available() then", 1, true) ~= nil,
   "a tile sheet only goes through the palette when it HAS one")
ok(sheetSrc:find("else\n    body()\n  end", 1, true) ~= nil,
   "and is drawn raw otherwise -- baked pixels, nothing to substitute")

local cardSrc = assert(slurp(ENGINE .. "/src/ui/gen2/TrainerCard.lua"))
ok(cardSrc:find("function TrainerCard:drawPortrait()", 1, true) ~= nil,
   "the card draws a portrait")
ok(cardSrc:find("function TrainerCard:drawLeaderFace(first, tx, ty)", 1, true) ~= nil,
   "and a leader's face, taking the first tile id and a position")
-- Both go through `self:tile`, i.e. a sheet blit per tile -- which is why the
-- cut has to be of the assembled block and not of the sheet.
local portrait = cardSrc:match("function TrainerCard:drawPortrait.-\nend\n")
ok(portrait and portrait:find("self:tile(self.card", 1, true) ~= nil,
   "the portrait is a block of TILE blits, not one image")
local face = cardSrc:match("function TrainerCard:drawLeaderFace.-\nend\n")
ok(face and face:find("self:tile(self.leaders", 1, true) ~= nil,
   "and so is a leader's face")

-- The next-tile-id it returns is what the page walks its eight faces with, so
-- a cached draw has to answer the same number.  Counted here only to show the
-- arm must NOT count it: 4 tiles then 2x3 is ten, and the first attempt at
-- deriving it said thirteen.
ok(face and face:find("return id", 1, true) ~= nil,
   "drawLeaderFace returns the next tile id, which the page depends on")
ok(src:find("return blockReturn[key]", 1, true) ~= nil,
   "so the cached path answers what the RECORDED call answered, not a count")
ok(src:find("first + 4 + 9", 1, true) == nil, "and derives nothing itself")

-- The dex's other shape: one image, with a plate filled behind it.
local dexSrc = assert(slurp(ENGINE .. "/src/ui/gen2/PokedexMenu.lua"))
ok(dexSrc:find('G.rectangle("fill", tx * 8, ty * 8, 7 * 8, 7 * 8)', 1, true) ~= nil,
   "the #DEX fills a plate behind its pic")
ok(dexSrc:find("local blank = colors and GbcPalette.color(colors, 1)", 1, true) ~= nil,
   "in the palette's colour 0 -- so the plate is half the square")
ok(src:find("dropped = true", 1, true) ~= nil,
   "which the arm drops, but only when a cut picture is going in its place")

-- ---- nothing is built inside a draw
--
-- The rule the arena learned the hard way in 0.32.62: a readback binds a
-- canvas and the result is a texture, and doing either with the frame's canvas
-- bound is a flipped sprite on iOS and a crash on Android.
ok(src:find("mod.hooks:wrap(\"core.update\"", 1, true) ~= nil,
   "the build hangs off core.update, where nothing is bound")
for _, call in ipairs({ "newCanvas", "newImageData", "newImage" }) do
  local inDraw = false
  for _, fn in ipairs({ "function self.imageFor", "function self.blockFor",
                        "function self.record" }) do
    local body = src:match(fn:gsub("%.", "%%.") .. ".-\n  end\n")
    if body and body:find(call, 1, true) then inDraw = true end
  end
  ok(not inDraw, "the draw side never calls " .. call)
end

-- ---- the cut itself
--
-- The whole of the risk: getting it wrong cuts a hole in a picture.

local Cutout2 = assert(loadfile("runtime/cutout2.lua"))()
ok(type(Cutout2.new) == "function", "the runtime is built like the matte is")
ok(type(Cutout2.cut) == "function", "and its cut is a pure function")

local function dataOf(w, h, plot)
  return { getDimensions = function() return w, h end,
           getPixel = function(_, x, y)
             local v = plot(x, y)
             return v, v, v, 1
           end }
end

love = love or {}
love.image = { newImageData = function(w, h)
  local px = {}
  return { w = w, h = h, px = px,
           setPixel = function(_, x, y, r, g, b, a) px[y * w + x] = a end,
           alphaAt = function(_, x, y) return px[y * w + x] end }
end }

do
  -- An 8x8 figure: a 4x4 body of ink at (2,2)-(5,5) with a 2x2 WHITE SHIRT
  -- enclosed inside it, standing in a white field.  The shirt is the whole
  -- point: keying white out everywhere would punch a hole through it.
  local function plot(x, y)
    local inBody = x >= 2 and x <= 5 and y >= 2 and y <= 5
    local inShirt = x >= 3 and x <= 4 and y >= 3 and y <= 4
    if inBody and not inShirt then return 0 end
    return 1
  end
  local out = Cutout2.cut(dataOf(8, 8, plot), 8, 8)
  ok(out ~= nil, "a figure in a white field is cut")
  if out then
    eq(out:alphaAt(0, 0), 0, "the corner of the square is gone")
    eq(out:alphaAt(1, 4), 0, "and the field beside the figure")
    eq(out:alphaAt(2, 2), 1, "the body stays")
    eq(out:alphaAt(3, 3), 1, "and so does the WHITE SHIRT inside it")
    eq(out:alphaAt(4, 4), 1, "all of it")
  end
end

do -- art that already carries alpha is somebody else's, and is left alone
  local data = { getDimensions = function() return 8, 8 end,
                 getPixel = function(_, x) return 1, 1, 1, x == 0 and 0 or 1 end }
  eq(Cutout2.cut(data, 8, 8), nil, "a picture with its own alpha is left alone")
end

do -- one flat colour is not a picture in a square
  eq(Cutout2.cut(dataOf(8, 8, function() return 1 end), 8, 8), nil,
     "a single-colour square is not a figure in a field")
end

do -- a figure the border cannot see around is not in a square
  eq(Cutout2.cut(dataOf(8, 8, function() return 0 end), 8, 8), nil,
     "and neither is a picture with no field at all")
end

do -- a photograph is refused rather than read
  local out = Cutout2.cut(dataOf(16, 16, function(x, y)
    return (x * 16 + y) / 256
  end), 16, 16)
  eq(out, nil, "art with too many colours to be a cart pic is refused")
end

do -- the DPI trap: a canvas that came back bigger is measured off what came
   -- back, not off what was asked for
  local big = dataOf(8, 8, function() return 1 end)
  big.getDimensions = function() return 12, 12 end
  eq(Cutout2.cut(big, 8, 8), nil,
     "a readback whose size is not a whole multiple is refused rather than "
     .. "read as a magnified corner")
end

io.write(("cutout2: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
