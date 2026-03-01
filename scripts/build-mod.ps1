Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail {
    param([string]$Message)
    [Console]::Error.WriteLine("Error: $Message")
    exit 1
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

$rootDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$solution = Join-Path $rootDir 'Source/NoJobAuthors.sln'

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Fail 'Could not find dotnet in PATH.'
}

Write-Host "Build target: $solution"
Write-Host 'Build tool: dotnet'

Invoke-Dotnet -Arguments @('restore', $solution)
Invoke-Dotnet -Arguments @('build', $solution, '-c', 'Release', '--no-restore')
