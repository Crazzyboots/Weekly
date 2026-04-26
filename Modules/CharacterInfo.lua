local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "characterInfo",
    label = "Character",
    order = 10,
    events = {},  -- ilvl is collected on window open, not on every gear swap
}

function mod:Collect(charData)
    local name = UnitName("player")
    local realm = GetRealmName()
    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")
    local faction = UnitFactionGroup("player")

    charData.name = name or charData.name
    charData.realm = realm or charData.realm
    charData.class = classFile or charData.class
    charData.level = level or charData.level
    charData.faction = faction or charData.faction

    if GetAverageItemLevel then
        local avg, avgEquipped = GetAverageItemLevel()
        charData.avgItemLevel = avg or charData.avgItemLevel
        charData.avgItemLevelEquipped = avgEquipped or charData.avgItemLevelEquipped
    end
end

function mod:GetRows()
    local rows = {}

    -- Great Vault claimed status — top-level row above all sections
    rows[#rows + 1] = {
        section = self.key,
        label = "Great Vault",
        order = self.order + 1,
        getValue = function(charData)
            local gv = charData.greatVault
            if not gv then return U.FormatCheckmark(false) end

            local hasRewards = gv.hasAvailableRewards or gv.canClaim
            if hasRewards then
                return U.ColorText("Open!", C.Colors.IN_PROGRESS)
            end

            -- Check if any slots were earned
            local anyEarned = false
            for _, slots in pairs({ gv.mythicPlus, gv.raid, gv.world }) do
                if slots then
                    for _, slot in ipairs(slots) do
                        if slot.earned then anyEarned = true break end
                    end
                end
                if anyEarned then break end
            end

            if anyEarned then
                return U.FormatCheckmark(true)
            end
            return U.FormatCheckmark(false)
        end,
        getTooltip = function(charData)
            local gv = charData.greatVault
            if not gv then return "Great Vault\nNo data" end
            local hasRewards = gv.hasAvailableRewards or gv.canClaim
            if hasRewards then
                return "Great Vault\n" .. U.ColorText("Rewards waiting — visit the vault!", C.Colors.IN_PROGRESS)
            end
            return "Great Vault\nReward claimed or no slots earned"
        end,
    }

    -- Voidcore weekly quest (any of Gold / Voidlight Marl / Veteran Dawncrest).
    -- Data is collected by the GreatVault module — we only render here.
    rows[#rows + 1] = {
        section = self.key,
        label = "Voidcore Quest",
        order = self.order + 2,
        getValue = function(charData)
            local d = charData.voidcore
            return U.FormatCheckmark(d and d.weeklyCompleted)
        end,
        getTooltip = function(charData)
            local d = charData.voidcore
            local lines = {
                "Nebulous Voidcores (weekly)",
                "Choose ONE Decimus quest in Howling Ridge:",
                "  Gold (5,000g)",
                "  Voidlight Marl (2,000)",
                "  Veteran Dawncrest (80)",
                "Reward: 2 Nebulous Voidcores",
            }
            if d then
                lines[#lines + 1] = " "
                lines[#lines + 1] = "Status: " .. ((d.weeklyCompleted and "Completed") or "Not completed")
                if d.maxQuantity and d.maxQuantity > 0 then
                    lines[#lines + 1] = "Season: " .. (d.totalEarned or 0) .. "/" .. d.maxQuantity
                end
            end
            return table.concat(lines, "\n")
        end,
    }

    -- Voidcore held count
    rows[#rows + 1] = {
        section = self.key,
        label = "Held",
        order = self.order + 3,
        getValue = function(charData)
            local d = charData.voidcore
            local qty = (d and d.quantity) or 0
            local color
            if qty <= 0 then
                color = C.Colors.NOT_STARTED
            elseif d and d.weeklyCompleted then
                color = C.Colors.COMPLETE
            else
                color = C.Colors.IN_PROGRESS
            end
            return U.ColorText(tostring(qty), color)
        end,
        getTooltip = function(charData)
            local d = charData.voidcore
            if not d then return "Nebulous Voidcore\nHeld: 0" end
            local lines = {
                "Nebulous Voidcore",
                "Held: " .. (d.quantity or 0),
            }
            if d.maxQuantity and d.maxQuantity > 0 then
                lines[#lines + 1] = "Season: " .. (d.totalEarned or 0) .. "/" .. d.maxQuantity
            end
            lines[#lines + 1] = " "
            lines[#lines + 1] = "Spent on Voidforge bonus rolls:"
            lines[#lines + 1] = "  1 = M+ / Bountiful Delve / Nightmare Prey"
            lines[#lines + 1] = "  2 = Raid boss"
            return table.concat(lines, "\n")
        end,
    }

    return rows
end

function mod:OnReset(charData)
    -- Character info is persistent, nothing to reset
end

function mod:OnEvent(event, ...)
    -- Re-collect on gear changes
end

Weekly.RegisterModule(mod)
