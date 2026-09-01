-- A battle's outcome is committed AFTER battle.ended, and the save waits.
--
-- `battle.ended` is emitted while the battle is still tearing down.  What
-- writes the OUTCOME runs later: BattleState hands the battle's `onFinish` to
-- the battle-return transition as its onDone, and a trainer's onFinish is what
-- sets `save.defeatedTrainers[npc.id]` and the map's event flag.
--
-- The ten covered frames at the front of that return are the window a
-- post-battle save aims at, and they are all BEFORE the win exists.  So the
-- save that was reliably taken there was reliably a save of the battle NOT
-- won: load it and the trainer wants to fight again, having been beaten.  The
-- good window is what made it happen every time rather than sometimes.
--
-- What is asserted is the order and nothing else: not due at battle.ended,
-- due once onFinish has run, and the inner onFinish having run FIRST -- which
-- is the whole of the fix, because "committed" means that call returned.
--
-- Run:  luajit tests/autosave_outcome_test.lua

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

-- The same stand-in autosave_veil_test uses, with the event bus kept rather
-- than dropped: this file's whole subject is what a handler does.
local function fakeMod()
  local self = { id = "gen1_wild_qol_nightly", path = ".", exports = {},
                 stored = {}, handlers = {} }
  self.options = {
    define = function() end,
    get = function(_, key) return self.stored[key] end,
    set = function(_, key, value) self.stored[key] = value end,
  }
  self.save = { get = function(_, _, fallback) return fallback end,
                set = function() end }
  self.cache = { read = function() end, write = function() end }
  self.storage = { read = function() end, write = function() end,
                   delete = function() end }
  self.log = {}
  for _, level in ipairs({ "info", "warn", "error", "debug" }) do
    self.log[level] = function() end
  end
  self.hooks = { wrap = function() end }
  self.events = {
    on = function(_, name, fn)
      local list = self.handlers[name] or {}
      list[#list + 1] = fn
      self.handlers[name] = list
    end,
    once = function(_, name, fn) return self.events.on(_, name, fn) end,
  }
  self.content = {}
  self.ui = { push = function() end }
  self.world = {}
  self.find = function() return nil end
  function self:read() return nil end
  function self.fire(name, event)
    for _, fn in ipairs(self.handlers[name] or {}) do fn(event) end
  end
  return self
end

local function install()
  local mod = fakeMod()
  local chunk = load_("modules/Gen1AutoSave/main.lua")
  chunk(mod)
  -- The two switches this path is behind, both on: the mod itself, and the
  -- "save after battles, catches, evolutions" row.
  mod.options:set("enabled", true)
  mod.options:set("events", true)
  -- A save asked for before the battle would make every case below say yes
  -- for the wrong reason.
  mod.fire("save.writing", {})
  return mod
end

local function due(mod)
  return mod.exports.autosaveStatus().due
end

io.write("a post-battle save waits for the outcome\n")

-- ------------------------------- a trainer battle: the outcome is onFinish

do
  local mod = install()
  local ran = {}
  local battle = {
    onFinish = function(result) ran[#ran + 1] = "onFinish:" .. tostring(result) end,
  }
  local inner = battle.onFinish

  mod.fire("battle.ended", { battle = battle, result = "win" })
  eq(due(mod), false,
     "battle.ended alone does NOT make a save due -- the win is not written yet")
  ok(battle.onFinish ~= inner, "the outcome call has been wrapped")

  battle.onFinish("win")
  eq(ran[1], "onFinish:win", "the battle's own onFinish still runs, and first")
  eq(due(mod), true, "and the save is due once it has")
end

-- --------------------------------- a wild battle: there is nothing to wait for

do
  local mod = install()
  mod.fire("battle.ended", { battle = {}, result = "win" })
  eq(due(mod), true,
     "a battle carrying no onFinish has no outcome pending, so it is due at once")

  mod = install()
  mod.fire("battle.ended", { result = "run" })
  eq(due(mod), true, "and so is an event with no battle on it at all")
end

-- --------------------------------------------------- the switch is honoured

do
  local mod = install()
  mod.options:set("events", false)
  local battle = { onFinish = function() end }
  mod.fire("battle.ended", { battle = battle, result = "win" })
  eq(due(mod), false, "with the events row off, nothing is asked for")
  battle.onFinish("win")
  eq(due(mod), false, "and running the outcome does not smuggle one in")
end

-- ------------------------------------------------ a teardown that goes wrong

do
  local mod = install()
  local battle = { onFinish = function() error("boom", 0) end }
  mod.fire("battle.ended", { battle = battle, result = "win" })
  local fine = pcall(battle.onFinish, "win")
  eq(fine, false, "a raising onFinish still raises to whoever called it")
  eq(due(mod), true,
     "and the save is still due: a half-torn-down battle is what will be loaded")
end

-- ----------------------------------------------------- wrapped exactly once

do
  local mod = install()
  local calls = 0
  local battle = { onFinish = function() calls = calls + 1 end }
  mod.fire("battle.ended", { battle = battle, result = "win" })
  local first = battle.onFinish
  mod.fire("battle.ended", { battle = battle, result = "win" })
  eq(battle.onFinish, first, "a second battle.ended does not wrap the wrapper")
  battle.onFinish("win")
  eq(calls, 1, "so the battle's own onFinish runs once, not twice")
end

-- ------------------- the half 0.32.2 missed: a save that was ALREADY owed
--
-- Delaying the request is not enough on its own.  `due` is very often already
-- true when a battle ends -- a catch, an evolution, a map entered on the way
-- to the fight -- and the covered-screen write wants only `due and dirty`.
-- The battle's return hold is the most covered screen this mod ever sees, so
-- a save that was already owed lands there regardless of what battle.ended
-- asked for: between the last hit and the defeat being recorded.
--
-- What has to be true is that the WRITE stands down, not the request.
io.write("a save already owed does not spend the battle's return hold\n")

do
  local mod = install()
  local status = mod.exports.autosaveStatus

  -- something earlier already asked for a save
  mod.exports.autosaveRequest()
  eq(status().due, true, "a save is owed before the battle even ends")

  local battle = { onFinish = function() end }
  mod.fire("battle.ended", { battle = battle, result = "win" })

  eq(status().inBattle, false, "the battle is over as far as the mod knows")
  eq(status().outcomePending, true,
     "but its outcome is not written yet, and the mod is holding for that")

  battle.onFinish("win")
  eq(status().outcomePending, false, "the hold is released once it is")
  eq(status().due, true, "and the save is still owed, to be taken after")
end

do
  -- A wild battle has no outcome to wait for, so it must not hold at all --
  -- holding every battle would push every post-battle save off the one window
  -- the mod was built around.
  local mod = install()
  mod.fire("battle.ended", { battle = {}, result = "run" })
  eq(mod.exports.autosaveStatus().outcomePending, false,
     "a battle carrying no onFinish holds nothing")
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
