-- Gen1ModernBag: the item icons.
--
-- Returns a factory: factory(mod) -> a table of helpers.
--
-- The same file Gen1ItemInfo carries, and carried rather than depended on for
-- the reason that suite gives everywhere else it copies sixty lines: a Bag
-- that refuses to draw a picture until you also install an item-description
-- mod is a worse trade than a second copy of a loader.  Anything changed here
-- should be changed there.  The assets under assets/items/ are the same set
-- and are built by the same script.
--
-- ------- what an icon is
--
-- A 16x16 PNG under assets/items/, named for the item id in lower case:
-- POTION is potion.png, MAX_ELIXER is max_elixer.png.  Nothing lists them
-- here.  The folder IS the list -- an id with no file is an item with no
-- icon, which is a blank column and not an error -- so adding one is dropping
-- a PNG in, and a mod that adds an item can be given an icon without this
-- file learning its name.
--
-- Sixteen because that is the height of a list row.  Every list in this game
-- puts its rows sixteen pixels apart, the mart's and the item PC's and the
-- bag's alike, and an icon taller than its row overlaps the one above it.
-- The art is Polished Crystal's, which draws items at 24, so
-- tools/make_item_icons.py is what steps it down and where the choice of
-- which of their icons stands for which Gen 1 item is written out.  See
-- CREDITS.md: the icons are that project's work, not this one's.
--
-- ------- the machines are the exception
--
-- Fifty TMs and five HMs, and there is no art for any of them anywhere.  So
-- they are the one thing here drawn rather than sourced: a disc in the colour
-- of the type of the move it teaches -- tm_fire.png, hm_water.png -- which is
-- how every generation since Gen 3 has drawn a machine, and the only thing
-- that tells TM24 from TM25 in a pocket of fifty-five four-letter rows.
--
-- The type is read off the MOVE, through the item's own `machine.move`, and
-- not off a table here.  Same reason main.lua builds a machine's description
-- that way: a mod that retunes what TM26 teaches would leave a hand-written
-- table lying, and this way it cannot.  A machine whose move has a type
-- nothing has drawn falls back to the plain tm.png / hm.png.
--
-- ------- an item may name its own
--
-- `data.items[id].icon`, if it is a string, is a path and it wins.  Which is
-- the same shape `description` has -- the field goes on the ITEM, so anything
-- can read it and anything can set it -- and it means a sprite pack, or a mod
-- that adds an item, can hand its own art to every screen in the suite
-- without this mod being told.  What is here is the fallback, not the rule.

return function(mod)

  -- ------- the matte behind true-colour art
  --
  -- `PaletteFX.markTrueColor` blits a rectangle RAW so a coloured icon keeps
  -- its own colours instead of being read as four shades.  Raw means raw: the
  -- white page under it stays white when everything around it goes black,
  -- which is the white box behind every icon on a dark screen.
  --
  -- So the rectangle is painted with what the theme will make of it BEFORE
  -- the art goes in.  Only ever inside a rectangle about to be marked -- a
  -- dark rectangle anywhere else is shade-3 pixels, which the theme maps to
  -- the page's ink and puts a hole in the page.
  --
  -- Under LIGHT the colour is white, which is what this drew before the theme
  -- existed, so a build with no theme in it is unchanged.
  local function matte(x, y, w, h)
    local theme = type(mod.theme) == "function" and mod.theme() or nil
    local colour = theme and type(theme.matte) == "function"
      and theme.matte() or nil
    if type(colour) ~= "table" then return end
    love.graphics.setColor(colour[1] / 255, colour[2] / 255, colour[3] / 255, 1)
    love.graphics.rectangle("fill", x, y, w, h)
  end
  local W, H = 16, 16
  local DIR = "assets/items/"

  -- The palette pass repaints the frame through the zone's four shades, and
  -- an icon is not four shades of anything.  Marking the rectangle it landed
  -- in is what exempts it -- the same call Gen1Dex marks a true-colour sprite
  -- with.  Absent on a build without it, which costs the icons their colour
  -- and nothing else.
  local okFX, PaletteFX = pcall(require, "src.render.PaletteFX")
  if not okFX then PaletteFX = nil end

  local C = { W = W, H = H }

  -- Every path asked for, hit or miss.  `false` is a file that is not there,
  -- and it is cached as hard as an image is: a pocket of fifty items with no
  -- icon would otherwise ask the filesystem for fifty missing files on every
  -- frame it is open.
  local images = {}


  -- ------- an icon on dark paper
  --
  -- These icons carry no white at all.  Every one of the 106 draws its line
  -- work in pure black on transparency, because the art was made to sit on
  -- the white page: the page is the POKe BALL's lower half, and the black
  -- outline around it is what makes the shape.
  --
  -- 0.6.0 painted the cell the colour the page was about to be, so on a dark
  -- page the ball lost its paper AND kept a black outline nobody could see
  -- against black.  A POKe BALL came out a red blob.
  --
  -- The first attempt at this was a flood fill -- find the transparent pixels
  -- the outline encloses and make them white.  It does not work, and the
  -- reason is worth writing down: the outlines are NOT CLOSED.  They never had
  -- to be, because inside and outside were both the same white page, so the
  -- ball's lower edge is a few disconnected strokes and a fill leaks straight
  -- through them.
  --
  -- What is true of every one of these files is the line work.  So on dark
  -- paper the ink is swapped, the way the theme swaps it everywhere else: a
  -- pure-black opaque pixel is drawn white and every other pixel is left
  -- exactly as it is.  A POKe BALL keeps its red dome and reads as a white
  -- outline over the dark page, which is what a line drawing inverts to and
  -- is what the rest of the screen has already done.
  --
  -- Built once per file, beside the original, and only when the pixels are
  -- reachable.  A build where they are not draws the plain image, which is
  -- what it drew before this existed.
  local function inkSwapped(data)
    local w, h = data:getDimensions()
    local swapped = false
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local r, g, b, a = data:getPixel(x, y)
        if a > 0 and r == 0 and g == 0 and b == 0 then
          data:setPixel(x, y, 1, 1, 1, a)
          swapped = true
        end
      end
    end
    return swapped
  end

  -- The pixels of a file, or nil.  Two ways in because a mod reaches
  -- love.image directly on one build and through the engine's own resolver on
  -- another; either answers, and neither answering is not fatal.
  local function pixelsOf(path)
    if love and love.image and love.image.newImageData then
      local ok, data = pcall(love.image.newImageData, path)
      if ok and data then return data end
    end
    local okAssets, Assets = pcall(require, "src.render.Assets")
    if okAssets and type(Assets) == "table" and Assets.imageData then
      local ok, data = pcall(Assets.imageData, path)
      if ok and data then return data end
    end
    return nil
  end

  -- light image -> its ink-swapped twin.  Weak keys, so a twin goes when the
  -- image it belongs to does.
  local darkTwin = setmetatable({}, { __mode = "k" })

  local function load(path)
    local cached = images[path]
    if cached ~= nil then return cached or nil end
    local ok, image = pcall(love.graphics.newImage, path)
    if ok and image then
      -- Pixel art inside a 160x144 frame that is integer-scaled afterwards;
      -- anything but nearest turns a 16-pixel icon to soup.
      pcall(image.setFilter, image, "nearest", "nearest")
      local data = pixelsOf(path)
      local okSwap, swapped = false, false
      if data then okSwap, swapped = pcall(inkSwapped, data) end
      if okSwap and swapped then
        local madeOk, twin = pcall(love.graphics.newImage, data)
        if madeOk and twin then
          pcall(twin.setFilter, twin, "nearest", "nearest")
          darkTwin[image] = twin
        end
      end
      images[path] = image
    else
      images[path] = false
    end
    return images[path] or nil
  end

  -- Is the paper this icon is about to sit on dark?  Asked of the theme's own
  -- matte rather than of its name, so the question is the one that matters --
  -- what colour is behind this -- and a theme that grows a third answer needs
  -- no change here.
  local function onDarkPaper()
    local theme = type(mod.theme) == "function" and mod.theme() or nil
    if not (theme and type(theme.matte) == "function") then return false end
    local colour = theme.matte()
    if type(colour) ~= "table" or #colour < 3 then return false end
    return (0.2126 * colour[1] + 0.7152 * colour[2] + 0.0722 * colour[3]) < 128
  end

  local function shipped(stem)
    return load(tostring(mod.path) .. "/" .. DIR .. stem .. ".png")
  end

  -- TM or HM off the id, which is what the engine itself does everywhere it
  -- needs to know (BagMenu's unsellable check, ShopMenu's), and the type off
  -- the move the machine carries.
  local function machine(game, def, id)
    local kind = id:find("^HM_") and "hm" or "tm"
    local moves = game and game.data and game.data.moves
    local move = moves and def.machine.move and moves[def.machine.move]
    local element = type(move) == "table" and move.type
    if type(element) == "string" and element ~= "" then
      local typed = shipped(kind .. "_" .. element:lower())
      if typed then return typed end
    end
    return shipped(kind)
  end

  -- The icon for an item, or nil.  Nil is an ordinary answer -- a badge has
  -- no icon, and neither does an item a mod added -- and the row is drawn
  -- without one.
  -- for tests/itemicons_test.lua, which has no love to load a file with
  C.inkSwapped = inkSwapped

  function C.of(game, id)
    if type(id) ~= "string" or id == "" then return nil end
    local items = game and game.data and game.data.items
    local def = items and items[id]

    if type(def) == "table" and type(def.icon) == "string" then
      local own = load(def.icon)
      if own then return own end
    end

    if type(def) == "table" and type(def.machine) == "table" then
      return machine(game, def, id)
    end

    return shipped(id:lower())
  end

  -- White before the image or its colours come out multiplied by whatever the
  -- caller last set -- black leaves a silhouette, which is exactly what the
  -- chrome around these rows is drawing in.  Black again on the way out, so a
  -- caller can keep drawing text without knowing this happened.
  function C.draw(image, x, y)
    if not image then return end
    -- the page under the icon, before the icon: a marked rectangle is blitted
    -- raw, so the white it was cleared to survives a dark page unless this
    -- paints over it first
    if PaletteFX and PaletteFX.markTrueColor then
      matte(x, y, W, H)
    end
    if onDarkPaper() then image = darkTwin[image] or image end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, x, y)
    if PaletteFX and PaletteFX.markTrueColor then
      pcall(PaletteFX.markTrueColor, x, y, W, H)
    end
    love.graphics.setColor(0, 0, 0, 1)
  end

  -- Both at once, for the ordinary case.
  function C.drawFor(game, id, x, y)
    local image = C.of(game, id)
    C.draw(image, x, y)
    return image
  end

  return C
end
