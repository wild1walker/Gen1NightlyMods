-- The statics, retryable until they are caught.
--
-- Vanilla's rule is the same cruelty it is in Red: a static is not a rare
-- encounter, it is a saving throw.  Knock LUGIA out by accident, or panic and
-- run, and that species is gone from the file forever.  The countermeasure
-- players actually use is to save in front of it and reset on a bad outcome,
-- which is not a mechanic, it is a workaround for one.
--
-- Gen151 fixes this by clearing EVENT_BEAT_<SPECIES> and putting the object
-- back.  That is exactly what NOT to do here, and finding out why is most of
-- what this file knows.
--
-- ------- why the flag is never touched
--
-- Gen 1's EVENT_BEAT_* flags mean one thing.  Gen 2's EVENT_FOUGHT_* flags
-- are load-bearing for unrelated progression:
--
--   EVENT_FOUGHT_SUDOWOODO   the GOLDENROD flower shop and the ROUTE 35 gate
--   EVENT_FOUGHT_SNORLAX     a VICTORY ROAD GATE object, and IRWIN's gossip
--   EVENT_FOUGHT_SUICUNE     the WISE TRIO and the TIN TOWER entrance --
--                            which is to say HO-OH's entire chain
--   EVENT_FOUGHT_HO_OH       four separate reads in TIN TOWER 1F
--
-- Clearing EVENT_FOUGHT_SUICUNE to give a player their SUICUNE back could
-- take HO-OH away from them.  So nothing here writes an event flag at all.
--
-- ------- what it does instead
--
-- Each static's object carries its OWN visibility flag, which is what
-- `disappear` sets and what World:appearObject clears
-- (src/world/gen2/World.lua:1932) -- separate from the FOUGHT flag entirely.
-- The map's MAPCALLBACK_OBJECTS hides the object again on every load, reading
-- the FOUGHT flag; this puts it back afterwards, on every entry, reading
-- whether the player actually owns the species.
--
-- So the flag stays set, every script that depends on it keeps its answer,
-- and the bird is standing on its perch again.  It is idempotent by
-- construction: it can run on every map entry forever and do nothing until
-- there is something to do, and it quietly repairs a save that lost one
-- before this mod was installed.
--
-- ------- the two that are not here
--
-- SUDOWOODO and SUICUNE are excluded, and not for want of trying.  Both are
-- driven by a map SCENE rather than by an object you can walk up to and talk
-- to, so putting the object back does not put the encounter back:
--
--   SUDOWOODO  Route 36 runs `variablesprite SPRITE_WEIRD_TREE, SPRITE_TWIN`
--              after the battle.  The object that would come back is a TWIN,
--              carrying a twin's script, and talking to it does not start a
--              battle with anything.
--   SUICUNE    TIN TOWER 1F's object is approached by a scripted movement
--              inside a scene.  Re-appearing it puts a SUICUNE on the tiles
--              with no path back into the script that battles it.
--
-- Restoring either means re-entering a scene rather than un-hiding an object,
-- which is a different and much more invasive operation than this file
-- performs.  They are named here rather than quietly missing.

local Statics = {}

-- species -> { map, object }
--
-- The object names are the cart's own object_const_def labels, which is what
-- the map def carries and what WorldAPI:toggleObject matches on.  Every one
-- of the three has an UNGUARDED script -- faceplayer, text, loadwildmon,
-- startbattle -- so an object that is back on the map is an encounter that is
-- back, with no flag to clear and no scene to re-enter.
Statics.ROSTER = {
  LUGIA = { map = "WHIRL_ISLAND_LUGIA_CHAMBER",
            object = "WHIRLISLANDLUGIACHAMBER_LUGIA" },
  HO_OH = { map = "TIN_TOWER_ROOF", object = "TINTOWERROOF_HO_OH" },
  SNORLAX = { map = "VERMILION_CITY", object = "VERMILIONCITY_BIG_SNORLAX" },
}

-- Which map to act on, so a sweep costs one table lookup rather than three.
Statics.BY_MAP = {}
for species, row in pairs(Statics.ROSTER) do
  Statics.BY_MAP[row.map] = { species = species, object = row.object }
end

-- Gen 2 spells it `caught`, where Gen 1 spells it `owned`
-- (src/core/gen2/Save.lua:252).  Reading the Gen 1 name here would have
-- returned nil for every species, and nil is indistinguishable from "not
-- caught" -- so every static would have been restored forever, including for
-- a player holding the Pokemon.
function Statics.owns(save, species)
  local dex = save and save.pokedex
  local caught = dex and dex.caught
  return (caught and caught[species]) and true or false
end

-- Whether this map's static should be standing there.
function Statics.wants(save, mapId)
  local row = Statics.BY_MAP[mapId]
  if not row then return nil end
  if Statics.owns(save, row.species) then return nil end
  return row
end

-- ------------------------------------------------------------- the roamers
--
-- RAIKOU and ENTEI are the same loss through a different door: no object and
-- no flag, just a save slot that BattleEnd_HandleRoamMons empties when the
-- beast is caught OR beaten (src/core/gen2/Roamers.lua:412-421 -- `win` and
-- `caught` are the same branch).  A slot keeps its INDEX, which is what says
-- which beast it was, so the roster refills it.
--
-- Deliberately not restored: hp.  A roamer that came back at the health it
-- fled with would be the same beast; this is a fresh one, which is the whole
-- point of it being back at all.
function Statics.restoreRoamers(save, roster, owns)
  local list = save and save.roamers
  if type(list) ~= "table" or type(roster) ~= "table" then return {} end
  local back = {}
  for index, row in ipairs(roster) do
    local slot = list[index]
    -- An emptied slot has neither species nor map (Roamers.active), and that
    -- is the only shape refilled: a beast still out there is left alone, hp
    -- and position and all.
    if type(slot) == "table" and slot.species == nil and slot.map == nil
        and row.species and not owns(row.species) then
      slot.species = row.species
      slot.level = row.level
      slot.map = row.map
      slot.hp = 0
      back[#back + 1] = row.species
    end
  end
  return back
end

-- ------------------------------------------------------------- installing

function Statics.install(mod)
  -- The roster the beasts are refilled from.  Required rather than
  -- reconstructed: the order of the rows is what identifies a slot, and a
  -- hand-written order that drifted from the cart's would put ENTEI back as
  -- RAIKOU.  The bundle already declares engine_internals.
  local okRoamers, Roamers = pcall(require, "src.core.gen2.Roamers")
  if not okRoamers then Roamers = nil end

  local function save()
    return mod.game and mod.game.save or nil
  end

  local function owns(species)
    return Statics.owns(save(), species)
  end

  -- Returns what it put back, for the log and for the bench.
  function Statics.sweep(mapId)
    local record = save()
    local back = {}
    if not record then return back end

    local row = mapId and Statics.wants(record, mapId)
    if row and mod.world then
      -- toggleObject only resolves for the loaded map, which is exactly the
      -- map that was just entered.  A failure is not worth a warning every
      -- time the player walks through: the object may legitimately be
      -- visible already, which is the steady state once it is back.
      local ok = pcall(function()
        return mod.world:toggleObject(mapId, row.object, true)
      end)
      if ok then
        back[#back + 1] = row.species
      end
    end

    if Roamers then
      local okRoster, roster = pcall(Roamers.roster,
        mod.game and mod.game.data and mod.game.data.gen2Encounters)
      if okRoster and type(roster) == "table" then
        for _, species in ipairs(
            Statics.restoreRoamers(record, roster, owns)) do
          back[#back + 1] = species
          mod.log:info("%s was never caught, so it is roaming again", species)
        end
      end
    end

    return back
  end

  mod.events:on("map.entered", function(event)
    Statics.sweep(event and event.mapId)
  end)

  -- A save loaded straight onto a static's map gets no map.entered for it on
  -- some boot paths, so the current map is swept on load too.  Idempotent, so
  -- a doubled call costs nothing.
  local function sweepHere()
    local here = mod.world and mod.world:current()
    Statics.sweep(here and here.mapId)
  end
  mod.events:on("save.loaded", sweepHere)
  mod.events:on("game.ready", sweepHere)
end

return Statics
