local _, Weekly = ...

Weekly.Utils = {}
local U = Weekly.Utils
local C = Weekly.Constants

---------------------------------------------------------------------------
-- Class color helpers
---------------------------------------------------------------------------
function U.GetClassColor(classFile)
    -- Prefer Blizzard's RAID_CLASS_COLORS if available
    if RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] then
        local c = RAID_CLASS_COLORS[classFile]
        return c.r, c.g, c.b
    end
    local c = C.ClassColors[classFile]
    if c then
        return c.r, c.g, c.b
    end
    return 1, 1, 1
end

function U.ClassColoredText(text, classFile)
    local r, g, b = U.GetClassColor(classFile)
    return string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, text)
end

---------------------------------------------------------------------------
-- Color helpers
---------------------------------------------------------------------------
function U.ColorText(text, color)
    return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
end

function U.ProgressColor(current, total)
    if current >= total then
        return C.Colors.COMPLETE
    elseif current > 0 then
        return C.Colors.IN_PROGRESS
    else
        return C.Colors.NOT_STARTED
    end
end

---------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------
function U.FormatProgress(current, total)
    local color = U.ProgressColor(current, total)
    return U.ColorText(current .. "/" .. total, color)
end

function U.FormatCheckmark(completed)
    if completed then
        return "|cff00ff00\226\156\148|r"   -- green ✔
    else
        return "|cff666666\226\128\148|r"    -- grey dash —
    end
end

function U.FormatNA()
    return U.ColorText("N/A", C.Colors.UNAVAILABLE)
end

function U.Abbreviate(text, maxLen)
    maxLen = maxLen or 12
    if #text <= maxLen then return text end
    return text:sub(1, maxLen - 1) .. "\226\128\166"  -- …
end

---------------------------------------------------------------------------
-- Character key
---------------------------------------------------------------------------
function U.GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if name and realm then
        return realm .. "-" .. name
    end
    return nil
end

---------------------------------------------------------------------------
-- Table utilities
---------------------------------------------------------------------------
function U.ShallowCopy(src)
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = v
    end
    return copy
end

function U.SafeGet(tbl, ...)
    local current = tbl
    for i = 1, select("#", ...) do
        if type(current) ~= "table" then return nil end
        current = current[select(i, ...)]
    end
    return current
end

---------------------------------------------------------------------------
-- Timestamp
---------------------------------------------------------------------------
function U.GetServerTime()
    return GetServerTime and GetServerTime() or time()
end

---------------------------------------------------------------------------
-- Debug print
---------------------------------------------------------------------------
function U.Print(msg)
    print("|cff00ccff[Weekly]|r " .. tostring(msg))
end

function U.Debug(msg)
    if Weekly.debug then
        print("|cff888888[Weekly-Debug]|r " .. tostring(msg))
    end
end
