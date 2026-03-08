local _, Weekly = ...

local C = Weekly.Constants
local DB = Weekly.Database
local U = Weekly.Utils
local G = Weekly.Grid
local SP = Weekly.SettingsPanel

---------------------------------------------------------------------------
-- Create the main window
---------------------------------------------------------------------------
local function CreateMainWindow()
    local settings = DB.GetSettings()
    local width = settings.windowSize.width
    local height = settings.windowSize.height

    -- Main frame
    local frame = CreateFrame("Frame", "WeeklyMainWindow", UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint(
        settings.windowPosition.point,
        UIParent,
        settings.windowPosition.point,
        settings.windowPosition.x,
        settings.windowPosition.y
    )
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClipsChildren(true)

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0.05, 0.05, 0.07, 1.0)
    frame:SetBackdropBorderColor(0.55, 0.12, 0.12, 0.9)

    -----------------------------------------------------------------
    -- Title bar
    -----------------------------------------------------------------
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(C.UI.TITLE_HEIGHT)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    titleBar:EnableMouse(true)

    -- Dragging via title bar
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        -- Save position
        local point, _, _, x, y = frame:GetPoint()
        local s = DB.GetSettings()
        s.windowPosition.point = point
        s.windowPosition.x = x
        s.windowPosition.y = y
    end)

    -- Title text (centered)
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetText(U.ColorText("Weekly", C.Colors.TITLE))

    -- Version text
    local versionText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 8, 0)
    versionText:SetText("|cff666666v" .. C.ADDON_VERSION .. "|r")

    -----------------------------------------------------------------
    -- Close button
    -----------------------------------------------------------------
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()  -- OnHide handler takes care of settings panel
    end)

    -----------------------------------------------------------------
    -- Gear (settings) button — left of close button
    -----------------------------------------------------------------
    local gearBtn = CreateFrame("Button", nil, frame)
    gearBtn:SetSize(22, 22)
    gearBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
    gearBtn:SetFrameLevel(titleBar:GetFrameLevel() + 5)
    gearBtn:RegisterForClicks("LeftButtonUp")

    local gearIcon = gearBtn:CreateTexture(nil, "ARTWORK")
    gearIcon:SetAllPoints()
    gearIcon:SetTexture("Interface\\Scenarios\\ScenarioIcon-Interact")
    gearIcon:SetVertexColor(0.8, 0.8, 0.8)

    local gearHighlight = gearBtn:CreateTexture(nil, "HIGHLIGHT")
    gearHighlight:SetAllPoints()
    gearHighlight:SetTexture("Interface\\Scenarios\\ScenarioIcon-Interact")
    gearHighlight:SetVertexColor(1, 1, 1)
    gearHighlight:SetAlpha(0.3)

    gearBtn:SetScript("OnClick", function()
        SP.Toggle()
    end)

    gearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Settings", 1, 1, 1)
        GameTooltip:Show()
    end)
    gearBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -----------------------------------------------------------------
    -- Separator line below title
    -----------------------------------------------------------------
    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -(C.UI.TITLE_HEIGHT + 4))
    sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -(C.UI.TITLE_HEIGHT + 4))
    sep:SetColorTexture(0.7, 0.15, 0.15, 0.8)

    -----------------------------------------------------------------
    -- Initialize grid inside the frame
    -----------------------------------------------------------------
    G.Init(frame)

    -----------------------------------------------------------------
    -- Initialize settings panel inside the frame
    -----------------------------------------------------------------
    SP.Init(frame)

    -----------------------------------------------------------------
    -- ESC to close
    -----------------------------------------------------------------
    table.insert(UISpecialFrames, "WeeklyMainWindow")

    -- When main window hides, dismiss the settings panel.
    -- SP.Hide() is guarded against double-calls and will restore the grid
    -- (harmless since the parent is hiding anyway).
    frame:SetScript("OnHide", function()
        if SP.IsShown() then
            SP.Hide()
        end
    end)

    frame:Hide()
    return frame
end

---------------------------------------------------------------------------
-- Deferred creation (after PLAYER_LOGIN + DB init)
---------------------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.1, function()
            Weekly.mainWindow = CreateMainWindow()
        end)
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
