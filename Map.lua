--[[
Octo Survival Companion - Map.lua
The Map tab: Kalimdor / Eastern Kingdoms sub-tabs, tree-tier/zone picker
dropdowns, client map art rendering (real zone maps, the "revealed
terrain" overlay, and the zoomed continent-crop fallback for zones with
no real client map), and the spawn-point pip markers.
Written against the vanilla 1.12.1 widget API (Turtle WoW / OctoWoW / CapyCraft / TurtleCraft).
]]

OctoSurvivalCompanion = OctoSurvivalCompanion or {}
local SC = OctoSurvivalCompanion

local RARE_ZONE_THRESHOLD = 10

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
-- x/y, tiers) by name. Shared by SC.ResolveZoneMapFile (looking up a
-- zone's real areaId for the reveal-overlay fetch), SC.RefreshMapInfoText
-- (the "(approximate placement)" note), and SC.UpdateMapView (feeding
-- CenterZoomCropOnZone's x/y for the zoomed-crop fallback view).
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
--
-- TRIED AND REVERTED 2026-08-17: briefly switched this to vanilla's own
-- native GetNumMapOverlays()/GetMapOverlayInfo() (confirmed genuine
-- 1.12.1 client API, per the Vanilla WoW Wiki, and what pfUI's own
-- mapreveal.lua module uses), reasoning it'd remove the ClassicAPI
-- dependency and fix zones ClassicAPI's own data didn't cover (Blackstone
-- Island). That reasoning missed something: the NATIVE api is
-- EXPLORATION-GATED -- it's the same underlying data source vanilla's own
-- World Map uses to reveal fog as YOU personally walk around, so it only
-- returns overlays for terrain this character has actually explored,
-- same as the base fogged tiles it was meant to draw OVER. In-game this
-- made every single zone show unrevealed (not just Blackstone Island),
-- confirming ClassicAPI's C_Map.GetMapOverlays() must be doing something
-- genuinely different -- returning full terrain overlay data regardless
-- of this character's own exploration history, a real "reveal everything"
-- rather than a fog-of-war readout. So: back to C_Map.GetMapOverlays().
--
-- CLOSED 2026-08-17: passing the zone's real areaId explicitly (see the
-- areaId note above SC.ResolveZoneMapFile's caller site below) fixed
-- reveal for every custom zone EXCEPT Blackstone Island and Tel'abim.
-- Tel'abim comes back with genuinely zero overlay tiles even with the
-- correct areaId -- no WorldMapOverlay.dbc art on file for it at all, per
-- ClassicAPI's own Overlays.cpp source (that DBC is what
-- C_Map.GetMapOverlays() reads directly), nothing to fix from this
-- addon's side. Blackstone Island is a DIFFERENT, worse case, confirmed
-- via an in-game screenshot: it DOES get some overlay tiles back with the
-- explicit areaId, but they render as a messy patchwork of revealed vs.
-- fogged BLOTCHES across the landmass, not a clean full reveal -- because
-- the overlay data (now correctly resolved to Blackstone Island's OWN
-- true WorldMapArea row) and the base map TEXTURE (still whatever
-- borrowed/reused zone SetMapZoom's zoneIndex resolution landed on, see
-- the forceZoomCrop revert note above SC.UpdateMapView) come from two
-- DIFFERENT WorldMapArea entries with unrelated canvases -- a real
-- "double map" mismatch, not a scale-math bug fixable by adjusting
-- constants. NO_OVERLAY_ZONES below just skips the overlay attempt
-- entirely for both -- plain fog is strictly better than a mismatched
-- patchwork, and the user confirmed plain fog reads fine for these two.
local NO_OVERLAY_ZONES = { ["Blackstone Island"] = true, ["Tel'abim"] = true }

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
            if C_Map and C_Map.GetMapOverlays and not NO_OVERLAY_ZONES[zoneName] then
                -- ADDED 2026-08-17 -- pass the zone's real AreaTable id
                -- (Data.lua's zones[].areaId, sourced from pfQuest-turtle)
                -- when we know it, instead of always calling
                -- C_Map.GetMapOverlays() bare. Per ClassicAPI's own source
                -- (src/map/Overlays.cpp, Script_GetMapOverlays), the
                -- no-argument form resolves WorldMapOverlay.dbc rows from
                -- whatever WorldMapArea row the CURRENT SetMapZoom view
                -- happens to land on -- and for a zone like Blackstone
                -- Island, whose real client map turned out to be a
                -- borrowed/reused texture from a different zone (see the
                -- forceZoomCrop revert note above SC.UpdateMapView), that
                -- resolved row is NOT guaranteed to be Blackstone Island's
                -- own true area identity, even though the borrowed art
                -- itself displays fine. Passing the known real areaId
                -- explicitly resolves the DBC row directly, sidestepping
                -- whatever zone SetMapZoom's borrowed-texture resolution
                -- actually landed on.
                local zoneData = FindZoneData(zoneName)
                resultOverlayTiles = {}
                local overlays
                if zoneData and zoneData.areaId then
                    overlays = C_Map.GetMapOverlays(zoneData.areaId)
                else
                    overlays = C_Map.GetMapOverlays()
                end
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

-- PIP_SIZE/PIP_Y_SCALE moved up here (were originally declared right above
-- RefreshMapPips, further down the file) because RefreshZoomCropPips --
-- defined BELOW this point but ABOVE where they used to live -- also needs
-- them. Lua locals aren't visible before their own declaration point in
-- the chunk, so that ordering silently resolved PIP_SIZE to a nil global
-- inside RefreshZoomCropPips (-> "Usage: <unnamed>:SetWidth(width)" at
-- runtime) for as long as nothing actually exercised that function's pip
-- loop -- see the note above SC.UpdateMapView's forceZoomCrop for why that
-- changed.
local PIP_SIZE = 10
-- Compresses pips' effective vertical range down to 0-88% instead of
-- 0-100% -- see the note where this is used in RefreshMapPips for why
-- (a tuned approximation for a mismatch between octowow.st's own
-- coordinate authoring and Blizzard's real canvas, not a bug in this
-- addon's own map-reading code).
local PIP_Y_SCALE = 0.88

-- Fallback view for whatever zone SC.ResolveZoneMapFile genuinely can't
-- resolve a real client map for (mapFileName nil -- see SC.UpdateMapView).
-- NAMED (not anonymous) and given the SAME "UIPanelScrollFrameTemplate"
-- the codebase's one other ScrollFrame uses (trainersScroll in
-- CreateTrainersPanel), unlike the original bare/anonymous version of this
-- function -- UNVERIFIED whether that was ever the actual cause of anything,
-- since the one confirmed real-world "solid black" report (Moonwhisper
-- Coast, Blackstone Island, 2026-08-17) turned out to be caused by
-- SC.UpdateMapView routing zones AWAY from their perfectly-working real
-- maps into this function unnecessarily (see the REVERTED note there) --
-- so this path may still be genuinely broken and effectively untested
-- in-game. If a zone ever actually lands here and shows solid black again,
-- that's real signal this function itself needs another look, not a repeat
-- of the same routing mistake.
local zoomCropCounter = 0
local function CreateZoomCrop(parent, continent, areaWidth, areaHeight)
    zoomCropCounter = zoomCropCounter + 1
    local scroll = CreateFrame("ScrollFrame", "OctoSurvivalCompanionZoomCrop" .. zoomCropCounter, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    scroll:SetWidth(areaWidth)
    scroll:SetHeight(areaHeight)
    scroll:Hide()
    local scrollBar = getglobal(scroll:GetName() .. "ScrollBar")
    if scrollBar then
        scrollBar:Hide()
    end

    local zoomedW = areaWidth * ZOOM_FACTOR
    local zoomedH = areaHeight * ZOOM_FACTOR
    local child = CreateFrame("Frame", scroll:GetName() .. "Child", scroll)
    child:SetWidth(zoomedW)
    child:SetHeight(zoomedH)
    scroll:SetScrollChild(child)

    local grid, textures = CreateTileGrid(child, 4, 3, zoomedW / 4, zoomedH / 3)
    SetGridTextures(textures, continent.mapFileName)

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
            tiersText = SC.JoinList(names)
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
            frame.infoText:SetText(tierKey .. " Wood (skill " .. skillText .. "): " .. SC.JoinList(zoneNames))
        end
    else
        frame.infoText:SetText("Pick a tree and/or a zone above to see chop details.")
    end
end

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

    -- REVERTED 2026-08-17 -- briefly forced the 7 areaId zones (Moonwhisper
    -- Coast, Blackstone Island, Northwind, Balor, Grim Reaches, Thalassian
    -- Highlands, Gilneas) straight to the zoomed continent-crop view below,
    -- reasoning that a real client map's zone-local coordinate space has no
    -- known mapping to our octowow.st-scraped CONTINENT-relative pip data
    -- (tierData.spawnPointsContinentRelative) for these zones. That's still
    -- true, BUT it turned out to be the wrong tradeoff in practice:
    -- Moonwhisper Coast's real map (SC.ResolveZoneMapFile below DOES
    -- resolve one for it -- CONFIRMED in-game, a legitimate zone map, not a
    -- bug) was rendering correctly all along, just without pips -- exactly
    -- like Hyjal/Tel'abim's already-accepted "real map, no pip data yet"
    -- gap (see the README's "About the data" section). Forcing zoom-crop
    -- traded a working map with no pips for a completely black one, since
    -- CreateZoomCrop's ScrollFrame-based rendering has its own separate,
    -- still-unresolved bug (never root-caused -- temporary debug prints
    -- added while chasing it were removed again once this revert made
    -- them unnecessary). So:
    -- trust SC.ResolveZoneMapFile again for every zone, same as any other
    -- zone -- zoom-crop is still the fallback for whatever zone it
    -- genuinely can't resolve (mapFileName nil), same as originally
    -- designed, not specifically targeted at the areaId zones anymore.
    local selectedZoneData = FindZoneData(frame.selectedZone)
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
        CenterZoomCropOnZone(frame.zoomCropFrame, selectedZoneData)
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
-- zone-by-zone.)
local function BuildZoneDropdownList(frame)
    local info = {}
    info.text = "All Zones"
    info.notCheckable = 1
    info.func = function() SC.MapSelectZone(frame, nil) end
    UIDropDownMenu_AddButton(info)

    local tierData = nil
    -- When a tier is picked, every zone left in this list grows THAT
    -- tier (that's what the filtering above already guarantees), so its
    -- icon is unambiguous -- shown via info.icon below, the dropdown
    -- template's own dedicated icon field (a real Icon texture region the
    -- template positions itself), NOT a "|T..|t" inline-texture escape
    -- embedded in info.text. FIXED 2026-08-17: the embedded-escape version
    -- showed the raw "|Tpath:14|t" text literally instead of an image --
    -- dropdown button labels don't render texture escapes the way a plain
    -- FontString (tooltip, chat line) does, even though the exact same
    -- icon paths work fine as real Textures elsewhere in this file (map
    -- pips, SetTexture calls) -- confirmed those are NOT broken/missing
    -- files, just this one rendering path. "All Zones" (no tier picked)
    -- leaves the icon off, since a zone can carry 2-3 different tiers and
    -- there'd be no single "appropriate" one to show.
    local tierIconPath = nil
    if frame.selectedTier then
        tierData = GetTierByKey(frame.selectedTier)
        tierIconPath = GetTierIconPath(tierData)
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
                    -- after the zone name (e.g. "Winterspring (14)", with
                    -- the tier's icon rendered separately via info.icon
                    -- above -- Blizzard's dropdown template draws that to
                    -- the right of the whole text string) -- left off for
                    -- "All Zones" (no single tier to count)
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
                    info.text = zoneName .. countMarkup
                    info.icon = tierIconPath
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
    infoText:SetWidth(SC.PANEL_WIDTH - 12)
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
    local mapWidth = SC.PANEL_WIDTH
    local mapHeight = (SC.PANEL_HEIGHT - 26) - mapTop

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
        mapHolder:SetWidth(SC.PANEL_WIDTH)
        mapHolder:SetHeight(SC.PANEL_HEIGHT - 26)
        mapContinentFrames[i] = CreateContinentMap(mapHolder, MAP_CONTINENTS[i])
    end
    ShowMapContinent("Kalimdor")
end
SC.CreateMapPanel = CreateMapPanel
