local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "abundance",
    label = "Abundance",
    order = 80,
    events = {
        "CURRENCY_DISPLAY_UPDATE",
    },
}

function mod:Collect(charData)
    if not charData.abundance then
        charData.abundance = {}
    end

    if not C_CurrencyInfo or not C_CurrencyInfo.GetCurrencyInfo then return end

    -- Shard of Dundun
    if C.Abundance and C.Abundance.currencyID > 0 then
        local info = C_CurrencyInfo.GetCurrencyInfo(C.Abundance.currencyID)
        if info then
            charData.abundance.dundun = {
                held = info.quantity or 0,
                maxHeld = info.maxQuantity or 8,
                weeklyEarned = info.quantityEarnedThisWeek or 0,
                weeklyCap = info.maxWeeklyQuantity or 8,
            }
        end
    end

    -- Unalloyed Abundance
    if C.Abundance and C.Abundance.abundanceCurrencyID
        and C.Abundance.abundanceCurrencyID > 0 then
        local info = C_CurrencyInfo.GetCurrencyInfo(C.Abundance.abundanceCurrencyID)
        if info then
            charData.abundance.unalloyed = {
                quantity = info.quantity or 0,
                totalEarned = info.totalEarned or 0,
            }
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

    -- Shard of Dundun
    rows[#rows + 1] = {
        section = self.key,
        label = "  Shard of Dundun",
        order = self.order + 1,
        getValue = function(charData)
            local d = U.SafeGet(charData, "abundance", "dundun")
            if not d then return U.ColorText("0/8", C.Colors.NOT_STARTED) end
            local held = d.held or 0
            local max = d.maxHeld or 8
            return U.ColorText(held .. "/" .. max, U.ProgressColor(held, max))
        end,
        getTooltip = function(charData)
            local d = U.SafeGet(charData, "abundance", "dundun")
            if not d then return "Shards of Dundun currently held" end
            return "Shard of Dundun\nHeld: " .. (d.held or 0) .. "/" .. (d.maxHeld or 8)
        end,
    }

    -- Harvested
    rows[#rows + 1] = {
        section = self.key,
        label = "  Harvested",
        order = self.order + 2,
        getValue = function(charData)
            local d = U.SafeGet(charData, "abundance", "dundun")
            if not d then return U.ColorText("0/8", C.Colors.NOT_STARTED) end
            local earned = d.weeklyEarned or 0
            local cap = d.weeklyCap or 8
            return U.ColorText(earned .. "/" .. cap, U.ProgressColor(earned, cap))
        end,
        getTooltip = function(charData)
            local d = U.SafeGet(charData, "abundance", "dundun")
            if not d then return "Abundance harvests this week" end
            return "Abundance Harvests\nThis week: " .. (d.weeklyEarned or 0) .. "/" .. (d.weeklyCap or 8)
        end,
    }

    -- Unalloyed Abundance
    rows[#rows + 1] = {
        section = self.key,
        label = "  Unalloyed",
        order = self.order + 3,
        getValue = function(charData)
            local d = U.SafeGet(charData, "abundance", "unalloyed")
            if not d then return U.ColorText("0", C.Colors.NOT_STARTED) end
            local qty = d.quantity or 0
            local color = qty > 0 and C.Colors.IN_PROGRESS or C.Colors.NOT_STARTED
            return U.ColorText(U.FormatNumber(qty), color)
        end,
        getTooltip = function(charData)
            local d = U.SafeGet(charData, "abundance", "unalloyed")
            if not d then return "Unalloyed Abundance" end
            return "Unalloyed Abundance\nCurrent: " .. U.FormatNumber(d.quantity or 0)
                .. "\nTotal earned: " .. U.FormatNumber(d.totalEarned or 0)
        end,
    }

    return rows
end

function mod:OnReset(charData)
    if not charData.abundance then return end

    -- Reset weekly harvest count, preserve held currencies
    if charData.abundance.dundun then
        charData.abundance.dundun.weeklyEarned = 0
    end
    -- Unalloyed quantity persists (it's a currency, not weekly progress)
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
