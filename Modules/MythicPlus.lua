local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants
local mod = {
    key = "mythicPlus",
    label = "Mythic+",
    order = 20,
    events = {
        "CHALLENGE_MODE_COMPLETED",
        "MYTHIC_PLUS_NEW_WEEKLY_RECORD",
        "WEEKLY_REWARDS_UPDATE",
    },
}

-- Module-level dungeon list, discovered from the C_ChallengeMode API.
-- Each entry: { mapID = number, name = string }
mod.seasonDungeons = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- Return a short abbreviation for a dungeon name (used in narrow columns).
local function GetDungeonAbbrev(name)
    if not name or name == "" then return "?" end
    for pattern, abbrev in pairs(C.MythicPlusDungeonAbbrevs or {}) do
        if name:find(pattern) then return abbrev end
    end
    -- Fallback: first 4 characters
    return name:sub(1, 4)
end

-- Discover the current season's dungeon pool from the API.
function mod:DiscoverSeasonDungeons()
    if not C_ChallengeMode or not C_ChallengeMode.GetMapTable then return end
    local mapIDs = C_ChallengeMode.GetMapTable()
    if not mapIDs or #mapIDs == 0 then return end

    local dungeons = {}
    for _, mapID in ipairs(mapIDs) do
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        if name and name ~= "" then
            dungeons[#dungeons + 1] = { mapID = mapID, name = name }
        end
    end

    table.sort(dungeons, function(a, b) return a.name < b.name end)
    self.seasonDungeons = dungeons
end

-- Get the dungeon list, falling back to stored character data if the API
-- hasn't returned anything yet (e.g. window opened before PLAYER_LOGIN).
function mod:GetSeasonDungeons()
    if #self.seasonDungeons > 0 then
        return self.seasonDungeons
    end

    -- Try the API one more time
    self:DiscoverSeasonDungeons()
    if #self.seasonDungeons > 0 then
        return self.seasonDungeons
    end

    -- Fallback: rebuild from any character's stored dungeon data
    local seen = {}
    local dungeons = {}
    local DB = Weekly.Database
    for _, charData in pairs(DB.GetAllCharacters()) do
        if charData.mythicPlus and charData.mythicPlus.dungeons then
            for mapID, info in pairs(charData.mythicPlus.dungeons) do
                if not seen[mapID] and info.name then
                    seen[mapID] = true
                    dungeons[#dungeons + 1] = { mapID = mapID, name = info.name }
                end
            end
        end
    end
    table.sort(dungeons, function(a, b) return a.name < b.name end)
    return dungeons
end

---------------------------------------------------------------------------
-- Collect
---------------------------------------------------------------------------
function mod:Collect(charData)
    if not charData.mythicPlus then
        charData.mythicPlus = {
            rating = 0,
            bestKeyLevel = 0,
            bestKeyDungeon = "",
            dungeonRuns = 0,
            currentKeystone = { level = 0, dungeonName = "" },
            dungeons = {},
        }
    end
    local mp = charData.mythicPlus

    -- Ensure sub-tables exist (handles pre-v6 data)
    if not mp.currentKeystone then
        mp.currentKeystone = { level = 0, dungeonName = "" }
    end
    if not mp.dungeons then
        mp.dungeons = {}
    end

    -- Rating & per-dungeon scores from rating summary
    local ratingSummary
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if ratingSummary then
            mp.rating = ratingSummary.currentSeasonScore or mp.rating
        end
    end

    -- Current Keystone in bags
    if C_MythicPlus then
        local keystoneLevel = C_MythicPlus.GetOwnedKeystoneLevel and C_MythicPlus.GetOwnedKeystoneLevel()
        local keystoneMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID and C_MythicPlus.GetOwnedKeystoneChallengeMapID()

        if keystoneLevel and keystoneLevel > 0 and keystoneMapID then
            local dungeonName = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo(keystoneMapID) or ""
            mp.currentKeystone.level = keystoneLevel
            mp.currentKeystone.dungeonName = dungeonName or ""
        else
            mp.currentKeystone.level = 0
            mp.currentKeystone.dungeonName = ""
        end
    end

    -- Discover season dungeons (updates the module-level list)
    self:DiscoverSeasonDungeons()

    -- Per-dungeon season best from rating summary
    if ratingSummary and ratingSummary.runs then
        for _, run in ipairs(ratingSummary.runs) do
            if run.challengeModeID then
                local dungeonName = C_ChallengeMode and C_ChallengeMode.GetMapUIInfo(run.challengeModeID) or ""
                mp.dungeons[run.challengeModeID] = {
                    name = dungeonName or "",
                    level = run.bestRunLevel or 0,
                    score = run.mapScore or 0,
                    timed = run.finishedSuccess or false,
                }
            end
        end
    end

    -- Also fill in dungeons with zero data for any season dungeon not yet run
    for _, dungeon in ipairs(self.seasonDungeons) do
        if not mp.dungeons[dungeon.mapID] then
            mp.dungeons[dungeon.mapID] = {
                name = dungeon.name,
                level = 0,
                score = 0,
                timed = false,
            }
        end
    end

    -- Weekly run history (for best-key-this-week tracking)
    if C_MythicPlus and C_MythicPlus.GetRunHistory then
        local runs = C_MythicPlus.GetRunHistory(false, true)  -- not completed, this week
        if runs then
            mp.dungeonRuns = #runs
            local bestLevel = 0
            local bestDungeon = ""
            for _, run in ipairs(runs) do
                if run.level and run.level > bestLevel then
                    bestLevel = run.level
                    bestDungeon = run.mapChallengeModeID and C_ChallengeMode and
                        C_ChallengeMode.GetMapUIInfo(run.mapChallengeModeID) or ""
                end
            end
            mp.bestKeyLevel = bestLevel
            mp.bestKeyDungeon = bestDungeon or ""
        end
    end
end

---------------------------------------------------------------------------
-- GetRows
---------------------------------------------------------------------------
function mod:GetRows()
    local rows = {}

    -- Section header
    rows[#rows + 1] = {
        section = self.key,
        label = self.label,
        isHeader = true,
        order = self.order,
    }

    -- Rating
    rows[#rows + 1] = {
        section = self.key,
        label = "  Rating",
        order = self.order + 1,
        getValue = function(charData)
            local mp = charData.mythicPlus
            if not mp or mp.rating == 0 then return U.FormatNA() end
            return tostring(math.floor(mp.rating))
        end,
        getTooltip = function(charData)
            return "Mythic+ Rating for current season"
        end,
    }

    -- Current Keystone
    rows[#rows + 1] = {
        section = self.key,
        label = "  Current Key",
        order = self.order + 2,
        getValue = function(charData)
            local mp = charData.mythicPlus
            if not mp or not mp.currentKeystone or mp.currentKeystone.level == 0 then
                return U.ColorText("-", C.Colors.NOT_STARTED)
            end
            local ks = mp.currentKeystone
            local abbrev = GetDungeonAbbrev(ks.dungeonName)
            return abbrev .. " +" .. ks.level
        end,
        getTooltip = function(charData)
            local mp = charData.mythicPlus
            if mp and mp.currentKeystone and mp.currentKeystone.level > 0 then
                return "Current Keystone: " .. mp.currentKeystone.dungeonName .. " +" .. mp.currentKeystone.level
            end
            return "No keystone"
        end,
    }

    -- Per-dungeon rows (season best)
    local dungeons = self:GetSeasonDungeons()
    for i, dungeon in ipairs(dungeons) do
        local mapID = dungeon.mapID
        local displayName = dungeon.name

        rows[#rows + 1] = {
            section = self.key,
            label = "  " .. U.Abbreviate(displayName, 20),
            order = self.order + 2 + i,
            getValue = function(charData)
                local mp = charData.mythicPlus
                if not mp or not mp.dungeons then return U.ColorText("-", C.Colors.NOT_STARTED) end
                local d = mp.dungeons[mapID]
                if not d or d.level == 0 then
                    return U.ColorText("-", C.Colors.NOT_STARTED)
                end
                local color = d.timed and C.Colors.COMPLETE or C.Colors.IN_PROGRESS
                return U.ColorText("+" .. d.level, color)
            end,
            getTooltip = function(charData)
                local mp = charData.mythicPlus
                if not mp or not mp.dungeons then return displayName .. ": Not completed" end
                local d = mp.dungeons[mapID]
                if not d or d.level == 0 then
                    return displayName .. ": Not completed"
                end
                local timedStr = d.timed and "Timed" or "Over time"
                return displayName .. "\nBest: +" .. d.level .. " (" .. timedStr .. ")\nScore: " .. d.score
            end,
        }
    end

    return rows
end

---------------------------------------------------------------------------
-- OnReset (weekly)
---------------------------------------------------------------------------
function mod:OnReset(charData)
    if charData.mythicPlus then
        charData.mythicPlus.bestKeyLevel = 0
        charData.mythicPlus.bestKeyDungeon = ""
        charData.mythicPlus.dungeonRuns = 0
        charData.mythicPlus.currentKeystone = { level = 0, dungeonName = "" }
        -- Note: per-dungeon season bests are NOT reset weekly (they persist all season)
    end
end

function mod:OnEvent(event, ...)
    -- Events trigger a re-collect via Core.lua throttle
end

Weekly.RegisterModule(mod)
