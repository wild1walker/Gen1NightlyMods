-- Which frames are pages, and the one that is a page only sometimes.
--
-- The bug, from a phone screenshot of the CONTINUE menu in DARK: a black
-- CONTINUE / NEW GAME box in the top left, a black PLAYER / BADGES / POKeDEX /
-- TIME box under it, and white paper in the corners neither of them reaches.
-- The boxes were themed and the page they sit on was not.
--
-- The title screen owns its frame and is not in Theme.PAGES, quite rightly:
-- for most of its life it is the logo, the mon and the version ribbon, and
-- reversing that would be vandalism.  But `TitleState:draw` opens with a white
-- fill of the whole screen and then `if self.menuOpen then return end`
-- (TitleState.lua:711-715) -- MainMenu's own ClearScreen, which wipes the
-- logo, the mon and the sprites before the border goes down.  From the moment
-- that menu opens there is no art on that screen at all.
--
-- So it is a page WHEN SOMETHING IS STACKED ON IT and a picture when it is
-- alone.  0.24.0 made it a page in both states and three things went wrong on
-- screen; see Theme.COVERED_PAGES for what and why it is not that any more.
--
-- Run:  luajit tests/titlepage_test.lua

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
local function load_(path, ...)
  return assert(load(assert(readFile(path)), "@" .. path))(...)
end

package.loaded["src.mods.ManagerState"] = { openOptions = function() end }

-- The two engine classes this file needs to be able to name.  Resolved by
-- require inside the theme, so standing them in here is enough to be matched
-- by getmetatable, which is how Theme.PAGES works on a real boot.
local TitleState = {}; TitleState.__index = TitleState
package.loaded["src.ui.TitleState"] = TitleState
local HallOfFame = {}; HallOfFame.__index = HallOfFame

local OptionSet = load_("runtime/optionset.lua")
local Theme = load_("runtime/theme.lua")

local function themeOver()
  local stored = {}
  local mod = {
    id = "ui",
    options = { define = function() end,
                get = function(_, key) return stored[key] end,
                set = function(_, key, value) stored[key] = value end },
    log = { info = function() end, warn = function() end, error = function() end },
    hooks = { wrap = function() end },
  }
  local theme = Theme.new({ mod = mod, optionset = OptionSet.new() })
  theme.defineRow()
  theme.write("dark")
  return theme
end

local GREYS = { {255,255,255}, {170,170,170}, {85,85,85}, {0,0,0} }
local LOGO2 = { {255,255,255}, {255,200,100}, {200,100,50}, {0,0,0} }
local MEWMON = { {255,255,255}, {255,180,180}, {200,80,80}, {0,0,0} }

-- PaletteFX.zone takes tile CORNERS, not a width and a height
-- (src/render/PaletteFX.lua:217-221).
local function zone(colors, tx1, ty1, tx2, ty2)
  return { colors = colors, x = tx1 * 8, y = ty1 * 8,
           w = (tx2 - tx1 + 1) * 8, h = (ty2 - ty1 + 1) * 8 }
end

-- TitleState:sgbPalettes with the menu open: three bands across the screen,
-- then a DMG-greys zone per visible titleUiBox (TitleState.lua:68-101).
local function titleZones()
  return {
    zone(LOGO2, 0, 0, 19, 7),
    zone(LOGO2, 0, 8, 19, 9),
    zone(MEWMON, 0, 10, 19, 17),
    zone(GREYS, 0, 0, 12, 9),      -- the CONTINUE menu's box
    zone(GREYS, 4, 7, 19, 16),     -- ContinueInfo's box
  }
end

-- The last zone covering a tile is the one that paints it.
local function paperAt(zones, col, row)
  local px, py, hit = col * 8, row * 8, nil
  for _, z in ipairs(zones) do
    if z.colors and px >= z.x and px < z.x + z.w
       and py >= z.y and py < z.y + z.h then
      hit = z
    end
  end
  return hit and hit.colors[1] or nil
end

local function everyTileDark(zones)
  for row = 0, 17 do
    for col = 0, 19 do
      local paper = paperAt(zones, col, row)
      if not paper or paper[1] > 127 then
        return false, ("tile %d,%d is %s"):format(col, row,
          paper and ("%02x"):format(paper[1]) or "unpainted")
      end
    end
  end
  return true
end

-- ------------------------------------------------------- the menu is up

do
  io.write("the CONTINUE menu is dark all the way into the corners\n")
  local theme = themeOver()
  local title = setmetatable({ sgbPalettes = true }, TitleState)
  -- src/ui/Menu.lua keeps its box in tx/ty/tw/th; ContinueInfo is a plain
  -- state carrying only titleUiBox, and draws its box with Font.drawBox
  local menu = { tx = 0, ty = 0, tw = 13, th = 10 }
  local info = { titleUiBox = { 4, 7, 19, 16 } }

  Theme.recordBox(0, 0, 13, 10)
  Theme.recordBox(4, 7, 16, 10)

  local out = theme.apply({ stack = { states = { title, menu, info } } },
                          titleZones())
  local dark, where = everyTileDark(out)
  ok(dark, "no white is left anywhere on the screen" .. (where and (" -- " .. where) or ""))

  -- The title's three colour bands are replaced by one black page rather
  -- than reversed, because its list does not open on a whole-screen zone
  -- (pageZones).  Nothing is lost by that here: with the menu open there is
  -- no art on the screen for those bands to be colouring.
  eq(#out, 3, "one page, and a panel for each of the two boxes")
  eq(out[1].w, 160, "the page covers the screen")
  eq(out[1].h, 144, "...all of it")
  eq(out[2].x, 0, "the CONTINUE menu's box")
  eq(out[2].w, 104, "...at its own width")
  eq(out[3].x, 32, "and ContinueInfo's, which no state describes")
  eq(out[3].w, 128, "...at the width it drew it")
end

-- --------------------------------------------------- the title is alone

do
  io.write("the title screen on its own is left as the picture it is\n")
  local theme = themeOver()
  local title = setmetatable({ sgbPalettes = true }, TitleState)
  local zones = titleZones()
  local out = theme.apply({ stack = { states = { title } } }, zones)

  eq(out, zones, "the list comes back by reference, untouched")
  eq(out[1].colors[1][1], 255, "the logo band keeps its paper")
  eq(out[3].colors[1][1], 255, "and so does the mon band")
end

-- ---------------------------------------------- pictures stay pictures

do
  io.write("a picture with a box on it themes the box and nothing else\n")
  -- The Hall of Fame, the intro, Oak's speech, the evolution and trade
  -- animations, the slots and the surfing minigame all own a frame and are
  -- all art.  None of them is named in COVERED_PAGES, so a box over one is a
  -- panel and the picture underneath is untouched.
  local theme = themeOver()
  local hall = setmetatable({ sgbPalettes = true }, HallOfFame)
  local box = { tx = 0, ty = 12, tw = 20, th = 6 }
  Theme.recordBox(0, 12, 20, 6)

  local zones = { zone(MEWMON, 0, 0, 19, 17) }
  local out = theme.apply({ stack = { states = { hall, box } } }, zones)

  eq(#out, 2, "the picture's own zone, and one panel")
  eq(out[1].colors[1][1], 255, "the picture is not reversed")
  eq(out[2].y, 96, "the box is")
  eq(out[2].colors[1][1], 0, "...and it is dark")
end

-- -------------------------------------------------- the map is still safe

do
  io.write("and the overworld is still nobody's page\n")
  local theme = themeOver()
  local world = { sgbPalettes = true }          -- no class, no marker
  local start = { tx = 9, ty = 0, tw = 11, th = 18 }
  Theme.recordBox(9, 0, 11, 18)

  local zones = { zone(MEWMON, 0, 0, 19, 17) }
  local out = theme.apply({ stack = { states = { world, start } } }, zones)

  eq(#out, 2, "the map's zone and the menu's panel")
  eq(out[1].colors[1][1], 255, "a map that goes dark is a map you cannot read")
end

-- ------------------------------------------------------------ the list

do
  io.write("the covered list names what it means to\n")
  eq(#Theme.COVERED_PAGES, 1, "one class, and a reason written beside it")
  eq(Theme.COVERED_PAGES[1], "src.ui.TitleState", "the title screen")
  for _, path in ipairs(Theme.COVERED_PAGES) do
    local named = false
    for _, page in ipairs(Theme.PAGES) do
      if page == path then named = true end
    end
    ok(not named, path .. " is covered OR a page, never both")
  end
end

io.write(("\n%d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
