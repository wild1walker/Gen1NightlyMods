-- Wild Green -- the recipe that turns the player green.
--
-- The player's pictures are the vanilla ones, so this mod may not ship them:
-- derived art travels as a recipe and the pixels come from the player's own
-- imported cache (Guide: Art Pipeline, "The rule").  This file is that
-- recipe.  It runs once on install, and again only when the cache is
-- re-imported or this file changes.
--
-- ------- shade 2 is the face, not the outfit
--
-- The importer decodes vanilla art to four grey shades and the palette pass
-- colours them at draw time.  On the player those four are, in order: the
-- transparent/white ground, the SKIN and the shirt's white, the OUTFIT, and
-- the black outline and hair.
--
-- The first cut of this file recoloured shades 2 and 3 both, on the
-- assumption that everything above black was clothing.  In the field that
-- turned his face green as well -- the whole sprite read as one green blob.
-- Only shade 3 is the outfit.  Shade 2 becomes skin, because under trueColor
-- these pixels are drawn exactly as written and the palette pass is not
-- coming along afterwards to make a face out of grey.
--
-- ------- why it writes to green/ and not over the cache path
--
-- A transform's output shadows the cache by relative path: write
-- "sprites/red.png" and every draw of the player is green, everywhere,
-- always.  That is one line shorter and it takes the PLAYER option away --
-- there would be no red art left to switch back to.
--
-- So the outputs go under a "green/" prefix, which matches nothing the
-- importer writes and therefore shadows nothing.  They are still reachable:
-- Assets.resolve rewrites any "assets/generated/<rel>" through
-- save/mod-derived/<id>/<rel> whether or not the cache has a file there
-- (src/render/Assets.lua, derivedPath).  main.lua points the player's art at
-- "assets/generated/green/..." when the option says GREEN and leaves it
-- alone when it says RED, and both sets exist the whole time.
--
-- ------- the sandbox
--
-- No require, no love, no io, no os.  ctx is the entire surface, so the
-- palette below is a copy of tools/palette.py's rather than an import of
-- it; tools/check.py fails if the two ever disagree.

return function(ctx)
  -- lightest first, which is the order ctx.recolor reads
  local WILD_GREEN = {
    { 0xff, 0xff, 0xff },   -- paper  -- pure white: battle pics matte on it
    { 0xf0, 0xa3, 0x63 },   -- skin   #f0a363  the face and hands
    { 0x65, 0xba, 0x3f },   -- outfit #65ba3f  the cap and clothes
    { 0x00, 0x00, 0x00 },   -- ink    -- outline and hair
  }

  -- Not a shade.  Red's lips are drawn in the CAP's shade, so in vanilla they
  -- come out the same red as his hat -- which is why they read as lips at all.
  -- 1.1.2 turned them skin and they vanished; this is vanilla's own colour,
  -- sampled off red Red, so they read as lips on a green hat too.
  local MOUTH = { 0xec, 0x4d, 0x29 }

  -- Nor is this.  The bill is drawn in the FACE's shade, so on red Red it is
  -- the same colour as his cheek and reads as nothing at all -- and painting
  -- it the cap's green just merged it into the hat.  A green-tinted white
  -- gives it back its own edge against both.
  local BILL = { 0xe6, 0xf4, 0xdc }

  -- Nor this.  Vanilla draws the shadow on the skin -- the ear, the brow,
  -- the line of the mouth -- in the shade BELOW the skin's own, which on a
  -- monochrome ramp is the same shade as the clothes.  Painting only shade 2
  -- leaves those as green freckles on a skin-coloured face, so the pieces
  -- of shade 3 sealed inside skin take the skin's own shadow.
  local SKIN_DARK = { 0xad, 0x75, 0x47 }

  -- The trainer art takes a DIFFERENT four, because shade 2 does not mean
  -- the same thing there.
  --
  -- On the 16x16 overworld sprite shade 2 is only ever the face.  On the
  -- 56x56 portrait it is the LIGHT for everything: the cap's front, the
  -- shading on the shirt, the highlight on the knees and the shoes.  Vanilla
  -- gets away with one shade for both because its ramp is monochrome red --
  -- white, light red, red, black -- and light red happens to look like skin.
  -- Painting that shade a skin tone put orange blotches on the hat and the
  -- knees, and the mouth rule speckled red over the rest.
  --
  -- So the portrait gets the same trick in green, and neither of the
  -- position rules: a face-sized rule on face-sized art is noise.
  local WILD_GREEN_PIC = {
    { 0xff, 0xff, 0xff },
    { 0xa8, 0xdd, 0x8a },
    { 0x65, 0xba, 0x3f },
    { 0x00, 0x00, 0x00 },
  }

  -- ------- and the other eight
  --
  -- PLAYER is nine colours.  Only three values differ between them, and they
  -- are the three above that carry the outfit's hue: the outfit, the
  -- portrait's light shade, and the bill.  SKIN, SKIN_DARK, MOUTH, the paper
  -- and the ink are the SAME in every suit -- the face is the face whatever
  -- he is wearing, which is what "only the outfit" means and is the whole
  -- reason the rules below learned to tell skin from clothing.
  --
  -- Green's three are the hand-sampled ones above and do not move: it is the
  -- default and the cart's own colour, and its files come out byte for byte
  -- as they did before this table existed.  The other eight are its own rule
  -- applied to a different outfit -- 45% toward white for the portrait light,
  -- 83% toward white for the bill, and 35% toward BLACK for the bill of a
  -- pale outfit, where mixing further toward white would be no edge at all.
  -- Derived once and written out, so what ships is numbers rather than
  -- arithmetic; tools/check.py holds these against tools/palette.py.
  --
  -- The order is the order the PLAYER row offers them, green first.
  local SUITS = {
    { "green",  { 0x65, 0xba, 0x3f }, { 0xa8, 0xdd, 0x8a }, { 0xe6, 0xf4, 0xdc } },
    { "orange", { 0xe2, 0x68, 0x1c }, { 0xef, 0xac, 0x82 }, { 0xfa, 0xe5, 0xd8 } },
    { "blue",   { 0x3f, 0x7b, 0xd8 }, { 0x95, 0xb6, 0xea }, { 0xde, 0xe9, 0xf8 } },
    { "purple", { 0x8a, 0x5b, 0xd0 }, { 0xbf, 0xa5, 0xe5 }, { 0xeb, 0xe3, 0xf7 } },
    { "yellow", { 0xe8, 0xc5, 0x3a }, { 0xf2, 0xdf, 0x93 }, { 0x97, 0x80, 0x26 } },
    { "pink",   { 0xee, 0x7b, 0xb8 }, { 0xf6, 0xb6, 0xd8 }, { 0xfc, 0xe9, 0xf3 } },
    { "black",  { 0x3d, 0x3d, 0x45 }, { 0x94, 0x94, 0x99 }, { 0xde, 0xde, 0xdf } },
    { "white",  { 0xcd, 0xd3, 0xda }, { 0xe4, 0xe9, 0xee }, { 0x85, 0x89, 0x8e } },
    { "grey",   { 0x8b, 0x91, 0x99 }, { 0xbf, 0xc2, 0xc7 }, { 0xeb, 0xec, 0xee } },
  }

  -- One suit as the two ramps and the bill the recipe below actually reads.
  -- Built from the four constants that never change plus the three that do,
  -- so a suit cannot accidentally move the skin.
  local function suitOf(entry)
    local outfit, picLight, bill = entry[2], entry[3], entry[4]
    return {
      id = entry[1],
      ramp = { WILD_GREEN[1], WILD_GREEN[2], outfit, WILD_GREEN[4] },
      picRamp = { WILD_GREEN[1], picLight, outfit, WILD_GREEN[4] },
      bill = bill,
    }
  end

  -- Every picture of the player this recipe knows how to recolour, and the
  -- ONLY ones main.lua will swap: the hook checks this same list, so it can
  -- never point a draw at a green file the recipe did not write.  The two
  -- copies are compared by tools/check.py.
  --
  --   sprites/red.png        the overworld walker (SPRITE_RED, 16x96)
  --   sprites/red_bike.png   the same on the BICYCLE
  --   battle/redb.png        the battle back pic, drawn at 2x until "Go!"
  --   trainer_card/red.png   the front pic Oak's intro, the card and the
  --                          Hall of Fame share
  --
  -- The rest are names an import may or may not have written; ctx.exists
  -- decides, and a cache without one simply keeps that picture as the base
  -- game drew it.
  --
  -- One absence is deliberate: the old man's demo back pic
  -- (battle/oldmanb.png) is not the player, and the catch tutorial should
  -- not turn green.
  --
  -- title/player.png is the figure holding the ball out on the title screen,
  -- and it is here for one mode only.  Everywhere else that rectangle is cut
  -- out of the true-colour region so the mon cycling behind him keeps its
  -- palette, and what is left is painted BY SHADE -- so the colour a
  -- recoloured file carries is thrown away and MEWMON does the work instead.
  -- Under ADVANCED the zone pass never reaches him, main.lua hands that draw
  -- this file, and the same face and hands the trainer card gets come with
  -- it.  main.lua's own bake stays as the fallback for a cache that has no
  -- such file.
  --
  -- `field` picks the ramp: true takes the overworld four and the mouth and
  -- bill rules, false takes the portrait four and neither.
  local PICS = {
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

  -- ------- the mouth is not clothing
  --
  -- Red's overworld mouth is one block of the CAP's colour sitting in the
  -- middle of his face, so a flat shade remap paints it green: in the field
  -- that read as green lips.  It cannot be told apart by shade, because it
  -- IS the outfit shade -- only by where it sits.
  --
  -- The rule: a shade-3 pixel with skin on both sides of it in the same row,
  -- within a few pixels, is enclosed by face and is not clothing.  The cap
  -- and the clothes are bounded by black, never by skin, so they are never
  -- caught by it.
  --
  -- ctx has no per-pixel verb, so this reaches for ImageData's own getPixel
  -- and mapPixel on the objects ctx hands over -- the same methods
  -- AssetTransform.recolor uses internally.  That is one step past the
  -- documented surface, so the whole thing is pcall'd: if those methods are
  -- ever not there, the picture falls back to the plain remap and comes out
  -- exactly as 1.1.1 drew it, green mouth and all, rather than not at all.

  local REACH = 3

  -- The bill is a SMALL patch of the face's shade, TOUCHING the cap, HIGH in
  -- its frame.  All three, because any two of them catch something else:
  --
  --   * small and touching clothing is also the HANDS, which sit beside the
  --     body lower down -- so the height matters;
  --   * touching and high is also the top of the FACE in some frames -- so
  --     the size matters;
  --   * small and high is also whatever else the cap has around it -- so the
  --     touching matters.
  --
  -- 1.1.3 looked only directly above a pixel and missed the profile frames,
  -- where the bill sticks out beside the cap rather than under it.  Region
  -- and neighbourhood, rather than one direction, is what covers all six
  -- frames of a walker sheet.
  local BILL_MAX = 8

  -- The overworld sheets are 16x16 frames stacked into one column (Art
  -- Pipeline: "Overworld character sprites").  The cap and its bill live in
  -- the top half of a frame; the hands are below it.
  local FRAME, BILL_ROWS = 16, 8

  local function shadeOf(r)
    if r > 0.83 then return 1 end
    if r > 0.5 then return 2 end
    if r > 0.17 then return 3 end
    return 4
  end

  local STEPS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

  -- ------- which parts of a portrait are skin
  --
  -- Vanilla's ramp on this art is monochrome, so a pixel's SHADE never says
  -- whether it is a cheek or a sleeve.  Worse, skin is not one shade: the
  -- face is drawn in shade 2 with its brow and mouth in shade 3, and the
  -- HANDS are drawn in shade 3 alone -- the same shade as the trousers and
  -- the cap.  Every rule up to 1.8.0 only ever looked at shade 2, so the
  -- hands and the ear were never reachable by any of them, and what it did
  -- reach on the arms was the jacket's own shading.
  --
  -- Read back out of the game, the card's four skin parts are:
  --
  --   the FACE   one patch of shade 2, 22px, high in the figure.
  --   the EAR    ONE pixel of shade 2 beside it, with one of shade 3 under
  --              it.  Not in any patch big enough to have a rule of its own.
  --   the HANDS  two patches of SHADE 3 -- 6px at the left hip, 7px at the
  --              right -- sitting past the edge of the shirt.
  --   the DETAIL small pieces of shade 3 inside or against skin: the brow,
  --              the mouth, the ear's own shadow.
  --
  -- and the four things that look like them and are not:
  --
  --   the cap's shading (19px of shade 2, sealed inside the cap);
  --   the jacket's shoulder and its sleeve shading (shade 2, and on the real
  --     art one pixel away from a hand on every local count there is);
  --   the collar (6px of shade 3, the same size and profile as a hand);
  --   the shirt's hem (4px of shade 3 past the shirt's edge).
  --
  -- So nothing here is decided by size or by colour alone.  Every rule is
  -- about WHERE a patch sits relative to the figure and to the biggest mass
  -- of ink in it, which is his shirt front.
  local FACE_BAND = 0.40   -- how far down the figure a face may begin
  local FACE_PAPER = 2     -- paper against it; a garment's shading has none
  local EAR_MAX = 2        -- an ear is a speck, not a patch
  local EAR_NEAR = 4       -- and it is right beside the face
  local HAND_MIN = 4       -- smaller than this out there is dither
  local HAND_MAX = 8       -- bigger is the trouser leg
  local HAND_INK = 4       -- outline around it: a hem strip has almost none
  local HAND_REACH = 2     -- rows past the shirt a hand may still start
  local DETAIL_MAX = 6     -- sealed inside skin: a brow, never a garment
  local SPECK_MAX = 2      -- or a speck against it: the ear's own shadow
  local GLINT_MAX = 2      -- a speck of the LIGHT shade inside a hand
  local TEMPLE_MAX = 3     -- and the specks between the hat and the face
  local TEMPLE_ROWS = 3    -- which is all the higher this ever looks
  local SIDEBURN_FACE = 4  -- skin running this far the other way: a cheek
  local SIDEBURN_OUT = { -1, 1 }   -- which way the ear is, hoisted out of
                                   -- the per-pixel test

  -- every 4-connected patch of one shade
  local function connected(shade, w, h, want)
    local id, list = {}, {}
    for y = 0, h - 1 do id[y] = {} end
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        if shade[y][x] == want and not id[y][x] then
          local n = #list + 1
          local pixels, stack = {}, { { x, y } }
          id[y][x] = n
          while #stack > 0 do
            local at = table.remove(stack)
            pixels[#pixels + 1] = at
            for _, step in ipairs(STEPS) do
              local nx, ny = at[1] + step[1], at[2] + step[2]
              if nx >= 0 and nx < w and ny >= 0 and ny < h
                  and shade[ny][nx] == want and not id[ny][nx] then
                id[ny][nx] = n
                stack[#stack + 1] = { nx, ny }
              end
            end
          end
          list[n] = pixels
        end
      end
    end
    return list
  end

  local function bounds(pixels)
    local top, bottom, left, right
    for _, at in ipairs(pixels) do
      local x, y = at[1], at[2]
      if not top or y < top then top = y end
      if not bottom or y > bottom then bottom = y end
      if not left or x < left then left = x end
      if not right or x > right then right = x end
    end
    return top, bottom, left, right
  end

  -- how many neighbours of a patch are paper, or are ink
  local function against(pixels, shade, w, h, paper)
    local n = 0
    for _, at in ipairs(pixels) do
      for _, step in ipairs(STEPS) do
        local nx, ny = at[1] + step[1], at[2] + step[2]
        if nx >= 0 and nx < w and ny >= 0 and ny < h then
          local s = shade[ny][nx]
          if paper then
            if s == 0 or s == 1 then n = n + 1 end
          elseif s == 4 then
            n = n + 1
          end
        end
      end
    end
    return n
  end

  -- -> the mask of skin, and the mask of the shade-3 detail inside it
  local function skinMask(shade, w, h)
    -- the drawn figure, ignoring the ground: "high in the picture" has to
    -- mean high in HIM, not high in a canvas that is mostly padding
    local top, bottom
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local s = shade[y][x]
        if s ~= 0 and s ~= 1 then
          if not top then top = y end
          if y > (bottom or -1) then bottom = y end
        end
      end
    end
    if not top then return nil, nil end
    local high = top + (bottom - top + 1) * FACE_BAND

    local light = connected(shade, w, h, 2)
    local mid = connected(shade, w, h, 3)

    -- the FACE: the biggest patch of shade 2 high in the figure with paper
    -- against it.  The cap's own shading is bigger than either hand and sits
    -- up there too, but it is sealed inside the cap and touches no paper.
    local face
    for _, pixels in ipairs(light) do
      local t = bounds(pixels)
      if t <= high and against(pixels, shade, w, h, true) >= FACE_PAPER
          and (not face or #pixels > #face) then
        face = pixels
      end
    end
    if not face then return nil, nil end

    local skin = {}
    local function paint(pixels)
      for _, at in ipairs(pixels) do
        skin[at[2]] = skin[at[2]] or {}
        skin[at[2]][at[1]] = true
      end
    end
    paint(face)

    local ftop, fbot, fleft, fright = bounds(face)

    -- the EAR: a speck of the same shade BESIDE the upper half of the face.
    -- Beside, because inside is the face already and below is the collar;
    -- upper half, because that is where an ear is and the chin is not.
    local earBottom = ftop + math.floor((fbot - ftop + 1) / 2)
    for _, pixels in ipairs(light) do
      if pixels ~= face and #pixels <= EAR_MAX then
        local t, b, l, r = bounds(pixels)
        if b >= ftop - 1 and t <= earBottom
            and (l > fright or r < fleft)
            and l <= fright + EAR_NEAR and r >= fleft - EAR_NEAR then
          paint(pixels)
        end
      end
    end

    -- the HANDS, which are shade 3 and not shade 2 at all.  The shirt front
    -- is the biggest mass of ink there is; a hand is a small patch past its
    -- edge, low enough to be at the hip rather than the shoulder, and ringed
    -- by outline -- which is what the shirt's own hem, out there at the same
    -- height and the same size, is not.
    local torso
    for _, pixels in ipairs(connected(shade, w, h, 4)) do
      if not torso or #pixels > #torso then torso = pixels end
    end
    local isHand = {}
    if torso then
      local vtop, vbot, vleft, vright = bounds(torso)
      local waist = (vtop + vbot) / 2
      for i, pixels in ipairs(mid) do
        local t, b, l, r = bounds(pixels)
        if #pixels >= HAND_MIN and #pixels <= HAND_MAX
            and b >= waist and t <= vbot + HAND_REACH
            -- reaching PAST the shirt's edge, not merely overlapping it: a
            -- hand at the hip still shares a column or two with the shirt
            and (l < vleft or r > vright)
            and against(pixels, shade, w, h, false) >= HAND_INK then
          isHand[i] = true
          paint(pixels)
        end
      end
    end

    -- the GLINT: a speck of the LIGHT shade sitting inside skin already
    -- painted.  Leaving it green puts a green pixel in the middle of a hand.
    --
    -- It takes the hand's own tone rather than the light one its shade would
    -- otherwise earn, which is the one place this file does not go by shade.
    -- At six pixels a hand is a fist, and a single lighter pixel inside a
    -- fist reads as the gap between two fingers, not as a highlight on it --
    -- so it goes in with the shadow and the hand comes out one colour.
    --
    -- It has to run after the hands, and it only ever looks at skin this
    -- pass has painted: every other light-shade speck on the picture is
    -- dither on the cap or the knees, and there are twenty-eight of those.
    local glint = {}
    for _, pixels in ipairs(light) do
      if #pixels <= GLINT_MAX then
        local touching, foreign = 0, false
        for _, at in ipairs(pixels) do
          for _, step in ipairs(STEPS) do
            local nx, ny = at[1] + step[1], at[2] + step[2]
            if nx >= 0 and nx < w and ny >= 0 and ny < h then
              if skin[ny] and skin[ny][nx] then touching = touching + 1
              elseif shade[ny][nx] == 2 then foreign = true end
            end
          end
        end
        if touching >= 2 and not foreign then
          glint[#glint + 1] = pixels
        end
      end
    end

    -- the TEMPLE: the specks of mid shade between the hat's underside and
    -- the face.  They touch no skin -- the hat's outline is in the way -- so
    -- nothing below can reach them, and they are the last of him that is
    -- still green.  Bounded to the rows just above the face, so the hat's
    -- own dither is never in range.
    local isTemple = {}
    for i, pixels in ipairs(mid) do
      local t, b = bounds(pixels)
      if #pixels <= TEMPLE_MAX and b < ftop and b >= ftop - TEMPLE_ROWS then
        isTemple[i] = true
      end
    end

    -- the DETAIL: shade 3 sealed inside skin -- the brow, the mouth -- or a
    -- speck of it against skin, which is the ear's own shadow.  All of it in
    -- the skin's shadow colour, the temple included: shade 3 is the shade
    -- BELOW the skin's own everywhere it appears.
    local detail = {}
    for i, pixels in ipairs(mid) do
      if isTemple[i] and not isHand[i] then
        for _, at in ipairs(pixels) do
          detail[at[2]] = detail[at[2]] or {}
          detail[at[2]][at[1]] = true
        end
      elseif not isHand[i] and #pixels <= DETAIL_MAX then
        local sealed, touching = true, 0
        for _, at in ipairs(pixels) do
          for _, step in ipairs(STEPS) do
            local nx, ny = at[1] + step[1], at[2] + step[2]
            if nx < 0 or nx >= w or ny < 0 or ny >= h then
              sealed = false
            else
              local s = shade[ny][nx]
              if s == 2 then
                if skin[ny] and skin[ny][nx] then touching = touching + 1
                else sealed = false end
              elseif s == 0 or s == 1 then
                sealed = false
              end
            end
          end
        end
        if touching > 0 and (#pixels <= SPECK_MAX or sealed) then
          for _, at in ipairs(pixels) do
            detail[at[2]] = detail[at[2]] or {}
            detail[at[2]][at[1]] = true
          end
        end
      end
    end

    for _, pixels in ipairs(glint) do
      for _, at in ipairs(pixels) do
        detail[at[2]] = detail[at[2]] or {}
        detail[at[2]][at[1]] = true
      end
    end

    return skin, detail
  end

  -- ------- title/player.png, which is painted rather than reasoned about
  --
  -- Every other picture here is recoloured by rules, because a rule works on
  -- whatever the player's cache actually holds.  This one is not, and the
  -- reason is that the rules cannot express it.  Of the 95 pixels that are
  -- not plain ramp on that figure, FOURTEEN come from the paper shade -- the
  -- lit side of his face and the back of a hand, drawn in white -- and eight
  -- go to ink.  No rule in this file touches white at all, and inventing one
  -- to fit a single sprite is not a rule, it is a drawing with extra steps.
  --
  -- So it is a drawing.  The table below is a list of "at this row and
  -- column, with this shade underneath, paint this", authored by eye against
  -- the figure on the title screen.  It carries no pixels of the vanilla art
  -- -- the art stays in the player's own cache, as everything here does, and
  -- the other two thousand pixels of this picture are still whatever their
  -- import wrote.  What it carries is where a face is.
  --
  -- Each entry is row.col.shade.tone:
  --
  --   shade  what must be under it: 1 paper, 2 light, 3 mid, 4 ink
  --   tone   1 skin, 2 the skin's shadow, 3 ink
  --
  -- The shade is the guard, and it is why this is safe to ship.  Every entry
  -- has to find the shade it was authored against; a cache whose figure
  -- differs -- a translation, a conversion, a different rip -- fails those
  -- checks and the picture falls through to the ordinary rules instead of
  -- being painted somewhere it should not be.  ENTRIES_MIN is how much of it
  -- has to match before it is believed at all.
  local TITLE_PIC = "title/player.png"
  local TABLE_MIN = 0.9
  local TABLE_TONE = { WILD_GREEN[2], SKIN_DARK, { 0x00, 0x00, 0x00 } }
  local TITLE_TABLE =
    "13.22.3.2 13.23.2.1 13.26.3.2 13.27.3.2 13.30.3.2 14.18.3.2 "
    .. "14.21.2.1 14.22.2.1 14.23.2.1 14.26.2.1 14.29.2.1 15.18.2.1 "
    .. "15.21.2.1 15.22.2.1 15.23.2.1 15.24.2.1 15.25.2.1 15.26.2.1 "
    .. "15.29.3.2 16.18.2.1 16.19.2.1 16.20.2.1 16.21.3.2 16.22.2.1 "
    .. "16.23.2.1 16.24.2.1 16.25.2.1 17.18.2.1 17.19.2.1 17.20.2.1 "
    .. "17.21.2.1 17.22.2.1 17.23.2.1 17.24.2.1 17.25.2.1 18.19.3.2 "
    .. "18.20.2.1 18.21.2.1 18.22.3.2 18.24.2.1 19.21.3.2 19.22.2.1 "
    .. "19.23.2.1 19.24.2.1 20.24.3.2 21.24.2.1 22.23.2.1 22.24.2.1 "
    .. "22.25.2.1 24.24.3.3 25.23.3.3 25.25.3.3 26.1.2.1 26.2.1.2 "
    .. "26.24.3.3 27.2.2.1 27.4.2.1 27.6.1.2 27.12.3.3 27.13.1.2 27.14.2.1 "
    .. "27.23.3.3 27.25.3.3 28.1.2.1 28.4.2.1 28.6.2.1 28.11.2.1 28.12.1.2 "
    .. "28.13.1.2 28.14.2.1 28.15.2.1 28.24.3.3 29.11.2.1 29.12.2.1 "
    .. "29.13.2.1 29.14.2.1 30.11.2.1 30.12.2.1 30.13.2.1 31.13.3.2 "
    .. "31.33.2.2 31.34.1.1 32.33.2.2 32.34.1.1 32.35.1.1 32.36.3.2 "
    .. "33.33.2.2 33.34.2.2 33.35.1.1 34.34.2.2 38.34.1.1 39.34.1.1 "
    .. "39.37.1.1 40.36.1.1 40.37.1.1 "

  -- ------- battle/redb.png, which is painted for the same reason
  --
  -- The battle BACK pic had no skin on it at all: he was one green shape
  -- from the cap to the boots, which is what "the battle sprites are still
  -- all green" was looking at.  It is not that a rule got it wrong -- no
  -- rule ever reached it.  `skinMask` is built around finding a FACE and
  -- returns nothing the moment it cannot, and every rule it has after that
  -- -- the ear, the hands, the glint, the temple -- is placed relative to
  -- the face's own bounds.  On the back of his head there is no face, so
  -- the picture fell through to the plain ramp and stayed there.  The
  -- greenskin/ copy came out identical to the green/ one, which is why
  -- PORTRAIT SKIN appeared to do nothing on it.
  --
  -- What is actually skin on it is two pieces: the NECK and jaw below the
  -- cap, and the HAND and forearm at his lower right.
  --
  -- This one gets a table rather than a rule, and it is the same argument
  -- the title figure makes above.  Of its 33 skin pixels ELEVEN come from
  -- the PAPER shade -- the back of the hand is drawn in white -- and no
  -- rule in this file touches white.  A white patch is not distinguishable
  -- from the ground by shade, only by what surrounds it, and there is
  -- exactly one sprite in the game shaped like this: it is a single fixed
  -- 32x32 picture, not a sheet of frames a rule has to generalise over.
  -- Inventing a rule to fit one sprite is, as the title figure puts it, a
  -- drawing with extra steps.
  --
  -- The same guard makes it safe: every entry names the shade it was
  -- authored against, so a cache holding a different back pic fails the
  -- checks, `tableMask` returns nil, and the picture comes out exactly as
  -- it does today rather than skin-toned in the wrong places.  It carries
  -- no pixels of the vanilla art -- 33 coordinates out of 489 drawn ones,
  -- and what they carry is where his neck and his hand are.
  local BACK_PICS = { ["battle/redb.png"] = true,
                      ["battle/back/redb.png"] = true }
  local BACK_TABLE =
    "9.17.3.2 9.18.3.2 10.18.2.1 11.16.2.1 12.16.2.1 12.20.3.2 "
    .. "13.15.3.2 13.17.2.1 14.13.3.2 14.14.2.1 14.15.2.1 14.16.2.1 "
    .. "14.17.2.1 14.18.2.1 15.10.3.2 15.11.3.2 15.12.3.2 15.15.3.2 "
    .. "15.16.3.2 15.18.3.2 19.25.3.2 20.23.1.2 20.24.1.1 20.25.1.1 "
    .. "21.23.1.1 21.24.1.1 21.25.1.1 22.24.1.1 22.25.1.1 22.26.1.1 "
    .. "22.27.3.2 23.25.1.1 23.26.1.1 "

  -- The engine lifts an 8x8 POKE BALL out of this file at (0,16) and draws
  -- it on its own, at a y of its own that moves while the title animates
  -- (TitleState: newQuad(0, 16, 8, 8), drawn at 82, self.ballY).  It is a
  -- ball, not the player -- so it keeps vanilla's own red rather than going
  -- green with his jacket, the same argument the overworld MOUTH rule makes.
  --
  -- No coordinates for it: the rect is the engine's constant, so the ball is
  -- wherever the file says and the table never has to name it.  Which is
  -- just as well, because in a screenshot it is never where it lives.
  local BALL_RAMP = {
    { 0xff, 0xff, 0xff },
    { 0xec, 0xa8, 0x78 },
    { 0xd8, 0x40, 0x30 },
    { 0x00, 0x00, 0x00 },
  }
  local BALL_X, BALL_Y, BALL_W, BALL_H = 0, 16, 8, 8

  -- ------- reading a table against a picture
  --
  -- Two pictures carry tables.  The guard is the same for both: every entry
  -- has to find the shade it was authored against, and TABLE_MIN is how much
  -- of a table has to match before any of it is believed.
  --
  -- ------- and why the coordinates are not absolute any more
  --
  -- A table is a list of coordinates, so it only ever found the art it was
  -- drawn against sitting exactly where it sat.  A cache holding the SAME
  -- sprite one pixel over -- an importer that pads differently, a rip on a
  -- larger sheet, a canvas that is not 32x32 -- failed all 33 guards at once
  -- and the picture fell through to the flat ramp.  That is the whole of
  -- what a table could not reach, and it is placement, not pixels.
  --
  -- So the table is matched at its own coordinates FIRST -- which is exactly
  -- what this did before, so art that worked keeps working, byte for byte --
  -- and only if that fails is it slid over the picture looking for the
  -- offset it does fit at.
  --
  -- It cannot wander into painting something else.  A run has to clear the
  -- same TABLE_MIN it always did, which on the back pic means 30 of 33
  -- entries landing on the right shade across THREE different shades in one
  -- fixed arrangement -- a flat region cannot do that, whatever it is made
  -- of.  And the best offset has to be the ONLY best one: two offsets
  -- reading equally well is an ambiguous picture, and an ambiguous picture
  -- is left alone rather than painted at the first of them.
  --
  -- What is still out of reach is art whose PIXELS differ, and that is on
  -- purpose.  There is no rule underneath this to fall back to -- on the
  -- back pic the hand cannot be told from the sleeve's own white by size,
  -- by height, or by reaching past the body, because the sleeve does all
  -- three; only by where it sits.  A rule tuned tight enough to separate
  -- them would BE this table, and would fail open on art it has never seen
  -- instead of quietly leaving it alone.  Failing closed is the feature.
  local function parseTable(spec)
    local entries, minRow, maxRow, minCol, maxCol
    entries = {}
    for row, col, want, tone in spec:gmatch("(%d+)%.(%d+)%.(%d+)%.(%d+)") do
      row, col = tonumber(row), tonumber(col)
      entries[#entries + 1] = { row, col, tonumber(want), tonumber(tone) }
      if not minRow or row < minRow then minRow = row end
      if not maxRow or row > maxRow then maxRow = row end
      if not minCol or col < minCol then minCol = col end
      if not maxCol or col > maxCol then maxCol = col end
    end
    return entries, minRow, maxRow, minCol, maxCol
  end

  -- how many of a table's entries find their shade with the table shifted
  -- by (dy, dx); an entry off the edge simply does not match
  local function scoreTable(entries, shade, w, h, dy, dx)
    local found = 0
    for i = 1, #entries do
      local e = entries[i]
      local row, col = e[1] + dy, e[2] + dx
      if row >= 0 and row < h and col >= 0 and col < w
          and shade[row][col] == e[3] then
        found = found + 1
      end
    end
    return found
  end

  -- the tones of the entries that DID match, which is the mask; an entry
  -- that missed its shade paints nothing, as it never did
  local function paintTable(entries, shade, w, h, dy, dx)
    local mask = {}
    for i = 1, #entries do
      local e = entries[i]
      local row, col = e[1] + dy, e[2] + dx
      if row >= 0 and row < h and col >= 0 and col < w
          and shade[row][col] == e[3] then
        mask[row] = mask[row] or {}
        mask[row][col] = TABLE_TONE[e[4]]
      end
    end
    return mask
  end

  -- -> a mask of tones for a picture that carries a table, or nil
  local function tableMask(spec, shade, w, h)
    local entries, minRow, maxRow, minCol, maxCol = parseTable(spec)
    local total = #entries
    if total == 0 then return nil end

    -- where it was authored, which is where it has always looked
    if scoreTable(entries, shade, w, h, 0, 0) / total >= TABLE_MIN then
      return paintTable(entries, shade, w, h, 0, 0)
    end

    -- the same figure, somewhere else on the canvas
    local best, bestDy, bestDx, ties = -1, 0, 0, 0
    for dy = -minRow, h - 1 - maxRow do
      for dx = -minCol, w - 1 - maxCol do
        local n = scoreTable(entries, shade, w, h, dy, dx)
        if n > best then
          best, bestDy, bestDx, ties = n, dy, dx, 1
        elseif n == best then
          ties = ties + 1
        end
      end
    end
    if ties ~= 1 or best / total < TABLE_MIN then return nil end
    return paintTable(entries, shade, w, h, bestDy, bestDx)
  end

  local function recoloured(rel, field, wantSkin, suit)
    local ramp = field and suit.ramp or suit.picRamp
    local BILL = suit.bill
    local bill = field
    local src = ctx.readImage(rel)
    local out = ctx.readImage(rel)
    local w, h = src:getDimensions()

    -- every pixel's shade up front: the rules below ask about neighbours, and
    -- reading them back out of the image being written would see its own work
    local shade = {}
    for y = 0, h - 1 do
      shade[y] = {}
      for x = 0, w - 1 do
        local r, _, _, a = src:getPixel(x, y)
        shade[y][x] = (a == 0) and 0 or shadeOf(r)
      end
    end

    local function shadeAt(x, y)
      if x < 0 or x >= w or y < 0 or y >= h then return nil end
      return shade[y][x]
    end

    -- the first shade either side that is not shade 3, within REACH
    local function beside(x, y, step)
      for d = 1, REACH do
        local other = shadeAt(x + step * d, y)
        if other == nil or other ~= 3 then return other end
      end
      return nil
    end

    -- flood the shade-2 regions; the small ones that touch the cap are bill
    local isBill = {}
    if bill and h % FRAME == 0 then
      local seen = {}
      local function mark(x, y)
        seen[y] = seen[y] or {}
        if seen[y][x] then return false end
        seen[y][x] = true
        return true
      end
      for y = 0, h - 1 do
        for x = 0, w - 1 do
          if shade[y][x] == 2 and mark(x, y) then
            local stack, region, touchesCap = { { x, y } }, {}, false
            while #stack > 0 do
              local at = table.remove(stack)
              region[#region + 1] = at
              for _, step in ipairs(STEPS) do
                local nx, ny = at[1] + step[1], at[2] + step[2]
                local s = shadeAt(nx, ny)
                if s == 3 then
                  touchesCap = true
                elseif s == 2 and mark(nx, ny) then
                  stack[#stack + 1] = { nx, ny }
                end
              end
            end
            local high = true
            for _, at in ipairs(region) do
              if at[2] % FRAME >= BILL_ROWS then high = false break end
            end
            if touchesCap and high and #region <= BILL_MAX then
              for _, at in ipairs(region) do
                isBill[at[2]] = isBill[at[2]] or {}
                isBill[at[2]][at[1]] = true
              end
            end
          end
        end
      end
    end

    -- only asked for on the skinned copy of a portrait; nil is the answer
    -- that leaves the picture monochrome
    local skin, detail, painted
    if (not field) and wantSkin then
      if rel == TITLE_PIC then
        painted = tableMask(TITLE_TABLE, shade, w, h)
      elseif BACK_PICS[rel] then
        painted = tableMask(BACK_TABLE, shade, w, h)
      end
      if not painted then skin, detail = skinMask(shade, w, h) end
    end
    local ball = rel == TITLE_PIC

    -- ------- the mouth, facing down and facing sideways
    --
    -- Facing down the mouth has cheek on both sides of it, and that alone
    -- tells it from the cap and the collar, which are bounded by black.
    --
    -- In PROFILE it does not.  Read off the walking frames, the sideways
    -- mouth is a single pixel of the outfit's shade with skin on one side
    -- and the silhouette's own outline on the other -- so the both-sides
    -- test misses it and the lips came out green whenever he faced left or
    -- right.  What is still true of it there is what is ABOVE it: cheek.
    -- The cap is never under skin, and the collar has the chin's black
    -- above it rather than the chin.
    --
    -- Except under the hat's own bill, which IS skin, and directly above
    -- the cap's bottom row -- so a bill pixel does not count as a face.
    -- The fixture has exactly that pixel in it, with skin beside it too.
    local function mouthAt(x, y)
      local left, right = beside(x, y, -1), beside(x, y, 1)
      if left == 2 and right == 2 then return true end
      if left ~= 2 and right ~= 2 then return false end
      if shadeAt(x, y - 1) ~= 2 then return false end
      return not (isBill[y - 1] and isBill[y - 1][x])
    end

    -- The sideburn: the tip of the hair between the cap and the ear.
    --
    -- Vanilla draws it as ONE pixel and does not draw it the same in both
    -- forward-facing walk frames -- skin in the one with his arms out, ink
    -- in the other.  In the grey art that alternation is a light pixel and
    -- a black one against a grey cap and reads as shading; here shade 2 is
    -- flesh and shade 3 is a green cap, so the same two pixels swing
    -- between orange and black and read as the hair flickering.
    --
    -- So it is held to skin in both frames.  Nothing is darkened: the frame
    -- that already draws them skin is untouched, and this repaints only the
    -- frame that draws them ink.
    --
    -- Eleven conditions, because a looser test also finds the hairline
    -- above the eye in the profile frames, which is hair and must stay
    -- black.  What is only true of the sideburn is the EAR: on the row
    -- below, outward, an outline pixel, one pixel of skin, then outline
    -- again -- with the cheek running the other way, which is what says
    -- this is the head's outer edge and not somewhere in the middle of it.
    local function sideburnAt(x, y)
      if shadeAt(x, y - 1) ~= 4 or shadeAt(x, y - 2) ~= 3 then return false end
      if shadeAt(x - 1, y) ~= 4 or shadeAt(x + 1, y) ~= 4 then return false end
      if shadeAt(x, y + 1) ~= 2 then return false end
      for _, d in ipairs(SIDEBURN_OUT) do
        if shadeAt(x + d, y + 1) == 4 and shadeAt(x + 2 * d, y + 1) == 2
            and shadeAt(x + 3 * d, y + 1) == 4 then
          local cheek = true
          for k = 1, SIDEBURN_FACE do
            if shadeAt(x - d * k, y + 1) ~= 2 then cheek = false break end
          end
          if cheek then return true end
        end
      end
      return false
    end

    out:mapPixel(function(x, y, r, g, b, a)
      if a == 0 then return r, g, b, a end
      local s = shade[y][x]
      local colour = ramp[s]
      if ball and x >= BALL_X and x < BALL_X + BALL_W
          and y >= BALL_Y and y < BALL_Y + BALL_H then
        -- the ball the title screen throws: vanilla's own, not his outfit's
        colour = BALL_RAMP[s]
      elseif painted then
        -- the one picture with a table: what it says, or the plain ramp
        colour = (painted[y] and painted[y][x]) or ramp[s]
      elseif not field then
        -- The portrait: the ramp, and the skin if any was found.  Skin is
        -- the skin tone; the shadow tone is for the pieces the DETAIL pass
        -- picked out -- the brow, the mouth, the ear's underside, the temple
        -- under the hat, and the speck inside a hand.
        --
        -- 1.11.0 tried colouring by the pixel's own shade instead, so that a
        -- hand drawn wholly in the mid shade came out shadowed.  On this art
        -- that reads as a hand in shadow rather than a hand, and it is not
        -- what the picture wants: a hand is skin, and only the crease in it
        -- is the shadow.  Which pieces are shadow is the detail pass's
        -- answer, not the shade's.
        if skin and skin[y] and skin[y][x] then
          -- the skin, which is the same in every suit
          colour = WILD_GREEN[2]
        elseif detail and detail[y] and detail[y][x] then
          colour = SKIN_DARK
        end
      elseif s == 3 and mouthAt(x, y) then
        -- a mouth: the outfit's shade, but sitting in the face
        colour = MOUTH
      elseif s == 2 and isBill[y] and isBill[y][x] then
        colour = BILL
      elseif s == 4 and sideburnAt(x, y) then
        -- the hair's tip between cap and ear: skin in every frame, so it
        -- stops flickering as he walks
        colour = ramp[2]
      end
      return colour[1] / 255, colour[2] / 255, colour[3] / 255, a
    end)
    return out
  end

  -- Every suit gets the whole set.  Nine colours by nine pictures, plus a
  -- skinned twin for each of the portraits -- so the option is a path
  -- change at load rather than a re-run of this file, and switching colour
  -- costs nothing at all.  All of it is small art: 16x96 walker sheets and
  -- 56x56 portraits, and this runs once on install.
  --
  -- The prefix is the suit's own id, which matches nothing the importer
  -- writes and therefore shadows nothing -- the same reason "green/" was
  -- chosen, now nine times over.  RED needs no prefix and gets none: it is
  -- the vanilla cache, untouched.
  for _, entry in ipairs(SUITS) do
    local suit = suitOf(entry)
    for _, pic in ipairs(PICS) do
      local rel, field = pic[1], pic[2]
      -- A cache that does not carry one of these is a cache from a version or
      -- an import that never made it, not a broken install: skip it and leave
      -- that picture as the base game drew it.
      if ctx.exists(rel) then
        local ok, image = pcall(recoloured, rel, field, false, suit)
        if not ok then
          -- the per-pixel path is one step past the documented ctx, so its
          -- absence costs the position rules and nothing else
          image = ctx.recolor(ctx.readImage(rel),
            field and suit.ramp or suit.picRamp)
        end
        ctx.writeImage(image, suit.id .. "/" .. rel)

        -- A second copy of every portrait with the face painted skin, which
        -- is what the PORTRAIT SKIN row picks between.  Two files rather than
        -- one decided here, because the recipe runs at install and never sees
        -- the options -- and because it makes the rule something a player can
        -- turn off in a menu rather than something that needs a release to
        -- undo.
        --
        -- When the rule finds no face the two copies are identical, so the
        -- row is a no-op on that picture rather than broken.  The battle BACK
        -- pic is exactly that case: there is no face on it to find.
        if not field then
          local okSkin, skinned = pcall(recoloured, rel, field, true, suit)
          ctx.writeImage(okSkin and skinned or image, suit.id .. "skin/" .. rel)
        end
      end
    end
  end
end
