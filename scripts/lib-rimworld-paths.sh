#!/usr/bin/env bash

rw_is_wsl() {
  if grep -qi "microsoft" /proc/version 2>/dev/null; then
    return 0
  fi
  [ -n "${WSL_DISTRO_NAME:-}" ]
}

rw_is_macos() {
  [ "$(uname -s)" = "Darwin" ]
}

rw_macos_local_mods_path() {
  printf '%s\n' "$HOME/Library/Application Support/RimWorld/Mods"
}

rw_normalize_path_input() {
  local input="$1"
  if rw_is_wsl && command -v wslpath >/dev/null 2>&1; then
    case "$input" in
      [A-Za-z]:\\*|[A-Za-z]:/*)
        wslpath "$input"
        return 0
        ;;
    esac
  fi
  printf '%s\n' "$input"
}

rw_canonical_dir() {
  local path
  path="$(rw_normalize_path_input "$1")"
  (
    cd "$path" >/dev/null 2>&1 && pwd -P
  )
}

rw_extract_steam_library_paths() {
  local vdf="$1"
  [ -f "$vdf" ] || return 0

  awk -F'"' '/"path"[[:space:]]*"/ {print $4}' "$vdf" | while IFS= read -r raw; do
    [ -n "$raw" ] || continue
    raw="${raw//\\\\/\\}"
    raw="${raw//\\//}"
    rw_normalize_path_input "$raw"
  done
}

rw_detect_rimworld_root() {
  local verbose="${1:-0}"
  local candidates=()
  local steam_vdfs=()
  local vdf
  local library_path
  local candidate
  local path

  candidates+=(
    "/mnt/c/Program Files (x86)/Steam/steamapps/common/RimWorld"
    "/mnt/c/Program Files/Steam/steamapps/common/RimWorld"
    "/c/Program Files (x86)/Steam/steamapps/common/RimWorld"
    "/c/Program Files/Steam/steamapps/common/RimWorld"
  )
  steam_vdfs+=(
    "/mnt/c/Program Files (x86)/Steam/steamapps/libraryfolders.vdf"
    "/mnt/c/Program Files/Steam/steamapps/libraryfolders.vdf"
    "/c/Program Files (x86)/Steam/steamapps/libraryfolders.vdf"
    "/c/Program Files/Steam/steamapps/libraryfolders.vdf"
  )

  if rw_is_macos; then
    candidates+=(
      "$HOME/Library/Application Support/Steam/steamapps/common/RimWorld"
      "$HOME/Library/Application Support/Steam/steamapps/common/RimWorld/RimWorldMac.app"
    )
    steam_vdfs+=(
      "$HOME/Library/Application Support/Steam/steamapps/libraryfolders.vdf"
    )
  fi

  if rw_is_wsl; then
    local drive
    for drive in /mnt/[d-z]; do
      [ -d "$drive" ] || continue
      candidates+=(
        "$drive/Program Files (x86)/Steam/steamapps/common/RimWorld"
        "$drive/Program Files/Steam/steamapps/common/RimWorld"
      )
      steam_vdfs+=(
        "$drive/Program Files (x86)/Steam/steamapps/libraryfolders.vdf"
        "$drive/Program Files/Steam/steamapps/libraryfolders.vdf"
      )
    done
  fi

  for vdf in "${steam_vdfs[@]}"; do
    while IFS= read -r library_path; do
      [ -n "$library_path" ] || continue
      candidate="$library_path/steamapps/common/RimWorld"
      candidates+=("$candidate")
      if rw_is_macos; then
        candidates+=("$candidate/RimWorldMac.app")
      fi
    done < <(rw_extract_steam_library_paths "$vdf")
  done

  for path in "${candidates[@]}"; do
    if [ "$verbose" = "1" ]; then
      printf 'Checking RimWorld path candidate: %s\n' "$path" >&2
    fi
    if [ -d "$path/Mods" ]; then
      rw_canonical_dir "$path"
      return 0
    fi
    if [ -d "$path/RimWorldMac.app/Mods" ]; then
      rw_canonical_dir "$path"
      return 0
    fi
  done

  return 1
}
