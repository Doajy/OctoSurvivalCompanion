--[[
Octo Survival Companion - Core.lua
Saved variables, initialization, tree-chop tracking, and slash commands.
Targets the vanilla 1.12.1 API used by Turtle WoW / OctoWoW / CapyCraft / TurtleCraft clients.
]]

OctoSurvivalCompanion = OctoSurvivalCompanion or {}
local SC = OctoSurvivalCompanion

-- Item names that count as "wood" for chop detection, one per wood tier.
-- Confirmed against CapyCraft's item database (db.capycraft.org) on
-- 2026-08-15 -- see the woodTiers catalog in Data.lua for the full
-- breakdown (item IDs, icons, matching leaf item, example zones).
SC.WOOD_ITEM_NAMES = {
    ["Simple Wood"] = true,
    ["Bright Wood"] = true,
    ["Shade Wood"] = true,
    ["Tropical Wood"] = true,
    ["Star Wood"] = true, -- 100% from Star Wood Tree; also a ~25% bonus drop off Dead Wood Tree
}

-- Item names that count as "leaves" from the same tree -- these credit
-- the corresponding tree's count too, they just get tracked separately
-- under the hood (wood vs. leaf) in case that breakdown is useful later.
-- Also confirmed against db.capycraft.org on 2026-08-15.
SC.LEAF_ITEM_NAMES = {
    ["Simple Leaves"] = true,
    ["Bright Leaves"] = true,
    ["Shade Leaves"] = true,
    ["Tropical Leaves"] = true,
    ["Star Leaves"] = true,
    ["Dead Leaves"] = true,
}

local function SC_Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff5bc0ffOcto Survival Companion|r: " .. msg)
end
SC.Print = SC_Print

local function SC_InitDB()
    if not OctoSurvivalCompanionDB then
        OctoSurvivalCompanionDB = {}
    end
    if not OctoSurvivalCompanionDB.known then
        OctoSurvivalCompanionDB.known = {}
    end
    if not OctoSurvivalCompanionDB.treesChopped then
        OctoSurvivalCompanionDB.treesChopped = {} -- [treeName] = combined wood+leaf count
    end
    if not OctoSurvivalCompanionDB.treeOrder then
        OctoSurvivalCompanionDB.treeOrder = {} -- treeName list, in first-seen order (keeps icon layout stable)
    end
    if not OctoSurvivalCompanionDB.treeDetail then
        OctoSurvivalCompanionDB.treeDetail = {} -- [treeName] = { wood = n, leaf = n }
    end
    if not OctoSurvivalCompanionDB.knownPets then
        OctoSurvivalCompanionDB.knownPets = {} -- [petName] = true once you've learned that companion
    end

    -- First-run welcome/setup screen and its options. setupComplete stays
    -- false until the player saves it once (or dismisses it), at which
    -- point SC.ShowWelcome() won't auto-pop again -- /scw setup reopens it
    -- any time to change these.
    if OctoSurvivalCompanionDB.setupComplete == nil then
        OctoSurvivalCompanionDB.setupComplete = false
    end
    if OctoSurvivalCompanionDB.faction == nil then
        OctoSurvivalCompanionDB.faction = nil -- set from UnitFactionGroup("player") or manually in the welcome screen
    end
    if OctoSurvivalCompanionDB.hidePetNames == nil then
        OctoSurvivalCompanionDB.hidePetNames = true -- show ???? for companion pets you haven't found yet
    end
    if OctoSurvivalCompanionDB.showTreeBar == nil then
        OctoSurvivalCompanionDB.showTreeBar = true
    end
    if OctoSurvivalCompanionDB.announceNewTree == nil then
        OctoSurvivalCompanionDB.announceNewTree = true -- chat message when a new tree type is first recorded
    end
    if OctoSurvivalCompanionDB.useTomTom == nil then
        OctoSurvivalCompanionDB.useTomTom = true -- best-effort TomTom waypoint on tree-icon click, see UI.lua
    end

    -- Minimap button position (angle in degrees around the minimap's rim)
    -- and visibility -- see SC.CreateMinimapButton in UI.lua.
    if OctoSurvivalCompanionDB.minimapAngle == nil then
        OctoSurvivalCompanionDB.minimapAngle = 200
    end
    if OctoSurvivalCompanionDB.minimapHidden == nil then
        OctoSurvivalCompanionDB.minimapHidden = false
    end
end
-- Exposed on the shared SC table since "local function" declarations
-- don't cross file/chunk boundaries in Lua -- UI.lua needs to call this
-- too (welcome screen, minimap button), and a bare SC_InitDB() from
-- another file would just error as a nil global.
SC.InitDB = SC_InitDB

-- ============================================================
-- Known recipe checklist
-- ============================================================

function SC_ToggleKnown(recipeName)
    SC_InitDB()
    if OctoSurvivalCompanionDB.known[recipeName] then
        OctoSurvivalCompanionDB.known[recipeName] = nil
    else
        OctoSurvivalCompanionDB.known[recipeName] = true
    end
    if SC.RefreshUI then
        SC.RefreshUI()
    end
end
SC.ToggleKnown = SC_ToggleKnown

function SC_IsKnown(recipeName)
    return OctoSurvivalCompanionDB and OctoSurvivalCompanionDB.known and OctoSurvivalCompanionDB.known[recipeName]
end
SC.IsKnown = SC_IsKnown

-- ============================================================
-- Tree-chop tracker
--
-- Records how many *different* trees you've chopped, and how many times
-- each -- wood and leaves both count toward the same tree's total, since
-- both come off the same node. This only tracks tree names it has actually
-- seen you gather from -- there is no pre-made master list, since the
-- exact set of tree node names in your world isn't something this addon
-- can know in advance.
--
-- Detection is best-effort for now (see the CHAT_MSG_LOOT handler below)
-- and the hover tooltip content is a placeholder -- both are meant to be
-- tuned once we've confirmed exactly how chopping fires in game. Until
-- then, "/scw chop <tree name>" and "/scw leaf <tree name>" let you add
-- entries manually to test the bar.
-- ============================================================

-- kind is "wood" or "leaf" (defaults to "wood"); it only affects the
-- wood/leaf breakdown kept per tree, the combined total always goes up.
function SC.RegisterChop(treeName, kind)
    if not treeName or treeName == "" then
        return
    end
    if kind ~= "leaf" then
        kind = "wood"
    end
    SC_InitDB()
    if not OctoSurvivalCompanionDB.treesChopped[treeName] then
        OctoSurvivalCompanionDB.treesChopped[treeName] = 0
        OctoSurvivalCompanionDB.treeDetail[treeName] = { wood = 0, leaf = 0 }
        table.insert(OctoSurvivalCompanionDB.treeOrder, treeName)
        if OctoSurvivalCompanionDB.announceNewTree then
            SC_Print("New tree discovered: " .. treeName)
        end
    end
    if not OctoSurvivalCompanionDB.treeDetail[treeName] then
        OctoSurvivalCompanionDB.treeDetail[treeName] = { wood = 0, leaf = 0 }
    end
    OctoSurvivalCompanionDB.treesChopped[treeName] = OctoSurvivalCompanionDB.treesChopped[treeName] + 1
    OctoSurvivalCompanionDB.treeDetail[treeName][kind] = OctoSurvivalCompanionDB.treeDetail[treeName][kind] + 1
    if SC.RefreshTreeBar then
        SC.RefreshTreeBar()
    end
    if SC.RefreshLogbookPanel then
        SC.RefreshLogbookPanel()
    end
end

function SC.GetTreeOrder()
    SC_InitDB()
    return OctoSurvivalCompanionDB.treeOrder
end

-- Combined wood + leaf count for this tree.
function SC.GetTreeCount(treeName)
    SC_InitDB()
    return OctoSurvivalCompanionDB.treesChopped[treeName] or 0
end

-- Total successful chops across every tree, not just the count of unique
-- tree types -- every wood or leaf gather anywhere adds to this.
function SC.GetTotalChops()
    SC_InitDB()
    local total = 0
    local name, count
    for name, count in pairs(OctoSurvivalCompanionDB.treesChopped) do
        total = total + count
    end
    return total
end

function SC.GetTreeWoodCount(treeName)
    SC_InitDB()
    local detail = OctoSurvivalCompanionDB.treeDetail[treeName]
    return detail and detail.wood or 0
end

function SC.GetTreeLeafCount(treeName)
    SC_InitDB()
    local detail = OctoSurvivalCompanionDB.treeDetail[treeName]
    return detail and detail.leaf or 0
end

-- Matches a tree name (e.g. "Simple Wood Tree (Teldrassil)") against the
-- confirmed woodTiers catalog in Data.lua and returns that tier's table
-- (tier, woodItem, leafItem, level, chopZones), or nil if it doesn't
-- match any known tier -- e.g. a manually-tested name or a genuinely new
-- one we haven't seen yet.
function SC.GetTierForTree(treeName)
    if not treeName or not OctoSurvivalCompanion_Data or not OctoSurvivalCompanion_Data.woodTiers then
        return nil
    end
    local i
    for i = 1, table.getn(OctoSurvivalCompanion_Data.woodTiers) do
        local tier = OctoSurvivalCompanion_Data.woodTiers[i]
        if tier.treeNamePattern and string.find(treeName, tier.treeNamePattern) then
            return tier
        end
    end
    return nil
end

-- Combined wood+leaf chop count across every distinct tracked tree name
-- that matches this tier (e.g. "Star") -- a tier can cover more than one
-- treesChopped key if the game's own mob/object name includes a zone
-- qualifier (see the note above SC.GetTierForTree), so this can't just
-- read a single treesChopped entry directly.
function SC.GetTierChopCount(tierKey)
    SC_InitDB()
    local total = 0
    local name, count
    for name, count in pairs(OctoSurvivalCompanionDB.treesChopped) do
        local tier = SC.GetTierForTree(name)
        if tier and tier.tier == tierKey then
            total = total + count
        end
    end
    return total
end

function SC.ResetTrees()
    SC_InitDB()
    OctoSurvivalCompanionDB.treesChopped = {}
    OctoSurvivalCompanionDB.treeOrder = {}
    OctoSurvivalCompanionDB.treeDetail = {}
    if SC.RefreshTreeBar then
        SC.RefreshTreeBar()
    end
end

-- ============================================================
-- Tree-chop companion pets
--
-- Each wood tier has a ~0.05%-per-chop chance at a companion pet item (see
-- woodTiers[i].pets in Data.lua) -- confirmed 2026-08-15 via
-- db.capycraft.org. This addon can't peek at your actual pet/companion
-- collection (there's no documented API for it on a vanilla 1.12.1
-- client), so "known" here just means "this addon has seen evidence you
-- have it" -- either the CHAT_MSG_SYSTEM sniff below caught you learning
-- it, or you told it manually with /scw pet <name>. Until one of those
-- happens, the tooltip shows "????" for that pet instead of spoiling the
-- name, same idea as a collection addon hiding un-earned achievements.
-- ============================================================

-- Built once at load time from every tier's pets list in Data.lua, so the
-- CHAT_MSG_SYSTEM sniff below has a name to match against without having
-- to walk the whole woodTiers table on every single system message.
SC.PET_NAMES = {}
local function SC_BuildPetNameIndex()
    SC.PET_NAMES = {}
    if not OctoSurvivalCompanion_Data or not OctoSurvivalCompanion_Data.woodTiers then
        return
    end
    local i, j
    for i = 1, table.getn(OctoSurvivalCompanion_Data.woodTiers) do
        local tier = OctoSurvivalCompanion_Data.woodTiers[i]
        if tier.pets then
            for j = 1, table.getn(tier.pets) do
                SC.PET_NAMES[tier.pets[j].name] = true
            end
        end
    end
end

function SC.IsPetKnown(petName)
    if not petName then
        return false
    end
    SC_InitDB()
    return OctoSurvivalCompanionDB.knownPets[petName] == true
end

function SC.MarkPetKnown(petName, silent)
    if not petName or petName == "" then
        return
    end
    SC_InitDB()
    local alreadyKnew = OctoSurvivalCompanionDB.knownPets[petName]
    OctoSurvivalCompanionDB.knownPets[petName] = true
    if not alreadyKnew and not silent then
        SC_Print("Companion pet unlocked in your tooltip: " .. petName .. "!")
    end
end

-- Best-effort: this addon doesn't know the server's exact wording for the
-- "you learned a companion" system message, so it matches loosely -- any
-- CHAT_MSG_SYSTEM line that contains both a known pet name from
-- SC.PET_NAMES and a companion/learn-flavored keyword. If your server's
-- message doesn't happen to contain one of those keywords this will miss
-- it silently; use /scw pet <name> to record it by hand in that case, and
-- /scw report to flag the exact wording so this can be tightened up.
local function SC_TryDetectPetFromSystemMsg(msg)
    if not msg or msg == "" then
        return
    end
    if not (string.find(msg, "ompanion") or string.find(msg, "earned") or string.find(msg, "earn how")) then
        return
    end
    local name
    for name in pairs(SC.PET_NAMES) do
        if string.find(msg, name, 1, true) then
            SC.MarkPetKnown(name)
        end
    end
end

-- Experimental chop detection: when a wood or leaf item shows up in your
-- loot, assume whatever you currently have targeted (a lot of vanilla
-- gathering nodes briefly become your "target" when clicked) is the tree
-- you just chopped. This is a guess at how it'll behave, not a confirmed
-- hook -- treat it as a starting point to refine once tested live.
local function SC_TryDetectChopFromLoot(msg)
    if not msg then
        return
    end
    -- Real loot lines are colorized item hyperlinks (|cff..|Hitem:..|h[Name]|h|r),
    -- so just look for "You receive ..." and pull whatever is in the first
    -- [brackets] rather than trying to parse the hyperlink escape codes.
    if not (string.find(msg, "You receive item:") or string.find(msg, "You receive loot:")) then
        return
    end
    local _, _, itemName = string.find(msg, "%[(.-)%]")
    if not itemName then
        return
    end
    local kind = nil
    if SC.WOOD_ITEM_NAMES[itemName] then
        kind = "wood"
    elseif SC.LEAF_ITEM_NAMES[itemName] then
        kind = "leaf"
    else
        return
    end
    local treeName = nil
    if UnitExists and UnitExists("target") then
        treeName = UnitName("target")
    end
    SC.RegisterChop(treeName or "Unidentified Tree", kind)
end

local scFrame = CreateFrame("Frame", "OctoSurvivalCompanionEventFrame")
scFrame:RegisterEvent("ADDON_LOADED")
scFrame:RegisterEvent("CHAT_MSG_LOOT")
scFrame:RegisterEvent("CHAT_MSG_SYSTEM")
scFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "OctoSurvivalCompanion" then
        SC_InitDB()
        SC_BuildPetNameIndex()
        SC_Print("loaded. Type /scw to open the profession guide.")
        if SC.CreateMinimapButton then
            SC.CreateMinimapButton()
        end
        if not OctoSurvivalCompanionDB.setupComplete and SC.ShowWelcome then
            SC.ShowWelcome()
        end
    elseif event == "CHAT_MSG_LOOT" then
        SC_TryDetectChopFromLoot(arg1)
    elseif event == "CHAT_MSG_SYSTEM" then
        SC_TryDetectPetFromSystemMsg(arg1)
    end
end)

-- ============================================================
-- Slash commands
-- ============================================================

SLASH_OCTOSURVIVALCOMPANION1 = "/scw"
SLASH_OCTOSURVIVALCOMPANION2 = "/survival"
SLASH_OCTOSURVIVALCOMPANION3 = "/octosurvivalcompanion"
SlashCmdList["OCTOSURVIVALCOMPANION"] = function(msg)
    msg = msg or ""

    if msg == "report" or msg == "feedback" then
        SC_Print("This addon's data lives in Data.lua as a plain Lua table -- if something is wrong or missing, edit that file directly (it's fully commented) and share the fix.")
        return
    end

    if msg == "minimap" then
        if SC.ToggleMinimapButton then
            SC.ToggleMinimapButton()
            if OctoSurvivalCompanionDB.minimapHidden then
                SC_Print("Minimap button hidden. /scw minimap to bring it back.")
            else
                SC_Print("Minimap button shown.")
            end
        end
        return
    end

    if msg == "setup" or msg == "options" then
        if SC.ShowWelcome then
            SC.ShowWelcome()
        else
            SC_Print("Setup screen failed to load.")
        end
        return
    end

    local _, _, chopName = string.find(msg, "^chop%s+(.+)$")
    if chopName then
        SC.RegisterChop(chopName, "wood")
        return
    end

    local _, _, leafName = string.find(msg, "^leaf%s+(.+)$")
    if leafName then
        SC.RegisterChop(leafName, "leaf")
        return
    end

    if msg == "resettrees" then
        SC.ResetTrees()
        SC_Print("Tree tracker cleared.")
        return
    end

    local _, _, petName = string.find(msg, "^pet%s+(.+)$")
    if petName then
        SC.MarkPetKnown(petName)
        SC_Print("Marked companion pet known: " .. petName)
        return
    end

    if msg == "pets" then
        SC_InitDB()
        SC_BuildPetNameIndex()
        local name
        local known = {}
        local unknown = 0
        for name in pairs(SC.PET_NAMES) do
            if SC.IsPetKnown(name) then
                table.insert(known, name)
            else
                unknown = unknown + 1
            end
        end
        if table.getn(known) == 0 then
            SC_Print("No tree-chop companion pets recorded yet (" .. unknown .. " still unknown). Use /scw pet <name> once you learn one.")
        else
            local i
            local list = ""
            for i = 1, table.getn(known) do
                if i > 1 then
                    list = list .. ", "
                end
                list = list .. known[i]
            end
            SC_Print("Known tree-chop pets: " .. list .. " (" .. unknown .. " still unknown)")
        end
        return
    end

    if SC.ToggleFrame then
        SC.ToggleFrame()
    else
        SC_Print("UI failed to load.")
    end
end
