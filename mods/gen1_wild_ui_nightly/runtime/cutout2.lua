-- The white squares around Gold's pictures.
--
-- Returns a factory: factory(context) -> { install }, built by bundle.lua in
-- the place runtime/matte.lua is built on Red, and for the same reason: the
-- theme cannot reach these.
--
-- ------- why Gold needed one after all
--
-- runtime/matte.lua carries a note saying Gold has no equivalent -- "its art
-- is drawn in the picture like everything else, so there is no white box to
-- repair and nothing for a matte to do".  Three screenshots say otherwise: the
-- trainer card's portrait, the eight gym leaders on its BADGES page and the
-- #DEX's pic all sit in a white square on a black page.
--
-- The note was right about the MECHANISM and wrong about the conclusion.  Red
-- re-blits a true-colour rectangle past the shade pass and the white page it
-- was cut out of comes back with it; Gold does none of that.  What Gold has
-- instead is full-colour cart art with the white field BAKED INTO THE PIXELS,
-- drawn raw because there is no palette to remap it through -- `TileSheet:draw`
-- takes `body()` whenever `colors` is nil, and `BattleState:drawPic` skips the
-- remap outright for anything flagged `trueColor`.  A shade substitution has
-- nothing to substitute.  The white is a picture of white.
--
-- So the Gen 2 answer is not to paint a page under the square.  It is to take
-- the square away, which is what was asked for: "can you just cut them out of
-- that square, not replace the color".
--
-- ------- the cut, and why it is a flood fill rather than a colour test
--
-- Every one of these pictures is a figure standing in a field of one colour.
-- Keying that colour out everywhere would punch holes THROUGH the figure --
-- the player's white shorts, a leader's white collar, the highlight in an eye
-- -- so the field is found by flooding inward from the border instead.  White
-- that the edge can reach is the square; white the figure encloses is the
-- shirt, and it stays.
--
-- Guarded to art that is actually a cart pic: fully opaque (anything carrying
-- its own alpha is already cut, or is replacement art whose colour 0 "is not a
-- hole, it is a colour"), few enough colours to be one, and with a field the
-- border can actually see.
--
-- ------- and where it is built
--
-- NEVER inside a draw.  Reading a picture back binds a scratch canvas and the
-- result is a new texture, and doing either with the frame's canvas bound is
-- what broke the battle pics in 0.32.62: "on iOS, the image gets flipped, on
-- android it just crashes".  Same split as the arena's, for the same reason:
--
--   in the draw     a CACHE READ.  A picture it has not seen is remembered as
--                   wanted and the cart's own square is drawn, so the first
--                   frame a screen appears on is exactly the cartridge.
--   on core.update  nothing bound, no transform in effect -- one picture per
--                   frame is read back and cut.  From the next frame it is
--                   there.
--
-- ------- two kinds of picture
--
-- The #DEX draws ONE image and fills a plate behind it.  The trainer card
-- draws its portrait and each leader's face as a BLOCK OF TILE BLITS out of a
-- sheet, and the figure is not contiguous in that sheet -- the tiles are laid
-- out in rows of sixteen -- so cutting the sheet is meaningless.
--
-- A block is therefore cut by RECORDING the blits the engine makes (their
-- image, quad and position: no GL call, nothing created, safe inside a draw),
-- replaying them into a canvas on the update, and cutting that.  The geometry
-- stays the engine's own -- read off the blits rather than re-derived -- so a
-- tile the cart moves moves here too.

local Cutout2 = {}

-- Big enough for a 7x7 pic and a 5x7 portrait, small enough that a sheet
-- handed here by mistake is refused rather than read back a megapixel at a
-- time.
local MAX_SIDE = 128
-- A cart picture is 2bpp art or a small-palette replacement for one.  A
-- photograph is not a thing to cut a square out of.
local MAX_COLORS = 64

-- ------- the cut itself, on one ImageData
--
-- Pure, and exposed, because it is the whole of the risk: getting it wrong
-- cuts a hole in a picture.
function Cutout2.cut(data, w, h)
  local dw, dh = w, h
  if type(data.getDimensions) == "function" then
    local ok, gw, gh = pcall(data.getDimensions, data)
    if ok and tonumber(gw) and tonumber(gh) then dw, dh = gw, gh end
  end
  -- DPI scale: a canvas asked for at w x h can come back bigger, and reading
  -- the first w x h of that is a magnified corner.  Measured off what actually
  -- came back rather than off what was asked for.
  if dw < w or dh < h or dw % w ~= 0 or dh % h ~= 0 or dw / w ~= dh / h then
    return nil
  end
  local ratio = dw / w
  local half = math.floor(ratio / 2)

  local px, colors, nColors = {}, {}, 0
  local field, fieldRed = nil, -1
  for y = 0, h - 1 do
    local row = y * w
    for x = 0, w - 1 do
      local r, g, b, a = data:getPixel(x * ratio + half, y * ratio + half)
      if a <= 0.5 then return nil end
      local key = math.floor(r * 255 + 0.5) * 65536
                + math.floor(g * 255 + 0.5) * 256
                + math.floor(b * 255 + 0.5)
      px[row + x] = key
      if not colors[key] then
        colors[key] = true
        nColors = nColors + 1
        if nColors > MAX_COLORS then return nil end
      end
      -- The lightest by RED, which is the shade the hardware would call 0 --
      -- the same channel GbcPalette's own shader keys off.
      if r > fieldRed then field, fieldRed = key, r end
    end
  end
  if nColors < 2 or not field then return nil end

  local figure = {}
  for i = 0, w * h - 1 do
    if px[i] ~= field then figure[i] = true end
  end

  local outside, qx, qy, head = {}, {}, {}, 1
  local function push(x, y)
    if x < 0 or y < 0 or x >= w or y >= h then return end
    local key = y * w + x
    if outside[key] or figure[key] then return end
    outside[key] = true
    qx[#qx + 1], qy[#qy + 1] = x, y
  end
  for x = 0, w - 1 do push(x, 0); push(x, h - 1) end
  for y = 0, h - 1 do push(0, y); push(w - 1, y) end
  while head <= #qx do
    local x, y = qx[head], qy[head]
    head = head + 1
    push(x - 1, y); push(x + 1, y); push(x, y - 1); push(x, y + 1)
  end

  local n = 0
  for i = 0, w * h - 1 do if outside[i] then n = n + 1 end end
  -- Nothing the border can reach is not a picture in a square.
  if n == 0 then return nil end

  local out = love.image.newImageData(w, h)
  for y = 0, h - 1 do
    local row = y * w
    for x = 0, w - 1 do
      local r, g, b = data:getPixel(x * ratio + half, y * ratio + half)
      -- Colour is kept even where it is cut, so a host that ignores alpha
      -- shows the picture it always did rather than a black hole.
      out:setPixel(x, y, r, g, b, outside[row + x] and 0 or 1)
    end
  end
  return out
end

function Cutout2.new(context)
  local mod = context.mod
  local self = {}

  local function on()
    return mod.options:get("gen2_cutout") ~= false
  end

  -- ------- the queue
  --
  -- `wanted` is weak-keyed so a screen closing lets its pictures go; `queue`
  -- holds a strong reference only until the update that builds it.
  local built = setmetatable({}, { __mode = "k" })
  local wanted = setmetatable({}, { __mode = "k" })
  local queue = {}
  -- Blocks are keyed by a string, not by an image, so they are kept by hand.
  local blocks, blockWanted, blockQueue = {}, {}, {}
  -- What the engine's own draw RETURNED for a block, kept beside the cut.
  -- `drawLeaderFace` hands back the next tile id and the page walks its eight
  -- faces with it, so the cached path has to answer the same number -- and the
  -- only honest source for it is the call that was recorded.  Counting the
  -- tiles here instead is re-deriving the engine's loop, and the first attempt
  -- at it was wrong by three.
  local blockReturn = {}

  local function toImage(data)
    local image = love.graphics.newImage(data)
    if type(image.setFilter) == "function" then
      pcall(image.setFilter, image, "nearest", "nearest")
    end
    return image
  end

  -- ------- one image
  --
  -- The cart's own picture, read back through a canvas the size it says it is.
  local function readImage(image)
    local w, h = image:getDimensions()
    if w < 1 or h < 1 or w > MAX_SIDE or h > MAX_SIDE then return nil end
    -- dpiscale is load-bearing: without it a phone at scale 3 hands back a
    -- canvas three times the size and the read below is a magnified corner.
    local ok, canvas = pcall(love.graphics.newCanvas, w, h, { dpiscale = 1 })
    if not ok then canvas = love.graphics.newCanvas(w, h) end
    local previous = love.graphics.getCanvas()
    love.graphics.push("all")
    -- No transform: this runs between frames, but a host that left one in
    -- place would put the picture somewhere other than 0,0 and the read would
    -- be of an empty canvas.
    love.graphics.origin()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, 0, 0)
    love.graphics.setCanvas(previous)
    love.graphics.pop()
    return canvas:newImageData(), w, h
  end

  function self.imageFor(image)
    local hit = built[image]
    if hit ~= nil then return hit or nil end
    if not wanted[image] then
      wanted[image] = true
      queue[#queue + 1] = image
    end
    return nil
  end

  local function buildImage(image)
    built[image] = false
    local data, w, h = readImage(image)
    if not data then return end
    local cutData = Cutout2.cut(data, w, h)
    if cutData then built[image] = toImage(cutData) end
  end

  -- ------- a block of blits
  --
  -- The recording is (image, quad, x, y) tuples and nothing else: appending to
  -- a table inside a draw creates no GL object and cannot fail the way making
  -- a texture there can.
  local recording = nil

  function self.blockFor(key)
    local hit = blocks[key]
    if hit ~= nil then return hit or nil end
    return nil
  end

  -- Called around the engine's own draw.  Returns a function to close the
  -- recording, so the caller cannot forget which half it is in.
  function self.record(key, ox, oy, w, h)
    if blocks[key] ~= nil or blockWanted[key] then return function() end end
    local realDraw = love.graphics.draw
    local list = {}
    recording = list
    love.graphics.draw = function(image, a, b, c, ...)
      -- `draw(image, quad, x, y)` and `draw(image, x, y)` are both shapes the
      -- engine uses; the quad is only ever the second argument.
      if type(a) == "table" or type(a) == "userdata" then
        list[#list + 1] = { image = image, quad = a, x = b or 0, y = c or 0 }
      else
        list[#list + 1] = { image = image, x = a or 0, y = b or 0 }
      end
      return realDraw(image, a, b, c, ...)
    end
    return function(returned)
      love.graphics.draw = realDraw
      recording = nil
      if returned ~= nil then blockReturn[key] = returned end
      if #list == 0 then return end
      blockWanted[key] = true
      blockQueue[#blockQueue + 1] =
        { key = key, list = list, ox = ox, oy = oy, w = w, h = h }
    end
  end

  local function buildBlock(job)
    blocks[job.key] = false
    blockWanted[job.key] = nil
    local w, h = job.w, job.h
    if w < 1 or h < 1 or w > MAX_SIDE or h > MAX_SIDE then return end
    local ok, canvas = pcall(love.graphics.newCanvas, w, h, { dpiscale = 1 })
    if not ok then canvas = love.graphics.newCanvas(w, h) end
    local previous = love.graphics.getCanvas()
    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    for _, blit in ipairs(job.list) do
      -- Replayed at the block's own origin, so the canvas holds the picture
      -- and not the corner of a screen.
      if blit.quad then
        love.graphics.draw(blit.image, blit.quad, blit.x - job.ox, blit.y - job.oy)
      else
        love.graphics.draw(blit.image, blit.x - job.ox, blit.y - job.oy)
      end
    end
    love.graphics.setCanvas(previous)
    love.graphics.pop()
    local cutData = Cutout2.cut(canvas:newImageData(), w, h)
    if cutData then blocks[job.key] = toImage(cutData) end
  end

  -- One picture per frame.  A trainer card asks for nine at once and a
  -- readback is not free; cutting them all on the frame the page opens is a
  -- stutter exactly where it would be noticed.
  function self.buildOne()
    local job = table.remove(blockQueue, 1)
    if job then buildBlock(job); return job.key end
    local image = table.remove(queue, 1)
    if image then wanted[image] = nil; buildImage(image); return image end
    return nil
  end

  function self.queued() return #queue + #blockQueue end
  self.cut = Cutout2.cut
  self.blockReturn = function(key) return blockReturn[key] end

  -- ------- the screens

  local MARK = "__gen1wildCutout2"

  local function installTrainerCard()
    local ok, TrainerCard = pcall(require, "src.ui.gen2.TrainerCard")
    if not (ok and type(TrainerCard) == "table") then return end
    if rawget(TrainerCard, MARK) then return end

    local function overBlock(base, key, ox, oy, w, h)
      return function(screen, ...)
        if not on() then return base(screen, ...) end
        local cut = self.blockFor(key)
        if cut then
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.draw(cut, ox, oy)
          return
        end
        local close = self.record(key, ox, oy, w, h)
        local okDraw, err = pcall(base, screen, ...)
        close(okDraw and err or nil)
        if not okDraw then error(err, 0) end
        return err
      end
    end

    -- TrainerCard_PrintTopHalfOfCard: the 5x7 portrait at (14,1).  Its size is
    -- read off the screen rather than fixed, because `gfx.portraitWide` and
    -- `portraitTiles` are what the engine lays it out from.
    local basePortrait = TrainerCard.drawPortrait
    if type(basePortrait) == "function" then
      TrainerCard.drawPortrait = function(screen, ...)
        local wide = (screen.gfx and screen.gfx.portraitWide) or 5
        local high = math.floor(((screen.gfx and screen.gfx.portraitTiles)
          or 35) / wide)
        return overBlock(basePortrait, "portrait", 14 * 8, 1 * 8,
                         wide * 8, high * 8)(screen, ...)
      end
    end

    -- The eight leaders, each a 4x3 run of tiles starting at `first`.  Keyed
    -- by that run, so the eight are eight pictures and a leader that moves on
    -- the page keeps its cut.
    local baseFace = TrainerCard.drawLeaderFace
    if type(baseFace) == "function" then
      TrainerCard.drawLeaderFace = function(screen, first, tx, ty, ...)
        if not on() then return baseFace(screen, first, tx, ty, ...) end
        local key = "leader:" .. tostring(first)
        local cut = self.blockFor(key)
        if cut then
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.draw(cut, tx * 8, ty * 8)
          -- The engine's own return is the NEXT tile id and the page walks its
          -- eight faces with it, so the cached path answers what the recorded
          -- call answered rather than a count made up here.
          return blockReturn[key]
        end
        local close = self.record(key, tx * 8, ty * 8, 4 * 8, 3 * 8)
        local okDraw, err = pcall(baseFace, screen, first, tx, ty, ...)
        close(okDraw and err or nil)
        if not okDraw then error(err, 0) end
        return err
      end
    end

    TrainerCard[MARK] = true
  end

  local function installDex()
    local ok, PokedexMenu = pcall(require, "src.ui.gen2.PokedexMenu")
    if not (ok and type(PokedexMenu) == "table") then return end
    if rawget(PokedexMenu, MARK) then return end
    local basePic = PokedexMenu.drawPic
    if type(basePic) ~= "function" then return end

    -- The #DEX is the other shape: ONE image, with a plate filled behind it in
    -- the palette's colour 0 before it lands.  Both halves are the square --
    -- cutting the picture and leaving the plate would change nothing at all --
    -- so the plate is dropped for exactly as long as a cut picture is going in
    -- its place, and kept otherwise.
    PokedexMenu.drawPic = function(screen, row, tx, ty, ownColors, ...)
      if not on() then return basePic(screen, row, tx, ty, ownColors, ...) end
      local image
      if row and row.seen and row.species then
        local okPic, got = pcall(screen.picFor, screen, row.species)
        image = okPic and got or nil
      end
      if not image then return basePic(screen, row, tx, ty, ownColors, ...) end
      local cut = self.imageFor(image)
      if not cut then
        return basePic(screen, row, tx, ty, ownColors, ...)
      end

      local realRect = love.graphics.rectangle
      local realDraw = love.graphics.draw
      local dropped = false
      love.graphics.rectangle = function(mode, x, y, w, h, ...)
        if not dropped and mode == "fill" and w == 7 * 8 and h == 7 * 8 then
          dropped = true
          return
        end
        return realRect(mode, x, y, w, h, ...)
      end
      love.graphics.draw = function(what, ...)
        if what == image then return realDraw(cut, ...) end
        return realDraw(what, ...)
      end
      local okDraw, err = pcall(basePic, screen, row, tx, ty, ownColors, ...)
      love.graphics.rectangle, love.graphics.draw = realRect, realDraw
      if not okDraw then error(err, 0) end
      return err
    end

    PokedexMenu[MARK] = true
  end

  function self.install()
    installTrainerCard()
    installDex()
    mod.hooks:wrap("core.update", function(nextLink, game, dt)
      if on() then
        local okBuild, problem = pcall(self.buildOne)
        if not okBuild then
          mod.log:warn("a picture could not be cut from its square: %s",
                       tostring(problem))
        end
      end
      return nextLink(game, dt)
    end)
    return true
  end

    return self
end

return Cutout2
