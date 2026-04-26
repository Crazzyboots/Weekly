local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "crests",
    label = "Crests",
    order = 110,
    events = {
        "CURRENCY_DISPLAY_UPDATE",
        "QUEST_TURNED_IN",
    },
}

function mod:Collect(charData)
    if not charData.crests then
        charData.crests = {}
    end

    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end

    for _, crest in ipairs(C.Crests) do
        local info = C_CurrencyInfo.GetCurrencyInfo(crest.currencyID)
        if info then
            charData.crests[crest.key] = {
                quantity = info.quantity or 0,
                totalEarned = info.useTotalEarnedForMaxQty and info.totalEarned or nil,
                maxQuantity = info.maxQuantity or 0,
                earnedThisWeek = info.quantityEarnedThisWeek or 0,
                weeklyMax = info.maxWeeklyQuantity or 0,
            }
        end
    end

    -- Bonus crest sources (one-time per character)
    if C.CrestBonuses then
        if not charData.crests.bonuses then
            charData.crests.bonuses = {}
        end
        for _, bonus in ipairs(C.CrestBonuses) do
            if bonus.trackBy == "quest" and bonus.id > 0 then
                if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
                    charData.crests.bonuses[bonus.key] = C_QuestLog.IsQuestFlaggedCompleted(bonus.id)
                end
            elseif bonus.trackBy == "achieve" and bonus.id > 0 then
                if GetAchievementInfo then
                    local wasEarnedByMe = select(13, GetAchievementInfo(bonus.id))
                    charData.crests.bonuses[bonus.key] = wasEarnedByMe or false
                end
            end
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

    for i, crest in ipairs(C.Crests) do
        rows[#rows + 1] = {
            section = self.key,
            label = "  " .. crest.label,
            order = self.order + i,
            getValue = function(charData)
                local d = charData.crests and charData.crests[crest.key]
                if not d then return U.ColorText("0", C.Colors.NOT_STARTED) end
                local qty = d.quantity or 0
                local weeklyMax = d.weeklyMax or 0
                local earnedThisWeek = d.earnedThisWeek or 0
                local totalEarned = d.totalEarned
                local cap = d.maxQuantity or 0

                local color
                -- Season-capped (totalEarned currencies)
                if totalEarned and cap > 0 and totalEarned >= cap then
                    color = C.Colors.COMPLETE
                -- Weekly-capped and hit the weekly cap
                elseif weeklyMax > 0 and earnedThisWeek >= weeklyMax then
                    color = C.Colors.COMPLETE
                elseif earnedThisWeek > 0 or qty > 0 then
                    color = C.Colors.IN_PROGRESS
                else
                    color = C.Colors.NOT_STARTED
                end
                return U.ColorText(tostring(qty), color)
            end,
            getTooltip = function(charData)
                local d = charData.crests and charData.crests[crest.key]
                if not d then return crest.label .. " Dawncrests" end
                local weeklyMax = d.weeklyMax or 0
                local earnedThisWeek = d.earnedThisWeek or 0
                local totalEarned = d.totalEarned
                local cap = d.maxQuantity or 0

                local lines = {
                    crest.label .. " Dawncrests",
                    "Held: " .. (d.quantity or 0),
                }
                if weeklyMax > 0 then
                    lines[#lines + 1] = "Weekly: " .. earnedThisWeek .. "/" .. weeklyMax
                elseif earnedThisWeek > 0 then
                    lines[#lines + 1] = "This week: " .. earnedThisWeek
                end
                if totalEarned and cap > 0 then
                    lines[#lines + 1] = "Season: " .. totalEarned .. "/" .. cap
                end
                return table.concat(lines, "\n")
            end,
        }
    end

    -- Bonus crest source rows
    if C.CrestBonuses then
        local bonusStart = self.order + #C.Crests + 1
        for i, bonus in ipairs(C.CrestBonuses) do
            rows[#rows + 1] = {
                section = self.key,
                label = "  " .. bonus.label,
                order = bonusStart + i,
                getValue = function(charData)
                    local bonuses = charData.crests and charData.crests.bonuses
                    local done = bonuses and bonuses[bonus.key]
                    return U.FormatCheckmark(done)
                end,
                getTooltip = function(charData)
                    return bonus.tooltip or bonus.label
                end,
            }
        end
    end

    return rows
end

function mod:OnReset(charData)
    -- Crests persist across resets — re-collect updates quantities.
    -- Clear stale weekly baseline if it exists from prior approach.
    if charData.crests then
        charData.crests.weeklyBaseline = nil
    end
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
