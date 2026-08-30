-- The SAVE screen, and every box drawn over a panel.
--
-- The bug, from a phone screenshot of START > SAVE in DARK: the screen was
-- split down the middle.  Everything right of tile 9 was dark and everything
-- left of it was light -- across the save panel, across the START menu behind
-- it, and across the dialogue box at the bottom, on a line that was not the
-- edge of any of them.
--
-- The line WAS the edge of something: the START menu's box.  SAVE keeps that
-- menu open behind the panel (start_sub_menus.asm:641-647) and a Menu wide
-- enough for POKeDEX and the mod rows sits at tile 9, eleven wide and the
-- full eighteen tall.  It has tx/ty/tw/th, so it got a panel -- and a panel
-- remaps every pixel in its rectangle, including the pixels of the two boxes
-- drawn ON TOP of it, neither of which got a panel of its own: the save panel
-- is an ad-hoc table with a draw function and no rectangle at all, and
-- src/render/TextBox.lua keeps its box in boxTx/boxTy/boxTw/boxTh.
--
-- So the panels are taken from what was DRAWN as well as from what the states
-- say, and a box drawn over a panel is a panel too.  Only forwards: the list
-- is in painting order, so a menu stacked over a battle cannot reach back and
-- repaint the battle's own boxes.
--
-- Run:  luajit tests/savescreen_test.lua

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

local function readFile(path)
  local handle = io.open(path, "r")
  if not handle then return nil end
  local body = handle:read("*a")
  handle:close()
  return body
end

local function fakeMod(id)
  local self
  self = {
    id = id or "gen1_wild_ui",
    path = ".",
    version = "1.0.0",
    exports = {},
    -- what the runtime asked the engine for
    defined = nil,
    stored = {},
    saved = {},
    cached = {},
    logged = {},
    hooked = {},
    events_on = {},
    screens = {},
    found = {},
  }

  -- Reads fall to a virtual filesystem first, so a test can hand the runtime
  -- a module without one existing on disk, then to the repo, so runtime/*.lua
  -- is the real thing under test.
  self.files = {}
  function self:read(path)
    if self.files[path] then return self.files[path] end
    return readFile(path)
  end

  self.options = {
    define = function(_, schema) self.defined = schema end,
    get = function(_, key) return self.stored[key] end,
    set = function(_, key, value) self.stored[key] = value end,
  }

  self.save = {
    get = function(_, key, fallback)
      local value = self.saved[key]
      if value == nil then return fallback end
      return value
    end,
    set = function(_, key, value) self.saved[key] = value end,
  }

  self.cache = {
    read = function(_, file) return self.cached[file] end,
    write = function(_, file, bytes) self.cached[file] = bytes end,
  }

  self.storage = {
    read = function(_, _game, key) return self.saved["storage:" .. key] end,
    write = function(_, _game, key, value)
      self.saved["storage:" .. key] = value
      return true
    end,
    delete = function(_, _game, key) self.saved["storage:" .. key] = nil end,
  }

  self.log = {}
  for _, level in ipairs({ "info", "warn", "error", "debug" }) do
    self.log[level] = function(_, format, ...)
      self.logged[#self.logged + 1] = { level = level,
        text = select("#", ...) > 0 and format:format(...) or format }
    end
  end

  self.hooks = {
    wrap = function(_, name, fn, priority)
      self.hooked[#self.hooked + 1] = { name = name, fn = fn, priority = priority }
    end,
  }

  self.events = {
    on = function(_, name, fn)
      self.events_on[#self.events_on + 1] = { name = name, fn = fn }
    end,
    once = function(_, name, fn)
      self.events_on[#self.events_on + 1] = { name = name, fn = fn, once = true }
    end,
    emit = function(_, name, payload)
      for _, entry in ipairs(self.events_on) do
        if entry.name == name then entry.fn(payload) end
      end
    end,
  }

  self.content = {
    screens = {
      register = function(_, screenId, factory)
        self.screens[screenId] = factory
      end,
    },
  }

  self.ui = {
    push = function() end,
    insertBefore = function(rows, _anchor, row)
      rows[#rows + 1] = row
      return rows
    end,
    TextBox = { new = function() return {} end },
    Font = {},
  }

  self.find = function(name)
    if type(name) ~= "string" then return nil end
    return self.found[name]
  end

  self.world = { game = nil }
  return self
end

local function load_(path, ...)
  local source = assert(readFile(path), path .. " is missing")
  return assert(load(source, "@" .. path))(...)
end

package.loaded["src.mods.ManagerState"] = { openOptions = function() end }

local OptionSet = load_("runtime/optionset.lua")
local Theme = load_("runtime/theme.lua")

local function themeOver()
  local mod = fakeMod()
  local optionset = OptionSet.new()
  local theme = Theme.new({ mod = mod, optionset = optionset })
  theme.defineRow()
  theme.write("dark")
  return theme
end

-- The map's own zone list: one whole-screen zone in the overworld's colours,
-- which is not a page and must never become one.
local function overworldZones()
  return { { colors = { { 255, 239, 255 }, { 132, 132, 132 },
                        { 82, 82, 82 }, { 0, 0, 0 } },
             x = 0, y = 0, w = 160, h = 144 } }
end

local function hex(c) return ("%02x%02x%02x"):format(c[1], c[2], c[3]) end

-- Font.drawBox, as the engine calls it.  Every box in the game goes through
-- it, so recording it is recording the screen.
local function draw(tx, ty, tw, th) Theme.recordBox(tx, ty, tw, th) end

local function covers(zones, x, y, w, h)
  for _, zone in ipairs(zones) do
    if zone.x == x and zone.y == y and zone.w == w and zone.h == h then
      return zone
    end
  end
  return nil
end

-- ------------------------------------------------------- the screenshot

do
  io.write("START > SAVE is dark all the way across\n")
  local theme = themeOver()

  -- The stack, bottom up, as StartMenu.lua builds it: the map, the kept-open
  -- START menu, the save panel, the prompt, and its YES/NO.
  local world = { sgbPalettes = true }
  local start = { tx = 9, ty = 0, tw = 11, th = 18 }
  -- no rectangle of any kind: StartMenu.lua's `panel` is a bare table with
  -- update and draw on it
  local savePanel = { holdsUIAnchors = true }
  -- TextBox spells its box differently, which is why panelRect never saw it
  local prompt = { boxTx = 0, boxTy = 12, boxTw = 20, boxTh = 6 }
  -- SaveTheGame_YesOrNo pins its box at hlcoord 0,7 (save.asm:186-192)
  local choice = { tx = 0, ty = 7, tw = 6, th = 4 }

  -- and what they drew, in the order Game.draw drew them
  draw(9, 0, 11, 18)     -- Menu:draw
  draw(4, 0, 16, 10)     -- StartMenu.lua's Font.drawBox(4, 0, 16, 10)
  draw(0, 12, 20, 6)     -- TextBox:draw
  draw(0, 7, 6, 4)       -- ChoiceBox:draw

  local out = theme.apply(
    { stack = { states = { world, start, savePanel, prompt, choice } } },
    overworldZones())

  eq(#out, 5, "the map's zone, and one panel for each of the four boxes")
  eq(hex(out[1].colors[1]), "ffefff", "the map is not touched")

  local menu = covers(out, 72, 0, 88, 144)
  ok(menu, "the START menu's box, which is what the split line was")
  local panel = covers(out, 32, 0, 128, 80)
  ok(panel, "the save panel, which no state describes")
  local box = covers(out, 0, 96, 160, 48)
  ok(box, "the dialogue, whose rectangle is spelled boxTx")
  local yesno = covers(out, 0, 56, 48, 32)
  ok(yesno, "and the YES/NO, which had one all along")

  for _, zone in ipairs({ menu, panel, box, yesno }) do
    if zone then eq(hex(zone.colors[1]), "000000", "every panel is the same dark paper") end
  end
end

-- --------------------------------------------- a panel does not reach back

do
  io.write("a menu over a battle does not repaint the battle\n")
  local theme = themeOver()

  -- BattleState draws its own boxes and then the command menu is stacked on
  -- top.  The two overlap -- (0,8,11,5) is x 0-88 and the menu is x 72-160 --
  -- so an overlap rule that did not care about order would take the battle's
  -- dialogue box with it and leave the rest of the battle alone: the same
  -- half-and-half this file exists to stop.
  local battle = { sgbPalettes = true }
  local command = { tx = 9, ty = 7, tw = 11, th = 5 }

  draw(0, 8, 11, 5)      -- the battle's own, drawn first because it is under
  draw(4, 12, 16, 6)     -- and its move list
  draw(9, 7, 11, 5)      -- then the menu on top

  local out = theme.apply({ stack = { states = { battle, command } } },
                          overworldZones())

  eq(#out, 2, "the frame, and the menu's panel -- nothing of the battle's")
  ok(covers(out, 72, 56, 88, 40), "the command menu is themed")
  ok(not covers(out, 0, 64, 88, 40), "the battle's box is left alone")
end

-- ------------------------------------------------------------ transitive

do
  io.write("a box over a box over a panel comes along\n")
  local theme = themeOver()
  local world = { sgbPalettes = true }
  local start = { tx = 9, ty = 0, tw = 11, th = 18 }

  draw(9, 0, 11, 18)     -- the panel
  draw(4, 0, 16, 10)     -- touches it
  draw(0, 8, 5, 3)       -- touches only what touched it
  draw(0, 0, 2, 1)       -- touches neither

  local out = theme.apply({ stack = { states = { world, start } } },
                          overworldZones())
  eq(#out, 4, "three boxes and the frame")
  ok(covers(out, 0, 64, 40, 24), "the second-hand overlap is a panel too")
  ok(not covers(out, 0, 0, 16, 8), "a box that overlaps nothing is not")
end

-- --------------------------------------------------------- the plumbing

do
  io.write("the recorder is drained on every frame\n")
  local theme = themeOver()
  local world = { sgbPalettes = true }
  local start = { tx = 9, ty = 0, tw = 11, th = 18 }

  -- A LIGHT frame returns the list by reference and still empties the
  -- recorder: nothing else does, and a wrapper on an engine function cannot
  -- be asked to stop.
  theme.write("light")
  draw(4, 0, 16, 10)
  local zones = overworldZones()
  eq(theme.apply({ stack = { states = { world, start } } }, zones), zones,
     "LIGHT hands the list straight back")

  theme.write("dark")
  local out = theme.apply({ stack = { states = { world, start } } },
                          overworldZones())
  eq(#out, 2, "and the box from the light frame is not still in the list")

  ok(Theme.takeBoxes() == nil, "an empty recorder answers nil")
  Theme.recordBox(1, 2, 3, 4)
  local taken = Theme.takeBoxes()
  eq(#taken, 1, "one box in, one box out")
  eq(taken[1].x, 8, "in pixels")
  eq(taken[1].h, 32, "...both ways")
  ok(Theme.takeBoxes() == nil, "and taking it took it")

  Theme.recordBox(0, 0, 0, 4)
  Theme.recordBox("nine", 0, 1, 1)
  ok(Theme.takeBoxes() == nil, "a box with no area, or no numbers, is not one")
end

-- ------------------------------------------------- nothing drawn at all

do
  io.write("with nothing recorded the stack still answers\n")
  local theme = themeOver()
  local world = { sgbPalettes = true }
  local start = { tx = 10, ty = 0, tw = 10, th = 12 }

  local out = theme.apply({ stack = { states = { world, start } } },
                          overworldZones())
  eq(#out, 2, "the map's zone and the menu's panel")
  eq(out[2].x, 80, "the panel is still read off the state")
  eq(out[2].w, 80, "...and its width")
end

-- ------------------------------------------ the box under the YES / NO

do
  io.write("dialogue over the map is themed with its YES / NO\n")
  -- From a screenshot of the rematch prompt in DARK: "That will be Y450. OK?"
  -- on white paper, with a black YES / NO sitting beside it.  Two boxes, one
  -- themed.
  --
  -- src/ui/ChoiceBox.lua takes tx/ty/tw/th; src/render/TextBox.lua keeps the
  -- same four as boxTx/boxTy/boxTw/boxTh (TextBox.lua:123-126).  Only the
  -- first spelling was read -- and the drawn-box closure could not save it
  -- either, because the dialogue is drawn FIRST and the closure only ever
  -- looks backwards at boxes it has already accepted.
  local theme = themeOver()
  local world = { sgbPalettes = true }
  local prompt = { boxTx = 0, boxTy = 12, boxTw = 20, boxTh = 6 }
  local choice = { tx = 13, ty = 7, tw = 6, th = 4 }

  draw(0, 12, 20, 6)          -- TextBox:draw
  draw(13, 7, 6, 4)           -- ChoiceBox:draw

  local out = theme.apply({ stack = { states = { world, prompt, choice } } },
                          overworldZones())

  eq(#out, 3, "the map's zone, and a panel for each box")
  eq(hex(out[1].colors[1]), "ffefff", "the map is not touched")
  local box = covers(out, 0, 96, 160, 48)
  ok(box, "the dialogue is a panel now, spelled its own way")
  eq(hex(box.colors[1]), "000000", "...and it is dark")
  local yesno = covers(out, 104, 56, 48, 32)
  ok(yesno, "and the YES / NO, which always was")
end

do
  io.write("a state carrying both spellings is read once\n")
  local theme = themeOver()
  local world = { sgbPalettes = true }
  -- tx/ty first: that is the pair src/ui/Menu.lua computes, and a state that
  -- has both is a Menu with a box field that means something else.
  local both = { tx = 9, ty = 0, tw = 11, th = 18,
                 boxTx = 0, boxTy = 12, boxTw = 20, boxTh = 6 }

  local out = theme.apply({ stack = { states = { world, both } } },
                          overworldZones())
  eq(#out, 2, "one panel, not two")
  eq(out[2].x, 72, "and it is the tx/ty one")
end

-- --------------------------------------- a battle has no zone list at all

do
  io.write("a box over a battle does not repaint the battle\n")
  -- From a screenshot of "Will WILD change POKeMON?" in DARK: the boxes were
  -- themed and the ENTIRE battle behind them had gone black and white.
  --
  -- Renderer:blitCanvas opens with
  --
  --     local shader = zoneList and zoneList[1] and PaletteFX.shader() or nil
  --     if not shader then ... draw the canvas RAW ...
  --
  -- so an empty list is not "colour nothing", it is "run no shader and blit
  -- this frame in the colours it was drawn in".  BattleState:sgbPalettes
  -- returns nil for every layout but the wide one, so a battle IS that -- and
  -- appending one panel to it turns the shader on for the whole screen.
  local theme = themeOver()
  local battle = { sgbPalettes = true }
  local prompt = { boxTx = 0, boxTy = 12, boxTw = 20, boxTh = 6 }
  local choice = { tx = 0, ty = 7, tw = 6, th = 4 }

  draw(0, 12, 20, 6)
  draw(0, 7, 6, 4)

  local out = theme.apply({ stack = { states = { battle, prompt, choice } } },
                          nil)
  ok(out == nil, "a frame with no zones is handed back with no zones")

  -- and the same for a list that is there but empty
  local empty = {}
  eq(theme.apply({ stack = { states = { battle, prompt, choice } } }, empty),
     empty, "an empty list is the same answer")
end

do
  io.write("a frame that does have zones still gets its panels\n")
  -- the guard is about the EMPTY list, not about panels: the map has a zone
  -- list, so a box over it is themed exactly as before
  local theme = themeOver()
  local world = { sgbPalettes = true }
  local prompt = { boxTx = 0, boxTy = 12, boxTw = 20, boxTh = 6 }
  draw(0, 12, 20, 6)

  local out = theme.apply({ stack = { states = { world, prompt } } },
                          overworldZones())
  eq(#out, 2, "the map's zone and the dialogue's panel")
  ok(covers(out, 0, 96, 160, 48), "which is the dialogue")
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
