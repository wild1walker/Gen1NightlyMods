-- The white box behind true-colour art, on screens this suite does not own.
--
-- ------- what the box is, and why it is only ever ADVANCED
--
-- `PaletteFX.markTrueColor(x, y, w, h)` is the engine's opt-out from the
-- shade pass.  A marked rectangle is spliced onto the end of the frame's zone
-- list as `colors = false` and re-blitted RAW, so a mod's animated sprite or
-- a coloured portrait keeps its own colours instead of being read as four
-- DMG shades and repainted off its red channel.
--
-- Raw means raw.  The page the screen cleared to WHITE is white inside that
-- rectangle too, and it stays white when the theme turns everything around it
-- black.  That is the white box.
--
-- It is an ADVANCED problem and only an ADVANCED problem, which is worth
-- being exact about because it decides when any of this runs at all:
-- `Renderer`'s withTrueColor begins `if not PaletteFX.honorsTrueColor() then
-- return zoneList end`, and for a Gen 1 game `honorsTrueColor` is
-- `PaletteFX.mode == "redpp"` -- ADVANCED, and nothing else.  In SGB, OG RED
-- or any of the flat modes the marks are discarded, the art goes through the
-- shade pass with the rest of the screen, and there is no box to fix.
--
-- ------- why this cannot be fixed from a zone
--
-- The theme's own hook runs on the zone list before the renderer splices the
-- true-colour rects on, and those rects are LAST -- they re-blit their region
-- over whatever the shaded pass drew.  So no zone this suite adds can reach
-- inside one.  The white is not a palette; it is a pixel, and it was put
-- there by the screen when it cleared its page.
--
-- The screens this suite owns fix it themselves: each paints `theme.matte()`
-- into the rectangle before it draws the art into it.  This file is for the
-- ones it does not own -- the trainer card's portrait, the summary screen's
-- Pokemon, the Hall of Fame PC, the diploma -- where there is no line of ours
-- to put that paint on.
--
-- ------- what it does instead
--
-- Wraps the class's `draw` and runs it twice.
--
--   1. once with `markTrueColor` swapped for a recorder, which draws the
--      frame and collects the rectangles instead of marking them;
--   2. the matte, painted into each rectangle;
--   3. once more for real, which redraws the art on top of the matte and
--      marks the rectangles properly this time.
--
-- Twice is the price of not knowing where the art goes until the screen has
-- drawn it, and it is a price worth naming: these are static single-page
-- screens, the second pass is the same work the first did, and it is only
-- paid at all when a theme is on AND the mode is ADVANCED AND the screen
-- actually marked something.  A LIGHT boot, an SGB boot, or a screen with no
-- true-colour art on it never reaches step 1.
--
-- Recording SUPPRESSES the marks rather than duplicating them: the recorder
-- stands in for `markTrueColor` for exactly the length of pass 1, so the real
-- marks are the ones pass 3 makes, and the renderer sees each rectangle once.
--
-- ------- the honest cost
--
-- This patches a method on an engine class, which is a heavier hand than
-- anything else in this bundle -- every other screen here is registered
-- through `mod.content.screens`, or is an instance built by the engine and
-- re-dressed.  There is no seam for "before this state draws", and a screen
-- we do not own has no line of ours in it.  So the patch is kept as small as
-- a patch can be: it calls through in every case it does not handle, it is
-- installed once, and with a LIGHT theme or a mode that is not ADVANCED it is
-- one comparison and a tail call.

--
-- ------- the title screen, which is the same white page by another road
--
-- 0.24.0 tried to make the title screen dark the way every other page in
-- this suite is dark: reverse its palettes, so the paper goes black and the
-- ink goes white.  Three things went wrong on screen and it was backed out
-- in 0.28.0 (see Theme.COVERED_PAGES).  The one that matters here is the
-- third: the mon and the player figure are marked TRUE COLOUR, so their
-- rectangles are re-blitted raw from a canvas whose page is white -- two
-- white boxes on a black screen, which is exactly what a matte is for, and
-- exactly what a matte could not fix here.  `Matte.wrap` draws the screen
-- twice with the paint in between, and `TitleState:draw` OPENS with a white
-- fill of the whole screen: the second pass paints over the matte before it
-- draws anything.
--
-- So the title screen is done the other way round.  Rather than reverse the
-- palette and then repair the raw rectangles, paint the PAGE ITSELF black
-- and leave the palettes alone:
--
--   * the ground is black pixels, which every band already reads as its own
--     colour 3, and the theme pins that colour to black so it is black
--     whatever palette the cart ships (theme.lua, groundZones);
--   * the logo, the ribbon and the mon keep colours 0, 1 and 2 -- their own
--     colours, which is what was asked for;
--   * a true-colour rectangle re-blits a page that is ALREADY BLACK, so
--     there is no white box to repair and nothing has to be drawn twice.
--
-- It works in every display mode rather than only ADVANCED, because it is
-- not a true-colour fix -- it is the page.
--
-- Two details it has to get right:
--
--   The copyright line is BLACK INK, and black ink on a black page is not
--   there.  So the bottom row is left WHITE and the theme reverses that one
--   row on its own -- white letters on black, the same trade every dialogue
--   box in this suite makes.  Everything above it is painted black.
--
--   With the CONTINUE menu open none of this applies.  `TitleState:draw`
--   fills white and returns (MainMenu's own ClearScreen); there is no art on
--   the screen, the frame is an ordinary page, and Theme.COVERED_PAGES
--   reverses it like any other.  Painting a black ground under that would
--   reverse to a WHITE one.
--
-- ------- the shim, and why it is one
--
-- The fill is the first line of `TitleState:draw`.  There is no seam before
-- it and no colour to configure, so `love.graphics.rectangle` stands in for
-- itself for the length of one call: the first full-screen fill is answered
-- with the black page and the white copyright row, the real function is put
-- back the moment that fill is served, and every other rectangle the screen
-- draws goes through untouched.  It is the same shape as the markTrueColor
-- swap above -- narrow, restored on every path including a raise, and doing
-- nothing at all under LIGHT.
--
-- It is also indifferent to who else has wrapped this method.  Wild Green
-- wraps `TitleState.draw` to mark the figure before the draw reads it, and
-- whichever of the two ends up outermost, the fill is still served from
-- inside the other one.

local Matte = {}

-- Engine screens that BOTH mark true colour and are themed pages.  A screen
-- that marks nothing has nothing to matte; a screen the theme leaves alone is
-- still on white paper, where a white box is invisible.
--
-- `src.ui.DexEntryMenu` is here for the build where POKEDEX is switched off:
-- with it on, Gen1Dex registers its own entry screen, that instance carries
-- its own `draw`, and this wrapper is never reached for it.
Matte.SCREENS = {
  "src.ui.TrainerCard",
  "src.ui.SummaryMenu",
  "src.ui.LeaguePC",
  "src.ui.Diploma",
  "src.ui.DexEntryMenu",
}

-- The title screen, and the row its copyright line sits on.  `TitleState`
-- draws that line at y = 136 (drawCopyright, called with 136 on every frame
-- of the Red layout), so row 17 is the copyright and nothing else.
Matte.TITLE = "src.ui.TitleState"
Matte.GROUND_H = 136

function Matte.new(context)
  local self = {}
  local patched = {}

  -- The colour to paint, or nil for "there is nothing to do here".  Three
  -- ways to answer nil, and each of them is a whole build that pays nothing:
  -- no theme, LIGHT, or a mode that discards true-colour marks anyway.
  local function matteColour()
    local theme = context.theme
    if type(theme) ~= "table" or type(theme.read) ~= "function" then
      return nil
    end
    if theme.read() == "light" then return nil end
    local PaletteFX = require("src.render.PaletteFX")
    if type(PaletteFX.honorsTrueColor) == "function"
        and not PaletteFX.honorsTrueColor() then
      return nil
    end
    local colour = theme.matte()
    if type(colour) ~= "table" or #colour < 3 then return nil end
    return colour
  end

  -- Pass 1: draw, and collect the rectangles instead of marking them.
  local function record(base, state, ...)
    local PaletteFX = require("src.render.PaletteFX")
    local real = PaletteFX.markTrueColor
    local seen = {}
    PaletteFX.markTrueColor = function(x, y, w, h)
      if type(w) == "number" and type(h) == "number" and w > 0 and h > 0 then
        seen[#seen + 1] = { x = x or 0, y = y or 0, w = w, h = h }
      end
    end
    local ok, problem = pcall(base, state, ...)
    PaletteFX.markTrueColor = real
    if not ok then return nil, problem end
    return seen
  end

  local function paint(colour, rect)
    love.graphics.setColor(colour[1] / 255, colour[2] / 255,
                           colour[3] / 255, 1)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
    love.graphics.setColor(1, 1, 1, 1)
  end

  function self.wrap(base)
    return function(state, ...)
      local colour = matteColour()
      if not colour then return base(state, ...) end

      local rects, problem = record(base, state, ...)
      if not rects then
        -- pass 1 raised part way through: the frame is half drawn, so draw it
        -- again plainly rather than leaving it, and let the screen's own error
        -- surface the way it would have without this wrapper
        context.mod.log:warn("matte stood down: %s", tostring(problem))
        return base(state, ...)
      end
      if not rects[1] then return end     -- nothing marked; pass 1 IS the frame

      for _, rect in ipairs(rects) do paint(colour, rect) end
      return base(state, ...)
    end
  end

  -- DARK, and nothing else -- unlike the matte above this is not a
  -- true-colour repair, so the display mode does not come into it.
  local function darkGround()
    local theme = context.theme
    if type(theme) ~= "table" or type(theme.read) ~= "function" then
      return false
    end
    return theme.read() == "dark"
  end

  -- Serve the screen's opening full-screen fill as a black page, once, and
  -- then get out of the way.
  --
  -- ALL of it, the copyright row included.  0.31.8 left that row white on the
  -- canvas and turned it over in the palette; the strip looked right and the
  -- true-colour rect over the mon spilled a row of raw white across it, which
  -- is the bar a player reported.  Raw and shaded have to be the same pixels
  -- down there, so the paper is black and the letters are inverted to suit
  -- (`lightInk` below).
  --
  -- And the ink of anything the screen draws with `setColor(0, 0, 0)` goes
  -- white with them.  That is the copyright's text fallback and the logo's,
  -- on a build with no art for either -- black ink on a black page is not a
  -- choice anybody made, it is the page changing under a draw that predates
  -- it.
  local function withBlackPage(base, state, ...)
    local lg = love.graphics
    local real = lg.rectangle
    local realColor = lg.setColor
    local painted = false
    lg.rectangle = function(mode, x, y, w, h, ...)
      if not painted and mode == "fill"
          and x == 0 and y == 0 and w == 160 and h == 144 then
        painted = true
        lg.rectangle = real
        realColor(0, 0, 0, 1)
        real("fill", 0, 0, 160, 144)
        -- (1,1,1,1) is what the screen left set before its fill and what the
        -- logo draw on the next line expects to find.
        realColor(1, 1, 1, 1)
        return
      end
      return real(mode, x, y, w, h, ...)
    end
    lg.setColor = function(r, g, b, a, ...)
      if r == 0 and g == 0 and b == 0 and (a == nil or a == 1) then
        return realColor(1, 1, 1, a or 1)
      end
      return realColor(r, g, b, a, ...)
    end
    -- and the one draw whose pad could not be baked where it is drawn from
    local realDraw = lg.draw
    local ball, ballQuad = state.__gen1WildBall, state.ballQuad
    if ball and ballQuad then
      lg.draw = function(image, quad, x, y, ...)
        if quad == ballQuad and type(x) == "number" and type(y) == "number" then
          return realDraw(ball, x - 1, y - 1)
        end
        return realDraw(image, quad, x, y, ...)
      end
    end
    local ok, problem = pcall(base, state, ...)
    lg.rectangle = real
    lg.setColor = realColor
    lg.draw = realDraw
    return ok, problem, painted
  end

  -- ------- and the white inside the art
  --
  -- Pinning colour 0 to black takes the paper out of the logo and the ribbon,
  -- which is what a black ground needs -- and it takes the WHITE OUT OF THE
  -- ART with it, because the field the logo is printed on and the highlights
  -- inside its letters are the same shade.  A palette cannot tell them apart.
  --
  -- 0.31.2 keyed the paper that was CONNECTED TO THE BORDER and left every
  -- enclosed pixel alone, on the theory that a highlight inside a letter is
  -- not reachable from the edge.  For this logo that theory is simply false:
  -- POKeMON is grey letter faces inside a black outline on white, and of its
  -- 4381 near-white pixels every single one is border-connected.  The flood
  -- took all of them, which is why the player kept saying the logo had no
  -- white in it.  It had none to keep.
  --
  -- What the player asked for is the ITEM ICONS' treatment, by name, and the
  -- icons do not key paper -- they GROW it.  `Gen1ModernBag/icons.lua`
  -- dilates the line work by a pixel, floods the outside of the grown shape,
  -- and paints everything the flood could not reach opaque white: the art
  -- keeps paper of its own SHAPE, a sticker rather than a box.  That is the
  -- pad, and the same three steps give the logo its white back, put a white
  -- edge round the ribbon's words instead of a scatter of specks in their
  -- counters, and outline the title mon and the figure.
  --
  -- The only thing that differs per image is what counts as line work:
  --
  --   * the logo and the ribbon are printed ON paper -- opaque everywhere,
  --     near-white where the paper is -- so the ink is what is NOT paper.
  --   * the mon and the figure are sprites on transparency, so the ink is
  --     every opaque pixel and the pad is a one-pixel white outline.
  --
  -- One pixel of growth, for the icons' reason: two swells a shape until it
  -- fills the space it was cut out of, which is the box this is here to stop
  -- being.
  local PAD = 1

  local function paper(id, x, y)
    local r, g, b, a = id:getPixel(x, y)
    return a > 0 and r > 0.83 and g > 0.83 and b > 0.83
  end

  -- ------- one sheet, several pictures
  --
  -- The figure is a SHEET the title draws in pieces: three full-width slices
  -- with the POKe BALL tucked into the gap at (0,16).  A halo grown across
  -- the whole sheet would grow across that boundary too -- a white pixel off
  -- the ball's edge that belongs to the trainer, and lands on screen nowhere
  -- near him.
  --
  -- So the bake runs once per PIECE, inside that piece's rectangle, with the
  -- flood starting at the rectangle's own border.  Pieces that are contiguous
  -- when they land (the figure's slices are) grow no halo along the seam,
  -- because the pixel across it is ink and ink is never repapered.
  local function wholeOf(id)
    local w, h = id:getDimensions()
    return { { x = 0, y = 0, w = w, h = h } }
  end

  -- Grow, flood, keep what the flood could not reach.  In place, on an
  -- ImageData the caller owns.
  local function stickerRect(id, onPaper, rect)
    local w, h = rect.w, rect.h
    local x0, y0 = rect.x, rect.y
    if w <= 0 or h <= 0 then return false end

    local ink = {}
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local _, _, _, a = id:getPixel(x0 + x, y0 + y)
        if a > 0 and not (onPaper and paper(id, x0 + x, y0 + y)) then
          ink[y * w + x] = true
        end
      end
    end
    if not next(ink) then return false end

    -- 1. grow the line work by a pixel in all eight directions.  This is the
    -- sticker's edge and it is also what CLOSES an outline that never had to
    -- be closed on white paper; a bare flood leaks out through the gaps.
    local grown = {}
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        if ink[y * w + x] then
          for dy = -1, 1 do
            for dx = -1, 1 do
              local nx, ny = x + dx * PAD, y + dy * PAD
              if nx >= 0 and ny >= 0 and nx < w and ny < h then
                grown[ny * w + nx] = true
              end
            end
          end
        end
      end
    end

    -- 2. flood the outside of the grown shape in from the border
    local queue, head, outside = {}, 1, {}
    local function push(x, y)
      if x < 0 or y < 0 or x >= w or y >= h then return end
      local key = y * w + x
      if outside[key] or grown[key] then return end
      outside[key] = true
      queue[#queue + 1] = key
    end
    for x = 0, w - 1 do push(x, 0); push(x, h - 1) end
    for y = 0, h - 1 do push(0, y); push(w - 1, y) end
    while head <= #queue do
      local key = queue[head]; head = head + 1
      local x, y = key % w, math.floor(key / w)
      push(x - 1, y); push(x + 1, y); push(x, y - 1); push(x, y + 1)
    end

    -- 3. the ink is the picture, the outside is the page, and everything
    -- between them is the paper this art is printed on.
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local key = y * w + x
        if not ink[key] then
          if outside[key] then
            id:setPixel(x0 + x, y0 + y, 0, 0, 0, 0)
          else
            id:setPixel(x0 + x, y0 + y, 1, 1, 1, 1)
          end
        end
      end
    end
    return true
  end

  local function sticker(id, onPaper, rects)
    local any = false
    for _, rect in ipairs(rects or wholeOf(id)) do
      if stickerRect(id, onPaper, rect) then any = true end
    end
    return any
  end

  -- ------- reading back art this bundle did not load
  --
  -- The figure is not ours, and on this cart it is not the importer's either:
  -- Wild Green swaps `state.player` for its green derived copy, and Crystal
  -- Animated Sprites swaps the mon, both of them AFTER this bundle would have
  -- had a chance to look at a path.  0.31.8 baked the PATH and installed the
  -- result, which put the red figure back on a green cart -- "our trainer
  -- sprite doesn't have color now", and quite right.
  --
  -- So the pad is baked from the PICTURE, whoever put it there.  LOVE 11 does
  -- not keep an Image's ImageData, so it comes back off the GPU: draw the
  -- image to a canvas of its own size under "replace" -- which writes the
  -- source RGBA instead of blending it -- and read that canvas.  Once per
  -- image and cached weakly, so a mod that swaps the art gets one bake per
  -- picture rather than one a frame.
  --
  -- Everything the engine has set is put back: canvas, shader, blend mode,
  -- colour, scissor and transform.  This runs in the middle of the screen's
  -- own draw, and a draw that returns the pipeline in a different state than
  -- it found it is a bug in every frame after this one.
  local function dataOf(image)
    local lg = love.graphics
    if type(lg.newCanvas) ~= "function" then return nil end
    local w, h = image:getDimensions()
    if not (w and h and w > 0 and h > 0) then return nil end
    local canvas = lg.newCanvas(w, h)
    local wasCanvas = lg.getCanvas and lg.getCanvas() or nil
    local wasShader = lg.getShader and lg.getShader() or nil
    local sx, sy, sw, sh
    if lg.getScissor then sx, sy, sw, sh = lg.getScissor() end
    local r, g, b, a = 1, 1, 1, 1
    if lg.getColor then r, g, b, a = lg.getColor() end
    if lg.push then lg.push() end
    if lg.origin then lg.origin() end
    if lg.setScissor then lg.setScissor() end
    lg.setCanvas(canvas)
    if lg.setShader then lg.setShader() end
    if lg.clear then lg.clear(0, 0, 0, 0) end
    lg.setBlendMode("replace")
    lg.setColor(1, 1, 1, 1)
    lg.draw(image, 0, 0)
    lg.setBlendMode("alpha")
    lg.setCanvas(wasCanvas)
    if lg.setShader then lg.setShader(wasShader) end
    if lg.setScissor then
      if sx then lg.setScissor(sx, sy, sw, sh) else lg.setScissor() end
    end
    if lg.pop then lg.pop() end
    lg.setColor(r, g, b, a)
    return canvas:newImageData()
  end

  -- Weak on the key, so an image a mod stops using is not kept alive by this,
  -- and `ours` so a bake is never baked again -- the swap puts our copy on the
  -- state, and on a build where nobody swaps it back that copy is what the
  -- next frame would hand us.
  local bakes = setmetatable({}, { __mode = "k" })
  local ours = setmetatable({}, { __mode = "k" })

  local function bakedOf(image, bake)
    if not image or ours[image] then return nil end
    if bakes[image] ~= nil then return bakes[image] or nil end
    bakes[image] = false
    pcall(function()
      local id = dataOf(image)
      if not id then return end
      if bake(id) then
        local out = love.graphics.newImage(id)
        pcall(out.setFilter, out, "nearest", "nearest")
        ours[out] = true
        bakes[image] = out
      end
    end)
    return bakes[image] or nil
  end

  -- ------- the one that is words rather than a picture
  --
  -- The ribbon is not stickered, and the difference is the spacing.  The logo
  -- is one connected mass of line work, so a pixel of pad round it is an
  -- OUTLINE -- 417 pixels of white on a 128x56 sheet.  The ribbon is eight
  -- pixels of letters with a pixel between them: pad every letter and the
  -- pads meet, and what comes out is a white plate with words on it, which is
  -- the "white box behind wild green version" this whole line of work started
  -- from.
  --
  -- So its paper goes, all of it, counters included.  Keying only what the
  -- border could reach left the white shut inside an `e` or an `o` behind as
  -- a scatter of specks through the words.
  local function keyPaper(id)
    local w, h = id:getDimensions()
    local any = false
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        if paper(id, x, y) then id:setPixel(x, y, 0, 0, 0, 0); any = true end
      end
    end
    return any
  end

  -- ------- the pieces a sheet is drawn in
  --
  -- The figure's three slices and the POKe BALL in the gap between them.
  -- Taken from the quads the state built rather than restated here, because
  -- they are sized from the sheet and a sprite pack may ship a taller one.
  local function figureRects(state)
    return function(id)
      local w, h = id:getDimensions()
      local out, seen = {}, {}
      local function add(quad)
        if not quad or type(quad.getViewport) ~= "function" then return end
        local ok, qx, qy, qw, qh = pcall(quad.getViewport, quad)
        if not ok then return end
        local key = table.concat({ qx, qy, qw, qh }, ",")
        if seen[key] then return end
        seen[key] = true
        out[#out + 1] = { x = qx, y = qy, w = qw, h = qh }
      end
      for _, part in ipairs(state.playerQuads or {}) do add(part[1]) end
      add(state.ballQuad)
      if not out[1] then out[1] = { x = 0, y = 0, w = w, h = h } end
      return out
    end
  end

  -- ------- the POKe BALL, which has nowhere on the sheet to grow into
  --
  -- The ball is an eight-by-eight cell at (0,16) tucked into the gap the
  -- trainer's middle slice leaves, and the draw throws it at a y of its own.
  -- Every pixel around it inside the sheet belongs to the trainer, so a pad
  -- baked in place has nowhere to go and the ball came out with no white
  -- round it at all.
  --
  -- So it is cut out instead: the cell copied into an image a pixel larger on
  -- every side, stickered there, and substituted for that one draw at
  -- (x - 1, y - 1) so it lands exactly where the unpadded ball would have.
  local balls = setmetatable({}, { __mode = "k" })

  local function ballPad(image, quad)
    if not (image and quad and type(quad.getViewport) == "function") then
      return nil
    end
    if balls[image] ~= nil then return balls[image] or nil end
    balls[image] = false
    local okQ, qx, qy, qw, qh = pcall(quad.getViewport, quad)
    if not (okQ and qw and qh and qw > 0 and qh > 0) then return nil end
    local out
    pcall(function()
      local id = dataOf(image)
      if not id then return end
      local cell = love.image.newImageData(qw + 2, qh + 2)
      cell:paste(id, 1, 1, qx, qy, qw, qh)
      if not sticker(cell, false, nil) then return end
      out = love.graphics.newImage(cell)
      pcall(out.setFilter, out, "nearest", "nearest")
      ours[out] = true
    end)
    balls[image] = out or false
    return out
  end

  -- ------- the copyright, made light
  --
  -- Its row is black like the rest of the ground now, so its letters have to
  -- be light or they are not letters.
  --
  -- 0.31.10 turned every opaque pixel over, which is right for art drawn dark
  -- on nothing and wrong for art drawn light on a dark plate: that one came
  -- out as white blocks with the letters punched out of them, which is what
  -- happened to GAME FREAK inc. while the date beside it -- a different file,
  -- stored the other way -- came out fine.
  --
  -- So the paper is identified rather than assumed.  The corner says whether
  -- there is one: transparent there and every opaque pixel is line work, so
  -- it all goes white; opaque there and that shade is the plate, so pixels
  -- like it are keyed out and the rest go white.  Four ways of storing the
  -- same two-tone line of text, one thing on screen.
  local function lightInk(id)
    local w, h = id:getDimensions()
    if w <= 0 or h <= 0 then return false end

    -- A plate is opaque EVERYWHERE -- that is what makes it a plate.  One
    -- transparent pixel anywhere and there is no paper here, only line work,
    -- and all of it is ink.  (Sampling a corner instead is what the first
    -- attempt at this did, and the corner of a line of text is as likely to
    -- be a letter as anything else.)
    local light, dark, holes = 0, 0, false
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local r, g, b, a = id:getPixel(x, y)
        if a <= 0 then
          holes = true
        elseif (r + g + b) / 3 > 0.5 then
          light = light + 1
        else
          dark = dark + 1
        end
      end
    end
    if light + dark == 0 then return false end

    -- On a plate the paper outnumbers the letters, so the majority is the
    -- paper and it is keyed out; the letters go white.  With no plate every
    -- opaque pixel is a letter and goes white whatever shade it was drawn.
    local paperIsLight = nil
    if not holes then paperIsLight = light > dark end
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local r, g, b, a = id:getPixel(x, y)
        if a > 0 then
          if paperIsLight ~= nil
              and (((r + g + b) / 3 > 0.5) == paperIsLight) then
            id:setPixel(x, y, 0, 0, 0, 0)
          else
            id:setPixel(x, y, 1, 1, 1, a)
          end
        end
      end
    end
    return true
  end

  -- The art the title draws on its own page.  Every one of them is read back
  -- off the picture the state is holding, so whatever a mod has swapped in is
  -- what gets the treatment.
  local function keyTitleArt(state)
    if not (love.image and love.image.newImageData) then return nil end
    local put = {}
    local function swap(field, bake)
      local image = state[field]
      if not image then return end
      local baked = bakedOf(image, bake)
      if not baked then return end
      put[field] = image
      state[field] = baked
    end

    swap("logo", function(id) return sticker(id, true, nil) end)
    swap("version", keyPaper)
    -- the copyright's three, so its letters read on a black row
    swap("copyImg", lightInk)
    swap("nineImg", lightInk)
    swap("gfInc", lightInk)

    -- The figure, on transparency: a one-pixel white outline round the
    -- trainer.  Not in OG RED, where the draw rebuilds the image from
    -- `playerPath` through the OBP tables and never looks at this field --
    -- that mode keeps the figure it always had.
    local obp = false
    pcall(function()
      local PaletteFX = require("src.render.PaletteFX")
      obp = type(PaletteFX.usesSpriteObp) == "function"
        and PaletteFX.usesSpriteObp() or false
    end)
    if not obp then
      local rects = figureRects(state)
      swap("player", function(id) return sticker(id, false, rects(id)) end)
      if put.player then
        state.__gen1WildBall = ballPad(put.player, state.ballQuad)
      end
    end
    if not next(put) then return nil end
    return put
  end

  -- ------- and the mon, which is NOT ours to substitute
  --
  -- 0.31.10 stickered whatever `currentSprite` handed back.  With Crystal
  -- Animated Sprites installed that is not one picture of one POKeMON, it is
  -- the animation SHEET, and the mod that owns it draws a frame out of it.
  -- Handing back a same-size copy hands back the whole sheet -- which the
  -- title then drew whole, at `x = 40 + (56 - w) / 2` and `y = 136 - h` off a
  -- sheet's dimensions: a CHARMANDER over half the screen with the other
  -- frames beside it, on top of the logo and the ribbon.
  --
  -- There is no version of this that is this bundle's to get right.  The mon
  -- belongs to whoever is animating it, and it keeps its own art.
  function self.wrapTitle(base)
    return function(state, ...)
      if type(state) == "table" then state.__gen1WildDarkGround = nil end
      -- With the menu open there is no art on this screen and the frame is an
      -- ordinary page; the theme reverses it, and a black ground would reverse
      -- to a white one.
      if type(state) ~= "table" or state.menuOpen or not darkGround() then
        return base(state, ...)
      end
      local put = keyTitleArt(state)
      state.__gen1WildKeyedArt = put and true or nil
      -- The ring round the art stops above the copyright: this screen is
      -- black to row 135 and white from 136, and the mon's box ends on
      -- exactly that line.  Set every frame, taken with the rects at
      -- `render.zones`, so no other screen carries it.
      local theme = context.theme
      if type(theme) == "table" and type(theme.clipArt) == "function" then
        pcall(theme.clipArt, Matte.GROUND_H)
      end
      local ok, problem, painted = withBlackPage(base, state, ...)
      if put then
        for field, image in pairs(put) do state[field] = image end
      end
      -- Wild Green marks the figure BEFORE this draw runs, because the draw
      -- reads `self.player` at its top -- and the draw's opening full-screen
      -- fill wipes the skirt that mark painted.  Laying the rings down again
      -- now costs nothing (they are outside the art by construction) and is
      -- the difference between the figure keeping its hairline and not.
      if ok and type(theme) == "table"
          and type(theme.paintSkirts) == "function" then
        pcall(theme.paintSkirts)
      end
      if not ok then
        -- the screen raised part way through with the shim in place: it is
        -- already back, so let the frame be drawn plainly and the screen's own
        -- error surface the way it would have without this wrapper
        context.mod.log:warn("title ground stood down: %s", tostring(problem))
        return base(state, ...)
      end
      state.__gen1WildDarkGround = painted or nil
    end
  end

  function self.installTitle()
    local ok, class = pcall(require, Matte.TITLE)
    if ok and type(class) == "table" and type(class.draw) == "function"
        and not patched[class] then
      patched[class] = true
      class.draw = self.wrapTitle(class.draw)
    end
  end

  function self.install()
    for _, path in ipairs(Matte.SCREENS) do
      local ok, class = pcall(require, path)
      if ok and type(class) == "table" and type(class.draw) == "function"
          and not patched[class] then
        patched[class] = true
        class.draw = self.wrap(class.draw)
      end
    end
  end

  return self
end

return Matte
