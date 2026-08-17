--[[
Octo Survival Companion - UI.lua
Builds the main browsable frame: Recipes / Gardening / Trainers / Map tabs.
Written against the vanilla 1.12.1 widget API (Turtle WoW / OctoWoW / CapyCraft / TurtleCraft).
]]

OctoSurvivalCompanion = OctoSurvivalCompanion or {}
local SC = OctoSurvivalCompanion

local ROW_HEIGHT = 36
-- PANEL_WIDTH/PANEL_HEIGHT size the Map tab's map area (mapWidth =
-- PANEL_WIDTH, mapHeight = (PANEL_HEIGHT - 26) - mapTop, see
-- CreateContinentMap). SC.UpdateMapView stretches each zone's map tiles
-- (and C_Map.GetMapOverlays() reveal tiles, scaled the same way -- see
-- RefreshMapOverlay) to fill this box, rather than fitting GetMapInfo()'s
-- texWidth/texHeight -- that was tried twice and reverted both times: it
-- assumes texWidth/texHeight IS the shape the client displays a zone at,
-- but a side-by-side against the real World Map showed that's wrong
-- (Teldrassil's real displayed landmass is landscape, not the narrow
-- portrait shape 667x768 implies) -- texWidth/texHeight is most likely
-- just the tile canvas's raw resolution, unrelated to display shape.
--
-- RATIO set 2026-08-17 to roughly match the real World Map window's own
-- proportions (~1.4:1, eyeballed off a side-by-side screenshot) instead
-- of a stricter 4:3 or square shape, since every zone now stretches to
-- fill this box the same way the real client stretches into its own
-- window -- matching that shape is what keeps proportions looking right.
-- 750 / 1.442 = 520 (mapHeight). 520 + 108 (mapTop) + 26 = 654.
local PANEL_WIDTH = 750
local PANEL_HEIGHT = 654

local mainFrame
local tabButtons = {}
local panels = {}
local recipeRows = {}

local function ColorText(text, r, g, b)
    local ri = math.floor(r * 255 + 0.5)
    local gi = math.floor(g * 255 + 0.5)
    local bi = math.floor(b * 255 + 0.5)
    return string.format("|cff%02x%02x%02x%s|r", ri, gi, bi, text)
end

local function JoinList(list)
    if not list or table.getn(list) == 0 then
        return "none listed"
    end
    local out = ""
    local i
    for i = 1, table.getn(list) do
        if i > 1 then
            out = out .. ", "
        end
        out = out .. list[i]
    end
    return out
end

-- A zone with a KNOWN spawn count at or below this is flagged "(rare)"
-- wherever chop-zone lists are shown, rather than silently listed
-- alongside zones with 10-100x the population. 2026-08-16: added after
-- confirming several low counts (Balor 3 Bright Wood; Feralas 4 and
-- Darkshore 2 Star Wood; Searing Gorge 5, Un'Goro Crater 5, Azshara 4,
-- Darkshore 2 Dead Wood) are genuine, individually-verified spawn counts
-- -- not boundary-spillover artifacts like the secondary counts already
-- excluded elsewhere in Data.lua -- so they stay in chopZones/zoneCounts
-- (deleting confirmed-correct data would just make the addon less
-- accurate) but get flagged here instead, so "Choppable in: Balor" reads
-- as "technically true, don't make a special trip for it."
local RARE_ZONE_THRESHOLD = 10

-- Same as JoinList, but wraps whichever entry matches highlightItem in
-- [brackets] (used to call out your current zone) and appends " (rare)"
-- to any entry whose zoneCounts value (if the caller passes one) is at
-- or below RARE_ZONE_THRESHOLD. A zone with NO known count is never
-- marked rare -- zoneCounts is deliberately partial (see the note above
-- woodTiers in Data.lua), and "unknown" isn't the same claim as
-- "confirmed low."
local function JoinListAnnotated(list, highlightItem, zoneCounts)
    if not list or table.getn(list) == 0 then
        return "none listed"
    end
    local out = ""
    local i
    for i = 1, table.getn(list) do
        if i > 1 then
            out = out .. ", "
        end
        local entry = list[i]
        if zoneCounts and zoneCounts[entry] and zoneCounts[entry] <= RARE_ZONE_THRESHOLD then
            entry = entry .. " (rare)"
        end
        if highlightItem and list[i] == highlightItem then
            out = out .. "[" .. entry .. "]"
        else
            out = out .. entry
        end
    end
    return out
end

-- True if zoneName has a CONFIRMED low spawn count for this tier (at or
-- below RARE_ZONE_THRESHOLD) -- false for an unknown/unconfirmed count,
-- since "unknown" isn't the same claim as "confirmed low." Shared by the
-- Map tab's zone-dropdown filter and its tier-only info text, so a tier
-- pick with no zone picked always lists exactly what the dropdown offers.
local function IsZoneRareForTier(tierData, zoneName)
    if not tierData or not tierData.zoneCounts then
        return false
    end
    local count = tierData.zoneCounts[zoneName]
    if not count then
        return false
    end
    return count <= RARE_ZONE_THRESHOLD
end

-- Returns tier.chopZones with every confirmed rare/low-count zone
-- (IsZoneRareForTier) left out -- the "go farm this" view used by the
-- tree-bar tooltip and the tree-bar-icon jump-to-map feature, so both
-- only ever point you at spots actually worth the trip, same idea as the
-- Map tab's zone dropdown (BuildZoneDropdownList) already does. Returns
-- an EMPTY table (not the unfiltered list) when every known zone for this
-- tier is rare -- callers decide their own fallback/messaging for that
-- case rather than silently getting rare zones back.
local function GetFarmableZones(tier)
    if not tier or not tier.chopZones then
        return {}
    end
    local out = {}
    local i
    for i = 1, table.getn(tier.chopZones) do
        local zn = tier.chopZones[i]
        if not IsZoneRareForTier(tier, zn) then
            table.insert(out, zn)
        end
    end
    return out
end

-- ============================================================
-- Frame skeleton
-- ============================================================

local function CreateMainFrame()
    local f = CreateFrame("Frame", "OctoSurvivalCompanionFrame", UIParent)
    f:SetWidth(790)
    f:SetHeight(834)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Octo Survival Companion")
    f.title = title

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("Turtle WoW / OctoWoW / CapyCraft Survival profession reference")
    f.subtitle = subtitle

    local close = CreateFrame("Button", "OctoSurvivalCompanionCloseButton", f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() mainFrame:Hide() end)

    return f
end

local function CreateTabButton(parent, index, label, xOffset)
    local btn = CreateFrame("Button", "OctoSurvivalCompanionTab" .. index, parent, "UIPanelButtonTemplate")
    btn:SetWidth(108)
    btn:SetHeight(22)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -58)
    btn:SetText(label)
    btn:SetScript("OnClick", function() SC.ShowTab(index) end)
    return btn
end

local function CreatePanel(parent)
    local p = CreateFrame("Frame", nil, parent)
    p:SetWidth(PANEL_WIDTH)
    p:SetHeight(PANEL_HEIGHT)
    p:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -86)
    p:Hide()
    return p
end

-- ============================================================
-- Recipes tab
-- ============================================================

local function BuildRecipeTooltip(row, recipe)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    local shownItemTooltip = false
    if recipe.resultItemId then
        GameTooltip:SetHyperlink("item:" .. recipe.resultItemId .. ":0:0:0:0:0:0:0")
        shownItemTooltip = true
    end
    if not shownItemTooltip then
        GameTooltip:AddLine(recipe.name, 1, 0.82, 0)
    end
    GameTooltip:AddLine(" ")
    if not recipe.confirmed then
        GameTooltip:AddLine("(unconfirmed data -- verify in game)", 0.9, 0.3, 0.3)
    end
    local skillText = "Skill required: "
    if recipe.skillReq then
        skillText = skillText .. recipe.skillReq
    else
        skillText = skillText .. "unknown"
    end
    if recipe.charLevel then
        skillText = skillText .. "   (char level " .. recipe.charLevel .. "+)"
    end
    GameTooltip:AddLine(skillText, 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Reagents: " .. JoinList(recipe.reagents), 1, 1, 1, 1)
    if recipe.effect then
        GameTooltip:AddLine("Effect: " .. recipe.effect, 0.6, 1, 0.6, 1)
    end
    if recipe.duration then
        GameTooltip:AddLine("Duration: " .. recipe.duration, 0.8, 0.8, 0.8)
    end
    if recipe.cooldown then
        GameTooltip:AddLine("Cooldown: " .. recipe.cooldown, 0.8, 0.8, 0.8)
    end
    if recipe.source then
        GameTooltip:AddLine("Source: " .. recipe.source, 0.8, 0.8, 1)
    end
    if recipe.notes then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(recipe.notes, 0.6, 0.6, 0.6, 1)
    end
    GameTooltip:Show()
end

local function CreateRecipeScroll(parent)
    local scroll = CreateFrame("ScrollFrame", "OctoSurvivalCompanionRecipeScroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scroll:SetWidth(PANEL_WIDTH - 30)
    scroll:SetHeight(PANEL_HEIGHT)

    local recipes = OctoSurvivalCompanion_Data.recipes
    local count = table.getn(recipes)

    local content = CreateFrame("Frame", "OctoSurvivalCompanionRecipeScrollChild", scroll)
    content:SetWidth(PANEL_WIDTH - 30)
    content:SetHeight(count * ROW_HEIGHT + 4)
    scroll:SetScrollChild(content)

    local i
    for i = 1, count do
        local recipe = recipes[i]
        local row = CreateFrame("Frame", "OctoSurvivalCompanionRecipeRow" .. i, content)
        row:SetWidth(PANEL_WIDTH - 30)
        row:SetHeight(ROW_HEIGHT)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:EnableMouse(true)

        local highlight = row:CreateTexture(nil, "BACKGROUND")
        highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        highlight:SetAllPoints(row)
        highlight:Hide()
        row.highlight = highlight
        row:SetScript("OnEnter", function()
            this.highlight:Show()
            BuildRecipeTooltip(this, this.recipe)
        end)
        row:SetScript("OnLeave", function()
            this.highlight:Hide()
            GameTooltip:Hide()
        end)
        row.recipe = recipe

        local check = CreateFrame("CheckButton", "OctoSurvivalCompanionRecipeCheck" .. i, row, "UICheckButtonTemplate")
        check:SetWidth(20)
        check:SetHeight(20)
        check:SetPoint("LEFT", row, "LEFT", 2, 0)
        check.recipeName = recipe.name
        check:SetScript("OnClick", function()
            SC.ToggleKnown(this.recipeName)
        end)
        row.check = check

        local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetPoint("LEFT", check, "RIGHT", 6, 0)
        name:SetWidth(260)
        name:SetJustifyH("LEFT")
        local displayName = recipe.name
        if not recipe.confirmed then
            displayName = displayName .. " |cff999999(?)|r"
        end
        name:SetText(displayName)

        local skill = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        skill:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        skill:SetJustifyH("RIGHT")
        if recipe.skillReq then
            skill:SetText("Skill " .. recipe.skillReq)
        else
            skill:SetText("Skill ?")
        end

        recipeRows[i] = row
    end

    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 4, -14)
    hint:SetText("Hover a recipe for full details. Click the box to mark it as known.")

    return scroll
end

function SC.RefreshUI()
    local i
    for i = 1, table.getn(recipeRows) do
        local row = recipeRows[i]
        if row and row.check then
            row.check:SetChecked(SC.IsKnown(row.recipe.name))
        end
    end
end

-- ============================================================
-- Bottom bar: tree-chop tracker
--
-- STRIPPED TO BARE MINIMUM 2026-08-17 -- just the background bar and a
-- "Total Trees Chopped: N" counter, nothing per-tree. Two rewrites in a
-- row (icon textures, then colored text entries) both left the bar
-- visually broken in game for reasons that never reproduced from the code
-- or data in isolation, so this drops the per-tree row entirely rather
-- than debug a fourth variant blind.
--
-- Second row ADDED 2026-08-17 -- plain text, one entry per wood TIER (not
-- per distinct tree name like the old removed version) in the fixed order
-- Data.lua's woodTiers table lists them (Simple/Bright/Shade/Tropical/
-- Star/Dead), each showing SC.GetTierChopCount(tier.tier) -- deliberately
-- no hover tooltip and no click-to-jump yet, kept back until this simpler
-- text-only version is confirmed rendering fine in game.
-- ============================================================

local TIER_ENTRY_HEIGHT = 16
local TIER_ENTRY_GAP = 10

local treeBarFrame
local treeBarTierLabels = {}

local function CreateTreeBar(parent)
    local bar = CreateFrame("Frame", "OctoSurvivalCompanionTreeBar", parent)
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 20, 14)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 14)
    bar:SetHeight(44)
    bar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    bar:SetBackdropColor(0, 0, 0, 0.35)

    local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", bar, "TOPLEFT", 8, -6)
    label:SetJustifyH("LEFT")
    label:SetText("Total Trees Chopped: 0")
    bar.label = label

    local tierHolder = CreateFrame("Frame", nil, bar)
    tierHolder:SetPoint("TOPLEFT", bar, "TOPLEFT", 8, -24)
    tierHolder:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -8, 4)
    bar.tierHolder = tierHolder

    treeBarFrame = bar
    return bar
end

function SC.RefreshTreeBar()
    if not treeBarFrame then
        return
    end
    if OctoSurvivalCompanionDB and OctoSurvivalCompanionDB.showTreeBar == false then
        treeBarFrame:Hide()
        return
    end
    treeBarFrame:Show()
    local totalChops = 0
    if SC.GetTotalChops then
        totalChops = SC.GetTotalChops()
    end
    treeBarFrame.label:SetText("Total Trees Chopped: " .. totalChops)

    if not OctoSurvivalCompanion_Data or not OctoSurvivalCompanion_Data.woodTiers then
        return
    end

    local xCursor = 0
    local i
    for i = 1, table.getn(OctoSurvivalCompanion_Data.woodTiers) do
        local tier = OctoSurvivalCompanion_Data.woodTiers[i]
        local fs = treeBarTierLabels[i]
        if not fs then
            fs = treeBarFrame.tierHolder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetHeight(TIER_ENTRY_HEIGHT)
            fs:SetJustifyH("LEFT")
            treeBarTierLabels[i] = fs
        end

        local count = 0
        if SC.GetTierChopCount then
            count = SC.GetTierChopCount(tier.tier)
        end
        fs:SetText(tier.tier .. " (" .. count .. ")")
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", treeBarFrame.tierHolder, "TOPLEFT", xCursor, 0)
        xCursor = xCursor + fs:GetStringWidth() + TIER_ENTRY_GAP
        fs:Show()
    end

    local j
    for j = table.getn(OctoSurvivalCompanion_Data.woodTiers) + 1, table.getn(treeBarTierLabels) do
        if treeBarTierLabels[j] then
            treeBarTierLabels[j]:Hide()
        end
    end
end

-- ============================================================
-- Gardening tab
-- ============================================================

local function CreateGardeningPanel(parent)
    local g = OctoSurvivalCompanion_Data.gardening
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
    text:SetWidth(PANEL_WIDTH - 30)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")

    local lines = {}
    table.insert(lines, ColorText("Gardening (unlocked at Survival skill " .. tostring(g.unlockSkill) .. ")", 1, 0.82, 0))
    table.insert(lines, " ")
    table.insert(lines, ColorText("Starter quest: ", 0.6, 0.8, 1) .. g.startQuest.name .. " (level " .. g.startQuest.minLevel .. "+)")
    table.insert(lines, "Location: " .. g.startQuest.location)
    table.insert(lines, "Reward: " .. g.startQuest.reward)
    table.insert(lines, " ")
    table.insert(lines, ColorText("Materials:", 0.6, 0.8, 1))
    local i
    for i = 1, table.getn(g.materials) do
        table.insert(lines, "  - " .. g.materials[i])
    end
    table.insert(lines, " ")
    table.insert(lines, ColorText("Mechanic:", 0.6, 0.8, 1) .. " " .. g.mechanic)
    table.insert(lines, " ")
    table.insert(lines, ColorText("Notes:", 0.6, 0.6, 0.6) .. " " .. g.notes)

    local full = ""
    for i = 1, table.getn(lines) do
        if i > 1 then
            full = full .. "\n"
        end
        full = full .. lines[i]
    end
    text:SetText(full)
end

-- ============================================================
-- Trainers tab
-- ============================================================

local trainersScroll, trainersScrollContent, trainersScrollText

-- Turtle WoW city/capital names, grouped by faction, so the Trainers tab
-- can put your own faction's trainers first when you've set one in the
-- welcome screen (see Data.lua trainers[i].faction). Anything not in
-- either list (Rufus Hardwick's "Neutral (all)", Hellador Swiftluck's
-- "Silvermoon Remnant", Feebeld's "unconfirmed") is treated as neutral and
-- left in its original position.
local ALLIANCE_TRAINER_FACTIONS = { ["Stormwind"] = true, ["Darnassus"] = true, ["Ironforge"] = true }
local HORDE_TRAINER_FACTIONS = { ["Orgrimmar"] = true, ["Thunder Bluff"] = true, ["Undercity"] = true }

local function FactionGroupFor(factionText)
    if ALLIANCE_TRAINER_FACTIONS[factionText] then
        return "Alliance"
    elseif HORDE_TRAINER_FACTIONS[factionText] then
        return "Horde"
    end
    return "Neutral"
end

-- Stable sort (decorate-sort-undecorate, since table.sort isn't guaranteed
-- stable) that pulls playerFaction's trainers to the top, then neutral
-- ones, then the opposing faction -- without reshuffling within each group.
local function SortTrainersByFaction(trainers, playerFaction)
    if not playerFaction then
        return trainers
    end
    local decorated = {}
    local i
    for i = 1, table.getn(trainers) do
        local group = FactionGroupFor(trainers[i].faction)
        local priority = 1
        if group == playerFaction then
            priority = 0
        elseif group ~= "Neutral" then
            priority = 2
        end
        table.insert(decorated, { priority = priority, order = i, data = trainers[i] })
    end
    table.sort(decorated, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return a.order < b.order
    end)
    local result = {}
    for i = 1, table.getn(decorated) do
        table.insert(result, decorated[i].data)
    end
    return result
end

local function CreateTrainersPanel(parent)
    -- 15 trainers plus rank-up + quest info runs well past one screen, so
    -- this tab scrolls like the Recipes tab instead of using a fixed-size
    -- FontString.
    trainersScroll = CreateFrame("ScrollFrame", "OctoSurvivalCompanionTrainersScroll", parent, "UIPanelScrollFrameTemplate")
    trainersScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    trainersScroll:SetWidth(PANEL_WIDTH - 30)
    trainersScroll:SetHeight(PANEL_HEIGHT)

    trainersScrollContent = CreateFrame("Frame", "OctoSurvivalCompanionTrainersScrollChild", trainersScroll)
    trainersScrollContent:SetWidth(PANEL_WIDTH - 30)
    trainersScrollContent:SetHeight(1) -- resized below once we know the text height

    trainersScrollText = trainersScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    trainersScrollText:SetPoint("TOPLEFT", trainersScrollContent, "TOPLEFT", 4, -4)
    trainersScrollText:SetWidth(PANEL_WIDTH - 46)
    trainersScrollText:SetJustifyH("LEFT")
    trainersScrollText:SetJustifyV("TOP")

    trainersScroll:SetScrollChild(trainersScrollContent)
    SC.RefreshTrainersPanel()
end

-- Rebuilds the Trainers tab text -- called once when the tab is first
-- built, and again from the welcome/setup screen's Save button so a
-- faction change takes effect immediately without needing /reload.
function SC.RefreshTrainersPanel()
    if not trainersScrollText then
        return
    end

    local lines = {}
    table.insert(lines, ColorText("Survival Trainers", 1, 0.82, 0))
    table.insert(lines, "Most Survival recipes are taught directly by these NPCs -- not looted or bought as scrolls.")

    local playerFaction = nil
    if OctoSurvivalCompanionDB then
        playerFaction = OctoSurvivalCompanionDB.faction
    end
    if playerFaction then
        table.insert(lines, ColorText("Sorted for " .. playerFaction .. " -- change this with /scw setup.", 0.6, 0.6, 0.6))
    end

    local trainers = SortTrainersByFaction(OctoSurvivalCompanion_Data.trainers, playerFaction)
    local i
    for i = 1, table.getn(trainers) do
        local t = trainers[i]
        table.insert(lines, " ")
        local levelStr = "?"
        if t.level then
            levelStr = tostring(t.level)
        end
        local factionTag = " [" .. FactionGroupFor(t.faction) .. "]"
        table.insert(lines, ColorText(t.name .. " -- " .. t.title .. " (lvl " .. levelStr .. ")" .. factionTag, 0.6, 0.8, 1))
        table.insert(lines, t.zone .. "  (" .. t.coords .. ")  -- " .. t.faction)
        table.insert(lines, "Teaches: " .. JoinList(t.teaches))
        if t.notes then
            table.insert(lines, ColorText(t.notes, 0.6, 0.6, 0.6))
        end
    end

    table.insert(lines, " ")
    table.insert(lines, ColorText("Rank-ups (raise your Survival skill cap)", 1, 0.82, 0))
    local ranks = OctoSurvivalCompanion_Data.rankSpells
    for i = 1, table.getn(ranks) do
        local r = ranks[i]
        local line = r.name .. " -- skill cap " .. tostring(r.unlocksSkillCap)
        table.insert(lines, line)
        if r.note then
            table.insert(lines, ColorText(r.note, 0.6, 0.6, 0.6))
        end
    end

    table.insert(lines, " ")
    table.insert(lines, ColorText("Starting quest: " .. OctoSurvivalCompanion_Data.startQuest.name, 1, 0.82, 0))
    table.insert(lines, "Level " .. OctoSurvivalCompanion_Data.startQuest.minLevel .. "+, given at " .. OctoSurvivalCompanion_Data.startQuest.giver)
    table.insert(lines, "Requires:")
    local reqs = OctoSurvivalCompanion_Data.startQuest.requirements
    for i = 1, table.getn(reqs) do
        table.insert(lines, "  - " .. reqs[i])
    end
    table.insert(lines, "Reward: " .. OctoSurvivalCompanion_Data.startQuest.reward)
    if OctoSurvivalCompanion_Data.startQuest.altPaths then
        table.insert(lines, ColorText(OctoSurvivalCompanion_Data.startQuest.altPaths, 0.6, 0.6, 0.6))
    end

    local full = ""
    for i = 1, table.getn(lines) do
        if i > 1 then
            full = full .. "\n"
        end
        full = full .. lines[i]
    end
    trainersScrollText:SetText(full)

    trainersScrollContent:SetHeight(trainersScrollText:GetHeight() + 16)
end

-- ============================================================
-- Logbook tab -- "every log you've logged, logged." Your own chop
-- history from OctoSurvivalCompanionDB (Core.lua's SC.RegisterChop), tallied
-- and cross-referenced against the Data.lua wood-tier catalog. Nothing
-- here is pre-populated -- same as the tree-chop tracker bar this
-- expands on, it only knows about trees it's actually seen you gather
-- from. Built the same scrolling-FontString way as the Trainers tab.
-- ============================================================

local logbookScroll, logbookScrollContent, logbookScrollText

local function CreateLogbookPanel(parent)
    logbookScroll = CreateFrame("ScrollFrame", "OctoSurvivalCompanionLogbookScroll", parent, "UIPanelScrollFrameTemplate")
    logbookScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    logbookScroll:SetWidth(PANEL_WIDTH - 30)
    logbookScroll:SetHeight(PANEL_HEIGHT)

    logbookScrollContent = CreateFrame("Frame", "OctoSurvivalCompanionLogbookScrollChild", logbookScroll)
    logbookScrollContent:SetWidth(PANEL_WIDTH - 30)
    logbookScrollContent:SetHeight(1) -- resized below once we know the text height

    logbookScrollText = logbookScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    logbookScrollText:SetPoint("TOPLEFT", logbookScrollContent, "TOPLEFT", 4, -4)
    logbookScrollText:SetWidth(PANEL_WIDTH - 46)
    logbookScrollText:SetJustifyH("LEFT")
    logbookScrollText:SetJustifyV("TOP")

    logbookScroll:SetScrollChild(logbookScrollContent)
    SC.RefreshLogbookPanel()
end

-- Rebuilds the Logbook tab -- called once when the tab is first built,
-- and again from SC.RegisterChop (Core.lua) every time a chop is
-- recorded, so it updates live while the tab is open.
function SC.RefreshLogbookPanel()
    if not logbookScrollText then
        return
    end

    local lines = {}
    table.insert(lines, ColorText("The Logbook", 1, 0.82, 0))
    table.insert(lines, ColorText("Every log you've logged, logged.", 0.6, 0.6, 0.6))

    local totalChops = 0
    local treeOrder = {}
    if SC.GetTotalChops then
        totalChops = SC.GetTotalChops()
    end
    if SC.GetTreeOrder then
        treeOrder = SC.GetTreeOrder()
    end

    if totalChops == 0 then
        table.insert(lines, " ")
        table.insert(lines, "Nothing logged yet -- go chop something. Wood and leaves both count, and a tree gets logged here the moment you gather from it.")
        local full = ""
        local i
        for i = 1, table.getn(lines) do
            if i > 1 then
                full = full .. "\n"
            end
            full = full .. lines[i]
        end
        logbookScrollText:SetText(full)
        logbookScrollContent:SetHeight(logbookScrollText:GetHeight() + 16)
        return
    end

    table.insert(lines, " ")
    table.insert(lines, ColorText("Total Trees Chopped: " .. totalChops, 0.6, 0.8, 1) .. "   " .. ColorText("Distinct trees logged: " .. table.getn(treeOrder), 0.6, 0.8, 1))

    -- By tier: wood/leaf totals across every zone-instance of that tier
    -- you've chopped -- e.g. every "Simple Wood Tree (<Zone>)" you've hit
    -- gets folded into one Simple Wood line here.
    table.insert(lines, " ")
    table.insert(lines, ColorText("By tier", 1, 0.82, 0))
    if OctoSurvivalCompanion_Data and OctoSurvivalCompanion_Data.woodTiers then
        local t
        for t = 1, table.getn(OctoSurvivalCompanion_Data.woodTiers) do
            local tier = OctoSurvivalCompanion_Data.woodTiers[t]
            local woodTotal = 0
            local leafTotal = 0
            local instanceCount = 0
            local i
            for i = 1, table.getn(treeOrder) do
                local treeName = treeOrder[i]
                if tier.treeNamePattern and string.find(treeName, tier.treeNamePattern) then
                    instanceCount = instanceCount + 1
                    if SC.GetTreeWoodCount then
                        woodTotal = woodTotal + SC.GetTreeWoodCount(treeName)
                    end
                    if SC.GetTreeLeafCount then
                        leafTotal = leafTotal + SC.GetTreeLeafCount(treeName)
                    end
                end
            end
            if instanceCount > 0 then
                local woodLabel = tier.tier .. " Wood"
                if tier.woodItem then
                    woodLabel = tier.woodItem.name
                end
                local leafLabel = tier.tier .. " Leaves"
                if tier.leafItem then
                    leafLabel = tier.leafItem.name
                end
                local zoneWord = "zone"
                if instanceCount ~= 1 then
                    zoneWord = "zones"
                end
                table.insert(lines, tier.tier .. " Wood -- " .. woodLabel .. ": " .. woodTotal .. "    " .. leafLabel .. ": " .. leafTotal .. "  (logged in " .. instanceCount .. " " .. zoneWord .. ")")
            end
        end
    end

    -- By tree: exactly which named trees you've chopped, in first-seen
    -- order (matches the tree-bar's icon order), and how many times each.
    table.insert(lines, " ")
    table.insert(lines, ColorText("By tree", 1, 0.82, 0))
    local i
    for i = 1, table.getn(treeOrder) do
        local treeName = treeOrder[i]
        local count = 0
        local wood = 0
        local leaf = 0
        if SC.GetTreeCount then
            count = SC.GetTreeCount(treeName)
        end
        if SC.GetTreeWoodCount then
            wood = SC.GetTreeWoodCount(treeName)
        end
        if SC.GetTreeLeafCount then
            leaf = SC.GetTreeLeafCount(treeName)
        end
        table.insert(lines, ColorText(treeName, 0.6, 0.8, 1) .. "  -- " .. count .. " total (wood " .. wood .. ", leaf " .. leaf .. ")")
    end

    -- Companion pets: same known/unknown tracking as "/scw pets", laid
    -- out here too rather than making you tab out to chat for it.
    table.insert(lines, " ")
    table.insert(lines, ColorText("Companion pets", 1, 0.82, 0))
    local knownNames = {}
    local unknownCount = 0
    if OctoSurvivalCompanion_Data and OctoSurvivalCompanion_Data.woodTiers then
        local seen = {}
        local t
        for t = 1, table.getn(OctoSurvivalCompanion_Data.woodTiers) do
            local tier = OctoSurvivalCompanion_Data.woodTiers[t]
            if tier.pets then
                local p
                for p = 1, table.getn(tier.pets) do
                    local petName = tier.pets[p].name
                    if not seen[petName] then
                        seen[petName] = true
                        if SC.IsPetKnown and SC.IsPetKnown(petName) then
                            table.insert(knownNames, petName)
                        else
                            unknownCount = unknownCount + 1
                        end
                    end
                end
            end
        end
    end
    if table.getn(knownNames) == 0 then
        table.insert(lines, "None discovered yet (" .. unknownCount .. " still unknown). Use /scw pet <name> once you learn one.")
    else
        table.insert(lines, JoinList(knownNames) .. "  (" .. unknownCount .. " still unknown)")
    end

    local full = ""
    for i = 1, table.getn(lines) do
        if i > 1 then
            full = full .. "\n"
        end
        full = full .. lines[i]
    end
    logbookScrollText:SetText(full)

    logbookScrollContent:SetHeight(logbookScrollText:GetHeight() + 16)
end

-- ============================================================
-- Guide tab -- a step-by-step Survival skill-up leveling guide (what to
-- craft at each skill range, plus the Journeyman/Expert/Artisan Survival
-- rank-up gates in between), read straight from
-- OctoSurvivalCompanion_Data.levelingGuide.sections. Static reference
-- content, not tied to your own chop/pet tracking -- built the same
-- scrolling-FontString way as the Trainers and Logbook tabs. See the big
-- comment above levelingGuide in Data.lua for the source, including a
-- correction it surfaced for rankSpells/trainers (now applied there).
-- ============================================================

local guideScroll, guideScrollContent, guideScrollText

local function CreateGuidePanel(parent)
    guideScroll = CreateFrame("ScrollFrame", "OctoSurvivalCompanionGuideScroll", parent, "UIPanelScrollFrameTemplate")
    guideScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    guideScroll:SetWidth(PANEL_WIDTH - 30)
    guideScroll:SetHeight(PANEL_HEIGHT)

    guideScrollContent = CreateFrame("Frame", "OctoSurvivalCompanionGuideScrollChild", guideScroll)
    guideScrollContent:SetWidth(PANEL_WIDTH - 30)
    guideScrollContent:SetHeight(1) -- resized below once we know the text height

    guideScrollText = guideScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    guideScrollText:SetPoint("TOPLEFT", guideScrollContent, "TOPLEFT", 4, -4)
    guideScrollText:SetWidth(PANEL_WIDTH - 46)
    guideScrollText:SetJustifyH("LEFT")
    guideScrollText:SetJustifyV("TOP")

    guideScroll:SetScrollChild(guideScrollContent)
    SC.RefreshGuidePanel()
end

-- Rebuilds the Guide tab from Data.lua -- called once when the tab is
-- first built. Nothing here changes at runtime (it's not tied to your own
-- chop tracking), but this is still a function rather than inline
-- CreateGuidePanel code so a future /reload-free data edit (or a later
-- pass adding more of the guide) has somewhere to call back into.
function SC.RefreshGuidePanel()
    if not guideScrollText then
        return
    end

    local lines = {}
    table.insert(lines, ColorText("Survival Leveling Guide", 1, 0.82, 0))

    local guide = OctoSurvivalCompanion_Data and OctoSurvivalCompanion_Data.levelingGuide
    if not guide or not guide.sections or table.getn(guide.sections) == 0 then
        table.insert(lines, " ")
        table.insert(lines, "No leveling guide on file yet.")
        local full = ""
        local i
        for i = 1, table.getn(lines) do
            if i > 1 then
                full = full .. "\n"
            end
            full = full .. lines[i]
        end
        guideScrollText:SetText(full)
        guideScrollContent:SetHeight(guideScrollText:GetHeight() + 16)
        return
    end

    if guide.source then
        table.insert(lines, ColorText("Source: " .. guide.source, 0.6, 0.6, 0.6))
    end
    if guide.sourceNote then
        table.insert(lines, ColorText(guide.sourceNote, 0.55, 0.55, 0.5))
    end

    local i
    for i = 1, table.getn(guide.sections) do
        local section = guide.sections[i]
        table.insert(lines, " ")
        if section.type == "header" then
            table.insert(lines, ColorText(section.text, 1, 0.82, 0))
        elseif section.type == "gate" then
            table.insert(lines, ColorText(section.name, 0.9, 0.3, 0.3))
            table.insert(lines, section.text)
            if section.trainers then
                table.insert(lines, ColorText(section.trainers, 0.6, 0.8, 1))
            end
        elseif section.type == "bracket" then
            local rangeLabel = ""
            if section.range then
                rangeLabel = "[" .. section.range .. "]"
            end
            table.insert(lines, ColorText(rangeLabel, 0.6, 0.8, 1) .. "  " .. (section.craft or ""))
            if section.note then
                table.insert(lines, ColorText(section.note, 0.6, 0.6, 0.6))
            end
        elseif section.type == "note" then
            table.insert(lines, ColorText(section.text, 0.6, 0.6, 0.6))
        elseif section.type == "list" then
            if section.heading then
                table.insert(lines, ColorText(section.heading, 1, 0.82, 0))
            end
            if section.items then
                local j
                for j = 1, table.getn(section.items) do
                    table.insert(lines, "  " .. section.items[j])
                end
            end
            if section.total then
                table.insert(lines, ColorText(section.total, 0.6, 0.8, 1))
            end
        end
    end

    local full = ""
    for i = 1, table.getn(lines) do
        if i > 1 then
            full = full .. "\n"
        end
        full = full .. lines[i]
    end
    guideScrollText:SetText(full)

    guideScrollContent:SetHeight(guideScrollText:GetHeight() + 16)
end

-- ============================================================
-- Map tab: Kalimdor / Eastern Kingdoms sub-tabs
--
-- Draws using the client's own World Map art rather than any image
-- bundled with the addon -- vanilla arranges every map (continent OR
-- zone) as a flat 4x3 grid of 12 tiles named mapFileName1 through
-- mapFileName12 (Eastern Kingdoms' internal mapFileName is "Azeroth", a
-- long-standing vanilla FrameXML naming quirk). CONFIRMED 2026-08-16
-- against the actual 1.12.1 FrameXML source (WorldMapFrame_Update's own
-- tile-loading loop, NUM_WORLDMAP_DETAIL_TILES = 12) -- this is 1-INDEXED,
-- correcting an earlier version of this file that assumed a 0-indexed
-- Kalimdor0-11 scheme (untested guess, never verified), which would have
-- rendered the whole grid shifted one tile off. A map that needs fewer
-- than 12 tiles just leaves the higher indices pointing at textures that
-- don't exist -- WoW renders those blank rather than erroring.
--
-- 2026-08-16: replaced the old per-zone hotspot dots (hover tooltip,
-- shaded-area highlight, click-to-flash ring -- removed 2026-08-15) with
-- a pair of dropdowns per continent: pick a tree tier and/or a zone and
-- an info line underneath spells out what grows where. Built on the
-- stock UIDropDownMenuTemplate. Note that vanilla 1.12.1's dropdown API
-- takes the VALUE first and the WIDGET second -- UIDropDownMenu_SetWidth
-- (width, dropdown) and UIDropDownMenu_SetText(text, dropdown) -- later
-- expansions swapped that argument order, so don't copy examples from a
-- modern wiki without checking the version (confirmed 2026-08-16 against
-- the actual 1.12.1 FrameXML source, not just a wiki page).
--
-- 2026-08-16: picking a zone now switches the map art itself -- to that
-- zone's own client map when SC.ResolveZoneMapFile can match it against
-- the live GetMapZones() list, or to a zoomed-in crop of the continent
-- (CreateZoomCrop) centered on the zone's known x/y when it can't (all 7
-- custom Turtle WoW zones, plus anything else unmatched). See the
-- comments above SC.ResolveZoneMapFile and CreateZoomCrop for the full
-- reasoning -- this couldn't be a hardcoded name/file table because
-- vanilla's internal zone map folder names don't reliably match display
-- names, and there was no way to verify one from outside the game.
-- ============================================================

-- mapFileName is the client's own internal name for each continent's
-- World Map art folder (Interface\WorldMap\<mapFileName>\) -- Eastern
-- Kingdoms is named "Azeroth" internally, a long-standing vanilla
-- FrameXML naming quirk. Zones use this same scheme with their own
-- mapFileName, resolved live in SC.ResolveZoneMapFile below rather than
-- guessed here.
local MAP_CONTINENTS = {
    { key = "Kalimdor", label = "Kalimdor", mapFileName = "Kalimdor" },
    { key = "EasternKingdoms", label = "Eastern Kingdoms", mapFileName = "Azeroth" },
}

-- Looks up a zone's entry in the Map tab's zone list (name, continent,
-- x/y, tiers) by name. Shared by the tree/zone picker dropdowns below and
-- by SC.JumpToTreeOnMap's nearest-zone distance calc further down.
local function FindZoneData(zoneName)
    if not zoneName or not OctoSurvivalCompanion_Data or not OctoSurvivalCompanion_Data.zones then
        return nil
    end
    local i
    for i = 1, table.getn(OctoSurvivalCompanion_Data.zones) do
        if OctoSurvivalCompanion_Data.zones[i].name == zoneName then
            return OctoSurvivalCompanion_Data.zones[i]
        end
    end
    return nil
end

-- Looks up a wood tier's full data table (level/chopZones/zoneCounts/etc)
-- by its short key (e.g. "Simple") -- the picker dropdowns below only
-- store the key string on the button, this fetches the rest on demand.
local function GetTierByKey(tierKey)
    if not tierKey or not OctoSurvivalCompanion_Data or not OctoSurvivalCompanion_Data.woodTiers then
        return nil
    end
    local i
    for i = 1, table.getn(OctoSurvivalCompanion_Data.woodTiers) do
        if OctoSurvivalCompanion_Data.woodTiers[i].tier == tierKey then
            return OctoSurvivalCompanion_Data.woodTiers[i]
        end
    end
    return nil
end

-- Best available icon texture for a wood tier -- prefers the wood item's
-- own icon, falls back to the leaf item's (Dead Wood has no wood item of
-- its own, see Data.lua), then the addon's generic tree icon.
local function GetTierIconPath(tier)
    if tier then
        if tier.woodItem and tier.woodItem.icon then
            return tier.woodItem.icon
        end
        if tier.leafItem and tier.leafItem.icon then
            return tier.leafItem.icon
        end
    end
    if OctoSurvivalCompanion_Data then
        return OctoSurvivalCompanion_Data.defaultTreeIcon
    end
    return nil
end

-- Builds a 4x3 grid of BACKGROUND textures anchored at parent's TOPLEFT --
-- the same tile arrangement vanilla's own World Map uses for both
-- continent- and zone-level art (NUM_WORLDMAP_DETAIL_TILES = 12 in the
-- client's WorldMapFrame.lua, always a flat 12-tile grid regardless of
-- zoom level). Returns the grid frame plus a flat array of the 12
-- texture objects (row-major, 1-12) so callers can retarget them later
-- with SetGridTextures instead of rebuilding the grid from scratch.
local function CreateTileGrid(parent, cols, rows, tileWidth, tileHeight)
    local grid = CreateFrame("Frame", nil, parent)
    grid:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    grid:SetWidth(tileWidth * cols)
    grid:SetHeight(tileHeight * rows)
    local textures = {}
    local row, col
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local tile = grid:CreateTexture(nil, "BACKGROUND")
            tile:SetWidth(tileWidth + 1)
            tile:SetHeight(tileHeight + 1)
            tile:SetPoint("TOPLEFT", grid, "TOPLEFT", col * tileWidth, -(row * tileHeight))
            table.insert(textures, tile)
        end
    end
    return grid, textures
end

-- Resizes/repositions an already-built tile grid's 12 tiles to a new
-- tileWidth/tileHeight, reusing the same texture objects from
-- CreateTileGrid rather than recreating them (mirrors CreateTileGrid's own
-- layout math). Needed because a zone's real map canvas isn't always the
-- same proportions as this addon's fixed map display box -- see the
-- GetMapInfo() width/height note above SC.ResolveZoneMapFile, and the fit
-- logic in SC.UpdateMapView that calls this every time the zone changes.
local function ResizeTileGrid(grid, textures, cols, rows, tileWidth, tileHeight)
    grid:SetWidth(tileWidth * cols)
    grid:SetHeight(tileHeight * rows)
    local row, col
    local i = 1
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local tile = textures[i]
            tile:SetWidth(tileWidth + 1)
            tile:SetHeight(tileHeight + 1)
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", grid, "TOPLEFT", col * tileWidth, -(row * tileHeight))
            i = i + 1
        end
    end
end

-- Points an already-built 12-tile grid (from CreateTileGrid) at a
-- particular map's art. Tile files are named mapFileName1 through
-- mapFileName12 -- 1-INDEXED, confirmed 2026-08-16 against the actual
-- 1.12.1 FrameXML source (WorldMapFrame_Update's own tile-loading loop),
-- not just assumed -- this corrects an earlier version of this file that
-- assumed a 0-indexed Kalimdor0-11 scheme, which would have been off by
-- one tile the whole grid. A map that needs fewer than 12 tiles (most
-- zones) just leaves the higher indices pointing at textures that don't
-- exist -- WoW renders those blank rather than erroring, same as always.
local function SetGridTextures(textures, mapFileName)
    local i
    for i = 1, table.getn(textures) do
        textures[i]:SetTexture("Interface\\WorldMap\\" .. mapFileName .. "\\" .. mapFileName .. i)
    end
end

-- Resolves "Kalimdor" / "EasternKingdoms" to the client's own continent
-- index (GetMapContinents() return order) -- looked up by name rather
-- than hardcoded, in case that order ever differs from what we'd guess.
local continentIndexCache = {}
local function GetContinentIndex(continentKey)
    if continentIndexCache[continentKey] then
        return continentIndexCache[continentKey]
    end
    if not GetMapContinents then
        return nil
    end
    local continentNames = { GetMapContinents() }
    local wantName = "Eastern Kingdoms"
    if continentKey == "Kalimdor" then
        wantName = "Kalimdor"
    end
    local i
    for i = 1, table.getn(continentNames) do
        if continentNames[i] == wantName then
            continentIndexCache[continentKey] = i
            return i
        end
    end
    return nil
end

-- Resolves a zone's real Blizzard zone-map file name (for the "switch to
-- this zone's own map" feature) using the LIVE client API instead of a
-- hardcoded name -> file table. Vanilla's internal zone map folder names
-- don't always match the display name we use (Stranglethorn Vale, The
-- Barrens, and Hillsbrad Foothills are known exceptions), and there's no
-- way to verify a guessed table from outside the game -- so this asks
-- the client the same way the real World Map does: SetMapZoom to a
-- (continent, zone) pair from GetMapZones(), then read back GetMapInfo()'s
-- mapFileName. Whatever map was showing before this call (including the
-- real World Map, if the player has it open) is restored afterward, so
-- this never has a visible side effect.
--
-- Returns mapFileName, textureWidth, textureHeight on success, or nil if
-- this zone isn't one the client's own zone list recognizes -- true for
-- all 7 custom Turtle WoW zones (Blackstone Island, Thalassian Highlands,
-- Northwind, Balor, Grim Reaches, Gilneas, Moonwhisper Coast), and
-- possibly for a handful of ordinary zones if their in-game name doesn't
-- match ours. Callers should fall back to the zoomed continent-crop view
-- in that case (see CreateZoomCrop below) rather than showing nothing.
--
-- textureWidth/textureHeight come straight from GetMapInfo()'s own 2nd/3rd
-- return values -- CONFIRMED 2026-08-17 in-game (via /script + AddMessage,
-- GetMapInfo() isn't reachable through /dump in this 1.12.1-era client)
-- that these vary per zone and are NOT always the ~1024x768 this file
-- used to assume everywhere: Teldrassil's real canvas is 667x768, a
-- narrower zone than the fixed map display box this addon reserves. Not
-- accounting for that was the actual cause of a spawn-point "pips look
-- offset" report -- the pips themselves were fine, they were being placed
-- against a canvas size that didn't match what was really being
-- displayed. SC.UpdateMapView now fits this real aspect ratio into the
-- display box (letterboxed/centered) instead of always stretching to
-- fill it, and RefreshMapPips positions pips against that same fitted
-- size -- see both below.
--
-- overlayTiles (4th return value) is a SEPARATE finding from the same
-- 2026-08-17 investigation: the base detail tiles this function resolves
-- are the client's "fog of unexplored" layer BY DESIGN, not a bug -- a
-- side-by-side against the real in-game World Map showed full green
-- terrain there only because pfUI's own "Reveal Unexplored Areas" map
-- module was enabled, which works by drawing extra tiles from
-- C_Map.GetMapOverlays() (a ClassicAPI extension -- see
-- ClassicAPI/docs/API.md's C_Map.GetMapOverlays section, installed
-- alongside this addon) on top of the fogged base. That API call defaults
-- to whatever zone the World Map is CURRENTLY zoomed to, which is exactly
-- the state right after SetMapZoom below -- so it's captured here, at the
-- same moment, rather than needing a separate zone lookup. ClassicAPI is
-- a separate addon and may not be installed for everyone this gets
-- shared with, so this is nil (not an error) when C_Map isn't present --
-- callers should treat a nil/empty overlayTiles as "show the fogged base
-- tiles as-is," not fail.
local zoneMapFileCache = {}
function SC.ResolveZoneMapFile(continentKey, zoneName)
    local cached = zoneMapFileCache[zoneName]
    if cached ~= nil then
        if cached == false then
            return nil
        end
        return cached.name, cached.width, cached.height, cached.overlayTiles
    end
    if not SetMapZoom or not GetMapZones or not GetMapInfo then
        return nil
    end

    local continentIndex = GetContinentIndex(continentKey)
    if not continentIndex then
        zoneMapFileCache[zoneName] = false
        return nil
    end

    -- Remember what the map was showing so we can put it back afterward.
    local savedContinent = nil
    local savedZone = nil
    if GetCurrentMapContinent then
        savedContinent = GetCurrentMapContinent()
    end
    if GetCurrentMapZone then
        savedZone = GetCurrentMapZone()
    end

    local zoneNames = { GetMapZones(continentIndex) }
    local wantLower = string.lower(zoneName)
    local zoneIndex = nil
    local i
    for i = 1, table.getn(zoneNames) do
        if zoneNames[i] == zoneName then
            zoneIndex = i
            break
        end
    end
    if not zoneIndex then
        -- Fall back to a case-insensitive, "The "-prefix-tolerant match,
        -- since the client's own zone list doesn't always match our
        -- display names exactly (e.g. possibly "Barrens" vs "The Barrens").
        for i = 1, table.getn(zoneNames) do
            local candLower = string.lower(zoneNames[i])
            if candLower == wantLower
                or candLower == string.gsub(wantLower, "^the ", "")
                or wantLower == string.gsub(candLower, "^the ", "") then
                zoneIndex = i
                break
            end
        end
    end

    local result = nil
    local resultWidth = nil
    local resultHeight = nil
    local resultOverlayTiles = nil
    if zoneIndex then
        SetMapZoom(continentIndex, zoneIndex)
        local mapFileName, texWidth, texHeight = GetMapInfo()
        if mapFileName and mapFileName ~= "" then
            result = mapFileName
            resultWidth = texWidth
            resultHeight = texHeight
            if C_Map and C_Map.GetMapOverlays then
                resultOverlayTiles = {}
                local overlays = C_Map.GetMapOverlays()
                local o
                for o = 1, table.getn(overlays) do
                    local overlay = overlays[o]
                    if overlay.textureName ~= "" and overlay.tiles then
                        local t
                        for t = 1, table.getn(overlay.tiles) do
                            table.insert(resultOverlayTiles, overlay.tiles[t])
                        end
                    end
                end
            end
        end
    end

    -- Restore whatever was showing before -- don't leave the real World
    -- Map (if open) pointed somewhere the player didn't ask for.
    if savedContinent and savedContinent > 0 then
        if savedZone and savedZone > 0 then
            SetMapZoom(savedContinent, savedZone)
        else
            SetMapZoom(savedContinent)
        end
    elseif savedContinent == 0 then
        SetMapZoom(0)
    end

    if result then
        zoneMapFileCache[zoneName] = { name = result, width = resultWidth, height = resultHeight, overlayTiles = resultOverlayTiles }
    else
        zoneMapFileCache[zoneName] = false
    end
    return result, resultWidth, resultHeight, resultOverlayTiles
end

-- Fallback for zones with no real Blizzard zone map -- reuses the same
-- continent art, scaled up by ZOOM_FACTOR and scrolled to center on the
-- zone's known x/y point (Data.lua), inside a plain (scrollbar-less)
-- ScrollFrame that clips it back down to the normal map area size. This
-- is what shows for the 7 custom Turtle WoW zones, and for anything else
-- SC.ResolveZoneMapFile couldn't match.
local ZOOM_FACTOR = 3

local function CreateZoomCrop(parent, continent, areaWidth, areaHeight)
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scroll:SetWidth(areaWidth)
    scroll:SetHeight(areaHeight)
    scroll:Hide()

    local zoomedW = areaWidth * ZOOM_FACTOR
    local zoomedH = areaHeight * ZOOM_FACTOR
    local child = CreateFrame("Frame", nil, scroll)
    child:SetWidth(zoomedW)
    child:SetHeight(zoomedH)

    local grid, textures = CreateTileGrid(child, 4, 3, zoomedW / 4, zoomedH / 3)
    SetGridTextures(textures, continent.mapFileName)

    scroll:SetScrollChild(child)
    scroll.child = child
    scroll.zoomedW = zoomedW
    scroll.zoomedH = zoomedH
    scroll.areaWidth = areaWidth
    scroll.areaHeight = areaHeight
    return scroll
end

-- Scrolls a zoom-crop frame (from CreateZoomCrop) so the given zone's x/y
-- point sits at the center of the visible area, clamped so it never
-- scrolls past the edge of the underlying continent art.
local function CenterZoomCropOnZone(scroll, zoneData)
    if not scroll or not zoneData then
        return
    end
    local targetX = (zoneData.x / 100) * scroll.zoomedW
    local targetY = (zoneData.y / 100) * scroll.zoomedH
    local offsetX = targetX - (scroll.areaWidth / 2)
    local offsetY = targetY - (scroll.areaHeight / 2)
    local maxX = scroll.zoomedW - scroll.areaWidth
    local maxY = scroll.zoomedH - scroll.areaHeight
    if offsetX < 0 then offsetX = 0 end
    if offsetY < 0 then offsetY = 0 end
    if offsetX > maxX then offsetX = maxX end
    if offsetY > maxY then offsetY = maxY end
    scroll:SetHorizontalScroll(offsetX)
    scroll:SetVerticalScroll(offsetY)
end

-- Plots spawn-point pips on the zoomed-crop fallback view (custom Turtle
-- WoW zones with no real client map -- see CreateZoomCrop above), the
-- other half of the pip feature RefreshMapPips only handles for real
-- zone maps. Uses tierData.spawnPointsContinentRelative[zoneName] --
-- CONTINENT-relative percent coordinates (0-100 across the whole
-- continent), a different data set and coordinate space than
-- spawnPoints' zone-local ones -- see the note above Moonwhisper Coast's
-- entry in Data.lua for why these two can't share one field. Pips are
-- parented to the zoom-crop's SCROLLED child frame (scroll.child), not
-- the scroll frame itself, so they pan and clip together with the map
-- art for free -- no need to track the current scroll offset here.
local function RefreshZoomCropPips(frame)
    local scroll = frame.zoomCropFrame
    if scroll.pips then
        local i
        for i = 1, table.getn(scroll.pips) do
            scroll.pips[i]:Hide()
        end
    end

    if not scroll:IsShown() then
        return
    end
    if not frame.selectedZone or not frame.selectedTier then
        return
    end

    local tierData = GetTierByKey(frame.selectedTier)
    if not tierData or not tierData.spawnPointsContinentRelative then
        return
    end
    local points = tierData.spawnPointsContinentRelative[frame.selectedZone]
    if not points or table.getn(points) == 0 then
        return
    end

    local iconPath = OctoSurvivalCompanion_Data.defaultTreeIcon
    if tierData.woodItem and tierData.woodItem.icon then
        iconPath = tierData.woodItem.icon
    end

    if not scroll.pips then
        scroll.pips = {}
    end

    local i
    for i = 1, table.getn(points) do
        local pip = scroll.pips[i]
        if not pip then
            pip = scroll.child:CreateTexture(nil, "OVERLAY")
            pip:SetWidth(PIP_SIZE)
            pip:SetHeight(PIP_SIZE)
            scroll.pips[i] = pip
        end
        pip:SetTexture(iconPath)
        local point = points[i]
        local px = scroll.zoomedW * (point[1] / 100)
        local py = -(scroll.zoomedH * (point[2] / 100))
        pip:ClearAllPoints()
        pip:SetPoint("CENTER", scroll.child, "TOPLEFT", px, py)
        pip:Show()
    end
end

local mapSubTabButtons = {}
local mapContinentFrames = {}

-- Updates the info line under a continent's two dropdowns to reflect
-- whatever combination of tree tier / zone is currently picked on it.
function SC.RefreshMapInfoText(frame)
    if not frame or not frame.infoText then
        return
    end

    local zoneName = frame.selectedZone
    local tierKey = frame.selectedTier

    if zoneName then
        -- A specific zone is picked -- show what grows there (Data.lua's
        -- zones[].tiers), independent of whatever the tree dropdown says.
        local zoneData = FindZoneData(zoneName)
        local tiersText = "none on file"
        if zoneData and zoneData.tiers and table.getn(zoneData.tiers) > 0 then
            local names = {}
            local i
            for i = 1, table.getn(zoneData.tiers) do
                local tKey = zoneData.tiers[i]
                local label = tKey .. " Wood"
                local tData = GetTierByKey(tKey)
                if tData and tData.zoneCounts and tData.zoneCounts[zoneName] and tData.zoneCounts[zoneName] <= RARE_ZONE_THRESHOLD then
                    label = label .. " (rare)"
                end
                table.insert(names, label)
            end
            tiersText = JoinList(names)
        end
        local approxNote = ""
        if zoneData and zoneData.approxLocation then
            approxNote = " |cff888888(approximate placement)|r"
        end
        frame.infoText:SetText(zoneName .. approxNote .. " grows: " .. tiersText)
    elseif tierKey then
        -- A tree tier is picked but no specific zone -- list which of
        -- this continent's zones are actually worth farming it in (the
        -- zone dropdown above is filtered the exact same way -- see
        -- BuildZoneDropdownList): grows this tier AND isn't a confirmed
        -- rare/low-count spot (IsZoneRareForTier). Rare zones still show
        -- up if you pick them directly from "All Zones" or via a tree-bar
        -- tooltip -- this view specifically is "where should I go to
        -- farm this."
        local tier = GetTierByKey(tierKey)
        local zoneNames = {}
        local growsAtAllHere = false
        if OctoSurvivalCompanion_Data and OctoSurvivalCompanion_Data.zones then
            local i
            for i = 1, table.getn(OctoSurvivalCompanion_Data.zones) do
                local z = OctoSurvivalCompanion_Data.zones[i]
                if z.continent == frame.continentKey and z.tiers then
                    local j
                    for j = 1, table.getn(z.tiers) do
                        if z.tiers[j] == tierKey then
                            growsAtAllHere = true
                            if not IsZoneRareForTier(tier, z.name) then
                                table.insert(zoneNames, z.name)
                            end
                        end
                    end
                end
            end
        end
        local skillText = "unconfirmed"
        if tier and tier.level then
            skillText = tier.level
        end
        if table.getn(zoneNames) == 0 then
            if growsAtAllHere then
                frame.infoText:SetText(tierKey .. " Wood only grows here in small/rare amounts -- pick \"All Zones\" and a specific zone to see them.")
            else
                frame.infoText:SetText(tierKey .. " Wood doesn't grow on this continent -- try the other one.")
            end
        else
            frame.infoText:SetText(tierKey .. " Wood (skill " .. skillText .. "): " .. JoinList(zoneNames))
        end
    else
        frame.infoText:SetText("Pick a tree and/or a zone above to see chop details.")
    end
end

local PIP_SIZE = 10
-- Compresses pips' effective vertical range down to 0-88% instead of
-- 0-100% -- see the note where this is used in RefreshMapPips for why
-- (a tuned approximation for a mismatch between octowow.st's own
-- coordinate authoring and Blizzard's real canvas, not a bug in this
-- addon's own map-reading code).
local PIP_Y_SCALE = 0.88

-- Plots one "pip" per individual spawn point Data.lua has on file for the
-- currently picked tier over a zone's own client map (frame.zoneMapFrame)
-- -- tierData.spawnPoints[zoneName], zone-local percent coordinates
-- (0-100), see the note above Star Wood's spawnPoints in Data.lua for
-- where this data actually comes from. Each pip uses that tier's own wood
-- icon (tierData.woodItem.icon, e.g. Interface\Icons\star_log_2), falling
-- back to the generic defaultTreeIcon for tiers without one (Dead Wood
-- Tree has no wood item of its own) -- ADDED 2026-08-17, replacing a flat
-- gold WHITE8X8 dot so a pip's icon identifies which tree it is at a
-- glance, not just its color. These are the SAME custom icon paths the
-- tree-chop tracker bar tried and pulled back out (see the note above
-- CreateTreeBar) after showing up blank in game for a cause that was
-- never pinned down -- worth revisiting this if pips come up blank too,
-- since that'd point at the icon paths themselves rather than anything
-- about how the tracker bar specifically drew them.
--
-- Pips are pooled per continent frame (frame.mapPips) and reused/hidden
-- rather than recreated, same pattern as the recipe rows elsewhere in
-- this file -- a busy zone like Winterspring is 200+ points, no sense
-- rebuilding that every time the picker changes. Only the icon texture
-- itself is re-set on every refresh (cheap, and needed since the same
-- pooled pip frames get reused across different tiers).
--
-- Deliberately only wired up for the real-zone-map view. The zoomed-crop
-- fallback (custom Turtle WoW zones) uses a different, continent-relative
-- coordinate space that these zone-local points don't line up with -- see
-- the Moonwhisper Coast note in Data.lua.
local function RefreshMapPips(frame)
    if frame.mapPips then
        local i
        for i = 1, table.getn(frame.mapPips) do
            frame.mapPips[i]:Hide()
        end
    end

    if not frame.zoneMapFrame or not frame.zoneMapFrame:IsShown() then
        return
    end
    if not frame.selectedZone or not frame.selectedTier then
        return
    end

    local tierData = GetTierByKey(frame.selectedTier)
    if not tierData or not tierData.spawnPoints then
        return
    end
    local points = tierData.spawnPoints[frame.selectedZone]
    if not points or table.getn(points) == 0 then
        return
    end

    local iconPath = OctoSurvivalCompanion_Data.defaultTreeIcon
    if tierData.woodItem and tierData.woodItem.icon then
        iconPath = tierData.woodItem.icon
    end

    if not frame.mapPips then
        frame.mapPips = {}
    end

    local i
    for i = 1, table.getn(points) do
        local pip = frame.mapPips[i]
        if not pip then
            pip = frame.zoneMapFrame:CreateTexture(nil, "OVERLAY")
            pip:SetWidth(PIP_SIZE)
            pip:SetHeight(PIP_SIZE)
            frame.mapPips[i] = pip
        end
        pip:SetTexture(iconPath)
        local point = points[i]
        local renderWidth = frame.zoneMapRenderWidth or frame.mapWidth
        local renderHeight = frame.zoneMapRenderHeight or frame.mapHeight
        local px = renderWidth * (point[1] / 100)
        -- PIP_Y_SCALE ADDED 2026-08-17 -- a side-by-side against
        -- octowow.st showed pips drifting further south than their real
        -- spots the further south they already were (Starbreeze-area pips
        -- noticeably lower relative to that label on our render than on
        -- theirs), while the TERRAIN ART lined up fine -- since the
        -- terrain comes from Blizzard's own client tiles but the pip
        -- coordinates come from octowow.st's scraped data, this points at
        -- octowow.st's own coordinate authoring using a slightly different
        -- vertical crop/extent than Blizzard's real canvas, not a bug in
        -- how this addon reads Blizzard's map data. This is a tuned
        -- approximation (see PIP_Y_SCALE above), not a value derived from
        -- a hard measurement -- nudge it if future comparisons show it
        -- over- or under-correcting.
        local py = -(renderHeight * PIP_Y_SCALE * (point[2] / 100))
        pip:ClearAllPoints()
        pip:SetPoint("CENTER", frame.zoneMapFrame, "TOPLEFT", px, py)
        pip:Show()
    end
end

-- Draws the "reveal" overlay tiles (C_Map.GetMapOverlays(), see the note
-- above SC.ResolveZoneMapFile) on top of the base fogged tiles, so the
-- zone map shows its real terrain colors regardless of how much of the
-- zone the player has actually explored -- same idea as pfUI's own
-- "Reveal Unexplored Areas" map-reveal module, just always-on rather than
-- a toggle, since this addon's whole point is showing chop spots you
-- haven't necessarily been to yet. Overlay tile positions/sizes come back
-- from the API in the zone's NATIVE canvas pixels (texWidth x
-- texHeight -- the same GetMapInfo() values SC.UpdateMapView fits into
-- its display box), so they're scaled here to match whatever size this
-- addon is actually rendering the zone map at (renderWidth x
-- renderHeight). Draws on the BORDER layer -- above the base BACKGROUND
-- tiles, below the ARTWORK/OVERLAY-layer pips, so it can never cover them.
-- No-ops cleanly (leaving the base fogged tiles as the only thing shown)
-- when overlayTiles is nil -- either ClassicAPI isn't installed (a
-- separate addon this doesn't require), or this zone genuinely has no
-- overlay data on file.
-- The base tile grid (CreateTileGrid/ResizeTileGrid) always divides
-- renderWidth/renderHeight evenly into a 4x3 grid, with NO reference to
-- texWidth/texHeight at all -- that grid implicitly represents the
-- standard 1024x768 12-tile canvas (4 cols x 256px, 3 rows x 256px)
-- stretched to fill the render box, regardless of how much of that
-- canvas any given zone's real content occupies. Overlay tiles need that
-- SAME reference to line up with it.
local OVERLAY_CANVAS_WIDTH = 1024
local OVERLAY_CANVAS_HEIGHT = 768

local function RefreshMapOverlay(frame, overlayTiles, texWidth, texHeight, renderWidth, renderHeight)
    if frame.revealTiles then
        local i
        for i = 1, table.getn(frame.revealTiles) do
            frame.revealTiles[i]:Hide()
        end
    end
    if not overlayTiles or table.getn(overlayTiles) == 0 then
        return
    end

    if not frame.revealTiles then
        frame.revealTiles = {}
    end

    -- BUG FIXED 2026-08-17 -- this used to scale by renderWidth/texWidth
    -- (the zone's OWN used-canvas size, e.g. 667 for Teldrassil), a
    -- DIFFERENT reference than what the base tiles above use -- that
    -- mismatch is what caused a "two maps stacked, one revealed one not,
    -- bleeding past the frame" report: the overlay was being scaled up
    -- more than the base tiles (667 is smaller than the 1024 the base
    -- grid implies), so the "revealed" layer rendered visibly bigger and
    -- offset from the terrain underneath it instead of lining up.
    local scaleX = renderWidth / OVERLAY_CANVAS_WIDTH
    local scaleY = renderHeight / OVERLAY_CANVAS_HEIGHT

    -- Bounds check ADDED 2026-08-17 -- a report of "a big green patch
    -- bleeding off the right edge of the map" traced to specific overlay
    -- entries whose offsetX/offsetY (or width/height) don't actually fall
    -- within this zone's own texWidth x texHeight canvas -- most likely
    -- overlays for a boundary-adjacent connecting area rather than bad
    -- scale math (most tiles DO line up with the visible terrain). Rather
    -- than guess at which specific field is wrong per overlay, skip
    -- drawing any tile whose scaled box would land mostly outside this
    -- zone's own render area -- losing a little coverage at zone edges is
    -- far better than a giant mispositioned rectangle covering the map.
    local i
    for i = 1, table.getn(overlayTiles) do
        local t = overlayTiles[i]
        local px = t.offsetX * scaleX
        local py = t.offsetY * scaleY
        local w = t.width * scaleX
        local h = t.height * scaleY
        local tex = frame.revealTiles[i]
        if px + w < 0 or px > renderWidth or py + h < 0 or py > renderHeight then
            if tex then
                tex:Hide()
            end
        else
            if not tex then
                tex = frame.zoneMapFrame:CreateTexture(nil, "BORDER")
                frame.revealTiles[i] = tex
            end
            tex:SetTexture(t.file)
            tex:SetTexCoord(0, t.texCoordX, 0, t.texCoordY)
            tex:SetWidth(w)
            tex:SetHeight(h)
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", frame.zoneMapFrame, "TOPLEFT", px, -py)
            tex:Show()
        end
    end
end

-- Switches the map art below the pickers to match the current zone pick:
-- no zone selected -> the plain continent view; a zone selected and the
-- client recognizes it -> that zone's own map (SC.ResolveZoneMapFile);
-- a zone selected but unrecognized (all 7 custom Turtle WoW zones, plus
-- anything else that doesn't match) -> a zoomed-in crop of the continent
-- centered on that zone's known x/y, so there's always SOME useful view
-- rather than a blank frame.
function SC.UpdateMapView(frame)
    if not frame.plainMapFrame then
        return
    end

    if not frame.selectedZone then
        frame.plainMapFrame:Show()
        frame.zoneMapFrame:Hide()
        frame.zoomCropFrame:Hide()
        frame.mapCaption:SetText("")
        RefreshMapOverlay(frame, nil)
        RefreshMapPips(frame)
        RefreshZoomCropPips(frame)
        return
    end

    local mapFileName, texWidth, texHeight, overlayTiles = SC.ResolveZoneMapFile(frame.continentKey, frame.selectedZone)
    if mapFileName then
        SetGridTextures(frame.zoneMapTextures, mapFileName)

        -- REVERTED AGAIN 2026-08-17 -- letterboxing to GetMapInfo()'s
        -- texWidth/texHeight ratio (667x768 for Teldrassil, a narrow
        -- portrait shape) turned out to be based on a wrong assumption.
        -- A side-by-side against the real in-game World Map showed
        -- Teldrassil's actual displayed landmass is clearly WIDER than
        -- tall -- the opposite of what a 667x768 fit would produce.
        -- texWidth/texHeight is very likely just the tile canvas's raw
        -- resolution, not the shape the client actually displays a zone
        -- at -- the real WorldMapDetailFrame (what C_Map.GetMapOverlays()
        -- tile offsets are anchored to) stretches to fill whatever window
        -- it's given, same as this addon's own fixed map box. So: stretch
        -- to fill again, and -- important -- RefreshMapOverlay below is
        -- passed these SAME renderWidth/renderHeight values, so the
        -- reveal tiles stay scaled consistently with the base tiles no
        -- matter what this box's own shape is.
        local renderWidth = frame.mapWidth
        local renderHeight = frame.mapHeight
        ResizeTileGrid(frame.zoneMapFrame, frame.zoneMapTextures, 4, 3, renderWidth / 4, renderHeight / 3)
        frame.zoneMapFrame:ClearAllPoints()
        frame.zoneMapFrame:SetPoint("TOPLEFT", frame.mapArea, "TOPLEFT", 0, 0)
        frame.zoneMapRenderWidth = renderWidth
        frame.zoneMapRenderHeight = renderHeight
        RefreshMapOverlay(frame, overlayTiles, texWidth, texHeight, renderWidth, renderHeight)

        frame.plainMapFrame:Hide()
        frame.zoneMapFrame:Show()
        frame.zoomCropFrame:Hide()
        frame.mapCaption:SetText(frame.selectedZone .. "'s own map")
        RefreshZoomCropPips(frame)
    else
        RefreshMapOverlay(frame, nil)
        local zoneData = FindZoneData(frame.selectedZone)
        CenterZoomCropOnZone(frame.zoomCropFrame, zoneData)
        frame.plainMapFrame:Hide()
        frame.zoneMapFrame:Hide()
        frame.zoomCropFrame:Show()
        frame.mapCaption:SetText("No client map for this zone -- zoomed continent view")
        RefreshZoomCropPips(frame)
    end
    RefreshMapPips(frame)
end

-- Picking a tree tier filters the zone dropdown down to just the zones on
-- this continent that grow it. Changing the tier can invalidate whatever
-- zone was already picked, so it resets back to "All Zones" every time --
-- simpler and less surprising than trying to silently keep/drop a stale
-- pick.
function SC.MapSelectTier(frame, tierKey)
    frame.selectedTier = tierKey
    frame.selectedZone = nil
    if tierKey then
        UIDropDownMenu_SetText(tierKey .. " Wood", frame.treeDropdown)
    else
        UIDropDownMenu_SetText("All Trees", frame.treeDropdown)
    end
    UIDropDownMenu_SetText("All Zones", frame.zoneDropdown)
    SC.RefreshMapInfoText(frame)
    SC.UpdateMapView(frame)
end

function SC.MapSelectZone(frame, zoneName)
    frame.selectedZone = zoneName
    if zoneName then
        UIDropDownMenu_SetText(zoneName, frame.zoneDropdown)
    else
        UIDropDownMenu_SetText("All Zones", frame.zoneDropdown)
    end
    SC.RefreshMapInfoText(frame)
    SC.UpdateMapView(frame)
end

-- Rebuilds the "Tree" dropdown's option list -- called every time the
-- dropdown is opened (UIDropDownMenu_Initialize's initFunction is
-- re-invoked on each open, so this always reflects the current data).
--
-- 2026-08-16: each tier's required Survival skill is printed right in its
-- button label (e.g. "Star Wood (skill 30)") instead of a hover tooltip.
-- An earlier version of this showed it as a real GameTooltip on hover, but
-- vanilla 1.12.1's dropdown buttons are POOLED and shared globally by
-- every dropdown menu in the game (e.g. DropDownList1Button3 gets reused
-- by whatever dropdown next needs a 3rd option -- ours or anyone else's),
-- and the client has no built-in way to show a real tooltip there (its
-- own default OnEnter only fires GameTooltip_AddNewbieTip, which silently
-- does nothing unless the player has "Show Newbie Tips" on) -- showing a
-- reliable one meant overriding OnEnter/OnLeave on those shared buttons
-- ourselves, extra surface area for a fairly small payoff. Plain text in
-- the label gets the same information across with none of that.
local function BuildTreeDropdownList(frame)
    local info = {}
    info.text = "All Trees"
    info.notCheckable = 1
    info.func = function() SC.MapSelectTier(frame, nil) end
    UIDropDownMenu_AddButton(info)

    if OctoSurvivalCompanion_Data and OctoSurvivalCompanion_Data.woodTiers then
        -- 2026-08-16: listed by required skill level (ascending) rather
        -- than woodTiers' own declaration order in Data.lua -- e.g. Dead
        -- Wood (skill 250) now lists before Star Wood (skill 270) even
        -- though Star is declared first in that table. Sorted on a COPY
        -- of the tier list, not woodTiers itself, so anything else that
        -- indexes woodTiers by position (FindTierByKey and friends) is
        -- unaffected. Unconfirmed levels (nil) sort last.
        local sorted = {}
        local i
        for i = 1, table.getn(OctoSurvivalCompanion_Data.woodTiers) do
            table.insert(sorted, OctoSurvivalCompanion_Data.woodTiers[i])
        end
        table.sort(sorted, function(a, b)
            local la = a.level
            local lb = b.level
            if not la then la = 999999 end
            if not lb then lb = 999999 end
            return la < lb
        end)

        for i = 1, table.getn(sorted) do
            local tierData = sorted[i]
            local tierKey = tierData.tier
            local skillText = "unconfirmed"
            if tierData.level then
                skillText = tierData.level
            end
            info = {}
            info.text = tierKey .. " Wood (skill " .. skillText .. ")"
            info.notCheckable = 1
            info.func = function() SC.MapSelectTier(frame, tierKey) end
            UIDropDownMenu_AddButton(info)
        end
    end
end

-- Rebuilds the "Zone" dropdown's option list -- every zone on THIS
-- continent that grows the currently selected tree tier (if any).
--
-- 2026-08-16: a confirmed rare/low-count zone for that tier
-- (IsZoneRareForTier, e.g. Balor's 3 known Bright Wood spawns) used to be
-- left out of this list entirely. It's shown again now, but flagged --
-- its count gets ", might be spillover" tacked on (e.g. "Darkshore (2,
-- might be spillover)") instead of disappearing, so you can still see and
-- pick it, just with a clear heads-up that a count this low might be a
-- database boundary artifact rather than its own real population. (Some
-- of these specific low counts were individually re-verified as genuine
-- rather than spillover -- see the note above woodTiers in Data.lua --
-- but that confirmation doesn't apply to every low count on file, so the
-- caveat stays generic here rather than claiming more than is known
-- zone-by-zone.) The farmability filtering itself lives on elsewhere --
-- GetFarmableZones still leaves these out of the tree-bar tooltip's
-- "Choppable in" line and the click-to-jump target search, so this addon
-- still never *recommends* a spillover-suspect zone, it just no longer
-- hides that the option exists.
local function BuildZoneDropdownList(frame)
    local info = {}
    info.text = "All Zones"
    info.notCheckable = 1
    info.func = function() SC.MapSelectZone(frame, nil) end
    UIDropDownMenu_AddButton(info)

    local tierData = nil
    -- When a tier is picked, every zone left in this list grows THAT
    -- tier (that's what the filtering above already guarantees), so its
    -- icon is unambiguous -- tack it on after each zone's name via the
    -- |T..|t inline-texture escape (plain FontString markup, works in
    -- dropdown button text same as anywhere else). "All Zones" (no tier
    -- picked) leaves it off, since a zone can carry 2-3 different tiers
    -- and there'd be no single "appropriate" one to show.
    local tierIconMarkup = ""
    if frame.selectedTier then
        tierData = GetTierByKey(frame.selectedTier)
        local iconPath = GetTierIconPath(tierData)
        if iconPath then
            tierIconMarkup = " |T" .. iconPath .. ":14|t"
        end
    end

    if OctoSurvivalCompanion_Data and OctoSurvivalCompanion_Data.zones then
        local i
        for i = 1, table.getn(OctoSurvivalCompanion_Data.zones) do
            local zone = OctoSurvivalCompanion_Data.zones[i]
            if zone.continent == frame.continentKey then
                local include = true
                if frame.selectedTier then
                    include = false
                    local j
                    for j = 1, table.getn(zone.tiers) do
                        if zone.tiers[j] == frame.selectedTier then
                            include = true
                        end
                    end
                end
                if include then
                    local zoneName = zone.name
                    -- Known spawn count for the selected tier, shown right
                    -- after its icon (e.g. "Winterspring [icon] (14)") --
                    -- left off for "All Zones" (no single tier to count)
                    -- and for zones with no confirmed count on file (see
                    -- the note above woodTiers in Data.lua -- unknown
                    -- isn't the same claim as zero). A confirmed rare/
                    -- low-count zone (IsZoneRareForTier) gets ", might be
                    -- spillover" tacked on instead, e.g. "(2, might be
                    -- spillover)" -- see the note above this function.
                    local countMarkup = ""
                    if tierData and tierData.zoneCounts and tierData.zoneCounts[zoneName] then
                        local count = tierData.zoneCounts[zoneName]
                        if IsZoneRareForTier(tierData, zoneName) then
                            countMarkup = " (" .. count .. ", might be spillover)"
                        else
                            countMarkup = " (" .. count .. ")"
                        end
                    end
                    info = {}
                    info.text = zoneName .. tierIconMarkup .. countMarkup
                    info.notCheckable = 1
                    info.func = function() SC.MapSelectZone(frame, zoneName) end
                    UIDropDownMenu_AddButton(info)
                end
            end
        end
    end
end

local function CreateContinentMap(parent, continent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    frame:Hide()
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    })
    frame:SetBackdropColor(0.05, 0.05, 0.08, 1)
    frame.continentKey = continent.key

    -- Tree tier / zone picker dropdowns ---------------------------------
    local treeDropdown = CreateFrame("Frame", "OctoSurvivalCompanionMapTreeDrop" .. continent.key, frame, "UIDropDownMenuTemplate")
    treeDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", -12, -2)
    UIDropDownMenu_SetWidth(110, treeDropdown)
    UIDropDownMenu_SetText("All Trees", treeDropdown)
    frame.treeDropdown = treeDropdown

    local zoneDropdown = CreateFrame("Frame", "OctoSurvivalCompanionMapZoneDrop" .. continent.key, frame, "UIDropDownMenuTemplate")
    zoneDropdown:SetPoint("TOPLEFT", frame, "TOPLEFT", 158, -2)
    UIDropDownMenu_SetWidth(190, zoneDropdown)
    UIDropDownMenu_SetText("All Zones", zoneDropdown)
    frame.zoneDropdown = zoneDropdown

    UIDropDownMenu_Initialize(treeDropdown, function() BuildTreeDropdownList(frame) end)
    UIDropDownMenu_Initialize(zoneDropdown, function() BuildZoneDropdownList(frame) end)

    -- Info line: what the current tree/zone picks resolve to. One
    -- wrapping FontString rather than a scroll list -- even the longest
    -- zone list (Simple Wood, 16 zones) fits in a few wrapped lines at
    -- this width.
    local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    infoText:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -34)
    infoText:SetWidth(PANEL_WIDTH - 12)
    infoText:SetJustifyH("LEFT")
    infoText:SetJustifyV("TOP")
    frame.infoText = infoText

    -- Map area, shifted down to make room for the picker row and info
    -- line above. Three interchangeable views live in here, toggled by
    -- SC.UpdateMapView based on the current zone pick: the plain
    -- continent grid (default), a per-zone map grid (retargeted to
    -- whatever zone is picked, when the client recognizes it), and a
    -- zoomed continent crop (fallback for zones the client doesn't
    -- recognize -- all 7 custom Turtle WoW zones).
    local mapTop = 108 -- picker row + info line reserve, in pixels
    local mapWidth = PANEL_WIDTH
    local mapHeight = (PANEL_HEIGHT - 26) - mapTop

    local mapArea = CreateFrame("Frame", nil, frame)
    mapArea:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -mapTop)
    mapArea:SetWidth(mapWidth)
    mapArea:SetHeight(mapHeight)
    frame.mapArea = mapArea
    frame.mapWidth = mapWidth
    frame.mapHeight = mapHeight

    local tileW = mapWidth / 4
    local tileH = mapHeight / 3

    local plainGrid, plainTextures = CreateTileGrid(mapArea, 4, 3, tileW, tileH)
    SetGridTextures(plainTextures, continent.mapFileName)
    frame.plainMapFrame = plainGrid

    local zoneGrid, zoneTextures = CreateTileGrid(mapArea, 4, 3, tileW, tileH)
    zoneGrid:Hide()
    frame.zoneMapFrame = zoneGrid
    frame.zoneMapTextures = zoneTextures

    frame.zoomCropFrame = CreateZoomCrop(mapArea, continent, mapWidth, mapHeight)

    local mapCaption = mapArea:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    mapCaption:SetPoint("BOTTOMRIGHT", mapArea, "BOTTOMRIGHT", -4, 4)
    mapCaption:SetJustifyH("RIGHT")
    frame.mapCaption = mapCaption

    SC.RefreshMapInfoText(frame)
    SC.UpdateMapView(frame)

    return frame
end

local function ShowMapContinent(key)
    local i
    for i = 1, table.getn(MAP_CONTINENTS) do
        if MAP_CONTINENTS[i].key == key then
            mapContinentFrames[i]:Show()
            mapSubTabButtons[i]:Disable()
        else
            mapContinentFrames[i]:Hide()
            mapSubTabButtons[i]:Enable()
        end
    end
end
SC.ShowMapContinent = ShowMapContinent

local function CreateMapPanel(parent)
    local i
    for i = 1, table.getn(MAP_CONTINENTS) do
        local btn = CreateFrame("Button", "OctoSurvivalCompanionMapTab" .. i, parent, "UIPanelButtonTemplate")
        btn:SetWidth(140)
        btn:SetHeight(20)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", (i - 1) * 148, 0)
        btn:SetText(MAP_CONTINENTS[i].label)
        btn.continentKey = MAP_CONTINENTS[i].key
        btn:SetScript("OnClick", function()
            ShowMapContinent(this.continentKey)
        end)
        mapSubTabButtons[i] = btn

        local mapHolder = CreateFrame("Frame", nil, parent)
        mapHolder:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -26)
        mapHolder:SetWidth(PANEL_WIDTH)
        mapHolder:SetHeight(PANEL_HEIGHT - 26)
        mapContinentFrames[i] = CreateContinentMap(mapHolder, MAP_CONTINENTS[i])
    end
    ShowMapContinent("Kalimdor")
end

-- Clicking a tree-bar icon jumps straight to that tree's tier on the Map
-- tab: switches to the Map tab, flips to the right continent, prints the
-- zone + full chop list to chat, and -- if TomTom is loaded -- makes a
-- best-effort attempt at a waypoint too. (The Map tab itself no longer has
-- per-zone dots to flash -- see the note above CreateContinentMap -- so
-- this is chat-line + continent-switch only for now.)
--
-- 2026-08-16: the search now runs over GetFarmableZones(tier) (confirmed
-- non-rare zones only) instead of the raw chopZones list -- same "clean,
-- easy zones to farm" filtering the Map tab's zone dropdown already
-- applies -- and only falls back to the full rare-included list if this
-- tier has no confirmed-good zone on file at all, so it never silently
-- recommends a 3-spawn zone when a better one exists.
--
-- Target zone is picked in this order:
--   1. Your current zone, if this tier grows there in worthwhile amounts
--      -- zero travel, always wins.
--   2. Otherwise, the NEAREST farmable zone on your CURRENT continent --
--      straight-line distance between each zone's continent-percent x/y
--      point in Data.lua. This is "closest on the map," not a real
--      travel-time/pathing calculation (no route data exists to do
--      better), but it's right far more often than wrong and needs no
--      extra data beyond what's already there.
--   3. If nothing farmable on your current continent grows it (or your
--      current zone isn't one this addon has map data for, e.g. an
--      instance), fall back to the MOST POPULATED farmable zone overall,
--      using each tier's zoneCounts table (approximate, partial -- see
--      the note above woodTiers in Data.lua).
--   4. If none of the above resolve anything (no zone data for your
--      current zone AND no zoneCounts for this tier), fall back to the
--      first farmable zone, or -- if this tier has no confirmed-good zone
--      at all -- the first zone in the raw chopZones list, same as this
--      feature's original, simpler behavior.
function SC.JumpToTreeOnMap(treeName)
    if not treeName or not SC.GetTierForTree then
        return
    end
    local tier = SC.GetTierForTree(treeName)
    if not tier or not tier.chopZones or table.getn(tier.chopZones) == 0 then
        if SC.Print then
            SC.Print(treeName .. " -- no known chop zones on file yet.")
        end
        return
    end

    local currentZone = nil
    if GetRealZoneText then
        currentZone = GetRealZoneText()
    end

    -- Search among confirmed non-rare zones first (GetFarmableZones), so
    -- this always recommends somewhere actually worth the trip -- only
    -- fall back to the full chopZones list (rare spots included) if this
    -- tier has no confirmed-good zone on file at all.
    local searchZones = GetFarmableZones(tier)
    local usedRareFallback = false
    if table.getn(searchZones) == 0 then
        searchZones = tier.chopZones
        usedRareFallback = true
    end

    local targetZoneName = nil
    local pickNote = "" -- appended to the chat line so it's clear why this zone was picked

    -- 1. Current zone, if it grows this tier (and is worth farming).
    if currentZone then
        local i
        for i = 1, table.getn(searchZones) do
            if searchZones[i] == currentZone then
                targetZoneName = currentZone
            end
        end
    end

    -- 2. Nearest zone on your current continent.
    if not targetZoneName then
        local originData = FindZoneData(currentZone)
        if originData then
            local bestDist = nil
            local i
            for i = 1, table.getn(searchZones) do
                local candidate = FindZoneData(searchZones[i])
                if candidate and candidate.continent == originData.continent then
                    local dx = candidate.x - originData.x
                    local dy = candidate.y - originData.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if not bestDist or dist < bestDist then
                        bestDist = dist
                        targetZoneName = candidate.name
                    end
                end
            end
            if targetZoneName then
                pickNote = " (nearest on your continent)"
            end
        end
    end

    -- 3. Most populated zone overall (only reached if nothing on your
    -- current continent grows this tier, or your current zone has no
    -- map data at all).
    if not targetZoneName and tier.zoneCounts then
        local bestCount = nil
        local i
        for i = 1, table.getn(searchZones) do
            local zname = searchZones[i]
            local count = tier.zoneCounts[zname]
            if count and (not bestCount or count > bestCount) then
                bestCount = count
                targetZoneName = zname
            end
        end
        if targetZoneName then
            pickNote = " (most populated known)"
        end
    end

    -- 4. Last resort.
    if not targetZoneName then
        targetZoneName = searchZones[1]
    end

    local zoneData = FindZoneData(targetZoneName)

    -- mainFrame always exists by the time this runs -- it's only reachable
    -- by clicking a tree-bar icon, and the tree bar itself is only built
    -- as part of BuildUI().
    mainFrame:Show()
    SC.ShowTab(1) -- Map tab
    if zoneData and SC.ShowMapContinent then
        SC.ShowMapContinent(zoneData.continent)
    end

    if SC.Print then
        local listText
        if usedRareFallback then
            listText = "only small/rare spots on file -- " .. JoinListAnnotated(tier.chopZones, nil, tier.zoneCounts)
        else
            listText = JoinList(searchZones)
        end
        SC.Print(tier.tier .. " Wood -- try " .. targetZoneName .. pickNote .. ". Farmable zones: " .. listText)
    end

    -- TomTom integration is EXPERIMENTAL and unconfirmed against any real
    -- TomTom build on these servers: our zone x/y are percentage positions
    -- on the CONTINENT map image (0-100), which is what this addon's own
    -- Map tab uses, but TomTom's AddWaypoint normally expects coordinates
    -- within a single ZONE map, not the continent. There's no reliable
    -- zone-level coordinate data to source that from here. Wrapped in
    -- pcall so a mismatched API just fails quietly -- the chat line above
    -- is the reliable fallback either way.
    local tomtomAllowed = not OctoSurvivalCompanionDB or OctoSurvivalCompanionDB.useTomTom ~= false
    if tomtomAllowed and TomTom and TomTom.AddWaypoint and zoneData then
        local continentIndex = 1
        if zoneData.continent == "EasternKingdoms" then
            continentIndex = 2
        end
        local ok = pcall(function()
            TomTom:AddWaypoint(continentIndex, nil, zoneData.x, zoneData.y, {
                title = targetZoneName .. " -- " .. tier.tier .. " Wood",
                persistent = false,
            })
        end)
        if not ok and SC.Print then
            SC.Print("(TomTom waypoint attempt failed -- its API may not match what this addon guessed; the chat location above is still accurate.)")
        end
    end
end

-- ============================================================
-- Tab switching / init
-- ============================================================

function SC.ShowTab(index)
    local i
    for i = 1, table.getn(panels) do
        panels[i]:Hide()
        tabButtons[i]:Enable()
    end
    panels[index]:Show()
    tabButtons[index]:Disable()
end

-- Recipes and Gardening tabs are pulled for now (2026-08-15) while we
-- focus on the Map tab -- CreateRecipeScroll/BuildRecipeTooltip/
-- CreateGardeningPanel and the known-recipe checklist (SC.RefreshUI,
-- SC.ToggleKnown/SC.IsKnown in Core.lua) are left in place, just unwired
-- from BuildUI below, so they're a straight re-add (new tab + xOffset +
-- one CreateXScroll/Panel(panels[n]) call) rather than a rewrite if they
-- come back. The underlying Data.lua recipes/gardening tables aren't
-- touched at all.
local function BuildUI()
    mainFrame = CreateMainFrame()

    local labels = { "Map", "Trainers", "Logbook", "Guide" }
    local xOffsets = { 14, 126, 238, 350 }
    local i
    for i = 1, table.getn(labels) do
        tabButtons[i] = CreateTabButton(mainFrame, i, labels[i], xOffsets[i])
    end

    for i = 1, table.getn(labels) do
        panels[i] = CreatePanel(mainFrame)
    end

    CreateMapPanel(panels[1])
    CreateTrainersPanel(panels[2])
    CreateLogbookPanel(panels[3])
    CreateGuidePanel(panels[4])
    CreateTreeBar(mainFrame)

    SC.ShowTab(1)
    SC.RefreshUI()
    SC.RefreshTreeBar()
end

function SC.ToggleFrame()
    if not mainFrame then
        BuildUI()
    end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        SC.RefreshUI()
        SC.RefreshTreeBar()
        mainFrame:Show()
    end
end

-- ============================================================
-- Minimap button
--
-- Hand-rolled rather than a LibDBIcon-style library (nothing like that
-- ships in the 1.12.1 era this addon targets) -- drag-around-the-rim plus
-- click-to-toggle, same pattern most Turtle WoW-era addons use. Position
-- is stored as an angle in degrees (OctoSurvivalCompanionDB.minimapAngle)
-- rather than raw x/y, so it stays correct even if the minimap itself gets
-- resized (e.g. by pfUI, which is common in this addon list).
-- ============================================================

local minimapButton

local function UpdateMinimapButtonPosition()
    if not minimapButton then
        return
    end
    local angle = math.rad(OctoSurvivalCompanionDB.minimapAngle or 200)
    local radius = (Minimap:GetWidth() / 2) or 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function SC.CreateMinimapButton()
    if minimapButton or not Minimap then
        return
    end
    SC.InitDB()

    local btn = CreateFrame("Button", "OctoSurvivalCompanionMinimapButton", Minimap)
    btn:SetWidth(31)
    btn:SetHeight(31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetWidth(53)
    border:SetHeight(53)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 7, -6)
    -- Same fallback log icon used throughout Data.lua (defaultTreeIcon) --
    -- a standard vanilla icon file, not one of the server's custom item
    -- icons, so it's guaranteed to exist even if a custom texture doesn't.
    icon:SetTexture("Interface\\Icons\\INV_Misc_Log_02")

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetWidth(31)
    highlight:SetHeight(31)
    highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    btn:SetScript("OnDragStart", function()
        this:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px = px / scale
            py = py / scale
            OctoSurvivalCompanionDB.minimapAngle = math.deg(math.atan2(py - my, px - mx))
            UpdateMinimapButtonPosition()
        end)
    end)
    btn:SetScript("OnDragStop", function()
        this:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnClick", function()
        if SC.ToggleFrame then
            SC.ToggleFrame()
        end
    end)

    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:AddLine("Octo Survival Companion")
        GameTooltip:AddLine("Click to open/close", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag to move this button", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    minimapButton = btn
    UpdateMinimapButtonPosition()
    if OctoSurvivalCompanionDB.minimapHidden then
        btn:Hide()
    end
end

-- /scw minimap -- toggle the button's visibility without losing its saved
-- angle, in case someone wants it gone (e.g. a crowded pfUI/ModernMapMarkers
-- minimap setup).
function SC.ToggleMinimapButton()
    SC.InitDB()
    OctoSurvivalCompanionDB.minimapHidden = not OctoSurvivalCompanionDB.minimapHidden
    if not minimapButton then
        SC.CreateMinimapButton()
        return
    end
    if OctoSurvivalCompanionDB.minimapHidden then
        minimapButton:Hide()
    else
        minimapButton:Show()
    end
end

-- ============================================================
-- Welcome / first-run setup screen
--
-- Pops up once, the first time the addon ever loads (see the
-- ADDON_LOADED handler in Core.lua, gated on
-- OctoSurvivalCompanionDB.setupComplete). Reopen it any time with
-- /scw setup to change these -- nothing here is a one-way choice.
-- ============================================================

local welcomeFrame
local welcomeFactionButtons = {}

local function CreateWelcomeCheckbox(parent, dbKey, labelText, yOffset)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetWidth(22)
    check:SetHeight(22)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, yOffset)
    check.dbKey = dbKey
    check:SetScript("OnClick", function()
        OctoSurvivalCompanionDB[this.dbKey] = (this:GetChecked() == 1)
    end)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", check, "RIGHT", 4, 0)
    label:SetWidth(330)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)

    return check
end

local function CreateWelcomeFrame()
    local f = CreateFrame("Frame", "OctoSurvivalCompanionWelcomeFrame", UIParent)
    f:SetWidth(420)
    f:SetHeight(470)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() this:StartMoving() end)
    f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Welcome to Octo Survival Companion!")

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -6)
    subtitle:SetWidth(370)
    subtitle:SetJustifyH("CENTER")
    subtitle:SetText("A quick one-time setup. Everything here can be changed later with /scw setup.")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function()
        -- Checkboxes already write straight to OctoSurvivalCompanionDB on
        -- click (see CreateWelcomeCheckbox below), so dismissing via the X
        -- instead of Save & Close still needs to refresh anything that
        -- reads those settings once at build time -- same as Save does.
        OctoSurvivalCompanionDB.setupComplete = true
        welcomeFrame:Hide()
        if SC.RefreshTreeBar then
            SC.RefreshTreeBar()
        end
        if SC.RefreshTrainersPanel then
            SC.RefreshTrainersPanel()
        end
    end)

    -- Faction ------------------------------------------------------
    local factionLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    factionLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -90)
    factionLabel:SetText("Your faction:")

    local factionNote = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    factionNote:SetPoint("TOPLEFT", factionLabel, "BOTTOMLEFT", 0, -2)
    factionNote:SetWidth(370)
    factionNote:SetJustifyH("LEFT")
    factionNote:SetText("Used to sort the Trainers tab so your faction's trainers show first. Auto-detected below -- override it if that's wrong.")

    local function SelectFaction(faction)
        OctoSurvivalCompanionDB.faction = faction
        local i
        for i = 1, table.getn(welcomeFactionButtons) do
            if welcomeFactionButtons[i].faction == faction then
                welcomeFactionButtons[i]:Disable()
            else
                welcomeFactionButtons[i]:Enable()
            end
        end
    end

    local hordeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    hordeBtn:SetWidth(90)
    hordeBtn:SetHeight(22)
    hordeBtn:SetPoint("TOPLEFT", factionNote, "BOTTOMLEFT", 0, -8)
    hordeBtn:SetText("Horde")
    hordeBtn.faction = "Horde"
    hordeBtn:SetScript("OnClick", function() SelectFaction("Horde") end)
    welcomeFactionButtons[1] = hordeBtn

    local allianceBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    allianceBtn:SetWidth(90)
    allianceBtn:SetHeight(22)
    allianceBtn:SetPoint("LEFT", hordeBtn, "RIGHT", 10, 0)
    allianceBtn:SetText("Alliance")
    allianceBtn.faction = "Alliance"
    allianceBtn:SetScript("OnClick", function() SelectFaction("Alliance") end)
    welcomeFactionButtons[2] = allianceBtn

    -- Options --------------------------------------------------------
    local optionsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optionsLabel:SetPoint("TOPLEFT", hordeBtn, "BOTTOMLEFT", -20, -18)
    optionsLabel:SetText("Options:")

    -- Generously spaced (46px) since several of these labels wrap to 2
    -- lines at this width.
    local check1 = CreateWelcomeCheckbox(f, "hidePetNames",
        "Hide companion pet names in tooltips until you've found them (recommended)",
        -256)
    local check2 = CreateWelcomeCheckbox(f, "showTreeBar",
        "Show the tree-chop tracker bar at the bottom of the window",
        -302)
    local check3 = CreateWelcomeCheckbox(f, "announceNewTree",
        "Print a chat message when a new tree type is first recorded",
        -348)
    local check4 = CreateWelcomeCheckbox(f, "useTomTom",
        "Try to drop a TomTom waypoint when you click a tree-bar icon (experimental)",
        -394)
    f.checkboxes = { check1, check2, check3, check4 }

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetWidth(140)
    saveBtn:SetHeight(24)
    saveBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
    saveBtn:SetText("Save & Close")
    saveBtn:SetScript("OnClick", function()
        OctoSurvivalCompanionDB.setupComplete = true
        welcomeFrame:Hide()
        if SC.RefreshTreeBar then
            SC.RefreshTreeBar()
        end
        if SC.RefreshTrainersPanel then
            SC.RefreshTrainersPanel()
        end
        if SC.Print then
            SC.Print("Setup saved. Reopen anytime with /scw setup.")
        end
    end)

    welcomeFrame = f
    return f
end

-- Fills the widgets with whatever's currently in OctoSurvivalCompanionDB (or a
-- sensible auto-detected default) -- called every time the screen opens,
-- not just on first build, so /scw setup always reflects current settings.
local function RefreshWelcomeFrame()
    SC.InitDB()

    local faction = OctoSurvivalCompanionDB.faction
    if not faction and UnitFactionGroup then
        faction = UnitFactionGroup("player")
    end
    if faction ~= "Horde" and faction ~= "Alliance" then
        faction = "Horde" -- last-resort default so a button is always selected
    end
    OctoSurvivalCompanionDB.faction = faction
    local i
    for i = 1, table.getn(welcomeFactionButtons) do
        if welcomeFactionButtons[i].faction == faction then
            welcomeFactionButtons[i]:Disable()
        else
            welcomeFactionButtons[i]:Enable()
        end
    end

    local defaults = { hidePetNames = true, showTreeBar = true, announceNewTree = true, useTomTom = true }
    local dbKey
    for i = 1, table.getn(welcomeFrame.checkboxes) do
        local check = welcomeFrame.checkboxes[i]
        dbKey = check.dbKey
        if OctoSurvivalCompanionDB[dbKey] == nil then
            OctoSurvivalCompanionDB[dbKey] = defaults[dbKey]
        end
        if OctoSurvivalCompanionDB[dbKey] then
            check:SetChecked(1)
        else
            check:SetChecked(nil)
        end
    end
end

function SC.ShowWelcome()
    if not welcomeFrame then
        CreateWelcomeFrame()
    end
    RefreshWelcomeFrame()
    welcomeFrame:Show()
end
