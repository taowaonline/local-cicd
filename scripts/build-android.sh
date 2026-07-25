#!/usr/bin/env bash
# Build Flutter Android APK (release) and archive to dist/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: build-android.sh [options]

Options:
  --project <path>   Flutter project root (default: discover from cwd)
  --flavor <name>    Pass --flavor and --dart-define=FLAVOR=<name>
  --clean            Run flutter clean first (slower)
  --runner           Run build_runner if listed in pubspec
  --aab              Also build appbundle
  --debug            Build debug APK instead of release
  -h, --help         Show help

Default: incremental release APK, no clean, no git commits.
Artifacts: dist/<app>-<version>/android/
EOF
}

BUILD_AAB=0
BUILD_MODE="release"

for a in "$@"; do
  [[ "$a" == "--help" || "$a" == "-h" ]] && { usage; exit 0; }
done

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --aab) BUILD_AAB=1; shift ;;
    --debug) BUILD_MODE="debug"; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [[ ${#ARGS[@]} -gt 0 ]]; then
  parse_common_args "${ARGS[@]}" || { usage; exit 1; }
else
  parse_common_args || { usage; exit 1; }
fi

[[ -d "$PROJECT_ROOT/android" ]] || die "no android/ in $PROJECT_ROOT"
require_cmd flutter

log "project: $PROJECT_ROOT"
maybe_clean "$PROJECT_ROOT"
maybe_pub_get "$PROJECT_ROOT"
maybe_build_runner "$PROJECT_ROOT"

FLUTTER_ARGS=(build apk "--$BUILD_MODE")
if [[ -n "$FLAVOR" ]]; then
  FLUTTER_ARGS+=(--flavor "$FLAVOR" --dart-define="FLAVOR=$FLAVOR")
fi
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  FLUTTER_ARGS+=("${EXTRA_ARGS[@]}")
fi

log "flutter ${FLUTTER_ARGS[*]}"
(cd "$PROJECT_ROOT" && flutter "${FLUTTER_ARGS[@]}")

if [[ "$BUILD_AAB" -eq 1 ]]; then
  AAB_ARGS=(build appbundle "--$BUILD_MODE")
  if [[ -n "$FLAVOR" ]]; then
    AAB_ARGS+=(--flavor "$FLAVOR" --dart-define="FLAVOR=$FLAVOR")
  fi
  log "flutter ${AAB_ARGS[*]}"
  (cd "$PROJECT_ROOT" && flutter "${AAB_ARGS[@]}")
fi

DIST="$(dist_dir_for "$PROJECT_ROOT")"
ensure_dist "$DIST"

if archive_find "$DIST/android" "$PROJECT_ROOT/build/app/outputs/flutter-apk" -name '*.apk'; then
  :
elif archive_find "$DIST/android" "$PROJECT_ROOT/build/app/outputs/apk" -name '*.apk'; then
  :
else
  die "no APK found under build/app/outputs"
fi

if [[ "$BUILD_AAB" -eq 1 ]]; then
  if ! archive_find "$DIST/android" "$PROJECT_ROOT/build/app/outputs/bundle" -name '*.aab'; then
    warn "appbundle requested but no .aab found"
  fi
fi

log "Android build complete → $DIST/android"
ls -la "$DIST/android"
