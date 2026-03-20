local _, Weekly = ...

local U = Weekly.Utils
local C = Weekly.Constants

local mod = {
    key = "raids",
    label = "Raids",
    order = 30,
    events = {
        "ENCOUNTER_END",
        "BOSS_KILL",
    },
}

function mod:Collect(charData)
    if not charData.raids then
        charData.raids = {}
    end

    -- Request latest data
    if RequestRaidInfo then
        RequestRaidInfo()
    end

    local numInstances = GetNumSavedInstances and GetNumSavedInstances() or 0

    -- Build a lookup of current lockouts
    local lockouts = {}
    for i = 1, numInstances do
        local instanceName, instanceID, instanceReset, instanceDifficulty,
              locked, extended, instanceIDMostSig, isRaid, maxPlayers,
              difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(i)

        if instanceName and isRaid and locked then
            if not lockouts[instanceName] then
                lockouts[instanceName] = {}
            end

            local diffKey = nil
            for _, diff in ipairs(C.RaidDifficulties) do
                if diff.diffID == instanceDifficulty then
                    diffKey = diff.key
                    break
                end
            end

            if diffKey and numEncounters and numEncounters > 0 then
                local bosses = {}
                for j = 1, numEncounters do
                    local bossName, fileDataID, isKilled = GetSavedInstanceEncounterInfo(i, j)
                    bosses[j] = isKilled or false
                end
                lockouts[instanceName][diffKey] = {
                    bosses = bosses,
                    killed = encounterProgress or 0,
                    total = numEncounters or 0,
                }
            end
        end
    end

    -- Map lockouts to our known raids
    for _, raid in ipairs(C.Raids) do
        charData.raids[raid.key] = charData.raids[raid.key] or {}
        local raidData = charData.raids[raid.key]

        -- Try to match by instance name
        local matchedLockout = lockouts[raid.label]

        for _, diff in ipairs(C.RaidDifficulties) do
            if matchedLockout and matchedLockout[diff.key] then
                raidData[diff.key] = matchedLockout[diff.key]
            else
                -- Preserve existing data (might be from another login)
                raidData[diff.key] = raidData[diff.key] or nil
            end
        end
    end

    -- Vault data now handled by GreatVault module
end

function mod:GetRows()
    local rows = {}

    rows[#rows + 1] = {
        section = self.key,
        label = self.label,
        isHeader = true,
        order = self.order,
    }

    for _, raid in ipairs(C.Raids) do
        if raid.bosses > 0 then
            rows[#rows + 1] = {
                section = self.key,
                label = "  " .. raid.label,
                order = self.order + 1,
                getValue = function(charData)
                    local raidData = U.SafeGet(charData, "raids", raid.key)
                    if not raidData then return U.FormatNA() end

                    -- Find the highest difficulty with progress
                    local bestDiff, bestKilled, bestTotal = nil, 0, raid.bosses
                    for i = #C.RaidDifficulties, 1, -1 do
                        local diff = C.RaidDifficulties[i]
                        local dData = raidData[diff.key]
                        if dData and dData.killed and dData.killed > 0 then
                            bestDiff = diff
                            bestKilled = dData.killed
                            bestTotal = dData.total
                            break
                        end
                    end

                    if not bestDiff then
                        return U.FormatProgress(0, raid.bosses)
                    end

                    local label = string.sub(bestDiff.label, 1, 1) -- N, H, M, L
                    return U.FormatProgress(bestKilled, bestTotal) .. " " .. label
                end,
                getTooltip = function(charData)
                    local raidData = U.SafeGet(charData, "raids", raid.key)
                    if not raidData then return raid.label .. ": No data" end

                    local lines = { raid.label }
                    for _, diff in ipairs(C.RaidDifficulties) do
                        local dData = raidData[diff.key]
                        if dData and dData.total and dData.total > 0 then
                            local bossLine = diff.label .. ": " ..
                                U.FormatProgress(dData.killed or 0, dData.total)
                            lines[#lines + 1] = "  " .. bossLine

                            -- Individual boss details
                            if dData.bosses then
                                for bi, killed in ipairs(dData.bosses) do
                                    local marker = killed and
                                        U.ColorText("\226\156\148", C.Colors.COMPLETE) or
                                        U.ColorText("\226\156\150", C.Colors.NOT_STARTED)
                                    lines[#lines + 1] = "    Boss " .. bi .. ": " .. marker
                                end
                            end
                        end
                    end
                    return table.concat(lines, "\n")
                end,
            }
        else
            -- Raid not yet released
            rows[#rows + 1] = {
                section = self.key,
                label = "  " .. raid.label,
                order = self.order + 1,
                getValue = function() return U.FormatNA() end,
                getTooltip = function() return raid.label .. ": Not yet released" end,
            }
        end
    end

    return rows
end

function mod:OnReset(charData)
    charData.raids = {}
end

function mod:OnEvent(event, ...)
    -- Handled by Core throttle
end

Weekly.RegisterModule(mod)
