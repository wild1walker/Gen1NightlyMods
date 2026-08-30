-- Headless coverage of the party screen's COLORFUL zones.
--
-- The party screen is the one this suite has always coloured per Pokemon --
-- SPECIES COLOURS puts each member's own palette on its icon cell.  Under
-- COLORFUL that colour comes out of the cell and becomes the whole row, with
-- a band across the header and the footer.  This checks the zones that says,
-- because they are geometry and geometry is exactly what a headless harness
-- can check: which tile rows, in which order, in which palette.
--
-- The order is the part worth guarding.  The theme splices a screen's own
-- zones in ABOVE the page and BELOW whatever the screen had already returned,
-- so the card is a ground and the icon and the HP bar still land on top of
-- it.  Get that backwards and a full HP bar comes out the colour of the card
-- behind it, which is a green bar that no longer means "nearly full".
--
-- Run:  luajit tests/partytheme_test.lua

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

-- ---------------------------------------------------------------- harness

local function chunkOf(path)
  local handle = assert(io.open(path, "r"), path .. " is missing")
  local source = handle:read("*a")
  handle:close()
  return assert(load(source, "@" .. path))()
end

love = {
  graphics = {
    setColor = function() end,
    rectangle = function() end,
    circle = function() end,
    push = function() end, pop = function() end,
    setScissor = function() end,
  },
}

local function strings(text, ...)
  if select("#", ...) > 0 then return (tostring(text):format(...)) end
  return text
end

package.preload["src.core.Strings"] = function() return strings end
package.preload["src.render.Font"] = function()
  return { draw = function() end, drawCode = function() end,
           drawBox = function() end,
           width = function(t) return #tostring(t) * 8 end }
end
package.preload["src.render.HudTiles"] = function() return {} end
package.preload["src.pokemon.Sprites"] = function()
  return { iconPath = function(_, _, path) return path end }
end
package.preload["src.battle.Status"] = function()
  return { label = function() return nil end }
end
package.preload["src.ui.Theme"] = function()
  return { cursor = 0xED, cursorHollow = 0xEC, moreArrow = 0xEE }
end
package.preload["src.render.Assets"] = function()
  return { imageData = function() error("no assets in the harness") end }
end

-- The species palettes the screen asks for, in the shape PaletteFX returns:
-- an off-white paper, the species' light and dark, then black.
local MONPAL = {
  BULBASAUR = { { 255, 239, 255 }, { 0x63, 0xc8, 0x4a },
                { 0x21, 0x73, 0x21 }, { 0, 0, 0 } },
  CHARMANDER = { { 255, 239, 255 }, { 0xf8, 0x68, 0x20 },
                 { 0xb0, 0x28, 0x28 }, { 0, 0, 0 } },
}

package.preload["src.render.PaletteFX"] = function()
  return {
    GRAYS = { { 255, 255, 255 }, { 170, 170, 170 }, { 85, 85, 85 },
              { 0, 0, 0 } },
    whole = function(colors)
      return { colors = colors, x = 0, y = 0, w = 160, h = 144 }
    end,
    -- tile coordinates, inclusive, the way the engine addresses a zone
    zone = function(colors, tx1, ty1, tx2, ty2)
      return { colors = colors, tx1 = tx1, ty1 = ty1, tx2 = tx2, ty2 = ty2 }
    end,
    wholeNamed = function() return nil end,
    pal = function(_, name)
      if name == "GREENBAR" then
        return { { 255, 239, 255 }, { 0x31, 0xa2, 0x31 },
                 { 0x18, 0x51, 0x18 }, { 0, 0, 0 } }
      end
      return nil
    end,
    monPal = function(_, species) return MONPAL[species] end,
    barPalName = function() return "GREENBAR" end,
    markTrueColor = function() end,
  }
end

-- The vanilla party menu, as much of it as the factory touches: a constructor
-- that hands back an instance, and the three methods it replaces.
package.preload["src.ui.PartyMenu"] = function()
  local M = {}
  M.__index = M
  M.isOpaque = true
  function M.new(game, opts)
    return setmetatable({ game = game, index = 1,
                          party = (opts or {}).party }, M)
  end
  function M:sgbPalettes() return nil end
  function M:draw() end
  function M:update() end
  M.drawIcon = function() end
  return M
end

-- ------- the mod facade and the drawing kit

local options = { species_colours = true, ruled_icons = true,
                  live_move = true }
local mod = {
  options = { get = function(_, key) return options[key] end },
  log = { warn = function() end, info = function() end },
  cache = {},
}

local C = chunkOf("modules/Gen1Party/chrome.lua")(mod)
C.option = function(key, fallback)
  local value = options[key]
  if value == nil then return fallback end
  return value
end

local factory = chunkOf("modules/Gen1Party/screen.lua")(mod, C)
ok(type(factory) == "table" and type(factory.new) == "function",
   "the party screen builds")

-- ------- the theme, as the bundle hands it over

local Theme = chunkOf("runtime/theme.lua")
local theme = {
  tint = function(name) return Theme.TINTS[name] or Theme.TINTS.page end,
}
theme.band = function(name)
  return Theme.band(type(name) == "table" and name or theme.tint(name))
end

local function hex(c) return ("%02x%02x%02x"):format(c[1], c[2], c[3]) end

local PARTY = {
  { species = "BULBASAUR", hp = 20, stats = { hp = 20 } },
  { species = "CHARMANDER", hp = 5, stats = { hp = 20 } },
}
local game = { data = {}, save = { party = PARTY } }

-- ---------------------------------------------------------------- the zones

io.write("the party screen says what it is\n")
do
  local menu = factory.new(game, {})
  eq(menu.gen1wildTheme, "party",
     "the instance names its tint, so the theme finds it by marker and not "
     .. "only by class")
  ok(type(menu.gen1wildThemeZones) == "function",
     "and it colours its own rows")
end

io.write("COLORFUL bands the header and the footer\n")
do
  local menu = factory.new(game, {})
  local zones = menu:gen1wildThemeZones(Theme.TINTS.party, theme)
  ok(type(zones) == "table", "zones come back")

  -- The set's shape: header on tile rows 0-2, body on 3-14, footer on 15-17.
  eq(zones[1].ty1, 0, "the header band starts at the top")
  eq(zones[1].ty2, 2, "and ends where the header box ends")
  eq(zones[2].ty1, 15, "the footer band starts where the footer box starts")
  eq(zones[2].ty2, 17, "and runs to the bottom of the screen")
  eq(zones[1].tx1, 0, "both are full width")
  eq(zones[1].tx2, 19, "...to the last tile column")

  local band = Theme.band(Theme.TINTS.party)
  eq(hex(zones[1].colors[1]), hex(band[1]),
     "a band is the page's deep shade as its ground")
  eq(hex(zones[1].colors[4]), "ffffff", "with the type reversed out white")
end

io.write("and gives every POKeMON a card in its own colour\n")
do
  local menu = factory.new(game, {})
  local zones = menu:gen1wildThemeZones(Theme.TINTS.party, theme)
  eq(#zones, 4, "two bands and one card per member of the party")

  -- slot i is tile rows 3+(i-1)*2 and the one under it
  eq(zones[3].ty1, 3, "the first card starts on the first body row")
  eq(zones[3].ty2, 4, "and is two tile rows tall, like the row it colours")
  eq(zones[4].ty1, 5, "the second card starts under it")
  eq(zones[4].ty2, 6, "...and is the same height")
  eq(zones[3].tx1, 0, "a card is the whole row")
  eq(zones[3].tx2, 19, "...edge to edge")

  -- the species' LIGHT shade is the paper, and shade 3 is left alone so the
  -- name, the level and the HP numbers stay black on it
  eq(hex(zones[3].colors[1]), "63c84a", "BULBASAUR's card is BULBASAUR green")
  eq(hex(zones[4].colors[1]), "f86820", "CHARMANDER's is CHARMANDER orange")
  eq(hex(zones[3].colors[4]), "000000",
     "and the ink stays black, because a card is a ground and a ground that "
     .. "fights the type on it is worse than no card")
end

io.write("a card never covers the icon or the bar\n")
do
  -- What the screen returns from sgbPalettes is what lands ON TOP of these,
  -- because the theme splices these in under them.  So the card has to be
  -- BELOW in the final list: this checks the two lists agree about what each
  -- is for rather than both claiming the same cells.
  local menu = factory.new(game, {})
  local own = menu:sgbPalettes(game)
  ok(type(own) == "table" and own[1] ~= nil,
     "the screen still returns its own zones")

  local iconAt, barAt
  for _, zone in ipairs(own) do
    if zone.tx1 == 1 and zone.tx2 == 2 then iconAt = iconAt or zone end
    if zone.tx1 == 6 and zone.tx2 == 11 then barAt = barAt or zone end
  end
  ok(iconAt ~= nil, "an icon cell per POKeMON, in cols 1-2")
  ok(barAt ~= nil, "and an HP bar zone, in cols 6-11")
  eq(iconAt and iconAt.ty1, 3, "the first icon is on the first body row")
  eq(barAt and barAt.ty1, 4, "and the bar on the line under it")
end

io.write("and it stands down rather than guessing\n")
do
  local menu = factory.new(game, {})
  eq(menu:gen1wildThemeZones(Theme.TINTS.party, nil), nil,
     "with no theme to ask for a band, the screen has no opinion")
  eq(menu:gen1wildThemeZones(Theme.TINTS.party, {}), nil,
     "...nor with one that cannot make one")

  local orphan = factory.new(game, {})
  orphan.game = nil
  eq(orphan:gen1wildThemeZones(Theme.TINTS.party, theme), nil,
     "and a screen with no game behind it colours nothing")

  local empty = factory.new({ data = {}, save = { party = {} } }, {})
  local zones = empty:gen1wildThemeZones(Theme.TINTS.party, theme)
  eq(#zones, 2, "an empty party is two bands and no cards")
end

io.write(("\nparty theme: %d passed, %d failed\n"):format(passed, failed))
os.exit(failed == 0 and 0 or 1)
