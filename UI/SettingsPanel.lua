local _, Weekly = ...

Weekly.SettingsPanel = {}
local SP = Weekly.SettingsPanel
local C = Weekly.Constants
local DB = Weekly.Database
local U = Weekly.Utils
local G = Weekly.Grid

local panelState = {
    frame = nil,
    content = nil,
    initialized = false,
    built = false,
    scrollOffset = 0,
}

---------------------------------------------------------------------------
-- Delete character confirmation dialog
---------------------------------------------------------------------------
StaticPopupDialogs["WEEKLY_DELETE_CHARACTER"] = {
    text = "Delete all data for %s? This cannot be undone.",
    button1 = "Delete",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if not data then return end
        DB.PurgeCharacter(data)
        DB.SetCharacterHidden(data, false)
        SP.Rebuild()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

---------------------------------------------------------------------------
-- Track all regions/children so we can hide them on rebuild
---------------------------------------------------------------------------
local managedRegions = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local function CreateCheckbox(parent, x, y, label, checked, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    cb:SetSize(26, 26)
    cb:SetChecked(checked)
    cb:SetScript("OnClick", function(self)
        onChange(self:GetChecked())
    end)

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label)
    cb.label = text

    return cb
end

local function CreateSectionTitle(parent, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -y)
    fs:SetText(text)
    fs:SetTextColor(1, 0.84, 0)
    managedRegions[#managedRegions + 1] = fs
    return fs
end

local function CreateSeparator(parent, y)
    local sep = parent:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -y)
    sep:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, -y)
    sep:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    managedRegions[#managedRegions + 1] = sep
    return sep
end

local function CreateRadioButton(parent, x, y, label, selected, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(200, 20)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)

    local indicator = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    indicator:SetPoint("LEFT", btn, "LEFT", 0, 0)
    if selected then
        indicator:SetText("|cffcc3333(x)|r")
    else
        indicator:SetText("( )")
    end
    btn.indicator = indicator

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", indicator, "RIGHT", 6, 0)
    text:SetText(label)
    btn.label = text

    btn:SetScript("OnClick", function()
        onClick()
    end)

    return btn
end

local function CreateArrowButton(parent, x, y, direction, onClick)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(22, 18)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    btn:SetText(direction == "up" and "^" or "v")

    btn:SetScript("OnClick", function()
        onClick()
    end)

    return btn
end

local function RecycleAll(content)
    local children = { content:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:ClearAllPoints()
    end
    for _, region in ipairs(managedRegions) do
        region:Hide()
    end
    wipe(managedRegions)
end

---------------------------------------------------------------------------
-- Build the settings content
---------------------------------------------------------------------------
local function BuildContent(content)
    RecycleAll(content)

    local y = 12
    local settings = DB.GetSettings()

    -------------------------------------------------------------------
    -- Section A — Module Toggles
    -------------------------------------------------------------------
    CreateSectionTitle(content, y, "Module Toggles")
    y = y + 28

    for _, mod in ipairs(Weekly.modules) do
        if mod.key ~= "characterInfo" then
            local enabled = not DB.IsModuleDisabled(mod.key)
            local modKey = mod.key
            CreateCheckbox(content, 20, y, mod.label or mod.key, enabled, function(checked)
                DB.SetModuleDisabled(modKey, not checked)
            end)
            y = y + 28
        end
    end

    y = y + 8
    CreateSeparator(content, y)
    y = y + 16

    -------------------------------------------------------------------
    -- Section B — Characters
    -------------------------------------------------------------------
    CreateSectionTitle(content, y, "Characters")
    y = y + 28

    local charKeys = DB.GetSortedCharacterKeys()
    for _, charKey in ipairs(charKeys) do
        local charData = DB.GetCharacter(charKey)
        if charData then
            local classColor = C.ClassColors[charData.class] or C.Colors.WHITE
            local displayName = charData.name or "Unknown"
            if charData.realm and charData.realm ~= "" then
                displayName = displayName .. "-" .. charData.realm
            end

            local visible = not DB.IsCharacterHidden(charKey)
            local capturedKey = charKey
            local cb = CreateCheckbox(content, 20, y, "", visible, function(checked)
                DB.SetCharacterHidden(capturedKey, not checked)
            end)

            cb.label:SetText(U.ColorText(displayName, classColor))

            local delBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            delBtn:SetSize(60, 22)
            delBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 280, -y - 2)
            delBtn:SetText("Delete")
            local capturedName = displayName
            delBtn:SetScript("OnClick", function()
                local popup = StaticPopup_Show("WEEKLY_DELETE_CHARACTER", capturedName)
                if popup then
                    popup.data = capturedKey
                end
            end)

            y = y + 30
        end
    end

    if #charKeys == 0 then
        local noChars = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        noChars:SetPoint("TOPLEFT", content, "TOPLEFT", 24, -y)
        noChars:SetText("No characters yet. Log in on your characters!")
        managedRegions[#managedRegions + 1] = noChars
        y = y + 24
    end

    y = y + 8
    CreateSeparator(content, y)
    y = y + 16

    -------------------------------------------------------------------
    -- Section C — Sort Characters By
    -------------------------------------------------------------------
    CreateSectionTitle(content, y, "Sort Characters By")
    y = y + 28

    local sortOptions = {
        { key = "lastSeen", label = "Last Seen" },
        { key = "ilvl",     label = "Item Level" },
        { key = "name",     label = "Name (A-Z)" },
        { key = "custom",   label = "Custom Order" },
    }

    local currentSort = settings.sortBy or "lastSeen"

    for _, opt in ipairs(sortOptions) do
        local optKey = opt.key
        CreateRadioButton(content, 20, y, opt.label, currentSort == optKey, function()
            settings.sortBy = optKey
            SP.Rebuild()
            if Weekly.RefreshGrid then
                Weekly.RefreshGrid()
            end
        end)
        y = y + 24
    end

    -- If custom sort is active, show Up/Down arrows next to character names
    if currentSort == "custom" then
        y = y + 4
        if not settings.customCharOrder or #settings.customCharOrder == 0 then
            settings.sortBy = "lastSeen"
            settings.customCharOrder = DB.GetSortedCharacterKeys()
            settings.sortBy = "custom"
        end

        local order = settings.customCharOrder
        for i, charKey in ipairs(order) do
            local charData = DB.GetCharacter(charKey)
            if charData then
                local classColor = C.ClassColors[charData.class] or C.Colors.WHITE
                local displayName = charData.name or "Unknown"
                if charData.realm and charData.realm ~= "" then
                    displayName = displayName .. "-" .. charData.realm
                end

                local nameFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                nameFs:SetPoint("TOPLEFT", content, "TOPLEFT", 70, -y)
                nameFs:SetText(U.ColorText(displayName, classColor))
                managedRegions[#managedRegions + 1] = nameFs

                if i > 1 then
                    local idx = i
                    CreateArrowButton(content, 24, y, "up", function()
                        order[idx], order[idx - 1] = order[idx - 1], order[idx]
                        SP.Rebuild()
                        if Weekly.RefreshGrid then Weekly.RefreshGrid() end
                    end)
                end

                if i < #order then
                    local idx = i
                    CreateArrowButton(content, 46, y, "down", function()
                        order[idx], order[idx + 1] = order[idx + 1], order[idx]
                        SP.Rebuild()
                        if Weekly.RefreshGrid then Weekly.RefreshGrid() end
                    end)
                end

                y = y + 24
            end
        end
    end

    y = y + 8
    CreateSeparator(content, y)
    y = y + 16

    -------------------------------------------------------------------
    -- Section D — Display Options
    -------------------------------------------------------------------
    CreateSectionTitle(content, y, "Display")
    y = y + 28

    local mmShow = settings.minimapButton.show
    CreateCheckbox(content, 20, y, "Show minimap button", mmShow, function(checked)
        settings.minimapButton.show = checked
        if Weekly.minimapButton then
            if checked then
                Weekly.minimapButton:Show()
            else
                Weekly.minimapButton:Hide()
            end
        end
    end)
    y = y + 28

    CreateCheckbox(content, 20, y, "Show offline characters", settings.showOfflineCharacters, function(checked)
        settings.showOfflineCharacters = checked
    end)
    y = y + 36

    local sliderLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sliderLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 24, -y)
    sliderLabel:SetText("Column width: " .. (settings.columnWidth or C.UI.CHAR_COLUMN_WIDTH))
    managedRegions[#managedRegions + 1] = sliderLabel

    y = y + 18

    local slider = CreateFrame("Slider", nil, content, "BackdropTemplate")
    slider:SetPoint("TOPLEFT", content, "TOPLEFT", 24, -y)
    slider:SetSize(200, 16)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(80, 200)
    slider:SetValueStep(10)
    slider:SetObeyStepOnDrag(true)
    slider:EnableMouse(true)

    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })

    local thumb = slider:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(16, 24)
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    slider:SetThumbTexture(thumb)

    local minText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    minText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    minText:SetText("80")

    local maxText = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    maxText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    maxText:SetText("200")

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / 10 + 0.5) * 10
        settings.columnWidth = value
        sliderLabel:SetText("Column width: " .. value)
    end)

    slider:SetValue(settings.columnWidth or C.UI.CHAR_COLUMN_WIDTH)

    y = y + 40

    -- Set total content height for scrolling
    content:SetHeight(y + 20)

    panelState.built = true
end

---------------------------------------------------------------------------
-- Init — simple clip frame with manual mouse wheel scroll (NO scroll
-- frame template, which is broken in WoW 11.x)
---------------------------------------------------------------------------
function SP.Init(parent)
    if panelState.initialized then return end

    local titleHeight = C.UI.TITLE_HEIGHT

    -- Outer clip frame (masks overflow)
    local clipFrame = CreateFrame("Frame", nil, parent)
    clipFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -(titleHeight + 6))
    clipFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -4, 4)
    clipFrame:SetClipsChildren(true)

    -- Inner content frame (taller than clip, scrolled by mouse wheel)
    local content = CreateFrame("Frame", nil, clipFrame)
    content:SetPoint("TOPLEFT", clipFrame, "TOPLEFT", 0, 0)
    content:SetWidth(parent:GetWidth() - 8)
    content:SetHeight(1)

    -- Mouse wheel scrolling
    panelState.scrollOffset = 0
    clipFrame:EnableMouseWheel(true)
    clipFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, content:GetHeight() - clipFrame:GetHeight())
        panelState.scrollOffset = panelState.scrollOffset - (delta * 30)
        panelState.scrollOffset = math.max(0, math.min(panelState.scrollOffset, maxScroll))
        content:SetPoint("TOPLEFT", clipFrame, "TOPLEFT", 0, panelState.scrollOffset)
    end)

    panelState.frame = clipFrame
    panelState.content = content
    panelState.parent = parent
    panelState.initialized = true

    clipFrame:Hide()
end

---------------------------------------------------------------------------
-- Show / Hide / Toggle
---------------------------------------------------------------------------
function SP.Show()
    if not panelState.initialized then return end
    -- Build content BEFORE hiding grid (so if build fails, grid stays)
    if not panelState.built then
        local ok, err = pcall(BuildContent, panelState.content)
        if not ok then
            U.Print("|cffff0000Settings error:|r " .. tostring(err))
            return
        end
    end
    G.Hide()
    panelState.frame:Show()
end

function SP.Hide()
    if not panelState.initialized then return end
    if not panelState.frame:IsShown() then return end
    panelState.frame:Hide()
    G.Show()
end

function SP.IsShown()
    return panelState.initialized and panelState.frame:IsShown()
end

function SP.Rebuild()
    panelState.built = false
    panelState.scrollOffset = 0
    if SP.IsShown() then
        local ok, err = pcall(BuildContent, panelState.content)
        if not ok then
            U.Print("|cffff0000Settings rebuild error:|r " .. tostring(err))
        else
            panelState.content:SetPoint("TOPLEFT", panelState.frame, "TOPLEFT", 0, 0)
        end
    end
end

function SP.Toggle()
    if SP.IsShown() then
        SP.Hide()
    else
        SP.Show()
    end
end
