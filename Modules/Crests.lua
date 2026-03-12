local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "crests",
    label = "Crests",
    order = 75,
    events = {
        "CURRENCY_DISPLAY_UPDATE",
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
                totalEarned = info.totalEarned or 0,
                maxQuantity = info.maxQuantity or 0,
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

    for i, crest in ipairs(C.Crests) do
        rows[#rows + 1] = {
            section = self.key,
            label = "  " .. crest.label,
            order = self.order + i,
            getValue = function(charData)
                local d = charData.crests and charData.crests[crest.key]
                if not d then return U.ColorText("0", C.Colors.NOT_STARTED) end
                local qty = d.quantity or 0
                local color
                if qty >= 90 then
                    color = C.Colors.COMPLETE
                elseif qty > 0 then
                    color = C.Colors.IN_PROGRESS
                else
                    color = C.Colors.NOT_STARTED
                end
                return U.ColorText(tostring(qty), color)
            end,
            getTooltip = function(charData)
                local d = charData.crests and charData.crests[crest.key]
                if not d then return crest.label .. " Dawncrests" end
                local cap = d.maxQuantity or 0
                local lines = {
                    crest.label .. " Dawncrests",
                    "Current: " .. (d.quantity or 0),
                    "Season: " .. (d.totalEarned or 0) .. (cap > 0 and ("/" .. cap) or ""),
                }
                return table.concat(lines, "\n")
            end,
        }
    end

    return rows
end

function mod:OnReset(charData)
    -- Crests persist across resets (they're a currency, not weekly progress)
    -- but we re-collect to update quantities
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
