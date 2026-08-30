-- Wild Green
--
-- The player is green, he is called GREEN, and the title screen says so.
-- That is the whole mod.
--
-- It is the identity half of the Wild Green cart: the cart pins the two
-- Gen1Wild bundles for everything a playthrough actually does, and this
-- supplies the one thing a pinned mod set cannot -- a game that looks like
-- its own version rather than like Red with things added.
--
-- ------- the seams it uses, and why each one
--
--   player.sprite      the battle back pic and the front pic that Oak's
--                      intro, the trainer card and the Hall of Fame share.
--                      A HOOK, not a registry write: those paths are not in
--                      data.field at all.  Sprites.playerPath resolves them
--                      through FieldDefaults.fieldValue, so
--                      `field:get("playerPics")` hands back nothing and a
--                      patch built from it silently patches nothing -- which
--                      is exactly what 1.0.0 did, and why the player stayed
--                      red everywhere except the overworld.  The hook runs
--                      over the ALREADY-RESOLVED path, so it needs no guess
--                      about where the vanilla art lives.
--   sprites            the overworld walker.  A real record, so a patch does
--                      land -- and being a record it is decided at load, so
--                      PLAYER takes effect on the next launch.
--   field.boot.title   the title screen's version ribbon.  boot.title is the
--                      mod-reachable half of field.title, which the field
--                      schema does not expose.
--   palettes MEWMON    the title screen's standing figure, which has no
--                      per-image seam and is coloured by its zone palette.
--   TitleState         the same figure under REDPP, where the zone pass does
--                      not reach him and another mod paints him red after
--                      everything this one can say.  The only engine
--                      internal here, and the reason for the permission.
--   field.boot         playerName, so the game offers GREEN where it used to
--                      offer RED.
--   palettes LOGO1     the SGB palette the title's ribbon band wears.
--
-- None of the green pixels are here.  Every recoloured picture is written by
-- transforms.lua out of the player's own imported cache, under a "green/"
-- prefix that shadows nothing, and this file points the art at it.  Read
-- that file first: it explains the prefix, and why shade 2 is the face.

return function(mod)
  local CACHE = "assets/generated/"

  -- The character's four, lightest first: paper, skin, outfit, ink.  A copy
  -- of the ramp in transforms.lua, which cannot be imported from --
  -- tools/check.py fails the build if the two drift apart.  It is here for
  -- MEWMON, the title screen's own palette; the recolouring itself is the
  -- recipe's job.
  local WILD_GREEN = {
    { 0xff, 0xff, 0xff },
    { 0xf0, 0xa3, 0x63 },
    { 0x65, 0xba, 0x3f },
    { 0x00, 0x00, 0x00 },
  }

  -- The trainer art's four, which is what the title figure is baked to as
  -- well: monochrome green, because shade 2 on a portrait is the LIGHT for
  -- everything rather than the face.  transforms.lua explains it at length.
  -- Another copy tools/check.py keeps honest.
  local WILD_GREEN_PIC = {
    { 0xff, 0xff, 0xff },
    { 0xa8, 0xdd, 0x8a },
    { 0x65, 0xba, 0x3f },
    { 0x00, 0x00, 0x00 },
  }

  -- The ribbon band is lettering on white, not a sprite, so it does not use
  -- the character ramp.  It gets its own four, and both greens are dark
  -- enough to read as ink at 8px: 1.0.0 lent it the character's light green
  -- and it washed out on the title screen.
  local WILD_GREEN_TITLE = {
    { 0xff, 0xff, 0xff },
    { 0x2e, 0x8b, 0x3a },
    { 0x14, 0x57, 0x1f },
    { 0x00, 0x00, 0x00 },
  }

  -- The other eight suits, as (outfit, portrait light, bill).  A copy of the
  -- table in transforms.lua, which cannot be imported from -- tools/check.py
  -- fails the build if the two drift apart.  Only three values change
  -- between suits: the skin, the paper and the ink are the same in all nine,
  -- which is what "only the outfit" means.
  --
  -- It is here for the two things this file colours itself rather than
  -- reading off disk -- MEWMON, the palette the title screen paints the
  -- player figure through, and the bake that stands in when the cache has no
  -- title/player.png.  Both have to wear the suit the pictures do or the
  -- title screen is a different colour from the game behind it.
  local SUITS = {
    green  = { { 0x65, 0xba, 0x3f }, { 0xa8, 0xdd, 0x8a }, { 0xe6, 0xf4, 0xdc } },
    orange = { { 0xe2, 0x68, 0x1c }, { 0xef, 0xac, 0x82 }, { 0xfa, 0xe5, 0xd8 } },
    blue   = { { 0x3f, 0x7b, 0xd8 }, { 0x95, 0xb6, 0xea }, { 0xde, 0xe9, 0xf8 } },
    purple = { { 0x8a, 0x5b, 0xd0 }, { 0xbf, 0xa5, 0xe5 }, { 0xeb, 0xe3, 0xf7 } },
    yellow = { { 0xe8, 0xc5, 0x3a }, { 0xf2, 0xdf, 0x93 }, { 0x97, 0x80, 0x26 } },
    pink   = { { 0xee, 0x7b, 0xb8 }, { 0xf6, 0xb6, 0xd8 }, { 0xfc, 0xe9, 0xf3 } },
    black  = { { 0x3d, 0x3d, 0x45 }, { 0x94, 0x94, 0x99 }, { 0xde, 0xde, 0xdf } },
    white  = { { 0xcd, 0xd3, 0xda }, { 0xe4, 0xe9, 0xee }, { 0x85, 0x89, 0x8e } },
    grey   = { { 0x8b, 0x91, 0x99 }, { 0xbf, 0xc2, 0xc7 }, { 0xeb, 0xec, 0xee } },
  }

  -- The ribbon band in each suit, as (shadow, letter).  A copy of the table
  -- in tools/palette.py, which cannot be imported from -- tools/check.py
  -- fails the build if the two drift apart.
  --
  -- The band is lettering on white and not a sprite, so it does not take the
  -- suit's own three: a letter drawn in the outfit's own value washes out at
  -- 8px, which is what 1.0.0 shipped.  Each pair is the outfit taken to a
  -- fixed lightness instead -- the letter at 0.26 relative luminance and its
  -- one-pixel shadow at 0.45 -- and green's is the hand-sampled pair the cart
  -- shell is named after, unchanged.  palette.py carries the derivation.
  local TITLE_SUITS = {
    green  = { { 0x2e, 0x8b, 0x3a }, { 0x14, 0x57, 0x1f } },
    orange = { { 0xd0, 0x60, 0x1a }, { 0x78, 0x37, 0x0f } },
    blue   = { { 0x3e, 0x79, 0xd4 }, { 0x24, 0x46, 0x7a } },
    purple = { { 0x91, 0x5f, 0xda }, { 0x54, 0x37, 0x7e } },
    yellow = { { 0x89, 0x74, 0x22 }, { 0x4f, 0x43, 0x14 } },
    pink   = { { 0xb4, 0x5d, 0x8b }, { 0x68, 0x36, 0x50 } },
    black  = { { 0x72, 0x72, 0x81 }, { 0x3d, 0x3d, 0x45 } },
    white  = { { 0x70, 0x73, 0x77 }, { 0x41, 0x43, 0x45 } },
    grey   = { { 0x6f, 0x73, 0x7a }, { 0x40, 0x43, 0x46 } },
  }

  mod.options:define({
    -- The character, and the only thing here a player is likely to want both
    -- ways: GREEN is what the cart is for, RED is the vanilla art untouched.
    -- The overworld walker is a record, so this lands on the next launch;
    -- the battle and card pics follow the hook and change immediately.
    { key = "player", type = "choice", label = "PLAYER",
      choices = {
        { "GREEN", "green" }, { "RED", "red" },
        { "ORANGE", "orange" }, { "BLUE", "blue" }, { "PURPLE", "purple" },
        { "YELLOW", "yellow" }, { "PINK", "pink" }, { "BLACK", "black" },
        { "WHITE", "white" }, { "GREY", "grey" },
      },
      default = "green" },
    -- The title screen's version ribbon and the band it sits in.
    -- The face on the big pictures -- the battle back pic, the trainer card,
    -- Oak's intro, the credits, the Hall of Fame.  Its own row because the
    -- rule that finds it is a guess about a picture this mod never sees, and
    -- a guess a player can switch off is a different thing from one they
    -- cannot.  See the note over greenOf.
    { key = "portrait_skin", type = "toggle", label = "PORTRAIT SKIN",
      default = true },
    { key = "ribbon", type = "toggle", label = "TITLE RIBBON",
      default = true },
    -- The standing figure on the title screen.  Its own row because it is
    -- the one change here with a visible cost: see the note at the override.
    { key = "title_figure", type = "toggle", label = "TITLE FIGURE",
      default = true },
    -- The names the game OFFERS: the one it falls back to, and the list on
    -- the NEW NAME menu.  Its own row because a name is the one thing here
    -- that ends up written into a save.
    { key = "name", type = "toggle", label = "GREEN NAME LIST",
      default = true },
  })

  -- options:get can throw on a profile that has never stored a value for a
  -- row; every mod in the suite reads through a guard like this one.
  local function option(key, fallback)
    local ok, value = pcall(function() return mod.options:get(key) end)
    if not ok or value == nil then return fallback end
    return value
  end

  -- ------- which suit, and everything that follows from it
  --
  -- Recomputed rather than settled once, because PLAYER is live now: the row
  -- used to say "takes effect on the next launch" for the overworld walker,
  -- and a colour picker you have to reboot to see is a colour picker nobody
  -- turns twice.  `wear` is the whole of what a suit decides, in one place,
  -- and `relive` further down is what carries a second call of it out to the
  -- art already on screen.
  --
  -- RED is not a suit: it is the vanilla cache with nothing done to it, so it
  -- has no prefix and every swap below declines.  A stored value this build
  -- does not know -- a save from a version with a colour that has since gone
  -- -- falls back to the default rather than pointing at files nobody wrote.
  local suit, green, PREFIX, SKINNED
  local WORN_RAMP, WORN_PIC, WORN_TITLE
  -- the same portraits with the face painted skin.  A second set of files
  -- rather than a second recipe: the recipe runs at install and never sees
  -- the options, so both are written and this picks between them.
  local skinned

  local function wear(name)
    suit = name
    if suit ~= "red" and not SUITS[suit] then suit = "green" end
    green = suit ~= "red"
    PREFIX = CACHE .. suit .. "/"
    SKINNED = CACHE .. suit .. "skin/"
    skinned = option("portrait_skin", true)

    -- The chosen suit's three ramps: the four that never change, with the
    -- outfit, the portrait's light and the band's two swapped in -- so a suit
    -- can never move the skin.  GREEN takes the named tables above as they
    -- are rather than rebuilding them, which is what makes the default
    -- provably the same object it has always been.  RED reaches none of the
    -- places these are used.
    WORN_RAMP, WORN_PIC, WORN_TITLE =
      WILD_GREEN, WILD_GREEN_PIC, WILD_GREEN_TITLE
    local WORN, BAND = SUITS[suit], TITLE_SUITS[suit]
    if WORN and suit ~= "green" then
      WORN_RAMP = { WILD_GREEN[1], WILD_GREEN[2], WORN[1], WILD_GREEN[4] }
      WORN_PIC = { WILD_GREEN[1], WORN[2], WORN[1], WILD_GREEN[4] }
    end
    if BAND and suit ~= "green" then
      WORN_TITLE = { WILD_GREEN[1], BAND[1], BAND[2], WILD_GREEN[4] }
    end
  end

  wear(option("player", "green"))

  -- Exactly the pictures transforms.lua recolours, and the only ones this
  -- will swap.  It is the same list, in the same order, and tools/check.py
  -- compares the two -- because a swap to a green file the recipe did not
  -- write does not fall back to the red one, it draws nothing at all.
  -- Same shape as the recipe's own list, second value and all: true is an
  -- overworld sheet, false is a portrait.  Portraits are the ones with a
  -- skinned twin, so the two files have to agree about which is which.
  local RECOLOURED = {
    { "sprites/red.png", true },
    { "sprites/red_bike.png", true },
    { "battle/redb.png", false },
    { "battle/back/redb.png", false },
    { "trainer_card/red.png", false },
    { "credits/red.png", false },
    { "intro/red.png", false },
    { "hall_of_fame/red.png", false },
    { "title/player.png", false },
  }

  local KNOWN, PORTRAIT = {}, {}
  for _, entry in ipairs(RECOLOURED) do
    KNOWN[entry[1]] = true
    if not entry[2] then PORTRAIT[entry[1]] = true end
  end

  -- ------- PORTRAIT SKIN, and why it is a file and not a flag
  --
  -- Shade 2 on a portrait is the light for everything, so the monochrome
  -- ramp is what keeps the cap and the knees from going orange.  The recipe
  -- writes a second copy of each portrait with one patch of that shade --
  -- the one with eyes in it -- painted the character's skin instead, and
  -- fails closed to the monochrome copy when it cannot find exactly one.
  --
  -- So this is a choice between two files that both exist, not a recolour
  -- decided here.  Off is exactly 1.4.0's picture.  `wear` reads the row, so
  -- switching it moves the same pictures PLAYER does and at the same moment.

  -- The cache-relative name of a picture the recipe recolours, or nil.  Told
  -- apart from greenOf below because it answers in EVERY suit, RED included:
  -- the record sweep has to recognise the vanilla walker in order to have
  -- something to repoint when the row later moves off RED.
  local function cacheRel(path)
    if type(path) ~= "string" then return nil end
    local rel = path:match("^" .. CACHE .. "(.+)$")
    if not rel or not KNOWN[rel] then return nil end
    return rel
  end

  -- The green twin of a cache path, or nil when there is not one.
  local function greenOf(path)
    if not green then return nil end
    local rel = cacheRel(path)
    if not rel then return nil end
    if skinned and PORTRAIT[rel] then return SKINNED .. rel end
    return PREFIX .. rel
  end

  -- Registry writes are pcall'd one at a time rather than in a block: a
  -- schema that has moved under us should cost the thing it names and not
  -- the four that were fine.
  local function try(what, fn)
    local ok, problem = pcall(fn)
    if not ok then
      mod.log:warn("%s: %s", what, tostring(problem))
    end
    return ok
  end

  -- ------- the character
  --
  -- Installed whatever the row says, and `do` rather than `if green then` for
  -- exactly that reason: PLAYER is live, so RED is a value the row can be
  -- moved OFF as well as onto, and a hook that was never registered because
  -- the game booted red cannot be talked into existing later.  Every piece
  -- inside declines on its own while the suit is RED -- greenOf answers nil
  -- and the sweep repoints nothing -- which is the same picture the gate used
  -- to give and one that can change its mind.

  -- id -> the image its record shipped with, for every record this could ever
  -- repoint, and the set of paths this mod is drawing.  Hoisted out of the
  -- block because `relive` below is what a live PLAYER change runs, and it
  -- walks both.
  local walkers, greenArt = {}, {}
  -- and the paths the player.sprite hook has already reported, so a suit
  -- change logs its new pictures instead of going quiet on the grounds that
  -- it has spoken about that pic before.
  local seen = {}

  do
    -- The battle back pic, and the front pic Oak's intro, the trainer card
    -- and the Hall of Fame share.  ctx.demo is the catch tutorial's old man
    -- and ctx.oakDemo is Yellow's PROF.OAK -- neither is the player, and
    -- neither should turn green.
    -- Every distinct path this hook is handed, said once.  1.1.1 swapped the
    -- battle back pic and left the trainer card red, and there was no way to
    -- tell from outside whether the hook never ran, or ran and declined a
    -- path that is not shaped the way this expects.  One line per pic per
    -- session answers that without a debugger.
    local function note(path, ctx, verdict)
      if seen[path] then return end
      seen[path] = true
      mod.log:info("player.sprite %s/%s -> %s (%s)",
        tostring(ctx.kind), tostring(ctx.side), tostring(path), verdict)
    end

    -- ------- priority 940, and why it is not 0
    --
    -- Hooks:call walks the chain highest priority first, and a link that
    -- returns without calling next() ends it there (src/mods/Hooks.lua).
    -- Crystal Animated Sprites -- which this cart pins -- wraps player.sprite
    -- at 930 and does exactly that: when its PLAYER SPRITE option names a
    -- portrait it returns its own file and never calls next().
    --
    -- So at the default priority of 0 this link sat downstream of a chain
    -- that never reached it, and the battle back pic, the trainer card, Oak's
    -- intro and the Hall of Fame stayed red no matter what was done to them.
    -- Every attempt at those pictures from 1.0.0 to 1.1.4 was aimed at the
    -- wrong end of the problem.
    --
    -- 940 puts this one link outside that one, and no further up than it has
    -- to be.  The swap is computed from the path this link is HANDED, not
    -- from what downstream would answer -- downstream is where the
    -- substitution happens, and the point is to get in front of it.
    --
    -- The cost is real and is the PLAYER row's to pay: with GREEN the
    -- player's own portrait is the recoloured vanilla art, so a portrait
    -- chosen in CRYSTAL SPRITES > PLAYER SPRITE does not apply to the player.
    -- RED hands that back. Opponent portraits, the animated battle sprites
    -- and the shiny work are untouched either way -- this link only ever
    -- answers for the player.
    mod.hooks:wrap("player.sprite", function(next, path, ctx)
      if ctx.demo or ctx.oakDemo then
        note(path, ctx, "left alone: not the player")
        return next(path, ctx)
      end
      if not green then
        note(path, ctx, "left alone: PLAYER is RED")
        return next(path, ctx)
      end
      local swapped = greenOf(path)
      if not swapped then
        note(path, ctx, "NOT SWAPPED: outside " .. CACHE)
        return next(path, ctx)
      end
      note(path, ctx, "green")
      -- Drawn as written: without this the palette pass reads our green
      -- through the same red-channel shade buckets it reads grey art
      -- through and remaps it to something else entirely.
      ctx.trueColor = true
      return swapped
    end, 940)

    -- Every sprite record drawn from cache art: SPRITE_RED and, where the
    -- import wrote one, the BICYCLE sheet.  Found by image rather than by id
    -- so a name this mod guessed wrong is simply not matched.  A walker
    -- another mod has already reskinned points outside the cache, so
    -- cacheRel declines it and this does not fight over it.
    --
    -- `walkers` remembers the image each record shipped with even when the
    -- suit is RED and nothing is repointed, because that is the list `relive`
    -- walks when the row moves -- including the move back to RED, which is a
    -- restore and needs the vanilla path to restore TO.
    try("sprites", function()
      for id, def in mod.content.sprites:each() do
        local image = type(def) == "table" and def.image
        if type(image) == "string" and cacheRel(image) then
          walkers[id] = image
          local swapped = greenOf(image)
          if swapped then
            mod.content.sprites:patch(id, { image = swapped, trueColor = true })
            greenArt[swapped] = true
          end
        end
      end
    end)

    -- ------- and the walker in the dark
    --
    -- trueColor above is what keeps the green out of the palette pass.  The
    -- palette pass is also what blacks a cave out: Rock Tunnel and the other
    -- unlit floors arm PaletteFX's dark shift (home/fade.asm's FadePal2 writes
    -- rOBP0 = `dc 3,3,3,2`, so every object colour lands on shade 3), and the
    -- engine exempts a trueColor sprite from the whole thing --
    -- SpriteRenderer:draw claims a markTrueColor rect for it and blits the art
    -- as written.  So the one sprite that opted out of being recoloured also
    -- opted out of being blacked out, and the green player walked through Rock
    -- Tunnel lit up like a lamp beside a screenful of silhouettes.
    --
    -- The fix is not to paint him dark here.  It is to stop claiming an
    -- exemption in the one frame where there is nothing to exempt: the flag is
    -- dropped for the length of the draw, and the engine's own path bakes the
    -- sheet through PaletteFX.dmgObj() -- which in an unlit frame is already
    -- the darkened OBP0 -- and lets the zone shader colour it like every other
    -- object on the map.  He is the same silhouette, in the same shade, as the
    -- player who is not wearing green.
    --
    -- It works because of a decision transforms.lua already made: the green is
    -- recoloured so its RED CHANNEL still buckets onto the engine's four
    -- shades the way the vanilla art did (see "why shade 2 is the face").
    -- The bake was never garbage; trueColor was there to stop a LIT map's
    -- palette repainting the green, and an unlit one has no colour to keep.
    local function darkFrame(PaletteFX)
      if type(PaletteFX.shadeMap) == "function" then
        local ok, map = pcall(PaletteFX.shadeMap)
        -- Armed per frame by OverworldState:drawWorld while it draws a dark
        -- map, and left nil for a battle drawn over one, which is lit.  So it
        -- tracks the frame rather than the map.
        if ok then return map ~= nil end
      end
      if type(PaletteFX.darkWorld) == "function" then
        local ok, dark = pcall(PaletteFX.darkWorld)
        if ok then return dark == true end
      end
      return false
    end

    -- ------- and the walker on the town map
    --
    -- TownMap builds its own marker rather than drawing the player: it reads
    -- game.data.sprites[field.playerSprites.walk] and bakes THAT record's
    -- image through SpriteRenderer.obpImage (src/ui/TownMap.lua markerSheet).
    -- Two things follow, and both were wrong on this cart.
    --
    -- It never asks the `player.sprite` hook, which is what makes the walker
    -- green everywhere else, so the marker was the red art on a map where the
    -- player is green in every other frame of the game.
    --
    -- And obpImage keys OBJ colour 0 to alpha -- `r > 0.83` becomes
    -- transparent, matching GBC hardware, where sprite palette index 0 always
    -- is.  Wild Green's skin is 0xf0a363: red channel 0xf0, which is over that
    -- line.  So the face and the hands came out as holes with the map showing
    -- through them, on top of being the wrong colour.
    --
    -- Neither is a bake this art wants.  It is authored full colour and is
    -- drawn as written everywhere else -- that is what trueColor means up
    -- above -- so the marker is simply the file, loaded and handed to the same
    -- two fields the engine drew from.  markPlayerRedraw replays through those
    -- same fields, so the replay over the zone pass follows without another
    -- edit.
    try("town map", function()
      local TownMap = require("src.ui.TownMap")
      if type(TownMap) ~= "table" or type(TownMap.new) ~= "function" then
        return
      end
      if TownMap.__wildGreenMarker then return end
      local okAssets, Assets = pcall(require, "src.render.Assets")
      if not (okAssets and type(Assets) == "table"
              and type(Assets.image) == "function") then
        return
      end
      TownMap.__wildGreenMarker = true

      -- The record TownMap itself reads, resolved the same way it resolves
      -- it, so a dataset that names another walker is followed rather than
      -- guessed at.  Already-green is passed through: the sprites registry
      -- patch above may have reached this record, and greenOf declines a path
      -- that is already under the green prefix.
      local function markerPath(game)
        local data = game and game.data
        local sprites = (type(data) == "table" and data.sprites) or {}
        local field = (type(data) == "table" and data.field) or {}
        local id = (field.playerSprites or {}).walk or "SPRITE_RED"
        local def = sprites[id] or sprites.SPRITE_RED
        local image = type(def) == "table" and def.image or nil
        if type(image) ~= "string" then return nil end
        if image:sub(1, #PREFIX) == PREFIX or image:sub(1, #SKINNED) == SKINNED then
          return image
        end
        return greenOf(image)
      end

      local inner = TownMap.new
      TownMap.new = function(game, ...)
        local screen = inner(game, ...)
        if type(screen) ~= "table" then return screen end
        -- Only when the engine drew a marker of its own.  With no sheet it
        -- draws a small square instead, and putting a walker where it chose
        -- not to put one is a change this has no business making.
        if not screen.playerSheet then return screen end
        local path = markerPath(game)
        if not path then return screen end
        local ok, image = pcall(Assets.image, path)
        if not (ok and image) then return screen end
        pcall(image.setFilter, image, "nearest", "nearest")
        -- Inside the closure, not as pcall's first argument: a host without
        -- love.graphics would raise on the index before pcall ever ran.
        local okQuad, quad = pcall(function()
          return love.graphics.newQuad(0, 0, 16, 16, image:getDimensions())
        end)
        if not (okQuad and quad) then return screen end
        screen.playerSheet, screen.playerQuad = image, quad
        return screen
      end
    end)

    if next(greenArt) then
      try("dark caves", function()
        local SpriteRenderer = require("src.render.SpriteRenderer")
        local PaletteFX = require("src.render.PaletteFX")
        if type(SpriteRenderer) ~= "table" or type(PaletteFX) ~= "table" then
          return
        end
        if SpriteRenderer.__wildGreenDark then return end
        SpriteRenderer.__wildGreenDark = true

        -- Both draw paths, because the fishing pose goes through the other
        -- one: drawTile blits the rod row wearing the sprite's own palette
        -- and takes the same trueColor exemption.
        for _, name in ipairs({ "draw", "drawTile" }) do
          local inner = SpriteRenderer[name]
          if type(inner) == "function" then
            SpriteRenderer[name] = function(self, ...)
              local def = self and self.def
              if not (type(def) == "table" and def.trueColor
                      and greenArt[def.image] and darkFrame(PaletteFX)) then
                return inner(self, ...)
              end
              -- Put back on the way out however the draw goes, including
              -- through an error: a sprite record left permanently un-green
              -- would be a worse bug than the one being fixed.
              def.trueColor = nil
              local results = { pcall(inner, self, ...) }
              def.trueColor = true
              if not results[1] then error(results[2], 0) end
              return table.unpack and table.unpack(results, 2)
                or unpack(results, 2)
            end
          end
        end
      end)
    end
  end

  -- ------- the name and the title screen
  --
  -- Both live under field.boot, and they go in as ONE patch.  Two calls
  -- would be two writes to the same id, and the second is what the merge
  -- keeps -- which quietly cost the default name when this was written as
  -- two.

  local bootPatch, title, namesPatch = {}, {}, nil

  -- GREEN where the game used to offer RED.  It follows the character: a
  -- player who has switched back to the red sprite is playing as RED.
  --
  -- Two things, because the game asks twice.  playerName is what a save
  -- gets when no name is chosen (SaveData: `boot.playerName or "RED"`).
  -- namePresets is the list on the naming screen's first page, under
  -- NEW NAME -- the engine's own is RED / ASH / JACK for the player and
  -- BLUE / GARY / JOHN for the rival, and a boot that does not set it gets
  -- those as a fallback (OakSpeech.namePresets).  The two lists read down
  -- the cursor: WILD GREEN VERSION, then Thanks For Playing!
  --
  -- playerName stays GREEN rather than following the list's first entry.
  -- It is the name a save takes when the naming step never runs, and a
  -- green player called GREEN is the sensible one of the three.
  --
  -- Three things make the rival's list safe, and all three are worth
  -- writing down because none of them is obvious:
  --
  --   * "Playing!" is eight characters where a TYPED name stops at seven
  --     (OakSpeech.nameLen).  A preset is not typed: NamingScreen:enter
  --     calls onDone(preset) straight from the menu, so maxLen never sees
  --     it, and the save's name field is eleven bytes (GenSave.NAME_LENGTH)
  --     with the encoder writing at most ten.  It fits with room over.
  --   * Eight is also exactly what the box holds.  Menu widens itself to
  --     `widest + 3` tiles and the intro box asks for 11, so an 8-glyph
  --     label lands on 11 and the frame keeps vanilla's width.  A ninth
  --     character would silently grow the box.
  --   * Lowercase and "!" are all in the charmap
  --     (src/save_convert/data/charmap.lua), so they encode into a save and
  --     round-trip out of it as themselves rather than as "?".
  --
  -- And it takes TWO writes, not one.  The field registry's semantics are
  -- "deep" (Schemas.lua), and under deep semantics Merge.deepMerge CONCATS
  -- arrays rather than replacing them -- so a single patch carrying three
  -- names appends them to vanilla's three and the menu offers six:
  -- RED / ASH / JACK / WILD / GREEN / VERSION.  That is what 1.19.0 shipped.
  --
  -- mod.DELETE unsets a key, so unsetting namePresets in an earlier op and
  -- writing it in a later one lands on an absent list, which the merge
  -- copies wholesale instead of extending.  Registry.fold walks a mod's ops
  -- in order, so two patches to the same id are two ops and the order holds.
  if green and option("name", true) then
    bootPatch.playerName = "GREEN"
    namesPatch = {
      player = { "WILD", "GREEN", "VERSION" },
      rival = { "Thanks", "For", "Playing!" },
    }
  end

  if option("ribbon", true) then
    -- versionRibbon, not version: the importer's key is the vanilla pair of
    -- fragments the draw pass repositions, and ours is one continuous strip.
    -- TitleState centres a versionRibbon whole at y=64.
    title.versionRibbon =
      mod.assets:path("assets/title/wild_green_version.png")
  end

  if next(title) then bootPatch.title = title end

  if next(bootPatch) or namesPatch then
    try("field.boot", function()
      -- the unset first, so the lists that follow replace vanilla's rather
      -- than being appended to them
      if namesPatch then
        mod.content.field:patch("boot", { namePresets = mod.DELETE })
      end
      if next(bootPatch) or namesPatch then
        if namesPatch then bootPatch.namePresets = namesPatch end
        mod.content.field:patch("boot", bootPatch)
      end
    end)
  end

  -- ------- the title screen's standing figure
  --
  -- Not by swapping the pic.  The figure's rectangle is cut OUT of the
  -- true-colour region on purpose, so the mon cycling behind it keeps its
  -- palette, and what is left is painted by the SGB zone pass -- which
  -- reads the art's shade and not its colour.  Recoloured art handed to
  -- that draw comes back as whatever the zone palette says.
  --
  -- So the figure keeps the vanilla grey art and MEWMON is what colours it.
  -- MEWMON is the zone palette for tile rows 10-17, which is the figure, the
  -- cycling Pokemon and the GAME FREAK line, so this is not free:
  --
  --   * the copyright line goes green with him.  It is the cost, and it was
  --     taken deliberately.
  --   * the cycling Pokemon is untouched while its art is true-colour --
  --     markVisibleTrueColor marks the mon and cuts the figure out of it, so
  --     the palette reaches the figure and not the mon.  With a mod like
  --     Crystal Animated Sprites on, which the cart pins, that always holds.
  --     Switch every sprite mod off and the title mon goes green too; the
  --     TITLE FIGURE row is there to switch back out of that.
  --
  -- Like LOGO1 below, this is a registry record only under SGB: OG RED
  -- short-circuits every named palette to the boot-ROM pair and ADVANCED
  -- reads data/palettes_gbc.
  -- ------- ...and the same figure under REDPP, where MEWMON cannot reach him
  --
  -- ADVANCED (PaletteFX.mode "redpp") does not run the zone pass over that
  -- rectangle at all, and this cart is the reason.  Crystal Animated
  -- Sprites -- pinned here -- marks the trainer's rect true-colour under
  -- REDPP so the zone pass cannot smear MEWMON over the vivid mon behind
  -- him, and then luminance-bakes his grey art to Red's own white / skin /
  -- red / navy so he is not left raw grey.  That bake is the whole of "the
  -- main screen didn't change": the figure is red because another mod
  -- paints him red, downstream of everything this one can say.
  --
  -- It is also what 1.1.0 actually was.  The white-and-pink figure that
  -- release put on screen was that same bake reading OUR green art -- the
  -- outfit green and the light green both land in its skin bucket -- not
  -- the engine's shade buckets, which is what 1.1.1's note said and got
  -- wrong.  Swapping the pic was never going to work; running after the
  -- bake is.
  --
  -- So: the same bake in this mod's four.  It wraps TitleState.currentSprite
  -- from OUTSIDE (this mod is priority 1300 and loads last, so its wrapper
  -- goes on over theirs), captures the untouched art on the way in -- before
  -- the red bake happens -- and paints that on the way out.  Out of REDPP it
  -- hands the grey art back and MEWMON has him again.
  --
  -- Every step is pcall'd and every miss is a no-op: without the engine
  -- module, without love.graphics, without a clonable ImageData, the figure
  -- is exactly what it was before this block existed.
  local function shadeOf(r)
    -- the recipe's own four thresholds.  The red channel rather than a
    -- weighted luminance, so art that is already green -- if something got
    -- there first -- buckets by its shade instead of collapsing into one.
    if r > 0.83 then return 1 end
    if r > 0.5 then return 2 end
    if r > 0.17 then return 3 end
    return 4
  end

  -- ------- getting an Image's pixels back, which is not one call
  --
  -- love.graphics.Image has no getData under LOVE 11: the texture does not
  -- keep the ImageData it was built from.  1.4.0 called it and gave up when
  -- it was not there, so the bake below failed on the very first frame,
  -- cached the failure, and left the figure exactly as it was -- which is
  -- why 1.4.0 changed nothing on screen.
  --
  -- The way back to the pixels is to draw the image into a canvas of its own
  -- size and read that. Two things make it safe: everything it touches is
  -- put back, and the blit runs at the origin -- currentSprite can be called
  -- mid-draw with the screen's own transform still on the stack, and drawing
  -- through that transform pushes the art out of a 1:1 canvas and reads back
  -- nothing at all.
  --
  -- getData is still tried first, because where it exists it is cheaper and
  -- needs no graphics state at all.  A clone either way: the title art is
  -- cached and other draws read the same object, so mapping it in place
  -- would recolour theirs too.
  local function pixelsOf(image)
    local okData, data = pcall(image.getData, image)
    if okData and data then
      local okClone, clone = pcall(data.clone, data)
      if okClone and clone then return clone end
    end

    local g = type(love) == "table" and love.graphics or nil
    if not (g and g.newCanvas and g.getCanvas) then return nil end
    local okDim, w, h = pcall(image.getDimensions, image)
    if not (okDim and w and h and w > 0 and h > 0) then return nil end

    local wasCanvas = g.getCanvas()
    local blend, alphaMode = g.getBlendMode()
    local cr, cg, cb, ca = g.getColor()
    local out
    pcall(function()
      local canvas = g.newCanvas(w, h, { dpiscale = 1 })
      g.setCanvas(canvas)
      g.clear(0, 0, 0, 0)
      g.setBlendMode("replace", "premultiplied")
      g.setColor(1, 1, 1, 1)
      g.push()
      g.origin()
      g.draw(image, 0, 0)
      g.pop()
      g.setCanvas()
      out = canvas:newImageData()
      if canvas.release then pcall(canvas.release, canvas) end
    end)
    -- put the screen back whether or not any of that worked
    if wasCanvas then pcall(g.setCanvas, wasCanvas) else pcall(g.setCanvas) end
    pcall(g.setBlendMode, blend or "alpha", alphaMode)
    pcall(g.setColor, cr or 1, cg or 1, cb or 1, ca or 1)
    return out
  end

  -- A PRIVATE copy, recoloured.  Never the shared ImageData in place: the
  -- title art is cached and other draws read the same object.
  local function greenBake(raw)
    local copy = pixelsOf(raw)
    if not copy then return nil end
    local okMap = pcall(function()
      copy:mapPixel(function(_, _, r, g, b, a)
        if a == 0 then return r, g, b, a end
        local colour = WORN_PIC[shadeOf(r)]
        return colour[1] / 255, colour[2] / 255, colour[3] / 255, a
      end)
    end)
    if not okMap then return nil end
    local okNew, image = pcall(love.graphics.newImage, copy)
    if not (okNew and image) then return nil end
    pcall(image.setFilter, image, "nearest", "nearest")
    return image
  end

  local function wrapTitleFigure()
    if type(love) ~= "table" or type(love.graphics) ~= "table" then
      return "no love.graphics"
    end
    local okTitle, TitleState = pcall(require, "src.ui.TitleState")
    if not okTitle or type(TitleState) ~= "table"
        or type(TitleState.currentSprite) ~= "function" then
      return "no TitleState.currentSprite"
    end
    if TitleState.__wildGreenFigure then return "already wrapped" end
    local okFX, PaletteFX = pcall(require, "src.render.PaletteFX")
    if not okFX or type(PaletteFX) ~= "table" then return "no PaletteFX" end
    local okAssets, Assets = pcall(require, "src.render.Assets")
    if not okAssets or type(Assets) ~= "table" then Assets = nil end

    -- The recipe's own copy of this figure, which is the same art the
    -- trainer card gets and so has the same face, ear and hands on it.
    -- TitleState keeps the path it loaded him from (self.playerPath), so
    -- there is nothing to guess: the green twin of THAT is what to draw.
    -- Assets.image resolves an "assets/generated/..." path through
    -- save/mod-derived, which is where a transform's output lives.
    local function derived(title)
      if not Assets or type(Assets.image) ~= "function" then return nil end
      local swapped = greenOf(title.playerPath)
      if not swapped then return nil end
      local ok, image = pcall(Assets.image, swapped)
      if not (ok and image) then return nil end
      pcall(image.setFilter, image, "nearest", "nearest")
      return image
    end

    -- Where the strip is drawn.  Not derivable from here: it is the rect
    -- Crystal marks true-colour for the same image on the same screen, and
    -- it is marked again rather than conditionally, because the mark has to
    -- happen whether or not that mod is installed and marking the same rect
    -- twice costs nothing.
    local FIGURE_X, FIGURE_Y = 82, 80
    -- the ball the engine lifts out of the same picture and throws on a y of
    -- its own (TitleState: newQuad(0, 16, 8, 8), drawn at 82, self.ballY)
    local BALL_W, BALL_H = 8, 8

    -- the untouched art, for the bake.  The DERIVED copy needs none of
    -- this -- it is a file, found from the path TitleState loaded -- so the
    -- search only happens when the bake is what is left.
    local function rawOf(title)
      if title.__wildGreenRaw then return title.__wildGreenRaw end
      local raw = title.__crystalPlayerRaw
      -- and failing that, what is on the instance right now, but only while
      -- nothing has baked over it yet
      if not raw and not title.__crystalTrainerBaked then raw = title.player end
      title.__wildGreenRaw = raw
      return raw
    end

    -- ------- and keep asking for the derived copy
    --
    -- The recipe's copy is a FILE, and on the first boot after an install it
    -- can arrive a moment after this screen does -- the transform writes it,
    -- and the title is one of the earliest things drawn.  Settling for the
    -- flat bake for the life of the screen is what makes a fresh install
    -- show a faceless green figure until the next launch.  So while we are
    -- on the fallback, ask again: rarely, because each ask is a file load,
    -- and never once we have it.
    local RETRY = 45

    local function apply(title, mark)
      if PaletteFX.mode == "redpp" then
        if not title.__wildGreenHasCopy then
          local wait = title.__wildGreenWait
          if title.__wildGreenBaked == nil or not wait or wait <= 0 then
            local found = derived(title)
            if found then
              title.__wildGreenHasCopy = true
              title.__wildGreenBaked = found
              mod.log:info("title figure: the recipe's green copy")
            else
              title.__wildGreenWait = RETRY
              if title.__wildGreenBaked == nil then
                -- the bake is flat green: it works off the shade buckets
                -- alone and knows nothing about where a face is
                local raw = rawOf(title)
                if not raw then return end      -- nothing to work from yet
                title.__wildGreenBaked = greenBake(raw) or false
                -- the line 1.4.0 needed: the wrap succeeded there and the
                -- BAKE was what failed, silently, a frame later
                mod.log:info("title figure: %s", title.__wildGreenBaked
                  and ("a flat bake for now -- still looking for a derived "
                       .. "copy of " .. tostring(title.playerPath))
                  or "could not read the art, left as it was")
              end
            end
          else
            title.__wildGreenWait = wait - 1
          end
        end
        local baked = title.__wildGreenBaked
        if not baked then return end
        title.player = baked
        -- Crystal re-bakes on every call until its own flag is set; with it
        -- set its bake returns early and leaves ours standing.  Its restore
        -- path -- a switch out of REDPP -- then puts back the same picture
        -- we captured, which is where the branch below leaves it too, so the
        -- two agree about the figure in both directions.
        title.__crystalPlayerRaw = title.__crystalPlayerRaw or title.__wildGreenRaw
        title.__crystalTrainerBaked = true
        -- ------- and mark the rect, from whichever path got here
        --
        -- Without the mark the SGB zone pass repaints that rectangle by
        -- shade, and under ADVANCED that is MEWMON out of data/palettes_gbc
        -- -- white, #ef9c6b, #7321a5, black.  A purple figure, whatever
        -- image is under it.  Crystal marks it from currentSprite, and
        -- currentSprite is exactly what the draw skips while scrollPhase is
        -- "ball", so in that phase nothing marked it and the figure went
        -- purple no matter who had set the picture.  Marking the same rect
        -- twice in a frame costs nothing; not marking it at all costs this.
        if mark and type(PaletteFX.markTrueColor) == "function" then
          local okDim, w, h = pcall(baked.getDimensions, baked)
          if okDim and w and h then
            pcall(PaletteFX.markTrueColor, FIGURE_X, FIGURE_Y, w, h)
          end
          -- and the ball, which is drawn from the same picture at a y of its
          -- own -- and in that phase it is the only other thing on screen
          if type(title.ballY) == "number" then
            pcall(PaletteFX.markTrueColor, FIGURE_X, title.ballY,
              BALL_W, BALL_H)
          end
        end
      elseif title.__wildGreenBaked then
        -- out of REDPP the zone pass runs again and MEWMON is what colours
        -- him, so the grey art goes back: baked green through the zone pass
        -- would be painted twice.
        local raw = title.__wildGreenRaw or title.__crystalPlayerRaw
        if raw and title.player == title.__wildGreenBaked then
          title.player = raw
        end
        title.__wildGreenBaked = nil
        title.__wildGreenHasCopy = nil
        title.__wildGreenWait = nil
        title.__crystalTrainerBaked = nil
      end
    end

    TitleState.__wildGreenFigure = true
    local inner = TitleState.currentSprite
    function TitleState:currentSprite(...)
      -- captured on the way IN, which is the only moment the art is still
      -- the grey the importer wrote
      if self.player and not self.__wildGreenRaw then
        self.__wildGreenRaw = self.player
      end
      local image, trueColor = inner(self, ...)
      pcall(apply, self, true)
      return image, trueColor
    end

    -- ------- and again from draw(), because currentSprite is not enough
    --
    -- TitleState:draw takes `local playerImage = self.player` at the TOP and
    -- only calls currentSprite further down -- so a frame that changes
    -- self.player inside currentSprite still draws the picture it captured
    -- before the change.  One frame late is invisible while the value is
    -- stable, and this one is not stable: the same draw skips currentSprite
    -- entirely while scrollPhase is "ball", so for a whole phase of the
    -- title's animation nothing re-asserts the figure and Crystal's red bake
    -- is what stands.  That is the flash back to the old skin.
    --
    -- So assert it here too, before the draw reads it -- and mark the rect
    -- from here as well.  1.15.0 left the mark to currentSprite on the
    -- grounds that the marking pass owns it, and that is precisely the call
    -- this phase skips: the picture was green and the zone pass painted
    -- MEWMON purple straight over it.
    local innerDraw = TitleState.draw
    if type(innerDraw) == "function" then
      function TitleState:draw(...)
        pcall(apply, self, true)
        return innerDraw(self, ...)
      end
    end
    return "wrapped"
  end

  -- ------- MEWMON is the band, not the face
  --
  -- MEWMON colours tile rows 10-17, and that band is not just the figure: the
  -- cycling mon, the POKE BALL between him and the logo, and the copyright
  -- line along the bottom are all inside it.  It used to be overridden with
  -- WORN_RAMP -- the OVERWORLD four, whose shade 2 is the character's skin --
  -- on the reasoning that the figure is the thing being coloured.  He is not
  -- the only thing being coloured, and the shade means something else on
  -- everything else in the band: the ball came out with a skin-coloured
  -- half, and GAME FREAK's line at the bottom was lettered in skin.  That is
  -- what "part of the pokeball is skin color, the words at the bottom are
  -- skin color highlights too" is.
  --
  -- So the band takes WORN_PIC, the PORTRAIT four, whose shade 2 is a light
  -- rather than a face.  It is already what the figure is baked to under
  -- ADVANCED, so the two modes now agree about him as well -- and the face on
  -- the big pictures is PORTRAIT SKIN's job, which paints a file rather than
  -- a palette and is unaffected either way.
  if green and option("title_figure", true) then
    try("palettes.MEWMON", function()
      mod.content.palettes:override("MEWMON", WORN_PIC)
    end)
    try("title.figure", function()
      mod.log:info("title figure under REDPP: %s", tostring(wrapTitleFigure()))
    end)
  end

  if option("ribbon", true) then
    -- The ribbon art is grey, because the band it lands in is an SGB palette
    -- zone: TitleState:sgbPalettes colours tile rows 8-9 with LOGO1 and the
    -- shader remaps by shade.  So the colour comes from here.
    --
    -- WORN_TITLE, not WILD_GREEN_TITLE: the band follows PLAYER now.  It used
    -- to be green in every suit on the grounds that WILD GREEN VERSION is the
    -- game's name rather than the character's jacket, and in front of a
    -- player who has just put the character in purple that reads as a setting
    -- that did not take.  The WORDS still say GREEN; only the ink moves.
    try("palettes.LOGO1", function()
      mod.content.palettes:override("LOGO1", WORN_TITLE)
    end)
  end

  -- ------- the two title bands, in every display mode
  --
  -- The two overrides above are registry records, and a registry record is
  -- not how every display mode asks for a palette.  PaletteFX.pal
  -- short-circuits every NAME to the boot-ROM pair under OG RED and reads
  -- data/palettes_gbc under ADVANCED -- so in those two modes neither
  -- override is consulted at all, and the title screen wears the mode's own
  -- LOGO1 and MEWMON out of that pack:
  --
  --     LOGO1  = white / #f7f78c / #8cbd52 / #ad0021
  --     MEWMON = white / #ef9c6b / #7321a5 / black
  --
  -- The ribbon draws its letter in shade 2 and its shadow in shade 1, so
  -- under ADVANCED the lettering came out #8cbd52 on #f7f78c -- a yellow-green
  -- word with a pale yellow shadow, which is exactly the "it is like a
  -- yellow right now?" this fixes.  And MEWMON's shade 1 there is #ef9c6b, a
  -- skin tone, which is the ball's light half and the copyright line's
  -- highlight along the bottom of the screen.
  --
  -- Nothing a NAMED palette can say reaches those modes.  A zone is a
  -- different thing: `render.zones` is handed the finished list on the way to
  -- the blit, after the state has resolved every name, so replacing the
  -- colours of the two bands there lands in every mode that colours at all.
  -- The three deliberately monochrome modes (OG, OG INV, CLASSIC) substitute
  -- the whole screen downstream in PaletteFX.effectiveColors and are left to
  -- do it -- a mono mode asked for one palette, not ours.
  --
  -- The three bands TitleState:sgbPalettes returns, in its own order:
  -- the logo across tile rows 0-7, the version ribbon across 8-9, and the
  -- mon, the figure, the ball and the copyright line across 10-17.
  local LOGO_BAND = { y = 0, h = 64 }
  local RIBBON_BAND = { y = 64, h = 16 }
  local FIGURE_BAND = { y = 80, h = 64 }

  -- Which zone of a list is which band, or nil when the list is not the
  -- title screen's.
  --
  -- By RECTANGLE, and by all three at once.  Not by palette identity, because
  -- under ADVANCED the palettes in the list are the pack's and not ours --
  -- that is the whole reason this exists.  Not by asking the stack what state
  -- is on top either: that would mean requiring src.ui.TitleState to compare
  -- against, and the shape is a better witness than the class is.  Three
  -- full-width zones at y=0/64/80 with heights 64/16/64, in one list, is the
  -- packet that screen sends and nothing else does -- the trailing UI-box
  -- zones the CONTINUE / NEW GAME frame adds are narrow boxes at other rects
  -- and are not matched, which is what keeps that menu's black ink black.
  local function titleBands(zones)
    local logo, ribbon, figure
    for _, zone in ipairs(zones) do
      -- colors == false is the trueColor opt-out and is a rect, not a
      -- palette: the figure's own rectangle under ADVANCED is one of those,
      -- and painting it would undo the bake it was cut out for.
      if type(zone) == "table" and type(zone.colors) == "table"
          and zone.x == 0 and zone.w == 160 then
        if zone.y == LOGO_BAND.y and zone.h == LOGO_BAND.h then
          logo = zone
        elseif zone.y == RIBBON_BAND.y and zone.h == RIBBON_BAND.h then
          ribbon = zone
        elseif zone.y == FIGURE_BAND.y and zone.h == FIGURE_BAND.h then
          figure = zone
        end
      end
    end
    if logo and ribbon and figure then return ribbon, figure end
    return nil
  end

  mod.hooks:wrap("render.zones", function(nextLink, game, zones)
    zones = nextLink(game, zones)
    if type(zones) ~= "table" or not zones[1] then return zones end

    local wantsRibbon = option("ribbon", true)
    local wantsFigure = green and option("title_figure", true)
    if not (wantsRibbon or wantsFigure) then return zones end

    local ribbon, figure = titleBands(zones)
    if not ribbon then return zones end

    if wantsRibbon then ribbon.colors = WORN_TITLE end
    if wantsFigure then figure.colors = WORN_PIC end
    return zones
  end)

  -- ------- PLAYER, applied where the player is standing
  --
  -- The row used to take effect on the next launch, for one reason: the
  -- overworld walker is a `sprites` RECORD, records are folded into
  -- Game.data once at load, and SpriteRenderer copies the image out of the
  -- record when the Player is built.  Both of those are settled long before
  -- anybody opens the menu.
  --
  -- Neither is a reason it has to STAY settled.  The recipe writes every
  -- suit's files at install -- all nine, always -- so switching colour has
  -- never been a question of generating anything; it is a question of which
  -- path a record names.  So this repoints the folded record and rebuilds the
  -- renderers that had already copied out of it, and the walker changes
  -- colour under your feet.
  --
  -- What still waits for a relaunch, and why:
  --
  --   * the version ribbon's ARTWORK.  It is `field.boot.title`, read once
  --     when the title screen is built, and the title screen is not on
  --     screen when this row is turned.  Its COLOUR is live -- that goes
  --     through the zone hook above, which runs every frame.
  --   * the name list, which is boot data a save takes a copy of.
  --
  -- Everything else -- the walker, the bicycle sheet, the battle back pic,
  -- the trainer card, Oak's intro, the credits, the Hall of Fame, the
  -- town-map marker and the title figure -- is current on the next frame.
  local function relive(why)
    local ok, Game = pcall(require, "src.core.Game")
    if not ok or type(Game) ~= "table" then return end
    local data = Game.data
    local records = type(data) == "table" and data.sprites or nil
    if type(records) ~= "table" then return end

    -- The record tables themselves, so the renderer sweep below can tell a
    -- sheet this mod just moved from one another mod owns.
    local touched = {}
    for id, vanilla in pairs(walkers) do
      local def = records[id]
      if type(def) == "table" then
        local swapped = greenOf(vanilla)
        local want = swapped or vanilla
        if def.image ~= want then
          def.image = want
          -- trueColor is what keeps our green out of the shade buckets; the
          -- vanilla art wants it off again, or the palette pass stops
          -- reaching a walker that is grey after all.
          def.trueColor = swapped and true or nil
          touched[def] = true
        end
        if swapped then greenArt[swapped] = true end
      end
    end
    if not next(touched) then return end

    -- Rebuild only the renderers holding a record we just moved.  A
    -- SpriteRenderer reads the image once, in `new`, so the live player is
    -- still drawing the sheet the old path resolved to until it is rebuilt --
    -- and rebuilding by record rather than by name leaves a walker another
    -- mod owns exactly where it was.
    local player = Game.overworld and Game.overworld.player
    if player then
      local okSR, SpriteRenderer = pcall(require, "src.render.SpriteRenderer")
      if okSR and type(SpriteRenderer) == "table" then
        for _, key in ipairs({ "sprite", "surfSprite", "bikeSprite",
                               "surfPikachuSprite" }) do
          local renderer = player[key]
          if type(renderer) == "table" and touched[renderer.def] then
            local built, fresh = pcall(SpriteRenderer.new, renderer.def,
                                       renderer.seed or "player")
            if built then player[key] = fresh end
          end
        end
      end
    end

    -- The hook reports one line per picture per session; a suit change is a
    -- new set of pictures and should say so rather than stay quiet because it
    -- has already spoken about that pic once.
    for key in pairs(seen) do seen[key] = nil end
    mod.log:info("player=%s -- repointed live (%s)", suit:upper(), why)
  end

  -- The three rows that decide which file a picture is read from.  The
  -- others (the ribbon, the figure, the name list) are palettes and boot
  -- data, and are either already live or deliberately not.
  local LIVE_ROWS = { player = true, portrait_skin = true }

  -- Guarded because `mod.events` is the one part of the mod table a harness
  -- is likely not to stand up, and a mod that cannot listen should still
  -- install everything else.
  if mod.events and type(mod.events.on) == "function" then
  mod.events:on("mod.options_changed", function(ev)
    if type(ev) ~= "table" then return end
    if ev.mod ~= mod and ev.mod ~= mod.id then return end
    if not LIVE_ROWS[ev.key] then return end
    wear(option("player", "green"))
    -- The MEWMON and LOGO1 overrides are read by the zone hook out of the
    -- upvalues `wear` just rewrote, so the title screen needs nothing here.
    relive(tostring(ev.key))
  end)
  end

  -- One line a player can quote back when a picture stays red.  The recipe
  -- only recolours what the cache actually carries, and which pictures those
  -- are is the difference between "this mod is broken" and "your import
  -- never wrote that file".
  -- Which rows are set, and which set of files the pics are read from.  The
  -- prefix is the answer to "did PORTRAIT SKIN take": greenskin/ is the
  -- skinned copies, green/ the flat ones -- and a build that does not name a
  -- prefix at all is a build older than the row.
  mod.log:info("player=%s portrait_skin=%s ribbon=%s -- pics are read from %s",
    suit:upper(), tostring(skinned),
    tostring(option("ribbon", true)),
    green and (skinned and SKINNED or PREFIX) or "the cache, untouched")
end
