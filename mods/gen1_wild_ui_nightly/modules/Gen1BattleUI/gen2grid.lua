-- Gen1BattleUI on Gold: the command menu as four buttons.
--
-- Returns a factory: factory(mod) -> { install, owns, geometry }.
--
-- ------- what Gold already had, and what it did not
--
-- The reason this module was Gen 1 only for its whole life is that Gold ships
-- the half of it that matters most: `BattleState:drawPanel` lays the four
-- commands out at `col = ((i - 1) % 2) * spacing` and
-- `row = floor((i - 1) / 2) * 2` (src/ui/gen2/BattleState.lua), which IS the
-- 2x2 this mod builds for Red out of Red's four-row list.  The grid was
-- already there.
--
-- What was not there is the FRAME.  Gold draws one box across the right of
-- the strip and prints four words inside it, so the grid reads as a block of
-- text; Red's arm draws four boxes, one per command, and the grid reads as
-- four buttons.  Reported as "still no updated battle ui like we have for Gen
-- 1 with the 2x2 selections" -- the selections, not the layout.
--
-- So this is the frame and only the frame:
--
--   four 10x3 boxes tiling rows 12-17, the same CLASSIC_BOXES the Gen 1 arm
--   uses, because Gold's bottom strip is the same twenty tiles by six.
--
-- ------- and nothing about what the menu DOES
--
-- `menuIndex` is still the cart's, still means what it meant, and is still
-- moved by the cart's own input handling -- which already reads this menu as
-- a 2x2.  The labels are still `BattleState:menuLabels()`, so a translation
-- keeps answering and the <PK><MN> ligature is still the ligature.  Nothing
-- is replaced: the strip is asked not to draw (battle.bottom_ui_visible) and
-- the buttons go down in the seam the engine already has for exactly this
-- (battle.overlay, which runs last, in the 160x144 space).
--
-- ------- what it stands clear of
--
-- THE MOVE MENU.  Gold's is a list with a MoveInfoBox above it that shows the
-- type and the PP of the highlighted move -- which is the thing Red's arm had
-- to build a panel for.  Two columns inside 160 pixels would cost move names
-- their width to replace something already better, so the move menu is left
-- exactly as the cart draws it.
--
-- THE CONTEST MENU.  ContestBattleMenuHeader is the same grid moved out to
-- menu_coords 2, 12 because its third label is "PARKBALL" and the count
-- PrintNum writes after it -- eleven glyphs where a 10-tile box has seven.
-- It keeps the cart's own box.
--
-- THE MESSAGE.  Gold prints "<MON> what will you do?" into the left of the
-- strip and opens the menu over the right of it.  Four buttons tile the whole
-- strip, so the prompt goes -- exactly as it goes on Red, where the same four
-- buttons cover the same box.

return function(mod)
  local Gen2 = {}

  local okChrome, Chrome = pcall(require, "src.ui.gen2.Chrome")
  if not (okChrome and type(Chrome) == "table"
          and type(Chrome.box) == "function"
          and type(Chrome.printThrough) == "function") then
    error("no src.ui.gen2.Chrome to draw the battle menu with", 0)
  end

  -- Four 10x3 boxes tiling rows 12-17.  tx..tx+9 is the box and tx / tx+9 are
  -- its border columns, so the interior is tx+1..tx+8: one tile kept for the
  -- hand and seven of label.  The hand's column is reserved whether or not
  -- the hand is in it, which is what stops the other three labels from
  -- sliding sideways as the cursor moves.
  local BOXES = { { 0, 12 }, { 10, 12 }, { 0, 15 }, { 10, 15 } }
  local BOX_W, BOX_H = 10, 3

  -- Published so a case can assert against the numbers this file draws from
  -- rather than against a screenshot, and so a mod that wants to sit beside
  -- the buttons can find out where they are.
  function Gen2.geometry()
    local cells = {}
    for i, box in ipairs(BOXES) do
      cells[i] = {
        box = { x = box[1] * 8, y = box[2] * 8, w = BOX_W * 8, h = BOX_H * 8 },
        handX = (box[1] + 1) * 8,
        labelX = (box[1] + 2) * 8,
        textY = (box[2] + 1) * 8,
        labelW = 7 * 8,
      }
    end
    return cells
  end

  local function isTop(state)
    local stack = state.game and state.game.stack
    if not (stack and stack.top) then return true end
    local ok, top = pcall(stack.top, stack)
    if not ok then return true end
    return top == state
  end

  -- Whether this frame's bottom strip is ours.  Deliberately narrow: the
  -- command menu, on top of the stack, outside a contest, with the option on.
  -- Every other phase -- above all "messages" -- is left exactly as the cart
  -- draws it, which is the whole of how dialogue takes the strip back.
  function Gen2.owns(state)
    if type(state) ~= "table" then return false end
    if state.phase ~= "menu" then return false end
    if state.contest then return false end
    if not state.battle then return false end
    if mod.options:get("command_grid") == false then return false end
    if type(state.menuLabels) ~= "function" then return false end
    local index = state.menuIndex
    if type(index) ~= "number" then return false end
    return isTop(state)
  end

  function Gen2.draw(state)
    if not Gen2.owns(state) then return end
    local labels = state:menuLabels()
    if type(labels) ~= "table" then return end
    local palette = Chrome.DEFAULT_BOX_PALETTE
    for i, box in ipairs(BOXES) do
      local tx, ty = box[1], box[2]
      Chrome.box(tx, ty, BOX_W, BOX_H)
      local label = labels[i]
      if label ~= nil then
        if i == state.menuIndex and type(Chrome.cursor) == "function" then
          Chrome.cursor(tx + 1, ty + 1)
        end
        Chrome.printThrough(tostring(label), tx + 2, ty + 1, palette)
      end
    end
  end

  function Gen2.install()
    -- next() runs first and its answer is kept: a mod that has already hidden
    -- the battle's bottom layer means it.
    mod.hooks:wrap("battle.bottom_ui_visible", function(next, state)
      local visible = next(state)
      if not Gen2.owns(state) then return visible end
      return false
    end)

    -- Draw-only, and last.  A throw here is a frame with no menu on it rather
    -- than a crash, so it is caught: there is no version of "the battle
    -- stops" that is better than "the buttons are missing and the log says
    -- why".  The priority matches the Gen 1 arm's for the same reason -- a
    -- chain is run highest-first and outermost, and this link draws AFTER
    -- next(), so the highest priority is the one drawn on top.
    mod.hooks:wrap("battle.overlay", function(next, state)
      next(state)
      local ok, problem = pcall(Gen2.draw, state)
      if not ok and mod.log and type(mod.log.warn) == "function" then
        mod.log:warn("Gen1BattleUI could not draw the battle menu: %s",
                     tostring(problem))
      end
    end, 5000)
  end

  return Gen2
end
