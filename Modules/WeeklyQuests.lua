local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "weeklyQuests",
    label = "Weeklies",
    order = 40,
    events = {
        "QUEST_TURNED_IN",
    },
}

function mod:Collect(charData)
    if not charData.weeklyQuests then
        charData.weeklyQuests = {}
    end

    for _, quest in ipairs(C.WeeklyQuests) do
        local completed = false
        local matchedID = nil

        for _, qid in ipairs(quest.questIDs) do
            if qid > 0 and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
                if C_QuestLog.IsQuestFlaggedCompleted(qid) then
                    completed = true
                    matchedID = qid
                    break
                end
            end
        end

        charData.weeklyQuests[quest.key] = {
            completed = completed,
            questID = matchedID,
        }
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

    for _, quest in ipairs(C.WeeklyQuests) do
        rows[#rows + 1] = {
            section = self.key,
            label = "  " .. quest.label,
            order = self.order + 1,
            getValue = function(charData)
                local data = U.SafeGet(charData, "weeklyQuests", quest.key)
                if not data then return U.FormatCheckmark(false) end
                return U.FormatCheckmark(data.completed)
            end,
            getTooltip = function(charData)
                local data = U.SafeGet(charData, "weeklyQuests", quest.key)
                local status = (data and data.completed) and "Completed" or "Not completed"
                return quest.label .. ": " .. status
            end,
        }
    end

    return rows
end

function mod:OnReset(charData)
    charData.weeklyQuests = {}
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
