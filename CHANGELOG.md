# Changelog

All notable changes to this project will be documented in this file.

## [v1.1.1] - UI Refinements & Tank Synergies
### Added
- **Faction Toggle**: Added an Alliance / Horde radio button toggle to the main UI. It dynamically tracks and swaps the *Bloodlust* (Horde, ID 2825) and *Heroism* (Alliance, ID 32182) spell names, icons, and tooltips seamlessly across the entire UI depending on your faction. Default is Alliance.
- **Multi-Row Group Headers**: Group headers have been expanded and refactored using a flex-grid layout. They can now display up to 24 buff icons over 3 visually packed rows, guaranteeing all synergies are visible.
- **Dynamic DPS Group Tags**: Mixed physical and caster groups (like Hunter/Shaman/Druid) are now smartly labeled as "DPS" rather than forcing a strict "Melee" or "Casters" label.
- **Tank Blood Pact**: *Blood Pact* (Spell ID 27268) is now classified as a survival utility and stripped from all UI headers, *except* for the Tanks group, where the stamina gain is critically flagged as a primary tank synergy!

### Fixed
- Fixed an issue where the Buffs & Debuffs checklist panel would visually overlap the player groups when expanded.
- Fixed spell ID mapping conflicts for Warlocks and securely anchored *Bloodlust* to Spell ID 2825.


## [v1.1] - Advanced Meta & Interactive UI
### Added
- **Interactive Drag & Drop**: Players can now be manually dragged and dropped between groups in the UI to fine-tune synergies. Buffs are instantly recalculated and redrawn upon swapping.
- **Dynamic Group Header Icons**: Group headers now explicitly scrape and display a row of interactive WoW buff icons showing exactly what synergies that group generates for itself.
- **Intelligent Buff Filtering**: Irrelevant or non-throughput buffs (like *Blessing of Might* for Healers, or *Vampiric Touch* for physical Melee) are intelligently hidden from group headers to declutter the UI.
- **Utility Class Spreading**: The engine now actively round-robins Shadow Priests and Balance Druids across Caster and Healer groups to maximize *Vampiric Touch* and *Moonkin Aura* uptime without double-stacking.
- **Hunter Synergy Clustering**: All Hunters are now forcefully isolated into a single physical group, alongside a Feral Druid, to maximize exponential *Ferocious Inspiration* and *Leader of the Pack* scaling.
- **Tree of Life Priority**: Restoration Druids are now aggressively pulled into the Tank group for the *Tree of Life* aura healing bonus.

### Fixed
- Fixed an issue where generic "Blessings" displayed as a missing texture; explicitly replaced with individual Paladin Blessings for accurate UI mapping.
- Fixed a bug where Raid-Helper's trailing backend identifiers (e.g. `Holy1`, `Protection1`) would display ugly text in the UI. The UI now dynamically strips these trailing digits during render while perfectly preserving the logical backend matching.


## [v1.0] - Initial Release
### Added
- **Initial Release** of the WoW: The Burning Crusade Anniversary - Raid Composition Optimiser.
- Built a mathematical engine to automatically sort 25-man raid rosters imported from a Raid-Helper JSON string into 5 mathematically optimal groups.
- Implemented a strict Shaman priority matrix ensuring the "One Shaman Per Group" meta, appropriately assigning Enhancement to Melee, Elemental to Casters, and Restoration to Healers.
- Implemented deterministic synergy sorting for Tanks, Melee Pumpers, Casters, and Healers.
- Added a dynamic, native World of Warcraft UI window with a live, interactive Buff & Debuff icon checklist.
- Added a re-flowable UI flexbox-style grid system with dynamic group centering.
- Fully supported and dynamically integrated all class buffs natively using cached TBC Spell IDs.
