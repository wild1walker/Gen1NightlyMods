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
   "so the cached path answers what the REPLAYED call answered, not a count")
ok(src:find("first + 4 + 9", 1, true) == nil, "and derives nothing itself")

-- A face is an L, not a rectangle: row 0 is four columns wide, rows 1 and 2
-- are three.  The column the engine never draws comes back transparent in the
-- replay, and refusing on alpha meant all eight leaders were refused and the
-- badges page was untouched.
ok(face and face:find("for col = 0, 3 do", 1, true) ~= nil,
   "a leader's top row is four tiles")
ok(face and face:find("for col = 1, 3 do", 1, true) ~= nil,
   "and its lower rows are three -- so the block has a hole in its corner")
ok(src:find("Cutout2.cut(canvas:newImageData(), w, h, true)", 1, true) ~= nil,
   "so a replayed block is cut with gaps allowed")

-- And the replay is the ENGINE's own draw, not a recording of its blits.
-- `TileSheet:draw` lays its tiles inside GbcPalette.with when the sheet has a
-- palette, so the source pixels are 2bpp shades and the COLOUR is the shader:
-- replaying the blits raw came out greyscale.
ok(sheetSrc:find("GbcPalette.with(colors, body)", 1, true) ~= nil,
   "a sheet with a palette draws through a shader, so its file is greyscale")
ok(src:find("pcall(job.base, job.screen, unpack(job.args))", 1, true) ~= nil,
   "so the block is replayed by calling the engine's own draw")
ok(src:find("love.graphics.draw = function(image", 1, true) == nil,
   "and nothing records blits behind its back")

-- The dex's other shape: one image, with a plate filled behind it.
local dexSrc = assert(slurp(ENGINE .. "/src/ui/gen2/PokedexMenu.lua"))
ok(dexSrc:find('G.rectangle("fill", tx * 8, ty * 8, 7 * 8, 7 * 8)', 1, true) ~= nil,
   "the #DEX fills a plate behind its pic")
ok(dexSrc:find("local blank = colors and GbcPalette.color(colors, 1)", 1, true) ~= nil,
   "in the palette's colour 0 -- so the plate is half the square")
ok(src:find("dropped = true", 1, true) ~= nil, "which the arm drops")

-- THE LISTING IS NOT THE ENTRY.  `ownColors` is the cart's own name for it:
-- the listing draws every row through the question-mark palette and the cart
-- genuinely shows a green mon on green there, while the entry gets the mon's
-- own colours whose colour 0 is the white slab.  Cutting both took the green
-- OFF the listing and left the entry's square in place -- backwards.
local drawPicSrc = dexSrc:match("function PokedexMenu:drawPic.-\nend\n")
ok(drawPicSrc and drawPicSrc:find("colors = self.gfx and self.gfx.questionMarkPalette",
                                  1, true) ~= nil,
   "without ownColors the cart uses the question-mark palette -- the green")
ok(dexSrc:find("self:drawPic(self:current(), 1, 1)\n", 1, true) ~= nil,
   "and the LISTING calls drawPic without it")
ok(dexSrc:find("self:drawPic(row, 1, 1, true)", 1, true) ~= nil,
   "while the ENTRY passes it")
ok(src:find("if not on() or not ownColors then", 1, true) ~= nil,
   "so the arm leaves the listing entirely alone")

-- And on the entry the plate goes even when there is no picture to look up.
-- That gate is why the question mark kept its green box: the one case with
-- nothing to find was the one case that returned early.
ok(src:find("local cut = image and self.imageFor(image) or nil", 1, true) ~= nil,
   "a missing picture is optional, not a reason to keep the plate")
ok(src:find("if not image then return basePic", 1, true) == nil,
   "and there is no early return left that would keep it")
-- The plate and the picture's own field are two independent halves, and
-- treating them as one is what left the #DEX looking untouched: the arm bailed
-- unless a cut was ready, so a cut that was refused, slow, or simply on its
-- first frame left the 56x56 plate standing.
ok(src:find("if not cut then\n        return basePic", 1, true) == nil,
   "and drops it whether or not a cut picture is ready")
ok(src:find("if cut and what == image then", 1, true) ~= nil,
   "substituting the cut picture only when there IS one")
ok(src:find("local function refused(", 1, true) ~= nil,
   "and a refused cut says so once, rather than looking like nothing ran")

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
                        "function self.want" }) do
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

do
  -- The same figure with a GAP in the corner, which is what a replayed L
  -- looks like: the gap is where the engine drew nothing, so it seeds the
  -- fill rather than stopping it.
  local function plot(x, y)
    return (x >= 2 and x <= 5 and y >= 2 and y <= 5) and 0 or 1
  end
  local data = { getDimensions = function() return 8, 8 end,
                 getPixel = function(_, x, y)
                   if x == 0 and y >= 4 then return 0, 0, 0, 0 end
                   local v = plot(x, y)
                   return v, v, v, 1
                 end }
  eq(Cutout2.cut(data, 8, 8), nil,
     "a gap refuses a SOURCE image -- that alpha is somebody else's cut")
  local out = Cutout2.cut(data, 8, 8, true)
  ok(out ~= nil, "but a replayed BLOCK is cut through it")
  if out then
    eq(out:alphaAt(0, 5), 0, "the gap itself stays clear")
    eq(out:alphaAt(0, 0), 0, "the square goes")
    eq(out:alphaAt(3, 3), 1, "and the figure stays")
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
