-- What a backdrop takes away from Gold's battle, and has to put back.
--
-- Gold draws its battle against PAPER: `drawPanel` opens with `Chrome.clear()`
-- and everything after it is drawn knowing that whatever it does not paint is
-- white.  Put a picture there instead and two of the cart's own assumptions
-- become visible bugs, both of which were reported the first time anyone
-- played a battle on the Crystal cart:
--
--   * every HUD string paints its own paper cell, because a tilemap cell is
--     opaque -- so the name, the level, the gender symbol and the HP numbers
--     each arrived as a white block hugging its own text, ragged against the
--     art.  Not a dark-mode bug: wrong in LIGHT too.
--   * the pics are drawn with colour 0 TRANSPARENT, so you could see the
--     field through the player's jacket.
--
-- So the assertions here are about WHERE paper is laid and, just as much,
-- where it is NOT: a plate on a HUD the cart has blanked, or under a pic on a
-- battle no backdrop took, is a white rectangle the cart does not have.
--
-- The pic measurement is exercised for real rather than stubbed -- the
-- graphics stub below carries enough canvas for `readPic` to read an
-- ImageData back -- because "which box" is the half of that fix with
-- somewhere to go wrong.
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

-- One synthetic pic: a hollow 16x16 ring, which is the shape `measurePic` is
-- looking for -- ink round the edge, transparent inside, few enough colours to
-- be a four-shade sprite.  Its enclosed interior is what the paper fills.
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

local fills, draws
_G.love = _G.love or {}
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
  -- A backdrop is an image like any other here: the arm only needs one to
  -- exist for `consumed` to turn on, and what it looks like is not this
  -- file's subject.
  newImage = function()
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

-- Gold's Chrome, recording the one call the paper goes through.
local Chrome = {
  DEFAULT_BOX_PALETTE = {
    { 255, 255, 255 }, { 255, 255, 255 }, { 255, 255, 255 }, { 0, 0, 0 },
  },
  clear = function() fills[#fills + 1] = { kind = "clear" } end,
  paletteFill = function(x, y, w, h)
    fills[#fills + 1] = { kind = "paper", x = x, y = y, w = w, h = h }
  end,
}
package.loaded["src.ui.gen2.Chrome"] = Chrome

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
end
BattleState.drawEnemyHud = function() drawn[#drawn + 1] = "enemy" end
BattleState.drawPlayerHud = function() drawn[#drawn + 1] = "player" end
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
  ok(keys.hud_paper, "HUD PAPER is offered on Gold")
  eq(keys.hud_paper and keys.hud_paper.default, true, "and defaults on")
  ok(keys.pic_paper, "MON PAPER is there on both generations")
end

-- ------------------------------------------------------------- the plates

-- A battle screen as the engine hands one over.  `pick` decides whether a
-- backdrop is found for it, which is what `consumed` turns on.
local function screen(opts)
  opts = opts or {}
  local self = {
    battle = opts.battle ~= false and { wild = true } or nil,
    showEnemyHud = opts.showEnemyHud ~= false,
    showPlayerHud = opts.showPlayerHud ~= false,
    anim = opts.anim,
    drawsPics = opts.drawsPics,
  }
  self.hudCleared = function(s, side)
    return opts.cleared == side
  end
  self.statusHUDVisible = function() return opts.statusHud ~= false end
  self.activeMon = function() return opts.mon ~= false and { species = "X" } or nil end
  -- The class behind it, so `self:drawEnemyHud()` reaches the wrapped method
  -- the way it does on a live instance.
  return setmetatable(self, { __index = BattleState })
end

local function paperFills()
  local out = {}
  for _, f in ipairs(fills) do
    if f.kind == "paper" then out[#out + 1] = f end
  end
  return out
end

-- The pics draw BETWEEN the two HUDs, so paper arrives interleaved.  Told
-- apart by what it is the size of rather than by when it came: a plate is a
-- HUD block, a pic's paper is the measured box.
local PLATES = { [88] = "enemy", [80] = "player" }

local function plates()
  local out = {}
  for _, f in ipairs(paperFills()) do
    local side = PLATES[f.w]
    if side and f.h ~= 24 then out[side] = f end
  end
  return out
end

-- A pic's paper is a plain white rectangle, not a palette fill: it is the
-- shade the MON's own colour 0 is, inside the art, rather than the paper a
-- box would have had.
local function picPapers()
  local out = {}
  for _, f in ipairs(fills) do
    if f.kind == "rect" and f.w == 12 * 2 and f.h == 12 * 2 then
      out[#out + 1] = f
    end
  end
  return out
end

local function countPlates()
  local n = 0
  for _ in pairs(plates()) do n = n + 1 end
  return n
end

local function frame(self)
  fills, draws, drawn = {}, {}, {}
  BattleState.drawPanel(self)
end

-- Whether a backdrop was found for this frame is the one thing everything
-- below turns on, and it is not a flag a test can set: the arm decides it by
-- taking the engine's `Chrome.clear` call.  So it is READ instead, off the
-- mark the arm leaves for UI THEME.
local function tookTheField(self)
  return self.gen1wildArenaField == true
end

do
  io.write("no backdrop, no paper\n")
  mod.stored.enabled = false
  local self = screen()
  frame(self)
  eq(#paperFills(), 0,
     "with BACKDROPS off nothing is laid: the cart's own white field is "
     .. "still there and there is nothing to put back")
  eq(drawn[1], "panel", "and the engine's own panel still draws")
  eq(tookTheField(self), false, "and the field is the cart's")
  mod.stored.enabled = nil
end

do
  io.write("a backdrop, and the plates under the HUDs\n")
  local self = screen()
  frame(self)
  ok(tookTheField(self),
     "the arm took the field, which is what everything below is about")

  local plate = plates()
  eq(countPlates(), 2, "one plate per HUD")

  -- DrawEnemyHUD clears (1,0) 4 rows x 11 cols; the player's block is the one
  -- its own draw writes into, (10,7) 5 rows x 10 cols.  In pixels.
  eq(plate.enemy and plate.enemy.x, 8,
     "the enemy plate starts at the enemy HUD's own column")
  eq(plate.enemy and plate.enemy.y, 0, "and its row")
  eq(plate.enemy and plate.enemy.w, 88, "eleven tiles wide")
  eq(plate.enemy and plate.enemy.h, 32, "four tall")

  eq(plate.player and plate.player.x, 80,
     "the player plate starts at the player HUD's column")
  eq(plate.player and plate.player.y, 56, "and its row")
  eq(plate.player and plate.player.w, 80, "ten tiles wide")
  eq(plate.player and plate.player.h, 40, "five tall")

  -- ...and each is laid BEFORE the HUD it is for, or it would cover it.
  local order = {}
  for _, f in ipairs(fills) do
    if f.kind == "paper" then order[#order + 1] = "paper" end
  end
  local function firstAt(what)
    for i, v in ipairs(drawn) do if v == what then return i end end
  end
  ok(firstAt("enemy") < firstAt("player"),
     "the enemy HUD draws before the player's, as the cart draws them")
end

do
  io.write("a HUD the cart is not drawing gets no plate\n")
  -- pics off for these, so the only paper counted is a plate's
  frame(screen({ showEnemyHud = false, drawsPics = false }))
  eq(countPlates(), 1,
     "no plate for a HUD that is not on screen -- it would be a white "
     .. "rectangle the cart does not have")

  frame(screen({ cleared = "player", drawsPics = false }))
  eq(countPlates(), 1, "nor for one ClearActorHud has blanked mid-animation")

  frame(screen({ statusHud = false, drawsPics = false }))
  eq(countPlates(), 0, "nor before the HUDs have ever been drawn")

  frame(screen({ mon = false, drawsPics = false }))
  eq(countPlates(), 1,
     "nor on the player's side in the catching tutorial, where there is no "
     .. "mon and no HUD")
end

do
  io.write("HUD PAPER off\n")
  mod.stored.hud_paper = false
  frame(screen({ drawsPics = false }))
  eq(countPlates(), 0, "the ragged cells come back")
  mod.stored.hud_paper = nil
end

-- ---------------------------------------------------------- under the pics

do
  io.write("paper under a pic\n")
  local outside = love.graphics.draw
  frame(screen())

  -- The pic's own blit reaches the real draw with the engine's numbers
  -- untouched.  (`measurePic` reads an image back through a canvas the first
  -- time it sees one, which is a draw at 0,0 of its own; the pic's is the one
  -- at the coordinates drawPic worked out.)
  local blit
  for _, d in ipairs(draws) do
    if d.a == 40 and d.b == 48 then blit = d end
  end
  ok(blit ~= nil, "the pic blit reaches love.graphics.draw untouched")
  eq(blit and blit.d, 2, "at the scale the ENGINE passed, not one re-derived")

  local picPaper = picPapers()
  eq(#picPaper, 2, "one paper per pic, at the measured box's own size")
  eq(#paperFills(), 2,
     "and it is NOT a palette fill: only the two HUD plates go through the "
     .. "theme, because a mon's hollow is the mon's white and not the page's")
  -- the measured box (2,2 12x12) at the engine's own x, y and scale of 2
  eq(picPaper[1].x, 40 + 2 * 2, "offset into the blit by the measured box")
  eq(picPaper[1].y, 48 + 2 * 2, "on both axes")
  eq(picPaper[1].h, 12 * 2, "and scaled by the scale the engine passed")

  eq(love.graphics.draw, outside,
     "the draw is put back: the shim is for the length of one drawPic and "
     .. "no longer")
end

do
  io.write("MON PAPER off\n")
  mod.stored.pic_paper = false
  frame(screen())
  eq(#picPapers(), 0, "no paper under the pics")
  eq(countPlates(), 2, "only the two HUD plates are left")
  mod.stored.pic_paper = nil
end

-- ---------------------------------------------------------------- the pics

do
  io.write("the pic measurement\n")
  local measure = mod.exports.picPaperBox
  ok(type(measure) == "function", "the measurement is exposed")
  if type(measure) == "function" then
    local box = measure(IMAGE)
    ok(box ~= nil and box ~= false, "a hollow four-shade pic is measured")
    if type(box) == "table" then
      eq(box.x, 2, "the box starts at the ink's own left edge")
      eq(box.y, 2, "and its top")
      eq(box.w, 12, "and is as wide as the ink reaches")
      eq(box.h, 12, "and as tall -- the paper fills the mon, not a square "
         .. "around it")
    end
  end
end

io.write(("arena gen2 paper: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
