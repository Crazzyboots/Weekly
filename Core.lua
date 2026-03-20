local addonName, Weekly = ...

---------------------------------------------------------------------------
-- Global addon table
---------------------------------------------------------------------------
_G["Weekly"] = Weekly

Weekly.modules = {}
Weekly.debug = false

local DB = Weekly.Database
local U = Weekly.Utils
local C = Weekly.Constants

---------------------------------------------------------------------------
-- Module registry
---------------------------------------------------------------------------
function Weekly.RegisterModule(mod)
    if not mod or not mod.key then
        U.Debug("Attempted to register invalid module")
        return
    end

    -- Insert sorted by order
    local inserted = false
    for i, existing in ipairs(Weekly.modules) do
        if (mod.order or 99) < (existing.order or 99) then
            table.insert(Weekly.modules, i, mod)
            inserted = true
            break
        end
    end
    if not inserted then
        table.insert(Weekly.modules, mod)
    end

    U.Debug("Registered module: " .. mod.key)
end

---------------------------------------------------------------------------
-- Apply custom module order from settings
---------------------------------------------------------------------------
function Weekly.ApplyModuleOrder()
    local settings = DB.GetSettings()
    if not settings then return end

    -- Initialize moduleOrder if empty
    if not settings.moduleOrder or #settings.moduleOrder == 0 then
        settings.moduleOrder = {}
        for _, mod in ipairs(Weekly.modules) do
            if mod.key ~= "characterInfo" then
                settings.moduleOrder[#settings.moduleOrder + 1] = mod.key
            end
        end
    end

    -- Build a lookup: key -> position in custom order
    local orderLookup = {}
    for i, key in ipairs(settings.moduleOrder) do
        orderLookup[key] = i
    end

    -- Add any new modules not yet in the order list (e.g. newly added modules)
    for _, mod in ipairs(Weekly.modules) do
        if mod.key ~= "characterInfo" and not orderLookup[mod.key] then
            settings.moduleOrder[#settings.moduleOrder + 1] = mod.key
            orderLookup[mod.key] = #settings.moduleOrder
        end
    end

    -- Reassign order values: characterInfo stays at 10, others get 20, 30, 40...
    for _, mod in ipairs(Weekly.modules) do
        if mod.key == "characterInfo" then
            mod.order = 10
        elseif orderLookup[mod.key] then
            mod.order = 20 + (orderLookup[mod.key] - 1) * 10
        end
    end

    -- Re-sort the modules array
    table.sort(Weekly.modules, function(a, b)
        return (a.order or 99) < (b.order or 99)
    end)
end

---------------------------------------------------------------------------
-- Collect data for current character
---------------------------------------------------------------------------
function Weekly.CollectAll()
    local charKey = U.GetCharacterKey()
    if not charKey then return end

    local charData = DB.EnsureCharacter(charKey)
    if not charData then return end

    -- Reset this character's weekly data if they haven't been seen since last reset
    DB.ResetCharacterIfNeeded(charKey, charData)

    for _, mod in ipairs(Weekly.modules) do
        if mod.Collect and not DB.IsModuleDisabled(mod.key) then
            local ok, err = pcall(mod.Collect, mod, charData)
            if not ok then
                U.Debug("Error collecting " .. mod.key .. ": " .. tostring(err))
            end
        end
    end

    charData.lastSeen = U.GetServerTime()
end

---------------------------------------------------------------------------
-- Get all row definitions for the grid
---------------------------------------------------------------------------
function Weekly.GetAllRows()
    local rows = {}
    for _, mod in ipairs(Weekly.modules) do
        if mod.GetRows and not DB.IsModuleDisabled(mod.key) then
            local ok, modRows = pcall(mod.GetRows, mod)
            if ok and modRows then
                for _, row in ipairs(modRows) do
                    rows[#rows + 1] = row
                end
            else
                U.Debug("Error getting rows from " .. mod.key .. ": " .. tostring(modRows))
            end
        end
    end
    return rows
end

---------------------------------------------------------------------------
-- Event handling
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local registeredEvents = {}
local collectTimer = nil

local function ThrottledCollect()
    if collectTimer then return end
    collectTimer = C_Timer.After(1, function()
        collectTimer = nil
        Weekly.CollectAll()
        -- Only refresh the grid if the window is visible
        if Weekly.mainWindow and Weekly.mainWindow:IsShown() then
            local SP = Weekly.SettingsPanel
            if not (SP and SP.IsShown and SP.IsShown()) then
                Weekly.RefreshGrid()
            end
        end
    end)
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            DB.Init()
            U.Print("v" .. C.ADDON_VERSION .. " loaded. Type /weekly to open.")
        end

    elseif event == "PLAYER_LOGIN" then
        DB.DetectRegion()
        DB.CheckWeeklyReset()
        DB.ResetAllCharactersIfNeeded()
        Weekly.ApplyModuleOrder()

        Weekly.CollectAll()

        -- Schedule a timer to check for reset while logged in
        -- Check every 60 seconds (handles reset while playing)
        C_Timer.NewTicker(60, function()
            if DB.CheckWeeklyReset() then
                DB.ResetAllCharactersIfNeeded()
                Weekly.CollectAll()
                if Weekly.mainWindow and Weekly.mainWindow:IsShown() then
                    Weekly.RefreshGrid()
                end
            end
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Request raid info for lockout data
        if RequestRaidInfo then
            RequestRaidInfo()
        end
        C_Timer.After(2, function()
            Weekly.CollectAll()
            if Weekly.mainWindow and Weekly.mainWindow:IsShown() then
                Weekly.RefreshGrid()
            end
        end)

    elseif event == "PLAYER_LOGOUT" then
        -- Do NOT call CollectAll here — WoW APIs return stale/false data
        -- during logout, which overwrites good data with zeros.
        -- SavedVariables are saved automatically by WoW after this event.

    else
        -- Dispatch to modules
        for _, mod in ipairs(Weekly.modules) do
            if mod.OnEvent and mod.events then
                for _, evt in ipairs(mod.events) do
                    if evt == event then
                        local ok, err = pcall(mod.OnEvent, mod, event, ...)
                        if not ok then
                            U.Debug("Module " .. mod.key .. " event error: " .. tostring(err))
                        end
                        break
                    end
                end
            end
        end
        -- Throttled re-collect on module events
        ThrottledCollect()
    end
end

eventFrame:SetScript("OnEvent", OnEvent)

-- Core events
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

---------------------------------------------------------------------------
-- Register module events (called after all modules load)
---------------------------------------------------------------------------
local function RegisterModuleEvents()
    for _, mod in ipairs(Weekly.modules) do
        if mod.events then
            for _, event in ipairs(mod.events) do
                if not registeredEvents[event] then
                    eventFrame:RegisterEvent(event)
                    registeredEvents[event] = true
                end
            end
        end
    end
end

-- Register module events after a short delay (all TOC files load in same frame)
C_Timer.After(0, RegisterModuleEvents)

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------
SLASH_WEEKLY1 = "/weekly"
SlashCmdList["WEEKLY"] = function(msg)
    msg = strtrim(msg or "")

    if msg == "purge" then
        U.Print("Usage: /weekly purge RealmName-CharName")
        return
    end

    local purgeTarget = msg:match("^purge%s+(.+)$")
    if purgeTarget then
        DB.PurgeCharacter(strtrim(purgeTarget))
        return
    end

    if msg == "debug" then
        Weekly.debug = not Weekly.debug
        U.Print("Debug mode: " .. (Weekly.debug and "ON" or "OFF"))
        return
    end

    if msg == "reset" then
        DB.PerformReset()
        DB.CheckWeeklyReset()
        Weekly.CollectAll()
        U.Print("Manual reset performed.")
        if Weekly.mainWindow and Weekly.mainWindow:IsShown() then
            Weekly.RefreshGrid()
        end
        return
    end

    -- Default: toggle window
    Weekly.ToggleWindow()
end

---------------------------------------------------------------------------
-- Toggle window (wired up by MainWindow.lua)
---------------------------------------------------------------------------
function Weekly.ToggleWindow()
    if Weekly.mainWindow then
        if Weekly.mainWindow:IsShown() then
            Weekly.mainWindow:Hide()
        else
            -- Request fresh raid lockout info before collecting
            if RequestRaidInfo then RequestRaidInfo() end
            DB.ResetAllCharactersIfNeeded()
            Weekly.CollectAll()
            Weekly.RefreshGrid()
            Weekly.mainWindow:Show()
        end
    else
        U.Print("UI not yet initialized.")
    end
end
