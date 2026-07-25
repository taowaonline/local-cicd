#!/usr/bin/env bash
# Shared helpers for local-cicd scripts.
# shellcheck disable=SC2034

set -euo pipefail

LOCAL_CICD_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

# Resolve Flutter project root (directory with pubspec.yaml + android/ or ios/).
# Usage: resolve_project_root [optional_path]
resolve_project_root() {
  local start="${1:-$PWD}"
  local dir
  dir="$(cd "$start" && pwd)"

  while true; do
    if [[ -f "$dir/pubspec.yaml" ]] && { [[ -d "$dir/android" ]] || [[ -d "$dir/ios" ]]; }; then
      printf '%s\n' "$dir"
      return 0
    fi
    if [[ "$dir" == "/" ]]; then
      die "not a Flutter project (no pubspec.yaml with android/ or ios/). Run from project root or pass --project <path>"
    fi
    dir="$(dirname "$dir")"
  done
}

read_pubspec_name() {
  local root="$1"
  local name
  name="$(sed -nE 's/^name:[[:space:]]*//p' "$root/pubspec.yaml" | head -1 | tr -d '"' | tr -d "'")"
  [[ -n "$name" ]] || die "could not read name from pubspec.yaml"
  printf '%s\n' "$name"
}

read_pubspec_version() {
  local root="$1"
  local ver
  ver="$(sed -nE 's/^version:[[:space:]]*//p' "$root/pubspec.yaml" | head -1 | tr -d '"' | tr -d "'")"
  [[ -n "$ver" ]] || die "could not read version from pubspec.yaml"
  # sanitize for paths: 1.0.0+1 -> 1.0.0_1
  printf '%s\n' "${ver//+/_}"
}

has_build_runner() {
  local root="$1"
  grep -qE '^[[:space:]]*build_runner:' "$root/pubspec.yaml" 2>/dev/null
}

dist_dir_for() {
  local root="$1"
  local name version
  name="$(read_pubspec_name "$root")"
  version="$(read_pubspec_version "$root")"
  printf '%s\n' "$root/dist/${name}-${version}"
}

ensure_dist() {
  local dist="$1"
  mkdir -p "$dist/android" "$dist/ios" "$dist/docker"
}

copy_artifacts() {
  local dest_dir="$1"
  shift
  mkdir -p "$dest_dir"
  local f
  for f in "$@"; do
    if [[ -e "$f" ]]; then
      cp -R "$f" "$dest_dir/"
      log "archived: $dest_dir/$(basename "$f")"
    fi
  done
}

# Parse shared flags into globals: PROJECT_ROOT CLEAN FLAVOR NO_CODESIGN RUN_RUNNER EXTRA_ARGS
# Remaining args after -- go to EXTRA_ARGS array.
PROJECT_ROOT=""
CLEAN=0
FLAVOR=""
NO_CODESIGN=0
RUN_RUNNER=0
EXTRA_ARGS=()

parse_common_args() {
  PROJECT_ROOT=""
  CLEAN=0
  FLAVOR=""
  NO_CODESIGN=0
  RUN_RUNNER=0
  EXTRA_ARGS=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project)
        [[ $# -ge 2 ]] || die "--project requires a path"
        PROJECT_ROOT="$2"
        shift 2
        ;;
      --clean)
        CLEAN=1
        shift
        ;;
      --flavor)
        [[ $# -ge 2 ]] || die "--flavor requires a name"
        FLAVOR="$2"
        shift 2
        ;;
      --no-codesign)
        NO_CODESIGN=1
        shift
        ;;
      --runner)
        RUN_RUNNER=1
        shift
        ;;
      --help|-h)
        return 2
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          EXTRA_ARGS+=("$1")
          shift
        done
        break
        ;;
      -*)
        die "unknown flag: $1"
        ;;
      *)
        EXTRA_ARGS+=("$1")
        shift
        ;;
    esac
  done

  if [[ -z "$PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$(resolve_project_root "$PWD")"
  else
    PROJECT_ROOT="$(resolve_project_root "$PROJECT_ROOT")"
  fi
}

maybe_clean() {
  local root="$1"
  if [[ "$CLEAN" -eq 1 ]]; then
    log "flutter clean"
    (cd "$root" && flutter clean)
  fi
}

maybe_pub_get() {
  local root="$1"
  log "flutter pub get"
  (cd "$root" && flutter pub get)
}

maybe_build_runner() {
  local root="$1"
  if [[ "$RUN_RUNNER" -eq 1 ]]; then
    if has_build_runner "$root"; then
      log "dart run build_runner build --delete-conflicting-outputs"
      (cd "$root" && dart run build_runner build --delete-conflicting-outputs)
    else
      warn "build_runner not in pubspec.yaml; skipping --runner"
    fi
  fi
}

# Copy every path from find(1) args into dest dir. Returns 0 if at least one file copied.
archive_find() {
  local dest="$1"
  shift
  local found=0
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    copy_artifacts "$dest" "$f"
    found=1
  done < <(find "$@" 2>/dev/null || true)
  [[ "$found" -eq 1 ]]
}
