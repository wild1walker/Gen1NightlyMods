-- UI THEME: the same screens, in light, dark, or colour.
--
-- ------- what a theme is allowed to touch
--
-- Every full-screen page this suite draws is black and white, and it is black
-- and white for a reason: the art is the game's own four DMG shades, the
-- boxes are the game's own border glyphs, and the colour arrives afterwards,
-- from the SGB pass.  A state exposes `sgbPalettes()` returning a list of
-- rectangles with a four-colour palette each; `Renderer:endFrame` blits the
-- finished 160x144 frame once per rectangle through a shader that maps the
-- four shades onto that palette.
--
-- So a theme here is not a repaint.  Nothing is redrawn, no screen is edited,
-- and no feature learns that themes exist.  One hook -- `render.zones`, which
-- is handed the finished zone list on the way to the blit -- swaps the four
-- colours each rectangle carries, and the same pixels come out a different
-- colour.  That is why DARK is cheap and why it cannot break a layout: a
-- theme that cannot move a glyph cannot move a glyph off the screen.
--
-- ------- which frames are "ours"
--
-- The hook sees every frame, including the overworld and every battle, and
-- must answer for the UI only.  It decides by looking at what the frame is
-- already asking for rather than by asking what state is on top:
--
--     a frame whose zone list begins with ONE WHOLE-SCREEN ZONE OF THE FOUR
--     DMG GREYS is a black-and-white UI page.
--
-- That is not a heuristic, it is the definition.  `{ P.whole(P.GRAYS) }` is
-- what a full-screen menu in this engine returns and what every screen in
-- this suite returns -- it is the identity through the shade shader, which is
-- how a page keeps white paper and black ink while the display mode colours
-- everything else.  The overworld returns per-map terrain palettes, a battle
-- returns named battle palettes, and the title screen returns its three
-- lettered bands; none of the three is whole-screen greys, so none of the
-- three is touched.  A page that is not black and white is not ours to swap.
--
-- It also means the rule needs no engine internals, no list of screen names
-- to keep current, and no marking of instances: a screen this suite has not
-- been taught about yet is themed on the day it is added, and a mod's screen
-- that draws in colour is left alone on the day it arrives.
--
-- ------- the three
--
--   LIGHT     the identity.  The hook returns the list it was handed, by
--             reference, so a light boot is byte-identical to a build with
--             no theme in it at all.  This is the default and stays it.
--   DARK      every zone reversed, lightest for darkest.  Paper black, ink
--             white, and the shades between them swapped in place -- which
--             is the whole of "our UI is black and white, swap the two",
--             and is exactly what the engine's own SGB INV display mode does
--             to the whole game.  Doing it per zone is what keeps it to the
--             menus.
--   COLORFUL  work in progress.  The page takes a tint chosen by WHAT THE
--             SCREEN IS -- the Pokedex reads red, the box blue, the party
--             green -- and a screen that says what its rows are gets a
--             colour per row on top of that.  Every tint keeps the DMG
--             ramp's own lightness within a few values, so a coloured page
--             has the contrast a black-and-white one had.
--
-- ------- what is deliberately NOT themed
--
-- The overworld, battles, the title screen, and anything drawn true-colour
-- (a mon's animated sprite, an item icon) -- the first three because they are
-- pictures rather than pages, the fourth because a `colors == false` zone is
-- the engine's opt-out from the shade shader and painting it would undo the
-- art it was cut out for.

local Theme = {}

-- The four DMG greys, as `src/render/PaletteFX.lua` writes them.  Compared by
-- value rather than by identity: a screen may build its own copy, and two
-- lists of the same four numbers are the same palette.
local GREYS = { { 255, 255, 255 }, { 170, 170, 170 }, { 85, 85, 85 },
                { 0, 0, 0 } }

Theme.ORDER = { "light", "dark", "colorful" }

Theme.LABELS = {
  light = "LIGHT",
  dark = "DARK",
  -- The asterisk is the suite's own mark for a row that is not finished, and
  -- this row is the reason the mark is in the menu's legend.
  colorful = "COLORFUL*",
}

Theme.DEFAULT = "light"

-- ------- the tints
--
-- Lightest first, like every palette in the engine.  Each is the DMG ramp with
-- a hue laid over it and its LIGHTNESS held: every ramp's four land at
-- relative luminance 246 / 170 / 85 / ~6 against the greys' 255 / 170 / 85 /
-- 0, so a coloured page reads with the contrast the black-and-white one had.
-- That is the whole of "not intrusive" -- a background you notice after the
-- words, not before them, and never one that makes a word harder to read.
--
-- Paper is the one shade allowed to drift, and by nine values only: held at
-- 255 it comes out pure white in every ramp, which is a tint nobody can see.
-- Ink cannot be held at 0 at all -- a black that carries a hue is not black --
-- so it is the accent at a fixed low lightness instead.
--
-- tests/runtime_test.lua measures all four of every ramp against that, which
-- is what keeps a colour added later from being added by eye.
--
-- `page` is what everything else falls back to.  It is a paper rather than a
-- colour: a screen with nothing to say about itself should look like a page
-- of the same book as the ones that do.
Theme.TINTS = {
  -- a page of the same book as the rest
  page      = { { 0xfb, 0xf7, 0xdd }, { 0xba, 0xa8, 0x87 },
                { 0x60, 0x54, 0x3f }, { 0x08, 0x07, 0x04 } },
  -- out in the world
  world     = { { 0xed, 0xfb, 0xe1 }, { 0x92, 0xb6, 0x7b },
                { 0x46, 0x5d, 0x37 }, { 0x05, 0x07, 0x03 } },
  -- the Pokedex is a red device
  dex       = { { 0xfb, 0xf5, 0xf3 }, { 0xd9, 0x9e, 0x96 },
                { 0xa4, 0x40, 0x3a }, { 0x0f, 0x04, 0x04 } },
  -- a PC
  box       = { { 0xe4, 0xfb, 0xfb }, { 0x7a, 0xb3, 0xd9 },
                { 0x33, 0x5a, 0x88 }, { 0x03, 0x07, 0x0c } },
  -- your team, in a full HP bar's green
  party     = { { 0xe8, 0xfb, 0xee }, { 0x71, 0xbf, 0x83 },
                { 0x31, 0x62, 0x3c }, { 0x03, 0x08, 0x04 } },
  -- a fight
  battle    = { { 0xfb, 0xf6, 0xeb }, { 0xd9, 0xa1, 0x7a },
                { 0x8c, 0x49, 0x2c }, { 0x0d, 0x05, 0x02 } },
  -- leather
  bag       = { { 0xfb, 0xf7, 0xda }, { 0xce, 0xa6, 0x66 },
                { 0x6c, 0x52, 0x2a }, { 0x09, 0x06, 0x02 } },
  -- money
  shop      = { { 0xfb, 0xfa, 0xc1 }, { 0xbe, 0xac, 0x59 },
                { 0x62, 0x56, 0x22 }, { 0x08, 0x07, 0x01 } },
  -- an ID card
  card      = { { 0xe9, 0xf9, 0xfb }, { 0x96, 0xac, 0xd6 },
                { 0x48, 0x56, 0x71 }, { 0x05, 0x07, 0x0a } },
  -- settings, and the mod manager
  settings  = { { 0xfb, 0xf4, 0xfb }, { 0xc4, 0x9e, 0xd9 },
                { 0x64, 0x4b, 0x8b }, { 0x08, 0x05, 0x0d } },
  -- stats
  summary   = { { 0xe4, 0xfb, 0xfb }, { 0x62, 0xbe, 0xb8 },
                { 0x28, 0x62, 0x5e }, { 0x02, 0x08, 0x08 } },
}

-- ------- which tint a screen gets
--
-- Two ways in, and a screen only needs one of them.
--
-- A screen this suite REGISTERED says so itself: `state.gen1wildTheme` is a
-- tint name, set on the instance when it is built.  That covers the suite's
-- own menu screens, and it costs a feature nothing to adopt.
--
-- A screen the suite REPLACED is identified by its class instead.  The
-- replacements in this bundle keep the engine's own instance and swap only
-- its draw methods (Gen1Party and Gen1BillsBox both say so in as many words),
-- so `getmetatable(state)` is still the engine's class and comparing against
-- it is exact -- no name matching, no guessing from a title string.  A module
-- that is not present resolves to nothing and simply has no entry.
local BY_CLASS = {
  { "src.ui.PokedexMenu", "dex" },
  { "src.ui.DexEntryMenu", "dex" },
  { "src.ui.BoxMenu", "box" },
  { "src.ui.PlayerPC", "box" },
  { "src.ui.LeaguePC", "box" },
  { "src.ui.PartyMenu", "party" },
  { "src.ui.BagMenu", "bag" },
  { "src.ui.ShopMenu", "shop" },
  { "src.ui.PrizeCounter", "shop" },
  { "src.ui.TrainerCard", "card" },
  { "src.ui.Diploma", "card" },
  { "src.ui.SummaryMenu", "summary" },
  { "src.ui.OptionsMenu", "settings" },
  { "src.mods.ManagerState", "settings" },
}

local function classTints()
  local out = {}
  for _, entry in ipairs(BY_CLASS) do
    local ok, class = pcall(require, entry[1])
    if ok and type(class) == "table" then out[class] = entry[2] end
  end
  return out
end

-- ------- the transforms

local function reversed(colors)
  return { colors[4], colors[3], colors[2], colors[1] }
end

-- Is this the four DMG greys?  By value, and only the four -- a palette that
-- is grey-ish but not those numbers is somebody's deliberate choice.
local function isGreys(colors)
  if type(colors) ~= "table" then return false end
  for i = 1, 4 do
    local c, want = colors[i], GREYS[i]
    if type(c) ~= "table" then return false end
    for channel = 1, 3 do
      if c[channel] ~= want[channel] then return false end
    end
  end
  return true
end

-- Where in the list the page is -- always 1, or nil when the list is not a
-- page at all.  An index rather than the zone itself, because the transforms
-- copy the list rather than write into it and have to find the page again in
-- the copy.
--
-- It has to be the FIRST zone: the list is drawn in order and the base is what
-- everything after it sits on, so a whole-screen zone further down is a panel
-- covering a page rather than the page itself.
--
-- `owned` relaxes the palette test, and only that.  A screen that has said
-- `gen1wildTheme` is one of ours by name and is themed whatever base it drew
-- itself on -- the suite's own settings screens open on the MEWMON palette,
-- which is a deliberate choice and not black and white.  Everything else has
-- to BE black and white to be swapped, which is the rule at the top of this
-- file and the reason the overworld and the battles come through untouched.
local function basePage(zones, owned)
  local first = zones[1]
  if type(first) ~= "table" then return nil end
  if first.x ~= 0 or first.y ~= 0 or first.w ~= 160 or first.h ~= 144 then
    return nil
  end
  if type(first.colors) ~= "table" then return nil end
  if not owned and not isGreys(first.colors) then return nil end
  return 1
end

function Theme.new(context)
  local mod = context.mod
  local optionset = context.optionset
  local KEY = "ui_theme"

  local self = {}

  local tintOf                          -- built on the first frame
  -- One table per source palette per theme, kept for as long as the source is
  -- kept.  The hook runs on every frame of every menu, and a menu with a
  -- dozen icon zones would otherwise allocate a dozen tables sixty times a
  -- second to say the same thing each time.  Weak keys, so a palette that
  -- goes away takes its cached reversal with it.
  local reversals = setmetatable({}, { __mode = "k" })

  function self.read()
    local value = optionset.read(mod, KEY)
    if not Theme.LABELS[value] then return Theme.DEFAULT end
    return value
  end

  function self.write(value, game)
    if not Theme.LABELS[value] then return end
    return optionset.write(mod, KEY, value, game)
  end

  -- The palette a tint name stands for, for a screen that wants to colour its
  -- own rows.  runtime/menu.lua cannot require this file -- a mod's require
  -- does not reach into its own folder -- so the instance carries the lookup
  -- rather than the table being read directly.
  function self.tint(name)
    return Theme.TINTS[name] or Theme.TINTS.page
  end

  function self.label(value)
    return Theme.LABELS[value or self.read()] or Theme.LABELS[Theme.DEFAULT]
  end

  function self.step(direction, game)
    local current = self.read()
    local at = 1
    for index, name in ipairs(Theme.ORDER) do
      if name == current then at = index end
    end
    local next_ = Theme.ORDER[((at - 1 + (direction or 1)) % #Theme.ORDER) + 1]
    self.write(next_, game)
    return next_
  end

  -- The row the bundle owns, folded into the same schema every feature's rows
  -- go into, so it is stored, read and remembered like any other -- including
  -- across a sealed cart's option reset, which runtime/settings.lua handles by
  -- key and needs no teaching about this one.
  function self.defineRow()
    optionset.own({
      key = KEY,
      type = "choice",
      label = "UI THEME",
      choices = {
        { Theme.LABELS.light, "light" },
        { Theme.LABELS.dark, "dark" },
        { Theme.LABELS.colorful, "colorful" },
      },
      default = Theme.DEFAULT,
    })
  end

  -- Which state owns the frame's zones: the topmost one that has a palette to
  -- offer, which is the same rule src/core/Game.lua uses to pick the list in
  -- the first place.  Only consulted by COLORFUL, and only to choose a tint --
  -- DARK never asks, which is why DARK works on a screen nothing here has
  -- heard of.
  local function zoneOwner(game)
    local states = game and game.stack and game.stack.states
    if type(states) ~= "table" then return nil end
    for i = #states, 1, -1 do
      local state = states[i]
      if type(state) == "table" and state.sgbPalettes then return state end
    end
    return nil
  end

  local function tintFor(state)
    if type(state) ~= "table" then return Theme.TINTS.page end
    local named = state.gen1wildTheme
    if type(named) == "string" and Theme.TINTS[named] then
      return Theme.TINTS[named]
    end
    tintOf = tintOf or classTints()
    local byClass = tintOf[getmetatable(state)]
    if byClass and Theme.TINTS[byClass] then
      return Theme.TINTS[byClass]
    end
    return Theme.TINTS.page
  end

  local function reverse(colors)
    local cached = reversals[colors]
    if not cached then
      cached = reversed(colors)
      reversals[colors] = cached
    end
    return cached
  end

  -- ---- DARK
  --
  -- Every zone, not only the page.  A menu's zone list is the page plus the
  -- panels inside it -- a species colour behind each party icon, the HP bar's
  -- own green -- and leaving those alone would put a white-grounded icon on a
  -- black page, which is a hole rather than an icon.  Reversing them puts the
  -- icon's paper on the page's black and reads it light-on-dark in its own
  -- colour, which is what the engine's SGB INV mode does and is why that mode
  -- holds together at all.
  local DARK_PAGE = reversed(GREYS)

  -- ------- a theme never writes into the list it was handed
  --
  -- The zone tables belong to the state that built them, and this hook has no
  -- way to know whether that state built them fresh this frame or is handing
  -- back a list it keeps.  Every screen in this suite builds fresh; a screen
  -- somebody adds later might not, and a cached list written into is a screen
  -- that flickers -- reversed on one frame, reversed back on the next, and
  -- unfindable from the symptom.
  --
  -- So a themed frame is a NEW list of NEW zones.  It costs a handful of small
  -- tables per frame and buys a transform that is a pure function of its
  -- input, which is the only version of this that can be reasoned about.
  local function restyled(zones, colourOf)
    local out = {}
    for index, zone in ipairs(zones) do
      if type(zone) ~= "table" then
        out[index] = zone
      else
        local copy = {}
        for key, value in pairs(zone) do copy[key] = value end
        copy.colors = colourOf(index, zone)
        out[index] = copy
      end
    end
    return out
  end

  local function dark(zones, pageAt, owned)
    return restyled(zones, function(index, zone)
      -- `colors == false` is the true-colour opt-out and is a rectangle, not
      -- a palette: an animated mon sprite, an item icon.  It is art, and art
      -- is not inverted.
      if type(zone.colors) ~= "table" then return zone.colors end
      -- A page that opened on a colour rather than on the greys gets the plain
      -- black one instead of that colour reversed.  DARK is "black and white,
      -- swapped", and the reverse of the suite's own purple base is a washed
      -- lilac page rather than a dark one -- the right answer for the panels
      -- inside it and the wrong one for the paper under them.
      if owned and index == pageAt then return DARK_PAGE end
      return reverse(zone.colors)
    end)
  end

  -- ---- COLORFUL
  --
  -- The page takes its screen's tint, and a screen that knows what its rows
  -- ARE gets a colour per row on top of it: `state:gen1wildThemeZones(tint)`
  -- returns extra zones, which is how a card that opens BATTLE settings comes
  -- out in the battle colour and the one that opens ITEMS in the bag's.
  -- That is the half of this row that is still work in progress -- the
  -- suite's own menu screens answer it and nothing else does yet.
  --
  -- Only the PAGE is retinted.  The panels inside it are already colour and
  -- already mean something -- a party icon is the species' own colour, an HP
  -- bar is green because it is nearly full -- and a theme that repainted
  -- those would be taking information away to add decoration.
  local function colorful(zones, pageAt, state)
    local tint = tintFor(state)
    local out = restyled(zones, function(index, zone)
      if index == pageAt then return tint end
      return zone.colors
    end)
    if state and type(state.gen1wildThemeZones) == "function" then
      local ok, extra = pcall(state.gen1wildThemeZones, state, tint)
      if ok and type(extra) == "table" then
        for _, zone in ipairs(extra) do
          if type(zone) == "table" then out[#out + 1] = zone end
        end
      end
    end
    return out
  end

  -- The hook itself.  `next` first, so a mod downstream that builds zones of
  -- its own has already built them and is themed with everything else.
  function self.apply(game, zones)
    if type(zones) ~= "table" or not zones[1] then return zones end
    local theme = self.read()
    if theme == "light" then return zones end
    local state = zoneOwner(game)
    local owned = type(state) == "table"
      and type(state.gen1wildTheme) == "string"
      and Theme.TINTS[state.gen1wildTheme] ~= nil
    local pageAt = basePage(zones, owned)
    if not pageAt then return zones end
    if theme == "dark" then return dark(zones, pageAt, owned) end
    if theme == "colorful" then return colorful(zones, pageAt, state) end
    return zones
  end

  function self.install()
    self.defineRow()
    -- Guarded, and reported once.
    --
    -- This runs on every frame of every screen, and it is the only thing in
    -- the bundle that does.  A theme is decoration: if it raises, the right
    -- outcome is the frame it was handed, drawn in the colours it already
    -- had -- not a crash in the middle of somebody's game over a tint.
    --
    -- Once, because a per-frame failure is a per-frame log line, and a log
    -- nobody can scroll is a log nobody can read.  After the first the theme
    -- stands down for the rest of the session, which also means the cost of
    -- a broken theme is one pcall per frame rather than one error per frame.
    local broken = false
    mod.hooks:wrap("render.zones", function(nextLink, game, zones)
      zones = nextLink(game, zones)
      if broken then return zones end
      local ok, out = pcall(self.apply, game, zones)
      if ok then return out end
      broken = true
      mod.log:warn("UI THEME stood down for this session: %s", tostring(out))
      return zones
    end)
  end

  return self
end

-- For the tests, which have no engine to require classes out of.
Theme.isGreys = isGreys
Theme.basePage = basePage
Theme.reversed = reversed

return Theme
