# Changelog

## 1.1.0 (2026-03-20)

### New Features
- **Great Vault Module** — Dedicated section tracking all 3 vault categories (Mythic+, Raid, World/Delves) with slot progress and reward levels
- **Delves Tracking** — Coffer Key Shards weekly progress (e.g. 455/600), Delver's Bounty map status, and Restored Coffer Keys on hand
- **Settings: Module Reordering** — Up/down arrows to rearrange sections to your preference
- **Live Settings** — All settings changes apply instantly without needing /reload

### Bug Fixes
- Fixed Great Vault enum types (Raid=3, World=6) — vault data was previously mixing up categories
- Removed incorrect bountiful delve tracking (was using a one-time intro quest ID)
- Consolidated vault tracking into a single authoritative module

### Changes
- Updated default section order for Season 2: M+ → Raids → Delves → Prey → Weeklies → Professions → Abundance → Assignments → Great Vault → Crests
- Removed Vault row from Mythic+ section (now in Great Vault)
- Removed vault data collection from Raids module (now in Great Vault)

### Notes
- Requires a full game restart (not just /reload) on first update due to new files
- Existing settings will be migrated automatically

## 1.0.0 (2026-03-11)

### Initial Release
- Account-wide weekly tracking across all characters
- Modules: Mythic+, Raids, Weeklies, Abundance, Professions, Assignments, Prey, Delves, Crests
- Dark theme with red accents, class-colored character headers
- Collapsible sections, character hide/show, sort options
- Minimap button and /weekly slash command
