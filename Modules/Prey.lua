local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "prey",
    label = "Prey",
    order = 50,
    events = {
        "QUEST_TURNED_IN",
    },
}

---------------------------------------------------------------------------
-- Collect: SavedInstances "list" pattern
-- Scan all known prey quest IDs per difficulty via IsQuestFlaggedCompleted.
-- The server clears these flags on weekly reset, so any that return true
-- were completed this week — regardless of which targets rotated in.
---------------------------------------------------------------------------
function mod:Collect(charData)
    if not charData.prey then
        charData.prey = {
            normal    = { completed = 0, total = 4 },
            hard      = { completed = 0, total = 4 },
            nightmare = { completed = 0, total = 4 },
            journeyProgress = 0,
        }
    end

    for _, diff in ipairs(C.PreyDifficulties) do
        local questIDs = C.PreyQuestIDs and C.PreyQuestIDs[diff.key]
        local completed = 0

        if questIDs then
            for _, qid in ipairs(questIDs) do
                if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(qid) then
                    completed = completed + 1
                end
            end
        end

        charData.prey[diff.key] = {
            completed = completed,
            total = diff.total,
        }
    end

    -- Track Preyseeker's Journey currency
    if C.PreyCurrencyID > 0 and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(C.PreyCurrencyID)
        if info then
            charData.prey.journeyProgress = info.quantity or 0
        end
    end

    -- A Nightmarish Task (weekly quest: 3 Nightmare Hunts)
    if C.NightmarishTask and C.NightmarishTask.questID and C_QuestLog then
        if C_QuestLog.IsQuestFlaggedCompleted(C.NightmarishTask.questID) then
            charData.prey.nightmarishTask = { completed = true, progress = C.NightmarishTask.total, total = C.NightmarishTask.total }
        else
            local progress = 0
            local objectives = C_QuestLog.GetQuestObjectives(C.NightmarishTask.questID)
            if objectives and objectives[1] then
                progress = objectives[1].numFulfilled or 0
            end
            charData.prey.nightmarishTask = { completed = false, progress = progress, total = C.NightmarishTask.total }
        end
    end
end

---------------------------------------------------------------------------
-- Rows
---------------------------------------------------------------------------
function mod:GetRows()
    local rows = {}

    rows[#rows + 1] = {
        section = self.key,
        label = self.label,
        isHeader = true,
        order = self.order,
    }

    for _, diff in ipairs(C.PreyDifficulties) do
        rows[#rows + 1] = {
            section = self.key,
            label = "  " .. diff.label,
            order = self.order + 1,
            getValue = function(charData)
                local data = U.SafeGet(charData, "prey", diff.key)
                if not data then return U.FormatProgress(0, diff.total) end
                return U.FormatProgress(data.completed, data.total)
            end,
            getTooltip = function(charData)
                local data = U.SafeGet(charData, "prey", diff.key)
                local prey = charData.prey
                local lines = { "Prey Hunts - " .. diff.label }
                if data then
                    lines[#lines + 1] = "Completed: " .. data.completed .. "/" .. data.total
                end
                if prey and prey.journeyProgress and prey.journeyProgress > 0 then
                    lines[#lines + 1] = "Preyseeker's Journey: " .. prey.journeyProgress
                end
                return table.concat(lines, "\n")
            end,
        }
    end

    -- A Nightmarish Task row
    rows[#rows + 1] = {
        section = self.key,
        label = "  Nightmare Task",
        order = self.order + 2,
        getValue = function(charData)
            local nt = U.SafeGet(charData, "prey", "nightmarishTask")
            if not nt then return U.FormatProgress(0, C.NightmarishTask.total) end
            return U.FormatProgress(nt.progress, nt.total)
        end,
        getTooltip = function(charData)
            local nt = U.SafeGet(charData, "prey", "nightmarishTask")
            local lines = { "A Nightmarish Task (Weekly)" }
            if nt and nt.completed then
                lines[#lines + 1] = "|cff00ff00Completed this week|r"
            elseif nt and nt.progress > 0 then
                lines[#lines + 1] = "Nightmare Hunts: " .. nt.progress .. "/" .. nt.total
            else
                lines[#lines + 1] = "Not started"
            end
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Complete 3 Nightmare Prey Hunts."
            lines[#lines + 1] = "Rewards 20 uncapped Hero Crests"
            lines[#lines + 1] = "and a Beacon of Hope (drops in a delve)."
            return table.concat(lines, "\n")
        end,
    }

    return rows
end

---------------------------------------------------------------------------
-- Reset: server clears IsQuestFlaggedCompleted on weekly reset,
-- so next Collect() will naturally return 0s. We also clear stored data.
---------------------------------------------------------------------------
function mod:OnReset(charData)
    charData.prey = {
        normal    = { completed = 0, total = 4 },
        hard      = { completed = 0, total = 4 },
        nightmare = { completed = 0, total = 4 },
        journeyProgress = charData.prey and charData.prey.journeyProgress or 0,
        nightmarishTask = { completed = false, progress = 0, total = C.NightmarishTask.total },
    }
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
