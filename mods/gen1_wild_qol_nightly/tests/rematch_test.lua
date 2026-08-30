-- TRAINER REMATCH: which button you left the conversation with.
--
-- The feature is one wrap on world.talk and the whole of its interface is a
-- button press, so what is worth holding is the branching: who gets offered a
-- rematch, who is handed straight back to the engine, and what the two ways
-- out of the after-battle line do.
--
-- The one thing here that is not obvious and must not rot: a rematch battle
-- carries NO checkpointOrigin.  The engine's restore path keys on
-- `kind == "trainer_encounter"` and re-runs the entire first-win branch on
-- whatever it brings back -- defeatedTrainers, the header's event flag,
-- checkVictoryRewards -- so a restored rematch would hand out the badge a
-- second time.  Leaving the origin off means the checkpoint declines to
-- restore the battle, which is the failure worth having.
--
-- Run:  luajit tests/rematch_test.lua

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

-- ---------------------------------------------------------------- the engine
--
-- Only the four things the module reaches for, and each of them records what
-- it was asked so the test can look.

local boxes, battles

package.loaded["src.core.Strings"] = function(text) return text end

package.loaded["src.render.TextBox"] = {
  new = function(game, text, onDone, opts)
    local box = { game = game, text = text, onDone = onDone, opts = opts }
    boxes[#boxes + 1] = box
    return box
  end,
}

package.loaded["src.battle.BattleState"] = {
  newTrainer = function(game, class, party)
    local battle = { game = game, oppClass = class, partyIndex = party }
    battles[#battles + 1] = battle
    return battle
  end,
}

-- ---------------------------------------------------------------- the world

local HEADER = { after = "TEXT_ROUTE3_AFTER" }
local LINE = "I need to catch more\nPOKeMON!"

local function newWorld(options)
  options = options or {}
  local pressed = {}

  local game = {
    save = { money = 3000 },
    stack = { pushed = {}, push = function(self, state)
      self.pushed[#self.pushed + 1] = state
    end },
    input = { wasPressed = function(_, key) return pressed[key] == true end },
    data = {
      text = { TEXT_ROUTE3_AFTER = LINE },
      trainerHeader = function(_, label, index)
        if options.noHeader then return nil end
        return (label == "ROUTE_3" and index == 4) and HEADER or nil
      end,
    },
  }

  local npc = {
    frozen = false,
    faced = false,
    def = { trainerClass = "OPP_YOUNGSTER", trainerParty = 2, index = 4 },
    facePlayer = function(self) self.faced = true end,
  }
  if options.notATrainer then npc.def.trainerClass = nil end

  local ow = {
    player = {},
    map = { def = { label = "ROUTE_3" } },
    trainerDefeated = function() return options.beaten ~= false end,
    pushed = nil,
    finished = nil,
    pushBattle = function(self, battle) self.pushed = battle end,
    afterBattle = function(self, result) self.finished = result end,
  }

  return { game = game, npc = npc, ow = ow,
           press = function(key) pressed[key] = true end,
           release = function(key) pressed[key] = nil end }
end

-- ------------------------------------------------------------------ the mod

local function install(stored)
  boxes, battles = {}, {}
  local world = newWorld(stored and stored.world or nil)
  local values = (stored and stored.options) or {}
  local wrapped

  local mod = {
    world = { game = world.game },
    options = {
      define = function() end,
      get = function(_, key) return values[key] end,
    },
    hooks = { wrap = function(_, name, fn)
      if name == "world.talk" then wrapped = fn end
    end },
    log = { warn = function() end, info = function() end,
            error = function() end },
  }

  local source = assert(readFile("modules/Gen1Rematch/main.lua"))
  assert(load(source, "@modules/Gen1Rematch/main.lua"))()(mod)
  assert(wrapped, "the module did not wrap world.talk")

  world.talk = function()
    local reached = false
    wrapped(function() reached = true end, world.ow, world.npc)
    return reached
  end
  return world
end

-- ------------------------------------------------- A through, then the prompt

do
  io.write("A through a beaten trainer's line offers the rematch\n")
  local w = install()

  eq(w.talk(), false, "the wrap owns this interaction")
  eq(#boxes, 1, "one box: the trainer's own after-battle line")
  eq(boxes[1].text, LINE, "which is the line the engine would have printed")
  ok(w.npc.frozen, "the trainer is held for the conversation")
  ok(w.npc.faced, "and turned to face you, as talkTo does")

  -- A closed the box, so the press this frame is not B
  boxes[1].onDone()
  eq(#boxes, 2, "the prompt follows")
  eq(boxes[2].text, "Want to battle\nagain?", "asking the obvious question")
  ok(type(boxes[2].opts.choice) == "function", "as a YES / NO")
  ok(w.npc.frozen, "still held while the question is up")

  boxes[2].opts.choice(true)
  eq(#battles, 1, "YES starts a battle")
  eq(battles[1].oppClass, "OPP_YOUNGSTER", "against the trainer you talked to")
  eq(battles[1].partyIndex, 2, "with the roster they were beaten on")
  ok(battles[1].checkpointOrigin == nil,
     "and NO checkpoint origin -- a restore would re-award the badge")
  eq(w.ow.pushed, battles[1], "the battle is pushed")

  battles[1].onFinish("win")
  eq(w.ow.finished, "win", "the overworld is told how it ended")
  ok(not w.npc.frozen, "and the trainer is let go")
end

-- ------------------------------------------------------------- B out of it

do
  io.write("B out of the line asks nothing\n")
  local w = install()
  w.talk()
  eq(#boxes, 1, "the line, as before")

  w.press("b")
  boxes[1].onDone()
  eq(#boxes, 1, "no prompt")
  eq(#battles, 0, "no battle")
  ok(not w.npc.frozen, "and the trainer is let go")
end

do
  io.write("B wins a frame that carries both\n")
  local w = install()
  w.talk()
  w.press("a")
  w.press("b")
  boxes[1].onDone()
  eq(#boxes, 1, "the cancel is read first, so nothing is offered")
end

do
  io.write("NO at the prompt is the same as never asking\n")
  local w = install()
  w.talk()
  boxes[1].onDone()
  boxes[2].opts.choice(false)
  eq(#battles, 0, "no battle")
  ok(not w.npc.frozen, "the trainer is let go")
end

-- -------------------------------------------------- who is handed back

do
  io.write("everyone else goes to the engine untouched\n")

  local still = install({ world = { beaten = false } })
  eq(still.talk(), true, "a trainer still standing is the engine's")
  eq(#boxes, 0, "and nothing of ours is pushed")

  local mute = install({ world = { noHeader = true } })
  eq(mute.talk(), true, "a trainer with no after-battle line is too")

  local plain = install({ world = { notATrainer = true } })
  eq(plain.talk(), true, "so is anyone who is not a trainer")

  local off = install({ options = { enabled = false } })
  eq(off.talk(), true, "and so is everyone when the row is off")
  eq(#boxes, 0, "OFF is the vanilla interaction, with nothing to relaunch")
end

-- ------------------------------------------------------------- the purse

do
  io.write("REMATCH PRIZE decides whether the win pays\n")

  local paid = install({ options = { prize = true } })
  paid.talk(); boxes[1].onDone(); boxes[2].opts.choice(true)
  paid.game.save.money = paid.game.save.money + 480   -- the battle's own prize
  battles[1].onFinish("win")
  eq(paid.game.save.money, 3480, "on, the prize is left where the battle put it")

  local free = install({ options = { prize = false } })
  free.talk(); boxes[1].onDone(); boxes[2].opts.choice(true)
  free.game.save.money = free.game.save.money + 480
  battles[1].onFinish("win")
  eq(free.game.save.money, 3000, "off, the money is put back afterwards")

  -- Only a win pays, so only a win is refunded -- and a loss has already
  -- taken its own money on the way out of the battle, which is not ours.
  local lost = install({ options = { prize = false } })
  lost.talk(); boxes[1].onDone(); boxes[2].opts.choice(true)
  lost.game.save.money = 1500
  battles[1].onFinish("lose")
  eq(lost.game.save.money, 1500, "a blackout's cost is not refunded")
  eq(lost.ow.finished, "lose", "and the overworld still hears about it")
  ok(not lost.npc.frozen, "the trainer is let go either way")
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
