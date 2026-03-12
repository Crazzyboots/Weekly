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
    local titleHeight = C.UI.TITLE_HEIGHT
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(titleHeight)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    titleBar:EnableMouse(true)
    titleBar:SetFrameLevel(frame:GetFrameLevel() + 2)

    -- Gradient header background (dark red at top → body dark at bottom)
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(1, 1, 1, 1)
    titleBg:SetGradient("VERTICAL",
        CreateColor(0.06, 0.04, 0.06, 1.0),   -- bottom: blends into body
        CreateColor(0.14, 0.05, 0.05, 1.0)     -- top: warm dark red
    )

    -- Top accent strip (bright red, 2px)
    local topAccent = titleBar:CreateTexture(nil, "ARTWORK")
    topAccent:SetHeight(2)
    topAccent:SetPoint("TOPLEFT", titleBar, "TOPLEFT", 0, 0)
    topAccent:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", 0, 0)
    topAccent:SetColorTexture(0.75, 0.15, 0.15, 1.0)

    -- Left decorative line (flanking the title)
    local leftLine = titleBar:CreateTexture(nil, "ARTWORK")
    leftLine:SetHeight(1)
    leftLine:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    leftLine:SetWidth(70)
    leftLine:SetColorTexture(1, 1, 1, 1)
    leftLine:SetGradient("HORIZONTAL",
        CreateColor(0.75, 0.15, 0.15, 0.0),    -- fade from transparent
        CreateColor(0.75, 0.15, 0.15, 0.6)      -- to red
    )

    -- Right decorative line (flanking the title)
    local rightLine = titleBar:CreateTexture(nil, "ARTWORK")
    rightLine:SetHeight(1)
    rightLine:SetPoint("RIGHT", titleBar, "RIGHT", -50, 0)
    rightLine:SetWidth(70)
    rightLine:SetColorTexture(1, 1, 1, 1)
    rightLine:SetGradient("HORIZONTAL",
        CreateColor(0.75, 0.15, 0.15, 0.6),     -- from red
        CreateColor(0.75, 0.15, 0.15, 0.0)       -- fade to transparent
    )

    -- Title shadow (offset behind the main text for depth)
    local titleShadow = titleBar:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    titleShadow:SetPoint("CENTER", titleBar, "CENTER", 1, -1)
    titleShadow:SetText("Weekly")
    titleShadow:SetTextColor(0.0, 0.0, 0.0, 0.6)

    -- Title text (centered, bright white)
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
    titleText:SetText("Weekly")
    titleText:SetTextColor(1.0, 0.95, 0.9, 1.0)

    -- Version badge (subtle, styled)
    local versionText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionText:SetPoint("LEFT", titleText, "RIGHT", 10, 0)
    versionText:SetText("|cff8b3030v" .. C.ADDON_VERSION .. "|r")

    -- Dragging via title bar
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint()
        local s = DB.GetSettings()
        s.windowPosition.point = point
        s.windowPosition.x = x
        s.windowPosition.y = y
    end)

    -----------------------------------------------------------------
    -- Close button (higher level to stay above header)
    -----------------------------------------------------------------
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetFrameLevel(titleBar:GetFrameLevel() + 5)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
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
    -- Separator below title: red line + soft glow beneath
    -----------------------------------------------------------------
    local sepY = -(titleHeight + 4)
    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(2)
    sep:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, sepY)
    sep:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, sepY)
    sep:SetColorTexture(0.70, 0.15, 0.15, 0.9)

    -- Soft glow beneath separator
    local sepGlow = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    sepGlow:SetHeight(8)
    sepGlow:SetPoint("TOPLEFT", sep, "BOTTOMLEFT", 0, 0)
    sepGlow:SetPoint("TOPRIGHT", sep, "BOTTOMRIGHT", 0, 0)
    sepGlow:SetColorTexture(1, 1, 1, 1)
    sepGlow:SetGradient("VERTICAL",
        CreateColor(0.55, 0.10, 0.10, 0.0),   -- bottom: transparent
        CreateColor(0.55, 0.10, 0.10, 0.25)    -- top: subtle red glow
    )

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
