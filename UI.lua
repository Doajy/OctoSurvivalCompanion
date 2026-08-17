--[[
Octo Survival Companion - UI.lua
The main window's shell: the frame itself, tab switching, the bottom
tree-chop tracker bar, the minimap button, and the first-run welcome/setup
screen. Tab CONTENT lives elsewhere -- Recipes/Gardening/Trainers/Logbook/
Guide in Panels.lua, the Map tab in Map.lua -- this file just builds the
window around them and wires the tabs together (SC.CreateMapPanel and
friends, exposed by those two files, are called from BuildUI below).
Written against the vanilla 1.12.1 widget API (Turtle WoW / OctoWoW / CapyCraft / TurtleCraft).
]]

OctoSurvivalCompanion = OctoSurvivalCompanion or {}
local SC = OctoSurvivalCompanion

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
-- Exposed for Map.lua and Panels.lua, which both size their own scroll
-- frames/panels/map area against these same two constants.
SC.PANEL_WIDTH = PANEL_WIDTH
SC.PANEL_HEIGHT = PANEL_HEIGHT

local mainFrame
local tabButtons = {}
local panels = {}
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
-- Exposed for Panels.lua (Recipes/Trainers/Logbook) and Map.lua, both of
-- which join plain name lists the same way this does.
SC.JoinList = JoinList
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
    SC.mainFrame = mainFrame

    local labels = { "Map", "Trainers", "Logbook", "Guide" }
    local xOffsets = { 14, 126, 238, 350 }
    local i
    for i = 1, table.getn(labels) do
        tabButtons[i] = CreateTabButton(mainFrame, i, labels[i], xOffsets[i])
    end

    for i = 1, table.getn(labels) do
        panels[i] = CreatePanel(mainFrame)
    end

    SC.CreateMapPanel(panels[1])
    SC.CreateTrainersPanel(panels[2])
    SC.CreateLogbookPanel(panels[3])
    SC.CreateGuidePanel(panels[4])
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
    -- 380, down from 470 -- shrunk 2026-08-17 after removing 2 of the 4
    -- option checkboxes (hidePetNames, useTomTom -- see the note above
    -- them below) left a big empty gap above the Save button otherwise.
    f:SetHeight(380)
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

    -- Generously spaced (46px) since these labels wrap to 2 lines at this
    -- width. REMOVED 2026-08-17: hidePetNames and useTomTom checkboxes --
    -- both settings were fully plumbed into the DB but never actually
    -- consumed anywhere (hidePetNames had no reader at all; useTomTom's
    -- only reader lived inside SC.JumpToTreeOnMap, removed the same day as
    -- dead code -- see the note above CreateContinentMap in Map.lua). A
    -- checkbox that does nothing is worse than no checkbox -- re-add
    -- properly if/when either feature actually gets built.
    local check1 = CreateWelcomeCheckbox(f, "showTreeBar",
        "Show the tree-chop tracker bar at the bottom of the window",
        -256)
    local check2 = CreateWelcomeCheckbox(f, "announceNewTree",
        "Print a chat message when a new tree type is first recorded",
        -302)
    f.checkboxes = { check1, check2 }

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

    local defaults = { showTreeBar = true, announceNewTree = true }
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
