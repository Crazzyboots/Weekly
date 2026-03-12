local _, Weekly = ...

---------------------------------------------------------------------------
-- Custom tooltip frame (avoids conflicts with GameTooltip)
---------------------------------------------------------------------------
local tooltip = CreateFrame("Frame", "WeeklyTooltipFrame", UIParent, "BackdropTemplate")
tooltip:SetFrameStrata("TOOLTIP")
tooltip:SetClampedToScreen(true)
tooltip:Hide()

tooltip:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
tooltip:SetBackdropColor(0, 0, 0, 0.9)
tooltip:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

local tooltipText = tooltip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tooltipText:SetPoint("TOPLEFT", tooltip, "TOPLEFT", 10, -10)
tooltipText:SetJustifyH("LEFT")
tooltipText:SetWordWrap(true)

---------------------------------------------------------------------------
-- Show / Hide
---------------------------------------------------------------------------
function Weekly.ShowTooltip(anchor, text)
    if not text or text == "" then return end

    tooltipText:SetText(text)

    local textWidth = tooltipText:GetStringWidth()
    local textHeight = tooltipText:GetStringHeight()

    local maxWidth = 300
    if textWidth > maxWidth then
        tooltipText:SetWidth(maxWidth)
        textWidth = maxWidth
        textHeight = tooltipText:GetStringHeight()
    else
        tooltipText:SetWidth(textWidth)
    end

    local minWidth = 160
    tooltip:SetSize(math.max(textWidth + 20, minWidth), textHeight + 20)

    tooltip:ClearAllPoints()
    tooltip:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    tooltip:Show()
end

function Weekly.HideTooltip()
    tooltip:Hide()
end
