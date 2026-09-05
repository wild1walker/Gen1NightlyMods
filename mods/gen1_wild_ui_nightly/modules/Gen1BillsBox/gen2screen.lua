-- Gen1BillsBox on Gold: the same box, over Gold's storage.
--
-- Returns a factory: factory(mod) -> a screen table registered as an override
-- for `Gen2BoxMenu`.
--
-- ------- why this exists at all, when Gold's PC is already better than Red's
--
-- The feature stood down on Gen 2 for six releases on the grounds that "Gold
-- already has the screen this builds".  That was too generous by half, and it
-- is worth writing down what Gold actually has, because the difference is the
-- whole of this file.
--
-- `src/ui/gen2/BoxMenu.lua` is a transcription of `engine/pokemon/bills_pc.asm`
-- and it is a LIST: `.PlaceNickname` writes five nicknames from (9,4), two
-- rows apart, with a left panel carrying the front pic, the level, the gender
-- and the species of whichever one the cursor is on.  It is a good list.  It
-- is not a box: there is no grid, the party is not on screen beside it, and
-- moving a POKeMON is a four-step modal flow (`.PrepSubmenu` ->
-- `.MoveMonWOMailSubmenu` -> `.PrepInsertCursor` -> `.Joypad2`) reached from
-- a third entry on the PC menu.
--
-- What this mod builds for Red -- the party down the left, the open box as a
-- grid on the right, and a cursor that picks a POKeMON up and puts it down --
-- is exactly what neither game shipped.  So it is built here too, and it
-- REPLACES the list: `override("Gen2BoxMenu")` is the id `PcMenu` pushes for
-- all three of WITHDRAW, DEPOSIT and MOVE POKeMON, so the three verbs land on
-- one screen and there is no second entrance left to fall out of step with
-- the save.
--
-- ------- and every write is the cart's
--
-- This is the one screen in the suite where a mistake loses a POKeMON, so
-- nothing here invents a rule or writes a save field directly.  The refusals
-- and the side effects are `src/core/gen2/Boxes.lua`'s, which is the cart's:
--
--   canDeposit   the box is full / this is your last healthy POKeMON / it is
--                holding MAIL, whose letter has nowhere to live in a box
--                (sPartyMail is six structs keyed by PARTY SLOT)
--   enterBox     RestorePPOfDepositedPokemon, then status cleared and HP
--                refilled from MAXHP, because box_struct has no MON_STATUS
--                and no MON_HP
--   canWithdraw  the party is full
--   removeSlot   every letter behind a departing party mon moves up one
--
-- The one thing this screen does that the cart has no call for is SWAP -- a
-- POKeMON in hand landing on an occupied cell -- and the rules for it are
-- derived from the two above rather than guessed: a swap moves one mon each
-- way, so the box cannot overflow and the party cannot shrink, which is why
-- the capacity halves of both checks are the two that do not apply.  What
-- does apply is what a whiteout depends on: the party must still hold a
-- healthy POKeMON when the dust settles.
--
-- ------- the geometry is Red's, to the pixel
--
-- Both games draw 160x144, so the layout is not re-derived: a 5x4 grid of
-- 24x24 cells at (32,24), the party's icons at x=8 stepping 16 from y=24, and
-- the hairline between the two panes at x=28.  A player who knows this screen
-- on one cart knows it on the other.

return function(mod)
  local Boxes = require("src.core.gen2.Boxes")
  local Chrome = require("src.ui.gen2.Chrome")
  local Mail = require("src.core.gen2.Mail")
  local PartyMenu = require("src.ui.gen2.PartyMenu")
  local Strings = require("src.core.Strings")

  local Screen = {}
  Screen.__index = Screen
  Screen.isOpaque = true

  -- ------- layout, Red's own (modules/Gen1BillsBox/screen.lua)

  local COLS, ROWS = 5, 4
  local CELL_W, CELL_H = 24, 24
  local GRID_X, GRID_Y = 32, 24
  local SLOTS = COLS * ROWS

  local PARTY_ROWS = 6
  local PARTY_H = 16
  local PARTY_X, PARTY_Y = 8, 24
  local RULE_X = 28

  local ICON = 16
  local ICON_DX = math.floor((CELL_W - ICON) / 2)
  -- Not vertically centred, and deliberately: the column holds a gap, the
  -- 4-pixel cursor, a gap, the icon and a gap in 23 pixels.  Spending the
  -- three spare anywhere but 1/1/1 takes an end gap to zero, and an arrow
  -- with no gap above it is drawn ON the rule.  See Red's screen.lua.
  local ICON_DY = 7
  local ARROW_DX = ICON_DX + math.floor((ICON - 7) / 2)
  local ARROW_DY = 2

  local HEADER_TH = 3
  local INFO_TY = 15

  local REPEAT_DELAY, REPEAT_RATE = 16, 5
  local FLASH_PERIOD, FLASH_ON = 24, 16
  local TICKS = 240

  local function option(key, fallback)
    local ok, value = pcall(function() return mod.options:get(key) end)
    if not ok or value == nil then return fallback end
    return value
  end

  -- ------- drawing primitives
  --
  -- Through Chrome rather than Font, so UI THEME reaches this screen the way
  -- it reaches every other Gold page: the box palette is rewritten in place
  -- once a frame and `Chrome.box` / `Chrome.printThrough` read it at call
  -- time.  The rules and the cursor are the one thing drawn by hand, and they
  -- take the palette's INK so they go light on a dark page with the text.

  local function palette()
    return Chrome.DEFAULT_BOX_PALETTE
  end

  local function inkColor()
    local pal = palette()
    local ink = type(pal) == "table" and pal[4]
    if type(ink) ~= "table" then return 0, 0, 0 end
    return (ink[1] or 0) / 255, (ink[2] or 0) / 255, (ink[3] or 0) / 255
  end

  local function line(x, y, w, h)
    local r, g, b, a = love.graphics.getColor()
    local ir, ig, ib = inkColor()
    love.graphics.setColor(ir, ig, ib, 1)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(r, g, b, a)
  end

  -- A solid triangle, and the same triangle hollow while a POKeMON is in
  -- hand.  Drawn rather than printed because the charmap has a down arrow but
  -- no hollow twin of it -- the hollow/filled PAIR only exists sideways.
  --
  -- Two directions, and which one goes where is not decoration.  The grid
  -- points DOWN because a cell has a band above the icon to point from.  The
  -- party points RIGHT, because six rows of sixteen fill the pane's
  -- ninety-six pixels exactly and there is no band above a party POKeMON's
  -- head to put an arrow in -- and because a column of entries with the
  -- cursor to their left is the party menu's own idiom on both games.  The
  -- first cut of this screen used the down arrow for both and it read as
  -- pointing at nothing.
  local ARROW_LONG, ARROW_SHORT = 7, 4

  local function arrow(x, y, dir, hollow)
    local r, g, b, a = love.graphics.getColor()
    local ir, ig, ib = inkColor()
    love.graphics.setColor(ir, ig, ib, 1)
    for i = 0, ARROW_SHORT - 1 do
      local span = ARROW_LONG - i * 2
      local whole = not hollow or span <= 2 or i == 0
      if dir == "down" then
        if whole then
          love.graphics.rectangle("fill", x + i, y + i, span, 1)
        else
          love.graphics.rectangle("fill", x + i, y + i, 1, 1)
          love.graphics.rectangle("fill", x + i + span - 1, y + i, 1, 1)
        end
      else
        -- the same triangle a quarter turn round: columns instead of rows
        local px = dir == "right" and (x + i) or (x + ARROW_SHORT - 1 - i)
        if whole then
          love.graphics.rectangle("fill", px, y + i, 1, span)
        else
          love.graphics.rectangle("fill", px, y + i, 1, 1)
          love.graphics.rectangle("fill", px, y + i + span - 1, 1, 1)
        end
      end
    end
    love.graphics.setColor(r, g, b, a)
  end

  -- ------- what the save holds

  local function partyOf(save) return (save and save.party) or {} end

  local function boxList(save, index) return Boxes.box(save, index) end

  local function nameOf(screen, mon)
    if not mon then return "" end
    if mon.isEgg then return Strings("EGG") end
    if mon.nickname and mon.nickname ~= "" then return mon.nickname end
    local data = screen.game and screen.game.data
    local def = data and data.pokemon and data.pokemon[mon.species]
    return (def and def.name) or tostring(mon.species or "?")
  end

  -- ------- moving a POKeMON, through the cart's own rules
  --
  -- `intoBox` and `intoParty` are the two tails the cart runs at each end of
  -- a move: a mon entering storage has its PP restored and its status and HP
  -- reset from MAXHP, and one entering the party is healed the same way the
  -- withdraw arm heals it.  Both are Boxes' own, called rather than copied.

  local function intoBox(mon) return Boxes.enterBox(mon) end

  local function intoParty(mon)
    if not mon then return mon end
    mon.status = nil
    mon.statusTurns = nil
    if mon.isEgg then mon.hp = 0 else mon.hp = mon.maxHp or mon.hp end
    return mon
  end

  local function healthyAfter(party, leaving, arriving)
    local n = 0
    for _, mon in ipairs(party) do
      if mon ~= leaving and (mon.hp or 0) > 0 then n = n + 1 end
    end
    -- A boxed POKeMON arrives healed, so it counts unless it is an egg.
    if arriving and not arriving.isEgg then n = n + 1 end
    return n
  end

  -- ------- the screen

  function Screen.new(game, opts)
    opts = opts or {}
    local self = setmetatable({}, Screen)
    self.game = game
    self.save = opts.save or (game and game.save)
    self.mode = opts.mode or "withdraw"
    self.onClose = opts.onClose
    self.boxIndex = (self.save and self.save.currentBox) or 1
    self.pane = option("startPane", "box") == "party" and "party" or "box"
    -- Which pane the header was reached FROM, so DOWN goes back to it.
    self.lastPane = self.pane
    self.boxSlot = 1
    self.partySlot = 1
    self.held = nil
    self.ticks = 0
    self.hold = nil
    self.message = nil
    -- The engine's own party-menu icon path, so per-species icons, the
    -- `pokemon.icon` hook and any icon replacement mod land in the box
    -- exactly as they land in the party.  Built with an empty party: it is
    -- used as a renderer, never as a list.
    local ok, icons = pcall(PartyMenu.new, game, { party = {}, save = self.save })
    self.icons = ok and icons or nil
    return self
  end

  function Screen:say(text)
    self.message = text
  end

  function Screen:close()
    -- A POKeMON in hand goes back where it came from rather than out of the
    -- save with the screen.
    self:returnHeld()
    if self.save then self.save.currentBox = self.boxIndex end
    if self.onClose then self.onClose() end
  end

  -- ------- what is in each cell
  --
  -- A box is a COMPACT array, so cells 1..count hold POKeMON and the rest are
  -- empty.  The one exception is the cell a carried POKeMON came out of: it
  -- stays empty for as long as the POKeMON is in hand, so the grid does not
  -- close up under the cursor as you lift something out of the middle of it.

  function Screen:boxCells(index)
    local list = boxList(self.save, index)
    local cells, at = {}, 1
    local hole = nil
    local held = self.held
    if held and held.from == "box" and held.box == index then hole = held.cell end
    for cell = 1, SLOTS do
      if cell == hole then
        cells[cell] = nil
      else
        cells[cell] = list[at]
        if list[at] then at = at + 1 end
      end
    end
    return cells
  end

  -- The compact index a cell stands for, which is what the cart's own calls
  -- take.  nil for an empty cell.
  function Screen:boxIndexAt(index, cell)
    local list = boxList(self.save, index)
    local at = 1
    local hole = nil
    local held = self.held
    if held and held.from == "box" and held.box == index then hole = held.cell end
    for c = 1, SLOTS do
      if c ~= hole then
        if c == cell then return list[at] and at or nil end
        if list[at] then at = at + 1 end
      elseif c == cell then
        return nil
      end
    end
    return nil
  end

  function Screen:partyCells()
    local party = partyOf(self.save)
    local cells, at = {}, 1
    local hole = nil
    local held = self.held
    if held and held.from == "party" then hole = held.row end
    for row = 1, PARTY_ROWS do
      if row == hole then
        cells[row] = nil
      else
        cells[row] = party[at]
        if party[at] then at = at + 1 end
      end
    end
    return cells
  end

  function Screen:partyIndexAt(row)
    local party = partyOf(self.save)
    local at = 1
    local hole = nil
    local held = self.held
    if held and held.from == "party" then hole = held.row end
    for r = 1, PARTY_ROWS do
      if r ~= hole then
        if r == row then return party[at] and at or nil end
        if party[at] then at = at + 1 end
      elseif r == row then
        return nil
      end
    end
    return nil
  end

  function Screen:monUnder()
    if self.pane == "party" then
      return self:partyCells()[self.partySlot]
    end
    return self:boxCells(self.boxIndex)[self.boxSlot]
  end

  -- ------- picking up

  function Screen:grab()
    if self.held then return end
    if self.pane == "party" then
      local row = self.partySlot
      local index = self:partyIndexAt(row)
      local party = partyOf(self.save)
      local mon = index and party[index]
      if not mon then return end
      -- Refused at the PICK-UP rather than at the drop, which is what makes
      -- the rule impossible to walk around: with one POKeMON in the party
      -- there is nothing to reorder either.
      if #party <= 1 then
        return self:say(Strings("You can't deposit\nthe last POKéMON!"))
      end
      if Mail.monHoldsMail(mon) then
        return self:say(Strings("Remove MAIL."))
      end
      table.remove(party, index)
      Mail.removeSlot(self.save, index)
      self.held = { mon = mon, from = "party", row = row }
      return
    end
    local index = self:boxIndexAt(self.boxIndex, self.boxSlot)
    if not index then return end
    local mon = table.remove(boxList(self.save, self.boxIndex), index)
    self.held = { mon = mon, from = "box", box = self.boxIndex,
                  cell = self.boxSlot }
  end

  -- ------- putting down
  --
  -- Everything is asked BEFORE anything moves, so a refusal leaves the
  -- POKeMON in hand rather than half-placed.

  function Screen:refuse(pane, target)
    local held = self.held
    local mon = held.mon
    local party = partyOf(self.save)
    if pane == "box" and held.from == "party" then
      if Mail.monHoldsMail(mon) then return Strings("Remove MAIL.") end
      if not target and Boxes.isFull(self.save, self.boxIndex) then
        return Strings("The BOX is full.")
      end
      if healthyAfter(party, nil, target) < 1 then
        return Strings("You can't deposit\nthe last POKéMON!")
      end
    elseif pane == "party" and held.from == "box" then
      -- No "the party is full" arm, and its absence is the point rather than
      -- an omission: an empty party ROW only exists while the party is short
      -- of six, so a drop onto one can never be the seventh POKeMON.  A full
      -- party leaves only occupied rows, and every one of those is a SWAP --
      -- one in, one out, so the party is the same size afterwards.
      if target and Mail.monHoldsMail(target) then
        return Strings("Remove MAIL.")
      end
      if target and healthyAfter(party, target, mon) < 1 then
        return Strings("You can't deposit\nthe last POKéMON!")
      end
    elseif pane == "box" and held.from == "box"
        and not target and Boxes.isFull(self.save, self.boxIndex) then
      return Strings("The BOX is full.")
    end
    return nil
  end

  function Screen:place()
    local held = self.held
    if not held then return end
    local pane = self.pane
    local party = partyOf(self.save)

    local target, targetIndex
    if pane == "party" then
      targetIndex = self:partyIndexAt(self.partySlot)
      target = targetIndex and party[targetIndex]
    else
      targetIndex = self:boxIndexAt(self.boxIndex, self.boxSlot)
      target = targetIndex and boxList(self.save, self.boxIndex)[targetIndex]
    end

    local refusal = self:refuse(pane, target)
    if refusal then return self:say(refusal) end

    -- The carried POKeMON lands first, then the one it displaced goes back to
    -- where the carried one came from.
    if target then
      if pane == "party" then
        party[targetIndex] = intoParty(held.mon)
      else
        boxList(self.save, self.boxIndex)[targetIndex] = intoBox(held.mon)
      end
      local sent = target
      if held.from == "party" then
        table.insert(party, math.min(held.row, #party + 1), intoParty(sent))
      else
        local list = boxList(self.save, held.box)
        table.insert(list, math.min(held.cell, #list + 1), intoBox(sent))
      end
    else
      if pane == "party" then
        party[#party + 1] = intoParty(held.mon)
      else
        local list = boxList(self.save, self.boxIndex)
        list[#list + 1] = intoBox(held.mon)
      end
    end
    self.held = nil
    if option("placeCry", true) then
      pcall(function()
        require("src.core.Sound").playCry(self.game.data,
          (target or held.mon).species)
      end)
    end
  end

  function Screen:returnHeld()
    local held = self.held
    if not held then return end
    self.held = nil
    if held.from == "party" then
      local party = partyOf(self.save)
      if #party < Boxes.PARTY_SIZE then
        table.insert(party, math.min(held.row, #party + 1), intoParty(held.mon))
        return
      end
    end
    local list = boxList(self.save, held.box or self.boxIndex)
    if #list < Boxes.MONS_PER_BOX then
      table.insert(list, math.min(held.cell or (#list + 1), #list + 1),
                   intoBox(held.mon))
      return
    end
    -- Nowhere it came from and nowhere beside it: the first box with room.
    -- A POKeMON is never dropped on the floor.
    for index = 1, Boxes.NUM_BOXES do
      if not Boxes.isFull(self.save, index) then
        local other = boxList(self.save, index)
        other[#other + 1] = intoBox(held.mon)
        return
      end
    end
    local party = partyOf(self.save)
    party[#party + 1] = intoParty(held.mon)
  end

  -- ------- moving about

  function Screen:changeBox(delta)
    local index = self.boxIndex + delta
    if index < 1 then index = Boxes.NUM_BOXES end
    if index > Boxes.NUM_BOXES then index = 1 end
    self.boxIndex = index
    if self.save then self.save.currentBox = index end
  end

  -- The header is a stop on the way round rather than a wall: UP out of the
  -- top of either pane lands on it, DOWN goes back where it came from, and UP
  -- again wraps past it to the bottom of that pane.  Box changes live here,
  -- beside the name and the count they change, rather than on a shortcut --
  -- which is what makes them visible.
  function Screen:moveHeader(dir)
    if dir == "left" then
      self:changeBox(-1)
    elseif dir == "right" then
      self:changeBox(1)
    elseif dir == "down" then
      self.pane = self.lastPane
    elseif dir == "up" then
      if self.lastPane == "party" then
        self.partySlot = PARTY_ROWS
        self.pane = "party"
      else
        self.boxSlot = (ROWS - 1) * COLS + ((self.boxSlot - 1) % COLS) + 1
        self.pane = "box"
      end
    end
  end

  function Screen:move(dir)
    if self.pane == "header" then return self:moveHeader(dir) end
    if self.pane == "party" then
      if dir == "up" then
        if self.partySlot == 1 then
          self.lastPane = "party"
          self.pane = "header"
        else
          self.partySlot = self.partySlot - 1
        end
      elseif dir == "down" then
        self.partySlot = self.partySlot < PARTY_ROWS and self.partySlot + 1 or 1
      elseif dir == "right" then
        self.pane = "box"
      end
      return
    end
    local col = (self.boxSlot - 1) % COLS
    local row = math.floor((self.boxSlot - 1) / COLS)
    if dir == "left" then
      if col == 0 then self.pane = "party" return end
      col = col - 1
    elseif dir == "right" then
      -- the party is off the left edge, so the right edge wraps within the
      -- row rather than stepping to the next box: box changes belong to the
      -- header, where they are visible
      col = col == COLS - 1 and 0 or col + 1
    elseif dir == "up" then
      if row == 0 then
        self.lastPane = "box"
        self.pane = "header"
        return
      end
      row = row - 1
    elseif dir == "down" then
      row = row < ROWS - 1 and row + 1 or 0
    end
    self.boxSlot = row * COLS + col + 1
  end

  -- ------- the actions pop-up
  --
  -- START on Red opens the verbs the vanilla PC put on its own menu -- STATS,
  -- and RELEASE for a boxed POKeMON.  The first cut of this arm made START
  -- CLOSE the screen, which is both wrong and the one thing a player will hit
  -- by accident: reported as "clicking start closes the box instead of giving
  -- me my options".  B is the way out and always was.
  --
  -- Drawn here rather than pushed as a screen because it is modal over this
  -- one: a pop-up that owned the stack would take the box off the display
  -- behind it, and the whole point of the verbs is that you can still see
  -- what they are about.
  local function actionsFor(screen)
    local mon = (not screen.held) and screen:monUnder() or nil
    if not mon then return nil end
    local items = { { label = Strings("STATS"), id = "stats" } }
    if screen.pane == "box" then
      items[#items + 1] = { label = Strings("RELEASE"), id = "release" }
    end
    items[#items + 1] = { label = Strings("CANCEL"), id = "cancel" }
    return items
  end

  -- ------- sorting a box, and one step back
  --
  -- Red's box has a SAVED cell layout: a gap you left in it is a decision, so
  -- every sort there ends by closing the box up into cells 1..n and COLLAPSE
  -- is the sort that only does that.  Gold's box is a COMPACT array -- the
  -- cart's own Boxes.lua keeps it that way and the only hole this screen ever
  -- shows is the transient one under a POKeMON in hand -- so there is nothing
  -- to collapse, and COLLAPSE is not on the menu.  It is not a feature that
  -- was dropped; it is a feature Gold's storage does not have a use for.
  --
  -- Everything else is Red's, key for key, including the tie-break: table.sort
  -- is not stable, so the position each POKeMON is already in is carried
  -- alongside and used as the last word.  POKeMON that tie keep the order
  -- somebody is looking at.
  local SORT_LABELS = {
    { "BY DEX", "dex" },
    { "BY LEVEL", "level" },
    { "BY NAME", "name" },
    { "BY TYPE", "type" },
  }

  local function sortKey(screen, mode, entry)
    local mon = entry.mon
    local data = screen.game and screen.game.data
    local def = data and data.pokemon and data.pokemon[mon.species]
    if mode == "dex" then return (def and def.dex) or math.huge end
    -- strongest first, which is what a box is usually being tidied for
    if mode == "level" then return -(tonumber(mon.level) or 0) end
    if mode == "name" then return nameOf(screen, mon) end
    -- the primary type, alphabetically: the data carries type names rather
    -- than the cart's numbering, so there is no other order to honour
    if mode == "type" then
      local types = def and def.types
      return tostring(types and types[1] or "")
    end
    return entry.at
  end

  -- Is this box still holding exactly the POKeMON the snapshot was taken of?
  -- Identity, not count: one released and one deposited leaves the count alone
  -- and would otherwise let UNDO resurrect the released one.
  local function sameMembers(list, snapshot)
    if #list ~= #snapshot then return false end
    local left = {}
    for _, mon in ipairs(snapshot) do left[mon] = (left[mon] or 0) + 1 end
    for _, mon in ipairs(list) do
      local n = left[mon]
      if not n or n == 0 then return false end
      left[mon] = n - 1
    end
    return true
  end

  function Screen:sortBox(mode)
    local list = boxList(self.save, self.boxIndex)
    if not list or #list < 2 then return end

    -- One step, and only for this box: changing box while a snapshot is held
    -- would otherwise offer to restore another box's order.
    local snapshot = { box = self.boxIndex, mons = {} }
    for j = 1, #list do snapshot.mons[j] = list[j] end

    local order = {}
    for j = 1, #list do order[j] = { mon = list[j], at = j } end
    for _, entry in ipairs(order) do
      entry.key = sortKey(self, mode, entry)
    end
    table.sort(order, function(a, b)
      if a.key ~= b.key then return a.key < b.key end
      return a.at < b.at
    end)

    for j = 1, #order do list[j] = order[j].mon end
    self.sortUndo = snapshot
  end

  function Screen:canUndoSort()
    local undo = self.sortUndo
    if not undo or undo.box ~= self.boxIndex then return false end
    local list = boxList(self.save, undo.box)
    return list ~= nil and sameMembers(list, undo.mons)
  end

  function Screen:undoSort()
    if not self:canUndoSort() then return end
    local undo = self.sortUndo
    self.sortUndo = nil
    local list = boxList(self.save, undo.box)
    for j = 1, #undo.mons do list[j] = undo.mons[j] end
  end

  -- SELECT over the box.  Refused with a POKeMON in hand, because a sort that
  -- reordered the box around one that is not in it reads as the box shuffling
  -- itself for no reason.
  --
  -- SELECT rather than another row on START's menu, which is where Red puts
  -- it: START's rows are what you do to ONE POKeMON and a sort is what you do
  -- to the box.  SELECT was a third way to change box here -- L, R and the
  -- header's LEFT/RIGHT are the other two and all of them stay -- so nothing
  -- is lost by giving it the job it has on Red.
  function Screen:openSort()
    if self.held or self.pane == "header" then return end
    local list = boxList(self.save, self.boxIndex)
    if not list or #list < 2 then
      return self:say(Strings("There is nothing\nto sort."))
    end
    local items = {}
    for _, row in ipairs(SORT_LABELS) do
      items[#items + 1] = { label = Strings(row[1]), id = row[2] }
    end
    if self:canUndoSort() then
      items[#items + 1] = { label = Strings("UNDO"), id = "undo" }
    end
    items[#items + 1] = { label = Strings("CANCEL"), id = "cancel" }
    self.sortMenu = { items = items, index = 1 }
  end

  function Screen:chooseSort(id)
    self.sortMenu = nil
    if not id or id == "cancel" then return end
    if id == "undo" then return self:undoSort() end
    self:sortBox(id)
  end

  function Screen:openActions()
    if self.held or self.pane == "header" then return end
    local items = actionsFor(self)
    if not items then return end
    self.actions = { items = items, index = 1 }
  end

  function Screen:openStats()
    local mon = self:monUnder()
    if not mon then return end
    local game = self.game
    if not (game and game.stack) then return end
    local ok, Screens = pcall(require, "src.ui.Screens")
    if not (ok and type(Screens) == "table") then return end
    -- The cart's own summary, exactly as its BoxMenu opens one.
    if not pcall(Screens.get, game, "Gen2SummaryMenu") then return end
    pcall(Screens.push, game, "Gen2SummaryMenu", {
      mon = mon, save = self.save,
      onClose = function() game.stack:pop() end,
    })
  end

  -- RELEASE is the one thing on this screen that destroys a POKeMON, so it
  -- asks first and NO is where the cursor starts -- the same defaultNo the
  -- cart's own QUIT box uses, and for the same reason.
  function Screen:askRelease()
    local mon = self:monUnder()
    if not (mon and self.pane == "box") then return end
    self.confirm = { mon = mon, choice = 2,
                     text = Strings("Release this\nPOKéMON?") }
  end

  function Screen:doRelease()
    local index = self:boxIndexAt(self.boxIndex, self.boxSlot)
    if not index then return end
    local ok = Boxes.release(self.save, self.boxIndex, index)
    if not ok then return end
    self:say(Strings("Released."))
  end

  function Screen:chooseAction(id)
    self.actions = nil
    if id == "stats" then return self:openStats() end
    if id == "release" then return self:askRelease() end
  end

  -- ------- input

  local DIRECTIONS = { "up", "down", "left", "right" }

  function Screen:update(_dt)
    self.ticks = (self.ticks + 1) % TICKS
    if self.icons then self.icons.clock = (self.icons.clock or 0) + 1 end
    local input = self.game and self.game.input
    if not input then return end

    if self.message then
      if input:wasPressed("a") or input:wasPressed("b") then
        self.message = nil
      end
      return
    end

    if self.confirm then
      if input:wasPressed("up") or input:wasPressed("down") then
        self.confirm.choice = self.confirm.choice == 1 and 2 or 1
      elseif input:wasPressed("a") then
        local yes = self.confirm.choice == 1
        self.confirm = nil
        if yes then self:doRelease() end
      elseif input:wasPressed("b") then
        self.confirm = nil
      end
      return
    end

    if self.sortMenu then
      local list = self.sortMenu
      if input:wasPressed("up") then
        list.index = list.index > 1 and list.index - 1 or #list.items
      elseif input:wasPressed("down") then
        list.index = list.index < #list.items and list.index + 1 or 1
      elseif input:wasPressed("a") then
        local item = list.items[list.index]
        self:chooseSort(item and item.id)
      elseif input:wasPressed("b") or input:wasPressed("select") then
        self.sortMenu = nil
      end
      return
    end

    if self.actions then
      local list = self.actions
      if input:wasPressed("up") then
        list.index = list.index > 1 and list.index - 1 or #list.items
      elseif input:wasPressed("down") then
        list.index = list.index < #list.items and list.index + 1 or 1
      elseif input:wasPressed("a") then
        local item = list.items[list.index]
        self:chooseAction(item and item.id)
      elseif input:wasPressed("b") or input:wasPressed("start") then
        self.actions = nil
      end
      return
    end

    for _, dir in ipairs(DIRECTIONS) do
      if input:wasPressed(dir) then
        self.hold = { dir = dir, at = 0 }
        self:move(dir)
      end
    end
    -- Hold to keep moving, at ui.list_menu's own cadence, so a held direction
    -- here moves at the speed a held direction moves everywhere else.
    if self.hold and option("holdMove", true) then
      local down = input.isDown and input:isDown(self.hold.dir)
      if down then
        self.hold.at = self.hold.at + 1
        if self.hold.at >= REPEAT_DELAY
            and (self.hold.at - REPEAT_DELAY) % REPEAT_RATE == 0 then
          self:move(self.hold.dir)
        end
      else
        self.hold = nil
      end
    end

    if input:wasPressed("l") then self:changeBox(-1) end
    if input:wasPressed("r") then self:changeBox(1) end
    if input:wasPressed("select") then self:openSort() end

    if input:wasPressed("a") then
      -- A on the header is not a grab: there is nothing under it to pick up,
      -- and LEFT/RIGHT are what it is for.
      if self.pane == "header" then return end
      if self.held then self:place() else self:grab() end
    elseif input:wasPressed("b") then
      if self.held then self:returnHeld() else self:close() end
    elseif input:wasPressed("start") then
      self:openActions()
    end
  end

  -- ------- drawing

  function Screen:drawHeader()
    Chrome.box(0, 0, 20, HEADER_TH)
    -- The two box arrows and the selector between them: same shape, same
    -- height, same row, so they line up by construction rather than by luck.
    arrow(8, 8, "left")
    arrow(148, 8, "right")
    if self.pane == "header" then arrow(16, 8, "right") end
    local name = Boxes.name(self.save, self.boxIndex)
    Chrome.printThrough(tostring(name), 3, 1, palette())
    local count = Boxes.count(self.save, self.boxIndex)
    Chrome.printRightThrough(("%d/%d"):format(count, Boxes.MONS_PER_BOX),
                             18, 1, palette())
  end

  function Screen:drawParty()
    local cells = self:partyCells()
    for row = 1, PARTY_ROWS do
      local mon = cells[row]
      local y = PARTY_Y + (row - 1) * PARTY_H
      if mon and self.icons then
        pcall(self.icons.drawIcon, self.icons, mon, PARTY_X, y)
      end
      if self.pane == "party" and self.partySlot == row then
        -- In the gutter to the LEFT of the icon, pointing at it: six rows of
        -- sixteen fill the pane exactly, so there is no band above a party
        -- POKeMON's head for a down arrow to sit in.
        arrow(0, y + 4, "right", self.held ~= nil)
      end
    end
  end

  function Screen:drawGrid()
    local cells = self:boxCells(self.boxIndex)
    -- The rules first, so an icon is never drawn under one.
    for col = 0, COLS do
      line(GRID_X + col * CELL_W, GRID_Y, 1, ROWS * CELL_H)
    end
    for row = 0, ROWS do
      line(GRID_X, GRID_Y + row * CELL_H, COLS * CELL_W + 1, 1)
    end
    for cell = 1, SLOTS do
      local col = (cell - 1) % COLS
      local row = math.floor((cell - 1) / COLS)
      local x = GRID_X + col * CELL_W
      local y = GRID_Y + row * CELL_H
      local mon = cells[cell]
      if mon and self.icons then
        pcall(self.icons.drawIcon, self.icons, mon, x + ICON_DX, y + ICON_DY)
      end
      if self.pane == "box" and self.boxSlot == cell then
        arrow(x + ARROW_DX, y + ARROW_DY, "down", self.held ~= nil)
      end
    end
  end

  function Screen:drawHeld()
    local held = self.held
    if not held or not self.icons then return end
    -- Lit twice as long as it is dark: the thing flashing is the thing you
    -- are trying to look at.
    if self.ticks % FLASH_PERIOD >= FLASH_ON then return end
    local x, y
    if self.pane == "header" then
      return
    elseif self.pane == "party" then
      x, y = PARTY_X, PARTY_Y + (self.partySlot - 1) * PARTY_H
    else
      local col = (self.boxSlot - 1) % COLS
      local row = math.floor((self.boxSlot - 1) / COLS)
      x = GRID_X + col * CELL_W + ICON_DX
      y = GRID_Y + row * CELL_H + ICON_DY
    end
    pcall(self.icons.drawIcon, self.icons, held.mon, x, y)
  end

  function Screen:drawInfo()
    Chrome.box(0, INFO_TY, 20, 18 - INFO_TY)
    local mon = (self.held and self.held.mon) or self:monUnder()
    if not mon then return end
    Chrome.printThrough(nameOf(self, mon), 1, INFO_TY + 1, palette())
    if not mon.isEgg then
      Chrome.printRightThrough(("<LV>%d"):format(mon.level or 1), 19,
                               INFO_TY + 1, palette())
    end
  end

  -- Hung from the bottom edge rather than centred, so the POKeMON the verbs
  -- are about stays visible above it however many rows it grows to.
  function Screen:drawActions()
    local list = self.actions
    if not list then return end
    local th = #list.items * 2 + 2
    local ty = math.max(0, 18 - th)
    Chrome.box(9, ty, 11, th)
    for i, item in ipairs(list.items) do
      local row = ty + 1 + (i - 1) * 2
      if i == list.index then
        Chrome.cursorThrough(10, row, palette())
      end
      Chrome.printThrough(tostring(item.label), 11, row, palette())
    end
  end

  -- The same widget as START's rows, headed the way the box list is headed:
  -- Chrome.box draws the border either way, and the title costs no row.
  function Screen:drawSortMenu()
    local list = self.sortMenu
    if not list then return end
    local th = #list.items * 2 + 2
    local ty = math.max(0, 18 - th)
    Chrome.box(8, ty, 12, th)
    Chrome.printThrough(" " .. Strings("SORT") .. " ", 9, ty, palette())
    for i, item in ipairs(list.items) do
      local row = ty + 1 + (i - 1) * 2
      if i == list.index then
        Chrome.cursorThrough(9, row, palette())
      end
      Chrome.printThrough(tostring(item.label), 10, row, palette())
    end
  end

  function Screen:drawConfirm()
    local confirm = self.confirm
    if not confirm then return end
    Chrome.textbox(0, 12, 18, 4)
    local first, second =
      tostring(confirm.text):match("^([^\n]*)\n?(.*)$")
    Chrome.printThrough(first or "", 1, 14, palette())
    Chrome.printThrough(second or "", 1, 16, palette())
    Chrome.box(14, 7, 6, 5)
    Chrome.printThrough(Strings("YES"), 16, 8, palette())
    Chrome.printThrough(Strings("NO"), 16, 10, palette())
    Chrome.cursorThrough(15, confirm.choice == 1 and 8 or 10, palette())
  end

  function Screen:drawPanel()
    Chrome.clear()
    self:drawHeader()
    line(RULE_X, GRID_Y, 1, ROWS * CELL_H)
    self:drawParty()
    self:drawGrid()
    self:drawHeld()
    self:drawInfo()
    self:drawActions()
    self:drawSortMenu()
    self:drawConfirm()
    if self.message then
      Chrome.textbox(0, 12, 18, 4)
      local first, second = tostring(self.message):match("^([^\n]*)\n?(.*)$")
      Chrome.printThrough(first or "", 1, 14, palette())
      Chrome.printThrough(second or "", 1, 16, palette())
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  function Screen:draw()
    self:drawPanel()
  end

  function Screen:drawWidescreen(winW, winH)
    local G = love.graphics
    Chrome.letterbox(winW, winH, 1, 1, 1)
    local scale = Chrome.fitScale(winW, winH)
    G.push()
    G.translate(Chrome.fitOrigin(winW, winH, scale))
    G.scale(scale, scale)
    self:drawPanel()
    G.pop()
  end

  Screen.SLOTS = SLOTS
  Screen.COLS = COLS
  Screen.ROWS = ROWS
  Screen.PARTY_ROWS = PARTY_ROWS

  return Screen
end
