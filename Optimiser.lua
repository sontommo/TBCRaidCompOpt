local AddonName, Addon = ...
Addon.Optimiser = {}

-- Localize globals for performance optimization
local table_insert = table.insert
local table_remove = table.remove
local ipairs = ipairs

local SPECS = {
    -- Warriors
    ["Arms"] = { class="Warrior", role="Melee", buffs={"Battle Shout", "Commanding Shout", "Blood Frenzy", "Sunder Armor", "Improved Demoralizing Shout", "Improved Thunder Clap"} },
    ["Fury"] = { class="Warrior", role="Melee", buffs={"Battle Shout", "Commanding Shout", "Sunder Armor", "Improved Demoralizing Shout"} },
    ["Protection"] = { class="Warrior", role="Tank", buffs={"Battle Shout", "Commanding Shout", "Sunder Armor", "Improved Demoralizing Shout", "Improved Thunder Clap"} },
    
    -- Paladins
    ["Holy1"] = { class="Paladin", role="Healer", buffs={"Blessing of Kings", "Blessing of Might", "Blessing of Wisdom", "Blessing of Salvation", "Devotion Aura", "Concentration Aura", "Judgement of Wisdom", "Judgement of Light"} },
    ["Holy"] = { class="Paladin", role="Healer", buffs={"Blessing of Kings", "Blessing of Might", "Blessing of Wisdom", "Blessing of Salvation", "Devotion Aura", "Concentration Aura", "Judgement of Wisdom", "Judgement of Light"} },
    ["Protection1"] = { class="Paladin", role="Tank", buffs={"Blessing of Kings", "Blessing of Might", "Blessing of Wisdom", "Blessing of Salvation", "Devotion Aura", "Retribution Aura", "Judgement of Wisdom", "Judgement of Light", "Blessing of Sanctuary"} },
    ["Retribution"] = { class="Paladin", role="Melee", buffs={"Blessing of Kings", "Blessing of Might", "Blessing of Wisdom", "Blessing of Salvation", "Sanctity Aura", "Retribution Aura", "Judgement of Wisdom", "Judgement of Light", "Improved Seal of the Crusader"} },
    ["Protection"] = { class="Warrior", role="Tank", buffs={"Battle Shout", "Commanding Shout", "Sunder Armor"} },
    
    -- Hunters
    ["Beastmastery"] = { class="Hunter", role="Ranged", buffs={"Ferocious Inspiration", "Scorpid Sting"} },
    ["Marksmanship"] = { class="Hunter", role="Ranged", buffs={"Trueshot Aura", "Scorpid Sting"} },
    ["Survival"] = { class="Hunter", role="Ranged", buffs={"Expose Weakness", "Scorpid Sting"} },
    
    -- Rogues
    ["Assassination"] = { class="Rogue", role="Melee", buffs={"Expose Armor", "Improved Expose Armor"} },
    ["Combat"] = { class="Rogue", role="Melee", buffs={"Expose Armor", "Improved Expose Armor"} },
    ["Subtlety"] = { class="Rogue", role="Melee", buffs={"Expose Armor", "Improved Expose Armor", "Hemorrhage"} },
    
    -- Priests
    ["Discipline"] = { class="Priest", role="Healer", buffs={"Power Word: Fortitude", "Shadow Protection", "Divine Spirit", "Pain Suppression"} },
    ["Holy"] = { class="Priest", role="Healer", buffs={"Power Word: Fortitude", "Shadow Protection"} },
    ["Shadow"] = { class="Priest", role="Ranged", buffs={"Power Word: Fortitude", "Shadow Protection", "Vampiric Touch", "Misery", "Shadow Weaving"} },
    ["Smite"] = { class="Priest", role="Ranged", buffs={"Power Word: Fortitude", "Shadow Protection"} },
    
    -- Shamans
    ["Elemental"] = { class="Shaman", role="Ranged", buffs={"Bloodlust", "Totem of Wrath", "Wrath of Air Totem", "Mana Spring Totem", "Tremor Totem"} },
    ["Enhancement"] = { class="Shaman", role="Melee", buffs={"Bloodlust", "Windfury Totem", "Unleashed Rage", "Strength of Earth Totem", "Grace of Air Totem", "Tremor Totem"} },
    ["Restoration1"] = { class="Shaman", role="Healer", buffs={"Bloodlust", "Mana Tide Totem", "Mana Spring Totem", "Wrath of Air Totem", "Healing Stream Totem", "Tremor Totem", "Earth Shield"} },
    ["Restoration"] = { class="Shaman", role="Healer", buffs={"Bloodlust", "Mana Tide Totem", "Mana Spring Totem", "Wrath of Air Totem", "Healing Stream Totem", "Tremor Totem", "Earth Shield"} },
    
    -- Mages
    ["Arcane"] = { class="Mage", role="Ranged", buffs={"Arcane Intellect"} },
    ["Fire"] = { class="Mage", role="Ranged", buffs={"Arcane Intellect", "Improved Scorch"} },
    ["Frost"] = { class="Mage", role="Ranged", buffs={"Arcane Intellect", "Winter's Chill"} },
    
    -- Warlocks
    ["Affliction"] = { class="Warlock", role="Ranged", buffs={"Curse of the Elements", "Curse of Recklessness", "Shadow Embrace", "Malediction", "Improved Healthstone"} },
    ["Demonology"] = { class="Warlock", role="Ranged", buffs={"Curse of the Elements", "Curse of Recklessness", "Improved Healthstone"} },
    ["Destruction"] = { class="Warlock", role="Ranged", buffs={"Curse of the Elements", "Curse of Recklessness", "Improved Healthstone", "Improved Shadow Bolt"} },
    
    -- Druids
    ["Balance"] = { class="Druid", role="Ranged", buffs={"Mark of the Wild", "Improved Mark of the Wild", "Moonkin Form", "Improved Faerie Fire", "Insect Swarm", "Innervate"} },
    ["Dreamstate"] = { class="Druid", role="Ranged", buffs={"Mark of the Wild", "Improved Mark of the Wild", "Improved Faerie Fire", "Innervate"} },
    ["Feral"] = { class="Druid", role="Melee", buffs={"Mark of the Wild", "Improved Mark of the Wild", "Leader of the Pack", "Mangle", "Faerie Fire", "Innervate"} },
    ["Guardian"] = { class="Druid", role="Tank", buffs={"Mark of the Wild", "Improved Mark of the Wild", "Leader of the Pack", "Mangle", "Faerie Fire", "Innervate"} },
    ["Restoration"] = { class="Druid", role="Healer", buffs={"Mark of the Wild", "Improved Mark of the Wild", "Tree of Life", "Innervate"} },
}

Addon.SPECS = SPECS

-- Map EVERY buff to its exact Spell ID to ensure GetSpellInfo resolves it regardless of spellbook cache
Addon.BUFF_SPELL_IDS = {
    ["Battle Shout"] = 2048,
    ["Commanding Shout"] = 469,
    ["Blood Frenzy"] = 29859,
    ["Sunder Armor"] = 7386,
    ["Blessing of Kings"] = 25898,
    ["Blessing of Might"] = 27141,
    ["Blessing of Wisdom"] = 25894,
    ["Blessing of Salvation"] = 25895,
    ["Devotion Aura"] = 465,
    ["Concentration Aura"] = 19746,
    ["Retribution Aura"] = 7294,
    ["Blessing of Sanctuary"] = 25899,
    ["Sanctity Aura"] = 20218,
    ["Judgement of Wisdom"] = 20355,
    ["Judgement of Light"] = 20185,
    ["Ferocious Inspiration"] = 34460,
    ["Trueshot Aura"] = 19506,
    ["Expose Weakness"] = 34503,
    ["Expose Armor"] = 8647,
    ["Hemorrhage"] = 16511,
    ["Power Word: Fortitude"] = 1243,
    ["Shadow Protection"] = 39374,
    ["Divine Spirit"] = 14752,
    ["Pain Suppression"] = 33206,
    ["Vampiric Touch"] = 34914,
    ["Misery"] = 33195,
    ["Shadow Weaving"] = 15332,
    ["Bloodlust"] = 2825,
    ["Totem of Wrath"] = 30706,
    ["Wrath of Air Totem"] = 3738,
    ["Mana Spring Totem"] = 5675,
    ["Tremor Totem"] = 8143,
    ["Windfury Totem"] = 8512,
    ["Unleashed Rage"] = 30809,
    ["Strength of Earth Totem"] = 8075,
    ["Grace of Air Totem"] = 8835,
    ["Mana Tide Totem"] = 16190,
    ["Healing Stream Totem"] = 5394,
    ["Earth Shield"] = 974,
    ["Arcane Intellect"] = 27127,
    ["Improved Scorch"] = 12873,
    ["Winter's Chill"] = 11180,
    ["Curse of the Elements"] = 27228,
    ["Curse of Recklessness"] = 27268,
    ["Shadow Embrace"] = 32385,
    ["Malediction"] = 32484,
    ["Improved Healthstone"] = 6262,
    ["Improved Shadow Bolt"] = 17803,
    ["Mark of the Wild"] = 26990,
    ["Improved Mark of the Wild"] = 16998,
    ["Moonkin Form"] = 24907,
    ["Improved Faerie Fire"] = 33602,
    ["Insect Swarm"] = 27013,
    ["Leader of the Pack"] = 24932,
    ["Mangle"] = 33878,
    ["Faerie Fire"] = 26993,
    ["Tree of Life"] = 33891,
    ["Innervate"] = 29166,
    ["Improved Demoralizing Shout"] = 12879,
    ["Improved Thunder Clap"] = 12666,
    ["Improved Seal of the Crusader"] = 20336,
    ["Scorpid Sting"] = 3043,
    ["Improved Expose Armor"] = 14169,
}

Addon.PHYSICAL_BUFFS = {
    ["Blessing of Might"] = true,
    ["Windfury Totem"] = true,
    ["Unleashed Rage"] = true,
    ["Leader of the Pack"] = true,
    ["Sanctity Aura"] = true,
    ["Trueshot Aura"] = true,
    ["Ferocious Inspiration"] = true,
    ["Expose Weakness"] = true,
    ["Expose Armor"] = true,
    ["Sunder Armor"] = true,
    ["Blood Frenzy"] = true,
    ["Hemorrhage"] = true,
    ["Battle Shout"] = true,
    ["Mangle"] = true,
    ["Faerie Fire"] = true,
    ["Commanding Shout"] = true,
    ["Improved Demoralizing Shout"] = true,
    ["Improved Thunder Clap"] = true,
    ["Improved Expose Armor"] = true,
    ["Scorpid Sting"] = true,
}

Addon.SPELL_BUFFS = {
    ["Blessing of Wisdom"] = true,
    ["Mana Spring Totem"] = true,
    ["Mana Tide Totem"] = true,
    ["Vampiric Touch"] = true,
    ["Moonkin Form"] = true,
    ["Totem of Wrath"] = true,
    ["Wrath of Air Totem"] = true,
    ["Arcane Intellect"] = true,
    ["Improved Scorch"] = true,
    ["Curse of the Elements"] = true,
    ["Shadow Weaving"] = true,
    ["Misery"] = true,
    ["Divine Spirit"] = true,
    ["Judgement of Wisdom"] = true,
    ["Malediction"] = true,
    ["Winter's Chill"] = true,
    ["Improved Shadow Bolt"] = true,
    ["Improved Seal of the Crusader"] = true,
}

Addon.IGNORED_UI_BUFFS = {
    ["Tremor Totem"] = true,
    ["Power Word: Fortitude"] = true,
    ["Shadow Protection"] = true,
    ["Devotion Aura"] = true,
    ["Concentration Aura"] = true,
    ["Retribution Aura"] = true,
    ["Blessing of Sanctuary"] = true,
    ["Healing Stream Totem"] = true,
    ["Pain Suppression"] = true,
    ["Tree of Life"] = true,
    ["Mark of the Wild"] = true,
    ["Improved Mark of the Wild"] = true,
    ["Judgement of Light"] = true,
    ["Earth Shield"] = true,
    ["Improved Healthstone"] = true,
    ["Innervate"] = true,
}

function Addon.Optimiser:GetPlayerRole(spec)
    if SPECS[spec] then return SPECS[spec].role end
    return "Unknown"
end

function Addon.Optimiser:Optimise(players)
    local groups = {{}, {}, {}, {}, {}}
    local function getFree(g) return 5 - #groups[g] end
    local function addToGroup(p, g)
        if getFree(g) > 0 then
            table_insert(groups[g], p)
            return true
        end
        return false
    end

    local shamans = {}
    local tanks = {}
    local healers = {}
    local melee = {}
    local ranged = {}
    
    for _, p in ipairs(players) do
        if p.class == "Shaman" then
            table_insert(shamans, p)
        else
            local role = self:GetPlayerRole(p.spec)
            if role == "Tank" or p.spec:match("Protection") or p.spec == "Guardian" then
                table_insert(tanks, p)
            elseif role == "Healer" or p.spec:match("Restoration") or p.spec:match("Holy") or p.spec == "Discipline" then
                table_insert(healers, p)
            elseif role == "Melee" then
                table_insert(melee, p)
            else
                table_insert(ranged, p)
            end
        end
    end
    
    -- Shaman Priority Matrix
    local shamanAssignments = {nil, nil, nil, nil, nil}
    local function assignShaman(groupIndex, preferredSpecs)
        if shamanAssignments[groupIndex] then return end
        for i, s in ipairs(shamans) do
            for _, spec in ipairs(preferredSpecs) do
                if s.spec == spec or (spec == "Restoration" and s.spec == "Restoration1") then
                    shamanAssignments[groupIndex] = s
                    table_remove(shamans, i)
                    return true
                end
            end
        end
        return false
    end
    
    assignShaman(2, {"Enhancement"})
    assignShaman(3, {"Enhancement"})
    assignShaman(4, {"Elemental"})
    assignShaman(5, {"Restoration", "Restoration1"})
    assignShaman(1, {"Restoration", "Restoration1", "Enhancement", "Elemental"})
    
    for g=1, 5 do
        if not shamanAssignments[g] and #shamans > 0 then
            shamanAssignments[g] = table_remove(shamans, 1)
        end
    end
    
    for g=1, 5 do
        if shamanAssignments[g] then
            addToGroup(shamanAssignments[g], g)
        end
    end
    
    for _, s in ipairs(shamans) do
        if s.spec == "Enhancement" then
            if getFree(2) > 0 then addToGroup(s, 2)
            elseif getFree(3) > 0 then addToGroup(s, 3)
            else addToGroup(s, 1) end
        elseif s.spec == "Elemental" then
            if getFree(4) > 0 then addToGroup(s, 4)
            else addToGroup(s, 5) end
        else
            if getFree(5) > 0 then addToGroup(s, 5)
            else addToGroup(s, 1) end
        end
    end

    -- G1: Tanks
    for _, p in ipairs(tanks) do addToGroup(p, 1) end
    
    -- Warlock for Blood Pact in Tank Group
    for i = #ranged, 1, -1 do
        if getFree(1) > 0 and ranged[i].class == "Warlock" then
            addToGroup(ranged[i], 1)
            table_remove(ranged, i)
            break
        end
    end
    
    -- Restoration Druid for Tanks (Tree of Life)
    local foundRestoDruidForTanks = false
    for i = #healers, 1, -1 do
        if getFree(1) > 0 and healers[i].class == "Druid" and (healers[i].spec:match("Restoration") or healers[i].spec == "Restoration1") then
            addToGroup(healers[i], 1)
            table_remove(healers, i)
            foundRestoDruidForTanks = true
            break
        end
    end
    -- Fallback to Holy Paladin if no Resto Druid available for tank group
    if not foundRestoDruidForTanks then
        for i = #healers, 1, -1 do
            if getFree(1) > 0 and healers[i].class == "Paladin" then
                addToGroup(healers[i], 1)
                table_remove(healers, i)
                break
            end
        end
    end

    -- Extract Hunters to group them tightly in G3
    local hunters = {}
    for i = #ranged, 1, -1 do
        if ranged[i].class == "Hunter" then
            table_insert(hunters, ranged[i])
            table_remove(ranged, i)
        end
    end

    -- G3: Hunters & Feral Synergy
    -- Find one Feral Druid for the hunters if possible
    for i = #melee, 1, -1 do
        if getFree(3) > 0 and melee[i].spec == "Feral" and #hunters > 0 then
            addToGroup(melee[i], 3)
            table_remove(melee, i)
            break
        end
    end
    
    -- Add hunters to G3 (spill to G2 or G4 if full)
    for _, h in ipairs(hunters) do
        if getFree(3) > 0 then addToGroup(h, 3)
        elseif getFree(2) > 0 then addToGroup(h, 2)
        elseif getFree(4) > 0 then addToGroup(h, 4)
        else addToGroup(h, 5) end
    end

    -- G2: Melee (Feral, Ret, Rogues, Warriors)
    local function placeMeleeSupport(specName)
        for i = #melee, 1, -1 do
            if melee[i].spec == specName then
                if getFree(2) > 0 then addToGroup(melee[i], 2)
                elseif getFree(3) > 0 then addToGroup(melee[i], 3) end
                table_remove(melee, i)
            end
        end
    end
    -- Any remaining Feral Druids go to melee
    placeMeleeSupport("Feral")
    -- Ret Paladins go to melee
    placeMeleeSupport("Retribution")
    
    for i = #melee, 1, -1 do
        if getFree(2) > 0 then addToGroup(melee[i], 2)
        elseif getFree(3) > 0 then addToGroup(melee[i], 3)
        elseif getFree(4) > 0 then addToGroup(melee[i], 4)
        elseif getFree(1) > 0 then addToGroup(melee[i], 1) end
    end

    -- G5: Healers
    for i = #healers, 1, -1 do
        if getFree(5) > 0 then addToGroup(healers[i], 5)
        elseif getFree(4) > 0 then addToGroup(healers[i], 4)
        elseif getFree(3) > 0 then addToGroup(healers[i], 3) end
    end

    -- G4: Casters & Ranged (Shadow Priest, Boomkin, Mages, Warlocks)
    local function groupHasSpec(gIndex, specName)
        for _, p in ipairs(groups[gIndex]) do
            if p.spec == specName then return true end
        end
        return false
    end

    local function placeRangedSupport(specName)
        for i = #ranged, 1, -1 do
            if ranged[i].spec == specName then
                if getFree(4) > 0 and not groupHasSpec(4, specName) then addToGroup(ranged[i], 4)
                elseif getFree(5) > 0 and not groupHasSpec(5, specName) then addToGroup(ranged[i], 5)
                elseif getFree(3) > 0 and not groupHasSpec(3, specName) then addToGroup(ranged[i], 3)
                elseif getFree(4) > 0 then addToGroup(ranged[i], 4)
                elseif getFree(5) > 0 then addToGroup(ranged[i], 5)
                elseif getFree(3) > 0 then addToGroup(ranged[i], 3) end
                table_remove(ranged, i)
            end
        end
    end
    placeRangedSupport("Balance")
    placeRangedSupport("Shadow")
    
    for i = #ranged, 1, -1 do
        if getFree(4) > 0 then addToGroup(ranged[i], 4)
        elseif getFree(5) > 0 then addToGroup(ranged[i], 5)
        elseif getFree(3) > 0 then addToGroup(ranged[i], 3)
        elseif getFree(2) > 0 then addToGroup(ranged[i], 2)
        elseif getFree(1) > 0 then addToGroup(ranged[i], 1) end
    end

    self:RefreshGroupBuffs(groups)

    return groups
end

function Addon.Optimiser:RefreshGroupBuffs(groups)
    for g=1, 5 do
        local groupRole = "Mixed"
        local counts = { Tank=0, Healer=0, Melee=0, Ranged=0 }
        
        for _, p in ipairs(groups[g]) do
            local role = self:GetPlayerRole(p.spec)
            if role then counts[role] = (counts[role] or 0) + 1 end
        end
        if counts.Tank >= 2 then groupRole = "Tanks"
        elseif counts.Healer >= 3 then groupRole = "Healers"
        elseif counts.Melee > 0 and counts.Ranged > 0 then groupRole = "DPS"
        elseif counts.Melee >= 3 then groupRole = "Melee"
        elseif counts.Ranged >= 3 then groupRole = "Casters"
        end
        groups[g].label = groupRole
        
        groups[g].buffs = {}
        local seenBuffs = {}
        
        local isCasterOrHealer = (groupRole == "Casters" or groupRole == "Healers")
        local isMeleeOrTank = (groupRole == "Melee" or groupRole == "Tanks")
        
        for _, p in ipairs(groups[g]) do
            local sInfo = SPECS[p.spec]
            if sInfo then
                for _, buffName in ipairs(sInfo.buffs) do
                    local skip = false
                    if Addon.IGNORED_UI_BUFFS and Addon.IGNORED_UI_BUFFS[buffName] then
                        skip = true
                    elseif isCasterOrHealer and Addon.PHYSICAL_BUFFS[buffName] then
                        skip = true
                    elseif isMeleeOrTank and Addon.SPELL_BUFFS[buffName] then
                        skip = true
                    end
                    
                    if not skip and not seenBuffs[buffName] then
                        seenBuffs[buffName] = true
                        table_insert(groups[g].buffs, buffName)
                    end
                end
            end
        end
    end
end

function Addon.Optimiser:AnalyzeBuffs(groups)
    local categories = {}
    local currentCat = nil
    
    local function addCategory(name)
        currentCat = { name = name, items = {} }
        table_insert(categories, currentCat)
    end
    
    local function addBuff(text, active, spellName)
        if currentCat then
            table_insert(currentCat.items, { text=text, active=active, spellName=spellName })
        end
    end
    
    local function hasRaidBuff(buffName)
        for g=1, 5 do
            for _, p in ipairs(groups[g]) do
                local sInfo = SPECS[p.spec]
                if sInfo then
                    for _, b in ipairs(sInfo.buffs) do
                        if b == buffName then return true end
                    end
                end
            end
        end
        return false
    end
    
    local function hasClass(className)
        for g=1, 5 do
            for _, p in ipairs(groups[g]) do
                if p.class == className then return true end
            end
        end
        return false
    end

    local function countClass(className)
        local count = 0
        for g=1, 5 do
            for _, p in ipairs(groups[g]) do
                if p.class == className then count = count + 1 end
            end
        end
        return count
    end

    local function checkGroupBuff(gIndex, buffName)
        for _, p in ipairs(groups[gIndex]) do
            local specInfo = SPECS[p.spec]
            if specInfo then
                for _, b in ipairs(specInfo.buffs) do
                    if b == buffName then return true end
                end
            end
        end
        return false
    end
    
    local function countRole(gIndex, role)
        local c = 0
        for _, p in ipairs(groups[gIndex]) do
            if Addon.Optimiser:GetPlayerRole(p.spec) == role then c = c + 1 end
        end
        return c
    end

    addCategory("Raid Buffs")
    addBuff("Bloodlust / Heroism", hasClass("Shaman"), "Bloodlust/Heroism")
    addBuff("Power Word: Fortitude", hasClass("Priest"), "Power Word: Fortitude")
    addBuff("Shadow Protection", hasClass("Priest"), "Shadow Protection")
    addBuff("Mark of the Wild", hasClass("Druid"), "Mark of the Wild")
    addBuff("Arcane Brilliance", hasClass("Mage"), "Arcane Brilliance")
    
    local numPaladins = countClass("Paladin")
    addBuff("Blessing of Kings", numPaladins >= 1, "Blessing of Kings")
    addBuff("Blessing of Might", numPaladins >= 2, "Blessing of Might")
    addBuff("Blessing of Wisdom", numPaladins >= 3, "Blessing of Wisdom")
    addBuff("Blessing of Salvation", numPaladins >= 4, "Blessing of Salvation")

    addBuff("Divine Spirit", hasRaidBuff("Divine Spirit"), "Divine Spirit")

    addCategory("Raid Debuffs (Target)")
    addBuff("Sunder / Expose Armor", hasRaidBuff("Sunder Armor") or hasRaidBuff("Expose Armor"), "Sunder Armor")
    addBuff("Curse of the Elements", hasRaidBuff("Curse of the Elements"), "Curse of the Elements")
    addBuff("Curse of Recklessness", hasRaidBuff("Curse of Recklessness"), "Curse of Recklessness")
    addBuff("Misery", hasRaidBuff("Misery"), "Misery")
    addBuff("Shadow Weaving", hasRaidBuff("Shadow Weaving"), "Shadow Weaving")
    addBuff("Improved Scorch", hasRaidBuff("Improved Scorch"), "Improved Scorch")
    addBuff("Blood Frenzy (Phys Dmg)", hasRaidBuff("Blood Frenzy"), "Blood Frenzy")
    addBuff("Expose Weakness", hasRaidBuff("Expose Weakness"), "Expose Weakness")
    addBuff("Mangle (Bleed Dmg)", hasRaidBuff("Mangle"), "Mangle")
    addBuff("Judgement of Wisdom", hasRaidBuff("Judgement of Wisdom"), "Judgement of Wisdom")
    addBuff("Judgement of Light", hasRaidBuff("Judgement of Light"), "Judgement of Light")
    addBuff("Improved Faerie Fire", hasRaidBuff("Improved Faerie Fire"), "Improved Faerie Fire")
    
    addCategory("Melee Group Buffs")
    local meleeWF, meleeLotP, meleeUR, meleeBS, meleeSA = false, false, false, false, false
    for g=1, 5 do
        if countRole(g, "Melee") >= 2 then
            if checkGroupBuff(g, "Windfury Totem") then meleeWF = true end
            if checkGroupBuff(g, "Leader of the Pack") then meleeLotP = true end
            if checkGroupBuff(g, "Unleashed Rage") then meleeUR = true end
            if checkGroupBuff(g, "Battle Shout") then meleeBS = true end
            if checkGroupBuff(g, "Sanctity Aura") then meleeSA = true end
        end
    end
    addBuff("Windfury Totem", meleeWF, "Windfury Totem")
    addBuff("Leader of the Pack", meleeLotP, "Leader of the Pack")
    addBuff("Unleashed Rage", meleeUR, "Unleashed Rage")
    addBuff("Battle Shout", meleeBS, "Battle Shout")
    addBuff("Sanctity Aura", meleeSA, "Sanctity Aura")

    addCategory("Caster Group Buffs")
    local casterWoA, casterToW, casterMA, casterVT = false, false, false, false
    for g=1, 5 do
        if countRole(g, "Ranged") >= 2 then
            if checkGroupBuff(g, "Wrath of Air Totem") then casterWoA = true end
            if checkGroupBuff(g, "Totem of Wrath") then casterToW = true end
            if checkGroupBuff(g, "Moonkin Aura") then casterMA = true end
            if checkGroupBuff(g, "Vampiric Touch") then casterVT = true end
        end
    end
    addBuff("Wrath of Air Totem", casterWoA, "Wrath of Air Totem")
    addBuff("Totem of Wrath", casterToW, "Totem of Wrath")
    addBuff("Moonkin Aura", casterMA, "Moonkin Aura")
    addBuff("Vampiric Touch", casterVT, "Vampiric Touch")
    
    addCategory("Healer Group Buffs")
    local healerMT, healerToL = false, false
    for g=1, 5 do
        if countRole(g, "Healer") >= 2 then
            if checkGroupBuff(g, "Mana Tide Totem") then healerMT = true end
            if checkGroupBuff(g, "Tree of Life Aura") then healerToL = true end
        end
    end
    addBuff("Mana Tide Totem", healerMT, "Mana Tide Totem")
    addBuff("Tree of Life Aura", healerToL, "Tree of Life Aura")
    
    addCategory("Tank Group Buffs")
    local tankBP, tankDA = false, false
    for g=1, 5 do
        if countRole(g, "Tank") >= 1 then
            if checkGroupBuff(g, "Blood Pact") then tankBP = true end
            if checkGroupBuff(g, "Devotion Aura") then tankDA = true end
        end
    end
    addBuff("Blood Pact", tankBP, "Blood Pact")
    addBuff("Devotion Aura", tankDA, "Devotion Aura")

    return categories
end
