local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "greatVault",
    label = "Great Vault",
    order = 100,
    events = {
        "WEEKLY_REWARDS_UPDATE",
        "CURRENCY_DISPLAY_UPDATE",
        "QUEST_TURNED_IN",
    },
}

-- Voidcore weekly completion: any of the three Decimus exchange quests
-- counts (they all reward the same 2 cores under one shared weekly cap),
-- and currency-cap detection (totalEarned >= maxQuantity) covers the case
-- where the quest flag isn't yet visible.
local function ComputeVoidcoreCompleted(info)
    if info and info.totalEarned and info.maxQuantity and info.maxQuantity > 0 then
        if info.totalEarned >= info.maxQuantity then
            return true
        end
    end
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        for _, qid in ipairs(C.Voidcore and C.Voidcore.questIDs or {}) do
            if qid > 0 and C_QuestLog.IsQuestFlaggedCompleted(qid) then
                return true
            end
        end
    end
    return false
end

-- Difficulty names for raid vault display
local DIFF_NAMES = {
    [17] = "LFR",
    [14] = "N",
    [15] = "H",
    [16] = "M",
}

function mod:Collect(charData)
    if not charData.greatVault then
        charData.greatVault = {}
    end
    local gv = charData.greatVault

    gv.canClaim = false
    gv.mythicPlus = {}
    gv.raid = {}
    gv.world = {}

    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return end

    local activities = C_WeeklyRewards.GetActivities()
    if not activities then return end

    for _, activity in ipairs(activities) do
        local slot = {
            index = activity.index or 0,
            threshold = activity.threshold or 0,
            progress = activity.progress or 0,
            level = activity.level or 0,
            id = activity.id or 0,
        }
        slot.earned = slot.progress >= slot.threshold

        local aType = activity.type
        -- Use enum if available, fall back to known numeric values
        if aType == (Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.Activities or 1)
            or aType == 1 then
            gv.mythicPlus[#gv.mythicPlus + 1] = slot
        elseif aType == (Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.Raid or 3)
            or aType == 3 then
            gv.raid[#gv.raid + 1] = slot
        elseif aType == (Enum.WeeklyRewardChestThresholdType and Enum.WeeklyRewardChestThresholdType.World or 6)
            or aType == 6 then
            gv.world[#gv.world + 1] = slot
        end
    end

    -- Sort each category by index
    table.sort(gv.mythicPlus, function(a, b) return a.index < b.index end)
    table.sort(gv.raid, function(a, b) return a.index < b.index end)
    table.sort(gv.world, function(a, b) return a.index < b.index end)

    if C_WeeklyRewards.CanClaimRewards then
        gv.canClaim = C_WeeklyRewards.CanClaimRewards()
    end
    if C_WeeklyRewards.HasAvailableRewards then
        gv.hasAvailableRewards = C_WeeklyRewards.HasAvailableRewards()
    end

    -- Nebulous Voidcore (rendered in this section, stored separately)
    if not charData.voidcore then
        charData.voidcore = { quantity = 0, totalEarned = 0, maxQuantity = 0, weeklyCompleted = false }
    end
    if C.Voidcore and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(C.Voidcore.currencyID)
        if info then
            charData.voidcore.quantity        = info.quantity or 0
            charData.voidcore.totalEarned     = info.totalEarned or 0
            charData.voidcore.maxQuantity     = info.maxQuantity or 0
            charData.voidcore.weeklyCompleted = ComputeVoidcoreCompleted(info)
        end
    end
end

-- Helper: summarize slots earned and best level for display
local function SlotSummary(slots)
    if not slots or #slots == 0 then return 0, 3, 0 end
    local earned = 0
    local bestLevel = 0
    for _, slot in ipairs(slots) do
        if slot.earned then
            earned = earned + 1
            if slot.level > bestLevel then bestLevel = slot.level end
        end
    end
    return earned, #slots, bestLevel
end

-- Helper: build a compact display string like "2/3" or "2/3 (+7)"
local function FormatVaultCell(slots, levelFormatter)
    local earned, total, bestLevel = SlotSummary(slots)
    local base = earned .. "/" .. total
    local color = U.ProgressColor(earned, total)
    if earned > 0 and bestLevel > 0 and levelFormatter then
        return U.ColorText(base .. " " .. levelFormatter(bestLevel), color)
    end
    return U.ColorText(base, color)
end

function mod:GetRows()
    local rows = {}

    rows[#rows + 1] = {
        section = self.key,
        label = self.label,
        isHeader = true,
        order = self.order,
    }

    -- Row 1: Mythic+ vault
    rows[#rows + 1] = {
        section = self.key,
        label = "  Mythic+",
        order = self.order + 1,
        getValue = function(charData)
            local gv = charData.greatVault
            if not gv then return U.FormatProgress(0, 3) end
            return FormatVaultCell(gv.mythicPlus, function(lvl)
                return "(+" .. lvl .. ")"
            end)
        end,
        getTooltip = function(charData)
            local gv = charData.greatVault
            if not gv or not gv.mythicPlus then return "Great Vault — Mythic+" end
            local lines = { "Great Vault — Mythic+" }
            for _, slot in ipairs(gv.mythicPlus) do
                if slot.earned then
                    lines[#lines + 1] = "  Slot " .. slot.index .. ": " ..
                        U.ColorText("+" .. slot.level .. " \226\156\148", C.Colors.COMPLETE)
                else
                    local remaining = slot.threshold - slot.progress
                    lines[#lines + 1] = "  Slot " .. slot.index .. ": " ..
                        U.ColorText(remaining .. " more to unlock", C.Colors.IN_PROGRESS)
                end
            end
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Complete 1/4/8 dungeons"
            return table.concat(lines, "\n")
        end,
    }

    -- Row 2: Raid vault
    rows[#rows + 1] = {
        section = self.key,
        label = "  Raid",
        order = self.order + 2,
        getValue = function(charData)
            local gv = charData.greatVault
            if not gv then return U.FormatProgress(0, 3) end
            return FormatVaultCell(gv.raid, function(lvl)
                return "(" .. (DIFF_NAMES[lvl] or "?") .. ")"
            end)
        end,
        getTooltip = function(charData)
            local gv = charData.greatVault
            if not gv or not gv.raid then return "Great Vault — Raid" end
            local lines = { "Great Vault — Raid" }
            for _, slot in ipairs(gv.raid) do
                if slot.earned then
                    local diffName = DIFF_NAMES[slot.level] or ("Diff " .. slot.level)
                    lines[#lines + 1] = "  Slot " .. slot.index .. ": " ..
                        U.ColorText(diffName .. " \226\156\148", C.Colors.COMPLETE)
                else
                    local remaining = slot.threshold - slot.progress
                    lines[#lines + 1] = "  Slot " .. slot.index .. ": " ..
                        U.ColorText(remaining .. " more to unlock", C.Colors.IN_PROGRESS)
                end
            end
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Kill 2/4/6 raid bosses"
            return table.concat(lines, "\n")
        end,
    }

    -- Row 3: World (Delves) vault
    rows[#rows + 1] = {
        section = self.key,
        label = "  World",
        order = self.order + 3,
        getValue = function(charData)
            local gv = charData.greatVault
            if not gv then return U.FormatProgress(0, 3) end
            return FormatVaultCell(gv.world, function(lvl)
                return "(T" .. lvl .. ")"
            end)
        end,
        getTooltip = function(charData)
            local gv = charData.greatVault
            if not gv or not gv.world then return "Great Vault — World" end
            local lines = { "Great Vault — World (Delves)" }
            for _, slot in ipairs(gv.world) do
                if slot.earned then
                    lines[#lines + 1] = "  Slot " .. slot.index .. ": " ..
                        U.ColorText("Tier " .. slot.level .. " \226\156\148", C.Colors.COMPLETE)
                else
                    local remaining = slot.threshold - slot.progress
                    lines[#lines + 1] = "  Slot " .. slot.index .. ": " ..
                        U.ColorText(remaining .. " more to unlock", C.Colors.IN_PROGRESS)
                end
            end
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Complete 2/4/8 delves or world activities"
            return table.concat(lines, "\n")
        end,
    }

    return rows
end

function mod:OnReset(charData)
    charData.greatVault = {
        canClaim = false,
        hasAvailableRewards = false,
        mythicPlus = {},
        raid = {},
        world = {},
    }
    -- Voidcore: currency persists across resets; weeklyCompleted recomputes
    -- on next Collect from totalEarned vs the bumped maxQuantity.
    if charData.voidcore then
        charData.voidcore.weeklyCompleted = false
    end
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
