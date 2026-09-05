-- The battle command menu on Gold, as four buttons.
--
-- Gold already lays its four commands out as a 2x2 -- `col = ((i-1)%2)*
-- spacing`, `row = floor((i-1)/2)*2` -- which is why this mod was Gen 1 only
-- for its whole life.  What it does not do is FRAME them: the four words sit
-- in one box across the right of the strip, so the grid reads as a block of
-- text rather than as four buttons.  That is what "still no updated battle ui
-- like we have for Gen 1 with the 2x2 selections" was about.
--
-- So the Gold arm is the frame and only the frame, and these cases are about
-- how narrowly it claims the strip: the command menu, on top of the stack,
-- outside a contest, with the option on.  Everything else -- a message, a
-- move list, the bug contest's eleven-glyph third label -- keeps the cart's
-- own box, and a claim that leaked into any of them would take a text box
-- away from a player mid-sentence.
--
-- Run:  luajit tests/battlemenu2_test.lua

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

local function slurp(path)
  local handle = assert(io.open(path, "r"), path .. " is missing")
  local source = handle:read("*a")
  handle:close()
  return source
end

-- ------------------------------------------------------------- the harness

package.loaded["src.core.GameVersion"] = {
  generation = function() return 2 end,
  get = function() return "gold" end,
  isYellow = function() return false end,
}

local boxes, prints, cursors
local Chrome = {
  DEFAULT_BOX_PALETTE = {
    { 255, 255, 255 }, { 255, 255, 255 }, { 255, 255, 255 }, { 0, 0, 0 },
  },
  box = function(tx, ty, tw, th)
    boxes[#boxes + 1] = { tx = tx, ty = ty, tw = tw, th = th }
  end,
  printThrough = function(text, tx, ty)
    prints[#prints + 1] = { text = text, tx = tx, ty = ty }
    return #tostring(text) * 8
  end,
  cursor = function(tx, ty) cursors[#cursors + 1] = { tx = tx, ty = ty } end,
}
package.loaded["src.ui.gen2.Chrome"] = Chrome

local mod = {
  id = "gen1_wild_ui_nightly",
  path = "modules/Gen1BattleUI",
  exports = {},
  stored = {},
  hooked = {},
  logged = {},
}
mod.read = function(_, name)
  return slurp("modules/Gen1BattleUI/" .. name)
end
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
mod.hooks = {
  wrap = function(_, name, fn, priority)
    mod.hooked[name] = { fn = fn, priority = priority }
  end,
}

assert(load(slurp("modules/Gen1BattleUI/main.lua"),
            "@modules/Gen1BattleUI/main.lua"))()(mod)

-- The labels are the cart's, ligature and all: `<PK><MN>` is two glyphs of
-- charmap and not the four letters it is spelled with here.
local LABELS = { "FIGHT", "<PK><MN>", "PACK", "RUN" }

local function screen(opts)
  opts = opts or {}
  local self = {
    phase = opts.phase or "menu",
    battle = opts.battle ~= false and { wild = true } or nil,
    menuIndex = opts.menuIndex or 1,
    contest = opts.contest,
  }
  self.menuLabels = function() return LABELS end
  if opts.covered then
    local other = {}
    self.game = { stack = { top = function() return other end } }
  end
  return self
end

local function overlay(state)
  boxes, prints, cursors = {}, {}, {}
  local hook = mod.hooked["battle.overlay"]
  hook.fn(function() end, state)
end

local function visible(state)
  local hook = mod.hooked["battle.bottom_ui_visible"]
  return hook.fn(function() return true end, state)
end

-- ---------------------------------------------------------------- installed

do
  io.write("the Gold arm installs\n")
  ok(mod.hooked["battle.bottom_ui_visible"], "the strip is asked for")
  ok(mod.hooked["battle.overlay"], "and the buttons are drawn on the overlay")
  eq(mod.hooked["battle.overlay"].priority, 5000,
     "last on the chain, so nothing else on the overlay draws over them")
  ok(not mod.hooked["battle.exp_award"],
     "and none of the Gen 1 machinery is installed: Gold has its own XP bar, "
     .. "its own level-up box and its own move panel")

  local keys = {}
  for _, row in ipairs(mod.rows or {}) do keys[row.key] = row end
  ok(keys.command_grid, "COMMAND GRID is the one row")
  eq(keys.command_grid and keys.command_grid.default, true, "and it is on")
  ok(not keys.move_panel,
     "and MOVE PANEL is not offered, because Gold's move list already shows "
     .. "the type and the PP this mod's panel exists to add")
end

-- ------------------------------------------------------------- the four boxes

do
  io.write("four boxes tiling the strip\n")
  overlay(screen())
  eq(#boxes, 4, "one box per command")

  -- Rows 12-17, twenty tiles wide: four 10x3 boxes tile it exactly, which is
  -- the same CLASSIC_BOXES the Gen 1 arm draws.
  local wanted = { { 0, 12 }, { 10, 12 }, { 0, 15 }, { 10, 15 } }
  for i, want in ipairs(wanted) do
    eq(boxes[i] and boxes[i].tx, want[1], ("box %d starts in its column"):format(i))
    eq(boxes[i] and boxes[i].ty, want[2], ("box %d on its row"):format(i))
    eq(boxes[i] and boxes[i].tw, 10, ("box %d is ten wide"):format(i))
    eq(boxes[i] and boxes[i].th, 3, ("box %d is three tall"):format(i))
  end

  eq(#prints, 4, "and one label per box")
  eq(prints[1] and prints[1].text, "FIGHT", "the cart's own words")
  eq(prints[2] and prints[2].text, "<PK><MN>",
     "including the ligature, which is what makes it fit")
  -- tx..tx+9 is the box and tx / tx+9 are its border columns, so the interior
  -- is tx+1..tx+8: the hand's tile and seven of label.
  eq(prints[1] and prints[1].tx, 2, "the label clears the hand's column")
  eq(prints[1] and prints[1].ty, 13, "on the box's interior row")
  eq(prints[4] and prints[4].tx, 12, "and the right column's labels with it")
  eq(prints[4] and prints[4].ty, 16, "on the bottom row")
end

do
  io.write("the hand\n")
  overlay(screen({ menuIndex = 3 }))
  eq(#cursors, 1, "one hand")
  eq(cursors[1] and cursors[1].tx, 1,
     "in the column the label leaves for it, so nothing shifts sideways as "
     .. "the cursor moves")
  eq(cursors[1] and cursors[1].ty, 16, "on the row of the command it is on")
end

-- ------------------------------------------------------- what it stands clear of

do
  io.write("whose strip it is\n")
  eq(visible(screen()), false, "the command menu's strip is ours")

  eq(visible(screen({ phase = "messages" })), true,
     "a message keeps the engine's own text box, which is the whole of how "
     .. "dialogue takes the strip back")
  overlay(screen({ phase = "messages" }))
  eq(#boxes, 0, "and no buttons are drawn under it")

  eq(visible(screen({ phase = "moves" })), true,
     "so does the move list, which Gold draws with a type and PP panel this "
     .. "mod has nothing to add to")

  eq(visible(screen({ contest = { balls = 20 } })), true,
     "and so does the bug contest, whose third label is PARKBALL and a count "
     .. "-- eleven glyphs where a 10-tile box has seven")
  overlay(screen({ contest = { balls = 20 } }))
  eq(#boxes, 0, "no buttons over it either")

  eq(visible(screen({ covered = true })), true,
     "and a battle with a screen open above it is not the one being asked "
     .. "about")

  eq(visible({ phase = "menu" }), true,
     "nor is a state that is not a battle at all")
end

do
  io.write("COMMAND GRID off\n")
  mod.stored.command_grid = false
  eq(visible(screen()), true, "the cart's own menu box comes back")
  overlay(screen())
  eq(#boxes, 0, "and nothing is drawn over it")
  mod.stored.command_grid = nil
end

-- ------------------------------------------------------------- the geometry

do
  io.write("the published geometry\n")
  local cells = mod.exports.geometry()
  eq(#cells, 4, "four cells")
  eq(cells[1].box.x, 0, "in pixels, for a neighbour that wants to clip")
  eq(cells[1].box.w, 80, "ten tiles")
  eq(cells[4].textY, 16 * 8, "and the last row's baseline")
  eq(cells[1].labelW, 56, "seven glyphs of label per button")
  ok(type(mod.exports.owns) == "function",
     "and whether the strip is claimed is answerable without drawing one")
end

io.write(("battle menu gen2: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
