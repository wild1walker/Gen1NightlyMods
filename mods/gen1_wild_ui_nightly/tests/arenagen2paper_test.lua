-- What a backdrop takes away from Gold's battle, and how it is given back.
--
-- Gold draws its battle against PAPER: `drawPanel` opens with `Chrome.clear()`
-- and everything after it is drawn knowing that whatever it does not paint is
-- white.  Put a picture there instead and three of the cart's own assumptions
-- become visible bugs, all three of which were reported from the Crystal cart:
--
--   * every HUD string paints its own paper cell first, because a tilemap
--     cell is opaque -- so the name, the level and the HP numbers each
--     arrived as a white block hugging its own text.
--   * the HP and exp bars are opaque 2bpp sheets, colour 0 and all, so each
--     bar arrived as a white slab with a bar drawn on it.
--   * the pics have holes in them, because the extractor's matte leaks
--     wherever the art runs off the edge of its own frame -- so you could see
--     the arena through the player's shirt.
--
-- The first fix put PLATES behind the HUD blocks and was rejected on sight:
-- "there shouldn't be the big black or white box behind all that stuff.  Look
-- gen 1 looks much cleaner."  So the assertions here are about paper being
-- TAKEN AWAY rather than added -- and the one place it is still added, inside
-- the pic, is asserted to be the pic's own shape and not a rectangle.
--
-- The pic measurement is exercised for real rather than stubbed -- the
-- graphics stub below carries enough canvas for `readPic` to read an
-- ImageData back -- because which pixels are a hole is the half of that fix
-- with somewhere to go wrong.
--
-- Run:  luajit tests/arenagen2paper_test.lua

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

local function load_(path, ...)
  local handle = assert(io.open(path, "r"), path .. " is missing")
  local source = handle:read("*a")
  handle:close()
  return assert(load(source, "@" .. path))(...)
end

-- ------------------------------------------------------------- the harness

-- One synthetic pic: a hollow 16x16 ring -- ink round a 12x12 edge with a
-- 10x10 transparent hole inside it, and nothing but transparency outside.
-- The hole is what the paper is for; the outside is what it must not touch.
local PIC_W, PIC_H = 16, 16
local function ringPixel(x, y)
  local edge = x == 2 or x == 13 or y == 2 or y == 13
  local inside = x >= 2 and x <= 13 and y >= 2 and y <= 13
  if not inside then return 0, 0, 0, 0 end
  if edge then return 0, 0, 0, 1 end
  return 0, 0, 0, 0            -- the hollow the paper is for
end

local IMAGE = {
  getDimensions = function() return PIC_W, PIC_H end,
}

local IMAGE_DATA = {
  getDimensions = function() return PIC_W, PIC_H end,
  getPixel = function(_, x, y) return ringPixel(x, y) end,
}

local fills, draws, keyed
_G.love = _G.love or {}

-- The ImageData the paper mask is built into, so a case can ask which pixels
-- it actually painted.
local function newImageData(w, h)
  local data = { width = w, height = h, pixels = {}, filled = 0 }
  data.setPixel = function(self, x, y, r, g, b, a)
    self.pixels[y * self.width + x] = { r, g, b, a }
    if (a or 0) > 0.5 then self.filled = self.filled + 1 end
  end
  data.at = function(self, x, y) return self.pixels[y * self.width + x] end
  return data
end
love.image = { newImageData = newImageData }

love.graphics = {
  rectangle = function(mode, x, y, w, h)
    fills[#fills + 1] = { kind = "rect", x = x, y = y, w = w, h = h }
  end,
  setColor = function() end,
  getColor = function() return 1, 1, 1, 1 end,
  push = function() end,
  pop = function() end,
  origin = function() end,
  setScissor = function() end,
  setShader = function() end,
  setBlendMode = function() end,
  getCanvas = function() return nil end,
  setCanvas = function() end,
  clear = function() end,
  newQuad = function(x, y, w, h) return { x = x, y = y, w = w, h = h } end,
  -- Two callers, told apart by what they hand over: a backdrop arrives as a
  -- path, the pic's paper mask as the ImageData it was just painted into.
  newImage = function(source)
    if type(source) == "table" and source.pixels then
      return { mask = source, setFilter = function() end,
               getDimensions = function() return source.width, source.height end }
    end
    return { getDimensions = function() return 160, 144 end,
             setFilter = function() end, getWidth = function() return 160 end,
             getHeight = function() return 144 end }
  end,
  newCanvas = function()
    return { newImageData = function() return IMAGE_DATA end }
  end,
  draw = function(image, a, b, c, d)
    draws[#draws + 1] = { image = image, a = a, b = b, c = c, d = d }
  end,
}

package.loaded["src.core.GameVersion"] = {
  generation = function() return 2 end,
  get = function() return "gold" end,
  isYellow = function() return false end,
}

-- Gold's palette machinery, reduced to the two binds the HUD tiles go
-- through.  Which of the two a tile was drawn under is the whole assertion:
-- `useKeyed` is the shader that makes colour 0 transparent.
local GbcPalette = {
  use = function() keyed[#keyed + 1] = "opaque"; return true end,
  useKeyed = function() keyed[#keyed + 1] = "keyed"; return true end,
}
package.loaded["src.render.GbcPalette"] = GbcPalette

-- Gold's Chrome.  `printThrough` fills its paper cell the way the real one
-- does -- through `love.graphics.rectangle`, which is exactly what the arm
-- swallows -- and then "draws" its glyphs.
local Chrome
Chrome = {
  DEFAULT_BOX_PALETTE = {
    { 255, 255, 255 }, { 255, 255, 255 }, { 255, 255, 255 }, { 0, 0, 0 },
  },
  clear = function() fills[#fills + 1] = { kind = "clear" } end,
  paletteFill = function(x, y, w, h)
    fills[#fills + 1] = { kind = "paper", x = x, y = y, w = w, h = h }
  end,
  printThrough = function(text, tx, ty)
    love.graphics.rectangle("fill", tx * 8, ty * 8, #tostring(text) * 8, 8)
    return #tostring(text) * 8
  end,
}
Chrome.printRightThrough = function(text, txEnd, ty)
  return Chrome.printThrough(text, txEnd, ty)
end
package.loaded["src.ui.gen2.Chrome"] = Chrome

-- The HUD's tiles.  Only the two things the arm reaches for: a tile drawn
-- with a palette (the bars) and one drawn with none (the border).
local BattleHud = {}
BattleHud.drawTile = function(self, key, first, tile, tx, ty, colors)
  fills[#fills + 1] = { kind = "tile", colors = colors }
  GbcPalette.use(colors or { { 255, 255, 255 } })
  return true
end
package.loaded["src.ui.gen2.BattleHud"] = BattleHud

-- Gold's BattleState, reduced to the methods the arm wraps and the state they
-- read.  `src.battle.BattleState` is the name the mod requires: on a Gen 2
-- boot the loader answers it with a write-through facade onto Gold's class,
-- so patching this table is patching Gold's.
local drawn
local BattleState = {}
BattleState.drawPanel = function(self)
  drawn[#drawn + 1] = "panel"
  Chrome.clear()
  -- drawHud's own order: the enemy HUD, then both pics, then the player's.
  self:drawEnemyHud()
  if self.drawsPics ~= false then
    self:drawPic({ species = "X" }, false)
    self:drawPic({ species = "X" }, true)
  end
  self:drawPlayerHud()
  -- The bottom strip, which is NOT the HUD: its box really does have paper.
  Chrome.printThrough("HELLO", 1, 14)
end
BattleState.drawEnemyHud = function(self)
  drawn[#drawn + 1] = "enemy"
  Chrome.printThrough("RATTATA", 1, 0)
  BattleHud.drawTile(BattleHud, "hpBar", 0x60, 0x62, 2, 2,
                     { { 255, 255, 255 }, { 0, 255, 0 }, { 0, 128, 0 },
                       { 0, 0, 0 } })
  BattleHud.drawTile(BattleHud, "enemyBorder", 0x6c, 0x6d, 1, 2)
end
BattleState.drawPlayerHud = function(self)
  drawn[#drawn + 1] = "player"
  Chrome.printRightThrough("18/18", 18, 10)
end
BattleState.drawPic = function(self, mon, back)
  drawn[#drawn + 1] = "pic"
  -- the plain blit `drawPic` ends in: image, x, y, rotation, scale, scale
  love.graphics.draw(IMAGE, 40, 48, 0, 2, 2)
end
package.loaded["src.battle.BattleState"] = BattleState
package.loaded["src.battle.WideBattle"] = nil

local mod = {
  id = "gen1_wild_ui_nightly",
  path = "modules/Gen1Arena",
  exports = {},
  stored = {},
  hooked = {},
  events_on = {},
  logged = {},
}
mod.options = {
  define = function(_, rows) mod.rows = rows end,
  get = function(_, key) return mod.stored[key] end,
  set = function(_, key, value) mod.stored[key] = value end,
}
mod.log = {}
for _, level in ipairs({ "info", "warn", "error", "debug" }) do
  mod.log[level] = function(_, format, ...)
    mod.logged[#mod.logged + 1] = select("#", ...) > 0
      and tostring(format):format(...) or tostring(format)
  end
end
mod.hooks = { wrap = function(_, name, fn) mod.hooked[name] = fn end }
mod.events = { on = function(_, name, fn) mod.events_on[name] = fn end }
mod.assets = { path = function(_, p) return p end }
mod.storage = { writeBytes = function() return true end }
mod.content = {}

load_("modules/Gen1Arena/main.lua", mod)
assert(type(mod.events_on["game.ready"]) == "function", "no game.ready")
mod.events_on["game.ready"]({ game = {} })

ok(BattleState.__gen1arena, "the Gold arm installed")

-- ---------------------------------------------------------------- the rows

do
  io.write("the option row\n")
  local keys = {}
  for _, row in ipairs(mod.rows or {}) do keys[row.key] = row end
  ok(keys.hud_clear, "CLEAR HUD is offered on Gold")
  eq(keys.hud_clear and keys.hud_clear.default, true, "and defaults on")
  ok(not keys.hud_paper, "and the plate's row is gone with the plates")
  ok(keys.pic_paper, "MON PAPER is there on both generations")
end

-- ------------------------------------------------------------- the frames

-- A battle screen as the engine hands one over.  Whether a backdrop is found
-- for it is what `consumed` turns on.
local function screen(opts)
  opts = opts or {}
  local self = {
    battle = opts.battle ~= false and { wild = true } or nil,
    drawsPics = opts.drawsPics,
  }
  -- The class behind it, so `self:drawEnemyHud()` reaches the wrapped method
  -- the way it does on a live instance.
  return setmetatable(self, { __index = BattleState })
end

local function frame(self)
  fills, draws, drawn, keyed = {}, {}, {}, {}
  BattleState.drawPanel(self)
end

local function kinds(want)
  local out = {}
  for _, f in ipairs(fills) do
    if f.kind == want then out[#out + 1] = f end
  end
  return out
end

-- Whether a backdrop was found for this frame is the one thing everything
-- below turns on, and it is not a flag a test can set: the arm decides it by
-- taking the engine's `Chrome.clear` call.  So it is READ instead, off the
-- mark the arm leaves for UI THEME.
local function tookTheField(self)
  return self.gen1wildArenaField == true
end

do
  io.write("no backdrop, nothing touched\n")
  mod.stored.enabled = false
  local self = screen()
  frame(self)
  eq(tookTheField(self), false, "the field is the cart's")
  eq(#kinds("rect"), 3,
     "so every HUD string keeps its own paper cell -- against the cart's "
     .. "white field it is invisible, and taking it away would be a change "
     .. "for its own sake")
  eq(keyed[1], "opaque", "and the bars keep the shader the cart drew them on")
  mod.stored.enabled = nil
end

do
  io.write("a backdrop, and the HUD's paper goes\n")
  local self = screen({ drawsPics = false })
  frame(self)
  ok(tookTheField(self),
     "the arm took the field, which is what everything below is about")

  eq(#kinds("paper"), 0,
     "no plate behind either HUD: the big box behind all that stuff is what "
     .. "was reported, not what was missing")

  local rects = kinds("rect")
  eq(#rects, 1, "one paper cell survives the frame")
  eq(rects[1] and rects[1].y, 14 * 8,
     "and it is the bottom strip's, which is a real box -- the two HUD "
     .. "strings drew their glyphs onto the picture with nothing behind them")

  eq(keyed[1], "keyed",
     "the HP bar's tiles are bound through the shader that keys colour 0 "
     .. "away, so the bar loses its white slab and keeps its two hues")
  eq(keyed[2], "keyed", "and so is the border")
end

do
  io.write("the border takes the theme's ink\n")
  frame(screen({ drawsPics = false }))
  local tiles = kinds("tile")
  eq(#tiles, 2, "both tiles drew")
  ok(tiles[1] and tiles[1].colors and tiles[1].colors[2][2] == 255,
     "a tile the cart coloured keeps the cart's colours")
  ok(tiles[2] and tiles[2].colors ~= nil,
     "and a tile the cart drew with no palette at all is given one, or it "
     .. "comes out flat black on a dark page")
  eq(tiles[2] and tiles[2].colors and tiles[2].colors[4][1], 0,
     "in the live box palette's ink")
end

do
  io.write("CLEAR HUD off\n")
  mod.stored.hud_clear = false
  frame(screen({ drawsPics = false }))
  eq(#kinds("rect"), 3, "the cart's own white blocks come back")
  eq(keyed[1], "opaque", "and its own shader with them")
  mod.stored.hud_clear = nil
end

-- ---------------------------------------------------------- under the pics

local function picBlits()
  local out = {}
  for _, d in ipairs(draws) do
    if d.a == 40 and d.b == 48 then out[#out + 1] = d end
  end
  return out
end

do
  io.write("paper inside a pic\n")
  local outside = love.graphics.draw
  frame(screen())

  local blits = picBlits()
  eq(#blits, 4, "two pics, and each one drawn twice: its paper, then it")
  ok(blits[1] and blits[1].image and blits[1].image.mask,
     "the paper goes down first, or it would cover the pic")
  eq(blits[2] and blits[2].image, IMAGE, "and the pic itself second")
  eq(blits[2] and blits[2].d, 2,
     "at the scale the ENGINE passed, not one re-derived -- and the paper "
     .. "takes the same one")
  eq(blits[1] and blits[1].d, 2, "so the two land on each other")

  eq(#kinds("paper"), 0,
     "and it is not a fill: a rectangle is the wrong shape for a mon, which "
     .. "is what the white box behind the pics was")

  eq(love.graphics.draw, outside,
     "the draw is put back: the shim is for the length of one drawPic and "
     .. "no longer")
end

do
  io.write("MON PAPER off\n")
  mod.stored.pic_paper = false
  frame(screen())
  eq(#picBlits(), 2, "one draw per pic, and it is the pic")
  mod.stored.pic_paper = nil
end

-- ----------------------------------------------------------- the pic's shape

do
  io.write("the paper's shape\n")
  local shape = mod.exports.picPaperImage
  ok(type(shape) == "function", "the shaping is exposed")
  if type(shape) == "function" then
    local paper = shape(IMAGE)
    ok(paper ~= nil and paper ~= false, "a pic with a hole in it gets paper")
    local mask = paper and paper.mask
    if mask then
      eq(mask.width, PIC_W, "the mask is the pic's own size, so it can be "
         .. "drawn with the pic's own coordinates")
      eq(mask.height, PIC_H, "on both axes")
      eq(mask.filled, 10 * 10,
         "and it is exactly the hole: ten by ten inside a twelve-wide ring")
      ok(mask:at(7, 7) ~= nil, "the middle of the hole is paper")
      eq(mask:at(2, 2), nil, "the ink is not")
      eq(mask:at(0, 0), nil,
         "and neither is the space around the mon, which is the picture")
    end
  end
end

do
  io.write("a pic with nothing to fill\n")
  -- A solid block: opaque throughout, so there is no hole and no paper -- and
  -- a mod's full-colour replacement art, which has too many shades to be a
  -- 2bpp pic, is refused for the same reason the Gen 1 arm refuses it.
  local solid = { getDimensions = function() return 8, 8 end }
  local realCanvas = love.graphics.newCanvas
  love.graphics.newCanvas = function()
    return { newImageData = function()
      return {
        getDimensions = function() return 8, 8 end,
        getPixel = function(_, x, y) return 0, 0, 0, 1 end,
      }
    end }
  end
  eq(mod.exports.picPaperImage(solid), nil,
     "a pic with no hole in it builds no paper and costs one readback")
  love.graphics.newCanvas = realCanvas
end

io.write(("arena gen2 paper: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
