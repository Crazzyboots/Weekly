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

function mod:Collect(charData)
    if not charData.mythicPlus then
        charData.mythicPlus = { rating = 0, bestKeyLevel = 0, bestKeyDungeon = "", dungeonRuns = 0, vaultSlots = {} }
    end
    local mp = charData.mythicPlus

    -- Rating
    if C_PlayerInfo and C_PlayerInfo.GetPlayerMythicPlusRatingSummary then
        local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
        if summary then
            mp.rating = summary.currentSeasonScore or mp.rating
        end
    end

    -- Run history (current week)
    if C_MythicPlus and C_MythicPlus.GetRunHistory then
        local runs = C_MythicPlus.GetRunHistory(false, true)  -- not completed, this week
        if runs then
            mp.dungeonRuns = #runs
            -- Find best key this week
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

    -- Vault data now handled by GreatVault module
end

function mod:GetRows()
    local rows = {}

    rows[#rows + 1] = {
        section = self.key,
        label = self.label,
        isHeader = true,
        order = self.order,
    }

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

    rows[#rows + 1] = {
        section = self.key,
        label = "  Best Key",
        order = self.order + 2,
        getValue = function(charData)
            local mp = charData.mythicPlus
            if not mp or mp.bestKeyLevel == 0 then return U.FormatNA() end
            local text = "+" .. mp.bestKeyLevel
            return text
        end,
        getTooltip = function(charData)
            local mp = charData.mythicPlus
            if mp and mp.bestKeyDungeon and mp.bestKeyDungeon ~= "" then
                return "Best key this week: +" .. mp.bestKeyLevel .. " " .. mp.bestKeyDungeon
            end
            return "Best key this week"
        end,
    }

    return rows
end

function mod:OnReset(charData)
    if charData.mythicPlus then
        charData.mythicPlus.bestKeyLevel = 0
        charData.mythicPlus.bestKeyDungeon = ""
        charData.mythicPlus.dungeonRuns = 0
    end
end

function mod:OnEvent(event, ...)
    -- Events trigger a re-collect via Core.lua throttle
end

Weekly.RegisterModule(mod)
