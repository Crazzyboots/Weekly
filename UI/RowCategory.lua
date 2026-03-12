local _, Weekly = ...

Weekly.RowCategory = {}
local RC = Weekly.RowCategory
local C = Weekly.Constants
local DB = Weekly.Database
local CR = Weekly.CellRenderers

---------------------------------------------------------------------------
-- Render a collapsible section header
---------------------------------------------------------------------------
function RC.RenderHeader(parent, x, y, width, height, sectionKey, label)
    local collapsed = DB.IsSectionCollapsed(sectionKey)
    local arrow = collapsed and "|cffaaaaaa\226\150\186|r " or "|cffaaaaaa\226\150\190|r "  -- ► / ▾

    local cell = CR.AcquireCell(parent)
    cell:SetSize(width, height)
    cell:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)

    cell.text:ClearAllPoints()
    cell.text:SetPoint("LEFT", cell, "LEFT", 6, 0)
    cell.text:SetJustifyH("LEFT")
    cell.text:SetWidth(width - 12)
    cell.text:SetFontObject(GameFontNormal)
    cell.text:SetText(arrow .. "|cffd94040" .. label .. "|r")

    cell.bg:SetColorTexture(
        C.Colors.HEADER_BG.r,
        C.Colors.HEADER_BG.g,
        C.Colors.HEADER_BG.b,
        C.Colors.HEADER_BG.a
    )

    -- Left accent bar
    if not cell.accent then
        cell.accent = cell:CreateTexture(nil, "ARTWORK")
    end
    cell.accent:ClearAllPoints()
    cell.accent:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
    cell.accent:SetSize(3, height)
    cell.accent:SetColorTexture(0.75, 0.15, 0.15, 1.0)
    cell.accent:Show()

    -- Click to toggle
    cell:SetScript("OnClick", function()
        DB.ToggleSection(sectionKey)
        Weekly.RefreshGrid()
    end)

    -- Highlight on hover
    cell:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.12, 0.07, 0.07, 1.0)
    end)
    cell:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(
            C.Colors.HEADER_BG.r,
            C.Colors.HEADER_BG.g,
            C.Colors.HEADER_BG.b,
            C.Colors.HEADER_BG.a
        )
    end)

    return cell, collapsed
end

---------------------------------------------------------------------------
-- Check if a row is visible (section not collapsed)
---------------------------------------------------------------------------
function RC.IsRowVisible(row)
    if row.isHeader then return true end
    return not DB.IsSectionCollapsed(row.section)
end
