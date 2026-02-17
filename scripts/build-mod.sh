#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SOLUTION="$ROOT_DIR/Source/NoJobAuthors.sln"
SOLUTION_ARG="$SOLUTION"

if command -v dotnet >/dev/null 2>&1; then
  dotnet restore "$SOLUTION_ARG"
  dotnet build "$SOLUTION_ARG" -c Debug --no-restore
  exit 0
fi

if [ -x "/mnt/c/Program Files/dotnet/dotnet.exe" ]; then
  if command -v wslpath >/dev/null 2>&1; then
    SOLUTION_ARG="$(wslpath -w "$SOLUTION")"
  else
    echo "Error: wslpath not found; cannot convert '$SOLUTION' for Windows dotnet.exe." >&2
    exit 1
  fi
  "/mnt/c/Program Files/dotnet/dotnet.exe" restore "$SOLUTION_ARG"
  "/mnt/c/Program Files/dotnet/dotnet.exe" build "$SOLUTION_ARG" -c Debug --no-restore
  exit 0
fi

if command -v msbuild >/dev/null 2>&1; then
  msbuild "$SOLUTION" /t:Restore /p:Configuration=Debug /v:m
  msbuild "$SOLUTION" /p:Configuration=Debug /v:m
  exit 0
fi

if command -v devenv >/dev/null 2>&1; then
  devenv "$SOLUTION" /build Debug
  exit 0
fi

echo "Error: no build tool found (dotnet/msbuild/devenv)." >&2
exit 1
