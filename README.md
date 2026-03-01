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

- `scripts/build-mod.sh`: restores and builds `Source/NoJobAuthors.sln` (Release).
- `scripts/install-mod.sh`: installs/updates this mod into your RimWorld `Mods` folder.
- `scripts/build-mod.ps1`: Windows PowerShell build script (restores and builds `Source/NoJobAuthors.sln` in Release).
- `scripts/install-mod.ps1`: Windows PowerShell install/update script for your RimWorld `Mods` folder.
  - Required runtime content copied: `About`, `1.6`, `LoadFolders.xml`.
  - Optional content copied when present: `Languages`, `Textures`, `README.md`, `changelog.txt`, `credits.md`.

## Generate DLL

- `.dll` files are intentionally not committed in this repository.
- Generate `NoJobAuthors.dll` locally with one of these commands:

Linux / WSL / macOS:

```bash
bash scripts/build-mod.sh
```

Windows (PowerShell):

```powershell
pwsh -File scripts/build-mod.ps1
```

Expected output:

- `1.6/Assemblies/NoJobAuthors.dll`

Quick verification:

```bash
ls 1.6/Assemblies/NoJobAuthors.dll
```

Examples:

Linux / WSL:

```bash
bash scripts/build-mod.sh
bash scripts/install-mod.sh --dry-run --verbose
bash scripts/install-mod.sh --build --mods-path "/mnt/c/Program Files (x86)/Steam/steamapps/common/RimWorld/Mods"
```

macOS:

```bash
bash scripts/build-mod.sh
bash scripts/install-mod.sh --mods-path "$HOME/Library/Application Support/RimWorld/Mods"
bash scripts/install-mod.sh --mods-path "$HOME/Library/Application Support/Steam/steamapps/common/RimWorld/RimWorldMac.app/Mods"
```

Windows (PowerShell):

```powershell
pwsh -File scripts/build-mod.ps1
pwsh -File scripts/install-mod.ps1 -DryRun -VerboseOutput
pwsh -File scripts/install-mod.ps1 -Build -ModsPath "C:\Program Files (x86)\Steam\steamapps\common\RimWorld\Mods"
```
