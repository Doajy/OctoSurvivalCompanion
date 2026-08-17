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
-- content, not tied to your own chop/pet tracking -- built the same
-- scrolling-FontString way as the Trainers and Logbook tabs. See the big
-- comment above levelingGuide in Data.lua for the source, including a
-- correction it surfaced for rankSpells/trainers (now applied there).
-- ============================================================

local guideScroll, guideScrollContent, guideScrollText

local function CreateGuidePanel(parent)
    guideScroll = CreateFrame("ScrollFrame", "OctoSurvivalCompanionGuideScroll", parent, "UIPanelScrollFrameTemplate")
    guideScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    guideScroll:SetWidth(SC.PANEL_WIDTH - 30)
    guideScroll:SetHeight(SC.PANEL_HEIGHT)

    guideScrollContent = CreateFrame("Frame", "OctoSurvivalCompanionGuideScrollChild", guideScroll)
    guideScrollContent:SetWidth(SC.PANEL_WIDTH - 30)
    guideScrollContent:SetHeight(1) -- resized below once we know the text height

    guideScrollText = guideScrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    guideScrollText:SetPoint("TOPLEFT", guideScrollContent, "TOPLEFT", 4, -4)
    guideScrollText:SetWidth(SC.PANEL_WIDTH - 46)
    guideScrollText:SetJustifyH("LEFT")
    guideScrollText:SetJustifyV("TOP")

    guideScroll:SetScrollChild(guideScrollContent)
    SC.RefreshGuidePanel()
end
SC.CreateGuidePanel = CreateGuidePanel

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
