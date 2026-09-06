-- The dex ENTRY's pic sits on a white slab, and the slab is a rectangle the
-- cart fills before it draws.
--
-- Reported with the Gold dex in DARK: the description and the words came out
-- right after 0.32.66, but the POKeMON on the entry page was still standing on
-- a white square.  That square is not part of the picture -- it is one
-- `G.rectangle("fill", ..., 7*8, 7*8)` in `PokedexMenu:drawPic`, the block the
-- pic is padded into, filled in the palette's colour 0 before the pic lands.
--
-- Which colour 0 that is, is the whole of the fix.  `ownColors` picks the
-- palette: the LISTING passes nothing and gets PokedexQuestionMarkPalette, and
-- the cart genuinely shows a green mon on green there -- that is Gold, and it
-- is left alone.  The ENTRY passes true and gets the mon's own two colours,
-- whose colour 0 is white.  So the entry, and only the entry, is repainted in
-- the page's paper.
--
-- The rule is read off the ENGINE below rather than restated here, because a
-- test that restates it agrees with whatever the arm got wrong.
--
-- Run:  luajit tests/dexplate_test.lua
--       (needs an engine tree; SKIPs without one)

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
      local probe = io.open(dir .. "/src/ui/gen2/PokedexMenu.lua")
      if probe then probe:close(); ENGINE = dir; break end
    end
  end
end
if not ENGINE then
  io.write("dexplate: SKIPPED -- no engine tree found "
    .. "(set GEN1RECOMP to a gen1recomp checkout)\n")
  os.exit(0)
end

local function slurp(path)
  local handle = assert(io.open(path), path)
  local text = handle:read("*a")
  handle:close()
  return text
end

-- ---- the plate, read off the cart

local dexSrc = slurp(ENGINE .. "/src/ui/gen2/PokedexMenu.lua")

ok(dexSrc:find("function PokedexMenu:drawPic(row, tx, ty, ownColors)", 1, true) ~= nil,
   "drawPic takes (row, tx, ty, ownColors) -- the wrap's signature")
ok(dexSrc:find('G.rectangle("fill", tx * 8, ty * 8, 7 * 8, 7 * 8)', 1, true) ~= nil,
   "and fills a 7x7 block before the pic")
ok(dexSrc:find("local blank = colors and GbcPalette.color(colors, 1)", 1, true) ~= nil,
   "in the palette's colour 0, which is what makes it a slab")

-- Which palette that is, both ways round.
local body = dexSrc:match("function PokedexMenu:drawPic.-\nend")
assert(body, "could not find drawPic in the engine")
ok(body:find("colors = self.gfx and self.gfx.questionMarkPalette", 1, true) ~= nil,
   "without ownColors the plate is the question-mark palette -- the cart's green")
ok(body:find("colors = self.palettes and Palettes.monColors", 1, true) ~= nil,
   "with it, the mon's own -- whose colour 0 is the white square")
-- The unseen branch overrides the caller either way.
local unseen = body:match("else\n(.-)\n  end\n  if not image")
ok(unseen and unseen:find("questionMarkPalette", 1, true) ~= nil,
   "a row that is not SEEN takes the question-mark palette whatever was asked")

-- The listing asks for the cart's colours and must keep them.
ok(dexSrc:find("self:drawPic(self:current(), 1, 1)\n", 1, true) ~= nil,
   "the listing calls drawPic without ownColors")
ok(dexSrc:find("self:drawPic(row, 1, 1, true)", 1, true) ~= nil,
   "the entry calls it with ownColors")

-- ---- the shipped arm, lifted

local src = slurp("runtime/theme2.lua")
local wrap = src:match(
  "(        PokedexMenu%.drawPic = function%(self, row, tx, ty, ownColors, %.%.%.%).-\n        end)\n")
assert(wrap, "could not find the drawPic wrap in runtime/theme2.lua")

local PAPER, INK = { 16, 16, 24 }, { 232, 232, 240 }
local WHITE = { 255, 255, 255 }
local vanilla = { WHITE, WHITE, WHITE, { 0, 0, 0 } }
local function same(a, b)
  for i = 1, 4 do
    local x, y = a[i], b[i]
    if x[1] ~= y[1] or x[2] ~= y[2] or x[3] ~= y[3] then return false end
  end
  return true
end

-- A stand-in cart: it fills the plate in whatever colour 0 it was handed, the
-- way the engine does, and records every rectangle and colour that reached it.
local function harness(live)
  local log = {}
  local colour = { 1, 1, 1 }
  local love = { graphics = {
    setColor = function(r, g, b) colour = { r, g, b } end,
    rectangle = function(mode, x, y, w, h)
      log[#log + 1] = { mode = mode, x = x, y = y, w = w, h = h,
                        colour = { colour[1], colour[2], colour[3] } }
    end,
  } }
  local basePic = function(self, row, tx, ty, ownColors)
    local blank = (row and row.seen and ownColors) and WHITE or { 24, 128, 56 }
    local G = love.graphics
    G.setColor(blank[1] / 255, blank[2] / 255, blank[3] / 255, 1)
    G.rectangle("fill", tx * 8, ty * 8, 7 * 8, 7 * 8)
    G.setColor(1, 1, 1, 1)
    return "drawn"
  end
  local drawPic = assert(load(
    "local live, vanilla, same, basePic, love = ...\nlocal PokedexMenu = {}\n"
    .. wrap:gsub("^%s+", "") .. "\nreturn PokedexMenu.drawPic", "@theme2.lua"))(
      live, vanilla, same, basePic, love)
  return drawPic, log, love
end

local function rgb255(c) return ("%d,%d,%d"):format(
  math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5)) end
local function rgb(c) return ("%d,%d,%d"):format(c[1], c[2], c[3]) end

do -- DARK, the entry, a seen mon: the slab becomes the page
  local live = { PAPER, PAPER, PAPER, INK }
  local drawPic, log = harness(live)
  eq(drawPic({}, { seen = true }, 1, 1, true), "drawn", "the wrap returns what the cart returned")
  eq(#log, 1, "one rectangle reached the screen")
  eq(rgb255(log[1].colour), rgb(PAPER), "and the plate is the page's paper, not white")
  eq(log[1].w, 56, "still the 7x7 block")
  eq(log[1].x, 8, "at the block's own corner")
end

do -- the LISTING: no ownColors, so Gold's green mon on green stands
  local live = { PAPER, PAPER, PAPER, INK }
  local drawPic, log = harness(live)
  drawPic({}, { seen = true }, 1, 1)
  eq(#log, 1, "the listing still draws its plate")
  eq(rgb255(log[1].colour), "24,128,56", "in the cart's green -- untouched")
end

do -- an UNSEEN row on the entry: the question mark keeps its own plate
  local live = { PAPER, PAPER, PAPER, INK }
  local drawPic, log = harness(live)
  drawPic({}, { seen = false }, 1, 1, true)
  eq(rgb255(log[1].colour), "24,128,56", "an unseen entry keeps the cart's plate")
end

do -- LIGHT: the theme is the cart, so nothing is repainted at all
  local drawPic, log = harness({ WHITE, WHITE, WHITE, { 0, 0, 0 } })
  drawPic({}, { seen = true }, 1, 1, true)
  eq(rgb255(log[1].colour), "255,255,255", "LIGHT leaves the white plate white")
end

do -- only the FIRST 7x7 fill, and only a 7x7 one
  local live = { PAPER, PAPER, PAPER, INK }
  local drawPic, log, love = harness(live)
  local G = love.graphics
  local base = assert(load(
    "local live, vanilla, same, basePic, love = ...\nlocal PokedexMenu = {}\n"
    .. wrap:gsub("^%s+", "") .. "\nreturn PokedexMenu.drawPic", "@theme2.lua"))(
      live, vanilla, same,
      function(self, row, tx, ty)
        G.setColor(1, 0, 0, 1)
        G.rectangle("fill", 0, 0, 160, 144)      -- a clear: not the plate
        G.setColor(1, 1, 1, 1)
        G.rectangle("fill", 8, 8, 56, 56)        -- the plate
        G.setColor(0, 1, 0, 1)
        G.rectangle("fill", 8, 8, 56, 56)        -- a second one: not ours
      end, love)
  base({}, { seen = true }, 1, 1, true)
  eq(#log, 3, "every rectangle still reaches the screen")
  eq(rgb255(log[1].colour), "255,0,0", "a full-screen fill is not the plate")
  eq(rgb255(log[2].colour), rgb(PAPER), "the first 7x7 fill is")
  eq(rgb255(log[3].colour), "0,255,0", "a later one is not repainted twice")
end

do -- a cart that throws: the shim is put back and the error carries through
  local live = { PAPER, PAPER, PAPER, INK }
  local drawPic, _, love = harness(live)
  local G = love.graphics
  local realRect = G.rectangle
  local boom = assert(load(
    "local live, vanilla, same, basePic, love = ...\nlocal PokedexMenu = {}\n"
    .. wrap:gsub("^%s+", "") .. "\nreturn PokedexMenu.drawPic", "@theme2.lua"))(
      live, vanilla, same, function() error("kaboom", 0) end, love)
  local fine, why = pcall(boom, {}, { seen = true }, 1, 1, true)
  eq(fine, false, "an error in the cart is not swallowed")
  eq(why, "kaboom", "and arrives unwrapped")
  eq(G.rectangle, realRect, "and love.graphics.rectangle is put back")
end

-- ---- installed once, and only over a real function

ok(src:find('local okDex, PokedexMenu = pcall(require, "src.ui.gen2.PokedexMenu")',
            1, true) ~= nil,
   "the module is required through pcall -- a build without it is not a crash")
ok(src:find('not rawget(PokedexMenu, "__gen1wildDexPlate")', 1, true) ~= nil,
   "and wrapped once per session")
ok(src:find('type(PokedexMenu.drawPic) == "function"', 1, true) ~= nil,
   "over a drawPic that is actually there")

io.write(("dexplate: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
