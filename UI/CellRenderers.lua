local _, Weekly = ...

Weekly.CellRenderers = {}
local CR = Weekly.CellRenderers
local C = Weekly.Constants

---------------------------------------------------------------------------
-- Cell pool (reusable frames)
---------------------------------------------------------------------------
local cellPool = {}
local activeCells = {}

function CR.AcquireCell(parent)
    local cell = table.remove(cellPool)
    if not cell then
        cell = CreateFrame("Button", nil, parent)
        cell.text = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell.bg = cell:CreateTexture(nil, "BACKGROUND")
        cell.bg:SetAllPoints()
    else
        cell:SetParent(parent)
    end

    cell:ClearAllPoints()
    cell:SetFrameLevel(parent:GetFrameLevel() + 1)
    cell:Show()

    -- Reset text to a clean state every time (prevents bouncing between
    -- LEFT/CENTER when cells cycle between label and data roles)
    cell.text:ClearAllPoints()
    cell.text:SetPoint("CENTER")
    cell.text:SetJustifyH("CENTER")
    cell.text:SetFontObject(GameFontHighlightSmall)
    cell.text:SetText("")
    cell.text:SetWidth(0)
    cell.text:Show()

    cell.bg:SetColorTexture(0, 0, 0, 0)

    -- Hide accent bar if this cell was previously used as a section header
    if cell.accent then
        cell.accent:Hide()
    end

    -- Hide bottom border if this cell was previously used as a character header
    if cell.bottomBorder then
        cell.bottomBorder:Hide()
    end

    activeCells[#activeCells + 1] = cell
    return cell
end

function CR.ReleaseAllCells()
    for _, cell in ipairs(activeCells) do
        cell:Hide()
        cell:SetScript("OnEnter", nil)
        cell:SetScript("OnLeave", nil)
        cell:SetScript("OnClick", nil)
        cellPool[#cellPool + 1] = cell
    end
    wipe(activeCells)
end

---------------------------------------------------------------------------
-- Render a text cell
---------------------------------------------------------------------------
function CR.RenderTextCell(parent, x, y, width, height, text, tooltipText)
    local cell = CR.AcquireCell(parent)
    cell:SetSize(width, height)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)

    cell.text:SetText(text or "")
    cell.text:SetWidth(width - 4)

    if tooltipText then
        cell:SetScript("OnEnter", function(self)
            Weekly.ShowTooltip(self, tooltipText)
        end)
        cell:SetScript("OnLeave", function()
            Weekly.HideTooltip()
        end)
    end

    return cell
end

---------------------------------------------------------------------------
-- Render a label cell (left-aligned, for row labels)
---------------------------------------------------------------------------
function CR.RenderLabelCell(parent, x, y, width, height, text, isHeader)
    local cell = CR.AcquireCell(parent)
    cell:SetSize(width, height)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)

    cell.text:ClearAllPoints()
    cell.text:SetPoint("LEFT", cell, "LEFT", 8, 0)
    cell.text:SetJustifyH("LEFT")
    cell.text:SetWidth(width - 16)

    if isHeader then
        cell.text:SetFontObject(GameFontNormal)
        cell.text:SetText(text or "")
    else
        cell.text:SetFontObject(GameFontHighlightSmall)
        cell.text:SetText(text or "")
    end

    return cell
end

---------------------------------------------------------------------------
-- Render a header cell (character column header)
---------------------------------------------------------------------------
function CR.RenderCharacterHeader(parent, x, y, width, height, charData)
    local cell = CR.AcquireCell(parent)
    cell:SetSize(width, height)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)

    local name = charData.name or "Unknown"
    local classFile = charData.class or "WARRIOR"
    local ilvl = charData.avgItemLevelEquipped or 0

    local r, g, b = Weekly.Utils.GetClassColor(classFile)
    local coloredName = Weekly.Utils.ClassColoredText(Weekly.Utils.Abbreviate(name, 12), classFile)

    cell.text:ClearAllPoints()
    cell.text:SetPoint("CENTER")
    cell.text:SetJustifyH("CENTER")
    cell.text:SetFontObject(GameFontNormal)
    cell.text:SetWidth(width - 4)

    -- Only show ilvl if it's been scanned (non-zero)
    if ilvl > 0 then
        cell.text:SetText(coloredName .. "\n|cff888888" .. string.format("%.2f", ilvl) .. "|r")
    else
        cell.text:SetText(coloredName)
    end

    cell.bg:SetColorTexture(0.08, 0.08, 0.10, 1.0)

    -- Bottom border line for visual separation from data rows
    if not cell.bottomBorder then
        cell.bottomBorder = cell:CreateTexture(nil, "ARTWORK")
    end
    cell.bottomBorder:ClearAllPoints()
    cell.bottomBorder:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 0, 0)
    cell.bottomBorder:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)
    cell.bottomBorder:SetHeight(1)
    cell.bottomBorder:SetColorTexture(C.Colors.SEPARATOR.r, C.Colors.SEPARATOR.g, C.Colors.SEPARATOR.b, C.Colors.SEPARATOR.a)
    cell.bottomBorder:Show()

    -- Tooltip with full character info
    cell:SetScript("OnEnter", function(self)
        local lines = {
            Weekly.Utils.ClassColoredText(charData.name, classFile),
            charData.realm or "",
            "Level " .. (charData.level or 0),
            "Item Level: " .. string.format("%.2f", charData.avgItemLevel or 0) .. " (" .. string.format("%.2f", ilvl) .. " equipped)",
            "Last seen: " .. (charData.lastSeen and date("%Y-%m-%d %H:%M", charData.lastSeen) or "Unknown"),
        }
        Weekly.ShowTooltip(self, table.concat(lines, "\n"))
    end)
    cell:SetScript("OnLeave", function()
        Weekly.HideTooltip()
    end)

    return cell
end

---------------------------------------------------------------------------
-- Row background stripe
---------------------------------------------------------------------------
function CR.RenderRowBackground(parent, x, y, width, height, rowIndex)
    local cell = CR.AcquireCell(parent)
    cell:SetSize(width, height)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    cell:SetFrameLevel(parent:GetFrameLevel())  -- behind data cells

    local color = (rowIndex % 2 == 0) and C.Colors.ROW_BG_1 or C.Colors.ROW_BG_2
    cell.bg:SetColorTexture(color.r, color.g, color.b, color.a)

    return cell
end

---------------------------------------------------------------------------
-- Render a vertical column separator (1px line)
---------------------------------------------------------------------------
function CR.RenderColumnSeparator(parent, x, y, height)
    local cell = CR.AcquireCell(parent)
    cell:SetSize(1, height)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    cell:SetFrameLevel(parent:GetFrameLevel() + 2)

    cell.bg:SetColorTexture(C.Colors.SEPARATOR.r, C.Colors.SEPARATOR.g, C.Colors.SEPARATOR.b, C.Colors.SEPARATOR.a)
    cell.text:Hide()

    return cell
end

---------------------------------------------------------------------------
-- Render a horizontal header bottom border (1px line)
---------------------------------------------------------------------------
function CR.RenderHeaderBottomBorder(parent, x, y, width)
    local cell = CR.AcquireCell(parent)
    cell:SetSize(width, 1)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    cell:SetFrameLevel(parent:GetFrameLevel() + 2)

    cell.bg:SetColorTexture(C.Colors.SEPARATOR.r, C.Colors.SEPARATOR.g, C.Colors.SEPARATOR.b, C.Colors.SEPARATOR.a)
    cell.text:Hide()

    return cell
end
