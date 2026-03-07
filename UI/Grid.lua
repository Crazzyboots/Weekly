local _, Weekly = ...

Weekly.Grid = {}
local G = Weekly.Grid
local C = Weekly.Constants
local DB = Weekly.Database
local U = Weekly.Utils
local CR = Weekly.CellRenderers
local RC = Weekly.RowCategory
local SC = Weekly.ScrollContainer

local gridState = {
    labelContainer = nil,
    scrollContainer = nil,
    initialized = false,
}

---------------------------------------------------------------------------
-- Initialize the grid within the main window
---------------------------------------------------------------------------
function G.Init(parent)
    local UI = C.UI
    local labelWidth = UI.LABEL_COLUMN_WIDTH
    local headerHeight = UI.HEADER_HEIGHT
    local titleHeight = UI.TITLE_HEIGHT

    local parentWidth = parent:GetWidth()
    local parentHeight = parent:GetHeight()
    local dataWidth = parentWidth - labelWidth
    local dataHeight = parentHeight - titleHeight - headerHeight

    -- Label column (fixed left side) — includes both header area and row area
    local labelFrame = CreateFrame("Frame", nil, parent)
    labelFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -titleHeight)
    labelFrame:SetSize(labelWidth, parentHeight - titleHeight)
    labelFrame:SetClipsChildren(true)

    -- Scroll container for character columns (header + data together)
    local scrollContainer = SC.Create(parent, labelWidth, titleHeight, dataWidth, parentHeight - titleHeight)

    gridState.labelContainer = labelFrame
    gridState.scrollContainer = scrollContainer
    gridState.parent = parent
    gridState.initialized = true
end

function G.Hide()
    if gridState.labelContainer then gridState.labelContainer:Hide() end
    if gridState.scrollContainer and gridState.scrollContainer.clipFrame then
        gridState.scrollContainer.clipFrame:Hide()
    end
end

function G.Show()
    if gridState.labelContainer then gridState.labelContainer:Show() end
    if gridState.scrollContainer and gridState.scrollContainer.clipFrame then
        gridState.scrollContainer.clipFrame:Show()
    end
end

---------------------------------------------------------------------------
-- Refresh the grid
---------------------------------------------------------------------------
function Weekly.RefreshGrid()
    if not gridState.initialized then return end

    local UI = C.UI
    local labelWidth = UI.LABEL_COLUMN_WIDTH
    local colWidth = DB.GetSettings().columnWidth or UI.CHAR_COLUMN_WIDTH
    local headerHeight = UI.HEADER_HEIGHT
    local rowHeight = UI.ROW_HEIGHT
    local sectionHeight = UI.SECTION_HEIGHT

    -- Release all existing cells
    CR.ReleaseAllCells()

    -- Get data
    local rows = Weekly.GetAllRows()
    local allKeys = DB.GetSortedCharacterKeys()
    local charKeys = {}
    for _, key in ipairs(allKeys) do
        if not DB.IsCharacterHidden(key) then
            charKeys[#charKeys + 1] = key
        end
    end
    local numChars = #charKeys

    if numChars == 0 then
        -- Show empty state
        local msg
        if #allKeys > 0 then
            msg = "|cff888888All characters are hidden.\nUnhide them in Settings.|r"
        else
            msg = "|cff888888No character data yet.\nLog in on your characters!|r"
        end
        CR.RenderTextCell(gridState.labelContainer, 20, headerHeight + 20, labelWidth - 40, 40, msg)
        return
    end

    -- Update scroll container content width
    local contentWidth = numChars * colWidth
    SC.SetContentWidth(gridState.scrollContainer, contentWidth)

    local content = gridState.scrollContainer.content
    local labelFrame = gridState.labelContainer

    -----------------------------------------------------------------
    -- Render character header row (in scroll area)
    -----------------------------------------------------------------
    for ci, charKey in ipairs(charKeys) do
        local charData = DB.GetCharacter(charKey)
        if charData then
            local x = (ci - 1) * colWidth
            CR.RenderCharacterHeader(content, x, 0, colWidth, headerHeight, charData)
        end
    end

    -----------------------------------------------------------------
    -- Render data rows
    -----------------------------------------------------------------
    local currentY = headerHeight
    local rowIndex = 0

    for _, row in ipairs(rows) do
        if row.isHeader then
            -- Section header — render across full width in label column
            local _, collapsed = RC.RenderHeader(
                labelFrame, 0, currentY, labelWidth, sectionHeight,
                row.section, row.label
            )

            -- Also render header background across data area
            local headerBg = CR.AcquireCell(content)
            headerBg:SetSize(math.max(contentWidth, 1), sectionHeight)
            headerBg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -currentY)
            headerBg.bg:SetColorTexture(
                C.Colors.HEADER_BG.r, C.Colors.HEADER_BG.g,
                C.Colors.HEADER_BG.b, C.Colors.HEADER_BG.a
            )
            headerBg.text:SetText("")

            currentY = currentY + sectionHeight

        elseif RC.IsRowVisible(row) then
            -- Row background stripe in label area
            CR.RenderRowBackground(labelFrame, 0, currentY, labelWidth, rowHeight, rowIndex)

            -- Row label
            CR.RenderLabelCell(labelFrame, 0, currentY, labelWidth, rowHeight, row.label, false)

            -- Data cells for each character
            for ci, charKey in ipairs(charKeys) do
                local charData = DB.GetCharacter(charKey)
                if charData and row.getValue then
                    local x = (ci - 1) * colWidth
                    local value = ""
                    local tooltipText = nil

                    local ok, result = pcall(row.getValue, charData)
                    if ok then value = result or "" end

                    if row.getTooltip then
                        local tok, tresult = pcall(row.getTooltip, charData)
                        if tok then tooltipText = tresult end
                    end

                    -- Row background stripe in data area
                    CR.RenderRowBackground(content, x, currentY, colWidth, rowHeight, rowIndex)

                    -- Data cell
                    CR.RenderTextCell(content, x, currentY, colWidth, rowHeight, value, tooltipText)
                end
            end

            currentY = currentY + rowHeight
            rowIndex = rowIndex + 1
        end
    end

    -- Update content height for proper scrolling
    local totalHeight = currentY
    gridState.scrollContainer.content:SetHeight(totalHeight)
    gridState.labelContainer:SetHeight(totalHeight)
end
