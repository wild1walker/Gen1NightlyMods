-- Gen1Arena stands down while a voxel mod is drawing the battle.
--
-- A voxel mod draws the battle over the MAP, so there is already a world
-- behind the fight.  A backdrop painted into the field is then a second
-- background nobody asked for -- and worse than redundant: DRAMALESS_SHAPE
-- suppresses the engine's field fill by shimming `love.graphics.rectangle`,
-- which is the same call this mod shims to REPLACE that fill.  Two mods
-- swapping one function for the length of one draw is a coin toss decided by
-- load order.
--
-- The test is the renderer rather than a list of mod ids.  Every fork presents
-- its battle through `Renderer:setWorldOverride`, and the renderer clears that
-- in `beginFrame` -- so a non-nil `worldOverride` is exactly "something
-- replaced the world image on THIS frame", asked of the engine, with no mod
-- named.  A fork with its 3D battles switched off never sets it, and then the
-- backdrop is wanted and drawn.
--
-- Run:  luajit tests/arenavoxel_test.lua

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

_G.love = { graphics = {
  rectangle = function() end, setColor = function() end,
  getColor = function() return 1, 1, 1, 1 end,
  getCanvas = function() return nil end, setCanvas = function() end,
  clear = function() end, draw = function() end,
  newQuad = function(x, y, w, h) return { x = x, y = y, w = w, h = h } end,
} }

-- The engine's Renderer is a singleton table; the mod reads one field off it.
local Renderer = { worldOverride = nil }
package.preload["src.render.Renderer"] = function() return Renderer end

local mod = { id = "gen1_wild_ui_nightly", exports = {}, stored = {},
              hooked = {}, events_on = {} }
mod.options = {
  define = function() end,
  get = function(_, key) return mod.stored[key] end,
  set = function(_, key, value) mod.stored[key] = value end,
}
mod.log = {}
for _, level in ipairs({ "info", "warn", "error", "debug" }) do
  mod.log[level] = function() end
end
mod.hooks = { wrap = function(_, name, fn) mod.hooked[name] = fn end }
mod.events = { on = function(_, name, fn) mod.events_on[name] = fn end }
mod.assets = { path = function(_, p) return p end }
mod.storage = { writeBytes = function() return true end }
mod.content = {}

load_("modules/Gen1Arena/main.lua", mod)

local worldTaken = mod.exports.worldTaken
ok(type(worldTaken) == "function", "the decision is exposed")

io.write("who is drawing the world behind this battle\n")

do
  Renderer.worldOverride = nil
  eq(worldTaken(), false,
     "nothing replaced the world, so the backdrop is this mod's to draw")

  -- What every fork actually hands the renderer: a canvas.
  Renderer.worldOverride = { canvas = true }
  eq(worldTaken(), true,
     "a world override is a voxel mod drawing the battle over the map")

  Renderer.worldOverride = nil
  eq(worldTaken(), false,
     "and it is cleared each frame, so the answer goes back on its own")
end

io.write("and it is asked of the engine, not of a mod list\n")
do
  -- The point of reading the renderer: a fork this mod has never heard of,
  -- or one whose 3D battles are switched off, is answered correctly without
  -- anybody adding an id anywhere.
  Renderer.worldOverride = { canvas = true }
  ok(worldTaken(), "an unknown fork that presents a world stands this down")
  Renderer.worldOverride = nil
  ok(not worldTaken(),
     "and a fork with 3D battles off never sets it, so the backdrop stays")
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
