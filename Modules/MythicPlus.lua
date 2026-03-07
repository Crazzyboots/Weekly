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

    -- Vault progress
    if C_WeeklyRewards and C_WeeklyRewards.GetActivities then
        local activities = C_WeeklyRewards.GetActivities()
        mp.vaultSlots = {}
        if activities then
            for _, activity in ipairs(activities) do
                if activity.type == Enum.WeeklyRewardChestThresholdType.MythicPlus
                    or activity.type == 1 then
                    mp.vaultSlots[#mp.vaultSlots + 1] = {
                        threshold = activity.threshold or 0,
                        progress = activity.progress or 0,
                        earned = (activity.progress or 0) >= (activity.threshold or 1),
                        level = activity.level or 0,
                    }
                end
            end
        end
    end

    -- Vault claimable
    if C_WeeklyRewards and C_WeeklyRewards.CanClaimRewards then
        charData.vault = charData.vault or {}
        charData.vault.canClaim = C_WeeklyRewards.CanClaimRewards()
    end
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

    rows[#rows + 1] = {
        section = self.key,
        label = "  Vault",
        order = self.order + 3,
        getValue = function(charData)
            local mp = charData.mythicPlus
            if not mp or not mp.vaultSlots or #mp.vaultSlots == 0 then
                return U.FormatProgress(0, 3)
            end
            local earned = 0
            for _, slot in ipairs(mp.vaultSlots) do
                if slot.earned then earned = earned + 1 end
            end
            return U.FormatProgress(earned, #mp.vaultSlots)
        end,
        getTooltip = function(charData)
            local mp = charData.mythicPlus
            if not mp or not mp.vaultSlots then return "Vault progress" end
            local lines = { "Great Vault - Mythic+" }
            for i, slot in ipairs(mp.vaultSlots) do
                local status = slot.earned and
                    U.ColorText("Earned (+" .. slot.level .. ")", C.Colors.COMPLETE) or
                    U.FormatProgress(slot.progress, slot.threshold)
                lines[#lines + 1] = "  Slot " .. i .. ": " .. status
            end
            return table.concat(lines, "\n")
        end,
    }

    return rows
end

function mod:OnReset(charData)
    if charData.mythicPlus then
        charData.mythicPlus.bestKeyLevel = 0
        charData.mythicPlus.bestKeyDungeon = ""
        charData.mythicPlus.dungeonRuns = 0
        charData.mythicPlus.vaultSlots = {}
    end
    if charData.vault then
        charData.vault.canClaim = false
    end
end

function mod:OnEvent(event, ...)
    -- Events trigger a re-collect via Core.lua throttle
end

Weekly.RegisterModule(mod)
