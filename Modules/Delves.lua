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

    -- Delver's Bounty: three-state detection
    -- "none"     = no map this week
    -- "obtained" = map looted but not yet used (item in bags or buff active)
    -- "used"     = map consumed and hidden trove opened
    if C.Delves.delversBountyQuestID and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        local questDone = C_QuestLog.IsQuestFlaggedCompleted(C.Delves.delversBountyQuestID)
        if not questDone then
            d.delversBountyState = "none"
        else
            -- Check if map is still in bags
            local hasMap = false
            if C.Delves.delversBountyItemIDs and GetItemCount then
                for _, itemID in ipairs(C.Delves.delversBountyItemIDs) do
                    if (GetItemCount(itemID) or 0) > 0 then
                        hasMap = true
                        break
                    end
                end
            end
            -- Check if bounty buff is active (map used, trove not yet opened)
            local hasBuff = false
            if C.Delves.delversBountyBuffID and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
                hasBuff = C_UnitAuras.GetPlayerAuraBySpellID(C.Delves.delversBountyBuffID) ~= nil
            end
            if hasMap or hasBuff then
                d.delversBountyState = "obtained"
            else
                d.delversBountyState = "used"
            end
        end
    end

    -- Gilded Stash (weekly count from UI widget — only available in certain zones)
    -- We cache the value so it persists when the player leaves the zone.
    if C.Delves.gildedStashWidgetID and C_UIWidgetManager and C_UIWidgetManager.GetSpellDisplayVisualizationInfo then
        local info = C_UIWidgetManager.GetSpellDisplayVisualizationInfo(C.Delves.gildedStashWidgetID)
        if info and info.spellInfo and info.spellInfo.tooltip then
            local current, max = info.spellInfo.tooltip:match("(%d+)%s*/%s*(%d+)")
            if current then
                d.gildedStashLooted = tonumber(current)
                d.gildedStashMax = tonumber(max) or C.Delves.gildedStashMax
            end
        end
        -- If widget returned nil, keep the previously stored value (don't overwrite)
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

    -- Row 2: Delver's Bounty (three states: none / obtained / used)
    rows[#rows + 1] = {
        section = self.key,
        label = "  Bounty",
        order = self.order + 2,
        getValue = function(charData)
            local d = charData.delves
            if not d then return U.ColorText("\226\156\151", C.Colors.NOT_STARTED) end
            local state = d.delversBountyState
            -- Backwards compat: handle old boolean field
            if state == nil and d.delversBountyObtained ~= nil then
                state = d.delversBountyObtained and "obtained" or "none"
            end
            if state == "used" then
                return U.ColorText("\226\156\148", C.Colors.COMPLETE)       -- green ✔
            elseif state == "obtained" then
                return U.ColorText("\226\156\151", C.Colors.IN_PROGRESS)    -- yellow ✗ (has map, not used)
            else
                return U.ColorText("\226\156\151", C.Colors.NOT_STARTED)    -- grey ✗
            end
        end,
        getTooltip = function(charData)
            local d = charData.delves
            local state = d and d.delversBountyState
            if state == nil and d and d.delversBountyObtained ~= nil then
                state = d.delversBountyObtained and "obtained" or "none"
            end
            local lines = { "Delver's Bounty" }
            if state == "used" then
                lines[#lines + 1] = "|cff00ff00Hidden Trove opened this week|r"
            elseif state == "obtained" then
                lines[#lines + 1] = "|cffffff00Map in bags — use in a delve!|r"
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

    -- Row 4: Gilded Stash (weekly, from T11 bountiful delves)
    rows[#rows + 1] = {
        section = self.key,
        label = "  Gilded Stash",
        order = self.order + 4,
        getValue = function(charData)
            local d = charData.delves
            if not d or not d.gildedStashLooted then return U.FormatProgress(0, C.Delves.gildedStashMax) end
            local looted = d.gildedStashLooted or 0
            local max = d.gildedStashMax or C.Delves.gildedStashMax
            return U.FormatProgress(looted, max)
        end,
        getTooltip = function(charData)
            local d = charData.delves
            local looted = d and d.gildedStashLooted or 0
            local max = d and d.gildedStashMax or C.Delves.gildedStashMax
            local lines = { "Gilded Stash" }
            lines[#lines + 1] = "Looted: " .. looted .. "/" .. max
            lines[#lines + 1] = ""
            lines[#lines + 1] = "Appears in Tier 11 Bountiful Delves."
            lines[#lines + 1] = "Resets weekly."
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
        delversBountyState = "none",
        gildedStashLooted = 0,
        gildedStashMax = C.Delves.gildedStashMax,
    }
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
