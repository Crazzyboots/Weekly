# Weekly

A World of Warcraft addon for tracking weekly activities across all your characters in one window.

![Weekly Addon](https://img.shields.io/badge/WoW-Midnight%2012.0-blue) ![Version](https://img.shields.io/badge/version-1.0.0-green)

## Features

- **Multi-character overview** — See all your characters' weekly progress in a single grid
- **Mythic+** — Current rating, best key, and Great Vault progress
- **Raids** — Boss kill tracking across LFR/Normal/Heroic/Mythic for all current raids (The Voidspire, The Dreamrift, March on Quel'Danas)
- **Weekly Quests** — Soiree, Fortify, Abundance, Legends of Haranir, Stormarion, Stand Your Ground
- **Special Assignments** — Eversong, Zul'Aman, Harandar, Voidstorm
- **Prey Hunts** — Normal/Hard/Nightmare kill tracking
- **Delves** — Bountiful Delves and Coffer Key tracking
- **Collapsible sections** — Click section headers to collapse/expand categories
- **Minimap button** — Quick toggle with left-click, or type `/weekly`
- **Character management** — Hide/show characters and reorder columns via Settings
- **Sleek dark UI** with red accents and class-colored character names

## Installation

### Manual Install
1. Download or clone this repository
2. Copy the `Weekly` folder into your WoW addons directory:
   ```
   World of Warcraft\_retail_\Interface\AddOns\Weekly
   ```
3. Restart WoW or type `/reload` if the game is running

### From Addon Manager
If available on WowUp or Wago, search for **Weekly** and install directly.

## Usage

- Type `/weekly` in chat to toggle the window
- Click the minimap button to open/close
- Click section headers (Mythic+, Raids, etc.) to collapse or expand them
- Click the gear icon to open Settings where you can hide characters or adjust column width
- Data updates automatically as you log into each character

## How It Works

Weekly scans your character data on login and stores it in WoW's SavedVariables (`WeeklyDB`). Since SavedVariables are account-wide, data from all characters is available in one place. The addon checks quest completion flags, instance save info, Mythic+ ratings, and currency counts to determine what you've done each week. Everything resets automatically based on your region's weekly reset schedule.

## Slash Commands

| Command | Action |
|---------|--------|
| `/weekly` | Toggle the main window |

## License

Free to use and modify.
