local _, Weekly = ...

local C = Weekly.Constants
local DB = Weekly.Database
local U = Weekly.Utils

---------------------------------------------------------------------------
-- Minimap button (manual implementation, no LibDBIcon)
---------------------------------------------------------------------------
local BUTTON_SIZE = 32
local MINIMAP_RADIUS = 80

local function CreateMinimapButton()
    local settings = DB.GetSettings()

    local button = CreateFrame("Button", "WeeklyMinimapButton", Minimap)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetClampedToScreen(true)
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- Custom addon icon (already circular with its own border)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\AddOns\\Weekly\\icon")

    -- Highlight: simple brighten on hover (no weird zoom-button circle)
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    highlight:SetPoint("CENTER")
    highlight:SetColorTexture(1, 1, 1, 0.15)

    -----------------------------------------------------------------
    -- Position around minimap
    -----------------------------------------------------------------
    local function UpdatePosition()
        local angle = math.rad(settings.minimapButton.position or 220)
        local x = math.cos(angle) * MINIMAP_RADIUS
        local y = math.sin(angle) * MINIMAP_RADIUS
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    -----------------------------------------------------------------
    -- Dragging
    -----------------------------------------------------------------
    local isDragging = false

    button:SetScript("OnDragStart", function(self)
        isDragging = true
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            cx, cy = cx / scale, cy / scale

            local angle = math.atan2(cy - my, cx - mx)
            settings.minimapButton.position = math.deg(angle)
            UpdatePosition()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    -----------------------------------------------------------------
    -- Click handlers
    -----------------------------------------------------------------
    button:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            Weekly.ToggleWindow()
        end
    end)

    -----------------------------------------------------------------
    -- Tooltip
    -----------------------------------------------------------------
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Weekly", 1, 0.84, 0)
        GameTooltip:AddLine("Left-click to open dashboard", 1, 1, 1)
        GameTooltip:AddLine("/weekly for slash commands", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    UpdatePosition()

    -- Hide if setting is off (always create so settings can toggle it)
    if not settings.minimapButton.show then
        button:Hide()
    end

    return button
end

---------------------------------------------------------------------------
-- Deferred creation
---------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.2, function()
            Weekly.minimapButton = CreateMinimapButton()
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
