# WoW: The Burning Crusade Anniversary - Raid Composition Optimiser
*Created by Béautiful - Spineshatter EU*

TBC Raid Comp Optimiser is a powerful, mathematically driven addon designed to automatically sort and optimize your 25-man raid compositions. By simply pasting your roster from Raid-Helper, the engine instantly organizes your raid into 5 perfect groups based on elite TBC Anniversary Edition meta rules. It ensures critical party-wide buffs (like Windfury, Totem of Wrath, and Ferocious Inspiration) are distributed flawlessly, while providing a real-time, dynamic checklist of all active raid synergies to guarantee your raid is fully optimized. 

## How to Use

To import your raid roster from Raid-Helper:
1. Click the **'comp'** link on your Raid-Helper sign-up list on Discord.
2. Click the **'GO TO EVENT'** icon on the webpage.
3. Click **JSON** in the top right corner of the page.
4. Type `/raidcomp` in game.
5. Copy and paste the full JSON string directly into the addon in-game.

## The Shaman Rule

Any good raid leader knows that Shamans are the backbone of a TBC raid. Even though Bloodlust and Heroism are now beautifully raid-wide in the Anniversary Edition, **Totems are still party-wide**. That means the absolute best comps run exactly 5 Shamans so you can put **one in every single group**.

Because of this, the Optimiser engine pulls out **all Shamans first** before it touches any other class, and distributes them exactly where they need to be:
- **Melee Groups (Group 2 & 3)**: It forcefully grabs **Enhancement Shamans** and locks them in here. Warriors and Rogues need Windfury Totem and Unleashed Rage to function.
- **Caster Group (Group 4)**: It grabs an **Elemental Shaman** so your Mages and Warlocks get Totem of Wrath (Spell Crit/Hit) and Wrath of Air (Spell Damage).
- **Healer Group (Group 5)**: It grabs a **Restoration Shaman** so your main healers get permanent Mana Tide Totem rotations.
- **Tank Group (Group 1)**: It drops a remaining Resto or flex Shaman in here for Healing Stream Totem, Grace of Air (for dodge), and Tremor Totem so your tanks don't get feared.

If you bring more than 5 Shamans (lucky you), it intelligently overflows them into the most logical backup groups.

## How the Rest of the Raid is Sorted

After the Shamans are perfectly locked in, it sorts the rest of the raid using the elite TBC 25-man meta composition rules:

### 1. The Tanks (Group 1)
- Protection Warriors, Protection Paladins, and Feral Bears are dumped in here.
- **Tree of Life**: The engine actively hunts down a **Restoration Druid** and places them into the Tank group. The *Tree of Life* aura passively increases healing received by everyone in the group by 25% of the Druid's spirit.
- **Blood Pact**: It pulls a Warlock from the ranged pile into the Tank group just so their Imp gives the tanks a massive stamina buff. 

### 2. The Hunter Group (Group 3)
- All Hunters are completely stripped out of the general ranged pool and aggressively clustered together into Group 3.
- **Ferocious Inspiration Stacking**: Because Beast Mastery hunters give a 3% damage boost to their party that natively stacks with other hunters, bunching them up creates exponential DPS returns.
- The engine also hunts down a **Feral Druid** specifically to buff this group with *Leader of the Pack* (5% crit), which directly increases the uptime of *Ferocious Inspiration* and *Expose Weakness*.

### 3. The Melee Pumpers (Group 2)
- Remaining **Feral Druids** and **Ret Paladins** are slotted in here for *Leader of the Pack* and *Sanctity Aura*.
- All remaining Fury/Arms Warriors and Rogues fill up the rest of the slots so they can soak up the physical damage auras alongside the Enhancement Shaman's *Windfury Totem*.

### 4. The Casters & Healers (Groups 4 & 5)
- **Utility Spreading**: Unlike simple sorting addons that clump all support classes together, this engine intelligently distributes your mana batteries. 
- It round-robins **Shadow Priests** and **Balance Druids** across the Caster Group (Group 4) and Healer Group (Group 5). This ensures their *Vampiric Touch* mana regeneration and *Moonkin Aura* (5% spell crit) are spread out perfectly to prevent wasted overlapping.
- Remaining pure casters (Mages/Warlocks) backfill into Group 4 with the Elemental Shaman, while remaining healers backfill into Group 5 with the Restoration Shaman.

## The Live Buff Checklist

Nobody wants to memorise all this. That's why the UI has a fully interactive, native icon checklist at the bottom of the window.
- It scans the groups you just built and cross-references them against every buff in the game.
- If your Melee group has an active Windfury Totem and Battle Shout, the icons light up fully coloured.
- If you're missing something critical (like no Sunder Armour or no Shadow Priest for the healers), the icon will be greyed out so you instantly know what you're missing.

## Advanced Engine Features

The addon has been significantly upgraded from simple static class tracking to a fully dynamic, context-aware engine:

### 1. Dynamic Context-Aware Buffs
Instead of locking static buffs to a player's spec, the engine actively inspects the role of the group they are placed in and intelligently swaps their buffs to maximize value:
- **Shamans**: A Resto Shaman manually dragged into a Melee or Tank group will dynamically unequip *Mana Spring Totem* and start providing *Windfury Totem* to their new group, instantly updating the UI checklist.
- **Warriors**: A Fury Warrior overflowing into a Casters group will intelligently drop *Battle Shout* and start shouting *Commanding Shout* to give the casters survivability.
- **Paladins**: A Holy Paladin moved to a Melee group will dynamically switch off *Concentration Aura* and provide the melee with *Devotion Aura* for physical damage reduction.

### 2. High-Resolution Faction Toggling
A sleek, high-resolution Alliance/Horde toggle on the UI dynamically tracks and swaps your faction spell variations. If you are Alliance, *Bloodlust* (Spell ID 2825) is instantly replaced with *Heroism* (Spell ID 32182) across the entire UI, complete with perfect tooltips and icons.

### 3. Hyper-Optimised `O(1)` Engine
The internal mathematics engine has been extensively refactored for massive 25-man parsing efficiency. Player totems and auras are calculated exactly once and cached directly onto the player object. The UI tracker utilizes a single-pass `O(N)` loop to build a hash map of raid statistics, eliminating hundreds of redundant loops and allowing the UI to instantly render and evaluate thousands of possible group variations with zero stutter. Memory generation is heavily strictly managed utilizing native `wipe()` API table recycling.
