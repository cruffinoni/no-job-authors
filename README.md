# No Job Authors
If a pawn is machining/fabricating and gives up halfway through to go perform some other task, you are left with an "Unfinished Thing" that is linked to that author. This mod seeks to remove that link, allowing any pawn to finish the job that was started by another.

It should be compatible with any mod that generates unfinished things (eg. Core Drill, etc).

https://ludeon.com/forums/index.php?topic=47836.0

## Save Compatibility

- Safe to add to existing saves.
- Safe to remove mid-game.
- If you remove the mod mid-save, unfinished work already on the map can still be continued by other eligible pawns even without the mod.
- New unfinished work created after removing the mod will use normal vanilla authorship behavior.

## Attribution

- Original author: Doug
- Forum thread: https://ludeon.com/forums/index.php?topic=47836.0
- Updated and uploaded for RimWorld 1.0 on Steam by sassykoala:
  https://steamcommunity.com/sharedfiles/filedetails/?id=1710932701
- Maintained for RimWorld 1.1+ by Jellypowered (with permission from Doug):
  https://github.com/Jellypowered/no-job-authors/releases/latest

## Dev Scripts

- `scripts/build-mod.sh`: restores and builds `Source/NoJobAuthors.sln` (Debug).
- `scripts/install-mod.sh`: installs/updates this mod into your RimWorld `Mods` folder.
  - Required runtime content copied: `About`, `1.6`, `LoadFolders.xml`.
  - Optional content copied when present: `Languages`, `Textures`, `README.md`, `changelog.txt`, `credits.md`.

Examples:

```bash
bash scripts/build-mod.sh
bash scripts/install-mod.sh --dry-run --verbose
bash scripts/install-mod.sh --build --mods-path "/mnt/c/Program Files (x86)/Steam/steamapps/common/RimWorld/Mods"
```

