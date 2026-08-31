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

love = {
  graphics = {
    setColor = function() end,
    rectangle = function() end,
    newImage = function(data) return { data = data } end,
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
local art = {}

local function art_from(rows)
  local h, w = #rows, #rows[1]
  local id = newData(w, h)
  for y = 1, h do
    for x = 1, w do
      local c = rows[y]:sub(x, x)
      if c == "#" then id:setPixel(x - 1, y - 1, 0, 0, 0, 1)
      elseif c == "w" then id:setPixel(x - 1, y - 1, 1, 1, 1, 1)
      else id:setPixel(x - 1, y - 1, 0, 0, 0, 0) end
    end
  end
  return id
end

package.preload["src.render.Assets"] = function()
  return { imageData = function(path) return assert(art[path], path) end }
end

package.preload["src.pokemon.Sprites"] = function()
  return { path = function() return "mon.png" end }
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
  art["logo.png"] = art_from {
    "wwwwwwww",
    "ww####ww",
    "ww#ww#ww",
    "ww#ww#ww",
    "ww####ww",
    "wwwwwwww",
  }
  local out = run { title = { logo = "logo.png" }, logo = "before" }
  ok(out.logo ~= "before", "the state draws with the baked copy")

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
  local state = { title = { logo = "logo.png" }, logo = "before" }
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
  art["ribbon.png"] = art_from {
    "wwwwwwww",
    "ww####ww",
    "ww#ww#ww",
    "ww####ww",
  }
  local out = run { title = { versionRibbon = "ribbon.png" },
                    version = "before", versionFull = true }
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
  art["player.png"] = art_from {
    "........",
    "...##...",
    "...##...",
    "........",
  }
  local quad = function(x, y, w, h)
    return { getViewport = function() return x, y, w, h end }
  end
  local out = run {
    title = {}, playerPath = "player.png", player = "before",
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
  art["player.png"] = art_from { "..##..", "..##.." }
  seen = nil
  PaletteFX.obp = true
  Matte.new(context).wrapTitle(titleDraw)({
    title = {}, playerPath = "player.png", player = "before" })
  eq(seen.player, "before", "the figure is left exactly as the state had it")
end

-- ------------------------------------------------------------- the mon

io.write("the mon is stickered through the call that hands it over\n")
do
  -- It is the one piece of title art with no field to swap: cached per
  -- species inside the state and reached only through `currentSprite`.
  art["mon.png"] = art_from { "....", ".##.", ".##.", "...." }
  art["logo.png"] = art_from { "w#w" }

  local base = function() return { data = "raw" }, true end
  local state = {
    title = { logo = "logo.png" }, logo = "before",
    cycleSpecies = { "BULBASAUR" }, cycleIndex = 1,
    game = { data = {} },
  }
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
  local TitleState = { draw = titleDraw,
                       currentSprite = function() return { data = "raw" }, true end }
  package.preload["src.ui.TitleState"] = function() return TitleState end
  Matte.new(context).installTitle()
  local image = TitleState.currentSprite({ cycleSpecies = { "X" }, cycleIndex = 1,
                                           game = { data = {} } })
  eq(image.data, "raw",
    "a state with no dark ground gets its own sprite back untouched")
end

io.write(("\ntitle art: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
