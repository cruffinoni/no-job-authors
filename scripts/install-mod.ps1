param(
    [switch]$Build,
    [string]$ModName = 'NoJobAuthors',
    [string]$RimWorldPath,
    [string]$ModsPath,
    [switch]$DryRun,
    [switch]$VerboseOutput,
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
    @'
Usage:
  scripts/install-mod.ps1 [options]

Options:
  -Build                    Build Source/NoJobAuthors.csproj (Release) before install. Stops on build failure.
  -ModName <name>           Destination folder name under RimWorld Mods (default: NoJobAuthors).
  -RimWorldPath <path>      Explicit RimWorld root path. Uses <path>\Mods.
  -ModsPath <path>          Explicit Mods directory path (highest precedence).
  -DryRun                   Print resolved paths and actions only.
  -VerboseOutput            Print path-detection attempts.
  -Help                     Show this help message.
'@ | Write-Host
}

function Fail {
    param([string]$Message)
    [Console]::Error.WriteLine("Error: $Message")
    exit 1
}

function Resolve-CanonicalDirectory {
    param([Parameter(Mandatory = $true)][string]$PathValue)

    if (-not (Test-Path -LiteralPath $PathValue -PathType Container)) {
        return $null
    }

    try {
        return (Resolve-Path -LiteralPath $PathValue).Path
    } catch {
        return $null
    }
}

function Invoke-Dotnet {
    param(
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    & dotnet @Arguments
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

function Invoke-BuildStep {
    param([Parameter(Mandatory = $true)][string]$RootDir)

    $project = Join-Path $RootDir 'Source/NoJobAuthors.csproj'
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        Fail 'Could not find dotnet in PATH.'
    }

    Write-Host "Build target: $project"
    Write-Host 'Build tool: dotnet'
    Invoke-Dotnet -Arguments @('restore', $project)
    Invoke-Dotnet -Arguments @('build', $project, '-c', 'Release', '--no-restore')
    Write-Host 'Build succeeded.'
}

function Get-SteamLibraryPathsFromVdf {
    param([Parameter(Mandatory = $true)][string]$VdfPath)

    $results = New-Object System.Collections.Generic.List[string]
    if (-not (Test-Path -LiteralPath $VdfPath -PathType Leaf)) {
        return $results.ToArray()
    }

    foreach ($line in Get-Content -LiteralPath $VdfPath -ErrorAction SilentlyContinue) {
        if ($line -match '"path"\s+"([^"]+)"') {
            $raw = $Matches[1] -replace '\\\\', '\'
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $results.Add($raw)
            }
            continue
        }

        if ($line -match '^\s*"\d+"\s+"([^"]+)"') {
            $raw = $Matches[1] -replace '\\\\', '\'
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $results.Add($raw)
            }
        }
    }

    return $results.ToArray()
}

function Get-RimWorldRoot {
    param([switch]$VerboseCheck)

    $candidates = New-Object System.Collections.Generic.List[string]
    $visited = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)

    function Add-Candidate {
        param([string]$PathValue)
        if (-not [string]::IsNullOrWhiteSpace($PathValue) -and $visited.Add($PathValue)) {
            $candidates.Add($PathValue)
        }
    }

    Add-Candidate 'C:\Program Files (x86)\Steam\steamapps\common\RimWorld'
    Add-Candidate 'C:\Program Files\Steam\steamapps\common\RimWorld'

    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        $root = $drive.Root.TrimEnd('\')
        Add-Candidate "$root\Program Files (x86)\Steam\steamapps\common\RimWorld"
        Add-Candidate "$root\Program Files\Steam\steamapps\common\RimWorld"
    }

    $vdfCandidates = New-Object System.Collections.Generic.List[string]
    $vdfCandidates.Add('C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf')
    $vdfCandidates.Add('C:\Program Files\Steam\steamapps\libraryfolders.vdf')
    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        $root = $drive.Root.TrimEnd('\')
        $vdfCandidates.Add("$root\Program Files (x86)\Steam\steamapps\libraryfolders.vdf")
        $vdfCandidates.Add("$root\Program Files\Steam\steamapps\libraryfolders.vdf")
    }

    foreach ($vdfPath in $vdfCandidates) {
        foreach ($libraryPath in Get-SteamLibraryPathsFromVdf -VdfPath $vdfPath) {
            Add-Candidate (Join-Path $libraryPath 'steamapps\common\RimWorld')
        }
    }

    foreach ($candidate in $candidates) {
        if ($VerboseCheck) {
            [Console]::Error.WriteLine("Checking RimWorld path candidate: $candidate")
        }
        $modsPath = Join-Path $candidate 'Mods'
        if (Test-Path -LiteralPath $modsPath -PathType Container) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    foreach ($item in Get-ChildItem -LiteralPath $Source -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $Destination -Recurse -Force
    }
}

function Copy-OptionalDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (Test-Path -LiteralPath $Source -PathType Container) {
        Copy-DirectoryContents -Source $Source -Destination $Destination
    }
}

function Copy-OptionalFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (Test-Path -LiteralPath $Source -PathType Leaf) {
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

if ([string]::IsNullOrWhiteSpace($ModName)) {
    Fail 'ModName cannot be empty.'
}

$rootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$rimworldRoot = $null
$modsCanonical = $null

if ($Build) {
    Invoke-BuildStep -RootDir $rootDir
}

if (-not [string]::IsNullOrWhiteSpace($ModsPath)) {
    $modsCanonical = Resolve-CanonicalDirectory -PathValue $ModsPath
    if (-not $modsCanonical) {
        Fail "Mods directory does not exist: $ModsPath"
    }
} elseif (-not [string]::IsNullOrWhiteSpace($RimWorldPath)) {
    $rimworldRoot = Resolve-CanonicalDirectory -PathValue $RimWorldPath
    if (-not $rimworldRoot) {
        Fail "RimWorld directory does not exist: $RimWorldPath"
    }

    $modsPathFromRimWorld = Join-Path $rimworldRoot 'Mods'
    $modsCanonical = Resolve-CanonicalDirectory -PathValue $modsPathFromRimWorld
    if (-not $modsCanonical) {
        Fail "Mods directory not found at '$modsPathFromRimWorld'."
    }
} else {
    $rimworldRoot = Get-RimWorldRoot -VerboseCheck:$VerboseOutput
    if (-not $rimworldRoot) {
        Fail 'Could not detect RimWorld install path. Pass -RimWorldPath or -ModsPath.'
    }

    $modsPathFromAutoDetect = Join-Path $rimworldRoot 'Mods'
    $modsCanonical = Resolve-CanonicalDirectory -PathValue $modsPathFromAutoDetect
    if (-not $modsCanonical) {
        Fail "Unable to resolve Mods directory: $modsPathFromAutoDetect"
    }
}

$destination = Join-Path $modsCanonical $ModName

$aboutDir = Join-Path $rootDir 'About'
$versionDir = Join-Path $rootDir '1.6'
$loadFoldersFile = Join-Path $rootDir 'LoadFolders.xml'

if (-not (Test-Path -LiteralPath $aboutDir -PathType Container)) {
    Fail "Required directory missing: $aboutDir"
}
if (-not (Test-Path -LiteralPath $versionDir -PathType Container)) {
    Fail "Required directory missing: $versionDir"
}
if (-not (Test-Path -LiteralPath $loadFoldersFile -PathType Leaf)) {
    Fail "Required file missing: $loadFoldersFile"
}

Write-Host "Source: $rootDir"
if ($rimworldRoot) {
    Write-Host "RimWorld root: $rimworldRoot"
}
Write-Host "Mods directory: $modsCanonical"
Write-Host "Destination: $destination"

if ($DryRun) {
    Write-Host 'Dry run: no files changed.'
    exit 0
}

New-Item -ItemType Directory -Path $destination -Force | Out-Null

Copy-DirectoryContents -Source $aboutDir -Destination (Join-Path $destination 'About')
Copy-DirectoryContents -Source $versionDir -Destination (Join-Path $destination '1.6')
Copy-Item -LiteralPath $loadFoldersFile -Destination (Join-Path $destination 'LoadFolders.xml') -Force

Copy-OptionalDirectory -Source (Join-Path $rootDir 'Languages') -Destination (Join-Path $destination 'Languages')
Copy-OptionalDirectory -Source (Join-Path $rootDir 'Textures') -Destination (Join-Path $destination 'Textures')
Copy-OptionalFile -Source (Join-Path $rootDir 'README.md') -Destination (Join-Path $destination 'README.md')
Copy-OptionalFile -Source (Join-Path $rootDir 'changelog.txt') -Destination (Join-Path $destination 'changelog.txt')
Copy-OptionalFile -Source (Join-Path $rootDir 'credits.md') -Destination (Join-Path $destination 'credits.md')

Write-Host 'Install/update complete.'
