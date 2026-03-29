local _, Weekly = ...

Weekly.Constants = {}
local C = Weekly.Constants

---------------------------------------------------------------------------
-- Version & Schema
---------------------------------------------------------------------------
C.ADDON_VERSION = "1.2.1"
C.SCHEMA_VERSION = 6

---------------------------------------------------------------------------
-- Colors
---------------------------------------------------------------------------
C.Colors = {
    COMPLETE    = { r = 0.0, g = 1.0, b = 0.0 },
    IN_PROGRESS = { r = 1.0, g = 0.8, b = 0.0 },
    NOT_STARTED = { r = 0.5, g = 0.5, b = 0.5 },
    UNAVAILABLE = { r = 0.35, g = 0.35, b = 0.35 },
    HEADER_BG   = { r = 0.08, g = 0.05, b = 0.05, a = 1.0 },
    ROW_BG_1    = { r = 0.04, g = 0.04, b = 0.06, a = 1.0 },
    ROW_BG_2    = { r = 0.09, g = 0.09, b = 0.11, a = 1.0 },
    SEPARATOR   = { r = 0.20, g = 0.08, b = 0.08, a = 1.0 },
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
        key = "unityVoid",
        label = "Spark Quest",
        questIDs = { 93744, 93767, 93889, 93909, 93910, 93911, 93766 },
        -- 93744 = Unity Against the Void (choice umbrella)
        -- 93767 = Midnight: Arcantina
        -- 93889 = Midnight: Saltheril's Soiree
        -- 93909 = Midnight: Delves
        -- 93910 = Midnight: Prey
        -- 93911 = Midnight: Dungeons
        -- 93766 = Midnight: World Quests
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

C.NightmarishTask = {
    questID = 94446,    -- Weekly quest: A Nightmarish Task
    total = 3,          -- Required Nightmare Hunts
}

---------------------------------------------------------------------------
-- Abundance (Shard of Dundun)
---------------------------------------------------------------------------
C.Abundance = {
    currencyID = 3376,           -- Shard of Dundun
    abundanceCurrencyID = 3377,  -- Unalloyed Abundance
}

---------------------------------------------------------------------------
-- Dawncrests (upgrade currencies)
---------------------------------------------------------------------------
C.Crests = {
    { key = "adventurer", label = "Adventurer", currencyID = 3383 },
    { key = "veteran",    label = "Veteran",    currencyID = 3341 },
    { key = "champion",   label = "Champion",   currencyID = 3343 },
    { key = "hero",       label = "Hero",       currencyID = 3345 },
    { key = "myth",       label = "Myth",       currencyID = 3348 },
}

---------------------------------------------------------------------------
-- Delves
---------------------------------------------------------------------------
C.Delves = {
    cofferKeyCurrencyID = 3028,     -- Restored Coffer Key currency
    cofferKeyShardsCurrencyID = 3310, -- Coffer Key Shards currency
    bountifulTrackerCurrencyID = 3142, -- Hidden: bountiful completions (28/week cap)
    maxCofferKeys = 4,
    maxWeeklyShards = 600,          -- Weekly cap for Coffer Key Shards
    delversBountyQuestID = 86371,   -- Weekly flag: Delver's Bounty map looted
    delversBountyItemIDs = { 248142, 254256 },  -- S3 Midnight bounty map + epic variant
    delversBountyBuffID = 473218,   -- Aura: map used, trove not yet opened
    gildedStashWidgetID = 7591,     -- UI widget tracking gilded stash looted count (Midnight)
    gildedStashMax = 4,             -- Weekly cap for gilded stash
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
    MYTHIC_PLUS = 1,  -- Enum.WeeklyRewardChestThresholdType.Activities
    RAID        = 3,  -- Enum.WeeklyRewardChestThresholdType.Raid
    WORLD       = 6,  -- Enum.WeeklyRewardChestThresholdType.World (Delves)
}

---------------------------------------------------------------------------
-- Professions — Weekly Knowledge Sources
-- Keyed by skillLineID. Quest IDs sourced from Myu's Knowledge Points Tracker.
---------------------------------------------------------------------------
C.Professions = {
    [2906] = {
        name = "Alchemy",
        abbrev = "Alch",
        treatiseQuestID = 95127,
        weeklyQuestIDs = { 93690 },
        treasureQuestIDs = { 93528, 93529 },
    },
    [2907] = {
        name = "Blacksmithing",
        abbrev = "B.S.",
        treatiseQuestID = 95128,
        weeklyQuestIDs = { 93691 },
        treasureQuestIDs = { 93530, 93531 },
    },
    [2909] = {
        name = "Enchanting",
        abbrev = "Ench",
        treatiseQuestID = 95129,
        weeklyQuestIDs = { 93699, 93698, 93697 },
        treasureQuestIDs = { 93532, 93533 },
    },
    [2910] = {
        name = "Engineering",
        abbrev = "Engr",
        treatiseQuestID = 95138,
        weeklyQuestIDs = { 93692 },
        treasureQuestIDs = { 93534, 93535 },
    },
    [2912] = {
        name = "Herbalism",
        abbrev = "Herb",
        treatiseQuestID = 95130,
        weeklyQuestIDs = { 93700, 93701, 93702, 93703, 93704 },
        treasureQuestIDs = { 81425, 81426, 81427, 81428, 81429, 81430 },
    },
    [2913] = {
        name = "Inscription",
        abbrev = "Insc",
        treatiseQuestID = 95131,
        weeklyQuestIDs = { 93693 },
        treasureQuestIDs = { 93536, 93537 },
    },
    [2914] = {
        name = "Jewelcrafting",
        abbrev = "J.C.",
        treatiseQuestID = 95133,
        weeklyQuestIDs = { 93694 },
        treasureQuestIDs = { 93538, 93539 },
    },
    [2915] = {
        name = "Leatherworking",
        abbrev = "L.W.",
        treatiseQuestID = 95134,
        weeklyQuestIDs = { 93695 },
        treasureQuestIDs = { 93540, 93541 },
    },
    [2916] = {
        name = "Mining",
        abbrev = "Mine",
        treatiseQuestID = 95135,
        weeklyQuestIDs = { 93705, 93706, 93707, 93708, 93709 },
        treasureQuestIDs = { 88673, 88674, 88675, 88676, 88677, 88678 },
    },
    [2917] = {
        name = "Skinning",
        abbrev = "Skin",
        treatiseQuestID = 95136,
        weeklyQuestIDs = { 93710, 93711, 93712, 93713, 93714 },
        treasureQuestIDs = { 88534, 88549, 88536, 88537, 88530, 88529 },
    },
    [2918] = {
        name = "Tailoring",
        abbrev = "Tail",
        treatiseQuestID = 95137,
        weeklyQuestIDs = { 93696 },
        treasureQuestIDs = { 93542, 93543 },
    },
}

-- Base skillLine ID → TWW skillLine ID mapping.
-- GetProfessionInfo() returns the base ID; we need the expansion-specific ID
-- to look up quest data in C.Professions.
C.ProfessionBaseToTWW = {
    [171] = 2906,  -- Alchemy
    [164] = 2907,  -- Blacksmithing
    [333] = 2909,  -- Enchanting
    [202] = 2910,  -- Engineering
    [182] = 2912,  -- Herbalism
    [773] = 2913,  -- Inscription
    [755] = 2914,  -- Jewelcrafting
    [165] = 2915,  -- Leatherworking
    [186] = 2916,  -- Mining
    [393] = 2917,  -- Skinning
    [197] = 2918,  -- Tailoring
}

---------------------------------------------------------------------------
-- Mythic+ Dungeon Abbreviations (for keystone display in narrow columns)
-- Matched by substring against dungeon names returned by the API.
---------------------------------------------------------------------------
C.MythicPlusDungeonAbbrevs = {
    ["Windrunner"]   = "WRS",
    ["Triumvirate"]  = "SEAT",
    ["Saron"]        = "POS",
    ["Skyreach"]     = "SKY",
    ["Xenas"]        = "NPX",
    ["Maisara"]      = "MAIS",
    ["Magisters"]    = "MGT",
    ["Algeth"]       = "AA",
}

---------------------------------------------------------------------------
-- UI Defaults
---------------------------------------------------------------------------
C.UI = {
    WINDOW_WIDTH       = 1035,
    WINDOW_HEIGHT      = 690,
    MIN_WINDOW_WIDTH   = 690,
    MIN_WINDOW_HEIGHT  = 460,
    LABEL_COLUMN_WIDTH = 170,
    CHAR_COLUMN_WIDTH  = 95,
    HEADER_HEIGHT      = 44,
    ROW_HEIGHT         = 20,
    SECTION_HEIGHT     = 22,
    TITLE_HEIGHT       = 40,
    SCROLL_STEP        = 40,
    SCROLLBAR_SIZE     = 10,
    SCROLLBAR_MIN_THUMB = 20,
}
