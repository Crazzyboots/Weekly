local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "delves",
    label = "Delves",
    order = 40,
    events = {
        "QUEST_TURNED_IN",
        "CURRENCY_DISPLAY_UPDATE",
    },
}

function mod:Collect(charData)
    if not charData.delves then
        charData.delves = {}
    end
    local d = charData.delves

    -- Coffer keys via currency (Restored Coffer Key)
    if C.Delves.cofferKeyCurrencyID > 0 and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(C.Delves.cofferKeyCurrencyID)
        if info then
            d.cofferKeysAvailable = info.quantity or 0
        end
    end

    -- Coffer Key Shards via currency (weekly tracking)
    if C.Delves.cofferKeyShardsCurrencyID and C.Delves.cofferKeyShardsCurrencyID > 0
        and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(C.Delves.cofferKeyShardsCurrencyID)
        if info then
            d.cofferKeyShards = info.quantity or 0
            d.cofferKeyShardsWeekly = info.quantityEarnedThisWeek or 0
            d.cofferKeyShardsWeeklyMax = info.maxWeeklyQuantity or C.Delves.maxWeeklyShards
        end
    end

    -- Delver's Bounty map (weekly quest flag)
    if C.Delves.delversBountyQuestID and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        d.delversBountyObtained = C_QuestLog.IsQuestFlaggedCompleted(C.Delves.delversBountyQuestID)
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

    -- Row 1: Coffer Key Shards weekly progress (e.g. "320/600")
    rows[#rows + 1] = {
        section = self.key,
        label = "  Shards",
        order = self.order + 1,
        getValue = function(charData)
            local d = charData.delves
            if not d then return U.ColorText("0/600", C.Colors.NOT_STARTED) end
            local earned = d.cofferKeyShardsWeekly or 0
            local cap = d.cofferKeyShardsWeeklyMax or C.Delves.maxWeeklyShards
            local color
            if earned >= cap then
                color = C.Colors.COMPLETE
            elseif earned > 0 then
                color = C.Colors.IN_PROGRESS
            else
                color = C.Colors.NOT_STARTED
            end
            return U.ColorText(earned .. "/" .. cap, color)
        end,
        getTooltip = function(charData)
            local d = charData.delves
            if not d then return "Coffer Key Shards" end
            local lines = { "Coffer Key Shards (Weekly)" }
            local earned = d.cofferKeyShardsWeekly or 0
            local cap = d.cofferKeyShardsWeeklyMax or C.Delves.maxWeeklyShards
            lines[#lines + 1] = "Earned this week: " .. earned .. "/" .. cap
            lines[#lines + 1] = "Total on hand: " .. (d.cofferKeyShards or 0)
            lines[#lines + 1] = ""
            lines[#lines + 1] = "100 shards = 1 Restored Coffer Key"
            return table.concat(lines, "\n")
        end,
    }

    -- Row 2: Delver's Bounty (weekly map obtained?)
    rows[#rows + 1] = {
        section = self.key,
        label = "  Bounty",
        order = self.order + 2,
        getValue = function(charData)
            local d = charData.delves
            if not d then return U.ColorText("\226\128\148", C.Colors.NOT_STARTED) end
            if d.delversBountyObtained then
                return U.ColorText("\226\156\148", C.Colors.COMPLETE)
            else
                return U.ColorText("\226\156\151", C.Colors.NOT_STARTED)
            end
        end,
        getTooltip = function(charData)
            local d = charData.delves
            local obtained = d and d.delversBountyObtained
            local lines = { "Delver's Bounty" }
            if obtained then
                lines[#lines + 1] = "Obtained this week"
            else
                lines[#lines + 1] = "Not yet obtained this week"
            end
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Looted from Bountiful Delves."
            lines[#lines + 1] = "Use before final boss for a"
            lines[#lines + 1] = "Hidden Trove (Hero-track gear)."
            return table.concat(lines, "\n")
        end,
    }

    -- Row 3: Restored Coffer Keys on hand
    rows[#rows + 1] = {
        section = self.key,
        label = "  Keys",
        order = self.order + 3,
        getValue = function(charData)
            local d = charData.delves
            if not d then return "0" end
            local n = d.cofferKeysAvailable or 0
            local color = n > 0 and C.Colors.IN_PROGRESS or C.Colors.NOT_STARTED
            return U.ColorText(tostring(n), color)
        end,
        getTooltip = function(charData)
            local d = charData.delves
            if not d then return "Coffer Keys" end
            local lines = { "Restored Coffer Keys" }
            lines[#lines + 1] = "Available: " .. (d.cofferKeysAvailable or 0)
            return table.concat(lines, "\n")
        end,
    }

    return rows
end

function mod:OnReset(charData)
    charData.delves = {
        cofferKeysAvailable = charData.delves and charData.delves.cofferKeysAvailable or 0,
        cofferKeyShards = charData.delves and charData.delves.cofferKeyShards or 0,
        cofferKeyShardsWeekly = 0,
        cofferKeyShardsWeeklyMax = C.Delves.maxWeeklyShards,
        delversBountyObtained = false,
    }
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
