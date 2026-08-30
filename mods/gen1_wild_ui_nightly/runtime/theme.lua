-- UI THEME: the same screens, in light or dark.
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
-- display modes that USE them.  ADVANCED is the one it is built for and
-- tested against; SGB, SGB INV and OG RED pass a zone's colours through the
-- same way.  The flat modes -- OG, OG INV, CLASSIC, and a custom ramp -- are
-- the player asking for one palette over the whole game, and
-- `PaletteFX.effectiveColors` replaces every zone's colours to give it to
-- them.  A theme cannot outrank that and should not try: OG INV already IS
-- dark mode for the whole screen.
--
-- ------- the two
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
--
-- There were three.  COLORFUL -- a saturated tint per screen, a band across
-- a header, a card per Pokemon in its own species colour -- was taken out at
-- 0.8.0 rather than finished.  Everything it needed went with it: the tint
-- table, `Theme.band`, `gen1wildThemeZones`, and the party screen's cards.
-- The history has it if it is ever wanted back; carrying a half-built third
-- option in the file that every frame of the game runs through is a worse
-- trade than looking it up.
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

Theme.ORDER = { "light", "dark" }

Theme.LABELS = {
  light = "LIGHT",
  dark = "DARK",
}

Theme.DEFAULT = "light"

-- ------- the pages
--
-- Two ways a screen is recognised, and it only needs one.
--
-- A screen this suite REGISTERED says so itself: `state.gen1wildTheme` is set
-- on the instance when it is built.  That covers the suite's own menu screens
-- and the test bench, and it costs a feature nothing.
--
-- Everything else is recognised by its class.  The list below is of STATE
-- classes -- things that go on `game.stack.states` -- which is why the bag,
-- the shop, Bill's PC and the prize counter are not in it by name: none of
-- them is a state.  `src/ui/BagMenu.lua` and its neighbours are modules that
-- build a `src.ui.ListMenu` and push THAT, so the one ListMenu entry covers
-- all four.
--
-- Left out deliberately: the screens that are pictures rather than pages --
-- the intro, Oak's speech, the Hall of Fame, the credits, the slots, the
-- trade animation, the title screen -- and PaletteScreen, which is the colour
-- picker itself and has to show colours as they are.
Theme.PAGES = {
  "src.ui.PokedexMenu",
  "src.ui.DexEntryMenu",
  -- the bag, the shops, the box, the PC and the prize counter all push one
  "src.ui.ListMenu",
  "src.ui.PartyMenu",
  "src.ui.SummaryMenu",
  "src.ui.TrainerCard",
  "src.ui.Diploma",
  "src.ui.TownMap",
  "src.ui.NamingScreen",
  "src.ui.LeaguePC",
  "src.ui.OptionsMenu",
  "src.mods.ManagerState",
}

-- The engine classes above, resolved to the class tables themselves so a
-- state can be matched by `getmetatable`.  Built on the first frame rather
-- than at load, because a mod's require of an engine module is cheap but not
-- free and a LIGHT boot never needs it.  A module that is not present
-- resolves to nothing and simply has no entry.
local function pageClasses()
  local out = {}
  for _, path in ipairs(Theme.PAGES) do
    local ok, class = pcall(require, path)
    if ok and type(class) == "table" then out[class] = true end
  end
  return out
end

-- ------- the transforms

local function reversed(colors)
  return { colors[4], colors[3], colors[2], colors[1] }
end

-- Plain black-and-white, swapped: the page a DARK screen falls back to, and
-- the colour a screen's true-colour matte takes under DARK.  File-wide rather
-- than per instance because it is a constant, and because self.matte needs it
-- in scope well before the DARK section that used to own it.
local DARK_PAGE = reversed({ { 255, 255, 255 }, { 170, 170, 170 },
                             { 85, 85, 85 }, { 0, 0, 0 } })

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

-- ------- panels
--
-- A page is a screen that owns the frame.  A PANEL is a box drawn ON one --
-- the START menu over the map, the bag's two windows, a field-move list, the
-- PC's menu.  None of those owns the frame's palettes: the engine hands the
-- zone list to the topmost state that has any, and a menu box has none, so
-- the map underneath answers for the whole screen and the theme quite
-- correctly declines it.  That is why the START menu stayed white in a dark
-- game, and it is not something the page rule can fix -- inverting the frame
-- to catch the menu would inverting the map with it.
--
-- So a panel is themed by its own rectangle and nothing else.  Two ways to
-- find one, and a screen only needs the first if the second is wrong:
--
--   * `state:gen1wildThemePanels()` returns rects in pixels, for a screen
--     that draws several boxes and knows where they are.
--   * failing that, `tx`/`ty`/`tw`/`th` on the state itself, in tiles.  That
--     is not a guess: `src/ui/Menu.lua` -- every menu box in this game --
--     keeps its box there and computes it in `Menu.new`, and the suite's own
--     windows are built to the same four fields.  Reading them off the object
--     costs nothing and covers screens nobody has taught this file about.
-- ------- the boxes the stack does not describe
--
-- A panel does not draw anything.  It hands the blit four colours FOR A
-- RECTANGLE, and every pixel inside that rectangle is remapped through them
-- -- including pixels that belong to something drawn ON TOP of the panel.
--
-- That is what the half-dark SAVE screen was.  START > SAVE leaves the START
-- menu open behind the save panel (start_sub_menus.asm:641-647), and the
-- menu is a `src/ui/Menu.lua` box eleven tiles wide by eighteen tall -- the
-- full height of the screen, from tile 9 rightwards.  It has tx/ty/tw/th, so
-- it got a panel.  The two boxes drawn over it did not: the save panel is an
-- ad-hoc table pushed on the stack with a `draw` and nothing else
-- (StartMenu.lua's `Font.drawBox(4, 0, 16, 10)`), and `src/render/TextBox.lua`
-- keeps its box in boxTx/boxTy/boxTw/boxTh rather than tx/ty/tw/th.  So the
-- menu's panel repainted the right-hand nine tiles of both of them and left
-- the rest alone: one screen, split down the middle, dark on one side of a
-- line that is not the edge of anything.
--
-- Reading boxTx as well would fix those two and not the next two.  The stack
-- is the wrong place to ask: what is on the screen is not what the states say
-- about themselves, it is what they DREW.
--
-- So ask that instead.  Every box in this game is drawn by `Font.drawBox` --
-- Menu, TextBox, ChoiceBox, ListMenu, the battle's own boxes, an ad-hoc panel
-- in a state's draw function, a mod's window -- so wrapping that one function
-- records every box on the screen, in the order they were drawn, whoever drew
-- them and whether or not they came from a state at all.
--
-- The order is free and it is the half that makes this safe: `src/core/
-- Game.lua` draws every state BEFORE it collects the zone list and raises
-- `render.zones`, so by the time this is asked the frame is complete and the
-- list is in painting order, bottom box first.
local boxes = {}
local boxCount = 0
-- A frame does not contain sixty boxes.  The cap is for the case where the
-- theme has stood down and nothing is draining the list any more: better a
-- stale sixty than a table that grows for the rest of the session.
local BOX_CAP = 60

local function recordBox(tx, ty, tw, th)
  if type(tx) ~= "number" or type(ty) ~= "number" then return end
  if type(tw) ~= "number" or type(th) ~= "number" then return end
  if tw <= 0 or th <= 0 then return end
  if boxCount >= BOX_CAP then return end
  boxCount = boxCount + 1
  boxes[boxCount] = { x = tx * 8, y = ty * 8, w = tw * 8, h = th * 8 }
end

-- The boxes drawn since the last call, and the list is emptied by asking.
local function takeBoxes()
  if boxCount == 0 then return nil end
  local out = {}
  for i = 1, boxCount do out[i] = boxes[i]; boxes[i] = nil end
  boxCount = 0
  return out
end

-- Wrapped once, and idempotently: `require` hands every mod the same table,
-- so a second bundle carrying this file -- or a hot reload of this one --
-- must not wrap the wrapper.  The marker is the same trick Gen1WildQOL's
-- SELECT handler uses on OverworldController, and for the same reason.
local FONT_MARK = "__gen1WildBoxRecorder"

local function watchBoxes()
  local ok, Font = pcall(require, "src.render.Font")
  if not ok or type(Font) ~= "table" then return false end
  if rawget(Font, FONT_MARK) then return true end
  local base = Font.drawBox
  if type(base) ~= "function" then return false end
  Font.drawBox = function(tx, ty, tw, th, ...)
    recordBox(tx, ty, tw, th)
    return base(tx, ty, tw, th, ...)
  end
  local assigned = pcall(function() Font[FONT_MARK] = true end)
  return assigned and true or false
end

local function overlaps(a, b)
  return a.x < b.x + b.w and b.x < a.x + a.w
     and a.y < b.y + b.h and b.y < a.y + a.h
end

local function sameRect(a, b)
  return a.x == b.x and a.y == b.y and a.w == b.w and a.h == b.h
end

local function panelRect(state)
  local tx, ty, tw, th = state.tx, state.ty, state.tw, state.th
  if type(tx) ~= "number" or type(ty) ~= "number" then return nil end
  if type(tw) ~= "number" or type(th) ~= "number" then return nil end
  if tw <= 0 or th <= 0 then return nil end
  return { x = tx * 8, y = ty * 8, w = tw * 8, h = th * 8 }
end

local function panelsOf(state)
  if type(state.gen1wildThemePanels) == "function" then
    local ok, got = pcall(state.gen1wildThemePanels, state)
    if ok and type(got) == "table" then return got end
    return nil
  end
  local one = panelRect(state)
  return one and { one } or nil
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

  local classes                         -- built on the first frame
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
        if state.gen1wildTheme ~= nil then return state, i end
        classes = classes or pageClasses()
        if classes[getmetatable(state)] then return state, i end
        -- owns the frame and is not a page: the frame is not ours, but
        -- anything stacked ON it still might be, so say where it sits
        if state.sgbPalettes then return nil, i end
      end
    end
    return nil
  end

  -- Every panel on the stack ABOVE whatever owns the frame, bottom up so a
  -- menu over a menu paints in the order the two were drawn.
  --
  -- Above the owner, and only above: a page IS the owner and is themed as a
  -- page, so painting its own box again would be a second coat of the same
  -- colour at best and a box over its own content at worst.  What is left
  -- above the owner is exactly the overlays -- the START menu on the map, the
  -- bag's windows, a field-move list, a battle's command box.
  local function panelZones(game, ownerAt, drawn)
    local states = game and game.stack and game.stack.states
    if type(states) ~= "table" then return nil end
    local rects
    for index = (ownerAt or 0) + 1, #states do
      local state = states[index]
      if type(state) == "table" then
        local found = panelsOf(state)
        if found then
          for _, rect in ipairs(found) do
            if type(rect) == "table" and type(rect.w) == "number"
                and type(rect.h) == "number" and rect.w > 0 and rect.h > 0 then
              rects = rects or {}
              rects[#rects + 1] = { x = rect.x or 0, y = rect.y or 0,
                                    w = rect.w, h = rect.h }
            end
          end
        end
      end
    end
    if not rects then return nil end

    -- ------- and everything drawn over one of them
    --
    -- A panel remaps its whole rectangle, so a box drawn on top of a panel is
    -- remapped by it whether or not anything asked for that.  There are only
    -- two honest answers to that and one of them is not painting the panel at
    -- all: either the box on top is themed too, or the box underneath must
    -- not be.  This takes the first -- the box on top IS a panel, it just did
    -- not come from a state that says so.
    --
    -- Only forwards, and that is the whole of the safety.  `drawn` is in
    -- painting order, so a box that comes AFTER a panel is a box drawn OVER
    -- it; one that comes before is underneath and was already covered.  A
    -- battle draws its own boxes and then a menu is stacked on top of it: the
    -- battle's boxes are earlier in the list than the menu's, so the menu's
    -- panel never reaches back and repaints the battle.  Nothing here can
    -- theme a screen that was not already being themed one box at a time.
    --
    -- Transitive, and free: the scan decides each box in order and only ever
    -- looks at boxes it has already decided, so a dialogue over a panel over
    -- the map brings its own YES/NO with it in the same pass.
    if drawn then
      local seeded, taken = {}, {}
      for i, box in ipairs(drawn) do
        for _, rect in ipairs(rects) do
          -- The state said this box and then drew it; it is already a panel,
          -- and it is where the closure starts.
          if sameRect(box, rect) then seeded[i] = true; taken[i] = true break end
        end
      end
      for j = 1, #drawn do
        if not seeded[j] then
          for i = 1, j - 1 do
            if seeded[i] and overlaps(drawn[i], drawn[j]) then
              seeded[j] = true
              break
            end
          end
        end
      end
      for j, box in ipairs(drawn) do
        if seeded[j] and not taken[j] then rects[#rects + 1] = box end
      end
    end

    local out = {}
    for _, rect in ipairs(rects) do
      out[#out + 1] = { colors = DARK_PAGE, x = rect.x, y = rect.y,
                        w = rect.w, h = rect.h }
    end
    return out
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

  -- ------- the matte
  --
  -- What a shade-0 pixel ENDS UP as, for the one thing a palette swap cannot
  -- reach: art drawn in true colour.
  --
  -- `PaletteFX.markTrueColor` is the engine's opt-out -- a marked rectangle is
  -- blitted raw so an animated sprite or a coloured item icon keeps its own
  -- colours instead of being read as four shades.  Raw means RAW: the page
  -- the screen cleared to white is white inside that rectangle too, and stays
  -- white when everything around it goes black.  That is the white box behind
  -- every icon in a dark party menu, box and Pokedex.
  --
  -- A screen fixes it by painting the rectangle this colour before it draws
  -- the art into it.  Only ever inside a rectangle it is about to mark: a
  -- black rectangle anywhere else is shade-3 pixels, which the theme would
  -- then map to the page's INK and put a hole in the page.
  --
  -- The hint is a tint name, or a ramp for a screen that knows the exact
  -- palette covering that spot -- a party icon sits on its Pokemon's card, not
  -- on the page.  Under LIGHT it is white, which is what every screen drew
  -- before this existed, so the call costs a build with no theme nothing.
  local MATTE_WHITE = { 255, 255, 255 }

  function self.matte()
    if self.read() == "light" then return MATTE_WHITE end
    return DARK_PAGE[1]
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

  -- The hook itself.  `next` first, so a mod downstream that builds zones of
  -- its own has already built them and is themed with everything else.
  --
  -- Three outcomes, and two of them return the caller's own list by
  -- reference: LIGHT, and a frame that is not a page.  That matters more than
  -- it looks -- this runs on every frame of the overworld and every frame of
  -- every battle, and on those frames it must cost a table lookup and a walk
  -- down a stack that is usually two states deep.
  function self.apply(game, zones)
    -- Drained on every frame, before the LIGHT return: the recorder is a
    -- wrapper on an engine function and cannot be asked to stop, so the one
    -- thing that must always happen is that somebody empties it.
    local drawn = takeBoxes()
    if self.read() ~= "dark" then return zones end

    local state, ownerAt = pageState(game)
    local out
    if state then
      out = dark(pageZones(zones, state), 1)
    elseif basePage(zones) then
      -- no page state, but the list itself says it is a page
      out = dark(zones, 1)
      ownerAt = ownerAt or 0
    else
      out = zones
    end

    -- Panels last, because they are drawn last: a menu box over a map is on
    -- top of the map, and the zone that colours it has to be on top of the
    -- zones that colour the map.  This is also the ONE path that can theme a
    -- frame that is not a page at all -- which is the whole point, because
    -- the START menu has never been one.
    local panels = panelZones(game, ownerAt, drawn)
    if not panels then return out end

    local spread = {}
    for _, zone in ipairs(out or {}) do spread[#spread + 1] = zone end
    for _, zone in ipairs(panels) do spread[#spread + 1] = zone end
    return spread
  end

  function self.install()
    self.defineRow()
    -- The box recorder, before the hook that reads it.  Absent on a build
    -- whose Font is not where it has always been, which costs the panels
    -- nothing they had before this: the stack's own tx/ty/tw/th still
    -- answers, and the boxes it cannot describe stay as they were.
    if not watchBoxes() then
      mod.log:info("boxes are not being watched; panels fall back to the stack")
    end
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
Theme.overlaps = overlaps
Theme.recordBox = recordBox
Theme.takeBoxes = takeBoxes

return Theme
