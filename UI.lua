local AddonName, Addon = ...
Addon.UI = {}
Addon.Faction = "Alliance"

-- Localize globals for performance optimization
local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local table_insert = table.insert
local ipairs = ipairs
local math_floor = math.floor
local math_abs = math.abs

-- Cache for spell icons to avoid redundant C-API lookups
local IconCache = {}

local function CreateGhostFrame()
    local ghost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ghost:SetSize(164, 28)
    ghost:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    ghost:SetBackdropColor(0.25, 0.25, 0.25, 0.8)
    ghost:SetFrameStrata("TOOLTIP")
    ghost.text = ghost:CreateFontString(nil, "OVERLAY")
    ghost.text:SetFontObject("GameFontHighlightSmall")
    ghost.text:SetAllPoints()
    ghost.text:SetJustifyH("LEFT")
    ghost:Hide()
    return ghost
end

local CLASS_COLORS = {
    ["Warrior"] = "|cFFC79C6E",
    ["Paladin"] = "|cFFF58CBA",
    ["Hunter"]  = "|cFFABD473",
    ["Rogue"]   = "|cFFFFF569",
    ["Priest"]  = "|cFFFFFFFF",
    ["Shaman"]  = "|cFF0070DE",
    ["Mage"]    = "|cFF69CCF0",
    ["Warlock"] = "|cFF9482C9",
    ["Druid"]   = "|cFFFF7D0A",
}

local function CreateSleekFrame(parent, name)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.12, 0.12, 0.12, 0.95)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    return f
end

local function CreateSleekButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.2, 0.2, 0.2, 1)
    btn:SetBackdropBorderColor(0, 0, 0, 1)
    
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject("GameFontHighlight")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    btn.text = fs
    
    btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.3, 0.3, 0.3, 1) end)
    btn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.2, 0.2, 0.2, 1) end)
    btn:SetScript("OnMouseDown", function(self) self:SetBackdropColor(0.15, 0.15, 0.15, 1) end)
    btn:SetScript("OnMouseUp", function(self) self:SetBackdropColor(0.3, 0.3, 0.3, 1) end)
    
    return btn
end

function Addon.UI:CreateMainFrame()
    -- Main Window
    local f = CreateSleekFrame(UIParent, "TBCRaidCompFrame")
    f:SetSize(1150, 700)
    f:SetResizeBounds(620, 500, 1600, 1200)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:SetResizable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    local resizeBtn = CreateFrame("Button", nil, f)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", -2, 2)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            f:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeBtn:SetScript("OnMouseUp", function(self, button)
        f:StopMovingOrSizing()
    end)
    
    f:SetScript("OnSizeChanged", function(self, width, height)
        Addon.UI:Reflow()
    end)
    
    -- Title Bar
    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(30)
    titleBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    titleBar:SetBackdropColor(0.08, 0.08, 0.08, 1)
    
    f.title = titleBar:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject("GameFontHighlightLarge")
    f.title:SetPoint("LEFT", 10, 0)
    f.title:SetText("WoW: The Burning Crusade Anniversary - Raid Composition Optimiser")
    
    local closeBtn = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
    closeBtn:SetPoint("RIGHT", 0, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    -- Import JSON Button (Main View)
    local importBtn = CreateSleekButton(f, "Import Raid-Helper JSON", 200, 30)
    importBtn:SetPoint("TOPLEFT", 20, -45)
    importBtn:SetScript("OnClick", function()
        Addon.UI.ImportFrame:Show()
    end)
    
    -- Faction Toggle
    local factionFrame = CreateFrame("Frame", nil, f)
    factionFrame:SetSize(120, 30)
    factionFrame:SetPoint("LEFT", importBtn, "RIGHT", 40, 0)
    factionFrame:SetScale(1.5)
    
    local allianceBtn = CreateFrame("CheckButton", nil, factionFrame, "UIRadioButtonTemplate")
    allianceBtn:SetPoint("LEFT", 0, 0)
    local allianceTex = allianceBtn:CreateTexture(nil, "OVERLAY")
    allianceTex:SetSize(24, 24)
    allianceTex:SetPoint("LEFT", allianceBtn, "RIGHT", 2, 0)
    allianceTex:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
    allianceBtn:SetChecked(true)
    
    local hordeBtn = CreateFrame("CheckButton", nil, factionFrame, "UIRadioButtonTemplate")
    hordeBtn:SetPoint("LEFT", allianceTex, "RIGHT", 10, 0)
    local hordeTex = hordeBtn:CreateTexture(nil, "OVERLAY")
    hordeTex:SetSize(24, 24)
    hordeTex:SetPoint("LEFT", hordeBtn, "RIGHT", 2, 0)
    hordeTex:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
    hordeBtn:SetChecked(false)
    
    local function UpdateFaction(faction)
        Addon.Faction = faction
        if Addon.Core and Addon.Core.CurrentGroups then
            local buffs = Addon.Optimiser:AnalyzeBuffs(Addon.Core.CurrentGroups)
            Addon.UI:RenderGroups(Addon.Core.CurrentGroups, buffs)
        end
    end
    
    allianceBtn:SetScript("OnClick", function(self)
        self:SetChecked(true)
        hordeBtn:SetChecked(false)
        UpdateFaction("Alliance")
    end)
    
    hordeBtn:SetScript("OnClick", function(self)
        self:SetChecked(true)
        allianceBtn:SetChecked(false)
        UpdateFaction("Horde")
    end)
    
    -- Groups Grid Container
    local groupsContainer = CreateFrame("Frame", nil, f)
    groupsContainer:SetPoint("TOPLEFT", 20, -90)
    f.groupsContainer = groupsContainer
    
    f.groupFrames = {}
    for i=1, 5 do
        local gf = CreateSleekFrame(groupsContainer)
        gf:SetSize(180, 330)
        gf:SetBackdropColor(0.15, 0.15, 0.15, 1)
        
        local labelBg = CreateFrame("Frame", nil, gf, "BackdropTemplate")
        labelBg:SetPoint("TOPLEFT", 1, -1)
        labelBg:SetPoint("TOPRIGHT", -1, -1)
        labelBg:SetHeight(70)
        labelBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        labelBg:SetBackdropColor(0.1, 0.1, 0.1, 1)
        
        local label = labelBg:CreateFontString(nil, "OVERLAY")
        label:SetFontObject("GameFontNormal")
        label:SetPoint("TOP", 0, -6)
        label:SetText("Group " .. i)
        gf.label = label
        
        local groupIconContainer = CreateFrame("Frame", nil, labelBg)
        groupIconContainer:SetSize(160, 48)
        groupIconContainer:SetPoint("TOP", 0, -20)
        gf.groupIconContainer = groupIconContainer
        gf.groupIcons = {}
        for k=1, 24 do
            local iconF = CreateFrame("Frame", nil, groupIconContainer)
            iconF:SetSize(14, 14)
            local row = math_floor((k-1) / 10)
            local col = (k-1) % 10
            iconF:SetPoint("TOPLEFT", col*16, -row*16)
            iconF:EnableMouse(true)
            local tex = iconF:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            iconF.texture = tex
            
            iconF:SetScript("OnEnter", function(self)
                if self.spellName then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[self.spellName]) or self.spellName
                    if type(query) == "number" then
                        GameTooltip:SetSpellByID(query)
                    else
                        GameTooltip:SetText(self.spellName, 1, 1, 1)
                    end
                    GameTooltip:Show()
                end
            end)
            iconF:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
            iconF:Hide()
            table_insert(gf.groupIcons, iconF)
        end
        
        gf.players = {}
        gf.playerIcons = {}
        for p=1, 5 do
            local pf = CreateFrame("Button", nil, gf, "BackdropTemplate")
            pf:SetSize(164, 28)
            pf:SetPoint("TOPLEFT", 8, -10 - (p-1)*48 - 75)
            pf:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
            pf:SetBackdropColor(0.25, 0.25, 0.25, 0.5)
            
            local highlight = pf:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetAllPoints()
            highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            highlight:SetBlendMode("ADD")
            highlight:SetAlpha(0.4)
            
            local pfText = pf:CreateFontString(nil, "OVERLAY")
            pfText:SetFontObject("GameFontHighlightSmall")
            pfText:SetAllPoints()
            pfText:SetJustifyH("LEFT")
            pfText:SetText("")
            pf.text = pfText
            
            pf.groupIndex = i
            pf.playerIndex = p
            
            pf:RegisterForDrag("LeftButton")
            pf:SetScript("OnDragStart", function(self)
                if not Addon.Core.CurrentGroups or not Addon.Core.CurrentGroups[self.groupIndex][self.playerIndex] then return end
                Addon.UI.DraggingPlayer = { groupIndex = self.groupIndex, playerIndex = self.playerIndex }
                self:SetAlpha(0.3)
                
                if not Addon.UI.GhostFrame then Addon.UI.GhostFrame = CreateGhostFrame() end
                local ghost = Addon.UI.GhostFrame
                ghost.text:SetText(self.text:GetText())
                ghost:Show()
                ghost:SetScript("OnUpdate", function(f)
                    if not IsMouseButtonDown("LeftButton") then
                        f:SetScript("OnUpdate", nil)
                        f:Hide()
                        Addon.UI.DraggingPlayer = nil
                        if Addon.Core.CurrentGroups then
                            local buffs = Addon.Optimiser:AnalyzeBuffs(Addon.Core.CurrentGroups)
                            Addon.UI:RenderGroups(Addon.Core.CurrentGroups, buffs)
                        end
                        return
                    end
                    local x, y = GetCursorPosition()
                    local scale = f:GetEffectiveScale()
                    f:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
                end)
            end)
            
            pf:SetScript("OnReceiveDrag", function(self)
                if not Addon.UI.DraggingPlayer then return end
                local drag = Addon.UI.DraggingPlayer
                
                if drag.groupIndex == self.groupIndex and drag.playerIndex == self.playerIndex then
                    self:SetAlpha(1)
                    if Addon.UI.GhostFrame then 
                        Addon.UI.GhostFrame:SetScript("OnUpdate", nil)
                        Addon.UI.GhostFrame:Hide()
                    end
                    Addon.UI.DraggingPlayer = nil
                    return
                end
                
                local groups = Addon.Core.CurrentGroups
                if not groups then return end
                
                local g1 = groups[drag.groupIndex]
                local g2 = groups[self.groupIndex]
                
                local p1 = g1[drag.playerIndex]
                local p2 = g2[self.playerIndex]
                
                if p2 then
                    g1[drag.playerIndex] = p2
                    g2[self.playerIndex] = p1
                else
                    table.remove(g1, drag.playerIndex)
                    table.insert(g2, p1)
                end
                
                if Addon.UI.GhostFrame then 
                    Addon.UI.GhostFrame:SetScript("OnUpdate", nil)
                    Addon.UI.GhostFrame:Hide()
                end
                Addon.UI.DraggingPlayer = nil
                
                Addon.Optimiser:RefreshGroupBuffs(groups)
                local buffs = Addon.Optimiser:AnalyzeBuffs(groups)
                Addon.UI:RenderGroups(groups, buffs)
            end)
            
            pf:SetScript("OnMouseUp", function(self)
                if Addon.UI.DraggingPlayer then
                    self:GetScript("OnReceiveDrag")(self)
                end
            end)
            
            table_insert(gf.players, pf)
            
            -- Prepare a container for icons
            local iconContainer = CreateFrame("Frame", nil, gf)
            iconContainer:SetSize(164, 16)
            iconContainer:SetPoint("TOPLEFT", pf, "BOTTOMLEFT", 0, -2)
            
            local icons = {}
            for k=1, 8 do
                local iconFrame = CreateFrame("Frame", nil, iconContainer)
                iconFrame:SetSize(14, 14)
                iconFrame:SetPoint("LEFT", (k-1)*16, 0)
                iconFrame:EnableMouse(true)
                
                local tex = iconFrame:CreateTexture(nil, "ARTWORK")
                tex:SetAllPoints()
                iconFrame.texture = tex
                
                iconFrame:SetScript("OnEnter", function(self)
                    if self.spellName then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[self.spellName]) or self.spellName
                        if type(query) == "number" then
                            GameTooltip:SetSpellByID(query)
                        else
                            GameTooltip:SetText(self.spellName, 1, 1, 1)
                        end
                        GameTooltip:Show()
                    end
                end)
                iconFrame:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
                
                iconFrame:Hide()
                table_insert(icons, iconFrame)
            end
            table_insert(gf.playerIcons, icons)
        end
        
        table_insert(f.groupFrames, gf)
    end
    
    -- Buffs Checklist Area (below groups)
    local buffsBg = CreateSleekFrame(f)
    buffsBg:SetPoint("BOTTOMLEFT", 20, 20)
    buffsBg:SetBackdropColor(0.15, 0.15, 0.15, 1)
    
    local buffsScrollFrame = CreateFrame("ScrollFrame", "TBCRaidCompBuffsScroll", buffsBg, "UIPanelScrollFrameTemplate")
    buffsScrollFrame:SetPoint("TOPLEFT", 5, -5)
    buffsScrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)
    
    local buffsContent = CreateFrame("Frame", nil, buffsScrollFrame)
    buffsContent:SetSize(500, 200)
    buffsScrollFrame:SetScrollChild(buffsContent)
    
    f.buffsBg = buffsBg
    f.buffsContent = buffsContent
    f.categoryFrames = {}
    
    Addon.MainFrame = f
    
    -- CREATE IMPORT MODAL
    local importF = CreateSleekFrame(f, "TBCRaidCompImportFrame")
    importF:SetSize(500, 400)
    importF:SetPoint("CENTER")
    importF:SetFrameLevel(f:GetFrameLevel() + 10)
    importF:Hide()
    
    local importTitle = importF:CreateFontString(nil, "OVERLAY")
    importTitle:SetFontObject("GameFontHighlightLarge")
    importTitle:SetPoint("TOP", 0, -15)
    importTitle:SetText("Paste JSON String")
    
    local iScroll = CreateFrame("ScrollFrame", "TBCRaidCompImportScroll", importF, "UIPanelScrollFrameTemplate")
    iScroll:SetPoint("TOPLEFT", 20, -50)
    iScroll:SetSize(440, 280)
    
    local iBg = CreateSleekFrame(importF)
    iBg:SetPoint("TOPLEFT", iScroll, "TOPLEFT", -5, 5)
    iBg:SetPoint("BOTTOMRIGHT", iScroll, "BOTTOMRIGHT", 25, -5)
    iBg:SetBackdropColor(0.08, 0.08, 0.08, 1)
    iBg:SetFrameLevel(iScroll:GetFrameLevel() - 1)
    
    local editBox = CreateFrame("EditBox", "TBCRaidCompImportEditBox", iScroll)
    editBox:SetSize(440, 280)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetAutoFocus(true)
    editBox:SetMaxBytes(200000)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); importF:Hide() end)
    iScroll:SetScrollChild(editBox)
    
    local processBtn = CreateSleekButton(importF, "Process Composition", 200, 30)
    processBtn:SetPoint("BOTTOM", 0, 10)
    processBtn:SetScript("OnClick", function()
        importF:Hide()
        if Addon.Core and Addon.Core.OnGenerateClicked then
            Addon.Core:OnGenerateClicked(editBox:GetText())
            editBox:SetText("") -- Clear after process
        end
    end)
    
    local iCloseBtn = CreateFrame("Button", nil, importF, "UIPanelCloseButton")
    iCloseBtn:SetPoint("TOPRIGHT", 0, 0)
    
    Addon.UI.ImportFrame = importF
end

function Addon.UI:RenderGroups(groups, activeBuffsList)
    if not Addon.MainFrame then return end
    
    -- Render Groups
    for gIndex, group in ipairs(groups) do
        local gf = Addon.MainFrame.groupFrames[gIndex]
        gf.label:SetText("Group " .. gIndex .. " - " .. (group.label or "Mixed"))
        
        if group.buffs then
            local numIcons = math.min(#group.buffs, 24)
            local totalWidth = math.min(numIcons, 10) * 16
            gf.groupIconContainer:SetWidth(totalWidth)
            for i=1, 24 do
                local iconF = gf.groupIcons[i]
                if i <= numIcons then
                    local buffName = group.buffs[i]
                    if buffName == "Bloodlust" then
                        buffName = (Addon.Faction == "Alliance") and "Heroism" or "Bloodlust"
                    end
                    local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[buffName]) or buffName
                    local iconTexture = IconCache[query]
                    if not iconTexture then
                        local _, _, tex = GetSpellInfo(query)
                        iconTexture = tex or "Interface\\Icons\\INV_Misc_QuestionMark"
                        IconCache[query] = iconTexture
                    end
                    iconF.texture:SetTexture(iconTexture)
                    iconF.spellName = buffName
                    iconF:Show()
                else
                    iconF:Hide()
                end
            end
        else
            for i=1, 24 do gf.groupIcons[i]:Hide() end
        end
        for pIndex=1, 5 do
            local pf = gf.players[pIndex]
            local player = group[pIndex]
            if player then
                local colorCode = CLASS_COLORS[player.class] or "|cFFFFFFFF"
                local displaySpec = string.gsub(player.spec, "%d+$", "")
                pf.text:SetText(colorCode .. player.name .. "|r\n|cFF999999" .. displaySpec .. " " .. player.class .. "|r")
                pf:SetAlpha(1)
                
                -- Render Icons
                local specInfo = Addon.SPECS and Addon.SPECS[player.spec]
                if specInfo and specInfo.buffs then
                    for i, buffName in ipairs(specInfo.buffs) do
                        local iconFrame = gf.playerIcons[pIndex][i]
                        if iconFrame then
                            local resolvedBuffName = buffName
                            if resolvedBuffName == "Bloodlust" then
                                resolvedBuffName = (Addon.Faction == "Alliance") and "Heroism" or "Bloodlust"
                            end
                            local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[resolvedBuffName]) or resolvedBuffName
                            
                            local iconTexture = IconCache[query]
                            if not iconTexture then
                                local _, _, tex = GetSpellInfo(query)
                                iconTexture = tex or "Interface\\Icons\\INV_Misc_QuestionMark"
                                IconCache[query] = iconTexture
                            end
                            
                            iconFrame.texture:SetTexture(iconTexture)
                            iconFrame.spellName = resolvedBuffName
                            iconFrame:Show()
                        end
                    end
                    -- Hide unused
                    for i = #specInfo.buffs + 1, 8 do
                        if gf.playerIcons[pIndex][i] then gf.playerIcons[pIndex][i]:Hide() end
                    end
                else
                    for i=1, 8 do gf.playerIcons[pIndex][i]:Hide() end
                end
            else
                pf.text:SetText("")
                pf:SetAlpha(1)
                for i=1, 8 do gf.playerIcons[pIndex][i]:Hide() end
            end
        end
    end
    
    -- Render Categories
    local buffsContent = Addon.MainFrame.buffsContent
    if not Addon.MainFrame.categoryFrames then
        Addon.MainFrame.categoryFrames = {}
    end
    local catFrames = Addon.MainFrame.categoryFrames
    
    for i, cat in ipairs(activeBuffsList) do
        local cf = catFrames[i]
        if not cf then
            cf = CreateFrame("Frame", nil, buffsContent)
            cf:SetSize(180, 200) -- height dynamic
            cf.items = {}
            table_insert(catFrames, cf)
        end
        cf:Show()
        
        for _, item in ipairs(cf.items) do
            item.fs:Hide()
            if item.iconFrame then item.iconFrame:Hide() end
        end
        
        local yOffset = 0
        
        -- Header
        local header = cf.items[1]
        if not header then
            header = {}
            header.fs = cf:CreateFontString(nil, "OVERLAY")
            
            local iconF = CreateFrame("Frame", nil, cf)
            iconF:SetSize(14, 14)
            header.iconFrame = iconF
            header.tex = iconF:CreateTexture(nil, "ARTWORK")
            header.tex:SetAllPoints()
            
            table_insert(cf.items, header)
        end
        header.fs:SetFontObject("GameFontNormal")
        header.fs:SetText("|cFFFFFF00" .. cat.name .. "|r")
        header.fs:SetPoint("TOPLEFT", cf, "TOPLEFT", 0, yOffset)
        header.fs:Show()
        header.iconFrame:Hide()
        yOffset = yOffset - 22
        
        -- Items
        local itemIndex = 2
        for _, buff in ipairs(cat.items) do
            local item = cf.items[itemIndex]
            if not item then
                item = {}
                item.fs = cf:CreateFontString(nil, "OVERLAY")
                
                local iconF = CreateFrame("Frame", nil, cf)
                iconF:SetSize(14, 14)
                iconF:EnableMouse(true)
                item.iconFrame = iconF
                
                item.tex = iconF:CreateTexture(nil, "ARTWORK")
                item.tex:SetAllPoints()
                
                iconF:SetScript("OnEnter", function(self)
                    if self.spellName then
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        local resolvedName = self.spellName
                        if resolvedName == "Bloodlust" then
                            resolvedName = (Addon.Faction == "Alliance") and "Heroism" or "Bloodlust"
                        end
                        local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[resolvedName]) or resolvedName
                        if type(query) == "number" then
                            GameTooltip:SetSpellByID(query)
                        else
                            GameTooltip:SetText(resolvedName, 1, 1, 1)
                        end
                        GameTooltip:Show()
                    end
                end)
                iconF:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
                
                table_insert(cf.items, item)
            end
            
            item.fs:SetFontObject("GameFontHighlightSmall")
            local color = buff.active and "|cFF00FF00" or "|cFF888888"
            item.fs:SetText(color .. buff.text .. "|r")
            item.fs:SetPoint("TOPLEFT", cf, "TOPLEFT", 18, yOffset)
            
            item.iconFrame:SetPoint("RIGHT", item.fs, "LEFT", -4, 0)
            
            local resolvedSpellName = buff.spellName
            if resolvedSpellName == "Bloodlust" then
                resolvedSpellName = (Addon.Faction == "Alliance") and "Heroism" or "Bloodlust"
            end
            item.iconFrame.spellName = resolvedSpellName
            
            if resolvedSpellName then
                local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[resolvedSpellName]) or resolvedSpellName
                local iconTexture = IconCache[query]
                if not iconTexture then
                    local _, _, t = GetSpellInfo(query)
                    iconTexture = t or "Interface\\Icons\\INV_Misc_QuestionMark"
                    IconCache[query] = iconTexture
                end
                item.tex:SetTexture(iconTexture)
                if not buff.active then
                    item.tex:SetDesaturated(true)
                    item.tex:SetVertexColor(0.5, 0.5, 0.5)
                else
                    item.tex:SetDesaturated(false)
                    item.tex:SetVertexColor(1, 1, 1)
                end
            else
                item.tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                item.tex:SetDesaturated(false)
                item.tex:SetVertexColor(1, 1, 1)
            end
            item.fs:Show()
            item.iconFrame:Show()
            
            yOffset = yOffset - 16
            itemIndex = itemIndex + 1
        end
        
        cf:SetHeight(math_abs(yOffset))
    end
    
    for i = #activeBuffsList + 1, #catFrames do
        catFrames[i]:Hide()
    end
    
    self:Reflow()
end

function Addon.UI:Reflow()
    local f = Addon.MainFrame
    if not f then return end
    
    local width = f:GetWidth()
    local height = f:GetHeight()
    
    local gcWidth = width - 40
    f.groupsContainer:SetWidth(gcWidth)
    
    local groupWidth = 180
    local padding = 10
    
    local maxCols = math_floor((gcWidth + padding) / (groupWidth + padding))
    if maxCols < 1 then maxCols = 1 end
    if maxCols > 5 then maxCols = 5 end
    
    local function getItemsInRow(r)
        local itemsLeft = 5 - (r * maxCols)
        if itemsLeft > maxCols then return maxCols end
        if itemsLeft < 0 then return 0 end
        return itemsLeft
    end
    
    local row, col = 0, 0
    for i=1, 5 do
        local itemsInThisRow = getItemsInRow(row)
        local rowWidth = (itemsInThisRow * groupWidth) + ((itemsInThisRow - 1) * padding)
        local startX = (gcWidth - rowWidth) / 2
        
        local gf = f.groupFrames[i]
        gf:ClearAllPoints()
        gf:SetPoint("TOPLEFT", f.groupsContainer, "TOPLEFT", startX + col * (groupWidth + padding), -row * (330 + padding))
        
        col = col + 1
        if col >= maxCols then
            col = 0
            row = row + 1
        end
    end
    
    local rowsNeeded = row + (col > 0 and 1 or 0)
    local groupsHeight = rowsNeeded * (330 + padding)
    f.groupsContainer:SetHeight(groupsHeight)
    
    f.buffsBg:SetPoint("TOPLEFT", f.groupsContainer, "TOPLEFT", 0, -groupsHeight - 10)
    f.buffsBg:SetWidth(gcWidth)
    
    if f.categoryFrames then
        local catWidth = 150
        local maxCatCols = math_floor((gcWidth - 30 + padding) / (catWidth + 5))
        if maxCatCols < 1 then maxCatCols = 1 end
        
        local catRow, catCol = 0, 0
        local maxRowHeight = 0
        local currentY = -10
        
        for i, cf in ipairs(f.categoryFrames) do
            if cf:IsShown() then
                cf:ClearAllPoints()
                cf:SetPoint("TOPLEFT", f.buffsContent, "TOPLEFT", 10 + catCol * (catWidth + 5), currentY)
                
                local ch = cf:GetHeight()
                if ch > maxRowHeight then maxRowHeight = ch end
                
                catCol = catCol + 1
                if catCol >= maxCatCols then
                    catCol = 0
                    catRow = catRow + 1
                    currentY = currentY - maxRowHeight - 15
                    maxRowHeight = 0
                end
            end
        end
        
        local totalBuffsHeight = math_abs(currentY) + maxRowHeight + 20
        f.buffsContent:SetSize(gcWidth - 30, totalBuffsHeight)
        
        local buffsHeight = height - groupsHeight - 140
        if buffsHeight < 100 then buffsHeight = 100 end
        f.buffsBg:SetHeight(buffsHeight)
    end
end
