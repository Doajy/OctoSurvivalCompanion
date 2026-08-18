--[[
Octo Survival Companion - Data.lua

Reference data for the custom "Survival" secondary profession found on
Turtle WoW and its derivative servers (OctoWoW, CapyCraft / Capybara
Paradise, TurtleCraft, and similar Turtle WoW clones). These servers all
share the same 1.12.1-based content database, so item/spell IDs listed
here should line up across them, but private servers do diverge over
time -- treat anything marked "unconfirmed" as a starting point, not
gospel, and use /scw report if you find something wrong.

Sources consulted while building this file (checked 2026-08-14):
  - https://turtle-wow.org/survival-and-gardening      (official, Turtle WoW)
  - https://octowow.st/survival-and-gardening          (official, OctoWoW)
  - https://turtlecraft.gg/survival-and-gardening      (official, TurtleCraft)
  - https://boosting-ground.com/wow-classic/guides/profession-guides/turtle-wow-survival-guide
  - https://www.mmoprovider.com/blog/turtle-wow-survival-guide-1-150
  - https://database.turtle-wow.org/  (item/spell IDs, where reachable)
  - Turtle WoW community forum threads referencing item ids 50230, 60001,
    60002, 65028, 65030, 65031, 81187 and spell ids 46070, 46077.

CapyCraft-specific note: CapyCraft (Capybara Paradise) is listed as a
Turtle WoW clone and mirrors Turtle WoW's profession set. If your server's
recipe list differs, edit the table below -- it's plain Lua, nothing is
hidden or compiled.
]]

-- Most Survival recipes are TAUGHT DIRECTLY BY TRAINER NPCS (like a weapon
-- skill or a rank-up), not learned from a recipe/schematic item you loot or
-- buy. Confirmed 2026-08-15 via db.capycraft.org, by following each recipe's
-- "Taught By" list on its spell page. There are THREE flavors of trainer
-- (RESOLVED 2026-08-16 to three -- see the big correction note above
-- levelingGuide below for how a TurtleCraft forum leveling guide surfaced
-- the 3rd one, previously not modeled at all):
--   <Survival Trainer>     -- one per major city/starting zone, teaches the
--                             base recipe set plus the Apprentice and
--                             Journeyman rank-ups (skill caps 75 / 150).
--   <Expert Survivalist>   -- only two of these exist (Swamp of Sorrows and
--                             Desolace); they ALSO teach the Expert rank-up
--                             (skill cap 225, NOT 300 -- see rankSpells)
--                             plus a couple of higher-tier recipes nobody
--                             else teaches.
--   <Artisan Survivalist>  -- only ONE exists: Rufus Hardwick (Stranglethorn
--                             Vale). He's the sole source of the Artisan
--                             rank-up (skill cap 300), taught not by a flat
--                             trainer-click like the other 3 ranks but by
--                             turning in crafted reagents plus the "To
--                             Survive in the Jungle" quest (see
--                             startQuest.altPaths).
-- helpers so the 16 trainer entries below don't have to repeat the shared
-- recipe list by hand -- extra is an optional array of recipes/ranks that
-- particular trainer teaches on top of the shared set.
local function BaseTeaches(extra)
    local t = { "Apprentice Survivalist", "Journeyman Survivalist", "Traveler's Tent", "Fishing Boat", "Murloc's Flippers" }
    if extra then
        local i
        for i = 1, table.getn(extra) do
            table.insert(t, extra[i])
        end
    end
    return t
end

local function ExpertTeaches()
    local t = BaseTeaches(nil)
    table.insert(t, "Expert Survivalist")
    table.insert(t, "Iron Lantern")
    table.insert(t, "Cleaning Cloth")
    return t
end

-- ADDED 2026-08-16. Deliberately built on BaseTeaches, NOT ExpertTeaches --
-- per the levelingGuide source, Rufus Hardwick teaches Apprentice/Journeyman
-- like any regular trainer plus his own Artisan Survivalist rank, but does
-- NOT teach the Expert rank -- that's still exclusive to the two Expert
-- Survivalist NPCs. So the real path from 150 to 300 skill runs through
-- BOTH an Expert Survivalist (150->225) AND Rufus Hardwick (225->300),
-- not either alone.
local function ArtisanTeaches(extra)
    local t = BaseTeaches(extra)
    table.insert(t, "Artisan Survivalist")
    return t
end

OctoSurvivalCompanion_Data = {

    meta = {
        -- 0.x.y (not 1.x.y) -- semver's own convention for pre-1.0/beta
        -- software. CORRECTED 2026-08-17: was "1.5.1", which reads like a
        -- mature post-1.0 release even though nothing has ever actually
        -- shipped as a stable 1.0 -- this project is still beta. Bump the
        -- minor (0.X) for meaningful feature work, the patch (.Y) for
        -- fixes/data updates, same as normal semver, and move to 1.0.0
        -- whenever it's actually considered done/stable.
        version = "0.5.1",
        lastUpdated = "2026-08-17",
        servers = { "Turtle WoW", "OctoWoW", "CapyCraft (Capybara Paradise)", "TurtleCraft" },
        disclaimer = "Community-sourced reference data, not an official API. Verify with /trade in game when in doubt.",
    },

    -- The four rank-up "spells" that raise your Survival skill cap. The
    -- first three are level-0/instant and taught by the trainer network
    -- below like any other recipe; the 4th (Artisan) is taught by turning
    -- in crafted reagents via a quest instead, see its note.
    -- RESTRUCTURED 2026-08-16 from a 3-rank model (Apprentice/Journeyman/
    -- Expert, with Expert unlocking straight to 300) to a 4-rank model, per
    -- a TurtleCraft forum leveling guide (forum.turtlecraft.gg, t=24572 --
    -- see the big correction note above levelingGuide below for the full
    -- reasoning). Expert Survivalist's unlocksSkillCap dropped from 300 to
    -- 225, and a new Artisan Survivalist rank (225->300) was added,
    -- reclassifying Rufus Hardwick from a plain Survival Trainer into its
    -- sole teacher (see his trainers entry below).
    rankSpells = {
        { name = "Apprentice Survivalist", spellId = 46051, unlocksSkillCap = 75 },
        { name = "Journeyman Survivalist", spellId = 46052, unlocksSkillCap = 150, note = "Taught by every regular Survival Trainer. Per the levelingGuide source: requires character level 10 and Survival skill 50 to learn." },
        { name = "Expert Survivalist", spellId = 46055, unlocksSkillCap = 225, note = "Taught ONLY by Swampwalker Krug (Swamp of Sorrows) and Nerean Stagtree (Desolace). CORRECTED 2026-08-16 -- unlocksSkillCap was 300, but the levelingGuide source says this rank only unlocks training up to 225, not all the way to 300 (see Artisan Survivalist below for that). Per that source: requires character level 20 and Survival skill 150." },
        { name = "Artisan Survivalist", spellId = nil, unlocksSkillCap = 300, note = "ADDED 2026-08-16 -- previously not modeled at all. Taught ONLY by Rufus Hardwick (Stranglethorn Vale), NOT via a flat trainer-click like the other 3 ranks -- he teaches it after you turn in a set of crafted reagents alongside the \"To Survive in the Jungle\" quest (see startQuest.altPaths). spellId unconfirmed. Per the levelingGuide source: requires character level 35 and Survival skill 225." },
    },

    -- Each trainer entry:
    --   name, npcId, title ("Survival Trainer", "Expert Survivalist", or
    --   "Artisan Survivalist" -- see the 3-flavor note above BaseTeaches),
    --   zone, coords ("x, y" as shown on the map, 0-100), faction, level,
    --   teaches (array of recipe/rank names -- built with the BaseTeaches/
    --   ExpertTeaches/ArtisanTeaches helpers above so the shared list only
    --   lives in one place), notes.
    trainers = {
        -- RECLASSIFIED 2026-08-16 from a plain "Survival Trainer" to the
        -- sole Artisan Survivalist -- see the rankSpells restructure note
        -- above and the big correction note above levelingGuide below. A
        -- TurtleCraft forum leveling guide says he's the ONLY NPC who
        -- teaches Artisan Survival (unlocks skill 225->300), via turning
        -- in crafted reagents plus the "To Survive in the Jungle" quest,
        -- not a flat trainer-click like the other 3 ranks.
        { name = "Rufus Hardwick", npcId = 50070, title = "Artisan Survivalist", zone = "Stranglethorn Vale", coords = "35.5, 10.6", faction = "Neutral (all)", level = 40,
          teaches = ArtisanTeaches({ "Dim Torch", "Repaired Electro-Lantern" }),
          notes = "Also still the ONLY confirmed trainer for Dim Torch and Repaired Electro-Lantern -- worth the trip even if you trained elsewhere first." },
        -- CORRECTED 2026-08-16: zone was "Teldrassil", the same zone
        -- already used below for Filadon Shieldarrow -- a TurtleCraft
        -- forum trainer-location list (forum.turtlecraft.gg, t=24572, via
        -- user screenshot) separately lists "Filadon Shieldarrow in
        -- Teldrassil" AND "Nallaeth in Darnassus" as two distinct Night
        -- Elf trainers, so this was two entries wrongly sharing one zone
        -- rather than a real duplicate -- coords not re-verified against
        -- this correction yet, spot-check in game.
        { name = "Nallaeth", npcId = 62950, title = "Survival Trainer", zone = "Darnassus", coords = "27.8, 52.2", faction = "Darnassus", level = 40, teaches = BaseTeaches(nil) },
        { name = "Krennan Wildberry", npcId = 62951, title = "Survival Trainer", zone = "Elwynn Forest", coords = "34.5, 49.0", faction = "Stormwind", level = 30, teaches = BaseTeaches(nil) },
        { name = "Eissinn Cragbelly", npcId = 62954, title = "Survival Trainer", zone = "Ironforge", coords = "59.1, 64.2", faction = "Ironforge", level = 20, teaches = BaseTeaches(nil) },
        { name = "Brakan", npcId = 62956, title = "Survival Trainer", zone = "Orgrimmar", coords = "68.1, 27.7", faction = "Orgrimmar", level = 28, teaches = BaseTeaches(nil) },
        { name = "Nasnan Hillcreek", npcId = 62959, title = "Survival Trainer", zone = "Mulgore", coords = "44.8, 58.7", faction = "Thunder Bluff", level = 50, teaches = BaseTeaches(nil) },
        { name = "Cynthessa Grimblood", npcId = 62961, title = "Survival Trainer", zone = "Undercity", coords = "85.3, 58.7", faction = "Undercity", level = 50, teaches = BaseTeaches(nil) },
        -- RESOLVED 2026-08-16: zone was "Eastern Kingdoms (exact sub-zone
        -- unclear...)" -- a TurtleCraft forum trainer-location list
        -- (forum.turtlecraft.gg, t=24572, via user screenshot) names this
        -- NPC's zone as "Alah'thalas", a custom Turtle WoW High/Blood Elf
        -- zone, which fits both the capycraft "Azeroth" fallback (a site
        -- limitation for zones it doesn't recognize -- same pattern as the
        -- Blackstone Island/Thalassian Highlands/etc. custom zones
        -- documented above woodTiers) and Hellador's own "Silvermoon
        -- Remnant" faction. Coords not re-verified against this
        -- correction, spot-check in game.
        { name = "Hellador Swiftluck", npcId = 62962, title = "Survival Trainer", zone = "Alah'thalas", coords = "53.98, 12.99", faction = "Silvermoon Remnant", level = 50, teaches = BaseTeaches(nil) },
        -- RESOLVED 2026-08-16: zone/location were "unconfirmed" -- the same
        -- forum trainer-location list above names this NPC's zone as
        -- "Blackstone Island", a custom Turtle WoW zone already on file
        -- elsewhere in this addon (see woodTiers' Simple tier chopZones) --
        -- exact coords still not given by that source, spot-check in game.
        { name = "Feebeld", npcId = 62963, title = "Survival Trainer", zone = "Blackstone Island", coords = "unconfirmed", faction = "unconfirmed", level = nil,
          teaches = BaseTeaches(nil),
          notes = "Linked as a 'Taught By' entry on 3 different recipe pages, but the NPC's own db.capycraft.org page 404'd both times it was checked. Zone resolved 2026-08-16 via a TurtleCraft forum trainer-location list -- exact coords still unconfirmed, spot-check in game." },
        { name = "Thonk", npcId = 62964, title = "Survival Trainer", zone = "Durotar", coords = "51.2, 42.4", faction = "Orgrimmar", level = 50, teaches = BaseTeaches(nil) },
        { name = "Filadon Shieldarrow", npcId = 62965, title = "Survival Trainer", zone = "Teldrassil", coords = "56.0, 60.0", faction = "Darnassus", level = 50, teaches = BaseTeaches(nil) },
        { name = "Karolina Cloven", npcId = 62966, title = "Survival Trainer", zone = "Tirisfal Glades", coords = "60.5, 51.5", faction = "Undercity", level = 50, teaches = BaseTeaches(nil) },
        { name = "Dyrohrinn Boulderhorn", npcId = 62967, title = "Survival Trainer", zone = "Dun Morogh", coords = "46.8, 53.8", faction = "Ironforge", level = 50, teaches = BaseTeaches(nil) },
        { name = "Swampwalker Krug", npcId = 63071, title = "Expert Survivalist", zone = "Swamp of Sorrows", coords = "46.6, 52.9", faction = "Orgrimmar", level = 40, teaches = ExpertTeaches() },
        { name = "Nerean Stagtree", npcId = 63072, title = "Expert Survivalist", zone = "Desolace", coords = "64.4, 7.7", faction = "Darnassus", level = 40, teaches = ExpertTeaches() },
        { name = "Sir S. J. Erlgadin", npcId = nil, title = "Survival Trainer", zone = "Stranglethorn Vale (Nesingwary's Expedition, alongside Rufus Hardwick)", coords = "unconfirmed", faction = "Neutral (all)", level = 40,
          teaches = BaseTeaches(nil),
          notes = "Found 2026-08-15 via octowow.st (?npc= lookup), standing at the same camp as Rufus Hardwick -- but he never showed up in db.capycraft.org's per-recipe \"Taught By\" traces the other 15 entries here are built from, so his exact teach list is inferred/best-guess, not individually confirmed like the rest." },
    },

    startQuest = {
        name = "Night's Exploration",
        minLevel = 5,
        giver = "Nesingwary's Expedition camp, Northern Stranglethorn Vale",
        requirements = {
            "Wooden Club -- picked up free at the camp",
            "Coil of Sturdy Rope -- 35s from Jaquilina Dramet",
            "Cheap Goblin's Oil -- 40s 50c, Bind on Pickup, from Mazk Snipeshot in Booty Bay",
        },
        reward = "Survival skill rank 1 and a starter torch",
        altPaths = "db.capycraft.org also surfaced two other quest ids referencing a Survival unlock -- \"To Survive in the Jungle\" (#42041, level 45 req) and a \"[Deprecated] Night's Exploration\" (#50230, level 15 req). These read like older/legacy unlock paths that may have been superseded by direct trainer-teaching (see rankSpells/trainers above); unconfirmed which quest is actually live on your server, spot-check in game. 2026-08-16 UPDATE: the levelingGuide source below confirms \"To Survive in the Jungle\" IS live and IS how Rufus Hardwick teaches Artisan Survival (skill 225->300) -- so that quest wasn't deprecated/superseded after all. It gives a required level of 35 there, vs. 45 on this quest id -- unconfirmed whether that's two different real numbers or one of the two sources is off; spot-check in game.",
    },

    -- A step-by-step Survival skill-up guide -- what to craft at each skill
    -- range to reliably tick the skill bar, plus the 3 mid-career "gate"
    -- skills (Journeyman/Expert/Artisan Survival) that each cap how far you
    -- can train until you learn the next one from the right trainer.
    --
    -- SOURCE: a TurtleCraft forum post, "Survival Skill Leveling Guide"
    -- (forum.turtlecraft.gg, thread id 24572) -- the live forum isn't
    -- reachable from outside the game client, so this was pulled from a
    -- web.archive.org capture (2026-04-21) the user linked, then
    -- transcribed by hand from screenshots of the rest of the thread
    -- 2026-08-16. Copied as posted -- NOT independently re-verified against
    -- octowow.st or in-game testing the way most of the rest of this file
    -- is, so treat exact reagent counts as a strong starting point rather
    -- than gospel.
    --
    -- CORRECTION this source surfaced, RESOLVED 2026-08-16: rankSpells and
    -- the trainers table used to describe a 3-rank structure -- Apprentice
    -- (cap 75), Journeyman (cap 150), Expert (cap 300, taught only by the 2
    -- Expert Survivalists). This guide describes a 4-rank structure
    -- instead: Apprentice (0-75), Journeyman Survival (unlocks 75->150,
    -- taught by every regular trainer), Expert Survival (unlocks 150->225,
    -- NOT 300 -- taught only by the 2 Expert Survivalists), and a 4th rank,
    -- Artisan Survival (unlocks 225->300), taught ONLY by Rufus Hardwick in
    -- Stranglethorn Vale via turning in crafted reagents plus the "To
    -- Survive in the Jungle" quest (see startQuest.altPaths above). Both
    -- rankSpells and Rufus Hardwick's trainers entry (now title = "Artisan
    -- Survivalist", teaches built with the new ArtisanTeaches helper) have
    -- been updated to match -- see the RESTRUCTURED note above rankSpells
    -- and the RECLASSIFIED note above Rufus Hardwick's entry.
    --
    -- Each section entry is one of:
    --   { type = "header", text }               -- a skill-range divider, e.g. "150-225"
    --   { type = "bracket", range, craft, note } -- what to craft in that skill range (note optional)
    --   { type = "gate", name, text, trainers }  -- a rank-up requirement (trainers optional)
    --   { type = "note", text }                  -- freeform guidance between brackets
    --   { type = "list", heading, items, total }  -- a labeled list of lines (tools, materials), total optional
    levelingGuide = {
        source = "TurtleCraft forum \"Survival Skill Leveling Guide\" (forum.turtlecraft.gg, t=24572)",
        sourceNote = "Transcribed from user-provided screenshots of a web.archive.org capture, 2026-08-16 -- covers the full skill 1-300 path, plus the tools list and the forum's own aggregate materials list below. Copied as posted, not independently re-verified against octowow.st or in-game testing the way most of the rest of this file is -- see the correction note above for how it corrected rankSpells/trainers (now applied).",
        sections = {
            -- CORRECTED 2026-08-17: the source screenshot lumped "Blacksmith
            -- Hammer and an Anvil" together as one buyable-for-20c line, but
            -- an Anvil is a stationary world object (found at various spots
            -- in most cities, like a Cooking Fire), not a carried item you
            -- buy from a vendor -- Blacksmith Hammer is the only one of the
            -- two that actually belongs on a "tools you need" shopping list.
            { type = "list", heading = "Survival Tools You'll Need", items = {
                "Whittle -- Survival Supplier, 50c",
                "Woodcutting Axe -- Survival Supplier, 50c",
                "Blacksmith Hammer -- Mining Supplier, 20c (needed for some recipes)",
                "Cooking Fire and an Anvil -- needed for some recipes, but both are stationary objects (found at various spots in most cities), not carried tools you buy",
            } },
            { type = "header", text = "1-75" },
            { type = "bracket", range = "1-10", craft = "9x Dim Torches -- 9x Unlit Poor Torch" },
            { type = "bracket", range = "10-15", craft = "30x Bundle of Simple Sticks -- 60x Simple Wood", note = "We are gunna need these bundles later." },
            { type = "bracket", range = "15-35", craft = "20x Crude Walking Sticks -- 80x Simple Wood" },
            { type = "bracket", range = "35-50", craft = "15x Simple Slingshots -- 60x Striped Melon Seeds, 30x Bundle of Simple Sticks, 15x Springy Rope", note = "These melon seeds can be found from farms in the Barrens, Durotar, Elwynn Forest or Redridge Mountains." },
            { type = "bracket", range = "50-75", craft = "25x Weak Healing Salve -- 25x Refreshing Spring Water, 50x Remedy Herbs, 25x Simple Leaves" },

            { type = "gate", name = "Journeyman Survival", text = "You can only train Survival past 75 if you learn Journeyman Survival. Every Survival trainer will teach you this skill. Requires character level 10 and Survival skill 50." },

            { type = "header", text = "75-150" },
            { type = "bracket", range = "75-100", craft = "25x Crude Fishing Rod -- 200x Simple Wood, 25x Fine Thread" },
            { type = "bracket", range = "100-125", craft = "30x Simple Fishing Lure -- 30x Clam Meat, 30x Remedy Herbs", note = "Save Simple Fishing Lures for the next level range." },
            { type = "bracket", range = "125-140", craft = "60x Bundle of Bright Wood Sticks -- 180x Bright Wood; 85x Sturdy Net -- 340x Sturdy Rope", note = "You need 45 Sturdy Nets for a few levels above and 40 Sturdy Nets to get from 280 to 300 later on." },
            { type = "bracket", range = "140-155", craft = "30x Blackmouth Fishing Trap -- 60x Bundle of Bright Wood Sticks, 30x Simple Fishing Lure, 30x Sturdy Net" },

            { type = "gate", name = "Expert Survival", text = "You can only train Survival past 150 if you learn Expert Survival. Not every Survival trainer will teach you this skill -- you have to find an Expert Survivalist. Requires character level 20 and Survival skill 150.", trainers = "Alliance: Nerean Stagtree (Desolace). Horde: Swampwalker Krug (Swamp of Sorrows)." },

            { type = "header", text = "150-225" },
            { type = "bracket", range = "155-160", craft = "5x Throwable Net -- 5x Sturdy Net, 20x Coarse Stone" },
            { type = "bracket", range = "160-175", craft = "15x Slowing Bolas -- 45x Heavy Stone, 30x Sturdy Rope" },
            { type = "bracket", range = "175-185", craft = "22x Bundle of Shade Wood Sticks -- 88x Shade Wood" },
            { type = "bracket", range = "185-200", craft = "10x Spicy Fishing Lure -- 10x Tangy Clam Meat, 10x Hot Spices; 10x Firefin Fishing Trap -- 20x Bundle of Shade Wood, 10x Spicy Fishing Lure, 10x Sturdy Net", note = "This is the start of collecting items required for Artisan Survival past level 225." },
            { type = "bracket", range = "200-210", craft = "10x Savory Fishing Lure -- 10x Zesty Clam Meat, 20x Soothing Spices" },
            { type = "bracket", range = "210-215", craft = "5x (3)Nutritious Rations -- 10x Juicy Watermelon, 10x Sour Mountain Berry, 10x Plump Country Pumpkin" },
            { type = "bracket", range = "215-217", craft = "2x Vine Cutter -- 20x Mithril Bar, 4x Solid Grinding Stone, 8x Thick Leather, 2x Bundle of Shade Wood Sticks" },
            { type = "bracket", range = "217-225", craft = "8x (3)Nutritious Rations -- 16x Juicy Watermelon, 16x Sour Mountain Berry, 16x Plump Country Pumpkin; 10x Bundle of Tropical Sticks -- 50x Tropical Wood", note = "When you get to 225 you need to make the bundles above. The only way to learn Bundle of Tropical Sticks is from the Swamp of Sorrows or Desolace trainer." },

            { type = "note", text = "Take these resources to Rufus Hardwick and accept the quest \"To Survive in the Jungle\" -- this is where he teaches you up to 300 Survival." },
            { type = "gate", name = "Artisan Survival", text = "You can only train Survival past 225 if you learn Artisan Survival. Not every Survival trainer will teach you this skill -- you have to find an Artisan Survivalist. Requires character level 35 and Survival skill 225.", trainers = "Neutral: Rufus Hardwick (Stranglethorn Vale)." },

            { type = "header", text = "225-300" },
            { type = "bracket", range = "225-240", craft = "25x Bundle of Tropical Sticks -- 125x Tropical Wood" },
            { type = "bracket", range = "240-260", craft = "20x Aromatic Berries -- 20x Sweet Mountain Berry, 20x Remedy Herbs, 40x Soothing Spices" },
            { type = "bracket", range = "260-275", craft = "15x Smooth Ironfeather Arrows -- 15x Bundle of Tropical Sticks, 15x Ironfeather, 15x Thorium Bar" },
            { type = "bracket", range = "275-290", craft = "20x Bundle of Star Wood Sticks -- 100x Star Wood; 10x Premium Fishing Lure -- 20x Zesty Clam Meat, 10x Molasses Firewater", note = "The ingredients above are for the Stonescale Fishing Trap needed to hit 300 next. Use the 50 Sturdy Nets you made at level 125, or make 20 more now." },
            { type = "bracket", range = "290-300", craft = "10x Stonescale Fishing Trap -- 20x Bundle of Star Wood Sticks, 10x Premium Fishing Lure, 20x Sturdy Net" },

            -- This list is the forum's own aggregate rollup of the whole
            -- 1-300 path (its own heading says "Approximate"), transcribed
            -- as posted rather than recomputed from the brackets above --
            -- a couple of lines don't quite add up against them (e.g. this
            -- says 90x Remedy Herbs, the brackets above only sum to 80-100
            -- depending which ones you count), consistent with it being a
            -- rough approximation rather than an audited total. One
            -- transcription call made here: the source screenshot lists
            -- "60x Striped Melon Seeds - AH" twice back to back, which
            -- looks like a copy/paste artifact rather than a real second
            -- requirement (only the 35-50 bracket above uses Melon Seeds,
            -- for 60 total) -- kept once here rather than doubled.
            { type = "list", heading = "Approximate Materials Required (whole 1-300 path, the forum's own rollup)", items = {
                "9x Unlit Poor Torch -- vendor 10c each (90c total)",
                "340x Simple Wood -- AH",
                "60x Striped Melon Seeds -- AH",
                "15x Springy Rope -- vendor 85c each (12s 75c total)",
                "25x Refreshing Spring Water -- vendor 25c each (3s 75c total)",
                "90x Remedy Herbs -- vendor 12c each (9s 60c total)",
                "25x Simple Leaves -- AH",
                "25x Fine Thread -- vendor 1s each (25s total)",
                "30x Clam Meat -- AH",
                "180x Bright Wood -- AH",
                "370x Sturdy Rope -- vendor 1s each (4g 10s total)",
                "20x Coarse Stone -- AH",
                "45x Heavy Stone -- AH",
                "88x Shade Wood -- AH",
                "10x Tangy Clam Meat -- AH",
                "10x Hot Spices -- vendor 40c each (4s total)",
                "30x Zesty Clam Meat -- AH",
                "26x Juicy Watermelon -- AH",
                "26x Sour Mountain Berry -- AH",
                "26x Plump Country Pumpkin -- AH",
                "20x Mithril Bar -- AH",
                "4x Solid Grinding Stone -- AH",
                "8x Thick Leather -- AH",
                "175x Tropical Wood -- AH",
                "20x Sweet Mountain Berry -- AH",
                "60x Soothing Spices -- vendor 1s 60c each (96s total)",
                "15x Ironfeather -- AH",
                "15x Thorium Bar -- AH",
                "100x Star Wood -- AH",
                "10x Molasses Firewater -- vendor 10s each (1g total)",
            }, total = "Total Vendor Cost: 6g 62s (AH-sourced items priced separately, not included in that total)" },
        },
    },

    -- Each recipe entry:
    --   name        Display / recipe name
    --   resultItemId   itemId of the crafted result, if known (nil if unconfirmed)
    --   recipeItemId   itemId of the recipe/schematic item that teaches it, if known
    --   spellId        spellId of the crafted ability, if known
    --   skillReq       Survival skill required to craft (number or nil if unconfirmed)
    --   charLevel      Character level suggested/required, if known
    --   reagents       Table of reagent name strings
    --   effect         Short effect description
    --   duration       Buff/object duration
    --   cooldown       Crafting cooldown
    --   source         Where the recipe is obtained
    --   confirmed      true if skillReq + reagents are confirmed from a primary source,
    --                  false if pieced together from secondary guides / unclear
    --   notes          Free text
    recipes = {
        {
            name = "Dim Torch",
            resultItemId = nil,
            spellId = 46064, -- teach spell (create-spell id not disambiguated -- see notes)
            skillReq = 1,
            charLevel = 1,
            reagents = { "Unlit Poor Torch", "Flint and Tinder", "a nearby fire source" },
            effect = "+4 Spirit for your party while held",
            duration = "Permanent while equipped/held",
            cooldown = "~1-2 min",
            source = "Taught ONLY by Rufus Hardwick <Survival Trainer> (Stranglethorn Vale, ~35.5,10.6) -- not a vendor scroll",
            confirmed = true,
            notes = "First craft available after the Night's Exploration quest, usable roughly skill 1-20. Trainer sourcing confirmed 2026-08-15 via db.capycraft.org spell #46064/46065; teach-vs-create split between those two ids wasn't fully disambiguated. octowow.st shows no separate \"Torn Outline\" pattern item for this one (only the crafted torch itself, item 6182, \"Requires Level 5\") -- consistent with it being trainer-only from skill 1.",
        },
        {
            name = "Bright Campfire",
            resultItemId = nil,
            spellId = nil,
            skillReq = 10,
            charLevel = nil,
            reagents = { "Simple Wood", "Flint and Tinder" },
            effect = "+8 Spirit to you and nearby party members",
            duration = "Lasts until it burns out / shared cooldown with basic campfire",
            cooldown = "5 min",
            source = "NOT taught by any Survival trainer or vendor -- it's the standard Cooking-profession recipe (General tab of the spellbook, learned from any Cooking trainer), which Turtle WoW's custom Survival system repurposes as a guaranteed Survival skill-up craft in this range",
            confirmed = true,
            notes = "RESOLVED 2026-08-17. Main leveling recipe from roughly skill 10 to 75 -- guaranteed skill-up per craft in that range. Two prior passes (2026-08-15, db.capycraft.org spell ids 46040-46090 and an octowow.st \"Torn Outline\" pattern-item search) came up empty because both searched Survival-taught sources specifically -- this recipe was never Survival-taught at all. Cross-checked 2026-08-17 against three independent guide sources (a boosting-ground.com Turtle WoW Survival guide fetched directly, plus corroborating summaries of a TurtleCraft/mmoprovider guide) that all independently describe the same mechanic: learn base Cooking from any Cooking trainer, Bright Campfire shows up in the spellbook's General tab (not the Survival crafting window), and crafting it counts toward Survival skill-ups in this bracket. Exact spellId still unconfirmed -- the official database.turtle-wow.org lists a \"Bright Campfire\" at spell #7359, but that domain wasn't reachable to verify directly this pass, and db.capycraft.org's own #7359 is a different, unrelated \"Simple Campfire Kit\" spell (the two sites don't share an id scheme for older/base-game content) -- spot-check in game.",
        },
        {
            name = "Traveler's Tent",
            resultItemId = 51283,
            recipeItemId = nil,
            spellId = 46059, -- teach spell
            craftSpellId = 46072, -- cast/create spell (2 hr cooldown, per capycraft)
            skillReq = 50,
            charLevel = 15,
            reagents = { "5 Simple Wood", "10 Linen Cloth", "1 Sturdy Rope" },
            effect = "Accelerates rested XP gain; stacks with up to 5 tents placed at once",
            duration = "20 min once placed",
            cooldown = "2 hours",
            source = "Taught by all 15 Survival/Expert Survivalist trainers (see trainers table) -- not a scroll/blueprint item",
            confirmed = true,
            notes = "Confirmed 2026-08-15 via db.capycraft.org/item/51283 -> spell #46059 (teach) -> #46072 (create, reagents+cooldown as listed). skillReq = 50 is now double-confirmed by octowow.st's \"Torn Outline: Traveler's Tent\" pattern item (id 50234), which lists \"Requires Survival (50)\". Note: capycraft's own trainer-taught trace found no recipe item at all for this one, so it's a bit of an open question whether that pattern item is a genuine alternate source or just a leftover/vestigial db entry -- either way the skill number lines up.",
        },
        {
            name = "Fishing Boat",
            resultItemId = nil,
            recipeItemId = nil,
            spellId = 46060, -- teach spell
            craftSpellId = 46073, -- cast/create spell
            skillReq = 75,
            charLevel = 25,
            reagents = { "Whittling tool (required)", "20 Simple Wood", "10 Handful of Copper Bolts", "2 Fish Oil" },
            effect = "+50 Fishing skill bonus for the boat's creator",
            duration = "60 min",
            cooldown = "2 hours",
            source = "Taught by at least 14 of the 15 trainers (see trainers table) -- not a book/vendor item",
            confirmed = true,
            notes = "Confirmed 2026-08-15 via db.capycraft.org spell #46060 (teach) -> #46073 (create). Reagent list above supersedes the old \"2x Fish Oil OR 15x Simple Wood + Copper Bolts\" guess -- it's actually all four reagents together, plus a Whittling tool in your bags. skillReq updated from an old unverified guess of 125 to 75, per octowow.st's \"Torn Outline: Fishing Boat\" pattern item (id 50235), which lists \"Requires Survival (75)\".",
        },
        {
            name = "Iron Lantern",
            resultItemId = nil,
            recipeItemId = nil,
            spellId = nil,
            skillReq = 30,
            charLevel = nil,
            reagents = { "4 Iron Bar", "8 Wool Cloth", "4 Flask of Oil", "Blacksmith Hammer (tool, required)" },
            effect = "Portable light source",
            duration = "Permanent, requires lantern oil to operate",
            cooldown = nil,
            source = "Taught ONLY by the two Expert Survivalist trainers -- Swampwalker Krug (Swamp of Sorrows) and Nerean Stagtree (Desolace)",
            confirmed = true,
            notes = "Corrected 2026-08-15: earlier revisions of this file guessed this came from a \"Torn Outline: Iron Lantern\" drop item (81187) -- that exact item id is STILL referenced on octowow.st (same id, 81187) where it lists \"Requires Survival (30)\", but db.capycraft.org's \"Taught By\" trace for this recipe found only the two Expert Survivalist trainers, no droppable pattern item. Both sources may be right at once (a pattern item that exists alongside direct trainer teaching), so skillReq is now set to the octowow.st-confirmed 30, but double check in game which path actually applies for you.",
        },
        {
            name = "Murloc's Flippers",
            resultItemId = 65028,
            recipeItemId = nil,
            spellId = 46066, -- teach spell (create-spell id not disambiguated -- see notes)
            skillReq = 75,
            charLevel = nil,
            reagents = { "4 Medium Leather", "2 Fine Thread", "8 Slimy Murloc Scale", "1 Swim Speed Potion", "2 Fish Oil" },
            effect = "Grants small amounts of all stats and increases swim speed while worn",
            duration = "Permanent (worn item)",
            cooldown = nil,
            source = "Taught by 14 trainers -- all base Survival Trainers plus both Expert Survivalists (see trainers table)",
            confirmed = true,
            notes = "Reagents confirmed 2026-08-15 via db.capycraft.org spell #46066/46067; teach-vs-create split between those two ids wasn't fully disambiguated. Result item id 65028 from an earlier Turtle WoW database pass. skillReq = 75 added from octowow.st's \"Torn Outline: Murloc Flippers\" pattern item (id 65029), \"Requires Survival (75)\".",
        },
        {
            name = "Repaired Electro-Lantern",
            resultItemId = 65030,
            recipeItemId = nil,
            spellId = 46077,
            skillReq = 90,
            charLevel = nil,
            reagents = { "unconfirmed" },
            effect = "+4 Spirit, plus a minor melee zap effect; runs on unlimited fuel",
            duration = "Permanent",
            cooldown = nil,
            source = "Taught ONLY by Rufus Hardwick <Survival Trainer> (Stranglethorn Vale, ~35.5,10.6) -- not a drop/find",
            confirmed = true,
            notes = "Corrected 2026-08-15: earlier revisions guessed this came from a \"Torn Outline: Repaired Electro-Lantern\" drop item (65031) -- db.capycraft.org's research instead traced it to Rufus Hardwick's trainer list, so the Torn Outline item id has been dropped pending confirmation either way. Result item id 65030 and spell id 46077 are from an earlier Turtle WoW database pass and weren't re-verified this round; reagents still unconfirmed. skillReq = 90 added from octowow.st's \"Torn Outline: Repaired Electro-Lantern\" pattern item (id 65031 -- same id capycraft's trace didn't corroborate), which lists \"Requires Survival (90)\".",
        },
        {
            name = "Simple Wooden Planter",
            resultItemId = nil,
            recipeItemId = nil,
            spellId = 46062,
            skillReq = 75,
            charLevel = nil,
            reagents = { "10 Simple Wood", "4 Handful of Copper Bolts" },
            effect = "Crafts the planter used to start Gardening",
            duration = "Permanent (tool)",
            cooldown = nil,
            source = "NOT trainer-taught, unlike most of this list -- either a free reward from the \"You Reap What You Sow\" Gardening starter quest, or self-crafted via spell #46062",
            confirmed = true,
            notes = "Confirmed 2026-08-15 via db.capycraft.org: spell #46062's own \"Taught By\" field is empty (no trainer teaches it), and it lines up with the free planter you already get from the Gardening starter quest in gardening.startQuest below. Treat the reagents above as the self-craft/backup path if you ever need a second planter. skillReq = 75 is now double-confirmed by octowow.st's \"Torn Outline: Simple Wooden Planter\" pattern item (id 50238), \"Requires Survival (75)\" -- also matching gardening.unlockSkill below.",
        },
        {
            name = "Cleaning Cloth",
            resultItemId = 60001,
            recipeItemId = nil,
            spellId = 46069, -- teach spell
            craftSpellId = 46068, -- cast/create spell
            skillReq = nil,
            charLevel = nil,
            reagents = { "2 Silk Cloth", "1 Volatile Rum" },
            effect = "Cleans a weapon, removing any temporary enhancement that has been applied to it",
            duration = nil,
            cooldown = nil,
            source = "Taught ONLY by the two Expert Survivalist trainers (Swampwalker Krug, Nerean Stagtree)",
            confirmed = true,
            notes = "RESOLVED 2026-08-17 with live db.capycraft.org lookups (the 2026-08-15 CAUTION below was working from an old pass and correctly smelled a problem, just hadn't pinned it down yet). Item #60001 (this recipe's result) is itself listed as \"Created By: Spell #46068\", which is the Survival-specific craft spell (2 Silk Cloth + 1 Volatile Rum, taught by Krug/Stagtree) -- its teach-spell counterpart is #46069 (\"Teaches how to create a Cleaning Cloth\", same two trainers). Spell #46070, previously filed here as this recipe's spellId, is NOT a separate/unrelated recipe as suspected -- it's item #60001's own on-use effect (the \"clean a weapon, remove temporary enhancement\" cast you get from consuming the crafted cloth), cross-referenced right on the item's own capycraft page. recipeItemId 60002 (\"Torn Outline: Cleaning Cloth\") has been dropped -- unlike the genuine Torn Outline pattern items elsewhere in this file, its capycraft page has no \"Requires Survival (X)\" text and nothing marking it as a pattern drop, so it isn't a confirmed alternate source. skillReq still unconfirmed (no Survival skill number appears on any of the three spell/item pages checked) -- spot-check in game. Also historically reported on the Turtle WoW forums as sometimes not showing up after being learned -- a known old bug, not something wrong with this list.",
        },
    },

    gardening = {
        unlockSkill = 75,
        startQuest = {
            name = "You Reap What You Sow",
            minLevel = 20,
            location = "Elwynn Forest (Alliance) or Mulgore (Horde)",
            reward = "Shovel and Wooden Planter",
        },
        materials = {
            "Refreshing Spring Water -- used to water plants",
            "Un'Goro Soil -- planted in the Wooden Planter with a seed",
            "Seeds -- 4 starter accelerated-growth seed types are taught to begin with",
        },
        mechanic = "Every 9 minutes you must water or fertilize the sproutling in your planter, or you risk losing the crop.",
        notes = "The specific seed species/names and any soil variants beyond Un'Goro Soil aren't reliably documented outside the live in-game recipe list on the sources checked for this addon. Once you're in game, open your Survival tradeskill window and Claude (or you) can fill in OctoSurvivalCompanion_Data.gardening.seeds with the exact names -- there's an empty table below ready for that.",
        seeds = {
            -- Fill in as: { name = "Example Seed", soil = "Un'Goro Soil", growTime = "?", yields = "?" },
        },
    },

    miscItems = {
        {
            name = "Erlgadin's Survival Guide",
            itemId = 50230,
            notes = "In-game reference item/book tied to the Survival trainer Erlgadin; useful as an in-client cross-check against this data file.",
        },
    },

    -- Tree-chop tracker bottom bar --------------------------------------
    -- The bar itself is still populated dynamically at runtime from
    -- whatever trees OctoSurvivalCompanionDB.treesChopped records (see
    -- Core.lua) -- there's no requirement that a tree be "known" here
    -- before it can show up. What changed is that we now have a real,
    -- confirmed catalog of the wood tiers this pulls from, sourced from
    -- CapyCraft's own item/object database (https://db.capycraft.org/,
    -- checked 2026-08-15) rather than guessed placeholder names:
    --
    --   https://db.capycraft.org/item/42007    (Bright Wood)
    --   https://db.capycraft.org/item/11291    (Star Wood -- confirms it comes
    --                                            from a dedicated "Star Wood Tree"
    --                                            object #2020299 at 100%, NOT
    --                                            "Dead Wood Tree" #2020300, which
    --                                            only has a 25% chance at it)
    --   https://db.capycraft.org/object/2020270   (Simple Wood Tree, Teldrassil)
    --   https://db.capycraft.org/object/2020282   (Bright Wood, Hillsbrad)
    --   https://db.capycraft.org/object/2020288   (Shade Wood Tree, Stranglethorn)
    --   https://db.capycraft.org/object/2020298   (Tropical Wood Tree)
    --   https://db.capycraft.org/object/2020299   (Star Wood Tree)
    --   https://db.capycraft.org/object/2020300   (Dead Wood Tree)
    --   ...and the corresponding wood/leaf item pages for icon filenames.
    --
    -- Tree node names in game follow "<Tier> Wood Tree (<Zone>)" for most
    -- tiers (Bright Wood's objects drop the "Tree" suffix in their name
    -- for some reason -- e.g. "Bright Wood (Hillsbrad)" not "Bright Wood
    -- Tree (Hillsbrad)"). Each tier's own wood item drops at 100% and a
    -- matching leaf item at a lower rate (60% for the tiers checked).
    --
    -- "Dead Wood Tree" is the one exception -- it doesn't have a
    -- dedicated wood item of its own at all. It yields Dead Leaves plus a
    -- ~25% chance at Star Wood as a bonus/rare drop (see woodItem = nil
    -- below). It's kept as its own tier entry anyway since it's a real,
    -- separately-named node you can chop, and it needs its own tree name
    -- pattern so the tracker doesn't misfile it under Star Wood Tree.
    --
    -- This is CapyCraft data specifically -- Turtle WoW / OctoWoW very
    -- likely match since they share the same profession, but that's
    -- not independently confirmed, so double check if you're not on
    -- CapyCraft.
    -- pets: each tree tier has a ~0.05%-per-chop chance (confirmed
    -- 2026-08-15 via db.capycraft.org, cross-checked against each tree
    -- object's own loot table, e.g. https://db.capycraft.org/item/37063)
    -- of awarding a companion pet item on TOP of the normal wood/leaf
    -- drop. Simple/Bright/Shade/Tropical each have 2 possible pets; Star
    -- and Dead only have 1 (verified against the object loot table, not
    -- just an ID-range guess). All use the generic "Add Companion to
    -- Collection" spell (#46498).
    --
    -- chopZones RE-VERIFIED 2026-08-15 at object level (not just the item
    -- "Contained In" summary): every tree tier is actually MULTIPLE
    -- separate game objects, one per zone (e.g. Bright Wood alone is 6
    -- distinct "Bright Wood Tree" object IDs, #2020282-2020287, each
    -- placed in one zone). Cross-checked all 36 of those object IDs
    -- across all 6 tiers directly against octowow.st's own per-object
    -- "Locations" page (e.g. https://octowow.st/db/?object=2020287),
    -- not just capycraft.org's per-object nickname.
    --
    -- Finding: octowow.st's per-object Locations lookup is NOT reliable
    -- for objects placed in custom Turtle WoW zones -- Blackstone Island,
    -- Thalassian Highlands, Northwind, Balor, Grim Reaches, and Gilneas
    -- are all real, independently-confirmed custom zones added by Turtle
    -- WoW (not vanilla, so octowow.st's zone lookup doesn't recognize
    -- their IDs), but its site falls back to either a raw continent name
    -- ("Azeroth"/"Kalimdor") or whatever ordinary zone happens to share a
    -- coordinate boundary with them (e.g. the "Grim Reaches" object shows
    -- up as "Loch Modan"/"Wetlands" on octowow.st, and "Gilneas" shows up
    -- as "Silverpine Forest"/"Hillsbrad Foothills" -- small counts, most
    -- likely boundary-adjacent trees getting mis-bucketed, not a second
    -- real spawn population). Similarly, several ordinary-zone objects
    -- (Dun Morogh, Tirisfal, Silverpine, Hinterlands, Badlands, Desolace,
    -- Stonetalon) show a small secondary zone count (2-14, vs. the
    -- primary zone's 40-120+) -- almost certainly the same
    -- boundary-spillover artifact, not a real additional chop zone.
    -- Given that, none of those low-count secondary entries were added
    -- to any tier's chopZones below -- they'd overstate how likely you
    -- are to find that tier there. Every existing zone in every tier
    -- checked out as correct; nothing needed removing either. Full
    -- object-ID-to-zone breakdown isn't reproduced here to keep this
    -- file readable -- re-run the check by fetching
    -- https://octowow.st/db/?object=<ID> for the object IDs above if you
    -- want to audit it again.
    --
    -- Coverage double-checked 2026-08-15: octowow.st's own search page
    -- (/db/?search=Wood+Tree) renders its results client-side in JS, so
    -- it can't be read directly -- but walked the object ID range by
    -- hand instead to make sure nothing was missed: #2020267-2020301 are
    -- all 6 tiers' tree objects (the 36 above), #2020302-2020308 are
    -- empty placeholder objects with no name or spawn data (not trees),
    -- and the IDs immediately outside that block (#2020266, #2020310,
    -- #2020311) are unrelated Gardening/mining nodes ("Draenethyst
    -- Formation", "Volcanic Soil", "Twisted Tree Sapling") -- so the
    -- 36-object set above is the complete list, nothing extra hiding in
    -- the gaps.
    --
    -- zoneCounts: approximate spawn counts per zone, pulled from the same
    -- 2026-08-15 object-by-object check as chopZones above. Shown next to
    -- each zone in the Map tab's zone dropdown (e.g. "Winterspring (14)"
    -- -- see BuildZoneDropdownList in Map.lua), and used by
    -- IsZoneRareForTier (also Map.lua) to flag any zone at or below
    -- RARE_ZONE_THRESHOLD as "(rare)"/"might be spillover" rather than
    -- letting a 2-3 spawn zone read the same as a 50-spawn one.
    -- Deliberately partial:
    -- a few zones didn't show a spawn count on their object's page at
    -- all (left out here, not zeroed), and the custom-zone entries
    -- (Blackstone Island, Thalassian Highlands, Northwind, Balor, Grim
    -- Reaches, Gilneas, Moonwhisper Coast) are the SUM of whatever
    -- zones/continent label octowow.st mis-attributed that object's
    -- spawns to (see the custom-zone caveat above) -- likely close, but
    -- less trustworthy than the plain single-zone numbers.
    --
    -- A handful of these counts are genuinely low (single digits) even
    -- though they're confirmed-real, individually-verified placements,
    -- not spillover -- Balor 3 (Bright), Feralas 4 / Darkshore 2 (Star),
    -- Searing Gorge 5 / Un'Goro Crater 5 / Azshara 4 / Darkshore 2 (Dead,
    -- re-verified 2026-08-16, see the note above the Dead tier below).
    -- Deliberately NOT removed from chopZones/zoneCounts -- they're
    -- correct, just sparse -- instead Map.lua's RARE_ZONE_THRESHOLD flags
    -- any zone at or below 10 as "(rare)" wherever chop-zone lists are
    -- shown, so the tooltip stays complete AND honest about which spots
    -- are actually worth a trip.
    --
    -- spawnPoints ADDED 2026-08-17 for all 6 tiers -- individual spawn
    -- "pips" for the Map tab (see RefreshMapPips in Map.lua), one {x,y}
    -- zone-local percent pair per known spawn. Pulled from octowow.st's
    -- raw page HTML for every tree object id in the #2020267-2020309
    -- range noted above (each object page embeds a myMapper.update({zone,
    -- coords}) call per zone it appears in, meant to feed its own map
    -- widget -- not visible on the rendered page, only in the source).
    -- Simple/Bright/Shade are one object per zone (16/6/11 objects
    -- respectively, see the chopZones notes on each tier below) so their
    -- per-zone results were fetched separately and merged; Tropical/Star/
    -- Dead are each a single object covering every zone at once.
    --
    -- Every result was cross-checked against that tier's own
    -- already-confirmed chopZones list before being kept -- raw scrape
    -- output otherwise re-surfaces the exact same boundary-spillover
    -- artifact documented above (a handful of stray points in a
    -- neighboring zone from an object placed near a boundary), and for
    -- Shade specifically the dropped set was Loch Modan/Wetlands/
    -- Silverpine Forest/Hillsbrad Foothills -- the very same 4 zones this
    -- file already named as Grim Reaches/Gilneas's spillover targets,
    -- good independent confirmation the filtering approach is right
    -- rather than just discarding real data. A few zone names also came
    -- back from the site with typos (e.g. "Elwynn Forrest", "Ungoro
    -- Crater", "Hilsbrad Foothills") -- normalized to match this file's
    -- own spelling so the Map.lua lookup (spawnPoints[zoneName]) actually
    -- matches. Custom Turtle WoW zones (Blackstone Island, Thalassian
    -- Highlands, Northwind, Balor, Grim Reaches, Gilneas, Moonwhisper
    -- Coast, Tel'abim) have no entry here even where they're in
    -- chopZones -- octowow.st doesn't recognize their zone ids either, so
    -- their spawns show up as an unresolved continent-level "Azeroth"/
    -- "Kalimdor" cluster instead (zone-local coordinates don't apply to a
    -- continent-wide cluster the same way -- see the Star Wood tier's own
    -- spawnPoints note for the fuller explanation and why that's left for
    -- a follow-up rather than guessed at).
    woodTiers = {
        {
            tier = "Simple",
            treeNamePattern = "^Simple Wood Tree",
            woodItem = { name = "Simple Wood", itemId = 4470, icon = "Interface\\Icons\\simple_wood_1" },
            leafItem = { name = "Simple Leaves", itemId = 42142, icon = "Interface\\Icons\\INV_Misc_Herb_10" },
            -- 5 -- cross-confirmed 2026-08-16 against a TurtleCraft forum
            -- "Survival Tree Locations" leveling guide (forum.turtlecraft.gg,
            -- t=24572, via web.archive.org -- the live site isn't reachable
            -- from here), which lists the same skill gate for every tier at
            -- once: Simple 5, Bright 125, Shade 175, Tropical 225, Dead 250,
            -- Star 270. This one already matched what was on file.
            level = 5,
            pets = {
                { name = "Wood Constrictor", itemId = 37061, chance = 0.05 },
                { name = "Yellow Wasp", itemId = 37062, chance = 0.05 },
            },
            -- Full 16-zone list per item 4470's "found in" page (16
            -- separate objects, #2020267-2020281 + #2020301, one per
            -- zone) -- re-checked object-by-object 2026-08-15, all 16
            -- confirmed. Blackstone Island and Thalassian Highlands are
            -- real custom Turtle WoW starter zones (Goblin / High Elf) --
            -- octowow.st's own Locations page doesn't recognize either
            -- one and falls back to a neighboring zone/continent label
            -- instead, but that's a site limitation, not a data error --
            -- see the note above woodTiers.
            chopZones = {
                "Durotar", "The Barrens", "Mulgore", "Teldrassil", "Darkshore",
                "Elwynn Forest", "Westfall", "Duskwood", "Redridge Mountains",
                "Dun Morogh", "Loch Modan", "Tirisfal Glades", "Silverpine Forest",
                "Wetlands", "Blackstone Island", "Thalassian Highlands",
            },
            zoneCounts = {
                Durotar = 54, ["The Barrens"] = 73, Mulgore = 71, Teldrassil = 84,
                Darkshore = 78, ["Elwynn Forest"] = 64, Westfall = 40, Duskwood = 56,
                ["Redridge Mountains"] = 37, ["Dun Morogh"] = 63, ["Loch Modan"] = 64,
                ["Tirisfal Glades"] = 85, ["Silverpine Forest"] = 90, Wetlands = 73,
                ["Blackstone Island"] = 32, ["Thalassian Highlands"] = 33,
            },
-- dropped as continent-catchall (different coord space): Kalimdor(21), Azeroth(22)
-- dropped as boundary-spillover (not in confirmed chopZones): Searing Gorge(2), Western Plaguelands(10), Alterac Mountains(1), Eastern Plaguelands(11)
-- confirmed real zones with NO spawn-point data found: Blackstone Island, Thalassian Highlands
            spawnPoints = {
                Darkshore = {
                    {35.77,90.69}, {36.12,83.11}, {37.03,81.42}, {37.11,94.73}, {38.22,56.78}, {38.53,95.18}, {38.54,50.18}, {38.62,73.73},
                    {38.73,84.19}, {38.74,60.85}, {38.91,64.36}, {39.02,71.8}, {39.03,40.77}, {39.08,38.41}, {39.64,77.5}, {40.13,68.55},
                    {40.16,76.04}, {40.24,85.77}, {40.42,59.55}, {40.64,36.63}, {41.14,59.37}, {41.28,87.56}, {41.72,48.9}, {41.74,36.01},
                    {41.86,84.76}, {41.9,91.43}, {41.98,78.67}, {42.91,47.14}, {42.93,80.44}, {43.19,35}, {43.58,37.29}, {43.67,51.4},
                    {43.89,33.44}, {44.09,85.22}, {44.1,53.32}, {44.39,29.96}, {44.5,84.12}, {44.74,81.44}, {44.77,57.6}, {44.88,87.08},
                    {44.91,28.36}, {45.19,59.32}, {45.25,92.09}, {45.29,90.72}, {45.43,53.66}, {45.93,26.23}, {46.33,54.44}, {46.42,45.31},
                    {46.93,39.47}, {47.06,41.53}, {48.01,44.07}, {48.1,35.96}, {48.21,28.45}, {48.58,38.3}, {50.3,35.78}, {51.03,28.08},
                    {51.19,25.77}, {52.82,35.46}, {53.09,24.51}, {53.34,23.89}, {54.07,32.07}, {54.15,21.69}, {54.7,29.57}, {55.19,32.02},
                    {55.35,27.51}, {55.93,21.33}, {57.38,18.14}, {57.66,27.88}, {57.77,20.98}, {58.33,14.34}, {59.03,25.75}, {59.41,12.17},
                    {59.87,9.03}, {60.74,17.46}, {60.99,7.611}, {61.43,13.08}, {62.16,10.7}, {62.62,7.061},
                },
                ["Dun Morogh"] = {
                    {25.34,47.85}, {26.46,53.48}, {26.93,57.16}, {27.35,41.48}, {28.98,50.31}, {29.48,36.82}, {30.36,58.54}, {32.73,52.99},
                    {33.04,36.15}, {36.57,59.97}, {36.69,54.06}, {37.1,34.72}, {39.6,58.57}, {40.77,46.63}, {41.61,34.66}, {41.73,45.2},
                    {42.66,36.27}, {42.74,60.06}, {43.07,54.36}, {44.12,28.29}, {44.39,48.36}, {46.56,64.93}, {46.99,39.84}, {47.62,61.49},
                    {48.04,48.06}, {48.71,56.53}, {48.81,57.65}, {49.63,63.26}, {50.42,53.24}, {51.05,60.15}, {53.16,42.36}, {53.61,48.3},
                    {54.44,56.19}, {54.66,59.3}, {55.25,52.05}, {56.04,56.53}, {56.61,63.26}, {58.13,54.52}, {58.62,46.87}, {59.82,58.99},
                    {62.13,47.69}, {62.17,55.55}, {62.84,60.82}, {63.55,57.56}, {64.06,60.88}, {65.65,55.12}, {65.75,49.49}, {66.13,57.96},
                    {68.27,50.13}, {69.32,52.87}, {69.42,58.41}, {71.45,63.07}, {71.88,56.71}, {73.77,60.42}, {75.19,47.33}, {77.67,58.69},
                    {78.8,56.37}, {78.97,61.43}, {79.21,48.76}, {79.7,41.85}, {80.29,35.75}, {82.52,57.23}, {86.11,46.87},
                },
                Durotar = {
                    {36.06,29.68}, {36.57,43.81}, {37.19,56.8}, {37.21,22.73}, {37.23,36.29}, {37.78,29.4}, {38.36,18.56}, {40.84,35.33},
                    {42.66,19.81}, {42.81,29.91}, {44.13,32.15}, {44.42,21.46}, {47.06,49.12}, {47.82,31.67}, {48.24,19.53}, {48.26,79.36},
                    {49.18,12.75}, {50.77,31.04}, {52.51,61.2}, {53.34,86.9}, {53.87,11.02}, {53.95,82.05}, {54.33,58.19}, {54.82,37.23},
                    {54.84,65.91}, {55.14,30}, {56.1,44.43}, {56.35,21.2}, {57.2,78}, {58.32,59.22}, {58.41,63.02}, {58.52,15.92},
                    {58.6,69.88}, {58.87,90.36}, {58.98,48.72}, {59.41,85.2}, {59.68,55.61}, {60.11,82.87}, {60.57,52.49}, {60.61,41.31},
                    {60.81,77.91}, {61.13,79.36}, {61.13,90.53}, {62.27,93.83}, {63.33,95.81}, {64.41,85.97}, {65.37,81.06}, {65.84,83.47},
                    {66.88,87.92}, {67.6,72.21}, {67.87,82.62}, {68.11,86.93}, {69.36,75.7}, {70.02,72.61}, {97.01,61.2}, {98.05,54.68},
                    {98.96,50.9},
                },
                Duskwood = {
                    {10.2,45.46}, {10.79,35.8}, {11.86,29.85}, {14.09,67.3}, {16.49,34.41}, {21.12,77.07}, {21.23,64.3}, {22.09,36.18},
                    {22.16,26.8}, {24.16,80.29}, {24.64,71.79}, {27.64,46.07}, {28.57,60.3}, {29.09,74.63}, {29.38,32.13}, {31.53,38.8},
                    {34.12,27.35}, {34.9,59.35}, {34.98,43.74}, {35.12,75.85}, {38.57,23.18}, {39.16,58.13}, {43.2,20.18}, {45.31,73.91},
                    {45.83,17.07}, {48.64,60.46}, {49.53,73.18}, {49.94,20.91}, {52.42,11.02}, {53.79,21.18}, {53.94,59.57}, {57.57,64.41},
                    {58.42,18.46}, {58.6,51.52}, {59.86,73.41}, {60.75,36.41}, {61.86,27.85}, {63.98,41.52}, {64.6,73.07}, {65.05,52.35},
                    {65.12,28.57}, {65.57,20.52}, {67.75,76.63}, {69.12,49.74}, {69.46,70.79}, {71.94,70.29}, {73.79,75.02}, {74.09,21.85},
                    {76.68,30.41}, {77.83,51.07}, {78.83,38.68}, {78.98,66.63}, {79.42,54.41}, {81.46,74.63}, {81.72,20.85}, {87.68,49.52},
                },
                ["Elwynn Forest"] = {
                    {22.4,71.04}, {24.16,93.81}, {25.14,87.55}, {26.98,65.99}, {28.13,91.57}, {28.25,59.81}, {28.36,74.03}, {28.45,78.86},
                    {30.29,68.37}, {30.93,53.89}, {32.42,65.26}, {33.32,61.32}, {33.49,89.06}, {33.55,53.94}, {33.75,80.03}, {35.8,47.11},
                    {38.3,78.99}, {38.88,85.35}, {39.05,57.74}, {39.2,63.66}, {41.27,68.63}, {41.41,51.82}, {41.93,81.28}, {43.11,74.29},
                    {46.83,63.7}, {47.15,57.48}, {47.29,86.86}, {47.44,49.88}, {48.13,79.38}, {49.65,78}, {54.09,62.27}, {55.3,71.43},
                    {55.42,56.96}, {56.14,66.85}, {59.1,81.28}, {59.51,59.16}, {59.8,65.13}, {60.08,74.37}, {61.12,80.51}, {63.86,56.1},
                    {63.92,72.6}, {65.1,63.48}, {66.05,64.61}, {66.19,46.63}, {68.5,77.83}, {69.74,39.98}, {70.6,67.46}, {70.63,60.68},
                    {71.87,73.51}, {72.27,53.12}, {72.59,83.75}, {74.78,60.29}, {74.81,41.49}, {76.1,67.37}, {76.54,47.54}, {77.11,84.74},
                    {79.99,64.18}, {80.4,40.11}, {80.91,82.15}, {81.38,55.75}, {83.33,58.95}, {85.61,79.04}, {88.81,65.99}, {91.23,81.46},
                },
                ["Loch Modan"] = {
                    {18.9,76.24}, {19.4,83.63}, {21.47,16.39}, {22.6,27.91}, {24.19,37.48}, {25.31,26.01}, {27.05,42.48}, {27.13,54.5},
                    {27.31,11.23}, {27.31,85.1}, {27.74,33.95}, {28.07,58.79}, {28.5,86.95}, {28.94,23.13}, {29.77,16.82}, {29.95,71.67},
                    {30.39,82}, {30.75,48.63}, {33.07,26.99}, {33.18,88.74}, {34.02,40.15}, {34.63,75.42}, {35.32,81.24}, {35.97,37.32},
                    {36.3,12.96}, {38.15,32.97}, {39.05,25.96}, {39.05,75.91}, {39.31,35.42}, {40.76,9.214}, {40.98,17.42}, {41.48,69.23},
                    {43.55,59.66}, {44.6,71.67}, {47.28,21.12}, {47.61,28.08}, {49.89,70.42}, {50.98,28.02}, {52.25,75.04}, {53.63,40.74},
                    {54.57,35.63}, {54.9,26.72}, {56.09,65.37}, {56.93,13.13}, {60.12,64.34}, {61.1,31.01}, {61.24,21.34}, {61.6,58.14},
                    {62.8,80.26}, {63.67,51.94}, {63.89,39.49}, {64.9,71.35}, {65.99,44.17}, {68.28,73.3}, {69.91,41.01}, {72.05,35.42},
                    {73.31,70.7}, {73.89,62.27}, {75.24,52}, {75.85,39.93}, {77.27,30.85}, {78.79,44.55}, {79.11,67.27}, {79.55,75.37},
                },
                Mulgore = {
                    {28.3,20.94}, {28.98,23.48}, {30.79,25.55}, {30.87,19.56}, {31.2,40.7}, {32.23,28.7}, {32.72,47.16}, {33.3,66.92},
                    {33.38,43.27}, {33.38,76.76}, {33.79,33.73}, {33.89,24.24}, {33.93,81.08}, {34.45,40.59}, {34.51,70.51}, {34.68,53.14},
                    {34.84,61.37}, {35.03,48.35}, {35.09,44.85}, {35.56,43.04}, {35.68,15.94}, {36.77,19.71}, {37.27,68.38}, {37.29,40.62},
                    {37.68,48.29}, {37.94,53.05}, {38.27,49.78}, {38.48,73.96}, {38.83,63.65}, {39.76,19.56}, {40.97,49.4}, {41.13,39.51},
                    {41.32,7.798}, {41.85,16.91}, {42.04,12.99}, {42.04,56.32}, {43.19,36.06}, {43.21,8.966}, {43.58,72.41}, {43.6,26.19},
                    {44.24,67.07}, {45.45,52.18}, {45.57,8.09}, {46.07,12.91}, {46.17,38.72}, {46.44,17.23}, {47.28,7.272}, {47.3,33.75},
                    {47.4,72.64}, {47.73,68.47}, {48.04,25.58}, {48.21,46.48}, {48.72,12.15}, {49.13,8.47}, {50.86,37.99}, {51.89,63.48},
                    {52.88,31.21}, {53.14,48.38}, {53.25,38.57}, {53.84,20.12}, {53.86,42.48}, {54.3,73.37}, {56.25,39.33}, {56.76,30.45},
                    {56.78,72.97}, {56.84,23.36}, {57.93,44.35}, {58.1,58.69}, {59.79,67.45}, {61.99,71.65}, {62.38,56.12},
                },
                ["Redridge Mountains"] = {
                    {10.42,69.07}, {13.78,84.67}, {14.38,48.9}, {14.79,57.19}, {19.03,45.72}, {19.22,60.78}, {20.18,57.88}, {22.35,34.46},
                    {25.21,78.87}, {27.69,24.66}, {30.09,62.09}, {30.5,40.27}, {34.97,5.801}, {35.25,37.43}, {35.39,23.21}, {36.68,70.03},
                    {38.24,47.38}, {41.6,18.85}, {42.76,69.55}, {42.89,39.09}, {46.03,79.43}, {48.88,31.01}, {50.82,45.17}, {54.92,38.12},
                    {55.42,72.86}, {61.64,63.75}, {64.78,39.09}, {65.19,83.71}, {67.26,54.49}, {71.18,73.42}, {73.53,35.84}, {75.09,71.62},
                    {75.88,53.25}, {77.17,83.29}, {81.77,35.98}, {82.05,50.21}, {83.52,59.05},
                },
                ["Silverpine Forest"] = {
                    {34,15.95}, {36.24,19.99}, {37.14,14.42}, {39.05,31.27}, {39.62,18.06}, {40.31,25.02}, {42.86,28.6}, {43.05,79.1},
                    {43.17,70.31}, {43.31,19.31}, {43.33,72.13}, {43.55,31.56}, {43.93,46.99}, {44.33,80.56}, {44.81,51.63}, {45.21,56.67},
                    {45.62,71.92}, {45.81,77.24}, {45.86,34.02}, {46.36,82.63}, {46.79,73.52}, {46.98,47.52}, {47.07,52.31}, {47.26,25.88},
                    {47.33,56.17}, {48.19,40.99}, {48.38,68.2}, {48.48,32.02}, {48.95,85.35}, {49.14,34.92}, {49.21,74.85}, {49.57,54.52},
                    {49.79,58.38}, {50,15.17}, {50.43,77.6}, {50.83,48.1}, {50.98,27.92}, {51.07,61.52}, {51.14,20.95}, {51.33,44.85},
                    {51.43,40.74}, {51.57,55.02}, {51.69,69.1}, {52.19,87.24}, {52.52,64.95}, {52.67,51.81}, {53,77.1}, {53.21,12.02},
                    {53.26,38.74}, {53.43,23.77}, {53.52,83.7}, {53.64,32.45}, {53.76,46.24}, {54.74,71.88}, {55.33,80.31}, {55.4,59.99},
                    {55.45,22.38}, {55.62,53.52}, {55.76,42.13}, {55.95,68.02}, {56.31,35.6}, {57.1,47.95}, {57.17,15.92}, {58.26,42.95},
                    {58.62,8.774}, {59.71,67.13}, {60.36,80.2}, {60.74,41.45}, {61.55,74.95}, {62.69,61.95}, {63.07,72.17}, {63.52,5.595},
                    {64.19,56.2}, {64.5,23.45}, {64.55,43.74}, {65.1,62.6}, {65.31,9.738}, {65.52,30.85}, {66.02,52.13}, {66.14,77.6},
                    {66.48,35.7}, {66.64,21.1}, {68.12,24.77}, {70.79,19.1}, {71.86,35.88}, {74.24,17.27}, {76.21,21.42}, {77,32.81},
                    {77.48,27.24}, {79.29,30.13},
                },
                Teldrassil = {
                    {29.73,73.7}, {31.26,75.32}, {31.4,31.95}, {32.26,29.89}, {32.61,76.44}, {33.2,36.69}, {34.11,29.47}, {34.85,71.52},
                    {35.87,37.16}, {36.37,40.64}, {36.91,74.44}, {37.11,43.71}, {37.5,48.72}, {37.54,62.18}, {37.74,57.05}, {37.82,25.32},
                    {38.39,80.36}, {38.76,66.25}, {39.06,36.43}, {39.51,80.42}, {39.98,48.86}, {40.43,67.63}, {40.59,57.61}, {40.69,62.95},
                    {41.02,45.27}, {41.12,54.08}, {41.45,42.73}, {41.59,80.36}, {41.77,73.61}, {42.14,33.98}, {42.89,77.21}, {43.38,47.33},
                    {43.55,25.91}, {43.69,37.49}, {43.69,67.54}, {44.12,55.46}, {44.91,58.85}, {45.03,53.78}, {45.28,30.42}, {45.52,79.71},
                    {45.54,43.44}, {45.58,25.73}, {45.71,46.15}, {46.05,74.32}, {46.62,34.54}, {46.89,40.2}, {47.5,54.76}, {48.19,77.5},
                    {48.25,70.25}, {48.33,27.03}, {48.44,44.27}, {48.76,31.6}, {49.03,72.26}, {49.09,67.22}, {50.09,60.86}, {50.66,75.65},
                    {52.04,63.65}, {52.25,72.99}, {52.76,74.88}, {52.78,61.41}, {52.94,76.74}, {53.04,80.07}, {54.18,66.81}, {54.34,72.29},
                    {55.45,69.69}, {56.2,77}, {56.55,74.7}, {58.28,65.98}, {58.87,71.76}, {58.99,75.59}, {61.35,60.71}, {61.64,72.67},
                    {61.88,66.63}, {62.64,63.98}, {63.09,73.23}, {64.14,60.27}, {64.55,68.78}, {64.84,52.19}, {65.96,65.25}, {67.34,58.2},
                    {67.36,52.63}, {67.4,63.92}, {69.07,53.99}, {69.85,58.14},
                },
                ["The Barrens"] = {
                    {38.97,16.01}, {39.35,10.69}, {39.57,30.57}, {40.28,20.98}, {40.75,21.97}, {40.82,45.54}, {41.18,79.56}, {41.56,59.86},
                    {42.04,28.65}, {42.07,38.85}, {42.48,33.16}, {42.74,49.72}, {43.16,38.76}, {43.43,72.09}, {43.49,55.84}, {43.98,81.22},
                    {44.03,22.61}, {44.49,11.3}, {44.65,90.89}, {45.06,61.25}, {45.1,51.28}, {45.37,43.32}, {45.43,86.59}, {45.73,21.59},
                    {46.95,79.16}, {47.32,53.68}, {47.64,49.16}, {47.76,63.34}, {48,28.35}, {48.18,15.42}, {48.19,9.895}, {48.32,73.95},
                    {48.51,51.01}, {49.37,35.63}, {49.72,31.76}, {49.88,47.96}, {51.2,17.4}, {51.32,23.63}, {51.4,38.68}, {51.48,12.19},
                    {52.01,50.23}, {52.06,44.75}, {52.07,22.14}, {52.64,15.43}, {52.87,36.43}, {52.96,55.73}, {54.08,35.99}, {54.78,23.16},
                    {54.93,47.98}, {54.94,38.48}, {55.11,14.35}, {55.53,31.62}, {55.54,27.55}, {55.59,40.5}, {56.71,33.83}, {56.74,9.717},
                    {56.85,5.513}, {57.03,43.85}, {57.24,47.49}, {57.58,25.64}, {58.08,18.2}, {58.41,32.42}, {58.89,27.02}, {59.15,8.34},
                    {59.4,51.71}, {59.76,22.61}, {60.22,11.12}, {61.21,32.35}, {61.85,52.54}, {62.23,3.145}, {62.44,10.5}, {63.58,48.45},
                    {64.6,43.64}, {31.84,31.42}, {32.34,30.65}, {33.04,34.57}, {34.39,35.32}, {35.46,38.02}, {36.18,50.75}, {36.22,37.81},
                    {36.28,52.33}, {36.51,41.89}, {37.07,53.19}, {38.3,57.02}, {39.5,64.04}, {39.84,62.57}, {40.41,57.73}, {97.42,26.95},
                    {98.13,29.65}, {98.42,24.25}, {98.47,22.06}, {98.8,30.23}, {99.18,19.96}, {99.29,25.89}, {99.59,21.72},
                },
                ["Tirisfal Glades"] = {
                    {30.59,51.57}, {32.41,45.03}, {33.51,52.13}, {35.24,47.78}, {38.07,52.53}, {38.18,45.56}, {39.02,38.22}, {39.51,54.19},
                    {40.79,44.27}, {41.12,65.88}, {41.68,61.66}, {42.25,46.06}, {42.39,43.47}, {42.63,50.97}, {43.23,39.85}, {43.45,70.02},
                    {43.58,54.95}, {43.74,63.75}, {43.98,28.53}, {44.64,34.54}, {45.02,59.97}, {45.88,43.63}, {46.04,69.13}, {46.88,60.96},
                    {47.34,53.83}, {47.63,50.14}, {47.65,28.03}, {47.83,45.2}, {48.34,60.73}, {48.91,64.58}, {49.91,68.76}, {50.04,36.76},
                    {50.4,27.77}, {50.73,53.29}, {51.55,57.24}, {51.73,62.99}, {51.97,69.23}, {52.21,47.98}, {53.03,29.93}, {53.78,73.38},
                    {53.92,70.32}, {54.4,43.77}, {55.04,60.8}, {56.73,34.77}, {57.17,40.02}, {57.83,58.64}, {60.44,32.85}, {61.26,42.04},
                    {62.52,36.1}, {62.97,41.91}, {63.37,48.35}, {64.47,52.93}, {65.82,64.88}, {66.49,48.81}, {66.64,39.29}, {68.77,43.07},
                    {69.58,61.06}, {69.85,31.85}, {70.25,57.44}, {70.65,54.16}, {71.07,47.49}, {71.64,52.43}, {71.66,36.93}, {72.57,56.45},
                    {72.68,59.3}, {72.7,62.92}, {72.93,43.57}, {73.12,32.58}, {74.78,47.62}, {74.85,55.82}, {75.21,58.11}, {76.33,51},
                    {77.04,33.44}, {78.75,48.12}, {79.03,59.27}, {80.87,42.04}, {81.36,29.43}, {81.36,52.13}, {82.77,47.25}, {83.37,54.46},
                    {84.5,34.77}, {85.38,43.37}, {86.31,54.52}, {88.02,44.83}, {89.66,52.4},
                },
                Westfall = {
                    {26.48,62.19}, {28.42,41.83}, {30.39,86.79}, {30.9,32.79}, {32.42,60.6}, {32.65,29.23}, {32.9,68.32}, {34.96,52.67},
                    {35.3,73.29}, {37.39,84.64}, {38.05,27.9}, {41.93,68.83}, {42.25,30.69}, {43.36,81.09}, {44.19,70.76}, {44.56,20.83},
                    {45.76,62.19}, {48.28,35.66}, {48.73,11.66}, {49.85,41.14}, {50.16,78.9}, {50.45,15.09}, {51.28,55.2}, {51.42,71.49},
                    {51.79,33.56}, {55.62,73.46}, {55.99,14.01}, {57.19,21.86}, {57.65,31.07}, {58.85,43.11}, {60.02,59.1}, {60.16,17.49},
                    {60.28,25.8}, {61.59,79.93}, {63.9,49.46}, {64.16,76.84}, {64.9,64.16}, {67.48,59.36}, {69.02,67.84}, {70.79,73.72},
                },
                Wetlands = {
                    {11.04,43}, {13.72,48.87}, {15.82,35.96}, {15.95,28.81}, {17.42,37.7}, {19.16,31.75}, {21,36.83}, {21.87,50.98},
                    {22.06,42.71}, {22.6,24.93}, {23.22,57.04}, {24.09,39.08}, {24.24,32}, {24.72,44.41}, {25.74,44.59}, {25.86,25.18},
                    {28.83,28.81}, {29.2,46.19}, {30.53,32.15}, {30.99,20.9}, {32.49,49.27}, {33.28,40.71}, {33.48,29.83}, {35,19.7},
                    {37.68,43.54}, {37.83,28.37}, {40.56,39.98}, {40.95,21.05}, {42.06,33.67}, {43.78,25.04}, {44.04,45.83}, {44.09,39.4},
                    {44.72,32.26}, {45.62,28.23}, {46.68,15.28}, {47.02,35.74}, {47.57,42.45}, {49.41,49.6}, {49.51,30.84}, {49.61,13.39},
                    {49.82,42.52}, {50.19,22.93}, {50.55,37.77}, {52.31,26.63}, {52.7,38.1}, {52.85,56.02}, {53.81,35.3}, {54.03,49.2},
                    {54.68,68.65}, {54.78,61.25}, {54.93,28.85}, {55.6,75.94}, {55.68,46.33}, {55.75,40.82}, {56.16,22.13}, {56.38,55.66},
                    {57.54,28.81}, {59.64,56.35}, {60.71,37.7}, {61.02,77.72}, {61.36,26.52}, {62.25,72.96}, {63.2,43.29}, {64.79,66.58},
                    {64.96,49.31}, {65.03,31.35}, {66.17,60.77}, {67.16,73.04}, {68.35,34.98}, {68.59,52.5}, {72.92,46.44}, {73.74,39.91},
                    {76.13,45.28},
                },
            },
        },
        {
            tier = "Bright",
            treeNamePattern = "^Bright Wood",
            woodItem = { name = "Bright Wood", itemId = 42007, icon = "Interface\\Icons\\oak_wood_1" },
            leafItem = { name = "Bright Leaves", itemId = 34001, icon = "Interface\\Icons\\INV_Misc_Herb_MountainSilversage" },
            -- 125 -- was nil/"not confirmed" (db.capycraft.org's item page
            -- for Bright Wood has no Level stat, unlike Star Wood's, which
            -- is how that one was guessed). Set 2026-08-16 from a
            -- TurtleCraft forum "Survival Tree Locations" leveling guide
            -- (forum.turtlecraft.gg, t=24572, via web.archive.org) -- see
            -- the note on Simple's level above for the full source and the
            -- other 5 tiers' numbers from the same post.
            level = 125,
            pets = {
                { name = "Dung Beetle", itemId = 37063, chance = 0.05 },
                { name = "Reclusive Spider", itemId = 37064, chance = 0.05 },
            },
            -- 6 separate objects, #2020282-2020287, one per zone --
            -- re-checked object-by-object 2026-08-15, all 6 confirmed.
            -- Northwind and Balor are real custom Turtle WoW zones (both
            -- confirmed independently, not just by the object nickname)
            -- -- same octowow.st Locations-page caveat as Blackstone
            -- Island/Thalassian Highlands above.
            chopZones = { "Hillsbrad Foothills", "Thousand Needles", "Northwind", "Balor", "Ashenvale", "Stonetalon Mountains" },
            zoneCounts = {
                ["Hillsbrad Foothills"] = 43, ["Thousand Needles"] = 19, Northwind = 67,
                Balor = 3, Ashenvale = 116, ["Stonetalon Mountains"] = 74,
            },
-- dropped as continent-catchall (different coord space): Azeroth(49)
-- dropped as boundary-spillover (not in confirmed chopZones): Alterac Mountains(18), Arathi Highlands(7), The Barrens(15), Feralas(2), Dun Morogh(16), Elwynn Forest(3), Burning Steppes(2), Desolace(1)
-- confirmed real zones with NO spawn-point data found: Northwind, Balor
            spawnPoints = {
                Ashenvale = {
                    {13.08,35.43}, {14.48,31.45}, {16.53,27.5}, {16.54,18.5}, {17.1,21.83}, {17.12,40.01}, {17.32,46.31}, {17.43,19.07},
                    {17.84,59.78}, {18.31,53.85}, {18.49,31.5}, {19.04,42.74}, {19.08,18.91}, {19.49,50.42}, {20.45,35.09}, {20.53,38.97},
                    {20.67,45.19}, {20.9,58.77}, {21.07,32.39}, {23.51,47.84}, {24.07,52.71}, {24.14,38.97}, {26.51,30.44}, {27.61,23.57},
                    {28.34,46.96}, {29.12,31.27}, {30.35,43.31}, {30.83,19.04}, {31.77,69.33}, {32.29,36.81}, {32.43,59.81}, {32.67,25.08},
                    {33.83,28.49}, {34.94,32.65}, {35.1,59.55}, {35.6,69.98}, {35.91,72.71}, {36.21,45.01}, {36.52,61.5}, {37.25,36.63},
                    {37.3,68.6}, {38.83,57.52}, {39.75,53.85}, {39.95,38.76}, {40.2,48.39}, {41.25,67.25}, {42,70.89}, {43.42,43.16},
                    {43.58,47.43}, {46.11,72.48}, {46.23,59.21}, {46.34,45.97}, {47.72,70.42}, {47.76,47.19}, {47.95,66.42}, {50.25,59.34},
                    {51.42,48.83}, {51.83,65.61}, {52.02,43.97}, {52.23,61.53}, {52.73,53.9}, {52.91,46.54}, {53.88,40.92}, {54.55,65.77},
                    {55.04,53.28}, {56.03,64.26}, {56.62,67.64}, {56.88,76.62}, {57.45,72.56}, {57.81,63.97}, {58.47,33.45}, {58.47,54.19},
                    {58.75,70.01}, {59.38,75.5}, {59.84,42.22}, {60.31,81.38}, {60.43,72.48}, {60.73,49.4}, {60.92,39.02}, {62.25,75.89},
                    {63,86.42}, {64.7,84.45}, {64.75,73.1}, {65.62,43.76}, {66.4,50.47}, {67.27,86.55}, {67.37,45.84}, {68.43,72.79},
                    {68.53,79.76}, {71.05,50.6}, {71.44,83.04}, {71.74,74.77}, {71.81,63.58}, {72.8,46.12}, {73.06,79.06}, {74.41,44.67},
                    {75.78,76.62}, {76.14,65.19}, {76.84,53.49}, {77.31,68.08}, {78.02,72.66}, {78.03,65.14}, {78.55,41.16}, {79.8,74.85},
                    {80.76,44.85}, {81.85,60.56}, {82.63,46.2}, {83.6,56.3}, {83.88,48.83}, {86.46,49.85}, {88.32,42.87}, {90.05,39.28},
                    {90.42,49.4}, {92.31,46.05}, {93.59,41.26}, {96.35,37.28},
                },
                ["Hillsbrad Foothills"] = {
                    {17.24,54.75}, {17.93,47.58}, {21.55,52.45}, {23.99,62.48}, {24.4,42.05}, {26.18,54.89}, {27.9,63.61}, {28.36,34.5},
                    {29.96,39.66}, {30.3,44.86}, {31.46,57.05}, {31.86,63.94}, {33.33,51.75}, {36.4,58.64}, {36.61,42.38}, {39.9,64.88},
                    {40.08,41.67}, {40.99,55.41}, {42.55,35.11}, {46.74,54.19}, {48.86,37.78}, {53.05,43.59}, {53.96,51.75}, {57.11,53.16},
                    {57.71,62.48}, {58.52,41.39}, {58.99,35.77}, {60.36,50.02}, {61.9,72}, {62.24,63.75}, {63.15,54.42}, {64.02,37.55},
                    {64.65,47.25}, {64.77,74.86}, {66.11,68.67}, {66.43,60.23}, {67.05,39.19}, {68.15,53.81}, {70.86,71.39}, {71.86,55.31},
                    {72.9,38.91}, {80.36,31.22}, {84.24,38.39},
                },
                ["Stonetalon Mountains"] = {
                    {17.36,20.72}, {20.29,27.84}, {21.54,20.69}, {22.6,32.17}, {25.06,28.09}, {27.11,69.64}, {27.52,52.04}, {30.39,65.83},
                    {31.23,38.35}, {31.47,6.101}, {31.49,58.83}, {31.8,49.8}, {31.88,12.4}, {31.9,73.72}, {32.47,16.88}, {34.01,60.3},
                    {34.85,36.96}, {35.71,47.1}, {35.83,31.04}, {36.14,13.75}, {37.08,20.9}, {37.18,68.69}, {37.53,7.637}, {38.95,33.37},
                    {39.5,10.74}, {39.85,17.77}, {40.44,71.08}, {42,31.07}, {42.47,29.07}, {43.43,66.48}, {43.76,42.62}, {45.56,20.6},
                    {46.71,29.69}, {49.02,34.51}, {49.06,47.65}, {50.7,40.71}, {52.28,34.51}, {53.53,43.63}, {53.65,56.34}, {53.65,75.94},
                    {53.98,70.93}, {54.63,64.27}, {54.98,37.55}, {58.46,71.97}, {59.96,50.45}, {60.12,61.35}, {60.69,76.43}, {61.25,46.67},
                    {61.63,81.89}, {61.8,65.56}, {62.25,57.33}, {63.97,53.27}, {64.32,92.18}, {64.67,48.05}, {64.67,95.71}, {67.12,56.87},
                    {68.19,46.67}, {69.46,89.88}, {71.28,91.91}, {71.46,42.8}, {71.55,55.05}, {72.34,86.44}, {74.41,51.28}, {74.41,80.05},
                    {74.95,50.39}, {75.11,43.38}, {75.4,84.01}, {75.97,64.85}, {76.28,69.12}, {77.2,50.69}, {77.91,43.57}, {78.86,64.33},
                    {78.9,60.92}, {79.12,50.75},
                },
                ["Thousand Needles"] = {
                    {12.54,25.44}, {17.56,22.78}, {18.72,21.32}, {21.54,34.99}, {23.2,43.75}, {32.58,35.09}, {34.77,54.01}, {39.88,50.67},
                    {43.65,36.9}, {45.97,58.82}, {47.56,40.17}, {48.13,52.48}, {51.42,42.15}, {52.67,47.47}, {60.74,59.7}, {60.79,54.15},
                    {62.97,46.82}, {67.06,63.83}, {69.15,52.65},
                },
            },
        },
        {
            tier = "Shade",
            treeNamePattern = "^Shade Wood Tree",
            woodItem = { name = "Shade Wood", itemId = 42008, icon = "Interface\\Icons\\pine_wood_1" },
            leafItem = { name = "Shade Leaves", itemId = 42143, icon = "Interface\\Icons\\INV_Misc_Herb_12" },
            -- 175 -- was 30 (an item-level guess, same method as Star's
            -- below, never independently confirmed). Corrected 2026-08-16
            -- from a TurtleCraft forum "Survival Tree Locations" leveling
            -- guide (forum.turtlecraft.gg, t=24572, via web.archive.org) --
            -- see the note on Simple's level above for the full source.
            level = 175,
            pets = {
                { name = "Darkfeather Owl", itemId = 37065, chance = 0.05 },
                { name = "Shadewing Bat", itemId = 37066, chance = 0.05 },
            },
            -- CORRECTED 2026-08-15: a re-verification pass against item
            -- 42008's own "Contained In" list on db.capycraft.org found the
            -- previous version of this list was wrong -- it had drifted in
            -- 5 zones that don't actually carry Shade Wood (Loch Modan,
            -- Wetlands, Mulgore, Silverpine Forest, Hillsbrad Foothills) and
            -- was missing 5 that do (Badlands, Dustwallow Marsh, Swamp of
            -- Sorrows, Hinterlands, Feralas). Re-fetched fresh and confirmed
            -- against the primary source, not carried over from the
            -- earlier list.
            -- DOUBLE-CHECKED 2026-08-15, same day, one level deeper: this
            -- tier is actually 11 separate objects (#2020288-2020297 +
            -- #2020309), one per zone. Checked all 11 individually against
            -- octowow.st's own per-object Locations page. All 11 zones
            -- below confirmed correct. Grim Reaches and Gilneas are real
            -- custom Turtle WoW zones -- octowow.st's Locations page
            -- doesn't recognize either one and instead reports Loch
            -- Modan/Wetlands (for the Grim Reaches object) or Silverpine
            -- Forest/Hillsbrad Foothills (for the Gilneas object), which
            -- is exactly the same 4 zones removed above, now showing up
            -- again as a site artifact -- good corroboration the removal
            -- was right, not a reason to add them back.
            chopZones = {
                "Stranglethorn Vale", "Arathi Highlands", "Grim Reaches", "Alterac Mountains",
                "Badlands", "Dustwallow Marsh", "Desolace", "Swamp of Sorrows",
                "Hinterlands", "Gilneas", "Feralas",
            },
            zoneCounts = {
                ["Stranglethorn Vale"] = 68, ["Arathi Highlands"] = 49, ["Grim Reaches"] = 62,
                ["Alterac Mountains"] = 20, Badlands = 39, ["Dustwallow Marsh"] = 50,
                Desolace = 63, ["Swamp of Sorrows"] = 34, Hinterlands = 67,
                Gilneas = 47, Feralas = 78,
            },
-- dropped as continent-catchall (different coord space): Azeroth(97)
-- dropped as boundary-spillover (not in confirmed chopZones): Loch Modan(7), Wetlands(5), Searing Gorge(1), Mulgore(1), Silverpine Forest(5), Hillsbrad Foothills(1)
-- confirmed real zones with NO spawn-point data found: Grim Reaches, Gilneas
            spawnPoints = {
                ["Alterac Mountains"] = {
                    {33.12,65.95}, {36.08,49.55}, {36.19,57.05}, {36.58,67.45}, {39.3,73.23}, {40.44,49.07}, {40.51,60.91}, {40.8,66.8},
                    {41.15,31.29}, {42.4,44.84}, {42.8,36.91}, {45.98,29.73}, {47.15,57.05}, {48.08,46.55}, {48.23,37.77}, {49.15,32.68},
                    {50.51,41.09}, {51.4,52.45}, {56.94,41.14}, {63.83,47.14},
                },
                ["Arathi Highlands"] = {
                    {16.4,68.82}, {19.31,38.69}, {22.09,43.82}, {22.26,71.24}, {23.29,28.94}, {23.34,49.36}, {27.18,19.82}, {28.26,67.65},
                    {31.29,30.86}, {31.4,42.57}, {32.48,21.32}, {32.81,25.99}, {33.15,56.69}, {35.04,46.19}, {35.98,66.82}, {37.29,43.15},
                    {38.73,28.61}, {39.68,49.74}, {40.9,74.86}, {42.56,63.19}, {43.37,78.28}, {44.81,36.9}, {45.95,53.4}, {48.18,83.32},
                    {49.62,62.82}, {49.93,36.24}, {53.15,33.36}, {53.73,71.15}, {54.04,53.94}, {56.65,35.94}, {56.79,38.28}, {57.95,32.44},
                    {59.37,71.99}, {61.7,43.53}, {64.18,72.99}, {64.23,53.03}, {64.73,65.4}, {65.4,27.4}, {66.93,69.49}, {68.7,32.19},
                    {69.18,72.99}, {70.37,60.19}, {71.43,68.9}, {72.15,49.07}, {72.76,67.28}, {73.31,60.53}, {76.84,32.78}, {78.34,38.36},
                    {81.81,37.36}, {39.37,16.15}, {40.54,19.69}, {85.06,18.9},
                },
                Badlands = {
                    {4.496,80.53}, {10,64.25}, {10.69,78.42}, {12.78,35.12}, {13.7,88.13}, {17.2,41.39}, {20.42,73.41}, {20.9,60.09},
                    {27.01,68.41}, {29.42,55.8}, {33.88,34.4}, {35.29,76.49}, {35.85,70.1}, {36.5,47.18}, {40.8,74.02}, {41.96,58.1},
                    {43.97,29.75}, {45.18,85.65}, {47.03,42.18}, {49.64,67.44}, {52.25,85.11}, {53.46,53.33}, {55.39,22.16}, {58.81,72.81},
                    {60.29,60.93}, {62.3,79.2}, {64.88,44.53}, {65.48,21.49}, {68.54,35.3}, {70.14,53.27}, {70.91,81.91}, {73.92,78.48},
                    {75.29,43.38}, {78.14,48.75}, {79.39,34.82}, {80.23,64}, {82.73,53.51}, {87.07,40.43}, {89.28,32.47},
                },
                Desolace = {
                    {29.95,54.21}, {32.19,52.41}, {32.88,60.04}, {34.35,81.23}, {34.84,56.24}, {35,87.86}, {35.02,61.55}, {35.62,37.6},
                    {39.38,36.19}, {39.4,69.48}, {40.18,51.81}, {41.87,81.99}, {43.07,60.08}, {44.34,71.49}, {44.38,28.92}, {44.47,42.3},
                    {44.65,86.36}, {44.78,52.54}, {46.74,16.05}, {46.76,65.61}, {47.85,57.21}, {47.85,93.23}, {48.7,31.72}, {49.7,5.907},
                    {49.88,41.8}, {50.79,44}, {51.39,61.25}, {52.06,91.17}, {52.48,21.75}, {53.46,58.34}, {55.1,67.18}, {56.06,21.18},
                    {57.66,47.64}, {57.73,7.708}, {57.79,82.73}, {59.06,41.66}, {60.77,75.32}, {60.93,79.39}, {61.02,24.29}, {61.11,69.65},
                    {61.33,53.57}, {63.18,92.43}, {63.78,88.6}, {63.87,16.65}, {64.29,59.08}, {65.05,38.63}, {65.27,24.49}, {65.6,70.89},
                    {68.69,31.46}, {69.58,78.76}, {70.07,58.11}, {70.78,42.93}, {71.16,35.89}, {71.83,19.15}, {71.85,48.57}, {73.1,12.64},
                    {73.43,74.85}, {75.34,10.48}, {75.77,52.07}, {76.23,34.69}, {76.77,26.75}, {77.37,17.05}, {79.46,21.65},
                },
                ["Dustwallow Marsh"] = {
                    {32.08,66.45}, {33.45,63.9}, {33.54,24.22}, {34.13,69.33}, {34.59,73.02}, {35.14,20.82}, {36.32,49.33}, {36.46,54.59},
                    {36.99,44.22}, {37.81,56.93}, {38.51,68.65}, {38.86,51.79}, {39.96,16.76}, {40.15,26.33}, {40.55,11.62}, {41.33,44.13},
                    {41.62,34.88}, {42.29,57.68}, {43.39,38.48}, {43.71,63.65}, {44.23,54.3}, {44.34,16.08}, {45.07,43.62}, {46.25,49.53},
                    {46.65,59.22}, {47.18,75.82}, {48.02,47.16}, {48.63,82.02}, {48.78,59.73}, {49.03,17.22}, {49.37,66.59}, {49.64,20.42},
                    {50.53,28.9}, {52.29,58.62}, {52.32,52.45}, {52.99,70.16}, {53.62,72.99}, {55.43,24.33}, {56.1,34.39}, {56.3,71.22},
                    {57.24,80.13}, {57.28,22.02}, {57.35,29.99}, {58.23,26.65}, {58.95,69.88}, {60.65,35.22}, {61.31,39.33}, {64.21,77.05},
                    {66.29,73.28}, {66.29,83.13},
                },
                Feralas = {
                    {23.74,65.32}, {25.77,64.09}, {26.08,49.04}, {28.23,52.43}, {28.7,45.37}, {31.81,49.6}, {36.01,31.88}, {37.15,21.42},
                    {38.2,11.49}, {38.57,25.45}, {38.92,15.18}, {39.64,9.352}, {41.68,18.5}, {42.21,10.76}, {43.97,9.439}, {44.01,20.29},
                    {44.38,35.14}, {46.11,30.07}, {47.38,17.08}, {48.14,5.986}, {48.17,45.68}, {49.72,27.16}, {50.54,33.24}, {50.57,46.67},
                    {51.02,16.8}, {51.46,22.43}, {51.61,51.35}, {52.12,8.532}, {52.43,29.7}, {52.5,31.5}, {54,49.15}, {54.11,14.92},
                    {54.41,10.41}, {54.61,65.9}, {54.89,4.388}, {55.29,56.62}, {55.32,72.76}, {56.5,47.53}, {56.86,76.58}, {58.3,59.34},
                    {59.41,56.92}, {59.95,44.96}, {59.95,73.65}, {61.19,57.27}, {61.23,67.63}, {61.48,49.45}, {61.49,62.94}, {63.12,71.01},
                    {63.49,49.32}, {64.89,52.47}, {65.87,51.14}, {66.3,38.68}, {66.92,46.73}, {67.25,56.51}, {68.33,39.81}, {68.92,61.86},
                    {69.59,51.29}, {70.61,45.07}, {72.02,35.1}, {72.3,49.88}, {72.87,58.8}, {74.97,61.71}, {76,53.36}, {76.94,47.34},
                    {77,64.69}, {77.05,41.45}, {77.22,33.29}, {78.1,59.47}, {79.66,46.97}, {80.59,34.86}, {80.96,38.27}, {81.51,44.7},
                    {83.25,48.78}, {83.79,56.94}, {83.85,64.82}, {85.45,45.01}, {87.32,39.05}, {89.79,38.81},
                },
                Hinterlands = {
                    {16.57,54.26}, {21.97,79.51}, {22.31,74.75}, {22.36,50.71}, {23.48,58.9}, {24.36,80.68}, {26.03,67.66}, {26.49,53.6},
                    {26.49,80.13}, {28.83,46.23}, {29.95,59.95}, {30.39,74.01}, {31.53,58.43}, {32.44,63.88}, {32.65,48.26}, {33.77,66.81},
                    {35.3,73}, {37.09,43.86}, {38.99,63.92}, {39.56,49.82}, {39.74,66.92}, {41.51,55.39}, {43.04,45.88}, {44.23,68.29},
                    {45.14,50.99}, {45.71,38.17}, {46.49,40.97}, {47.01,69.14}, {48.26,62.01}, {48.94,47.95}, {49.9,51.96}, {50.73,39.96},
                    {51.87,56.83}, {54.47,66.88}, {56.62,52.16}, {57.17,42.53}, {58.03,75.26}, {58.49,17.25}, {58.57,66.92}, {58.94,43.7},
                    {60.31,74.44}, {60.44,55}, {60.55,64.35}, {60.81,27.26}, {62.6,15.69}, {63.17,32.87}, {63.25,84.49}, {63.3,66.1},
                    {63.48,49.39}, {63.51,62.64}, {65.35,68.25}, {66.62,72.57}, {66.78,20.4}, {66.88,25.82}, {66.96,42.81}, {66.99,81.06},
                    {67.01,77.52}, {67.25,66.88}, {67.4,50.95}, {67.56,31.66}, {69.25,61.74}, {70.13,49.66}, {73.92,72.3}, {74.16,55.97},
                    {78.83,50.6}, {79.38,59.52}, {80.31,43.16},
                },
                ["Stranglethorn Vale"] = {
                    {19.32,11.19}, {19.55,22.59}, {21.18,14.34}, {21.26,23.21}, {21.98,17.54}, {22.75,11.17}, {23.96,13.47}, {23.99,8.773},
                    {25.02,15.99}, {25.24,8.843}, {25.96,10.61}, {26.01,13.38}, {27.75,13.12}, {27.86,16.81}, {28.91,8.726}, {30.13,25.7},
                    {30.34,13.47}, {30.45,20.15}, {30.63,7.386}, {30.74,22.81}, {31.84,14.79}, {32.25,18.5}, {33.34,24.24}, {33.99,16.08},
                    {34.33,12.65}, {34.58,22.45}, {34.87,6.587}, {35.26,37.78}, {36.07,26.07}, {37.04,30.21}, {37.29,41.24}, {37.95,26.24},
                    {37.95,35.08}, {39.25,45.96}, {39.71,40.81}, {39.91,32.73}, {40.18,30.19}, {40.63,8.679}, {41.32,26.5}, {41.67,42.58},
                    {41.81,35.57}, {42.09,11.62}, {42.09,44.29}, {42.51,32.11}, {42.89,16.69}, {43.09,37.55}, {43.22,21}, {44.25,7.198},
                    {44.36,42.83}, {44.61,13.19}, {44.64,34.47}, {44.8,27.55}, {45.13,9.995}, {45.69,25.34}, {45.76,40.25}, {46.26,37.05},
                    {46.51,31.72}, {46.65,28.68}, {47.17,43.63}, {47.29,34.75}, {47.83,10.47}, {47.93,16.93}, {47.98,22.9}, {48.69,30.92},
                    {49.31,13.07}, {49.39,25.65}, {50.46,21.51}, {50.77,30.07},
                },
                ["Swamp of Sorrows"] = {
                    {7.458,30.42}, {13.17,58.15}, {15.52,46.11}, {16.09,34.28}, {16.88,63.05}, {26.6,62.53}, {32.66,44.28}, {34.71,53.44},
                    {40.33,38.33}, {50.27,28.46}, {53.15,38.14}, {54.98,46.44}, {57.42,63.84}, {58.9,27.22}, {62.04,49.38}, {62.13,33.49},
                    {64.27,41.21}, {64.31,64.1}, {64.66,25.71}, {65.57,14.92}, {68.8,67.83}, {69.41,27.67}, {71.02,81.56}, {71.76,10.67},
                    {74.6,41.01}, {74.82,22.51}, {75.43,68.81}, {78.13,88.62}, {81.62,66.13}, {82.1,46.96}, {88.5,54.09}, {88.68,69.98},
                    {89.29,63.84}, {92.21,46.51},
                },
            },
        },
        {
            tier = "Tropical",
            treeNamePattern = "^Tropical Wood Tree",
            woodItem = { name = "Tropical Wood", itemId = 42009, icon = "Interface\\Icons\\tropical_logs_1" },
            leafItem = { name = "Tropical Leaves", itemId = 42145, icon = "Interface\\Icons\\INV_Misc_Herb_04" },
            -- 225 -- was 50 (an item-level guess off Tropical Leaves,
            -- since Tropical Wood's own item page didn't show one).
            -- Corrected 2026-08-16 from a TurtleCraft forum "Survival Tree
            -- Locations" leveling guide (forum.turtlecraft.gg, t=24572, via
            -- web.archive.org) -- see the note on Simple's level above for
            -- the full source.
            level = 225,
            pets = {
                { name = "Tropical Monkey", itemId = 37067, chance = 0.05 },
                { name = "Vibrant Parrot", itemId = 37068, chance = 0.05 },
            },
            -- Re-verified 2026-08-15 against object #2020298's "Locations"
            -- list (the item page itself has no zone data). Matches these 4
            -- named zones exactly, PLUS an unresolved 5th coordinate
            -- cluster the site only tags as "Azeroth" (a continent-level
            -- label, not an actual zone). Worth flagging: that cluster is
            -- 84 spawns, bigger than any of the 4 confirmed zones (45-57
            -- each) -- best guess at the time (2026-08-15) was Tel'abim, a
            -- custom Turtle WoW island zone off the eastern Tanaris coast,
            -- based on thematic/geographic fit alone, not added to
            -- chopZones yet pending confirmation.
            -- RECONCILED 2026-08-16: the same forum "Survival Tree
            -- Locations" post's own zone list for this tier independently
            -- names Tel'abim as a Tropical Wood zone -- two independent
            -- sources (octowow.st's unresolved cluster + this forum list)
            -- now agree, so Tel'abim is promoted from "guess" to "confirmed
            -- enough to include," with the 84-spawn count carried over from
            -- that cluster. The same forum list also names two more custom
            -- island zones not in octowow.st's data at all -- Lapidis Isle
            -- and Gillijim's Isle -- added below with no spawn count (no
            -- corroborating count data exists yet for either). Westfall
            -- stays in the list even though the forum's own post omits it,
            -- since it's independently confirmed via octowow.st and
            -- omission from a leveling guide doesn't mean zero spawns --
            -- see the RARE_ZONE_THRESHOLD note above woodTiers for why
            -- confirmed-but-sparse/uncounted zones are kept, not deleted.
            chopZones = { "Tanaris", "Un'Goro Crater", "Stranglethorn Vale", "Westfall", "Tel'abim", "Lapidis Isle", "Gillijim's Isle" },
            -- Westfall's count didn't render on the object's page at all
            -- (present, just uncounted) -- left out rather than guessed.
            -- Lapidis Isle and Gillijim's Isle have no count data at all
            -- yet (forum-only zones, not in octowow.st's object data).
            zoneCounts = { Tanaris = 57, ["Un'Goro Crater"] = 55, ["Stranglethorn Vale"] = 45, ["Tel'abim"] = 84 },
-- dropped as continent-catchall (different coord space): Azeroth(84)
-- dropped as boundary-spillover (not in confirmed chopZones): none
-- confirmed real zones with NO spawn-point data found: Tel'abim, Lapidis Isle, Gillijim's Isle
            spawnPoints = {
                ["Stranglethorn Vale"] = {
                    {1.079,57.43}, {4.448,68.08}, {4.934,70.13}, {23.54,49.63}, {24.73,53.69}, {24.93,61.31}, {25.59,85.64}, {26.51,65.68},
                    {26.76,82.94}, {27.06,69.54}, {27.64,46.95}, {27.7,39.92}, {27.81,49.74}, {28.27,63.12}, {28.88,58.44}, {29.07,69.75},
                    {29.38,44.69}, {29.9,57.64}, {30.32,87.4}, {30.43,39.94}, {30.45,37.33}, {31.28,42.48}, {31.46,37.66}, {31.57,78.96},
                    {31.62,50.87}, {32,57.85}, {32.19,67.87}, {33.05,72.97}, {33.09,63.76}, {33.49,66.51}, {33.77,39.97}, {34.97,87.61},
                    {35.16,51.63}, {35.51,58.21}, {36.42,65.85}, {36.75,53.81}, {36.93,81.03}, {37.01,62.7}, {37.94,84.14}, {39.41,51.74},
                    {39.55,56.8}, {39.6,79.22}, {40.96,59.66}, {41.4,49.65}, {41.42,83.24},
                },
                Tanaris = {
                    {21.5,78.35}, {22.31,79.28}, {23.77,80.3}, {26.13,84.09}, {29.71,85.61}, {38.97,29.37}, {39.6,28.96}, {48.32,86.59},
                    {49.16,92.04}, {53.7,98.15}, {56.45,93.39}, {60.09,86.87}, {64.28,62.48}, {64.57,59.43}, {65.73,58.59}, {65.95,37.78},
                    {66.45,20.13}, {66.71,29.59}, {66.74,26.48}, {67.21,35.04}, {67.84,40.76}, {70.84,42.04}, {71.5,44.13}, {71.63,46.15},
                    {72.11,49.7}, {73.25,44.63}, {73.55,49.15}, {90.53,45.17}, {90.97,62.83}, {91.05,54.7}, {91.13,40.48}, {91.25,58.11},
                    {91.31,49.26}, {92.55,44.26}, {92.86,70.11}, {93,48.48}, {93.64,63.72}, {93.71,56.28}, {93.74,36.5}, {93.92,39.02},
                    {94.22,51.8}, {95.38,68.61}, {95.44,47.11}, {95.55,64.74}, {95.84,51.17}, {96.03,59.7}, {96.11,55.61}, {97.38,33.52},
                    {97.48,40.43}, {97.67,51.67}, {97.87,48.57}, {97.92,44.52}, {98.96,35.33}, {99.21,59.7}, {99.32,53.78}, {99.38,42.17},
                    {99.63,63.98},
                },
                ["Un'Goro Crater"] = {
                    {19.85,59.41}, {22.52,58.59}, {24.82,50.49}, {27.23,42.78}, {27.87,61.92}, {29.85,68.12}, {30.2,32.41}, {30.77,22.27},
                    {32.14,38.81}, {33.31,74}, {34.04,32.77}, {34.23,21.42}, {36.28,54.05}, {36.74,50.45}, {37.47,46.51}, {37.82,41.36},
                    {39.68,76.07}, {39.74,29.45}, {40.58,61.51}, {40.87,50.57}, {41.82,19.64}, {42.9,74.08}, {43.2,57.3}, {43.25,37.47},
                    {44.12,89}, {44.33,45.3}, {47.9,63.54}, {48.31,42.14}, {50.6,17}, {50.74,82.47}, {51.14,30.3}, {55.04,20.65},
                    {55.06,41.53}, {55.58,70.68}, {55.85,56.69}, {58.77,27.05}, {58.85,48.86}, {58.93,35.93}, {59.28,82.19}, {59.85,68.89},
                    {60.44,77.69}, {61.47,21.14}, {64.33,53.85}, {64.36,39.34}, {66.66,46.03}, {67.63,75.86}, {67.74,70.39}, {68.6,40.55},
                    {68.95,26.81}, {70.28,49.72}, {70.55,58.27}, {72.14,69.74}, {72.77,34.64}, {74.98,47.93}, {75.09,57.62},
                },
                Westfall = {
                    {3.362,94.84},
                },
            },
        },
        {
            tier = "Star",
            treeNamePattern = "^Star Wood Tree",
            woodItem = { name = "Star Wood", itemId = 11291, icon = "Interface\\Icons\\star_log_2" },
            leafItem = { name = "Star Leaves", itemId = 42146, icon = "Interface\\Icons\\INV_Misc_Herb_12" },
            -- 270 -- was 30 (Star Wood's own item-level stat, which turned
            -- out not to track the actual chop skill gate any better than
            -- it did for the other tiers). Corrected 2026-08-16 from a
            -- TurtleCraft forum "Survival Tree Locations" leveling guide
            -- (forum.turtlecraft.gg, t=24572, via web.archive.org) -- see
            -- the note on Simple's level above for the full source.
            level = 270,
            pets = {
                { name = "Starsilk Moth", itemId = 37070, chance = 0.05 },
            },
            -- Re-verified 2026-08-15 against object #2020299's "Locations"
            -- list (the item page itself has no zone data) -- these 6 zones
            -- are where the dedicated "Star Wood Tree" object spawns (100%
            -- Star Wood). Star Wood ALSO drops at a 25% secondary rate off
            -- Dead Wood Tree, which spawns in the 14 zones listed under the
            -- "Dead" tier below -- deliberately not merged into this list,
            -- since those are two different choppable objects with their
            -- own tree-name patterns; the Dead tier's tooltip is where
            -- that secondary chance shows up.
            -- Also had an unresolved secondary cluster tagged "Kalimdor"
            -- (continent-level, 33 spawns) alongside the 6 confirmed
            -- zones -- same custom-zone-lookup caveat as Tropical Wood
            -- above. RESOLVED 2026-08-15: that's Moonwhisper Coast, a
            -- real custom Turtle WoW zone (Patch 1.18.1, Kalimdor,
            -- coastal Night Elf area) -- octowow.st doesn't recognize the
            -- zone ID so it fell back to the bare continent name, same
            -- pattern as Northwind/Balor/Grim Reaches/Gilneas/Blackstone
            -- Island/Thalassian Highlands above. Its map position below is
            -- next to Winterspring/Azshara, the top-right (northeast)
            -- corner of the Kalimdor map -- not a confirmed coordinate
            -- (approxLocation = true), but placed there per the map on
            -- turtle-wow.fandom.com/wiki/Kalimdor.
            -- RECONCILED 2026-08-16: the TurtleCraft forum "Survival Tree
            -- Locations" post's own zone list for this tier names Hyjal,
            -- not on file here at all (octowow.st's object data has no
            -- entry for it) -- added below with no spawn count, since
            -- there's no corroborating count data yet. That same forum
            -- list doesn't mention Darkshore or Ashenvale, which stay in
            -- the list regardless -- both are independently confirmed via
            -- octowow.st's own object data, and a leveling guide omitting a
            -- zone doesn't mean zero spawns there (see the
            -- RARE_ZONE_THRESHOLD note above woodTiers).
            chopZones = { "Winterspring", "Azshara", "Felwood", "Feralas", "Darkshore", "Ashenvale", "Moonwhisper Coast", "Hyjal" },
            -- Hyjal has no count data at all yet (forum-only zone).
            zoneCounts = {
                Winterspring = 231, Azshara = 72, Felwood = 28, Feralas = 4,
                Darkshore = 2, Ashenvale = 1, ["Moonwhisper Coast"] = 33,
            },
            -- Individual spawn-point "pips" for the Map tab, one {x,y} pair
            -- per known spawn (zone-local percent coordinates, 0-100,
            -- matching that zone's own client map -- same convention this
            -- file uses everywhere else for coords). PULLED 2026-08-17
            -- straight from octowow.st object #2020299's page source (the
            -- rendered page only shows the zoneCounts numbers above; the
            -- exact per-spawn coordinates are embedded in a
            -- myMapper.update({zone: <id>, coords: [[x,y,{...}], ...]})
            -- call in the page's own HTML, one call per zone, meant to feed
            -- its interactive map widget -- reading the raw HTML instead of
            -- the rendered/summarized page is what surfaced this). Point
            -- counts per zone match zoneCounts above exactly (231/72/28/4/2/1),
            -- which is what gave Ashenvale a real count for the first time --
            -- it wasn't "uncounted," its aggregate number just wasn't
            -- rendered on the summary line the way the others were.
            --
            -- Moonwhisper Coast's 33-point cluster is deliberately NOT
            -- included here. octowow.st doesn't recognize that zone (it's
            -- a custom Turtle WoW zone -- see the zones table note above),
            -- so its object page falls back to plotting those 33 points on
            -- the bare KALIMDOR CONTINENT map instead, in continent-relative
            -- percent coordinates -- a different coordinate space than the
            -- zone-local points below. See spawnPointsContinentRelative
            -- below for why this can't just be converted and dropped in.
            spawnPoints = {
                Winterspring = {
                    {14.4,72.66}, {15.6,69.56}, {16.46,74.8}, {16.58,73.08}, {17.03,69.77}, {21.09,67.68}, {23.3,84.05}, {24.22,86.29},
                    {24.72,82.17}, {25.06,71.52}, {25.41,66.85}, {25.93,87.73}, {27.5,70.78}, {27.99,87.79}, {28.91,48.32}, {29,45.18},
                    {29.81,37.3}, {29.88,64.82}, {30,66.28}, {30.5,76.23}, {30.54,35.42}, {30.58,81.03}, {32.33,74.8}, {33.1,36.56},
                    {33.31,90.51}, {33.36,40.06}, {33.5,76.7}, {33.91,82.97}, {34.09,88.46}, {34.54,74.75}, {34.99,45.01}, {35.55,77.71},
                    {35.92,36.41}, {36.99,81.98}, {37.19,85.32}, {37.34,91.02}, {37.38,39.49}, {37.78,86.54}, {37.82,35.25}, {37.96,80.23},
                    {38.53,83.46}, {38.6,81.75}, {39.72,84.18}, {40.13,88.17}, {40.15,44.25}, {40.57,82.93}, {40.65,80.75}, {40.75,37.99},
                    {42.24,42.22}, {42.51,63.05}, {42.61,82.21}, {42.74,88.65}, {42.89,73.11}, {42.95,83.94}, {43.15,36.94}, {44.72,87.05},
                    {44.89,43.08}, {45.95,33.28}, {46.1,81.09}, {46.12,38.01}, {46.19,45.96}, {47.08,36.64}, {48.26,80.33}, {48.71,43.76},
                    {48.79,18.68}, {49.16,5.606}, {49.2,14.99}, {49.48,8.88}, {49.5,37.97}, {49.72,47.46}, {50.23,80.99}, {50.57,20.23},
                    {50.79,42.2}, {50.81,11.39}, {51.22,46.21}, {52.03,25.23}, {52.51,32.01}, {53.41,12.11}, {53.75,42.01}, {54.08,48.62},
                    {54.1,36.62}, {54.43,14.48}, {55.13,18.41}, {55.47,30.62}, {55.67,39.51}, {56.15,48.7}, {56.23,16.15}, {56.6,46.27},
                    {56.71,44.88}, {56.89,39.32}, {56.91,53.12}, {57.33,55.78}, {57.58,20.63}, {57.58,34.65}, {57.69,14.46}, {58.15,99.94},
                    {58.17,67.95}, {58.19,12.11}, {58.38,50.29}, {59.06,42.05}, {59.15,48.11}, {59.4,17.18}, {59.58,69.98}, {59.72,62.5},
                    {59.75,58.23}, {59.79,28.25}, {59.82,53.61}, {59.91,65.14}, {60.62,20.23}, {60.72,32.52}, {60.72,42.83}, {61.38,14.77},
                    {61.69,51.62}, {61.78,55.68}, {62.16,47.14}, {62.82,26.71}, {62.92,22.76}, {62.96,17.84}, {63.43,62.58}, {63.51,16.3},
                    {63.88,30.56}, {63.88,66.54}, {63.96,74.27}, {64.48,60.28}, {64.6,20.2}, {64.88,24.39}, {65.15,64.25}, {65.6,40.23},
                    {65.85,50.33}, {65.99,68.92}, {66.15,48.09}, {66.23,60.87}, {66.36,70.65}, {66.51,27.94}, {66.55,32.99}, {66.68,35.65},
                    {67.3,21.68}, {67.86,42.83}, {68.23,53.75}, {68.41,37.3}, {68.62,50.14}, {69.27,3.218}, {71.79,67.32}, {73.6,70.89},
                    {73.92,6.261}, {74.19,1.951}, {74.4,62.96}, {74.46,39.87}, {74.67,34.08}, {75.24,50.56}, {75.47,70.08}, {75.74,66.09},
                    {75.89,7.211}, {76.71,59.77}, {77.05,32.92}, {77.12,3.408}, {77.27,10.04}, {77.53,34.7}, {77.65,26.84}, {77.69,61.89},
                    {77.84,45.68}, {78.02,0.2605}, {78.08,66.64}, {78.46,6.958}, {78.6,54.81}, {78.96,50.86}, {79.08,22.89}, {79.51,10.04},
                    {79.53,2.965}, {79.65,31.8}, {79.98,49.59}, {80.22,11.56}, {80.36,18.11}, {80.85,52.46}, {80.98,1.549}, {80.98,61.46},
                    {81.06,6.303}, {81.06,20.99}, {81.31,25.4}, {81.72,15.94}, {82.05,57.07}, {82.06,33.85}, {82.6,43.84}, {82.68,26.48},
                    {82.81,51.34}, {82.82,12.96}, {82.84,5.563}, {82.84,41.67}, {82.93,2.437}, {83.26,50.1}, {83.79,23.01}, {83.82,4.465},
                    {83.93,34.99}, {84.53,12.01}, {84.64,28.61}, {85.08,15.22}, {85.19,51.49}, {85.41,4.993}, {85.65,25.72}, {86.05,48.3},
                    {86.16,17.67}, {86.57,30.64}, {86.57,32.75}, {87.05,35.2}, {87.12,47.9}, {87.13,2.965}, {87.33,12.28}, {87.4,45.47},
                    {87.78,19.99}, {88.06,32.88}, {88.08,50.84}, {88.48,29.8}, {88.54,39.05}, {88.62,15.51}, {89.16,27.79}, {89.38,44.1},
                    {89.41,48.3}, {90.1,18.43}, {90.16,25.4}, {90.17,40.13}, {90.78,23.37}, {90.81,45.73}, {90.95,35.88}, {91.13,28.19},
                    {91.6,30.64}, {92.02,39.83}, {92.47,33.22}, {93.69,27.66}, {94.5,33.24}, {95.65,24.07}, {96.06,34.34},
                },
                Azshara = {
                    {13.21,82.24}, {17.51,67.33}, {18.26,60.09}, {18.46,53.11}, {18.48,78.84}, {21.81,58.1}, {23.49,77.89}, {24.57,58.34},
                    {25.52,82.27}, {26.42,79.13}, {27.71,54.94}, {30.13,59.85}, {31,81.44}, {31.22,47.16}, {32.2,55.24}, {32.26,44.97},
                    {33.74,64.49}, {34.19,77.27}, {34.35,56.39}, {35.18,38.82}, {35.87,83.45}, {36.76,49.5}, {38.04,42.1}, {38.45,70.26},
                    {38.53,21.46}, {39.79,59.88}, {40.17,65.74}, {40.25,84.49}, {40.48,77.65}, {41.08,46.19}, {41.33,25.69}, {41.88,41.93},
                    {42.08,34.86}, {43.21,19.57}, {43.54,64.52}, {43.9,82.65}, {43.94,75.38}, {45.87,84.93}, {47.51,24.24}, {48.27,30.96},
                    {49,16.02}, {49.38,85.64}, {50.48,83.18}, {50.96,24.36}, {51.47,19.92}, {53.24,32.67}, {53.68,90.7}, {53.74,73.96},
                    {55.24,82.39}, {56.14,25.1}, {56.62,30.3}, {57.39,19.24}, {58.27,78.51}, {59.12,87.3}, {59.61,30.27}, {59.71,82.56},
                    {61.47,90.1}, {62.55,15.66}, {62.75,87.56}, {63.36,25.48}, {64.86,79.99}, {66.14,17.88}, {68.27,25.6}, {71.01,12.71},
                    {74.31,30.16}, {74.66,35.3}, {79.28,25.34}, {79.39,17.88}, {80.97,28.35}, {81.56,15.31}, {82.98,19.72}, {85.15,22.47},
                },
                Felwood = {
                    {34.97,58.76}, {37.07,49.39}, {37.35,74.36}, {37.61,42.79}, {38.69,21.84}, {39.8,84.11}, {40.01,54.4}, {40.36,70.76},
                    {41.26,76.68}, {42.19,14.2}, {43.42,89.54}, {43.91,48.14}, {43.94,81.82}, {44.5,64.57}, {46.38,42.53}, {46.53,15.97},
                    {46.57,73.86}, {48.2,94.68}, {48.99,35.49}, {51.21,51.58}, {55.39,19.5}, {56.03,25.94}, {56.05,6.009}, {58.12,86.28},
                    {58.46,19.29}, {61.47,11.3}, {62.55,6.009}, {98.97,88.78},
                },
                Feralas = {
                    {27.95,71.4}, {28.4,76.97}, {29.69,85.24}, {31.52,84.96},
                },
                Darkshore = {
                    {47.78,85.24}, {48.91,86.27},
                },
                Ashenvale = {
                    {54.03,27.05},
                },
                -- ADDED 2026-08-18 -- Moonwhisper Coast's first REAL
                -- zone-local spawn points, gathered in-game via the
                -- separate Octo Node Scout addon's manual-log feature
                -- (GetPlayerMapPosition against the zone's own resolved
                -- map, SetMapToCurrentZone'd first -- genuinely the same
                -- coordinate space SC.ResolveZoneMapFile/RefreshMapPips
                -- render this zone at, unlike spawnPointsContinentRelative
                -- below). A small PARTIAL sample (10 distinct locations,
                -- deduplicated from 19 logged wood/leaf drops -- several
                -- were the same tree chopped twice, or the same tree
                -- logged from a slightly different standing position each
                -- time) -- not remotely a full census like the octowow.st
                -- data elsewhere in this file, just a real starting point.
                -- Keep appending here as more get logged; zoneCounts["Moonwhisper
                -- Coast"] = 33 above is a SEPARATE, unrelated figure (the
                -- octowow.st continent-relative scrape's own count) --
                -- don't conflate the two or overwrite one from the other.
                ["Moonwhisper Coast"] = {
                    {45.7,18.1}, {43.6,18.0}, {49.05,24.2}, {49.2,26.4}, {45.5,28.2},
                    {44.3,26.9}, {46.6,24.3}, {51.6,23.8}, {53.1,22.1}, {54.6,24.5},
                },
            },
            -- ADDED 2026-08-17 -- the 33-point Moonwhisper Coast cluster
            -- described above, now actually wired up. These are
            -- CONTINENT-relative percent coordinates (0-100 across the
            -- whole Kalimdor map), not zone-local like spawnPoints above --
            -- octowow.st's object page plots them on the bare continent
            -- map since it doesn't recognize this custom Turtle WoW zone,
            -- so that's the coordinate space they were authored in. Safe
            -- to attribute the whole cluster to Moonwhisper Coast
            -- specifically (not split across multiple custom zones)
            -- because it's the ONLY custom Kalimdor zone that carries
            -- Star Wood.
            --
            -- Moonwhisper Coast is unusual among the custom Turtle WoW
            -- zones in that it DOES resolve a real client map (see
            -- SC.UpdateMapView's forceZoomCrop-revert note in Map.lua), so
            -- it's shown there rather than on the zoomed-crop continent
            -- view these coordinates were originally authored for -- and
            -- RefreshMapPips (the real-map pip renderer) deliberately does
            -- NOT read this field, only tierData.spawnPoints. TRIED
            -- 2026-08-18: rescaling this cluster's bounding box into a
            -- synthetic zone-local space so it could plot on the real map
            -- anyway -- REVERTED SAME DAY once a screenshot showed
            -- Moonwhisper Coast's resolved map is actually a WIDE
            -- composite canvas that also shows Winterspring/Hyjal, not a
            -- tight crop of just the coast, so the stretched points landed
            -- all over Winterspring's unrelated landmass instead of
            -- clustering on the coast (see the note above RefreshMapPips
            -- in Map.lua). This field is genuinely orphaned right now --
            -- RefreshZoomCropPips would use it for a zone on the
            -- zoomed-crop view, but Moonwhisper Coast isn't one, and no
            -- other custom zone has continent-relative data on file.
            -- Fixing this for real needs zone-local coordinates gathered
            -- specifically against Moonwhisper Coast's actual resolved map
            -- (in-game or a source that maps to it), not a transform of
            -- this dataset.
            spawnPointsContinentRelative = {
                ["Moonwhisper Coast"] = {
                    {58.16,14.43}, {58.2,15.42}, {58.57,15.17}, {58.9,14.52}, {58.92,16.37}, {59.24,14.92}, {59.35,14.43}, {59.5,16.33},
                    {59.54,15.4}, {59.67,17.13}, {59.73,14.96}, {59.75,16.62}, {59.82,14.44}, {60,15.77}, {60.01,16.69}, {60.03,11.94},
                    {60.11,15.06}, {60.22,17.36}, {60.46,11.77}, {60.53,15.75}, {60.56,16.23}, {60.83,12.22}, {61,16.66}, {61.08,15.66},
                    {61.15,17.2}, {61.4,15.31}, {61.55,16.66}, {61.61,13.55}, {61.72,15.81}, {61.87,16.65}, {62.22,15.88}, {62.52,16.48},
                    {62.56,17.19},
                },
            },
        },
        {
            tier = "Dead",
            treeNamePattern = "^Dead Wood Tree",
            woodItem = nil, -- Dead Wood Tree has no dedicated wood item of its own -- see note above
            leafItem = { name = "Dead Leaves", itemId = 42148, icon = "Interface\\Icons\\INV_Misc_Herb_12" },
            -- 250 -- was 55 (an item-level guess -- Dead Wood Tree has no
            -- wood item of its own, so this had been read off Dead Leaves'
            -- item level instead). Corrected 2026-08-16 from a TurtleCraft
            -- forum "Survival Tree Locations" leveling guide
            -- (forum.turtlecraft.gg, t=24572, via web.archive.org) -- see
            -- the note on Simple's level above for the full source, which
            -- also explicitly calls Dead Wood "a worse version of Star Wood
            -- Trees, only do them if you are desperate before" reaching
            -- Star's own 270 gate -- consistent with Dead sitting just
            -- under Star here (250 vs 270).
            level = 250,
            pets = {
                { name = "Sludge Ooze", itemId = 37069, chance = 0.05 },
            },
            -- RE-VERIFIED 2026-08-16: unlike Simple/Bright/Shade (which
            -- are one distinct object ID per zone), Dead Wood Tree is a
            -- SINGLE object (#2020300) whose own Locations page lists
            -- every zone it spawns in directly -- re-fetched that page
            -- fresh and it matches this list and every count below
            -- exactly, with no "Azeroth"/"Kalimdor" continent-level
            -- fallback labels showing up anywhere in it. That matters
            -- because it rules out the boundary-spillover misattribution
            -- this file has documented elsewhere (see the note above
            -- woodTiers) -- Searing Gorge (5), Un'Goro Crater (5),
            -- Azshara (4), and Darkshore (2) below are this object's own
            -- genuine, if sparse, spawn counts, not a nearby zone's trees
            -- getting mis-bucketed here. Kept in chopZones/zoneCounts
            -- rather than removed -- see RARE_ZONE_THRESHOLD in Map.lua,
            -- which flags these as "(rare)" in the tooltip instead of
            -- deleting confirmed-correct data.
            -- RECONCILED 2026-08-16: the TurtleCraft forum "Survival Tree
            -- Locations" post's own zone list for this tier names Hyjal,
            -- not on file here (this object's own Locations page above has
            -- no entry for it either) -- added below with no spawn count.
            -- That same forum list also omits Winterspring, Un'Goro
            -- Crater, Darkshore, Ashenvale, and Feralas -- all 5 stay in
            -- the list regardless, since they're independently confirmed
            -- via this object's own re-verified Locations page above, and
            -- a leveling guide omitting a zone doesn't mean zero spawns
            -- (see RARE_ZONE_THRESHOLD note above woodTiers).
            chopZones = {
                "Felwood", "Eastern Plaguelands", "Silithus", "Western Plaguelands",
                "Burning Steppes", "Winterspring", "Blasted Lands", "Deadwind Pass",
                "Searing Gorge", "Un'Goro Crater", "Azshara", "Darkshore", "Ashenvale", "Feralas", "Hyjal",
            },
            -- Ashenvale and Feralas didn't render a count on the object's
            -- page at all (present, just uncounted) -- left out rather
            -- than guessed. Hyjal has no count data at all yet
            -- (forum-only zone).
            zoneCounts = {
                Felwood = 75, ["Eastern Plaguelands"] = 70, Silithus = 58,
                ["Western Plaguelands"] = 57, ["Burning Steppes"] = 38, Winterspring = 24,
                ["Blasted Lands"] = 24, ["Deadwind Pass"] = 16, ["Searing Gorge"] = 5,
                ["Un'Goro Crater"] = 5, Azshara = 4, Darkshore = 2,
            },
-- dropped as continent-catchall (different coord space): none
-- dropped as boundary-spillover (not in confirmed chopZones): none
-- confirmed real zones with NO spawn-point data found: Hyjal
            spawnPoints = {
                Ashenvale = {
                    {54.28,25.96},
                },
                Azshara = {
                    {67.11,88.48}, {70.09,79.1}, {70.32,91.44}, {72.94,86.73},
                },
                ["Blasted Lands"] = {
                    {39.08,35.7}, {40.55,30.06}, {43.14,43.04}, {43.26,29.39}, {44.04,18.82}, {47.83,36.91}, {48.07,46.13}, {48.58,16.18},
                    {49.05,42.01}, {49.65,55.09}, {52.22,48.01}, {53.83,42.1}, {54.37,37.22}, {54.82,52.27}, {56.01,33.06}, {57.95,29.92},
                    {58.97,44.92}, {59.62,36.69}, {59.77,49.58}, {63.14,28.63}, {63.89,43.63}, {64.1,55.81}, {64.7,48.01}, {65.71,33.37},
                },
                ["Burning Steppes"] = {
                    {11.89,31.03}, {16.57,58.85}, {21.42,45.68}, {25.14,56.39}, {31.69,68.63}, {31.8,56.75}, {32.51,48.6}, {34.39,67.45},
                    {37.56,44.81}, {40.43,59.51}, {41.46,36.41}, {45.31,45.73}, {46.17,57.52}, {48.9,38.36}, {49.85,25.34}, {51.56,65.92},
                    {53.44,58.34}, {54.81,37.13}, {58.25,23.76}, {59.21,39.43}, {62.42,60.9}, {66.17,51.88}, {67.06,41.99}, {68.77,34.16},
                    {70.3,53.26}, {70.99,46.5}, {73.14,60.74}, {75.46,31.49}, {77.92,55.67}, {81.71,48.14}, {82.08,37.23}, {82.46,59.92},
                    {84.2,26.68}, {87.1,38.2}, {90.92,47.88}, {91.74,56.18}, {92.32,65.81}, {97.45,52.14},
                },
                Darkshore = {
                    {47.8,86.69}, {49.19,86.25},
                },
                ["Deadwind Pass"] = {
                    {34.95,40.7}, {37.95,31.46}, {40.55,72.8}, {41.91,58.34}, {42.07,41.42}, {42.39,26.9}, {43.55,78.74}, {45.07,66.86},
                    {48.23,24.74}, {48.51,52.04}, {50.03,78.02}, {51.71,39.44}, {51.71,55.94}, {53.07,69.62}, {56.79,65.42}, {58.43,76.58},
                },
                ["Eastern Plaguelands"] = {
                    {11.95,39.55}, {13.6,33.08}, {13.68,43.51}, {16.78,28.94}, {19.11,24.6}, {21.12,61.71}, {23.09,65.39}, {23.47,75.31},
                    {24.38,39.59}, {25.64,18.17}, {27.35,88.29}, {29.78,82.83}, {30.42,76.4}, {31.48,41.22}, {32.05,65.82}, {33.08,35.18},
                    {35.2,66.91}, {36.29,39.32}, {36.73,52.3}, {36.93,77.09}, {38.4,69.77}, {39.41,19.06}, {43.05,85.54}, {43.08,70.82},
                    {43.36,39.94}, {43.93,92.2}, {44.5,66.29}, {46.34,81.86}, {48.4,57.76}, {49.36,30.26}, {50.13,66.29}, {51.43,42.62},
                    {51.63,36.49}, {52.46,52.18}, {53.67,79.23}, {53.88,59.89}, {54.34,15.5}, {56.36,29.44}, {56.62,51.91}, {56.75,63.73},
                    {56.95,19.02}, {58.43,85.97}, {59.54,72.17}, {59.72,66.44}, {61.11,73.34}, {63.21,30.8}, {63.41,41.57}, {63.57,63.34},
                    {64.24,21.58}, {64.37,86.47}, {64.68,45.95}, {66.2,36.53}, {66.59,79.5}, {67.13,56.21}, {68.19,65.43}, {68.22,73.14},
                    {69.17,27.51}, {69.38,82.29}, {69.56,37.19}, {69.82,42.73}, {71.06,48.66}, {72.48,32.19}, {74.13,73.07}, {74.57,82.83},
                    {75.32,49.51}, {75.48,65.36}, {75.79,54}, {75.84,35.91}, {78.71,59.7}, {82.22,37.89},
                },
                Felwood = {
                    {34.76,61.1}, {35.66,58.68}, {37.16,65.7}, {37.46,61.68}, {37.99,71.57}, {38.36,57.17}, {38.36,83.93}, {38.45,52.7},
                    {38.62,46.91}, {38.85,30.66}, {39.12,22.6}, {39.3,67.97}, {39.33,71.49}, {39.91,65.46}, {39.94,49.91}, {40.34,59.36},
                    {40.92,43.05}, {41.04,71.98}, {41.3,74.07}, {41.4,67.97}, {41.54,26.93}, {41.58,85.26}, {41.79,80.04}, {41.92,17.23},
                    {41.98,82.21}, {42.22,58.26}, {42.38,32.1}, {42.46,76.37}, {42.64,40.91}, {42.93,37.86}, {42.99,19.29}, {43.28,63.87},
                    {43.72,14.46}, {43.82,84.77}, {43.94,47.17}, {44.36,78.92}, {44.74,19}, {44.76,90.45}, {45.02,75.37}, {45.26,40.5},
                    {45.49,84.11}, {46.43,72.87}, {46.52,23.04}, {46.72,92.62}, {47.07,88.86}, {47.28,85.34}, {47.54,75.4}, {48.59,86.17},
                    {48.74,75.56}, {48.95,28.94}, {48.95,36.95}, {49.02,93.27}, {49.09,89.9}, {49.18,80.64}, {50.17,20.1}, {50.57,16.1},
                    {50.64,24.63}, {50.78,85.6}, {51.23,31.57}, {51.47,28.6}, {51.89,12.06}, {53.73,22.42}, {54.59,83.77}, {55.21,15.69},
                    {55.73,8.278}, {56.26,88.1}, {56.57,5.487}, {57.66,13.29}, {58.6,86.88}, {59.77,6.739}, {61.07,10.21}, {62.29,13.86},
                    {62.66,18.3}, {63.44,10.91}, {63.98,7.104},
                },
                Feralas = {
                    {54.73,82.54},
                },
                ["Searing Gorge"] = {
                    {27.25,81.88}, {28.06,24.34}, {58.36,82.02}, {72.34,12.24}, {72.34,79.8},
                },
                Silithus = {
                    {16.61,86.39}, {17.3,28.91}, {20,37.01}, {20.43,10.4}, {21.89,28.05}, {22.18,79.93}, {22.69,18.63}, {22.81,41.79},
                    {24.3,86.26}, {25.82,81.78}, {25.91,74.63}, {27.14,39.98}, {30.56,76.74}, {30.9,20.95}, {32.25,40.71}, {33.11,64.13},
                    {34.15,30.21}, {34.55,20.35}, {34.58,88.93}, {34.78,50.18}, {35.81,76.79}, {38.08,71.06}, {38.22,58.19}, {38.28,16.56},
                    {39.86,40.37}, {40.23,24.95}, {40.72,49.28}, {41.81,36.97}, {44.02,79.67}, {44.2,93.19}, {44.43,86.64}, {47.96,64.09},
                    {48.42,17.25}, {48.79,83.03}, {49.11,69.47}, {49.88,50.74}, {50.6,29.99}, {51.95,89.53}, {52.32,56.9}, {53.04,30.59},
                    {53.33,21.04}, {55.16,10.83}, {55.28,16.34}, {55.94,38.95}, {56.86,46.52}, {57,24.44}, {59.67,54.87}, {59.81,58.83},
                    {60.76,19.1}, {61.16,12.43}, {61.45,29.35}, {62.28,40.41}, {63.32,49.71}, {64.03,72.7}, {64.41,54.74}, {64.89,62.49},
                    {67.05,80.57}, {68.51,18.93},
                },
                ["Un'Goro Crater"] = {
                    {8.739,46.64}, {10.01,39.74}, {13.58,33.09}, {14.09,27.3}, {20.2,14.45},
                },
                ["Western Plaguelands"] = {
                    {30.29,61.24}, {32.22,55.63}, {34.22,66.37}, {34.71,76}, {35.76,55.31}, {36.69,80.26}, {37.11,63.37}, {40.13,50.5},
                    {40.25,67.35}, {40.39,54.34}, {40.62,82.24}, {41.02,74.57}, {42.76,47.92}, {43.88,35.85}, {44.34,56.53}, {44.78,65.53},
                    {45.22,71.81}, {45.6,49.1}, {45.62,60.58}, {47.09,68.95}, {47.13,31.77}, {47.36,65.26}, {47.48,58.87}, {47.55,35.53},
                    {48.71,82.84}, {48.78,39.86}, {49.2,55.42}, {49.43,28.66}, {49.46,76}, {49.5,46.63}, {51.04,24.27}, {51.57,52.21},
                    {51.57,68.26}, {53.5,21.86}, {53.95,64.73}, {54.11,78.86}, {54.27,39.48}, {54.32,45.83}, {55.99,54.41}, {56.29,66.62},
                    {57.74,35.81}, {59.43,60.27}, {59.55,51.93}, {61.36,52.49}, {63.06,47.5}, {63.2,61.03}, {65.02,50.6}, {65.5,38.5},
                    {65.88,25.21}, {66.83,55.38}, {68.09,46.03}, {68.41,51.83}, {70.06,37.7}, {70.95,27.72}, {71.92,31.14}, {73.74,31.59},
                    {73.83,42.97},
                },
                Winterspring = {
                    {19.91,75.47}, {20.23,70.13}, {20.46,73.36}, {22.02,74.5}, {22.13,76.8}, {24,73.68}, {28.68,87.54}, {29.91,82.76},
                    {30.19,88.8}, {30.61,83.48}, {31.72,66.41}, {32.48,82.95}, {32.5,67.89}, {32.95,61.42}, {34.65,70.23}, {34.99,60.64},
                    {37.92,67.17}, {38.02,61.95}, {38.43,59.06}, {38.81,70.68}, {39.51,61.02}, {40.77,65.92}, {41.96,57.94}, {42.47,60.51},
                },
            },
        },
    },

    -- Generic fallback for any tree name that doesn't match a tier
    -- pattern above (e.g. detection couldn't identify a target and fell
    -- back to "Unidentified Tree").
    defaultTreeIcon = "Interface\\Icons\\INV_Misc_Log_02",

    -- Map tab data ---------------------------------------------------
    -- Which zones carry which wood tier(s), for the Map tab's hover
    -- tooltips. tiers entries match the `tier` field in woodTiers above,
    -- and list EVERY zone that tier's tree can be chopped in (not just an
    -- example subset), derived from the same db.capycraft.org "found in"
    -- object lists as woodTiers, checked 2026-08-15.
    --
    -- x/y are approximate percentage positions (0-100) on that
    -- continent's map image, for placing a hover hotspot -- these are
    -- illustrative placements based on general zone geography, NOT
    -- pixel-measured against the actual 1.18.1 client map, so expect to
    -- nudge them once you can compare in game.
    --
    -- approxLocation = true marks custom Turtle WoW zones (not part of
    -- vanilla WoW) whose position here is inferred from written
    -- descriptions of what they're next to, rather than any map at all --
    -- treat those coordinates as rougher still.
    --
    -- RESEARCHED 2026-08-17: checked every other map-related addon
    -- installed alongside this one (pfQuest + pfQuest-turtle, ShaguTweaks,
    -- pfUI, MapNotes, ModernMapMarkers, MovementTracker) for better
    -- placement data on the 7 approxLocation zones below. None of them
    -- have real per-zone map art or a continent-relative x/y for these
    -- zones either -- pfQuest's own map code (pfQuest/map.lua
    -- pfMap:SetMapByID) depends on the exact same GetMapZones()/
    -- SetMapZoom() client calls this file's SC.ResolveZoneMapFile does,
    -- and just silently stops drawing pins when a zone isn't found, no
    -- fallback at all -- so this addon's zoomed-crop fallback is already
    -- ahead of the pack, not behind it. What that pass DID confirm: all 7
    -- of these zones have real, client-recognized numeric area ids (from
    -- Turtle WoW's own AreaTable.dbc, per pfQuest-turtle's zones-turtle.lua
    -- and its enUS locale file) -- they're genuine zones, not made up --
    -- recorded below as areaId for anyone cross-referencing against
    -- pfQuest/other tools later. Moonwhisper Coast's areaId (5642) comes
    -- from a "Turtle WoW 1.18.x additions" block in that same source,
    -- confirming it's a real, if newer/sparser-documented, zone too.
    zones = {
        -- Kalimdor
        { name = "Teldrassil", continent = "Kalimdor", x = 15, y = 8, tiers = { "Simple" } },
        { name = "Darkshore", continent = "Kalimdor", x = 18, y = 20, tiers = { "Simple", "Star", "Dead" } },
        { name = "Ashenvale", continent = "Kalimdor", x = 25, y = 32, tiers = { "Bright", "Star", "Dead" } },
        { name = "Stonetalon Mountains", continent = "Kalimdor", x = 22, y = 45, tiers = { "Bright" } },
        { name = "Desolace", continent = "Kalimdor", x = 28, y = 55, tiers = { "Shade" } },
        { name = "Feralas", continent = "Kalimdor", x = 20, y = 68, tiers = { "Star", "Dead", "Shade" } },
        { name = "Thousand Needles", continent = "Kalimdor", x = 38, y = 62, tiers = { "Bright" } },
        { name = "Tanaris", continent = "Kalimdor", x = 45, y = 80, tiers = { "Tropical" } },
        { name = "Silithus", continent = "Kalimdor", x = 42, y = 88, tiers = { "Dead" } },
        { name = "Un'Goro Crater", continent = "Kalimdor", x = 48, y = 72, tiers = { "Tropical", "Dead" } },
        { name = "Winterspring", continent = "Kalimdor", x = 55, y = 15, tiers = { "Star", "Dead" } },
        { name = "Azshara", continent = "Kalimdor", x = 62, y = 22, tiers = { "Star", "Dead" } },
        -- Custom Turtle WoW zone (Patch 1.18.1) -- coastal Night Elf area.
        -- CORRECTED 2026-08-15: originally placed near Teldrassil/Darkshore
        -- (northwest) as a guess from its description alone -- you flagged
        -- it actually sits in the top-right (northeast) segment of the
        -- Kalimdor map per the turtle-wow.fandom.com/wiki/Kalimdor map, so
        -- moved out here next to Winterspring/Azshara instead. Still an
        -- approximate placement, not a measured coordinate.
        { name = "Moonwhisper Coast", continent = "Kalimdor", x = 65, y = 8, tiers = { "Star" }, approxLocation = true, areaId = 5642 },
        { name = "Felwood", continent = "Kalimdor", x = 48, y = 30, tiers = { "Star", "Dead" } },
        -- Added 2026-08-16 during zone-list reconciliation (see the
        -- RECONCILED notes on the Star/Dead tiers above) -- octowow.st has
        -- no object data for this zone at all, so this position is a rough
        -- guess (roughly between Winterspring and Felwood, consistent with
        -- where Hyjal sits on other Turtle WoW zone maps), not a measured
        -- coordinate. Nudge once you can compare in game.
        { name = "Hyjal", continent = "Kalimdor", x = 52, y = 22, tiers = { "Star", "Dead" }, approxLocation = true },
        -- Added 2026-08-16 during zone-list reconciliation (see the
        -- RECONCILED note on the Tropical tier above) -- position is a
        -- rough guess, placed in the ocean off the Tanaris coast per the
        -- same thematic/geographic reasoning that first suggested this
        -- zone name, not a measured coordinate.
        -- areaId 5121 ("Tel'Abim") added 2026-08-17, same source and
        -- reasoning as the 7 custom zones' areaId note above (pfQuest-
        -- turtle's zones-turtle.lua + its enUS locale file) -- Tel'abim
        -- itself isn't one of those 7 (it DOES have a real client map,
        -- unlike them), but the areaId is still passed to
        -- C_Map.GetMapOverlays(areaId) explicitly so the "revealed map"
        -- feature resolves its real overlay data even if the map texture
        -- turns out to be a borrowed/reused one, same reasoning as
        -- Blackstone Island.
        { name = "Tel'abim", continent = "Kalimdor", x = 52, y = 85, tiers = { "Tropical" }, approxLocation = true, areaId = 5121 },
        { name = "Durotar", continent = "Kalimdor", x = 68, y = 42, tiers = { "Simple" } },
        { name = "The Barrens", continent = "Kalimdor", x = 52, y = 48, tiers = { "Simple" } },
        { name = "Mulgore", continent = "Kalimdor", x = 42, y = 50, tiers = { "Simple" } },
        { name = "Blackstone Island", continent = "Kalimdor", x = 75, y = 38, tiers = { "Simple" }, approxLocation = true, areaId = 5536 },
        { name = "Dustwallow Marsh", continent = "Kalimdor", x = 58, y = 58, tiers = { "Shade" }, approxLocation = true },

        -- Eastern Kingdoms
        { name = "Tirisfal Glades", continent = "EasternKingdoms", x = 30, y = 8, tiers = { "Simple" } },
        { name = "Silverpine Forest", continent = "EasternKingdoms", x = 25, y = 18, tiers = { "Simple" } },
        { name = "Western Plaguelands", continent = "EasternKingdoms", x = 42, y = 12, tiers = { "Dead" } },
        { name = "Eastern Plaguelands", continent = "EasternKingdoms", x = 55, y = 10, tiers = { "Dead" } },
        { name = "Hillsbrad Foothills", continent = "EasternKingdoms", x = 32, y = 28, tiers = { "Bright" } },
        { name = "Alterac Mountains", continent = "EasternKingdoms", x = 40, y = 22, tiers = { "Shade" } },
        { name = "Arathi Highlands", continent = "EasternKingdoms", x = 48, y = 28, tiers = { "Shade" } },
        { name = "Hinterlands", continent = "EasternKingdoms", x = 52, y = 20, tiers = { "Shade" }, approxLocation = true },
        { name = "Dun Morogh", continent = "EasternKingdoms", x = 25, y = 42, tiers = { "Simple" } },
        { name = "Loch Modan", continent = "EasternKingdoms", x = 35, y = 42, tiers = { "Simple" } },
        { name = "Wetlands", continent = "EasternKingdoms", x = 38, y = 32, tiers = { "Simple" } },
        { name = "Searing Gorge", continent = "EasternKingdoms", x = 45, y = 45, tiers = { "Dead" } },
        { name = "Burning Steppes", continent = "EasternKingdoms", x = 48, y = 52, tiers = { "Dead" } },
        { name = "Badlands", continent = "EasternKingdoms", x = 44, y = 58, tiers = { "Shade" }, approxLocation = true },
        { name = "Blasted Lands", continent = "EasternKingdoms", x = 48, y = 68, tiers = { "Dead" } },
        { name = "Swamp of Sorrows", continent = "EasternKingdoms", x = 44, y = 64, tiers = { "Shade" }, approxLocation = true },
        { name = "Deadwind Pass", continent = "EasternKingdoms", x = 38, y = 58, tiers = { "Dead" } },
        { name = "Duskwood", continent = "EasternKingdoms", x = 32, y = 58, tiers = { "Simple" } },
        { name = "Elwynn Forest", continent = "EasternKingdoms", x = 28, y = 52, tiers = { "Simple" } },
        { name = "Westfall", continent = "EasternKingdoms", x = 18, y = 55, tiers = { "Simple", "Tropical" } },
        { name = "Redridge Mountains", continent = "EasternKingdoms", x = 35, y = 52, tiers = { "Simple" } },
        { name = "Stranglethorn Vale", continent = "EasternKingdoms", x = 30, y = 78, tiers = { "Shade", "Tropical" } },
        { name = "Northwind", continent = "EasternKingdoms", x = 27, y = 45, tiers = { "Bright" }, approxLocation = true, areaId = 5581 },
        { name = "Balor", continent = "EasternKingdoms", x = 8, y = 52, tiers = { "Bright" }, approxLocation = true, areaId = 5561 },
        -- Nudged 2026-08-15: cross-referenced against a description of the
        -- zone (Dun Kintas, its main settlement, sits "nearly due east of
        -- Loch Modan, separated only by mountains") -- moved east and
        -- down slightly to sit level with Loch Modan (x=35,y=42) rather
        -- than Wetlands (x=38,y=32), while staying east of both. Still
        -- approximate, not a measured coordinate.
        { name = "Grim Reaches", continent = "EasternKingdoms", x = 46, y = 39, tiers = { "Shade" }, approxLocation = true, areaId = 5602 },
        { name = "Thalassian Highlands", continent = "EasternKingdoms", x = 60, y = 8, tiers = { "Simple" }, approxLocation = true, areaId = 5225 },
        { name = "Gilneas", continent = "EasternKingdoms", x = 15, y = 15, tiers = { "Shade" }, approxLocation = true, areaId = 5179 },
        -- Added 2026-08-16 during zone-list reconciliation (see the
        -- RECONCILED note on the Tropical tier above) -- no octowow.st
        -- object data exists for either of these two custom island zones
        -- at all, so these positions are rough guesses only (placed in the
        -- ocean southeast of Stranglethorn Vale, near Booty Bay, based on
        -- general familiarity with where Turtle WoW's custom island zones
        -- tend to sit) -- not measured coordinates, treat as placeholder
        -- until spot-checked in game.
        { name = "Lapidis Isle", continent = "EasternKingdoms", x = 33, y = 85, tiers = { "Tropical" }, approxLocation = true },
        { name = "Gillijim's Isle", continent = "EasternKingdoms", x = 36, y = 88, tiers = { "Tropical" }, approxLocation = true },
    },
}
