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
