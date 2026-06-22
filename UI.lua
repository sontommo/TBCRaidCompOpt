local AddonName, Addon = ...
Addon.UI = {}

-- Localize globals for performance optimization
local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local table_insert = table.insert
local ipairs = ipairs
local math_floor = math.floor
local math_abs = math.abs

-- Cache for spell icons to avoid redundant C-API lookups
local IconCache = {}

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
    
    -- Groups Grid Container
    local groupsContainer = CreateFrame("Frame", nil, f)
    groupsContainer:SetPoint("TOPLEFT", 20, -90)
    f.groupsContainer = groupsContainer
    
    f.groupFrames = {}
    for i=1, 5 do
        local gf = CreateSleekFrame(groupsContainer)
        gf:SetSize(180, 290)
        gf:SetBackdropColor(0.15, 0.15, 0.15, 1)
        
        local labelBg = CreateFrame("Frame", nil, gf, "BackdropTemplate")
        labelBg:SetPoint("TOPLEFT", 1, -1)
        labelBg:SetPoint("TOPRIGHT", -1, -1)
        labelBg:SetHeight(45)
        labelBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        labelBg:SetBackdropColor(0.1, 0.1, 0.1, 1)
        
        local label = labelBg:CreateFontString(nil, "OVERLAY")
        label:SetFontObject("GameFontNormal")
        label:SetPoint("TOP", 0, -6)
        label:SetText("Group " .. i)
        gf.label = label
        
        local groupIconContainer = CreateFrame("Frame", nil, labelBg)
        groupIconContainer:SetSize(160, 16)
        groupIconContainer:SetPoint("BOTTOM", 0, 4)
        gf.groupIconContainer = groupIconContainer
        gf.groupIcons = {}
        for k=1, 8 do
            local iconF = CreateFrame("Frame", nil, groupIconContainer)
            iconF:SetSize(14, 14)
            iconF:SetPoint("LEFT", (k-1)*16, 0)
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
            local pf = gf:CreateFontString(nil, "OVERLAY")
            pf:SetFontObject("GameFontHighlightSmall")
            pf:SetPoint("TOPLEFT", 8, -10 - (p-1)*48 - 45)
            pf:SetWidth(164)
            pf:SetJustifyH("LEFT")
            pf:SetText("")
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
            local numIcons = math.min(#group.buffs, 8)
            local totalWidth = numIcons * 16
            gf.groupIconContainer:SetWidth(totalWidth)
            for i=1, 8 do
                local iconF = gf.groupIcons[i]
                if i <= numIcons then
                    local buffName = group.buffs[i]
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
            for i=1, 8 do gf.groupIcons[i]:Hide() end
        end
        for pIndex=1, 5 do
            local pf = gf.players[pIndex]
            local player = group[pIndex]
            if player then
                local colorCode = CLASS_COLORS[player.class] or "|cFFFFFFFF"
                local displaySpec = string.gsub(player.spec, "%d+$", "")
                pf:SetText(colorCode .. player.name .. "|r\n|cFF999999" .. displaySpec .. " " .. player.class .. "|r")
                
                -- Render Icons
                local specInfo = Addon.SPECS and Addon.SPECS[player.spec]
                if specInfo and specInfo.buffs then
                    for i, buffName in ipairs(specInfo.buffs) do
                        local iconFrame = gf.playerIcons[pIndex][i]
                        if iconFrame then
                            local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[buffName]) or buffName
                            
                            local iconTexture = IconCache[query]
                            if not iconTexture then
                                local _, _, tex = GetSpellInfo(query)
                                iconTexture = tex or "Interface\\Icons\\INV_Misc_QuestionMark"
                                IconCache[query] = iconTexture
                            end
                            
                            iconFrame.texture:SetTexture(iconTexture)
                            iconFrame.spellName = buffName
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
                pf:SetText("")
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
                        local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[self.spellName]) or self.spellName
                        if type(query) == "number" then
                            GameTooltip:SetSpellByID(query)
                        else
                            GameTooltip:SetText(self.spellName, 1, 1, 1)
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
            item.iconFrame.spellName = buff.spellName
            
            if buff.spellName then
                local query = (Addon.BUFF_SPELL_IDS and Addon.BUFF_SPELL_IDS[buff.spellName]) or buff.spellName
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
        gf:SetPoint("TOPLEFT", f.groupsContainer, "TOPLEFT", startX + col * (groupWidth + padding), -row * (275 + padding))
        
        col = col + 1
        if col >= maxCols then
            col = 0
            row = row + 1
        end
    end
    
    local rowsNeeded = row + (col > 0 and 1 or 0)
    local groupsHeight = rowsNeeded * (275 + padding)
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
