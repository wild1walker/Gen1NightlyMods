-- UI THEME: the same screens, in light, dark, or colour.
--
-- ------- what a theme is allowed to touch
--
-- Every full-screen page in this game is drawn in black and white, this
-- suite's own pages included, and it is black and white for a reason: the art
-- is the game's own four DMG shades, the boxes are the game's own border
-- glyphs, and the colour arrives afterwards, from the SGB pass.  A state exposes `sgbPalettes()` returning a list of
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
-- must answer for the UI only.
--
-- The first version of this file decided by looking at the zone list alone: a
-- frame that opened on ONE WHOLE-SCREEN ZONE OF THE FOUR DMG GREYS was a
-- black-and-white page and everything else was left alone.  That rule was
-- wrong, and wrong in the way that costs the most -- it never fired.  The
-- engine's UI screens do not ask for the greys; they ask for a NAMED palette
-- and let the SGB pass colour them, which is the whole point of the pass:
--
--     OptionsMenu / ListMenu / ManagerState / NamingScreen / TrainerCard
--         PaletteFX.wholeNamed(game.data, "MEWMON")
--     PokedexMenu / DexEntryMenu     ... "BROWNMON"
--     PartyMenu                      ... "GREENBAR", then a zone per party row
--     TownMap                        ... "TOWNMAP"
--
-- None of those is the four greys, so UI THEME declined every screen in the
-- game and DARK did nothing at all.  Every SGB background palette in the pack
-- is built the same way, though -- an off-white paper at colour 0 and a near
-- black at colour 3, with the screen's own hue in the two between -- so the
-- page is not identified by its colours.  It is identified by WHOSE it is:
--
--     the topmost state on the stack that either says what it is
--     (`state.gen1wildTheme`) or is one of the engine UI classes named in
--     `Theme.PAGES` is the page, and the frame is that page's.
--
-- The walk stops early on purpose.  A state that OWNS the frame's zones and
-- is neither of those two things -- the overworld, a battle, the title screen
-- -- ends the search: whatever is under it is not what is on the screen, so
-- the frame is not ours.  An overlay that owns no zones (a text box, a fade)
-- is stepped over, which is what keeps a confirm box on top of the OPTION
-- screen from un-theming it.
--
-- An allowlist rather than a denylist, and of classes rather than names: the
-- suite's replacements keep the engine's own instance and swap only its draw
-- methods, so `getmetatable(state)` is still the engine's class and the match
-- is exact.  A screen this file has not been taught about is left looking
-- exactly as it looks today, which is the failure everyone can live with.
--
-- The old zone-shape rule is kept as a THIRD way in, for a screen from some
-- other mod that really does open on whole-screen greys.  It costs one
-- comparison and it means a mod's page can be themed without this file
-- learning its name.
--
-- ------- what a page is, once it is ours
--
-- Normally the page IS the frame's first zone: the state we found is the one
-- Game asked for palettes, and it returned a whole-screen zone.  When it did
-- not -- a screen that returns nil under some condition, or one that declares
-- no palettes at all and inherits whatever is beneath it -- the theme
-- SYNTHESISES a whole-screen page of the DMG greys instead of transforming a
-- list that belongs to a screen nobody can see.  Every class in `Theme.PAGES`
-- is opaque, so there is nothing behind it to preserve.
--
-- ------- one honest limit
--
-- This works by changing the colours a zone carries, so it works in the
-- display modes that USE them: SGB, SGB INV, ADVANCED, OG RED.  The flat
-- modes -- OG, OG INV, CLASSIC, and a custom ramp -- are the player asking
-- for one palette over the whole game, and `PaletteFX.effectiveColors`
-- replaces every zone's colours to give it to them.  A theme cannot outrank
-- that and should not try: OG INV already IS dark mode for the whole screen.
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
--             menus.  A page whose reversal would not actually be dark falls
--             back to plain black paper; see darkPage.
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

-- ------- the pages, and what colour each one is
--
-- Two ways a screen is recognised, and it only needs one.
--
-- A screen this suite REGISTERED says so itself: `state.gen1wildTheme` is a
-- tint name, set on the instance when it is built.  That covers the suite's
-- own menu screens and the test bench, and it costs a feature nothing.
--
-- Everything else is recognised by its class.  The list below is of STATE
-- classes -- things that go on `game.stack.states` -- which is why the bag,
-- the shop, Bill's PC and the prize counter are not in it by name: none of
-- them is a state.  `src/ui/BagMenu.lua` and its neighbours are modules that
-- build a `src.ui.ListMenu` and push THAT, so the one ListMenu entry themes
-- all four.  (The cost is that COLORFUL cannot tell a bag from a shop yet and
-- gives all of them the default paper.  That is the WIP half of that row.)
--
-- Left out deliberately: the screens that are pictures rather than pages --
-- the intro, Oak's speech, the Hall of Fame, the credits, the slots, the
-- trade animation, Pikachu's beach, the title screen -- and PaletteScreen,
-- which is the colour picker itself and has to show colours as they are.
Theme.PAGES = {
  { "src.ui.PokedexMenu", "dex" },
  { "src.ui.DexEntryMenu", "dex" },
  -- the bag, the shops, the box, the PC and the prize counter all push one
  { "src.ui.ListMenu", "page" },
  { "src.ui.PartyMenu", "party" },
  { "src.ui.SummaryMenu", "summary" },
  { "src.ui.TrainerCard", "card" },
  { "src.ui.Diploma", "card" },
  { "src.ui.TownMap", "world" },
  { "src.ui.NamingScreen", "page" },
  { "src.ui.LeaguePC", "box" },
  { "src.ui.OptionsMenu", "settings" },
  { "src.mods.ManagerState", "settings" },
}

local function classTints()
  local out = {}
  for _, entry in ipairs(Theme.PAGES) do
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

-- A zone that covers the screen.  The engine's UI states all open on one,
-- and it is the paper everything after it sits on -- which is why it has to
-- be the FIRST zone: a whole-screen zone further down the list is a panel
-- laid over a page rather than the page itself.
local function isWhole(zone)
  return type(zone) == "table" and zone.x == 0 and zone.y == 0
    and zone.w == 160 and zone.h == 144
end

-- The third way in, kept from this file's first version: a list that opens on
-- whole-screen greys is a black-and-white page whoever built it.  Nothing in
-- the engine returns that shape, but a mod's screen might, and recognising it
-- costs one comparison.  Returns the page's index (always 1) or nil.
local function basePage(zones)
  if type(zones) ~= "table" then return nil end
  local first = zones[1]
  if not isWhole(first) then return nil end
  if not isGreys(first.colors) then return nil end
  return 1
end

-- Rec. 709, the same weighting tests/runtime_test.lua measures the tints
-- against.  Used for one question only: is this actually dark?
local function luma(c)
  return 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3]
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

  -- ------- finding the page
  --
  -- Top of the stack downwards.  The first state that says what it is, or is
  -- a class in Theme.PAGES, is the page: returned with its tint name and
  -- whether it is one of ours.  The first state that owns the frame's zones
  -- and is NEITHER ends the walk with nothing -- that is the overworld, a
  -- battle, the title screen, and the frame is not a page.  A state that owns
  -- no zones and is not a page (a text box, a fade, the start menu) is
  -- stepped over, so a confirm box on top of the OPTION screen leaves the
  -- OPTION screen themed.
  --
  -- `sgbPalettes` is the same test src/core/Game.lua uses to pick the zone
  -- list in the first place, so "owns the zones" here means exactly what it
  -- means there.
  local function pageState(game)
    local states = game and game.stack and game.stack.states
    if type(states) ~= "table" then return nil end
    for i = #states, 1, -1 do
      local state = states[i]
      if type(state) == "table" then
        local named = state.gen1wildTheme
        if type(named) == "string" and Theme.TINTS[named] then
          return state, named, true
        end
        tintOf = tintOf or classTints()
        local byClass = tintOf[getmetatable(state)]
        if byClass then return state, byClass, false end
        if state.sgbPalettes then return nil end
      end
    end
    return nil
  end

  -- The list to theme, for a page we have found.
  --
  -- Usually the one we were handed: nothing above this state owns zones (the
  -- walk would have stopped), so if it has palettes of its own these are
  -- them.  When it has none -- a screen that returns nil under some
  -- condition, or one that declares no palettes and inherits from whatever is
  -- beneath it -- a page is made instead.  Every class in Theme.PAGES is
  -- opaque, so the list that came up from below is colouring a screen nobody
  -- can see and is the wrong thing to transform.
  local function pageZones(zones, state)
    if state.sgbPalettes and type(zones) == "table"
        and isWhole(zones[1]) and type(zones[1].colors) == "table" then
      return zones
    end
    return { { colors = GREYS, x = 0, y = 0, w = 160, h = 144 } }
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

  -- The page's own reversal, when that really is dark, and plain black-on-
  -- white when it is not.
  --
  -- Every SGB background palette in the pack is an off-white paper at colour
  -- 0 and a near-black at colour 3, with the screen's hue in the two between,
  -- so reversing one gives exactly what DARK is for: black paper, white ink,
  -- and the Pokedex still faintly red where the Pokedex was red.  Reversing
  -- is the right answer often enough to be the rule.
  --
  -- It is not always the right answer.  A page whose darkest colour is not
  -- dark -- the suite's own settings screens open on the player's outfit ramp
  -- -- reverses into a washed pastel, which is a different light mode rather
  -- than a dark one.  So the reversal has to PROVE it is dark (paper below
  -- luma 96, ink above 160) or the page falls back to the plain black one.
  -- Measured rather than listed, so a palette added later is judged on what
  -- it is instead of on whether somebody remembered to name it here.
  local function darkPage(colors)
    local flipped = reverse(colors)
    if luma(flipped[1]) <= 96 and luma(flipped[4]) >= 160 then return flipped end
    return DARK_PAGE
  end

  local function dark(zones, pageAt)
    return restyled(zones, function(index, zone)
      -- `colors == false` is the true-colour opt-out and is a rectangle, not
      -- a palette: an animated mon sprite, an item icon.  It is art, and art
      -- is not inverted.
      if type(zone.colors) ~= "table" then return zone.colors end
      if index == pageAt then return darkPage(zone.colors) end
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
  local function colorful(zones, pageAt, state, tintName)
    local tint = (tintName and Theme.TINTS[tintName]) or tintFor(state)
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
  --
  -- Three outcomes, and two of them return the caller's own list by
  -- reference: LIGHT, and a frame that is not a page.  That matters more than
  -- it looks -- this runs on every frame of the overworld and every frame of
  -- every battle, and on those frames it must cost a table lookup and a walk
  -- down a stack that is usually two states deep.
  function self.apply(game, zones)
    local theme = self.read()
    if theme == "light" then return zones end

    local state, tintName = pageState(game)
    if state then
      zones = pageZones(zones, state)
    else
      -- no page state: the frame is only ours if the list itself says so
      if not basePage(zones) then return zones end
      tintName = "page"
    end

    if theme == "dark" then return dark(zones, 1) end
    if theme == "colorful" then return colorful(zones, 1, state, tintName) end
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
Theme.isWhole = isWhole
Theme.basePage = basePage
Theme.luma = luma
Theme.reversed = reversed

return Theme
