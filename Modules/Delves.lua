local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "delves",
    label = "Delves",
    order = 70,
    events = {
        "QUEST_TURNED_IN",
    },
}

function mod:Collect(charData)
    if not charData.delves then
        charData.delves = {
            bountifulCompleted = 0,
            cofferKeysAvailable = 0,
            cofferKeyShards = 0,
        }
    end
    local d = charData.delves

    -- Bountiful completions via quest flags
    local bountiful = 0
    for _, qid in ipairs(C.Delves.bountifulQuestIDs) do
        if qid > 0 and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
            if C_QuestLog.IsQuestFlaggedCompleted(qid) then
                bountiful = bountiful + 1
            end
        end
    end
    d.bountifulCompleted = bountiful

    -- Coffer keys via currency (Restored Coffer Key)
    if C.Delves.cofferKeyCurrencyID > 0 and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(C.Delves.cofferKeyCurrencyID)
        if info then
            d.cofferKeysAvailable = info.quantity or 0
        end
    end

    -- Coffer Key Shards via currency
    if C.Delves.cofferKeyShardsCurrencyID and C.Delves.cofferKeyShardsCurrencyID > 0
        and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(C.Delves.cofferKeyShardsCurrencyID)
        if info then
            d.cofferKeyShards = info.quantity or 0
        end
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
        label = "  Bountiful",
        order = self.order + 1,
        getValue = function(charData)
            local d = charData.delves
            if not d then return "0" end
            local n = d.bountifulCompleted or 0
            local color = n > 0 and C.Colors.COMPLETE or C.Colors.NOT_STARTED
            return U.ColorText(tostring(n), color)
        end,
        getTooltip = function(charData)
            return "Bountiful Delve completions this week"
        end,
    }

    rows[#rows + 1] = {
        section = self.key,
        label = "  Keys",
        order = self.order + 2,
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
            if (d.cofferKeyShards or 0) > 0 then
                lines[#lines + 1] = "Shards: " .. d.cofferKeyShards .. "/100"
            end
            return table.concat(lines, "\n")
        end,
    }

    return rows
end

function mod:OnReset(charData)
    charData.delves = {
        bountifulCompleted = 0,
        cofferKeysAvailable = charData.delves and charData.delves.cofferKeysAvailable or 0,
        cofferKeyShards = charData.delves and charData.delves.cofferKeyShards or 0,
    }
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
