local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "specialAssignments",
    label = "Assignments",
    order = 90,
    events = {
        "QUEST_TURNED_IN",
    },
}

function mod:Collect(charData)
    if not charData.specialAssignments then
        charData.specialAssignments = { totalCompleted = 0, zones = {} }
    end
    local sa = charData.specialAssignments

    local total = 0
    sa.zones = {}

    for _, assignment in ipairs(C.SpecialAssignments) do
        local completed = false
        for _, qid in ipairs(assignment.questIDs) do
            if qid > 0 and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
                if C_QuestLog.IsQuestFlaggedCompleted(qid) then
                    completed = true
                    break
                end
            end
        end

        sa.zones[assignment.key] = { name = assignment.label, completed = completed }
        if completed then
            total = total + 1
        end
    end

    sa.totalCompleted = total
end

function mod:GetRows()
    local rows = {}
    local numAssignments = #C.SpecialAssignments

    rows[#rows + 1] = {
        section = self.key,
        label = self.label,
        isHeader = true,
        order = self.order,
    }

    for _, assignment in ipairs(C.SpecialAssignments) do
        rows[#rows + 1] = {
            section = self.key,
            label = "  " .. assignment.label,
            order = self.order + 1,
            getValue = function(charData)
                local data = U.SafeGet(charData, "specialAssignments", "zones", assignment.key)
                if not data then return U.FormatCheckmark(false) end
                return U.FormatCheckmark(data.completed)
            end,
            getTooltip = function(charData)
                local data = U.SafeGet(charData, "specialAssignments", "zones", assignment.key)
                local status = (data and data.completed) and "Completed" or "Not completed"
                return "Special Assignment: " .. assignment.label .. "\n" .. status
            end,
        }
    end

    return rows
end

function mod:OnReset(charData)
    charData.specialAssignments = { totalCompleted = 0, zones = {} }
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
