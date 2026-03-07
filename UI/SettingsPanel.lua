local _, Weekly = ...

Weekly.SettingsPanel = {}
local SP = Weekly.SettingsPanel
local C = Weekly.Constants
local DB = Weekly.Database
local U = Weekly.Utils
local G = Weekly.Grid

local panelState = {
    frame = nil,
    initialized = false,
    built = false,
    widgets = {},    -- holds references for in-place updates
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

---------------------------------------------------------------------------
-- Track all regions/children so we can hide them on rebuild
---------------------------------------------------------------------------
local managedRegions = {}  -- FontStrings and Textures we created

local function RecycleAll(content)
    -- Hide child frames
    local children = { content:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
        child:ClearAllPoints()
    end
    -- Hide FontStrings and Textures we created
    for _, region in ipairs(managedRegions) do
        region:Hide()
    end
    wipe(managedRegions)
end

---------------------------------------------------------------------------
-- Build the settings content
-- Called once on first show, then again only when character list changes
-- (delete). Checkbox state is wired to live callbacks, so no refresh needed
-- for toggle changes.
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
            local modKey = mod.key  -- capture for closure
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
            -- Class-colored name
            local classColor = C.ClassColors[charData.class] or C.Colors.WHITE
            local displayName = charData.name or "Unknown"
            if charData.realm and charData.realm ~= "" then
                displayName = displayName .. "-" .. charData.realm
            end

            -- Show/hide checkbox
            local visible = not DB.IsCharacterHidden(charKey)
            local capturedKey = charKey  -- capture for closure
            local cb = CreateCheckbox(content, 20, y, "", visible, function(checked)
                DB.SetCharacterHidden(capturedKey, not checked)
            end)

            -- Colored name label
            cb.label:SetText(U.ColorText(displayName, classColor))

            -- Delete button
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
    -- Section C — Display Options
    -------------------------------------------------------------------
    CreateSectionTitle(content, y, "Display")
    y = y + 28

    -- Minimap button toggle
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

    -- Show offline characters toggle
    CreateCheckbox(content, 20, y, "Show offline characters", settings.showOfflineCharacters, function(checked)
        settings.showOfflineCharacters = checked
    end)
    y = y + 36

    -- Column width slider
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

    local minLabel = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    minLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    minLabel:SetText("80")

    local maxLabel = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    maxLabel:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    maxLabel:SetText("200")

    -- Set OnValueChanged BEFORE SetValue so we don't fire with nil sliderLabel
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / 10 + 0.5) * 10
        settings.columnWidth = value
        sliderLabel:SetText("Column width: " .. value)
    end)

    slider:SetValue(settings.columnWidth or C.UI.CHAR_COLUMN_WIDTH)

    y = y + 40

    -- Set total content height
    content:SetHeight(y + 20)

    panelState.built = true
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------
function SP.Init(parent)
    if panelState.initialized then return end

    local titleHeight = C.UI.TITLE_HEIGHT

    -- Scroll frame for settings
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -(titleHeight + 6))
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -26, 4)

    local content = CreateFrame("Frame", nil, scrollFrame)
    -- Use a reasonable default width; OnSizeChanged will correct it once laid out
    content:SetSize(parent:GetWidth() - 30, 1)
    scrollFrame:SetScrollChild(content)

    -- Update content width when scroll frame gets laid out
    scrollFrame:SetScript("OnSizeChanged", function(self, w, h)
        content:SetWidth(w)
    end)

    panelState.frame = scrollFrame
    panelState.content = content
    panelState.parent = parent
    panelState.initialized = true

    scrollFrame:Hide()
end

---------------------------------------------------------------------------
-- Show / Hide / Toggle
---------------------------------------------------------------------------
function SP.Show()
    if not panelState.initialized then return end
    G.Hide()
    -- Build content on first show, or if flagged for rebuild
    if not panelState.built then
        BuildContent(panelState.content)
    end
    panelState.frame:Show()
end

function SP.Hide()
    if not panelState.initialized then return end
    if not panelState.frame:IsShown() then return end  -- guard against double-call
    panelState.frame:Hide()
    G.Show()
end

function SP.IsShown()
    return panelState.initialized and panelState.frame:IsShown()
end

-- Full rebuild (used after character delete)
function SP.Rebuild()
    panelState.built = false
    if SP.IsShown() then
        BuildContent(panelState.content)
    end
end

function SP.Toggle()
    if SP.IsShown() then
        SP.Hide()
    else
        SP.Show()
    end
end
