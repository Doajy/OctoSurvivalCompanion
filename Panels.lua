--[[
Octo Survival Companion - Panels.lua
Recipes / Gardening / Trainers / Logbook / Guide tab content -- everything
under the main window except the Map tab (see Map.lua) and the frame
shell/tab-switching/minimap/welcome screen (see UI.lua).
Written against the vanilla 1.12.1 widget API (Turtle WoW / OctoWoW / CapyCraft / TurtleCraft).
]]

OctoSurvivalCompanion = OctoSurvivalCompanion or {}
local SC = OctoSurvivalCompanion

-- Only used by the Recipes tab (below) -- Trainers/Logbook/Guide are built
-- as scrolling FontStrings instead (see CreateTrainersPanel and friends).
local ROW_HEIGHT = 36
local recipeRows = {}

local function ColorText(text, r, g, b)
    local ri = math.floor(r * 255 + 0.5)
    local gi = math.floor(g * 255 + 0.5)
    local bi = math.floor(b * 255 + 0.5)
    return string.format("|cff%02x%02x%02x%s|r", ri, gi, bi, text)
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
    GameTooltip:AddLine("Reagents: " .. SC.JoinList(recipe.reagents), 1, 1, 1, 1)
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
    scroll:SetWidth(SC.PANEL_WIDTH - 30)
    scroll:SetHeight(SC.PANEL_HEIGHT)

    local recipes = OctoSurvivalCompanion_Data.recipes
    local count = table.getn(recipes)

    local content = CreateFrame("Frame", "OctoSurvivalCompanionRecipeScrollChild", scroll)
    content:SetWidth(SC.PANEL_WIDTH - 30)
    content:SetHeight(count * ROW_HEIGHT + 4)
    scroll:SetScrollChild(content)

    local i
    for i = 1, count do
        local recipe = recipes[i]
        local row = CreateFrame("Frame", "OctoSurvivalCompanionRecipeRow" .. i, content)
        row:SetWidth(SC.PANEL_WIDTH - 30)
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
-- Gardening tab
-- ============================================================

local function CreateGardeningPanel(parent)
    local g = OctoSurvivalCompanion_Data.gardening
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
    text:SetWidth(SC.PANEL_WIDTH - 30)
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
    trainersScroll:SetWidth(SC.PANEL_WIDTH - 30)
    trainersScroll:SetHeight(SC.PANEL_HEIGHT)

    trainersScrollContent = CreateFrame("Frame", "OctoSurvivalCompanionTrainersScrollChild", trainersScroll)
    trainersScrollContent:SetWidth(SC.PANEL_WIDTH - 30)
    trainersScrollContent:SetHeight(1) -- resized below once we know the text height

    trainersScrollText = trainersScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    trainersScrollText:SetPoint("TOPLEFT", trainersScrollContent, "TOPLEFT", 4, -4)
    trainersScrollText:SetWidth(SC.PANEL_WIDTH - 46)
    trainersScrollText:SetJustifyH("LEFT")
    trainersScrollText:SetJustifyV("TOP")

    trainersScroll:SetScrollChild(trainersScrollContent)
    SC.RefreshTrainersPanel()
end
SC.CreateTrainersPanel = CreateTrainersPanel

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
        table.insert(lines, "Teaches: " .. SC.JoinList(t.teaches))
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
    logbookScroll:SetWidth(SC.PANEL_WIDTH - 30)
    logbookScroll:SetHeight(SC.PANEL_HEIGHT)

    logbookScrollContent = CreateFrame("Frame", "OctoSurvivalCompanionLogbookScrollChild", logbookScroll)
    logbookScrollContent:SetWidth(SC.PANEL_WIDTH - 30)
    logbookScrollContent:SetHeight(1) -- resized below once we know the text height

    logbookScrollText = logbookScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    logbookScrollText:SetPoint("TOPLEFT", logbookScrollContent, "TOPLEFT", 4, -4)
    logbookScrollText:SetWidth(SC.PANEL_WIDTH - 46)
    logbookScrollText:SetJustifyH("LEFT")
    logbookScrollText:SetJustifyV("TOP")

    logbookScroll:SetScrollChild(logbookScrollContent)
    SC.RefreshLogbookPanel()
end
SC.CreateLogbookPanel = CreateLogbookPanel

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
        table.insert(lines, "Nothing logged yet -- go chop something. Wood and leaves both count, and an item gets logged here the moment you gather it.")
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
    table.insert(lines, ColorText("Total Trees Chopped: " .. totalChops, 0.6, 0.8, 1) .. "   " .. ColorText("Distinct items logged: " .. table.getn(treeOrder), 0.6, 0.8, 1))

    -- By tier: wood/leaf totals per tier, looked up directly by that
    -- tier's own known item name(s) (tier.woodItem.name/leafItem.name) --
    -- REVISED 2026-08-18, see the note above SC.RegisterChop in Core.lua
    -- for why this is no longer a treeNamePattern match against a
    -- (never actually obtainable) zone-qualified tree name.
    table.insert(lines, " ")
    table.insert(lines, ColorText("By tier", 1, 0.82, 0))
    if OctoSurvivalCompanion_Data and OctoSurvivalCompanion_Data.woodTiers then
        local t
        for t = 1, table.getn(OctoSurvivalCompanion_Data.woodTiers) do
            local tier = OctoSurvivalCompanion_Data.woodTiers[t]
            local woodTotal = 0
            local leafTotal = 0
            if tier.woodItem and SC.GetTreeCount then
                woodTotal = SC.GetTreeCount(tier.woodItem.name)
            end
            if tier.leafItem and SC.GetTreeCount then
                leafTotal = SC.GetTreeCount(tier.leafItem.name)
            end
            if woodTotal > 0 or leafTotal > 0 then
                local woodLabel = tier.tier .. " Wood"
                if tier.woodItem then
                    woodLabel = tier.woodItem.name
                end
                local leafLabel = tier.tier .. " Leaves"
                if tier.leafItem then
                    leafLabel = tier.leafItem.name
                end
                table.insert(lines, tier.tier .. " Wood -- " .. woodLabel .. ": " .. woodTotal .. "    " .. leafLabel .. ": " .. leafTotal)
            end
        end
    end

    -- By item: each distinct wood/leaf item you've logged, in first-seen
    -- order, and how many times each. Manually-added entries ("/scw chop
    -- <name>"/"/scw leaf <name>") show up here too under whatever name was
    -- typed.
    table.insert(lines, " ")
    table.insert(lines, ColorText("By item", 1, 0.82, 0))
    local i
    for i = 1, table.getn(treeOrder) do
        local treeName = treeOrder[i]
        local count = 0
        if SC.GetTreeCount then
            count = SC.GetTreeCount(treeName)
        end
        table.insert(lines, ColorText(treeName, 0.6, 0.8, 1) .. "  -- " .. count)
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
        table.insert(lines, SC.JoinList(knownNames) .. "  (" .. unknownCount .. " still unknown)")
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
-- content, not tied to your own chop/pet tracking.
--
-- SPLIT 2026-08-19 from one long scroll into 4 folder sub-tabs (one per
-- rank: Apprentice/Journeyman/Expert/Artisan), each still built the same
-- scrolling-FontString way the Trainers and Logbook tabs use -- just one
-- scroll+text pair per sub-tab instead of one for the whole guide, filtered
-- by each section's `group` field (see the format comment above
-- levelingGuide in Data.lua). The Apprentice sub-tab (first/starting one)
-- also carries the tools list and the whole-path materials rollup, since
-- neither is rank-specific -- see the note above that list's entry in
-- Data.lua for why it stayed in its original array position instead of
-- being physically moved next to the other Apprentice entries.
--
-- Sub-tabs are plain "UIPanelButtonTemplate" buttons + Enable()/Disable()
-- for selected state -- the same pattern this addon's own top-level tab
-- bar (SC.ShowTab/CreateTabButton in UI.lua) and the Map tab's continent
-- tabs already use. Originally tried vanilla's real "TabButtonTemplate"
-- folder-tab art plus PanelTemplates_SelectTab/DeselectTab for an
-- authentic look -- abandoned 2026-08-19 after two separate unverifiable
-- live-client failures in a row (a wrong-argument-order crash, then tabs
-- locking up and refusing to switch once selected) -- see the note above
-- CreateGuidePanel below for the full history.
-- ============================================================

-- Order matters -- this is display/tab order left-to-right. "Supplies"
-- (tools + the whole-path materials rollup, see Data.lua) leads since it's
-- what you'd check before setting out -- ADDED 2026-08-19, split out of
-- Apprentice once that tab got bloated carrying both the supply lists and
-- its own step-by-step brackets. The other four still progress in rank-up
-- order.
local GUIDE_GROUPS = { "Supplies", "Apprentice", "Journeyman", "Expert", "Artisan" }

local guideSubTabs = {}
local guideSubScrollTexts = {}
local guideSubScrollContents = {}
local guideSubPanels = {}
local guideSelectedTab = 1

-- Builds one sub-tab's worth of lines: guide.source/sourceNote only on the
-- first (Apprentice) tab, then every section whose `group` matches,
-- rendered with the exact same per-type formatting the single-scroll
-- version used.
local function BuildGuideGroupLines(guide, groupKey, isFirstTab)
    local lines = {}
    if isFirstTab then
        table.insert(lines, ColorText("Survival Leveling Guide", 1, 0.82, 0))
        if guide.source then
            table.insert(lines, ColorText("Source: " .. guide.source, 0.6, 0.6, 0.6))
        end
        if guide.sourceNote then
            table.insert(lines, ColorText(guide.sourceNote, 0.55, 0.55, 0.5))
        end
    end

    local i
    for i = 1, table.getn(guide.sections) do
        local section = guide.sections[i]
        if section.group == groupKey then
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
    end
    return lines
end

-- Rebuilds every sub-tab's text from Data.lua. Nothing here changes at
-- runtime (it's not tied to your own chop tracking), but this stays a
-- function rather than inline CreateGuidePanel code so a future
-- /reload-free data edit has somewhere to call back into.
function SC.RefreshGuidePanel()
    if table.getn(guideSubScrollTexts) == 0 then
        return
    end

    local guide = OctoSurvivalCompanion_Data and OctoSurvivalCompanion_Data.levelingGuide
    local g
    for g = 1, table.getn(GUIDE_GROUPS) do
        local lines
        if not guide or not guide.sections or table.getn(guide.sections) == 0 then
            lines = { "No leveling guide on file yet." }
        else
            lines = BuildGuideGroupLines(guide, GUIDE_GROUPS[g], g == 1)
        end

        local full = ""
        local i
        for i = 1, table.getn(lines) do
            if i > 1 then
                full = full .. "\n"
            end
            full = full .. lines[i]
        end
        guideSubScrollTexts[g]:SetText(full)
        guideSubScrollContents[g]:SetHeight(guideSubScrollTexts[g]:GetHeight() + 16)
    end
end

-- Selects one sub-tab. ORIGINALLY called PanelTemplates_SelectTab/
-- DeselectTab (FrameXML UIPanelTemplates.lua) here for the persistent
-- raised/sunk look those give a real folder tab -- REVERTED 2026-08-19,
-- same day, after PanelTemplates_TabResize (called once per tab in
-- CreateGuidePanel below) threw "attempt to index local `tab' (a number
-- value)" in game. That's a positional-argument mismatch against this
-- client's actual UIPanelTemplates.lua signature, guessed at without a way
-- to verify it -- rather than keep guessing at the other two undocumented
-- helpers too, this now uses only Enable()/Disable() for selected state,
-- the same mechanism this addon's OWN top-level tab bar (SC.ShowTab in
-- UI.lua) and the Map tab's continent tabs already use successfully. The
-- tab buttons are still real CreateFrame(..., "TabButtonTemplate")
-- buttons, so they still render actual folder-tab shaped art -- this just
-- skips the extra persistent-selected-state polish PanelTemplates_SelectTab
-- would otherwise add, in exchange for not crashing.
function SC.ShowGuideSubTab(index)
    guideSelectedTab = index
    local i
    for i = 1, table.getn(guideSubTabs) do
        if i == index then
            guideSubTabs[i]:Disable()
            guideSubPanels[i]:Show()
        else
            guideSubTabs[i]:Enable()
            guideSubPanels[i]:Hide()
        end
    end
end

-- Reserved height for the tab row before the scroll content starts.
local GUIDE_TAB_ROW_HEIGHT = 30

local function CreateGuidePanel(parent)
    local prevTab
    local g
    for g = 1, table.getn(GUIDE_GROUPS) do
        -- Explicit fresh local per iteration for the OnClick closure below
        -- to capture, rather than the loop's own `g` directly -- ADDED
        -- 2026-08-19 after every sub-tab was observed disabling/showing
        -- tab 4 (the last one created) regardless of which was actually
        -- clicked, the exact symptom of every closure sharing one mutated
        -- variable instead of its own loop iteration's value. A numeric
        -- `for` loop variable is supposed to be fresh each iteration in
        -- Lua, verified true in a 5.4 interpreter here, but the actual
        -- client runs Lua 5.0 and that couldn't be verified directly
        -- against it -- this local makes the capture unambiguous either
        -- way, independent of whichever behavior turns out to be true.
        local tabIndex = g
        -- ABANDONED 2026-08-19 "TabButtonTemplate" (a genuine folder-tab
        -- look) after two separate live-client failures in a row it wasn't
        -- possible to verify or debug from here: first a crash from a
        -- guessed-wrong PanelTemplates_TabResize argument order, then
        -- (after removing that call) the tabs locking up on click and
        -- refusing to switch, with Disable()/Enable() -- the same pattern
        -- used below via "UIPanelButtonTemplate" instead. That swap is what
        -- fixed it: this addon's own top-level tab bar (SC.ShowTab, this
        -- file's -- actually UI.lua's -- CreateTabButton) and the Map tab's
        -- continent tabs already use UIPanelButtonTemplate + Enable/Disable
        -- successfully today, so these sub-tabs now match that same proven
        -- pattern instead of guessing at TabButtonTemplate's undocumented
        -- quirks a third time. Loses the authentic folder-tab art in
        -- exchange for actually working.
        local tab = CreateFrame("Button", "OctoSurvivalCompanionGuideSubTab" .. g, parent, "UIPanelButtonTemplate")
        tab:SetText(GUIDE_GROUPS[g])
        tab:SetWidth(100)
        tab:SetHeight(22)
        if prevTab then
            tab:SetPoint("TOPLEFT", prevTab, "TOPRIGHT", 4, 0)
        else
            tab:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, 0)
        end
        tab:SetScript("OnClick", function() SC.ShowGuideSubTab(tabIndex) end)
        guideSubTabs[g] = tab
        prevTab = tab

        local sub = CreateFrame("Frame", nil, parent)
        sub:SetWidth(SC.PANEL_WIDTH)
        sub:SetHeight(SC.PANEL_HEIGHT - GUIDE_TAB_ROW_HEIGHT)
        sub:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -GUIDE_TAB_ROW_HEIGHT)
        sub:Hide()
        guideSubPanels[g] = sub

        local scroll = CreateFrame("ScrollFrame", "OctoSurvivalCompanionGuideSubScroll" .. g, sub, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", sub, "TOPLEFT", 0, 0)
        scroll:SetWidth(SC.PANEL_WIDTH - 30)
        scroll:SetHeight(SC.PANEL_HEIGHT - GUIDE_TAB_ROW_HEIGHT)

        local content = CreateFrame("Frame", "OctoSurvivalCompanionGuideSubScrollChild" .. g, scroll)
        content:SetWidth(SC.PANEL_WIDTH - 30)
        content:SetHeight(1) -- resized in SC.RefreshGuidePanel once we know the text height
        guideSubScrollContents[g] = content

        local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", content, "TOPLEFT", 4, -4)
        text:SetWidth(SC.PANEL_WIDTH - 46)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        guideSubScrollTexts[g] = text

        scroll:SetScrollChild(content)
    end

    SC.RefreshGuidePanel()
    SC.ShowGuideSubTab(1)
end
SC.CreateGuidePanel = CreateGuidePanel
