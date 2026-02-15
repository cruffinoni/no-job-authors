# No Job Authors
If a pawn is machining/fabricating and gives up halfway through to go perform some other task, you are left with an "Unfinished Thing" that is linked to that author. This mod seeks to remove that link, allowing any pawn to finish the job that was started by another.

It should be compatible with any mod that generates unfinished things (eg. Core Drill, etc).

https://ludeon.com/forums/index.php?topic=47836.0

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

