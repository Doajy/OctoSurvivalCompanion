--[[
Octo Survival Companion - UI.lua
The main window's shell: the frame itself, tab switching, the minimap
button, and the first-run welcome/setup screen. Tab CONTENT lives
elsewhere -- Recipes/Gardening/Trainers/Logbook/
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
    -- 760, down from 834 -- shrunk 2026-08-18 after removing the bottom
    -- tree-chop tracker bar (that data now lives solely in the Logbook
    -- tab). Panel bottom sits at 86 (top offset) + 654 (PANEL_HEIGHT) =
    -- 740 from the frame's top, so 760 leaves a plain 20px margin below it
    -- instead of the ~94px the bar used to occupy.
    f:SetHeight(760)
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

    SC.ShowTab(1)
    SC.RefreshUI()
end

function SC.ToggleFrame()
    if not mainFrame then
        BuildUI()
    end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        SC.RefreshUI()
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
    -- REVERTED 2026-08-17 -- tried "INV_Campfire" (blank in-game, likely a
    -- later-Classic-only icon) and then Data.lua's defaultTreeIcon
    -- ("INV_Misc_Log_02", also blank) -- both were unverified guesses at
    -- STOCK Blizzard icon names. defaultTreeIcon turned out to never
    -- actually be exercised elsewhere in the addon either (every wood tier
    -- defines its own icon, so that fallback path never renders), so it
    -- was never really "confirmed working" to begin with. Switched to
    -- "simple_wood_1" instead -- one of the server's own CUSTOM item icons
    -- (Data.lua woodTiers["Simple"].woodItem.icon), the same one already
    -- rendering fine as a map pip, so it's the one icon path in this whole
    -- investigation with real in-game confirmation behind it.
    icon:SetTexture("Interface\\Icons\\simple_wood_1")
    -- Item icons are square art on a square canvas -- the circular
    -- MiniMap-TrackingBorder ring only masks a thin band, so the icon's
    -- own square corners poked out past it as a visible black box.
    -- Standard fix (same crop LibDBIcon-style minimap buttons use):
    -- zoom the texture coords in ~7% per edge so the corners are cropped
    -- away before they'd reach past the ring.
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetWidth(31)
    highlight:SetHeight(31)
    highlight:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    -- ADDED 2026-08-18 -- this is a glow-style asset (black background,
    -- white glow shape) meant for ADDITIVE blending, where black
    -- contributes nothing and only the glow adds light. Without this, the
    -- texture uses the default alpha-blend mode instead, which reads the
    -- black background as opaque black rather than transparent -- since
    -- HIGHLIGHT draws on top of everything else, that painted the icon
    -- over solid black on hover instead of glowing.
    highlight:SetBlendMode("ADD")

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
    -- 330, down from 470 -- shrunk 2026-08-17 after removing 2 of the 4
    -- option checkboxes (hidePetNames, useTomTom), then again 2026-08-18
    -- after removing showTreeBar too, down to a single remaining
    -- checkbox -- each removal otherwise left a bigger empty gap above
    -- the Save button.
    f:SetHeight(330)
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

    -- REMOVED 2026-08-17: hidePetNames and useTomTom checkboxes -- both
    -- settings were fully plumbed into the DB but never actually consumed
    -- anywhere (hidePetNames had no reader at all; useTomTom's only reader
    -- lived inside SC.JumpToTreeOnMap, removed the same day as dead code --
    -- see the note above CreateContinentMap in Map.lua). REMOVED
    -- 2026-08-18: showTreeBar checkbox, along with the bottom tree-chop
    -- tracker bar it toggled -- that data lives solely in the Logbook tab
    -- now. A checkbox that does nothing is worse than no checkbox --
    -- re-add properly if/when a removed feature actually comes back.
    local check1 = CreateWelcomeCheckbox(f, "announceNewTree",
        "Print a chat message when a new tree type is first recorded",
        -256)
    f.checkboxes = { check1 }

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetWidth(140)
    saveBtn:SetHeight(24)
    saveBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 16)
    saveBtn:SetText("Save & Close")
    saveBtn:SetScript("OnClick", function()
        OctoSurvivalCompanionDB.setupComplete = true
        welcomeFrame:Hide()
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

    local defaults = { announceNewTree = true }
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
