local _, Weekly = ...

Weekly.Database = {}
local DB = Weekly.Database
local C = Weekly.Constants
local U = Weekly.Utils

---------------------------------------------------------------------------
-- Default database structure
---------------------------------------------------------------------------
local DEFAULT_DB = {
    schemaVersion = C.SCHEMA_VERSION,
    lastResetTimestamp = 0,
    region = nil,

    characters = {},

    settings = {
        minimapButton = { show = true, position = 220 },
        windowPosition = { point = "CENTER", x = 0, y = 0 },
        windowSize = { width = C.UI.WINDOW_WIDTH, height = C.UI.WINDOW_HEIGHT },
        columnWidth = C.UI.CHAR_COLUMN_WIDTH,
        collapsedSections = {},
        showOfflineCharacters = true,
        disabledModules = {},
        hiddenCharacters = {},
        sortBy = "lastSeen",       -- "lastSeen", "ilvl", "name", "custom"
        customCharOrder = {},      -- ordered list of charKeys for custom sort
    },
}

local DEFAULT_CHARACTER = {
    name = "",
    realm = "",
    class = "WARRIOR",
    level = 0,
    faction = "Neutral",
    avgItemLevel = 0,
    avgItemLevelEquipped = 0,
    lastSeen = 0,

    mythicPlus = {
        rating = 0,
        bestKeyLevel = 0,
        bestKeyDungeon = "",
        dungeonRuns = 0,
        vaultSlots = {},
    },

    raids = {},

    vault = {
        mythicPlus = {},
        raids = {},
        world = {},
        canClaim = false,
    },

    weeklyQuests = {},

    specialAssignments = {
        totalCompleted = 0,
        zones = {},
    },

    prey = {
        normal    = { completed = 0, total = 4 },
        hard      = { completed = 0, total = 4 },
        nightmare = { completed = 0, total = 4 },
        journeyProgress = 0,
    },

    delves = {
        bountifulCompleted = 0,
        cofferKeysAvailable = 0,
        cofferKeyShards = 0,
    },
}

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------
function DB.Init()
    if not WeeklyDB then
        WeeklyDB = U.ShallowCopy(DEFAULT_DB)
        WeeklyDB.characters = {}
        WeeklyDB.settings = DB.DeepCopy(DEFAULT_DB.settings)
    end

    -- Migrate if needed
    DB.Migrate()

    -- Ensure settings exist (in case of partial DB)
    if not WeeklyDB.settings then
        WeeklyDB.settings = DB.DeepCopy(DEFAULT_DB.settings)
    end
    if not WeeklyDB.characters then
        WeeklyDB.characters = {}
    end

    Weekly.db = WeeklyDB
end

---------------------------------------------------------------------------
-- Deep copy
---------------------------------------------------------------------------
function DB.DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DB.DeepCopy(v)
    end
    return copy
end

---------------------------------------------------------------------------
-- Get/ensure character data
---------------------------------------------------------------------------
function DB.GetCharacter(charKey)
    if not Weekly.db then return nil end
    return Weekly.db.characters[charKey]
end

function DB.EnsureCharacter(charKey)
    if not Weekly.db then return nil end
    if not Weekly.db.characters[charKey] then
        Weekly.db.characters[charKey] = DB.DeepCopy(DEFAULT_CHARACTER)
    end
    return Weekly.db.characters[charKey]
end

function DB.GetAllCharacters()
    if not Weekly.db then return {} end
    return Weekly.db.characters
end

function DB.GetSortedCharacterKeys()
    local keys = {}
    for key in pairs(Weekly.db.characters) do
        keys[#keys + 1] = key
    end

    local sortBy = DB.GetSettings().sortBy or "lastSeen"

    if sortBy == "custom" then
        -- Follow saved order; any keys not in the list go to the end
        local order = DB.GetSettings().customCharOrder or {}
        local rank = {}
        for i, k in ipairs(order) do
            rank[k] = i
        end
        local fallback = #order + 1
        table.sort(keys, function(a, b)
            return (rank[a] or fallback) < (rank[b] or fallback)
        end)
    elseif sortBy == "ilvl" then
        table.sort(keys, function(a, b)
            local ca = Weekly.db.characters[a]
            local cb = Weekly.db.characters[b]
            return (ca.avgItemLevelEquipped or 0) > (cb.avgItemLevelEquipped or 0)
        end)
    elseif sortBy == "name" then
        table.sort(keys, function(a, b)
            local ca = Weekly.db.characters[a]
            local cb = Weekly.db.characters[b]
            return (ca.name or "") < (cb.name or "")
        end)
    else -- "lastSeen" (default)
        table.sort(keys, function(a, b)
            local ca = Weekly.db.characters[a]
            local cb = Weekly.db.characters[b]
            return (ca.lastSeen or 0) > (cb.lastSeen or 0)
        end)
    end

    return keys
end

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
function DB.GetSettings()
    return Weekly.db and Weekly.db.settings or DEFAULT_DB.settings
end

function DB.IsSectionCollapsed(sectionKey)
    local s = DB.GetSettings()
    return s.collapsedSections[sectionKey] or false
end

function DB.ToggleSection(sectionKey)
    local s = DB.GetSettings()
    s.collapsedSections[sectionKey] = not s.collapsedSections[sectionKey]
end

function DB.IsModuleDisabled(key)
    local s = DB.GetSettings()
    return s.disabledModules[key] or false
end

function DB.SetModuleDisabled(key, disabled)
    local s = DB.GetSettings()
    s.disabledModules[key] = disabled or nil
end

function DB.IsCharacterHidden(charKey)
    local s = DB.GetSettings()
    return s.hiddenCharacters[charKey] or false
end

function DB.SetCharacterHidden(charKey, hidden)
    local s = DB.GetSettings()
    s.hiddenCharacters[charKey] = hidden or nil
end

---------------------------------------------------------------------------
-- Weekly Reset Detection
---------------------------------------------------------------------------
function DB.DetectRegion()
    local region = GetCurrentRegion and GetCurrentRegion() or 1
    if Weekly.db then
        Weekly.db.region = region
    end
    return region
end

function DB.ComputeLastResetTimestamp(region)
    local schedule = C.ResetSchedule[region or 1]
    if not schedule then
        schedule = C.ResetSchedule[1]
    end

    -- Pure UTC arithmetic — no time(table) which interprets as local time
    local now = U.GetServerTime()
    local nowDate = date("!*t", now)

    -- Lua wday: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday...
    local daysSinceReset = (nowDate.wday - schedule.day) % 7

    -- Midnight UTC today, then go back to reset day
    local todayMidnightUTC = now - (nowDate.hour * 3600) - (nowDate.min * 60) - nowDate.sec
    local resetTimestamp = todayMidnightUTC - (daysSinceReset * 86400)
                         + (schedule.hour * 3600) + (schedule.min * 60)

    -- If the computed reset is in the future, go back 7 days
    if resetTimestamp > now then
        resetTimestamp = resetTimestamp - (7 * 86400)
    end

    return resetTimestamp
end

function DB.CheckWeeklyReset()
    if not Weekly.db then return false end

    local region = DB.DetectRegion()
    local lastReset = DB.ComputeLastResetTimestamp(region)

    if Weekly.db.lastResetTimestamp < lastReset then
        U.Print("Weekly reset detected.")
        Weekly.db.lastResetTimestamp = lastReset
        return true
    end

    return false
end

-- Reset a single character's weekly data (called before re-collecting)
function DB.ResetCharacterIfNeeded(charKey, charData)
    if not Weekly.db then return end

    local lastReset = Weekly.db.lastResetTimestamp or 0
    local lastSeen = charData.lastSeen or 0

    -- If character was last seen before the current reset, clear their weekly data
    if lastSeen < lastReset then
        for _, mod in ipairs(Weekly.modules or {}) do
            if mod.OnReset then
                mod:OnReset(charData)
            end
        end
    end
end

-- Manual reset (slash command): only resets current character
function DB.PerformReset()
    local charKey = U.GetCharacterKey()
    if charKey and Weekly.db.characters[charKey] then
        for _, mod in ipairs(Weekly.modules or {}) do
            if mod.OnReset then
                mod:OnReset(Weekly.db.characters[charKey])
            end
        end
    end
end

---------------------------------------------------------------------------
-- Purge character
---------------------------------------------------------------------------
function DB.PurgeCharacter(charKey)
    if Weekly.db and Weekly.db.characters[charKey] then
        Weekly.db.characters[charKey] = nil
        U.Print("Purged character: " .. charKey)
        return true
    end
    U.Print("Character not found: " .. charKey)
    return false
end

---------------------------------------------------------------------------
-- Schema Migration
---------------------------------------------------------------------------
function DB.Migrate()
    if not WeeklyDB then return end

    local version = WeeklyDB.schemaVersion or 0

    -- Migration from version 0 → 1
    if version < 1 then
        WeeklyDB.schemaVersion = 1
        -- Initial schema, nothing to migrate
    end

    if version < 2 then
        WeeklyDB.schemaVersion = 2
        if WeeklyDB.settings then
            if not WeeklyDB.settings.disabledModules then
                WeeklyDB.settings.disabledModules = {}
            end
            if not WeeklyDB.settings.hiddenCharacters then
                WeeklyDB.settings.hiddenCharacters = {}
            end
        end
    end

    if version < 3 then
        WeeklyDB.schemaVersion = 3
        -- Rename pinnacleCaches → specialAssignments on all characters
        if WeeklyDB.characters then
            for _, charData in pairs(WeeklyDB.characters) do
                charData.pinnacleCaches = nil
                if not charData.specialAssignments then
                    charData.specialAssignments = { totalCompleted = 0, zones = {} }
                end
            end
        end
    end

    if version < 4 then
        WeeklyDB.schemaVersion = 4
        if WeeklyDB.settings then
            if not WeeklyDB.settings.sortBy then
                WeeklyDB.settings.sortBy = "lastSeen"
            end
            if not WeeklyDB.settings.customCharOrder then
                WeeklyDB.settings.customCharOrder = {}
            end
        end
    end

    -- Future migrations go here:
    -- if version < 5 then ... end
end
