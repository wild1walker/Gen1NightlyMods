-- Headless coverage of the pad baked into the title screen's art.
--
-- The bug this is here for: on a black ground the theme pinned colour 0 to
-- black, which took the paper out of the logo AND the white out of its
-- letters, because a palette cannot tell a field from a highlight.  0.31.2
-- keyed the paper that was connected to the border and kept the rest -- and
-- for this logo that keeps nothing, because POKeMON is grey letter faces
-- inside a black outline on white and every one of its 4381 near-white
-- pixels is border-connected.  The player kept saying the logo had no white
-- in it; it had none to keep.
--
-- What the player asked for by name is the item icons' treatment: grow the
-- line work by a pixel, flood the outside of the grown shape, and paint
-- everything the flood could not reach opaque white.  The art keeps paper of
-- its own SHAPE -- a sticker rather than a box.
--
-- Run:  luajit tests/titleart_test.lua

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

-- ------- the engine's image side, as much of it as the bake touches

local ImageData = {}
ImageData.__index = ImageData

local function newData(w, h)
  local px = {}
  for i = 0, w * h - 1 do px[i] = { 0, 0, 0, 0 } end
  return setmetatable({ w = w, h = h, px = px }, ImageData)
end

function ImageData:getDimensions() return self.w, self.h end

function ImageData:getPixel(x, y)
  local p = self.px[y * self.w + x]
  return p[1], p[2], p[3], p[4]
end

function ImageData:setPixel(x, y, r, g, b, a)
  self.px[y * self.w + x] = { r, g, b, a }
end

function ImageData:paste(src, dx, dy, sx, sy, sw, sh)
  for y = 0, sh - 1 do
    for x = 0, sw - 1 do
      local r, g, b, a = src:getPixel(sx + x, sy + y)
      self:setPixel(dx + x, dy + y, r, g, b, a)
    end
  end
end

-- what the bake wrote, readable straight off the image the swap installed
local function shade(image, x, y)
  local r, _, _, a = image.data:getPixel(x, y)
  if a == 0 then return "." end                 -- keyed out to the page
  if r > 0.83 then return "W" end               -- paper
  return "#"                                    -- line work
end

local function picture(image, rect)
  local out = {}
  for y = rect.y, rect.y + rect.h - 1 do
    local row = {}
    for x = rect.x, rect.x + rect.w - 1 do row[#row + 1] = shade(image, x, y) end
    out[#out + 1] = table.concat(row)
  end
  return table.concat(out, "\n")
end

-- An Image is opaque on LOVE 11 -- it does not keep its ImageData -- so the
-- bake reads it back off the GPU through a canvas.  Here the canvas records
-- what was drawn into it and hands back that image's data, which is the same
-- contract with none of the driver.
local function newImage(data)
  local image = {}
  function image:getDimensions() return data:getDimensions() end
  function image:setFilter() end
  image.data = data
  return image
end

local canvasState = {}

love = {
  graphics = {
    setColor = function() end,
    rectangle = function() end,
    newImage = newImage,
    newCanvas = function(w, h)
      local canvas = { w = w, h = h }
      function canvas:newImageData()
        local id = newData(self.w, self.h)
        if self.painted then
          id:paste(self.painted, 0, 0, 0, 0, self.w, self.h)
        end
        return id
      end
      return canvas
    end,
    getCanvas = function() return canvasState.bound end,
    setCanvas = function(canvas) canvasState.bound = canvas end,
    setBlendMode = function() end,
    clear = function() end,
    draw = function(image)
      if canvasState.bound and image and image.data then
        canvasState.bound.painted = image.data
      end
    end,
  },
  image = { newImageData = newData },
}

local PaletteFX
PaletteFX = {
  mode = "redpp",
  marks = {},
  honorsTrueColor = function() return true end,
  usesSpriteObp = function() return PaletteFX.obp end,
  markTrueColor = function() end,
}
package.preload["src.render.PaletteFX"] = function() return PaletteFX end

-- The art the title loads, drawn here as strings so the bake can be read as
-- a picture rather than as a pixel count.
--   "#" line work, "w" the paper it is printed on, "." transparent
local function art_from(rows)
  local h, w = #rows, #rows[1]
  local id = newData(w, h)
  for y = 1, h do
    for x = 1, w do
      local c = rows[y]:sub(x, x)
      if c == "#" then id:setPixel(x - 1, y - 1, 0, 0, 0, 1)
      elseif c == "g" then id:setPixel(x - 1, y - 1, 0, 0.6, 0.2, 1)
      elseif c == "w" then id:setPixel(x - 1, y - 1, 1, 1, 1, 1)
      else id:setPixel(x - 1, y - 1, 0, 0, 0, 0) end
    end
  end
  return newImage(id)
end

local Matte = chunkOf("runtime/matte.lua")

local themeValue = "dark"
local theme = {
  read = function() return themeValue end,
  matte = function() return { 0, 0, 0 } end,
  clipArt = function() end,
}
local context = {
  theme = theme,
  mod = { log = { warn = function() end } },
}

-- The title, reduced to the fields the bake reads and a draw that hands back
-- what it was given to draw with.
local seen
local function titleDraw(state)
  love.graphics.rectangle("fill", 0, 0, 160, 144)
  seen = { logo = state.logo, version = state.version, player = state.player,
           copyImg = state.copyImg, gfInc = state.gfInc,
           mon = state.currentSprite and state:currentSprite() or nil }
end

local function run(state)
  seen = nil
  PaletteFX.obp = false
  Matte.new(context).wrapTitle(titleDraw)(state)
  return seen
end

-- ------------------------------------------------------- the logo's white

io.write("the logo keeps paper of its own shape, and loses the rest\n")
do
  -- A letter: black outline, white face inside it, white field all round.
  -- Every one of those white pixels is reachable from the border once the
  -- outline is walked round, which is why keying border-connected paper took
  -- the face with the field.
  local logo = art_from {
    "wwwwwwww",
    "ww####ww",
    "ww#ww#ww",
    "ww#ww#ww",
    "ww####ww",
    "wwwwwwww",
  }
  local out = run { logo = logo }
  ok(out.logo ~= logo, "the state draws with the baked copy")

  eq(picture(out.logo, { x = 0, y = 0, w = 8, h = 6 }), table.concat({
    ".WWWWWW.",
    ".W####W.",
    ".W#WW#W.",
    ".W#WW#W.",
    ".W####W.",
    ".WWWWWW.",
  }, "\n"), "the face keeps its white, the field goes, and a pixel of paper "
    .. "is left round the outline as the pad")
end

io.write("and a build that cannot read the art keeps the flat logo\n")
do
  -- The theme asks whether the bake TOOK (`__gen1WildKeyedArt`) rather than
  -- assuming it, because with the paper still on the art colour 0 has to stay
  -- pinned or the field comes back as a white box.
  local image = love.image
  love.image = nil
  local state = { logo = logo }
  run(state)
  love.image = image
  ok(state.__gen1WildKeyedArt == nil,
    "no flag, so the theme keeps colour 0 pinned to black")
end

-- --------------------------------------------- one sheet, several pictures

io.write("the ribbon loses its paper outright, pad and all\n")
do
  -- Not stickered, and the difference is spacing.  The logo is one connected
  -- mass, so a pixel of pad round it is an outline.  The ribbon is eight
  -- pixels of letters with a pixel between them: pad every letter and the
  -- pads meet, and what comes out is a white plate with words on it -- which
  -- is the "white box behind wild green version" this work started from.
  --
  -- And ALL of its paper, counters included: keying only what the border
  -- could reach left the white shut inside an `e` or an `o` behind as a
  -- scatter of specks through the words.
  local ribbon = art_from {
    "wwwwwwww",
    "ww####ww",
    "ww#ww#ww",
    "ww####ww",
  }
  local out = run { version = ribbon }
  eq(picture(out.version, { x = 0, y = 0, w = 8, h = 4 }), table.concat({
    "........",
    "..####..",
    "..#..#..",
    "..####..",
  }, "\n"), "the words keep their line work and nothing else keeps white")
end

-- ---------------------------------------------------- the figure's outline

io.write("the figure gets a one-pixel outline, per quad\n")
do
  -- Sprites on transparency, so the line work is every opaque pixel and the
  -- pad is an outline.  The POKe BALL is tucked into the gap at (0,16) and
  -- the trainer's slices are full width, so the bake runs once per quad or
  -- the ball wears a pixel of the trainer's edge.
  local figure = art_from {
    "........",
    "...##...",
    "...##...",
    "........",
  }
  local quad = function(x, y, w, h)
    return { getViewport = function() return x, y, w, h end }
  end
  local out = run {
    player = figure,
    playerQuads = { { quad(0, 0, 8, 4), 0, 0 } },
  }
  eq(picture(out.player, { x = 0, y = 0, w = 8, h = 4 }), table.concat({
    "..WWWW..",
    "..W##W..",
    "..W##W..",
    "..WWWW..",
  }, "\n"), "white all the way round the trainer and nowhere else")
end

io.write("and OG RED keeps the figure it always had\n")
do
  -- That mode rebuilds the image from `playerPath` through the OBP tables on
  -- every frame and never looks at `state.player`, so swapping it would cost
  -- a bake a frame and change nothing on screen.
  local figure = art_from { "..##..", "..##.." }
  seen = nil
  PaletteFX.obp = true
  Matte.new(context).wrapTitle(titleDraw)({ player = figure })
  eq(seen.player, figure, "the figure is left exactly as the state had it")
end

-- ------------------------------------------------------------- the mon

io.write("the mon is stickered through the call that hands it over\n")
do
  -- It is the one piece of title art with no field to swap: cached per
  -- species inside the state and reached only through `currentSprite`.
  local monArt = art_from { "....", ".##.", ".##.", "...." }
  local logo = art_from { "w#w" }

  local base = function() return monArt, true end
  local state = { logo = logo }
  local wrapped = Matte.new(context)
  -- installTitle is what wraps it on a real build; here the wrapper is
  -- applied to the same function by hand so the state can be a plain table
  local TitleState = { draw = titleDraw, currentSprite = base }
  package.preload["src.ui.TitleState"] = function() return TitleState end
  wrapped.installTitle()
  state.currentSprite = TitleState.currentSprite
  local out = run(state)
  ok(out.mon ~= nil, "a mon comes back")
  eq(picture(out.mon, { x = 0, y = 0, w = 4, h = 4 }), table.concat({
    "WWWW",
    "W##W",
    "W##W",
    "WWWW",
  }, "\n"), "outlined the same way the figure is")
end

io.write("and only while this screen is the dark one\n")
do
  local plain = art_from { "##" }
  local TitleState = { draw = titleDraw,
                       currentSprite = function() return plain, true end }
  package.preload["src.ui.TitleState"] = function() return TitleState end
  Matte.new(context).installTitle()
  eq(TitleState.currentSprite({}), plain,
    "a state with no dark ground gets its own sprite back untouched")
end

-- ------------------------------------------- whose picture gets the pad

io.write("the pad is baked from the picture, not from a path\n")
do
  -- The figure on this cart is not the importer's: Wild Green swaps
  -- `state.player` for its green derived copy, and it does it from a wrapper
  -- OUTSIDE this one, so by the time the bake looks the green art is what the
  -- state is holding.  0.31.8 baked `state.playerPath` instead and installed
  -- the red figure over the green one, which is what a player saw.
  local green = art_from {
    "......",
    "..gg..",
    "..gg..",
    "......",
  }
  local out = run { player = green,
                    playerQuads = { { (function()
                      return { getViewport = function() return 0, 0, 6, 4 end }
                    end)(), 0, 0 } } }
  ok(out.player ~= green, "the picture the state was holding is what was baked")
  local r, g, b = out.player.data:getPixel(2, 1)
  eq(g, 0.6, "and its colour came through the bake untouched")
  ok(r == 0 and b == 0.2, "...on every channel")
  eq(shade(out.player, 1, 1), "W", "with the pad round it")
end

-- ------------------------------------------------------ the POKe BALL

io.write("the ball is cut out so its pad has somewhere to go\n")
do
  -- Its eight-by-eight cell is boxed in by the trainer's own slices, so a pad
  -- baked in place has nowhere to grow and the ball came out with nothing
  -- round it.  It is copied into an image a pixel larger on every side and
  -- substituted for that one draw, one pixel up and left.
  local sheet = art_from {
    "..##....",
    "..##....",
    "........",
  }
  local ballQuad = { getViewport = function() return 2, 0, 2, 2 end }
  local drawnAt
  local function ballDraw(state)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
    local real = love.graphics.draw
    love.graphics.draw(state.player, state.ballQuad, 82, 40)
    love.graphics.draw = real
  end
  local painted = {}
  local realDraw = love.graphics.draw
  love.graphics.draw = function(image, a, b, c, ...)
    if canvasState.bound then return realDraw(image, a, b, c, ...) end
    painted[#painted + 1] = { image = image, a = a, b = b, c = c }
  end
  local state = { player = sheet, ballQuad = ballQuad,
                  playerQuads = { { ballQuad, 0, 0 } } }
  Matte.new(context).wrapTitle(ballDraw)(state)
  love.graphics.draw = realDraw

  ok(state.__gen1WildBall ~= nil, "a padded ball is cut from the sheet")
  local bw, bh = state.__gen1WildBall:getDimensions()
  eq(bw, 4, "two pixels wider than the cell it came from")
  eq(bh, 4, "...and two taller")
  eq(picture(state.__gen1WildBall, { x = 0, y = 0, w = 4, h = 4 }),
     table.concat({ "WWWW", "W##W", "W##W", "WWWW" }, "\n"),
     "white all the way round it, which the sheet had no room for")

  eq(#painted, 1, "the ball is drawn once")
  eq(painted[1].image, state.__gen1WildBall, "and it is the padded copy")
  eq(painted[1].a, 81, "a pixel left of where the bare ball would have gone")
  eq(painted[1].b, 39, "...and a pixel above it, so it lands where it did")
end

-- ------------------------------------------------- the copyright's letters

io.write("the copyright is turned over to read on a black row\n")
do
  -- The ground is black all the way down now, that row included, because raw
  -- and shaded have to be the same pixels there: the true-colour rect over
  -- the mon spills into that row and re-blits the canvas RAW, and 0.31.8's
  -- white paper came back through it as a bar across the words.  Dark letters
  -- on a black row are not letters, so every opaque pixel of the art turns
  -- over -- the line work comes out light and the paper it sat on comes out
  -- black, which is the page, so it disappears into it.
  local copy = art_from { "#w#" }
  local inc = art_from { "#" }
  local out = run { copyImg = copy, gfInc = inc }

  ok(out.copyImg ~= copy, "the screen draws with the turned-over copy")
  eq(shade(out.copyImg, 0, 0), "W", "the letters come out light")
  eq(shade(out.copyImg, 1, 0), "#", "and the paper under them goes black")
  eq(shade(out.gfInc, 0, 0), "W", "GAME FREAK inc. with them, as one line")
  eq(select(4, copy.data:getPixel(0, 0)), 1,
    "and the art the state came in with is not the art that was changed")
end

io.write(("\ntitle art: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
