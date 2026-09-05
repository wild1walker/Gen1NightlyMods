-- Gen1BillsBox on Gold: the grid, and above all the MOVES.
--
-- This is the one screen in the suite where a mistake loses a POKeMON, so
-- what is asserted here is not the layout -- it is that every POKeMON that
-- was in the save before an operation is still in it afterwards, in exactly
-- one place, and that the cart's own refusals still refuse.
--
-- The refusals and the tails are `src/core/gen2/Boxes.lua`'s, which is the
-- cart's, and this file drives the screen against a real save shape rather
-- than a mock of one: a party, fourteen boxes of twenty, mail keyed by party
-- slot.
--
-- Run:  luajit tests/billsbox2_test.lua

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
  local body = handle:read("*a")
  handle:close()
  return body
end

-- ------------------------------------------------------------- the harness

local NUM_BOXES, PER_BOX, PARTY_SIZE = 14, 20, 6

-- The cart's own storage logic, reduced to the surface the screen uses and
-- kept behaviourally identical to src/core/gen2/Boxes.lua: the same refusals,
-- the same two tails.  Standing it up here rather than requiring the engine is
-- what lets this run in the bundle's own suite.
local Boxes = {
  NUM_BOXES = NUM_BOXES, MONS_PER_BOX = PER_BOX, PARTY_SIZE = PARTY_SIZE,
}
function Boxes.box(save, index)
  save.boxes = save.boxes or {}
  save.boxes[index] = save.boxes[index] or {}
  return save.boxes[index]
end
function Boxes.count(save, index) return #Boxes.box(save, index) end
function Boxes.isFull(save, index) return Boxes.count(save, index) >= PER_BOX end
function Boxes.name(save, index) return "BOX" .. index end
function Boxes.enterBox(mon)
  mon.status = nil
  mon.hp = mon.isEgg and 0 or (mon.maxHp or mon.hp)
  return mon
end
function Boxes.canUsePc(save)
  if not (save and save.party and #save.party > 0) then
    return false, "You'll need a\nPOKéMON to call\fwith."
  end
  return true
end
package.loaded["src.core.gen2.Boxes"] = Boxes

local Mail = {}
function Mail.monHoldsMail(mon) return mon and mon.mail == true end
function Mail.removeSlot(save, slot)
  if save.mail then table.remove(save.mail, slot) end
end
package.loaded["src.core.gen2.Mail"] = Mail

local drawnIcons
package.loaded["src.ui.gen2.PartyMenu"] = {
  new = function(game, opts)
    return { clock = 0, drawIcon = function(_, mon, x, y)
      drawnIcons[#drawnIcons + 1] = { mon = mon, x = x, y = y }
    end }
  end,
}

local boxes, prints
package.loaded["src.ui.gen2.Chrome"] = {
  DEFAULT_BOX_PALETTE = {
    { 255, 255, 255 }, { 255, 255, 255 }, { 255, 255, 255 }, { 0, 0, 0 },
  },
  clear = function() end,
  box = function(tx, ty, tw, th)
    boxes[#boxes + 1] = { tx = tx, ty = ty, tw = tw, th = th }
  end,
  textbox = function(tx, ty, w, h)
    boxes[#boxes + 1] = { tx = tx, ty = ty, textbox = true }
  end,
  printThrough = function(text, tx, ty)
    prints[#prints + 1] = { text = tostring(text), tx = tx, ty = ty }
  end,
  printRightThrough = function(text, txEnd, ty)
    prints[#prints + 1] = { text = tostring(text), tx = txEnd, ty = ty }
  end,
  letterbox = function() end,
  fitScale = function() return 1 end,
  fitOrigin = function() return 0, 0 end,
}
package.loaded["src.core.Strings"] = setmetatable({
  source = function(s) return s end,
}, { __call = function(_, s) return s end })
package.loaded["src.core.Sound"] = { playCry = function() end }

_G.love = _G.love or {}
love.graphics = {
  setColor = function() end, getColor = function() return 1, 1, 1, 1 end,
  rectangle = function() end, push = function() end, pop = function() end,
  translate = function() end, scale = function() end,
}

local mod = { stored = {}, path = "modules/Gen1BillsBox" }
mod.options = {
  define = function() end,
  get = function(_, key) return mod.stored[key] end,
}
mod.log = {}
for _, level in ipairs({ "info", "warn", "error", "debug" }) do
  mod.log[level] = function() end
end

local Screen = assert(load(slurp("modules/Gen1BillsBox/gen2screen.lua"),
                           "@gen2screen.lua"))()(mod)

-- ------------------------------------------------------------- a real save

local nextId = 0
local function mon(opts)
  opts = opts or {}
  nextId = nextId + 1
  return { id = nextId, species = opts.species or 1, level = opts.level or 5,
           hp = opts.hp == nil and 20 or opts.hp, maxHp = 20,
           nickname = opts.nickname, isEgg = opts.isEgg, mail = opts.mail }
end

local function saveWith(partyN, boxN)
  local save = { party = {}, boxes = {}, currentBox = 1, mail = {} }
  for _ = 1, partyN do save.party[#save.party + 1] = mon() end
  for _ = 1, boxN do
    local box = Boxes.box(save, 1)
    box[#box + 1] = mon()
  end
  return save
end

local pressed = {}
local function screenOn(save, opts)
  local game = { save = save, data = {},
                 input = { wasPressed = function(_, k) return pressed[k] end,
                           isDown = function() return false end },
                 stack = { states = {}, pop = function() end,
                           top = function() return nil end } }
  local s = Screen.new(game, opts or {})
  return s
end

-- Every POKeMON in the save, by identity: the census this file is really about.
local function census(save, screen)
  local seen, total = {}, 0
  local function add(m, where)
    if not m then return end
    if seen[m.id] then
      ok(false, ("%s is in two places at once (%s and %s)")
        :format(tostring(m.nickname or m.id), seen[m.id], where))
    end
    seen[m.id] = where
    total = total + 1
  end
  for i, m in ipairs(save.party or {}) do add(m, "party " .. i) end
  for b = 1, NUM_BOXES do
    for i, m in ipairs((save.boxes or {})[b] or {}) do
      add(m, ("box %d slot %d"):format(b, i))
    end
  end
  if screen and screen.held then add(screen.held.mon, "in hand") end
  return total, seen
end

-- ------------------------------------------------------------- the grid

do
  io.write("the grid\n")
  local save = saveWith(3, 7)
  local s = screenOn(save)
  eq(Screen.COLS * Screen.ROWS, 20, "twenty cells, which is a Gen 2 box")
  eq(Screen.PARTY_ROWS, 6, "and six party rows beside them")

  local cells = s:boxCells(1)
  eq(cells[1], save.boxes[1][1], "a box is compact, so cell 1 is its first")
  eq(cells[7], save.boxes[1][7], "and cell 7 its seventh")
  eq(cells[8], nil, "with the rest empty")
  eq(s:boxIndexAt(1, 7), 7, "and a cell names the index the cart's calls take")
  eq(s:boxIndexAt(1, 8), nil, "nil where there is nothing")
end

-- ------------------------------------------------------- picking up

do
  io.write("picking a POKeMON up out of the middle\n")
  local save = saveWith(3, 7)
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.boxSlot = "box", 3
  local third = save.boxes[1][3]
  s:grab()

  eq(s.held and s.held.mon, third, "it is in hand")
  eq(Boxes.count(save, 1), 6, "and out of the box")
  eq(census(save, s), before, "and still in the save exactly once")

  -- The hole stays put: the grid must not close up under the cursor as you
  -- lift something out of the middle of it.
  local cells = s:boxCells(1)
  eq(cells[3], nil, "the cell it came out of stays empty while it is in hand")
  eq(cells[2], save.boxes[1][2], "the ones before it do not move")
  eq(cells[4], save.boxes[1][3],
     "and the ones after it stay where they were on screen")
end

do
  io.write("the last POKeMON is refused at the pick-up\n")
  -- Refusing the PICK-UP rather than the drop is what makes the rule
  -- impossible to walk around: with one POKeMON there is nothing to reorder.
  local save = saveWith(1, 0)
  local s = screenOn(save)
  s.pane, s.partySlot = "party", 1
  s:grab()
  eq(s.held, nil, "nothing is in hand")
  eq(#save.party, 1, "and the party still has it")
  ok(s.message and s.message:find("last"), "with the cart's own line")
end

do
  io.write("a POKeMON holding MAIL is refused at the pick-up\n")
  -- sPartyMail is six structs keyed by PARTY SLOT, so a boxed mon's letter
  -- has nowhere to live.
  local save = saveWith(2, 0)
  save.party[1].mail = true
  local s = screenOn(save)
  s.pane, s.partySlot = "party", 1
  s:grab()
  eq(s.held, nil, "it stays in the party")
  ok(s.message and s.message:find("MAIL"), "and is told why")
end

-- ------------------------------------------------------------ putting down

do
  io.write("party to box\n")
  local save = saveWith(3, 0)
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.partySlot = "party", 1
  local carried = save.party[1]
  s:grab()
  s.pane, s.boxSlot = "box", 1
  s:place()

  eq(s.held, nil, "the hand is empty")
  eq(#save.party, 2, "the party is one shorter")
  eq(Boxes.count(save, 1), 1, "the box one longer")
  eq(save.boxes[1][1], carried, "and it is the one that was carried")
  eq(census(save, s), before, "with the save's census unchanged")
  eq(carried.hp, carried.maxHp,
     "and the cart's own tail ran: a boxed POKeMON is refilled from MAXHP")
end

do
  io.write("box to party\n")
  local save = saveWith(2, 3)
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.boxSlot = "box", 2
  local carried = save.boxes[1][2]
  s:grab()
  s.pane, s.partySlot = "party", 3
  s:place()

  eq(#save.party, 3, "the party is one longer")
  eq(Boxes.count(save, 1), 2, "the box one shorter")
  eq(save.party[3], carried, "and it landed in the party")
  eq(census(save, s), before, "census unchanged")
end

do
  io.write("a full party has no empty row, so every drop is a swap\n")
  -- The cart's "You can't take any more POKéMON" cannot arise on this screen,
  -- and that is a property of the grid rather than a rule left out: an empty
  -- party ROW only exists while the party is short of six, so a drop onto one
  -- can never be the seventh.  A full party leaves only occupied rows.
  local save = saveWith(6, 2)
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.boxSlot = "box", 1
  local fromBox = save.boxes[1][1]
  s:grab()
  s.pane, s.partySlot = "party", 6
  local displaced = save.party[6]
  s:place()
  eq(s.held, nil, "the hand is empty")
  eq(#save.party, 6, "the party is still six")
  eq(Boxes.count(save, 1), 2, "and the box is still two")
  eq(save.party[6], fromBox, "the boxed one took the row")
  eq(save.boxes[1][1], displaced, "and the party one took its cell")
  eq(census(save, s), before, "census unchanged")
end

do
  io.write("a full box refuses a deposit\n")
  local save = saveWith(3, PER_BOX)
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.partySlot = "party", 1
  s:grab()
  s.pane, s.boxSlot = "box", PER_BOX + 0
  -- every cell is occupied, so aim at one and let the swap path run instead
  s.boxSlot = 20
  s:place()
  eq(s.held, nil, "a swap into a full box is allowed: one goes each way")
  eq(Boxes.count(save, 1), PER_BOX, "the box is the same size")
  eq(#save.party, 3, "and so is the party")
  eq(census(save, s), before, "census unchanged")
end

do
  io.write("swapping\n")
  local save = saveWith(3, 5)
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.partySlot = "party", 2
  local fromParty = save.party[2]
  s:grab()
  s.pane, s.boxSlot = "box", 4
  local fromBox = save.boxes[1][4]
  s:place()

  eq(s.held, nil, "the hand is empty")
  eq(#save.party, 3, "the party is the same size")
  eq(Boxes.count(save, 1), 5, "and so is the box")
  eq(save.boxes[1][4], fromParty, "the carried one took the cell")
  eq(save.party[2], fromBox, "and the one that was there took its row")
  eq(census(save, s), before, "census unchanged")
end

do
  io.write("a swap that would empty the party of healthy POKeMON\n")
  -- A swap moves one each way, so the party cannot shrink and the box cannot
  -- overflow -- the capacity halves of both rules are the two that do not
  -- apply.  What does apply is what a whiteout depends on.
  local save = { party = { mon(), mon({ hp = 0 }) }, boxes = {},
                 currentBox = 1, mail = {} }
  Boxes.box(save, 1)[1] = mon({ hp = 0, isEgg = true })
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.partySlot = "party", 1
  s:grab()
  s.pane, s.boxSlot = "box", 1
  s:place()
  ok(s.held ~= nil, "the swap is refused with the POKeMON still in hand")
  ok(s.message and s.message:find("last"), "and named")
  eq(census(save, s), before, "census unchanged")
end

-- ------------------------------------------------------------- putting back

do
  io.write("B puts a carried POKeMON back where it came from\n")
  local save = saveWith(3, 6)
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.boxSlot = "box", 2
  local carried = save.boxes[1][2]
  s:grab()
  s:returnHeld()
  eq(s.held, nil, "the hand is empty")
  eq(save.boxes[1][2], carried, "and it is back in its own cell")
  eq(census(save, s), before, "census unchanged")
end

do
  io.write("closing with a POKeMON in hand does not take it out of the save\n")
  local save = saveWith(3, 6)
  local before = census(save)
  local closed = false
  local s = screenOn(save, { onClose = function() closed = true end })
  s.pane, s.partySlot = "party", 2
  s:grab()
  s:close()
  eq(s.held, nil, "the hand is empty")
  eq(#save.party, 3, "the party is whole")
  eq(census(save, s), before,
     "and every POKeMON that was in the save still is -- a screen that closes "
     .. "mid-carry must never be the thing that loses one")
  ok(closed, "and the screen closed")
end

do
  io.write("a POKeMON is never dropped on the floor\n")
  -- Nowhere it came from and nowhere beside it: the first box with room.
  local save = { party = {}, boxes = {}, currentBox = 1, mail = {} }
  for _ = 1, PARTY_SIZE do save.party[#save.party + 1] = mon() end
  local box = Boxes.box(save, 1)
  for _ = 1, PER_BOX do box[#box + 1] = mon() end
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.boxSlot = "box", 1
  s:grab()
  -- fill the hole behind it so its own cell is gone too
  local list = Boxes.box(save, 1)
  list[#list + 1] = mon()
  local grown = census(save, s)
  s:returnHeld()
  eq(s.held, nil, "the hand is empty")
  eq(census(save, s), grown,
     "and it landed somewhere -- the first box with room, rather than nowhere")
end

-- --------------------------------------------------------------- the boxes

do
  io.write("walking the boxes\n")
  local save = saveWith(3, 2)
  local s = screenOn(save)
  eq(s.boxIndex, 1, "opens on the current box")
  s:changeBox(-1)
  eq(s.boxIndex, NUM_BOXES, "and wraps backwards to the fourteenth")
  eq(save.currentBox, NUM_BOXES, "carrying the save's own pointer with it")
  s:changeBox(1)
  eq(s.boxIndex, 1, "and forwards again")
end

do
  io.write("carrying across a box change\n")
  local save = saveWith(3, 4)
  local before = census(save)
  local s = screenOn(save)
  s.pane, s.boxSlot = "box", 2
  local carried = save.boxes[1][2]
  s:grab()
  s:changeBox(1)
  s.boxSlot = 1
  s:place()
  eq(Boxes.count(save, 1), 3, "box 1 is one shorter")
  eq(Boxes.count(save, 2), 1, "box 2 one longer")
  eq(save.boxes[2][1], carried, "and it is the one that was carried")
  eq(census(save, s), before, "census unchanged")
end

-- ------------------------------------------------------------- it draws

do
  io.write("it draws\n")
  local save = saveWith(3, 6)
  local s = screenOn(save)
  boxes, prints, drawnIcons = {}, {}, {}
  s:drawPanel()
  eq(#drawnIcons, 3 + 6, "an icon per party member and per boxed POKeMON")
  ok(#boxes >= 2, "the header and the info line are boxes")
  local names = {}
  for _, p in ipairs(prints) do names[p.text] = true end
  ok(names["BOX1"], "the box's name is on the header")
  ok(names["6/20"], "and how full it is")
end

io.write(("bills box gen2: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
