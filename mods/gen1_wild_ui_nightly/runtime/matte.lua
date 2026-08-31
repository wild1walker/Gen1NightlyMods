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

  -- Serve the screen's opening full-screen fill as a black page with a white
  -- copyright row, once, and then get out of the way.
  local function withBlackPage(base, state, ...)
    local lg = love.graphics
    local real = lg.rectangle
    local painted = false
    lg.rectangle = function(mode, x, y, w, h, ...)
      if not painted and mode == "fill"
          and x == 0 and y == 0 and w == 160 and h == 144 then
        painted = true
        lg.rectangle = real
        lg.setColor(0, 0, 0, 1)
        real("fill", 0, 0, 160, Matte.GROUND_H)
        lg.setColor(1, 1, 1, 1)
        real("fill", 0, Matte.GROUND_H, 160, 144 - Matte.GROUND_H)
        -- (1,1,1,1) is what the screen left set before its fill and what the
        -- logo draw on the next line expects to find.
        return
      end
      return real(mode, x, y, w, h, ...)
    end
    local ok, problem = pcall(base, state, ...)
    lg.rectangle = real
    return ok, problem, painted
  end

  -- ------- and the logo's own white
  --
  -- Pinning colour 0 to black takes the paper out of the logo and the ribbon,
  -- which is what a black ground needs -- and it takes the WHITE OUT OF THE
  -- ART with it, because the field the logo is printed on and the highlights
  -- inside its letters are the same shade.  A palette cannot tell them apart.
  --
  -- The art can.  This is the item icons' trick, which the player asked for by
  -- name: key the paper that is CONNECTED TO THE BORDER out to transparency
  -- and leave every enclosed pixel alone.  The field goes, so the page shows
  -- through it; the highlight inside a letter is not reachable from the edge
  -- and stays exactly the white it was drawn.
  --
  -- Then colour 0 can be white again, which is why the theme asks whether
  -- this took (`__gen1WildKeyedArt`) rather than assuming it: a build where
  -- the art cannot be read keeps the pin and keeps its flat logo, which is
  -- worse-looking and still correct.
  local keyed = {}

  local function pathOf(entry, fallback)
    if type(entry) == "table" then entry = entry.path end
    if type(entry) == "string" then return entry end
    return fallback
  end

  local function paper(id, x, y)
    local r, g, b, a = id:getPixel(x, y)
    return a > 0 and r > 0.83 and g > 0.83 and b > 0.83
  end

  -- A copy, always: Assets.imageData caches, and keying the cached data would
  -- hole the same art everywhere else it is drawn.
  local function keyedImage(path)
    if keyed[path] ~= nil then return keyed[path] or nil end
    keyed[path] = false
    local ok = pcall(function()
      local Assets = require("src.render.Assets")
      local src = Assets.imageData(path)
      local w, h = src:getDimensions()
      local id = love.image.newImageData(w, h)
      id:paste(src, 0, 0, 0, 0, w, h)

      -- Flood from every border pixel; only paper is walkable, so an
      -- enclosed highlight is never reached.
      local queue, head, seen = {}, 1, {}
      local function push(x, y)
        if x < 0 or y < 0 or x >= w or y >= h then return end
        local key = y * w + x
        if seen[key] or not paper(id, x, y) then return end
        seen[key] = true
        queue[#queue + 1] = key
      end
      for x = 0, w - 1 do push(x, 0); push(x, h - 1) end
      for y = 0, h - 1 do push(0, y); push(w - 1, y) end
      while head <= #queue do
        local key = queue[head]; head = head + 1
        local x, y = key % w, math.floor(key / w)
        id:setPixel(x, y, 0, 0, 0, 0)
        push(x - 1, y); push(x + 1, y); push(x, y - 1); push(x, y + 1)
      end
      keyed[path] = love.graphics.newImage(id)
    end)
    if not ok then keyed[path] = false end
    return keyed[path] or nil
  end

  -- The two the title prints on its own paper.  The mon and the figure are
  -- marked true colour and never went through a palette at all.
  local function keyTitleArt(state)
    if not (love.image and love.image.newImageData) then return nil end
    local title = type(state.title) == "table" and state.title or {}
    local put = {}
    local function swap(field, path)
      if not state[field] or not path then return end
      local image = keyedImage(path)
      if not image then return end
      put[field] = state[field]
      state[field] = image
    end
    swap("logo", pathOf(title.logo, "assets/logo/pokemon_logo.png"))
    swap("version", pathOf(title.versionRibbon or title.version,
                           "assets/generated/title/red_version.png"))
    if not next(put) then return nil end
    return put
  end

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
      local ok, problem, painted = withBlackPage(base, state, ...)
      if put then
        for field, image in pairs(put) do state[field] = image end
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
