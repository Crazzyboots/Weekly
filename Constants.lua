local _, Weekly = ...

Weekly.Constants = {}
local C = Weekly.Constants

---------------------------------------------------------------------------
-- Version & Schema
---------------------------------------------------------------------------
C.ADDON_VERSION = "1.0.0"
C.SCHEMA_VERSION = 3

---------------------------------------------------------------------------
-- Colors
---------------------------------------------------------------------------
C.Colors = {
    COMPLETE    = { r = 0.0, g = 1.0, b = 0.0 },
    IN_PROGRESS = { r = 1.0, g = 0.8, b = 0.0 },
    NOT_STARTED = { r = 0.5, g = 0.5, b = 0.5 },
    UNAVAILABLE = { r = 0.35, g = 0.35, b = 0.35 },
    HEADER_BG   = { r = 0.12, g = 0.06, b = 0.06, a = 1.0 },
    ROW_BG_1    = { r = 0.06, g = 0.06, b = 0.08, a = 1.0 },
    ROW_BG_2    = { r = 0.10, g = 0.10, b = 0.12, a = 1.0 },
    ACCENT      = { r = 0.75, g = 0.15, b = 0.15, a = 1.0 },
    TITLE       = { r = 1.0, g = 1.0, b = 1.0 },
    WHITE       = { r = 1.0, g = 1.0, b = 1.0 },
}

---------------------------------------------------------------------------
-- Class Colors (fallback if RAID_CLASS_COLORS unavailable at load time)
---------------------------------------------------------------------------
C.ClassColors = {
    WARRIOR     = { r = 0.78, g = 0.61, b = 0.43 },
    PALADIN     = { r = 0.96, g = 0.55, b = 0.73 },
    HUNTER      = { r = 0.67, g = 0.83, b = 0.45 },
    ROGUE       = { r = 1.00, g = 0.96, b = 0.41 },
    PRIEST      = { r = 1.00, g = 1.00, b = 1.00 },
    DEATHKNIGHT = { r = 0.77, g = 0.12, b = 0.23 },
    SHAMAN      = { r = 0.00, g = 0.44, b = 0.87 },
    MAGE        = { r = 0.25, g = 0.78, b = 0.92 },
    WARLOCK     = { r = 0.53, g = 0.53, b = 0.93 },
    MONK        = { r = 0.00, g = 1.00, b = 0.60 },
    DRUID       = { r = 1.00, g = 0.49, b = 0.04 },
    DEMONHUNTER = { r = 0.64, g = 0.19, b = 0.79 },
    EVOKER      = { r = 0.20, g = 0.58, b = 0.50 },
}

---------------------------------------------------------------------------
-- Weekly Reset (hours in UTC)
---------------------------------------------------------------------------
C.ResetSchedule = {
    [1] = { day = 3, hour = 15, min = 0 },  -- US: Tuesday 15:00 UTC (day 3 = Tue, Lua wday)
    [2] = { day = 4, hour = 4,  min = 0 },  -- KR: Wednesday 04:00 UTC
    [3] = { day = 4, hour = 4,  min = 0 },  -- EU: Wednesday 04:00 UTC
    [4] = { day = 4, hour = 4,  min = 0 },  -- TW: Wednesday 04:00 UTC
}

---------------------------------------------------------------------------
-- Quest IDs — Weekly Quests
---------------------------------------------------------------------------
-- Each zone event has an activity quest and a meta weekly (awards Spark of Radiance).
-- We use the "any" pattern: check all IDs, any true = completed this week.
-- Meta quests: 93889 (Soiree), 93890 (Abundance), 93891 (Haranir), 93892 (Stormarion)
C.WeeklyQuests = {
    {
        key = "soiree",
        label = "Soiree",
        questIDs = { 89289 },  -- "Favor of the Court" weekly turn-in
    },
    {
        key = "fortify",
        label = "Fortify",
        questIDs = { 90573, 90574, 90575, 90576 },  -- "Fortify the Runestones" (4 faction variants)
    },
    {
        key = "abundance",
        label = "Abundance",
        questIDs = { 89507 },  -- "Abundant Offerings" activity quest
    },
    {
        key = "legendsOfHaranir",
        label = "Legends of Haranir",
        questIDs = { 89268 },  -- "Lost Legends" activity quest
    },
    {
        key = "stormarion",
        label = "Stormarion",
        questIDs = { 90962 },  -- Stormarion Assault activity quest
    },
    {
        key = "standYourGround",
        label = "Stand Your Ground",
        questIDs = { 94581 },  -- Stormarion defense quest
    },
}

---------------------------------------------------------------------------
-- Special Assignments
-- Each zone has 2 rotating assignments. Per week: 1 weekly (7-day) +
-- 2 biweekly (3.5-day) = 3 total. We check all quest IDs and any
-- flagged as completed counts as done this reset cycle.
---------------------------------------------------------------------------
C.SpecialAssignments = {
    {
        key = "eversong",
        label = "Eversong",
        questIDs = { 92848 },  -- The Grand Magister's Drink
    },
    {
        key = "zulaman",
        label = "Zul'Aman",
        questIDs = { 94866, 94865 },  -- Ours Once More! / What Remains of a Temple Broken
    },
    {
        key = "harandar",
        label = "Harandar",
        questIDs = { 94390, 94391 },  -- A Hunter's Regret / Push Back the Light
    },
    {
        key = "voidstorm",
        label = "Voidstorm",
        questIDs = { 94795, 94743 },  -- Agents of the Shield / Precision Excision
    },
}

---------------------------------------------------------------------------
-- Prey Hunt
-- 30 unique targets × 3 difficulties = 90 quest IDs total.
-- Each week rotates which targets are available, but the quest IDs are
-- stable per target. We check all IDs via IsQuestFlaggedCompleted —
-- any that return true were completed this reset cycle.
---------------------------------------------------------------------------
C.PreyCurrencyID = 3387  -- Preyseeker's Journey progress currency

C.PreyQuestIDs = {
    normal = {
        91095, -- Magister Sunbreaker
        91096, -- Magistrix Emberlash
        91097, -- Senior Tinker Ozwold
        91098, -- L-N-0R the Recycler
        91099, -- Mordril Shadowfell
        91100, -- Deliah Gloomsong
        91101, -- Phaseblade Talasha
        91102, -- Nexus-Edge Hadim
        91103, -- Jo'zolo the Breaker
        91104, -- Zadu, Fist of Nalorakk
        91105, -- The Talon of Jan'alai
        91106, -- The Wing of Akil'zon
        91107, -- Ranger Swiftglade
        91108, -- Lieutenant Blazewing
        91109, -- Petyoll the Razorleaf
        91110, -- Lamyne of the Undercroft
        91111, -- High Vindicator Vureem
        91112, -- Crusader Luxia Maxwell
        91113, -- Praetor Singularis
        91114, -- Consul Nebulor
        91115, -- Executor Kaenius
        91116, -- Imperator Enigmalia
        91117, -- Knight-Errant Bloodshatter
        91118, -- Vylenna the Defector
        91119, -- Lost Theldrin
        91120, -- Neydra the Starving
        91121, -- Thornspeaker Edgath
        91122, -- Thorn-Witch Liset
        91123, -- Grothoz, the Burning Shadow
        91124, -- Dengzag, the Darkened Blaze
    },
    hard = {
        91210, -- Magister Sunbreaker
        91212, -- Magistrix Emberlash
        91214, -- Senior Tinker Ozwold
        91216, -- L-N-0R the Recycler
        91218, -- Mordril Shadowfell
        91220, -- Deliah Gloomsong
        91222, -- Phaseblade Talasha
        91224, -- Nexus-Edge Hadim
        91226, -- Jo'zolo the Breaker
        91228, -- Zadu, Fist of Nalorakk
        91230, -- The Talon of Jan'alai
        91232, -- The Wing of Akil'zon
        91234, -- Ranger Swiftglade
        91236, -- Lieutenant Blazewing
        91238, -- Petyoll the Razorleaf
        91240, -- Lamyne of the Undercroft
        91242, -- High Vindicator Vureem
        91243, -- Crusader Luxia Maxwell
        91244, -- Praetor Singularis
        91245, -- Consul Nebulor
        91246, -- Executor Kaenius
        91247, -- Imperator Enigmalia
        91248, -- Knight-Errant Bloodshatter
        91249, -- Vylenna the Defector
        91250, -- Lost Theldrin
        91251, -- Neydra the Starving
        91252, -- Thornspeaker Edgath
        91253, -- Thorn-Witch Liset
        91254, -- Grothoz, the Burning Shadow
        91255, -- Dengzag, the Darkened Blaze
    },
    nightmare = {
        91211, -- Magister Sunbreaker
        91213, -- Magistrix Emberlash
        91215, -- Senior Tinker Ozwold
        91217, -- L-N-0R the Recycler
        91219, -- Mordril Shadowfell
        91221, -- Deliah Gloomsong
        91223, -- Phaseblade Talasha
        91225, -- Nexus-Edge Hadim
        91227, -- Jo'zolo the Breaker
        91229, -- Zadu, Fist of Nalorakk
        91231, -- The Talon of Jan'alai
        91233, -- The Wing of Akil'zon
        91235, -- Ranger Swiftglade
        91237, -- Lieutenant Blazewing
        91239, -- Petyoll the Razorleaf
        91241, -- Lamyne of the Undercroft
        91256, -- High Vindicator Vureem
        91257, -- Crusader Luxia Maxwell
        91258, -- Praetor Singularis
        91259, -- Consul Nebulor
        91260, -- Executor Kaenius
        91261, -- Imperator Enigmalia
        91262, -- Knight-Errant Bloodshatter
        91263, -- Vylenna the Defector
        91264, -- Lost Theldrin
        91265, -- Neydra the Starving
        91266, -- Thornspeaker Edgath
        91267, -- Thorn-Witch Liset
        91268, -- Grothoz, the Burning Shadow
        91269, -- Dengzag, the Darkened Blaze
    },
}

C.PreyDifficulties = {
    { key = "normal",    label = "Normal",    total = 4 },
    { key = "hard",      label = "Hard",      total = 4 },
    { key = "nightmare", label = "Nightmare", total = 4 },
}

---------------------------------------------------------------------------
-- Delves
---------------------------------------------------------------------------
C.Delves = {
    bountifulQuestIDs = { 81514 },  -- "Bountiful Delves" weekly
    cofferKeyCurrencyID = 3028,     -- Restored Coffer Key currency
    cofferKeyShardsCurrencyID = 3310, -- Coffer Key Shards currency
    maxCofferKeys = 4,
}

---------------------------------------------------------------------------
-- Raids  (Midnight / 12.0.0 tier)
---------------------------------------------------------------------------
C.Raids = {
    {
        key = "voidspire",
        label = "The Voidspire",
        bosses = 6,
        instanceID = 0,  -- zone 16340; fill instanceID from GetSavedInstanceInfo once known
    },
    {
        key = "dreamrift",
        label = "The Dreamrift",
        bosses = 1,
        instanceID = 0,  -- zone 16531
    },
    {
        key = "quelDanas",
        label = "March on Quel'Danas",
        bosses = 2,
        instanceID = 0,  -- zone 16342; opens Mar 31
    },
}

C.RaidDifficulties = {
    { key = "lfr",    label = "LFR",    diffID = 17 },
    { key = "normal", label = "Normal",  diffID = 14 },
    { key = "heroic", label = "Heroic",  diffID = 15 },
    { key = "mythic", label = "Mythic",  diffID = 16 },
}

---------------------------------------------------------------------------
-- Great Vault Thresholds
---------------------------------------------------------------------------
C.VaultTypes = {
    MYTHIC_PLUS = 1,  -- Enum.WeeklyRewardChestThresholdType.MythicPlus (if available)
    RAID        = 2,
    WORLD       = 3,
}

---------------------------------------------------------------------------
-- UI Defaults
---------------------------------------------------------------------------
C.UI = {
    WINDOW_WIDTH       = 900,
    WINDOW_HEIGHT      = 600,
    MIN_WINDOW_WIDTH   = 600,
    MIN_WINDOW_HEIGHT  = 400,
    LABEL_COLUMN_WIDTH = 170,
    CHAR_COLUMN_WIDTH  = 95,
    HEADER_HEIGHT      = 44,
    ROW_HEIGHT         = 20,
    SECTION_HEIGHT     = 22,
    TITLE_HEIGHT       = 28,
    SCROLL_STEP        = 40,
}
