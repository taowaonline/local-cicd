#!/usr/bin/env bash
# Quick toolchain check for Flutter local builds.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: doctor.sh [--project <path>]

Checks Flutter / Xcode / Android SDK availability for local apk/ipa builds.
EOF
}

for a in "$@"; do
  [[ "$a" == "--help" || "$a" == "-h" ]] && { usage; exit 0; }
done

PROJECT_ARG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      [[ $# -ge 2 ]] || die "--project requires a path"
      PROJECT_ARG="$2"
      shift 2
      ;;
    *)
      die "unknown flag: $1 (try --help)"
      ;;
  esac
done

if [[ -z "$PROJECT_ARG" ]]; then
  PROJECT_ROOT="$(resolve_project_root "$PWD")"
else
  PROJECT_ROOT="$(resolve_project_root "$PROJECT_ARG")"
fi

log "project: $PROJECT_ROOT"
log "app: $(read_pubspec_name "$PROJECT_ROOT") @ $(read_pubspec_version "$PROJECT_ROOT")"

require_cmd flutter
log "flutter: $(flutter --version 2>/dev/null | head -1)"

echo
flutter doctor -v || true

echo
if [[ -d "$PROJECT_ROOT/android" ]]; then
  log "android/ present"
  if [[ -n "${ANDROID_HOME:-}${ANDROID_SDK_ROOT:-}" ]]; then
    log "Android SDK: ${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  else
    warn "ANDROID_HOME / ANDROID_SDK_ROOT not set (Android Studio default may still work)"
  fi
else
  warn "android/ missing — Android builds unavailable"
fi

if [[ -d "$PROJECT_ROOT/ios" ]]; then
  log "ios/ present"
  if command -v xcodebuild >/dev/null 2>&1; then
    log "xcodebuild: $(xcodebuild -version 2>/dev/null | head -1)"
  else
    warn "xcodebuild not found — iOS builds unavailable on this machine"
  fi
else
  warn "ios/ missing — iOS builds unavailable"
fi

if [[ -f "$PROJECT_ROOT/Dockerfile" ]] || [[ -f "$PROJECT_ROOT/docker/Dockerfile" ]]; then
  log "Dockerfile detected (docker backend ready)"
else
  log "no Dockerfile (docker build is optional)"
fi

log "doctor complete"
