local _, Weekly = ...

Weekly.ScrollContainer = {}
local SC = Weekly.ScrollContainer
local C = Weekly.Constants

---------------------------------------------------------------------------
-- Create a horizontal scroll container
---------------------------------------------------------------------------
function SC.Create(parent, offsetX, offsetY, width, height)
    -- Clip frame (masks overflow)
    local clipFrame = CreateFrame("Frame", nil, parent)
    clipFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, -offsetY)
    clipFrame:SetSize(width, height)
    clipFrame:SetClipsChildren(true)

    -- Scrollable content frame (wider than clip frame)
    local content = CreateFrame("Frame", nil, clipFrame)
    content:SetPoint("TOPLEFT", clipFrame, "TOPLEFT", 0, 0)
    content:SetSize(width, height)  -- Will be resized based on content

    local container = {
        clipFrame = clipFrame,
        content = content,
        scrollOffset = 0,
        maxScroll = 0,
    }

    -- Mouse wheel scrolling
    clipFrame:EnableMouseWheel(true)
    clipFrame:SetScript("OnMouseWheel", function(self, delta)
        SC.Scroll(container, -delta * C.UI.SCROLL_STEP)
    end)

    return container
end

---------------------------------------------------------------------------
-- Update content width
---------------------------------------------------------------------------
function SC.SetContentWidth(container, contentWidth)
    container.content:SetWidth(contentWidth)
    local visibleWidth = container.clipFrame:GetWidth()
    container.maxScroll = math.max(0, contentWidth - visibleWidth)

    -- Clamp current offset
    if container.scrollOffset > container.maxScroll then
        container.scrollOffset = container.maxScroll
    end
    SC.ApplyScroll(container)
end

---------------------------------------------------------------------------
-- Scroll by delta
---------------------------------------------------------------------------
function SC.Scroll(container, delta)
    container.scrollOffset = container.scrollOffset + delta
    container.scrollOffset = math.max(0, math.min(container.scrollOffset, container.maxScroll))
    SC.ApplyScroll(container)
end

function SC.ApplyScroll(container)
    container.content:ClearAllPoints()
    container.content:SetPoint("TOPLEFT", container.clipFrame, "TOPLEFT", -container.scrollOffset, 0)
end

---------------------------------------------------------------------------
-- Resize
---------------------------------------------------------------------------
function SC.Resize(container, width, height)
    container.clipFrame:SetSize(width, height)
    -- Recalculate max scroll
    local contentWidth = container.content:GetWidth()
    container.maxScroll = math.max(0, contentWidth - width)
    if container.scrollOffset > container.maxScroll then
        container.scrollOffset = container.maxScroll
    end
    SC.ApplyScroll(container)
end
