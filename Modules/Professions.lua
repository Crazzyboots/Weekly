local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "professions",
    label = "Professions",
    order = 70,
    events = {
        "QUEST_TURNED_IN",
    },
}

---------------------------------------------------------------------------
-- Helper: check if any quest in a list is flagged completed
---------------------------------------------------------------------------
local function IsAnyQuestCompleted(questIDs)
    if not questIDs or not C_QuestLog or not C_QuestLog.IsQuestFlaggedCompleted then
        return false
    end
    for _, qid in ipairs(questIDs) do
        if qid > 0 and C_QuestLog.IsQuestFlaggedCompleted(qid) then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------
-- Helper: count how many quests in a list are flagged completed
---------------------------------------------------------------------------
local function CountQuestsCompleted(questIDs)
    if not questIDs or not C_QuestLog or not C_QuestLog.IsQuestFlaggedCompleted then
        return 0
    end
    local count = 0
    for _, qid in ipairs(questIDs) do
        if qid > 0 and C_QuestLog.IsQuestFlaggedCompleted(qid) then
            count = count + 1
        end
    end
    return count
end

---------------------------------------------------------------------------
-- Collect profession knowledge data for current character
---------------------------------------------------------------------------
function mod:Collect(charData)
    if not charData.professions then
        charData.professions = {}
    end

    if not GetProfessions then return end
    local prof1, prof2 = GetProfessions()

    local profIndices = { prof1, prof2 }
    local trackedCount = 0

    for slot = 1, 2 do
        local profIndex = profIndices[slot]
        if profIndex then
            local name, _, _, _, _, _, skillLine = GetProfessionInfo(profIndex)
            local ttwSkillLine = C.ProfessionBaseToTWW[skillLine] or skillLine
            local profData = C.Professions[ttwSkillLine]
            if profData then
                local treasuresCompleted = CountQuestsCompleted(profData.treasureQuestIDs)
                trackedCount = trackedCount + 1

                charData.professions[slot] = {
                    skillLine = ttwSkillLine,
                    name = profData.name,
                    abbrev = profData.abbrev,
                    treatise = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
                        and C_QuestLog.IsQuestFlaggedCompleted(profData.treatiseQuestID) or false,
                    quest = IsAnyQuestCompleted(profData.weeklyQuestIDs),
                    treasuresCompleted = math.min(treasuresCompleted, 2),
                    treasuresTotal = 2,
                }
            else
                charData.professions[slot] = nil
            end
        else
            charData.professions[slot] = nil
        end
    end

    charData.professions.trackedCount = trackedCount
end

---------------------------------------------------------------------------
-- Helpers: aggregate across both profession slots
---------------------------------------------------------------------------
local function GetTrackedProfs(charData)
    local profs = charData and charData.professions
    if not profs then return nil end
    local list = {}
    for slot = 1, 2 do
        if profs[slot] then
            list[#list + 1] = profs[slot]
        end
    end
    if #list == 0 then return nil end
    return list
end

---------------------------------------------------------------------------
-- Build grid rows — 3 compact rows aggregating both professions
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

    -- Treatise row: X/N where N = number of tracked professions
    rows[#rows + 1] = {
        section = self.key,
        label = "  Treatise",
        order = self.order + 1,
        getValue = function(charData)
            local profs = GetTrackedProfs(charData)
            if not profs then return U.ColorText("\226\128\148", C.Colors.UNAVAILABLE) end
            local done = 0
            for _, p in ipairs(profs) do
                if p.treatise then done = done + 1 end
            end
            return U.FormatProgress(done, #profs)
        end,
        getTooltip = function(charData)
            local profs = GetTrackedProfs(charData)
            if not profs then return "No tracked professions" end
            local lines = { "Treatise" }
            for _, p in ipairs(profs) do
                local status = p.treatise and "|cff00ff00Complete|r" or "|cffff4444Incomplete|r"
                lines[#lines + 1] = "  " .. p.name .. ": " .. status
            end
            return table.concat(lines, "\n")
        end,
    }

    -- Quest row: X/N
    rows[#rows + 1] = {
        section = self.key,
        label = "  Quest",
        order = self.order + 2,
        getValue = function(charData)
            local profs = GetTrackedProfs(charData)
            if not profs then return U.ColorText("\226\128\148", C.Colors.UNAVAILABLE) end
            local done = 0
            for _, p in ipairs(profs) do
                if p.quest then done = done + 1 end
            end
            return U.FormatProgress(done, #profs)
        end,
        getTooltip = function(charData)
            local profs = GetTrackedProfs(charData)
            if not profs then return "No tracked professions" end
            local lines = { "Weekly Quest" }
            for _, p in ipairs(profs) do
                local status = p.quest and "|cff00ff00Complete|r" or "|cffff4444Incomplete|r"
                lines[#lines + 1] = "  " .. p.name .. ": " .. status
            end
            return table.concat(lines, "\n")
        end,
    }

    -- Treasures row: X/N (2 per tracked prof)
    rows[#rows + 1] = {
        section = self.key,
        label = "  Treasures",
        order = self.order + 3,
        getValue = function(charData)
            local profs = GetTrackedProfs(charData)
            if not profs then return U.ColorText("\226\128\148", C.Colors.UNAVAILABLE) end
            local done, total = 0, 0
            for _, p in ipairs(profs) do
                done = done + p.treasuresCompleted
                total = total + p.treasuresTotal
            end
            return U.FormatProgress(done, total)
        end,
        getTooltip = function(charData)
            local profs = GetTrackedProfs(charData)
            if not profs then return "No tracked professions" end
            local lines = { "Treasures" }
            for _, p in ipairs(profs) do
                local status
                if p.treasuresCompleted >= p.treasuresTotal then
                    status = "|cff00ff00Complete|r"
                elseif p.treasuresCompleted > 0 then
                    status = "|cffffcc00" .. p.treasuresCompleted .. "/" .. p.treasuresTotal .. "|r"
                else
                    status = "|cffff4444Incomplete|r"
                end
                lines[#lines + 1] = "  " .. p.name .. ": " .. status
            end
            return table.concat(lines, "\n")
        end,
    }

    return rows
end

---------------------------------------------------------------------------
-- Weekly reset: clear completion flags, keep profession identity
---------------------------------------------------------------------------
function mod:OnReset(charData)
    if not charData.professions then return end

    for slot = 1, 2 do
        local p = charData.professions[slot]
        if p then
            p.treatise = false
            p.quest = false
            p.treasuresCompleted = 0
        end
    end
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
