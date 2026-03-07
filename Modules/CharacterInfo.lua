local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "characterInfo",
    label = "Character",
    order = 10,
    events = { "PLAYER_EQUIPMENT_CHANGED" },
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
        charData.avgItemLevel = avg and math.floor(avg) or charData.avgItemLevel
        charData.avgItemLevelEquipped = avgEquipped and math.floor(avgEquipped) or charData.avgItemLevelEquipped
    end
end

function mod:GetRows()
    -- Character info is rendered as column headers, not rows
    return {}
end

function mod:OnReset(charData)
    -- Character info is persistent, nothing to reset
end

function mod:OnEvent(event, ...)
    -- Re-collect on gear changes
end

Weekly.RegisterModule(mod)
