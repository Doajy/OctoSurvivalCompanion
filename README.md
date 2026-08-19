Extremely unfinished so take care when using

# Octo Survival Companion

An in-game reference and tracker addon for the custom **Survival** secondary
profession found on Turtle WoW and its derivative servers — OctoWoW,
CapyCraft (Capybara Paradise), TurtleCraft, and similar 1.12.1 Turtle WoW
clones. No external dependencies, no compiled/hidden data — everything it
knows lives in one plain, heavily commented Lua file you can read or correct
yourself.

## Features

- **Map tab** — Kalimdor / Eastern Kingdoms sub-tabs rendered from the
  client's own map art. A tree-tier dropdown (sorted by required Survival
  skill, lowest first) and a zone dropdown work together: pick a tier and
  the zone list narrows to zones that carry it, each tagged with its known
  spawn count; pick a zone and the map below switches to that zone's own
  client map (or a zoomed-in crop of the continent for the custom Turtle
  WoW zones, which don't have one). When a real client map is showing, it's
  dotted with individual spawn-point "pips" — each one that tier's own wood
  icon — for every known tree location in that zone (all 6 wood tiers,
  ~2,550 spawn points total, sourced from octowow.st — see the
  `spawnPoints` note above `woodTiers` in `Data.lua`). If the separate
  **ClassicAPI** addon is installed, zone maps also render fully "revealed"
  (real terrain colors everywhere) instead of the client's default fog
  over areas you haven't personally explored yet — this addon is a
  reference tool, so seeing a spot before you've been there is the point.
  Without ClassicAPI, zone maps still work, just with the client's normal
  fog on unexplored areas (same as the stock World Map). Two custom zones,
  **Blackstone Island** and **Tel'abim**, stay on the normal fogged look
  even with ClassicAPI installed — confirmed 2026-08-17 there's genuinely
  no reveal artwork on file for either one client-side, not a bug in this
  addon, and the fogged look actually reads better for them anyway — see
  the note above `RefreshMapOverlay` in `Map.lua`.
- **Honest about sparse zones, without drowning in them** — a zone with a
  confirmed spawn count of 5–10 for a given tier (e.g. Un'Goro Crater's 5
  known Dead Wood spawns) still shows in the zone dropdown, just with a
  "(N, might be spillover)" flag instead of a plain "(N)" (see
  `IsZoneRareForTier` in `Map.lua`), so you can see and pick it with a
  clear heads-up. Below that — under 5 confirmed spawns (e.g. Balor's 3
  known Bright Wood spawns) — the zone is left off the dropdown entirely
  (`IsZoneTooRareToList`/`MIN_ZONE_LIST_COUNT`). This isn't a data-quality
  call — some of these specific counts are individually re-verified as
  genuinely real, not spillover — it's just "not worth a special trip
  either way," trimming clutter from an already-long list.
- **Logbook tab** — "every log you've logged, logged." Your full personal
  chop history: totals, a by-tier summary, a by-tree breakdown, and a
  companion-pet known/unknown summary. Nothing is pre-populated — it only
  knows what it's actually seen you gather.
- **Trainers tab** — all 16 Survival trainer NPCs (zone, coordinates,
  level, and exactly what each one teaches), the four skill-cap rank-ups,
  and the starting quest chain, auto-sorted so your own faction shows
  first.
- **Guide tab** — a bracket-by-bracket Survival leveling guide covering the
  full 1-300 skill range: what to craft at each skill bracket, the tools
  you need before you start, the rank-up gates (Journeyman/Expert/Artisan
  Survival) that stand in the way, and a full materials-required rollup for
  the whole path — sourced from a TurtleCraft forum guide. This same guide
  is also what the Trainers tab's four rank-ups and Rufus Hardwick's
  Artisan Survivalist classification come from.
- **Companion pet tracking** — spoiler-safe: pets you haven't confirmed
  show as `????` until the addon has seen evidence you've learned one (or
  you tell it yourself).
- **One-time setup screen** — faction (auto-detected), and toggles for pet
  name hiding, the tracker bar, new-tree chat announcements, and TomTom
  integration. Reopen anytime, nothing is a one-way choice.

## Installation

1. Unzip this into your WoW `Interface/AddOns/` folder, so you end up with
   `Interface/AddOns/OctoSurvivalCompanion/OctoSurvivalCompanion.toc`.
2. Restart the client (or reload UI with `/reload`) and enable the addon at
   the character select screen if needed.

## Usage

Type `/scw` (or `/survival`, or `/octosurvivalcompanion`) to open the
window, or click the minimap button. The first time it loads, a short setup
screen pops up on its own — reopen it anytime with `/scw setup`.

| Command | Effect |
| --- | --- |
| `/scw` | Open/close the main window |
| `/scw setup` (or `options`) | Open the setup screen |
| `/scw minimap` | Show/hide the minimap button (drag it around the rim to reposition) |
| `/scw chop <tree name>` | Manually log a wood gather (testing / fallback for missed auto-detection) |
| `/scw leaf <tree name>` | Manually log a leaf gather |
| `/scw resettrees` | Clear all tree-chop tracking data |
| `/scw pet <name>` | Manually mark a companion pet as known |
| `/scw pets` | Print a known/unknown companion pet summary to chat |
| `/scw report` (or `feedback`) | Print where to send data corrections |

Chop and companion-pet detection is best-effort: it listens for wood/leaf
loot and companion-pet-flavored system messages and infers from there, since
neither is a confirmed, documented hook. Use the manual commands above if
something gets missed.

## Compatibility

Built against `## Interface: 11200` — the vanilla 1.12.1 API (Lua 5.0, not
5.1), verified against the real 1.12.1 FrameXML client source where the
behavior wasn't obvious (dropdown menu argument order, World Map tile
naming, `ScrollFrame` methods, and so on — see the comments throughout
`UI.lua`/`Panels.lua`/`Map.lua`). Targets Turtle WoW and its 1.12.1-based clone servers: OctoWoW,
CapyCraft (Capybara Paradise), TurtleCraft, and similar. Not built for
retail, Classic Era, or Season of Discovery clients.

## About the data

Everything the addon knows lives in `Data.lua` as one plain, heavily
commented Lua table. It was assembled from public guides, the official
Turtle WoW / OctoWoW / TurtleCraft profession pages, and CapyCraft's own
item/object database at db.capycraft.org (linked at the top of `Data.lua`).

A pass through db.capycraft.org (following each recipe's "Taught By" list on
its spell page) found that **most Survival recipes are taught directly by
trainer NPCs**, not looted or bought as scroll/schematic items like an early
draft of this addon assumed. All 16 trainers — 13 regular
`<Survival Trainer>`s (one per major city/starting zone), 2
`<Expert Survivalist>`s (Swamp of Sorrows and Desolace) who teach the Expert
rank-up (skill 150→225), and Rufus Hardwick in Stranglethorn Vale, the sole
`<Artisan Survivalist>` who teaches the top rank-up (skill 225→300) — are
listed in `Data.lua`'s `trainers` table with zone, coordinates, level, and
exactly which recipes/ranks each one teaches. That 4-rank structure
(Apprentice/Journeyman/Expert/Artisan, replacing an earlier 3-rank model
where Expert wrongly unlocked straight to 300) came from the same
TurtleCraft forum leveling guide the Guide tab is built from — see the
`RESTRUCTURED`/`RECLASSIFIED` comments in `Data.lua` near `rankSpells` and
Rufus Hardwick's trainer entry for the full reasoning.
`octowow.st/db`'s NPC search page renders client-side with JavaScript so it
couldn't be scraped for this pass; everything above came from
db.capycraft.org instead.

A follow-up pass through **octowow.st's database** filled in recipe-level
Survival skill requirements that db.capycraft.org's pages don't show, by
chaining its exact-name quicksearch redirects to each recipe's "Torn
Outline" pattern-item page — that's where the corrected `skillReq` numbers
in `Data.lua` come from. Note octowow.st's own live search/results page
(`/db/?search=...`) is a client-side JavaScript app and can't be scraped by
a plain HTTP fetch — only its individual `?npc=` / `?item=` detail pages
render server-side, which is how this data was pulled.

Companion pets tied to tree-chopping (Wood Constrictor, Dung Beetle, etc.)
were confirmed the same way, cross-checked against each tree object's own
loot table on db.capycraft.org rather than guessed from nearby item IDs —
see `woodTiers[i].pets` in `Data.lua`.

Wood-tier chop-zone counts (`woodTiers[i].zoneCounts`) come from each wood
object's own "Locations" page on db.capycraft.org/octowow.st. A handful of
zones came back with confirmed-low counts (3-5 known spawns) rather than
being spillover from a database quirk — those stay in the data (deleting
confirmed-correct data would just make the addon less accurate) but are
treated as "rare" everywhere the addon recommends a farming spot, so they
never crowd out a genuinely good zone.

A 2026-08-16 pass through a TurtleCraft forum leveling guide (used to build
the Guide tab, see above) also cross-checked and reconciled a few older open
questions: **Bright Wood's, Shade Wood's, Tropical Wood's, Star Wood's, and
Dead Wood's** required chop skill were corrected from old item-level
guesses to the forum's confirmed numbers; three trainers whose zones were
previously `unconfirmed` or fuzzily attributed — **Feebeld** (Blackstone
Island), **Hellador Swiftluck** (Alah'thalas), and **Nallaeth** (corrected
from Teldrassil, which was already used for a different trainer, to
Darnassus) — got resolved; and a few zones the forum's own zone lists
mentioned but this addon's `octowow.st`-sourced data didn't (**Tel'abim**,
**Lapidis Isle**, **Gillijim's Isle** for Tropical Wood, and **Hyjal** for
Star/Dead Wood) were added to `chopZones`/`zones`, without spawn counts
since no count data exists for them yet — full reasoning is in the
`RECONCILED` comments next to each tier in `Data.lua`.

A 2026-08-17 pass resolved the two recipes that previously had open
`confirmed = false` questions in `Data.lua`. **Bright Campfire** turned out
not to be a Survival recipe at all — it's the base **Cooking**-profession
recipe (General spellbook tab, any Cooking trainer), which Turtle WoW's
custom Survival system repurposes as a guaranteed skill-up craft in the
skill 10-75ish range; that's why two earlier passes searching
Survival-specific sources (db.capycraft.org spell ids, an octowow.st
pattern-item search) never found it. **Cleaning Cloth**'s ids were
untangled via live db.capycraft.org lookups: the create spell is #46068 and
its teach spell is #46069 (both Krug/Stagtree, 2 Silk Cloth + 1 Volatile
Rum), while spell #46070 — previously filed as this recipe's spellId — is
actually the crafted item's own on-use "clean a weapon" effect, not a
separate recipe; the `recipeItemId` pointing at "Torn Outline: Cleaning
Cloth" (60002) was dropped since that item has no Survival requirement text
or pattern-drop markers of its own. Full reasoning is in the `RESOLVED
2026-08-17` notes next to each entry in `Data.lua`. The Gardening tab still
doesn't have specific seed names yet, though — there's an empty
`gardening.seeds` table in `Data.lua` ready to fill in once you can see them
in your own tradeskill window.

## Filling in missing spawn pips (Octo Node Scout)

Zones/tiers without pips on the Map tab (sparse octowow.st coverage, or the
custom Turtle WoW zones it doesn't recognize at all) can be filled in by
hand with **Octo Node Scout**, a separate standalone addon: walk up to a
tree and it logs the exact zone-local position under that wood tier
(auto-detected off the same wood/leaf loot message this addon's own chop
tracker reads, or typed by hand with `/ons` for anything missed).

That data gets merged into this addon's `Data.lua` **out of game**, not
through any in-game import UI -- a first attempt at a live cross-addon
import screen (`/scw nodes`) turned out fragile in practice and was
removed. Instead: log trees in game, `/reload` or log out so the client
flushes `OctoNodeScoutDB` to its `SavedVariables` file on disk, then read
and merge that file's points into the right tier's `spawnPoints` directly.

## Contributing

If you can confirm or correct any of the open questions above, open
`Data.lua` in a text editor and edit it directly — the structure is
documented in the comment block above each table (`trainers`, `recipes`,
`woodTiers`, `zones`, `gardening`). It's plain Lua, no build step. Pull
requests welcome, or use `/scw report` in game for a quick pointer back to
this file.

The Recipes and Gardening tabs are temporarily unwired from the tab bar
while Map/Logbook work is in progress — the code that builds them
(`CreateRecipeScroll`, `CreateGardeningPanel` in `Panels.lua`) and the
`Data.lua` tables they read from are all still there, so re-adding them is
a quick wire-up rather than a rewrite.

## Project structure

```
OctoSurvivalCompanion/
├── OctoSurvivalCompanion.toc   addon manifest (Interface, title, saved variables)
├── Data.lua                    all reference data: trainers, recipes, wood tiers, zones, gardening
├── Core.lua                    saved variables, chop/pet tracking, slash commands
├── UI.lua                      main window shell: frame, tab switching, tree-chop bar, minimap button, welcome screen
├── Panels.lua                  Recipes / Gardening / Trainers / Logbook / Guide tab content
├── Map.lua                     the Map tab: continent/zone maps, spawn-point pips, reveal overlay
└── README.md
```

Split into these three UI files 2026-08-17 once `UI.lua` alone passed 2,700
lines — `Map.lua` in particular had grown into its own largely
self-contained subsystem (tile grids, pips, the reveal overlay, the
zoomed-crop fallback, both picker dropdowns). Anything one file needs from
another goes through the shared `SC` table (`SC.PANEL_WIDTH`, `SC.JoinList`,
`SC.mainFrame`, `SC.CreateMapPanel`, etc.) rather than a bare local
reference — Lua's `local` doesn't cross file boundaries, which is also
what caused the `SC_InitDB` bug fixed earlier in this project's history.

## License

No license has been chosen for this project yet. Until one is added, all
rights are reserved by the author — open an issue if you'd like to reuse or
fork this and want that clarified.
