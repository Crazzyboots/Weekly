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
    labelContent = nil,
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
    local sbSize = UI.SCROLLBAR_SIZE
    local contentHeight = parentHeight - titleHeight - sbSize  -- room for h-scrollbar
    local dataWidth = parentWidth - labelWidth - sbSize        -- room for v-scrollbar

    -- Label column (clip frame — masks overflow)
    local labelFrame = CreateFrame("Frame", nil, parent)
    labelFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -titleHeight)
    labelFrame:SetSize(labelWidth, contentHeight)
    labelFrame:SetClipsChildren(true)

    -- Inner scrollable content for labels
    local labelContent = CreateFrame("Frame", nil, labelFrame)
    labelContent:SetPoint("TOPLEFT", labelFrame, "TOPLEFT", 0, 0)
    labelContent:SetSize(labelWidth, contentHeight)

    -- Scroll container for character columns (header + data together)
    local scrollContainer = SC.Create(parent, labelWidth, titleHeight, dataWidth, contentHeight)

    -- Link label frame so vertical scroll stays in sync
    SC.LinkLabelFrame(scrollContainer, labelFrame, labelContent)

    -- Mouse wheel on labels → vertical scroll
    labelFrame:EnableMouseWheel(true)
    labelFrame:SetScript("OnMouseWheel", function(self, delta)
        SC.ScrollVertical(scrollContainer, -delta * C.UI.SCROLL_STEP)
    end)

    -- Vertical separator between label column and data area
    local labelSep = parent:CreateTexture(nil, "ARTWORK")
    labelSep:SetWidth(1)
    labelSep:SetPoint("TOPLEFT", parent, "TOPLEFT", labelWidth, -titleHeight)
    labelSep:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", labelWidth, 0)
    labelSep:SetColorTexture(C.Colors.SEPARATOR.r, C.Colors.SEPARATOR.g, C.Colors.SEPARATOR.b, C.Colors.SEPARATOR.a)

    gridState.labelSeparator = labelSep
    gridState.labelContainer = labelFrame
    gridState.labelContent = labelContent
    gridState.scrollContainer = scrollContainer
    gridState.parent = parent
    gridState.initialized = true
end

function G.Hide()
    if gridState.labelContainer then gridState.labelContainer:Hide() end
    if gridState.labelSeparator then gridState.labelSeparator:Hide() end
    if gridState.scrollContainer and gridState.scrollContainer.clipFrame then
        gridState.scrollContainer.clipFrame:Hide()
    end
end

function G.Show()
    if gridState.labelContainer then gridState.labelContainer:Show() end
    if gridState.labelSeparator then gridState.labelSeparator:Show() end
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
            local charData = DB.GetCharacter(key)
            if charData and (charData.level or 0) >= 90 then
                charKeys[#charKeys + 1] = key
            end
        end
    end

    -- Current character always goes first
    local currentKey = U.GetCharacterKey()
    if currentKey then
        for i, key in ipairs(charKeys) do
            if key == currentKey then
                table.remove(charKeys, i)
                table.insert(charKeys, 1, key)
                break
            end
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
        CR.RenderTextCell(gridState.labelContent, 20, headerHeight + 20, labelWidth - 40, 40, msg)
        return
    end

    -- Update scroll container content width
    local contentWidth = numChars * colWidth
    SC.SetContentWidth(gridState.scrollContainer, contentWidth)

    local content = gridState.scrollContainer.content
    local labelContent = gridState.labelContent

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
                labelContent, 0, currentY, labelWidth, sectionHeight,
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
            CR.RenderRowBackground(labelContent, 0, currentY, labelWidth, rowHeight, rowIndex)

            -- Row label
            CR.RenderLabelCell(labelContent, 0, currentY, labelWidth, rowHeight, row.label, false)

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

    -- Update content dimensions
    local totalHeight = currentY
    gridState.labelContent:SetHeight(totalHeight)
    gridState.labelContent:SetWidth(labelWidth)

    -- Auto-resize window to fit all content (no scrolling needed)
    local parent = gridState.parent
    local sbSize = UI.SCROLLBAR_SIZE
    local titleHeight = UI.TITLE_HEIGHT

    -- Width: label column + all character columns + vertical scrollbar + border insets
    local desiredWidth = labelWidth + contentWidth + sbSize + 8
    local maxWidth = (UIParent:GetWidth()) * 0.95
    local newWidth = math.max(UI.MIN_WINDOW_WIDTH, math.min(desiredWidth, maxWidth))

    -- Height: all rows + title + horizontal scrollbar + border insets
    local desiredHeight = totalHeight + titleHeight + sbSize + 8
    local maxHeight = (UIParent:GetHeight()) * 0.9
    local newHeight = math.max(UI.MIN_WINDOW_HEIGHT, math.min(desiredHeight, maxHeight))

    parent:SetSize(newWidth, newHeight)

    -- Resize internal containers to match new dimensions
    local newContentHeight = newHeight - titleHeight - sbSize
    local dataWidth = newWidth - labelWidth - sbSize
    gridState.labelContainer:SetHeight(newContentHeight)
    SC.Resize(gridState.scrollContainer, dataWidth, newContentHeight)

    SC.SetContentHeight(gridState.scrollContainer, totalHeight)

    -----------------------------------------------------------------
    -- Column separators (vertical lines between character columns)
    -----------------------------------------------------------------
    for ci = 2, numChars do
        local sepX = (ci - 1) * colWidth
        CR.RenderColumnSeparator(content, sepX, 0, totalHeight)
    end

    -----------------------------------------------------------------
    -- Header bottom border (horizontal line below character headers)
    -----------------------------------------------------------------
    CR.RenderHeaderBottomBorder(content, 0, headerHeight, math.max(contentWidth, 1))
    CR.RenderHeaderBottomBorder(labelContent, 0, headerHeight, labelWidth)
end
