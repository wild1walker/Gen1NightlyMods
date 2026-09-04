-- Putting the START menu back after the layout editor.
--
-- The editor is reached FROM the START menu and has to put it back on the way
-- out, and that one call is the whole subject of this file, because getting it
-- wrong on Gold produces a menu that cannot be escaped.
--
-- Red's `StartMenu.new(game)` takes the game and nothing else: it builds every
-- row's `onSelect` itself, and the engine's own way in is a bare
-- `Screens.push(Game, "StartMenu")`.  Gold's is `StartMenu.new(game, opts)`
-- and takes `onChoose` and `onClose` as PUSH OPTIONS -- so the same bare push
-- there builds a menu whose `choose` ends in `if self.onChoose then` and whose
-- `close` ends in `if self.onClose then`.  Both are nil.  Nothing opens, and B
-- and START do not shut it: the rows draw, the cursor moves, and the only way
-- out is a soft reset.
--
-- So the assertion is not "a screen was pushed".  It is WHICH call was made:
-- the game's own opener where there is one, and only the learned screen id
-- where there is not.
--
-- Run:  luajit tests/menumanager_reopen_test.lua

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

local function readFile(path)
  local handle = io.open(path, "r")
  if not handle then return nil end
  local body = handle:read("*a")
  handle:close()
  return body
end

-- ------------------------------------------------------------- the harness

local DIR = "modules/Gen1MenuManager"

-- Enough of the engine's mod object for the entry chunk to install against,
-- instrumented where the assertions are: what was pushed, and what was logged.
local function fakeMod()
  local self = {
    id = "gen1_wild_qol_nightly",
    path = DIR,
    exports = {},
    stored = { select_shortcut = true, menu_row = true, pc_row = true },
    saved = {},
    hooks_by_name = {},
    listeners = {},
    screens = {},
    pushed = {},
    logged = {},
  }

  function self:read(name) return readFile(DIR .. "/" .. name) end

  self.options = {
    define = function() end,
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
  self.cache = { read = function() end, write = function() end }
  self.log = {}
  for _, level in ipairs({ "info", "warn", "error", "debug" }) do
    self.log[level] = function(_, format, ...)
      self.logged[#self.logged + 1] = select("#", ...) > 0
        and format:format(...) or format
    end
  end
  self.hooks = {
    wrap = function(_, name, fn) self.hooks_by_name[name] = fn end,
  }
  self.events = {
    on = function(_, name, fn)
      self.listeners[name] = self.listeners[name] or {}
      table.insert(self.listeners[name], fn)
    end,
    once = function(_, name, fn)
      self.listeners[name] = self.listeners[name] or {}
      table.insert(self.listeners[name], fn)
    end,
  }
  self.content = {
    screens = {
      register = function(_, id, factory) self.screens[id] = factory end,
    },
  }
  self.ui = {
    push = function(_game, id, opts)
      self.pushed[#self.pushed + 1] = { id = id, opts = opts }
      return opts
    end,
  }
  self.world = { game = nil }
  self.find = function() return nil end
  return self
end

local function install(mod)
  local source = assert(readFile(DIR .. "/main.lua"), "main.lua is missing")
  assert(load(source, "@" .. DIR .. "/main.lua"))()(mod)
  return mod
end

-- The two shapes of game.  Gold's has `openStartMenu`; Red's has no such
-- method at all, which is what the fallback is keyed on.
local function goldGame()
  local game = { save = { player = { name = "GOLD" } }, opened = 0 }
  game.stack = { states = {}, pop = function() end,
                 top = function() return nil end }
  game.openStartMenu = function(self) self.opened = self.opened + 1 end
  return game
end

local function redGame()
  local game = { save = { player = { name = "RED" } } }
  game.stack = { states = {}, pop = function() end,
                 top = function() return nil end }
  return game
end

-- Walk the START menu hook the way the engine does, find the manager's own
-- row, and run it -- which is what opens the editor and hands it the onCancel
-- that has to put the menu back.
local function editorCancelFor(mod, game)
  local hook = mod.hooks_by_name["ui.start_menu.items"]
  assert(type(hook) == "function", "the START menu hook was never wrapped")

  local vanilla = {
    { label = "POKeDEX", value = "pokedex" },
    { label = "PACK", value = "pack" },
    { label = "SAVE", value = "save" },
  }
  local rows = hook(function(_g, items) return items end, game, vanilla)

  local manager
  for _, row in ipairs(rows) do
    if row.label == "MENU MGR" then manager = row end
  end
  assert(manager, "the manager's own row is not on the menu")

  local before = #mod.pushed
  manager.onSelect(game)
  local push = mod.pushed[#mod.pushed]
  assert(#mod.pushed > before and push.id == "Gen1MenuManagerEditor",
         "the editor was not opened")
  return push.opts and push.opts.onCancel, rows
end

-- ------------------------------------------------------------------ Gold

do
  io.write("on Gold\n")
  local mod = install(fakeMod())
  local game = goldGame()

  local cancel, rows = editorCancelFor(mod, game)
  ok(type(cancel) == "function", "the editor is handed a way back")

  -- The engine learns the id from the live menu; give it Gold's, so the
  -- fallback path is available and the test can prove it is NOT the one taken.
  for _, fn in ipairs(mod.listeners["screen.pushed"] or {}) do
    fn({ state = { screenId = "Gen2StartMenu", items = rows,
                   update = function() end } })
  end

  local pushes = #mod.pushed
  cancel()

  eq(game.opened, 1,
     "the GAME is asked to open its own menu -- which is the only call that "
     .. "supplies onChoose and onClose")
  eq(#mod.pushed, pushes,
     "and the screen id is not pushed behind its back: a bare push builds a "
     .. "menu that opens nothing and does not close")
  eq(#mod.logged, 0, "with nothing to report")
end

do
  io.write("on Gold, when the opener raises\n")
  local mod = install(fakeMod())
  local game = goldGame()
  local cancel, rows = editorCancelFor(mod, game)
  for _, fn in ipairs(mod.listeners["screen.pushed"] or {}) do
    fn({ state = { screenId = "Gen2StartMenu", items = rows,
                   update = function() end } })
  end

  game.openStartMenu = function() error("no world") end
  cancel()

  local last = mod.pushed[#mod.pushed]
  eq(last and last.id, "Gen2StartMenu",
     "the learned id is the fallback -- a menu that opens nothing still "
     .. "beats no menu at all")
  ok(#mod.logged > 0, "and the failure is reported rather than swallowed")
end

-- ------------------------------------------------------------------- Red

do
  io.write("on Red\n")
  local mod = install(fakeMod())
  local game = redGame()

  local cancel, rows = editorCancelFor(mod, game)
  for _, fn in ipairs(mod.listeners["screen.pushed"] or {}) do
    fn({ state = { screenId = "StartMenu", items = rows,
                   update = function() end } })
  end

  local pushes = #mod.pushed
  cancel()

  eq(#mod.pushed, pushes + 1, "one screen is pushed")
  local last = mod.pushed[#mod.pushed]
  eq(last and last.id, "StartMenu",
     "and it is the learned id, unchanged -- Red's StartMenu.new takes the "
     .. "game and nothing else, so the bare push IS the engine's own call")
  eq(#mod.logged, 0, "with nothing to report")
end

do
  io.write("before the menu has ever been seen\n")
  -- No screen.pushed yet, so no id has been learned.  On Red that leaves
  -- nothing to do; the point is that it does not raise.
  local mod = install(fakeMod())
  local game = redGame()
  local cancel = editorCancelFor(mod, game)
  local pushes = #mod.pushed
  local fine = pcall(cancel)
  ok(fine, "the way back does not raise with no id learned")
  eq(#mod.pushed, pushes, "and pushes nothing")
end

io.write(("menumanager reopen: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
