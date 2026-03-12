local _, Weekly = ...

Weekly.ScrollContainer = {}
local SC = Weekly.ScrollContainer
local C = Weekly.Constants

---------------------------------------------------------------------------
-- Helper: create a scrollbar (track + thumb)
---------------------------------------------------------------------------
local function CreateScrollbar(parent, isVertical, length)
    local sbSize = C.UI.SCROLLBAR_SIZE
    local minThumb = C.UI.SCROLLBAR_MIN_THUMB

    -- Track
    local track = CreateFrame("Frame", nil, parent)
    if isVertical then
        track:SetSize(sbSize, length)
    else
        track:SetSize(length, sbSize)
    end

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0.10, 0.04, 0.04, 0.8)

    -- Thumb
    local thumb = CreateFrame("Frame", nil, track)
    if isVertical then
        thumb:SetSize(sbSize, minThumb)
    else
        thumb:SetSize(minThumb, sbSize)
    end
    thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)

    local thumbBg = thumb:CreateTexture(nil, "ARTWORK")
    thumbBg:SetAllPoints()
    thumbBg:SetColorTexture(0.65, 0.12, 0.12, 1.0)

    -- Hover effects
    thumb:EnableMouse(true)
    thumb:SetScript("OnEnter", function()
        thumbBg:SetColorTexture(0.85, 0.20, 0.20, 1.0)
    end)
    thumb:SetScript("OnLeave", function()
        thumbBg:SetColorTexture(0.65, 0.12, 0.12, 1.0)
    end)

    return track, thumb
end

---------------------------------------------------------------------------
-- Drag support for a thumb
---------------------------------------------------------------------------
local function SetupDrag(container, thumb, isVertical)
    local dragging = false
    local dragStart = 0
    local scrollStart = 0

    thumb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            dragging = true
            local scale = UIParent:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            dragStart = isVertical and cy or cx
            scrollStart = isVertical and container.vScrollOffset or container.hScrollOffset
        end
    end)

    thumb:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            dragging = false
        end
    end)

    thumb:SetScript("OnUpdate", function(self)
        if not dragging then return end
        local scale = UIParent:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        cx, cy = cx / scale, cy / scale

        if isVertical then
            local cursorDelta = dragStart - cy  -- cursor down = positive scroll
            local trackH = container.vTrack:GetHeight()
            local thumbH = container.vThumb:GetHeight()
            local scrollRange = trackH - thumbH
            if scrollRange > 0 then
                local scrollDelta = (cursorDelta / scrollRange) * container.vMaxScroll
                container.vScrollOffset = math.max(0, math.min(scrollStart + scrollDelta, container.vMaxScroll))
                SC.ApplyScroll(container)
            end
        else
            local cursorDelta = cx - dragStart  -- cursor right = positive scroll
            local trackW = container.hTrack:GetWidth()
            local thumbW = container.hThumb:GetWidth()
            local scrollRange = trackW - thumbW
            if scrollRange > 0 then
                local scrollDelta = (cursorDelta / scrollRange) * container.hMaxScroll
                container.hScrollOffset = math.max(0, math.min(scrollStart + scrollDelta, container.hMaxScroll))
                SC.ApplyScroll(container)
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Create scroll container with both scrollbars
---------------------------------------------------------------------------
function SC.Create(parent, offsetX, offsetY, width, height)
    -- Clip frame (masks overflow) — size unchanged
    local clipFrame = CreateFrame("Frame", nil, parent)
    clipFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX, -offsetY)
    clipFrame:SetSize(width, height)
    clipFrame:SetClipsChildren(true)

    -- Scrollable content frame
    local content = CreateFrame("Frame", nil, clipFrame)
    content:SetPoint("TOPLEFT", clipFrame, "TOPLEFT", 0, 0)
    content:SetSize(width, height)

    -- Vertical scrollbar — RIGHT of clipFrame, parented to main window
    local vTrack, vThumb = CreateScrollbar(parent, true, height)
    vTrack:SetPoint("TOPLEFT", clipFrame, "TOPRIGHT", 0, 0)
    vTrack:SetFrameLevel(parent:GetFrameLevel() + 10)

    -- Horizontal scrollbar — BELOW clipFrame, parented to main window
    local hTrack, hThumb = CreateScrollbar(parent, false, width)
    hTrack:SetPoint("TOPLEFT", clipFrame, "BOTTOMLEFT", 0, 0)
    hTrack:SetFrameLevel(parent:GetFrameLevel() + 10)

    local container = {
        clipFrame = clipFrame,
        content = content,
        hScrollOffset = 0,
        hMaxScroll = 0,
        vScrollOffset = 0,
        vMaxScroll = 0,
        vTrack = vTrack,
        vThumb = vThumb,
        hTrack = hTrack,
        hThumb = hThumb,
        labelClipFrame = nil,
        labelContent = nil,
    }

    -- Mouse wheel: unmodified = vertical, Shift = horizontal
    clipFrame:EnableMouseWheel(true)
    clipFrame:SetScript("OnMouseWheel", function(self, delta)
        if IsShiftKeyDown() then
            SC.ScrollHorizontal(container, -delta * C.UI.SCROLL_STEP)
        else
            SC.ScrollVertical(container, -delta * C.UI.SCROLL_STEP)
        end
    end)

    -- Drag support
    SetupDrag(container, vThumb, true)
    SetupDrag(container, hThumb, false)

    -- Initially hide scrollbars (shown when content overflows)
    vTrack:Hide()
    hTrack:Hide()

    return container
end

---------------------------------------------------------------------------
-- Scroll functions
---------------------------------------------------------------------------
function SC.ScrollVertical(container, delta)
    container.vScrollOffset = math.max(0, math.min(container.vScrollOffset + delta, container.vMaxScroll))
    SC.ApplyScroll(container)
end

function SC.ScrollHorizontal(container, delta)
    container.hScrollOffset = math.max(0, math.min(container.hScrollOffset + delta, container.hMaxScroll))
    SC.ApplyScroll(container)
end

function SC.ApplyScroll(container)
    -- Move data content by both offsets
    container.content:ClearAllPoints()
    container.content:SetPoint("TOPLEFT", container.clipFrame, "TOPLEFT",
        -container.hScrollOffset, container.vScrollOffset)

    -- Move label content vertically in sync
    if container.labelContent then
        container.labelContent:ClearAllPoints()
        container.labelContent:SetPoint("TOPLEFT", container.labelClipFrame, "TOPLEFT",
            0, container.vScrollOffset)
    end

    SC.UpdateThumbPositions(container)
end

---------------------------------------------------------------------------
-- Content size setters
---------------------------------------------------------------------------
function SC.SetContentWidth(container, contentWidth)
    container.content:SetWidth(contentWidth)
    local visibleWidth = container.clipFrame:GetWidth()
    container.hMaxScroll = math.max(0, contentWidth - visibleWidth)

    if container.hScrollOffset > container.hMaxScroll then
        container.hScrollOffset = container.hMaxScroll
    end

    -- Resize horizontal thumb proportionally; show/hide track
    if contentWidth > 0 and contentWidth > visibleWidth then
        local ratio = visibleWidth / contentWidth
        local thumbW = math.max(C.UI.SCROLLBAR_MIN_THUMB, ratio * container.hTrack:GetWidth())
        container.hThumb:SetWidth(thumbW)
        container.hTrack:Show()
    else
        container.hTrack:Hide()
    end

    SC.ApplyScroll(container)
end

function SC.SetContentHeight(container, contentHeight)
    container.content:SetHeight(contentHeight)
    local visibleHeight = container.clipFrame:GetHeight()
    container.vMaxScroll = math.max(0, contentHeight - visibleHeight)

    if container.vScrollOffset > container.vMaxScroll then
        container.vScrollOffset = container.vMaxScroll
    end

    -- Resize vertical thumb proportionally; show/hide track
    if contentHeight > 0 and contentHeight > visibleHeight then
        local ratio = visibleHeight / contentHeight
        local thumbH = math.max(C.UI.SCROLLBAR_MIN_THUMB, ratio * container.vTrack:GetHeight())
        container.vThumb:SetHeight(thumbH)
        container.vTrack:Show()
    else
        container.vTrack:Hide()
    end

    SC.ApplyScroll(container)
end

---------------------------------------------------------------------------
-- Link label frame for vertical sync
---------------------------------------------------------------------------
function SC.LinkLabelFrame(container, clipFrame, contentFrame)
    container.labelClipFrame = clipFrame
    container.labelContent = contentFrame
end

---------------------------------------------------------------------------
-- Update thumb positions based on scroll ratio
---------------------------------------------------------------------------
function SC.UpdateThumbPositions(container)
    -- Vertical thumb
    if container.vMaxScroll > 0 then
        local ratio = container.vScrollOffset / container.vMaxScroll
        local trackH = container.vTrack:GetHeight()
        local thumbH = container.vThumb:GetHeight()
        local yOff = ratio * (trackH - thumbH)
        container.vThumb:ClearAllPoints()
        container.vThumb:SetPoint("TOPLEFT", container.vTrack, "TOPLEFT", 0, -yOff)
    else
        container.vThumb:ClearAllPoints()
        container.vThumb:SetPoint("TOPLEFT", container.vTrack, "TOPLEFT", 0, 0)
    end

    -- Horizontal thumb
    if container.hMaxScroll > 0 then
        local ratio = container.hScrollOffset / container.hMaxScroll
        local trackW = container.hTrack:GetWidth()
        local thumbW = container.hThumb:GetWidth()
        local xOff = ratio * (trackW - thumbW)
        container.hThumb:ClearAllPoints()
        container.hThumb:SetPoint("TOPLEFT", container.hTrack, "TOPLEFT", xOff, 0)
    else
        container.hThumb:ClearAllPoints()
        container.hThumb:SetPoint("TOPLEFT", container.hTrack, "TOPLEFT", 0, 0)
    end
end

---------------------------------------------------------------------------
-- Resize
---------------------------------------------------------------------------
function SC.Resize(container, width, height)
    container.clipFrame:SetSize(width, height)

    -- Resize scrollbar tracks
    container.vTrack:SetHeight(height)
    container.hTrack:SetWidth(width)

    -- Recalculate horizontal
    local contentWidth = container.content:GetWidth()
    container.hMaxScroll = math.max(0, contentWidth - width)
    if container.hScrollOffset > container.hMaxScroll then
        container.hScrollOffset = container.hMaxScroll
    end
    if contentWidth > width then
        local ratio = width / contentWidth
        container.hThumb:SetWidth(math.max(C.UI.SCROLLBAR_MIN_THUMB, ratio * width))
        container.hTrack:Show()
    else
        container.hTrack:Hide()
    end

    -- Recalculate vertical
    local contentHeight = container.content:GetHeight()
    container.vMaxScroll = math.max(0, contentHeight - height)
    if container.vScrollOffset > container.vMaxScroll then
        container.vScrollOffset = container.vMaxScroll
    end
    if contentHeight > height then
        local ratio = height / contentHeight
        container.vThumb:SetHeight(math.max(C.UI.SCROLLBAR_MIN_THUMB, ratio * height))
        container.vTrack:Show()
    else
        container.vTrack:Hide()
    end

    SC.ApplyScroll(container)
end
