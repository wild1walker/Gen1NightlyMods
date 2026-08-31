-- The bakes the title screen's own art goes through, and the one thing they
-- all have in common: every one of them reads a FILE.
--
-- 0.31.10 read the pictures back off the GPU instead, so that art another mod
-- had swapped in could be treated too.  Something in that -- the canvas bind,
-- the blend mode, the transform; it was never established which -- left the
-- pipeline in a state the rest of the frame did not survive: POKeMON several
-- times their size, colour zones in the wrong places, hairlines through
-- everything, twice.  `Assets.imageData` touches no GPU state at all, and
-- that is the whole reason these are shaped the way they are.
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

-- ------- the engine's image side, and nothing else of it

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

local gpu = { canvases = 0 }

love = {
  graphics = {
    setColor = function() end,
    rectangle = function() end,
    newImage = function(data)
      return { data = data, setFilter = function() end,
               getDimensions = function(self) return self.data:getDimensions() end }
    end,
    draw = function() end,
    -- present, and failing loudly: nothing here may touch the pipeline
    newCanvas = function() gpu.canvases = gpu.canvases + 1; error("no canvases") end,
    setCanvas = function() error("no canvases") end,
  },
  image = { newImageData = newData },
}

local PaletteFX = {
  mode = "redpp",
  honorsTrueColor = function() return true end,
  markTrueColor = function() end,
}
package.preload["src.render.PaletteFX"] = function() return PaletteFX end

-- "#" line work, "w" the paper it is printed on, "." transparent
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

local Matte = chunkOf("runtime/matte.lua")

local theme = {
  read = function() return "dark" end,
  matte = function() return { 0, 0, 0 } end,
  clipArt = function() end,
  paintSkirts = function() end,
}
local context = { theme = theme, mod = { log = { warn = function() end } } }

local function shade(image, x, y)
  local r, _, _, a = image.data:getPixel(x, y)
  if a == 0 then return "." end
  if r > 0.83 then return "W" end
  return "#"
end

local function picture(image, w, h)
  local out = {}
  for y = 0, h - 1 do
    local row = {}
    for x = 0, w - 1 do row[#row + 1] = shade(image, x, y) end
    out[#out + 1] = table.concat(row)
  end
  return table.concat(out, "\n")
end

local fills, seen
local function titleDraw(state)
  love.graphics.rectangle("fill", 0, 0, 160, 144)
  seen = { logo = state.logo, version = state.version, player = state.player,
           copyImg = state.copyImg, gfInc = state.gfInc }
end

local function run(state)
  seen = nil
  fills = {}
  local real = love.graphics.rectangle
  love.graphics.rectangle = function(mode, x, y, w, h)
    fills[#fills + 1] = { x = x, y = y, w = w, h = h }
    return real(mode, x, y, w, h)
  end
  Matte.new(context).wrapTitle(titleDraw)(state)
  love.graphics.rectangle = real
  return seen
end

local function defaults()
  art["assets/logo/pokemon_logo.png"] = art_from { "w#w" }
  art["assets/generated/title/red_version.png"] = art_from { "w#w" }
  art["assets/generated/title/copyright.png"] = art_from { "w#w" }
  art["assets/generated/title/gamefreak_inc.png"] = art_from { "w#" }
end

-- ------------------------------------------------ nothing touches the GPU

io.write("no bake goes near a canvas\n")
do
  -- The stub raises on newCanvas and setCanvas.  If a bake reaches for one,
  -- every test below it fails loudly rather than quietly changing what this
  -- bundle does to somebody's frame.
  defaults()
  run { logo = art["assets/logo/pokemon_logo.png"] }
  eq(gpu.canvases, 0, "not one canvas was asked for")
end

-- ------------------------------------------------------- the logo's pad

io.write("the logo keeps paper of its own shape, and loses the rest\n")
do
  -- A letter: black outline, white face inside it, white field all round.
  -- Keying the paper the border can reach takes the face with the field on
  -- this logo -- every one of POKeMON's near-white pixels is reachable from
  -- the edge -- which is why it had no white in it.  The item icons do not
  -- key paper, they GROW it.
  --
  -- And it is baked into a sheet a pixel larger on every side, because the
  -- ROM's wordmark runs into the last column of its own -- `raw2bpp`
  -- "PokemonLogoGraphics" at 128x56 with no transparency -- and a pad has
  -- nowhere to go there.  That is the missing edge a player reported.
  defaults()
  local logo = art_from {
    "wwwwww",
    "w####w",
    "w#ww#w",
    "w####w",
    "wwwwww",
  }
  art["assets/logo/pokemon_logo.png"] = logo
  local out = run { logo = logo }
  ok(out.logo ~= logo, "the state draws with the baked copy")
  eq(picture(out.logo, 8, 7), table.concat({
    "........",
    ".WWWWWW.",
    ".W####W.",
    ".W#WW#W.",
    ".W####W.",
    ".WWWWWW.",
    "........",
  }, "\n"), "the face keeps its white, the field goes, and a pixel of paper "
    .. "is left round the outline as the pad -- on all four sides, including "
    .. "the one the sheet had no room for")
end

io.write("and a sheet with a margin is drawn a pixel up and left\n")
do
  -- Or the whole wordmark sits one pixel down and right of where the
  -- cartridge puts it.
  defaults()
  local logo = art_from { "w#w" }
  art["assets/logo/pokemon_logo.png"] = logo
  local drawnAt
  local realDraw = love.graphics.draw
  local state = { logo = logo }
  local function logoDraw(st)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
    love.graphics.draw(st.logo, 16, 8)
  end
  love.graphics.draw = function(image, x, y) drawnAt = { image, x, y } end
  Matte.new(context).wrapTitle(logoDraw)(state)
  love.graphics.draw = realDraw
  ok(drawnAt ~= nil, "the logo is drawn")
  eq(drawnAt[2], 15, "a pixel left of the 16 the cartridge draws it at")
  eq(drawnAt[3], 7, "...and a pixel above the 8")
end

io.write("the ribbon does not get one, and loses its paper outright\n")
do
  -- Not stickered, and the difference is spacing.  The logo is one connected
  -- mass, so a pixel of pad round it is an outline.  The ribbon is eight
  -- pixels of letters with a pixel between them: pad every letter and the
  -- pads meet, and out comes a white plate with words on it -- which is the
  -- white box behind WILD GREEN VERSION this work started from.  Counters
  -- included, or the white shut inside an `e` stays behind as a speck.
  defaults()
  local ribbon = art_from {
    "wwwwwwww",
    "ww####ww",
    "ww#ww#ww",
    "ww####ww",
  }
  art["assets/generated/title/red_version.png"] = ribbon
  local out = run { version = ribbon }
  eq(picture(out.version, 8, 4), table.concat({
    "........",
    "..####..",
    "..#..#..",
    "..####..",
  }, "\n"), "the words keep their line work and nothing else keeps white")
end

-- --------------------------------------------------- the copyright's row

io.write("the copyright turns over, and its row goes black with it\n")
do
  -- `RomExtractor` writes both its files with `raw2bpp` and no transparency
  -- -- title/copyright.png at 152x8 and title/gamefreak_inc.png at 72x8 --
  -- so they are fully opaque four-shade greys: white paper, dark letters.
  -- Turning every pixel over gives light letters on black paper, and black
  -- paper is the page, so it disappears into it.
  defaults()
  local out = run { copyImg = art["assets/generated/title/copyright.png"],
                    gfInc = art["assets/generated/title/gamefreak_inc.png"] }
  eq(picture(out.copyImg, 3, 1), "#W#", "the letters come out light and the "
    .. "paper they sat on comes out black -- opaque black, which is the page "
    .. "it is drawn on, so it disappears into it")
  eq(picture(out.gfInc, 2, 1), "#W", "GAME FREAK inc. with them, as one line")

  eq(#fills, 1, "and the ground is painted black in one fill, all 144 rows")
  eq(fills[1].h, 144, "...the copyright row included")
end

io.write("but a row whose letters could not be turned is left light\n")
do
  -- Light letters or a light row, never dark letters on a dark one.  This is
  -- the same shape as `__gen1WildKeyedArt`: the ground asks whether the bake
  -- TOOK rather than assuming it.
  defaults()
  art["assets/generated/title/gamefreak_inc.png"] = nil
  local out = run { copyImg = art["assets/generated/title/copyright.png"],
                    gfInc = { data = "unreadable" } }
  eq(#fills, 2, "the fill is served as two")
  eq(fills[1].h, 136, "black down to the copyright row")
  eq(fills[2].y, 136, "and that row left light, with its dark letters on it")
end

io.write("half a line is not a line\n")
do
  -- All of it turns over or none of it does.  Half a line of light letters
  -- beside half a line of dark ones is worse than the light row.
  defaults()
  local copy = art["assets/generated/title/copyright.png"]
  art["assets/generated/title/gamefreak_inc.png"] = nil
  local out = run { copyImg = copy, gfInc = { data = "unreadable" } }
  eq(out.copyImg, copy, "the half that could have turned is left alone too, "
    .. "or it would be light letters on a light row")
  eq(#fills, 2, "and the row stays light")
end

-- ------------------------------------------- the figure, and the guard

io.write("the figure is baked from the path its picture actually came from\n")
do
  -- `state.playerPath` is the RED figure's, because that is what TitleState
  -- loaded.  Wild Green swaps `state.player` for its green derived copy and
  -- leaves that path alone, so baking it is what put the red suit back on a
  -- green cart in 0.31.8.  Its recipe names the file it used instead.
  defaults()
  local red = art_from { "..##..", "..##.." }
  local green = art_from { "..##..", "..##.." }
  art["assets/generated/title/player.png"] = red
  art["assets/generated/green/title/player.png"] = green

  local quad = function(x, y, w, h)
    return { getViewport = function() return x, y, w, h end }
  end
  local out = run {
    player = green,
    playerPath = "assets/generated/title/player.png",
    __gen1WildPlayerPath = "assets/generated/green/title/player.png",
    playerQuads = { { quad(0, 0, 6, 2), 0, 0 } },
  }
  ok(out.player ~= green, "the figure is stickered")
  ok(out.player.data ~= red, "and it is the green file that was baked, not "
    .. "the red one the state still names")
end

io.write("the figure gets a one-pixel outline, per quad\n")
do
  -- Sprites on transparency, so the line work is every opaque pixel and the
  -- pad is an outline.  Per quad, because the POKe BALL is tucked into the
  -- gap at (0,16) and the trainer's slices are full width: one bake across
  -- the sheet would put a pixel of the trainer's edge on the ball.
  defaults()
  local figure = art_from {
    "........",
    "...##...",
    "...##...",
    "........",
  }
  art["assets/generated/title/player.png"] = figure
  local quad = function(x, y, w, h)
    return { getViewport = function() return x, y, w, h end }
  end
  local out = run {
    player = figure,
    playerPath = "assets/generated/title/player.png",
    playerQuads = { { quad(0, 0, 8, 4), 0, 0 } },
  }
  eq(picture(out.player, 8, 4), table.concat({
    "..WWWW..",
    "..W##W..",
    "..W##W..",
    "..WWWW..",
  }, "\n"), "white all the way round the trainer and nowhere else")
end

io.write("a bake of a different size does not stand in for anything\n")
do
  -- The guard that would have caught 0.31.10 on its first frame.  The title
  -- places the mon at `x = 40 + (56 - w) / 2` and `y = 136 - h` off the
  -- dimensions of whatever it is handed, so a substitute of a different size
  -- is not a different-looking mon, it is a POKeMON across half the screen on
  -- top of the logo.
  defaults()
  local drawn = art_from { "..##..", "..##.." }          -- what is on screen
  local other = art_from { "##", "##", "##", "##" }      -- a different sheet
  art["assets/generated/title/player.png"] = other
  local out = run {
    player = drawn,
    playerPath = "assets/generated/title/player.png",
  }
  eq(out.player, drawn, "the picture is handed back exactly as it came")
end

-- ------------------------------------------------------------ the ball

io.write("the ball is cut out so its pad has somewhere to go\n")
do
  -- Every pixel around its cell inside the sheet belongs to the trainer.
  defaults()
  local sheet = art_from {
    "..##....",
    "..##....",
    "........",
  }
  art["assets/generated/title/player.png"] = sheet
  local ballQuad = { getViewport = function() return 2, 0, 2, 2 end }
  local painted = {}
  local realDraw = love.graphics.draw
  local state = {
    player = sheet,
    playerPath = "assets/generated/title/player.png",
    ballQuad = ballQuad,
    playerQuads = { { ballQuad, 0, 0 } },
  }
  local function ballDraw(st)
    love.graphics.rectangle("fill", 0, 0, 160, 144)
    love.graphics.draw(st.player, st.ballQuad, 82, 40)
  end
  love.graphics.draw = function(image, a, b, c)
    painted[#painted + 1] = { image, a, b, c }
  end
  Matte.new(context).wrapTitle(ballDraw)(state)
  love.graphics.draw = realDraw

  ok(state.__gen1WildBall ~= nil, "a padded ball is cut from the sheet")
  eq(picture(state.__gen1WildBall, 4, 4),
     table.concat({ "WWWW", "W##W", "W##W", "WWWW" }, "\n"),
     "white all the way round it, which the sheet had no room for")
  eq(#painted, 1, "the ball is drawn once")
  eq(painted[1][1], state.__gen1WildBall, "and it is the padded copy")
  eq(painted[1][2], 81, "a pixel left of where the bare ball would have gone")
  eq(painted[1][3], 39, "...and a pixel above it, so it lands where it did")
end

-- ------------------------------------------------------------- the mon

io.write("the mon is stickered from the file its own call resolves\n")
do
  defaults()
  local monArt = art_from { "....", ".##.", ".##.", "...." }
  art["mon.png"] = monArt
  package.preload["src.pokemon.Sprites"] = function()
    return { path = function() return "mon.png" end }
  end
  local TitleState = { draw = titleDraw,
                       currentSprite = function() return monArt, true end }
  package.preload["src.ui.TitleState"] = function() return TitleState end
  Matte.new(context).installTitle()
  local image = TitleState.currentSprite({ __gen1WildKeyedArt = true,
                                           cycleSpecies = { "X" },
                                           cycleIndex = 1, game = { data = {} } })
  eq(picture(image, 4, 4), table.concat({
    "WWWW", "W##W", "W##W", "WWWW",
  }, "\n"), "outlined the way the figure is")
end

io.write("...and left alone when that file is a different size\n")
do
  -- With Crystal Animated Sprites installed, `currentSprite` hands back an
  -- animation SHEET; the static file behind it is a different size, the sizes
  -- disagree, and nothing is substituted.  0.31.10 had no guard and drew the
  -- sheet: a CHARMANDER over half the screen with its other frames beside it.
  defaults()
  art["mon.png"] = art_from { "##", "##" }
  local sheetOfFrames = art_from { "####", "####", "####", "####" }
  local TitleState = { draw = titleDraw,
                       currentSprite = function() return sheetOfFrames, true end }
  package.preload["src.ui.TitleState"] = function() return TitleState end
  Matte.new(context).installTitle()
  eq(TitleState.currentSprite({ __gen1WildKeyedArt = true,
                                cycleSpecies = { "X" }, cycleIndex = 1,
                                game = { data = {} } }),
     sheetOfFrames, "the sheet is handed straight back")
end

io.write("and on a screen that is not the dark one, never touched at all\n")
do
  defaults()
  local plain = art_from { "##" }
  local TitleState = { draw = titleDraw,
                       currentSprite = function() return plain, true end }
  package.preload["src.ui.TitleState"] = function() return TitleState end
  Matte.new(context).installTitle()
  eq(TitleState.currentSprite({}), plain,
    "a state with no dark ground gets its own sprite back untouched")
end

io.write(("\ntitle art: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
