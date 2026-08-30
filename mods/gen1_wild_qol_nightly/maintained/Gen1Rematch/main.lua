-- Gen1Rematch -- fight a trainer you have already beaten.
--
-- ------- the shape of it
--
-- A beaten trainer already has something to say.  `def_trainers` gives every
-- one of them an `after` line, and walking up to a trainer you have beaten
-- prints it (src/world/OverworldController.lua:3130-3137) -- that is the
-- whole of what talking to them does today.  So the rematch is offered where
-- the conversation already ends, rather than as a new thing on the screen:
--
--   A through the line   ->  "Want to battle again?"  ->  YES / NO
--   B out of the line    ->  nothing, exactly as before
--
-- Which button ended the box is the whole interface.  It costs no row, no
-- prompt for anyone who did not ask, and it is the reading both buttons
-- already have everywhere else in this game: A is "go on then", B is "I am
-- done here".
--
-- The engine does not distinguish them -- `TextBox` advances and closes on
-- either (home/text_script.asm:96 waits on A|B, and src/render/TextBox.lua:476
-- is that faithfully) -- but it does not have to.  `onDone` is called from
-- inside the same `update` that saw the press, one line after `stack:pop()`,
-- so the press is still this frame's and `wasPressed("b")` still answers.
-- That is the only reason this reads a button at all rather than patching the
-- box.
--
-- ------- what a rematch is and is not
--
-- It is the battle and nothing else.  The victory path a first win takes --
-- `defeatedTrainers`, the header's event flag, `checkVictoryRewards` -- is
-- not run here, so no badge is handed out twice, no gift item reappears, and
-- no map's onVictory script fires again.  A gym leader is an ordinary trainer
-- on this path and can be fought again for the practice; the badge is already
-- yours and stays exactly once yours.
--
-- The team is the one you beat, at the levels you beat it.  Nothing scales.
-- That is a deliberate floor rather than a limitation to fix later: a rematch
-- whose levels move is a different feature, and it would want to say so on
-- screen before the battle starts.
--
-- ------- what it costs
--
-- Half of what they pay, up front.  The engine's win branch adds
-- `baseMoney * level` (src/battle/BattleState.lua:4721-4722) and the rematch
-- asks for half of that before the battle starts, so a win nets you the other
-- half and a loss costs you the stake.  A repeatable battle that paid full
-- price would be a money printer; one that paid nothing would be a trip for
-- exp alone.  Half is the fight being worth making and worth losing.
--
-- The price is read off the battle that is about to be fought rather than off
-- the trainer's data table, and that is deliberate: `baseMoney * level` uses
-- the level of the LAST mon in the party as the battle actually built it, so
-- anything that rewrites a trainer's party on the way in -- a difficulty mod
-- through `trainer.party`, this suite's own or somebody else's -- moves the
-- prize and the price together, with nothing here having to know it happened.
-- The cost is that the battle is built to be asked and thrown away if you say
-- no; the only trace that leaves is the first mon marked SEEN, which it was
-- when you beat them.
--
-- REMATCH PRIZE off takes both halves out: nothing is charged, and the prize
-- the engine paid is put back afterwards.  Off is a rematch with no money in
-- it at all, in either direction.

return function(mod)

  -- Two pages, closing on the mart's own line (src/ui/ShopMenu.lua:90), so
  -- the price is stated in the words this game already uses for a price and
  -- nobody is charged for something they were not shown.  The YES/NO comes up
  -- by itself once the last page has typed out.
  local ASK = "Want to battle\nagain?"
  local PRICED = ASK .. "\fThat will be\n\194\165%d. OK?"
  local BROKE = "You don't have\nenough money."

  mod.options:define({
    { key = "enabled", type = "toggle", label = "TRAINER REMATCH",
      default = true },
    -- The money in a rematch, both ways: the half you stake and the whole
    -- the engine pays you back for winning.  Off is a rematch that is worth
    -- exp and nothing else, and costs the same.
    { key = "prize", type = "toggle", label = "REMATCH PRIZE", default = true,
      visible_if = { key = "enabled", equals = true } },
  })

  local function on(key) return mod.options:get(key) ~= false end

  local function say(text)
    local ok, Strings = pcall(require, "src.core.Strings")
    if ok and type(Strings) == "function" then
      local said, out = pcall(Strings, text)
      if said and type(out) == "string" then return out end
    end
    return text
  end

  -- ------- is this a trainer with a rematch in them?
  --
  -- Answers the line to print, or nil for "not ours" -- and nil is the
  -- ordinary answer.  Every gate here is one the vanilla path checks in the
  -- same order at OverworldController.lua:3125-3137, so a trainer this says
  -- yes to is exactly a trainer whose after-line the engine was about to
  -- print anyway.  One that says no falls through and the engine does what it
  -- always did.
  local function afterLine(ow, npc)
    local def = npc and npc.def
    if type(def) ~= "table" or not def.trainerClass then return nil end
    if type(ow.trainerDefeated) ~= "function" then return nil end
    local asked, beaten = pcall(ow.trainerDefeated, ow, npc)
    if not asked or not beaten then return nil end

    local game = mod.world and mod.world.game
    local data = game and game.data
    local label = ow.map and ow.map.def and ow.map.def.label
    if type(data) ~= "table" or type(data.trainerHeader) ~= "function" then
      return nil
    end
    if type(label) ~= "string" then return nil end

    local read, header = pcall(data.trainerHeader, data, label, def.index)
    if not read or type(header) ~= "table" or not header.after then return nil end
    local text = data.text and data.text[header.after]
    return type(text) == "string" and text or nil
  end

  -- ------- the battle
  --
  -- No `checkpointOrigin`, and that is load-bearing rather than an omission.
  -- The restore path keys on `kind == "trainer_encounter"` and re-runs the
  -- whole first-win branch on the battle it brings back -- defeatedTrainers,
  -- the event flag, checkVictoryRewards (OverworldController.lua:4744-4752).
  -- A rematch restored through it would hand out the badge a second time.
  -- With no origin the checkpoint simply does not restore this battle, which
  -- is the failure worth having.
  local function build(npc)
    local game = mod.world and mod.world.game
    local def = npc.def
    local made, BattleState = pcall(require, "src.battle.BattleState")
    if not made or type(BattleState) ~= "table" then return nil end
    local built, battle = pcall(BattleState.newTrainer, game, def.trainerClass,
                                def.trainerParty)
    if not built or type(battle) ~= "table" then
      mod.log:warn("rematch could not be started: %s", tostring(battle))
      return nil
    end
    return battle
  end

  -- Half of what this battle is about to pay, which is `baseMoney` times the
  -- level of the LAST mon in the party -- the one whose fainting runs the win
  -- branch, so the one the engine multiplies by.  Read off the built battle
  -- so a party rewritten on the way in moves the price with the prize.
  local function priceOf(battle)
    if not on("prize") then return 0 end
    local party = battle.enemyParty
    local last = type(party) == "table" and party[#party] or nil
    local base = type(battle.trainer) == "table" and battle.trainer.baseMoney
    if type(base) ~= "number" or type(last) ~= "table"
        or type(last.level) ~= "number" then
      return 0
    end
    return math.floor(base * last.level / 2)
  end

  local function startBattle(ow, battle, price, release)
    local game = mod.world and mod.world.game
    local save = game and game.save

    -- Read before anything is charged, so REMATCH PRIZE off is neutral in
    -- both directions.  Putting the money back also takes back a PAY DAY used
    -- in the rematch, which is the honest reading of the row rather than a
    -- hole in it: this fight pays nothing.
    local purse = (not on("prize")) and save and save.money or nil

    if price > 0 and save then save.money = save.money - price end

    battle.onFinish = function(result)
      if result == "win" and purse and save then save.money = purse end
      ow:afterBattle(result, battle)
      release()
    end
    ow:pushBattle(battle)
  end

  local function offer(ow, npc, release)
    local game = mod.world and mod.world.game
    local ok, TextBox = pcall(require, "src.render.TextBox")
    if not ok or type(TextBox) ~= "table" then return release() end

    -- Built here rather than after the YES, because the price cannot be
    -- quoted until the party is known and nobody should be charged for a
    -- number they were not shown.  A NO throws it away; see the note at the
    -- top about what that costs.
    local battle = build(npc)
    if not battle then return release() end

    local price = priceOf(battle)
    local purse = (game.save and game.save.money) or 0
    if price > purse then
      return game.stack:push(TextBox.new(game, say(BROKE), release))
    end

    -- A free rematch is not quoted a price of nothing.
    local ask = price > 0 and say(PRICED):format(price) or say(ASK)
    game.stack:push(TextBox.new(game, ask, nil, {
      choice = function(yes)
        if not yes then return release() end
        startBattle(ow, battle, price, release)
      end,
    }))
  end

  -- ------- the A press on a beaten trainer
  --
  -- `world.talk` is the A press on an object before the map's text tables get
  -- it, and a wrap that does not call next() owns the interaction.  This one
  -- owns exactly the case the engine would have spent on a single TextBox,
  -- and reproduces it: freeze the object, turn it to face you, print the
  -- line.  Everything else -- every trainer still standing, every non-trainer,
  -- every trainer with nothing to say -- goes straight through.
  mod.hooks:wrap("world.talk", function(next, ow, npc)
    if not on("enabled") then return next(ow, npc) end

    local line = afterLine(ow, npc)
    if not line then return next(ow, npc) end

    local game = mod.world and mod.world.game
    local ok, TextBox = pcall(require, "src.render.TextBox")
    if not ok or type(TextBox) ~= "table" or not (game and game.stack) then
      return next(ow, npc)
    end

    -- talkTo freezes the object it is talking to and thaws it on the way out
    -- (OverworldController.lua:3048-3049).  This holds the freeze all the way
    -- through the prompt and the battle instead, so a trainer cannot walk off
    -- mid-conversation with their own rematch.
    npc.frozen = true
    local released = false
    local function release()
      if released then return end
      released = true
      npc.frozen = false
    end
    if ow.player and type(npc.facePlayer) == "function" then
      pcall(npc.facePlayer, npc, ow.player)
    end

    game.stack:push(TextBox.new(game, line, function()
      -- Whichever button closed the box is still this frame's press.  B is a
      -- way out that costs nothing and asks nothing, which is the point: the
      -- prompt only ever appears for someone who read to the end and pressed
      -- on.  Checked before A rather than after, so a frame carrying both is
      -- read as the cancel.
      local input = game.input
      if input and input.wasPressed and input:wasPressed("b") then
        return release()
      end
      offer(ow, npc, release)
    end))
  end)
end
