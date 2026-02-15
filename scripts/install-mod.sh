#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd -P)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/lib-rimworld-paths.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/install-mod.sh [options]

Options:
  --build                Build Source/NoJobAuthors.csproj (Debug) before install. Stops on build failure.
  --mod-name <name>      Destination folder name under RimWorld Mods (default: NoJobAuthors).
  --rimworld-path <path> Explicit RimWorld root path. Uses <path>/Mods.
  --mods-path <path>     Explicit Mods directory path (highest precedence).
  --dry-run              Print resolved paths and actions only.
  --verbose              Print path-detection attempts.
  --help                 Show this help message.
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

run_build_step() {
  local project="$ROOT_DIR/Source/NoJobAuthors.csproj"
  local project_arg="$project"
  local -a dotnet_cmd=()

  if command -v dotnet >/dev/null 2>&1; then
    dotnet_cmd=(dotnet)
  elif [ -x "/mnt/c/Program Files/dotnet/dotnet.exe" ]; then
    dotnet_cmd=("/mnt/c/Program Files/dotnet/dotnet.exe")
    if command -v wslpath >/dev/null 2>&1; then
      project_arg="$(wslpath -w "$project")"
    else
      fail "wslpath not found; cannot convert '$project' for Windows dotnet.exe"
    fi
  else
    fail "Could not find dotnet. Ensure dotnet is in PATH or available at /mnt/c/Program Files/dotnet/dotnet.exe"
  fi

  printf 'Build target: %s\n' "$project"
  printf 'Build tool: %s\n' "${dotnet_cmd[*]}"
  "${dotnet_cmd[@]}" restore "$project_arg"
  "${dotnet_cmd[@]}" build "$project_arg" -c Debug --no-restore
  printf 'Build succeeded.\n'
}

copy_dir_contents() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
}

copy_optional_dir() {
  local src="$1"
  local dst="$2"
  if [ -d "$src" ]; then
    copy_dir_contents "$src" "$dst"
  fi
}

copy_optional_file() {
  local src="$1"
  local dst="$2"
  if [ -f "$src" ]; then
    cp -f "$src" "$dst"
  fi
}

main() {
  local mod_name="NoJobAuthors"
  local rimworld_path=""
  local mods_path=""
  local build=0
  local dry_run=0
  local verbose=0
  local rimworld_root=""
  local mods_canonical=""
  local destination=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --mod-name)
        [ $# -ge 2 ] || fail "--mod-name requires a value."
        mod_name="$2"
        shift 2
        ;;
      --build)
        build=1
        shift
        ;;
      --rimworld-path)
        [ $# -ge 2 ] || fail "--rimworld-path requires a value."
        rimworld_path="$2"
        shift 2
        ;;
      --mods-path)
        [ $# -ge 2 ] || fail "--mods-path requires a value."
        mods_path="$2"
        shift 2
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      --verbose)
        verbose=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        fail "Unknown argument: $1. Use --help."
        ;;
    esac
  done

  if [ "$build" = "1" ]; then
    run_build_step
  fi

  if [ -n "$mods_path" ]; then
    mods_path="$(rw_normalize_path_input "$mods_path")"
    [ -d "$mods_path" ] || fail "Mods directory does not exist: $mods_path"
  elif [ -n "$rimworld_path" ]; then
    rimworld_root="$(rw_normalize_path_input "$rimworld_path")"
    mods_path="$rimworld_root/Mods"
    [ -d "$mods_path" ] || fail "Mods directory not found at '$mods_path'."
  else
    rimworld_root="$(rw_detect_rimworld_root "$verbose" || true)"
    [ -n "$rimworld_root" ] || fail "Could not detect RimWorld install path. Pass --rimworld-path or --mods-path."
    mods_path="$rimworld_root/Mods"
  fi

  mods_canonical="$(rw_canonical_dir "$mods_path" || true)"
  [ -n "$mods_canonical" ] || fail "Unable to resolve Mods directory: $mods_path"
  destination="$mods_canonical/$mod_name"

  [ -d "$ROOT_DIR/About" ] || fail "Required directory missing: $ROOT_DIR/About"
  [ -d "$ROOT_DIR/1.6" ] || fail "Required directory missing: $ROOT_DIR/1.6"
  [ -f "$ROOT_DIR/LoadFolders.xml" ] || fail "Required file missing: $ROOT_DIR/LoadFolders.xml"

  printf 'Source: %s\n' "$ROOT_DIR"
  printf 'Mods directory: %s\n' "$mods_canonical"
  printf 'Destination: %s\n' "$destination"

  if [ "$dry_run" = "1" ]; then
    printf 'Dry run: no files changed.\n'
    exit 0
  fi

  mkdir -p "$destination"

  copy_dir_contents "$ROOT_DIR/About" "$destination/About"
  copy_dir_contents "$ROOT_DIR/1.6" "$destination/1.6"
  cp -f "$ROOT_DIR/LoadFolders.xml" "$destination/LoadFolders.xml"

  copy_optional_dir "$ROOT_DIR/Languages" "$destination/Languages"
  copy_optional_dir "$ROOT_DIR/Textures" "$destination/Textures"
  copy_optional_file "$ROOT_DIR/README.md" "$destination/README.md"
  copy_optional_file "$ROOT_DIR/changelog.txt" "$destination/changelog.txt"
  copy_optional_file "$ROOT_DIR/credits.md" "$destination/credits.md"

  printf 'Install/update complete.\n'
}

main "$@"
