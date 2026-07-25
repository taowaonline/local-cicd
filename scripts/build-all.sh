#!/usr/bin/env bash
# Build Android + iOS (and optional Docker) into dist/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: build-all.sh [options]

Runs build-android.sh then build-ios.sh with the same flags.
Docker build runs only if a Dockerfile exists (see build-docker.sh).

Options: same as build-android / build-ios
  --project --flavor --clean --runner --no-codesign --aab --debug
  --skip-android / --skip-ios / --skip-docker
  -h, --help
EOF
}

SKIP_ANDROID=0
SKIP_IOS=0
SKIP_DOCKER=0
PASS_ARGS=()

for a in "$@"; do
  [[ "$a" == "--help" || "$a" == "-h" ]] && { usage; exit 0; }
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-android) SKIP_ANDROID=1; shift ;;
    --skip-ios) SKIP_IOS=1; shift ;;
    --skip-docker) SKIP_DOCKER=1; shift ;;
    *) PASS_ARGS+=("$1"); shift ;;
  esac
done

# Resolve project for summary
if [[ ${#PASS_ARGS[@]} -gt 0 ]]; then
  parse_common_args "${PASS_ARGS[@]}" || true
fi
if [[ -z "${PROJECT_ROOT:-}" ]]; then
  PROJECT_ROOT="$(resolve_project_root "$PWD")"
fi

FAILED=0

run_child() {
  local script="$1"
  shift
  if [[ $# -gt 0 ]]; then
    "$script" "$@"
  else
    "$script"
  fi
}

if [[ "$SKIP_ANDROID" -eq 0 ]]; then
  log "=== Android ==="
  if [[ ${#PASS_ARGS[@]} -gt 0 ]]; then
    run_child "$SCRIPT_DIR/build-android.sh" "${PASS_ARGS[@]}" || { warn "Android build failed"; FAILED=1; }
  else
    run_child "$SCRIPT_DIR/build-android.sh" || { warn "Android build failed"; FAILED=1; }
  fi
fi

if [[ "$SKIP_IOS" -eq 0 ]]; then
  log "=== iOS ==="
  if [[ ${#PASS_ARGS[@]} -gt 0 ]]; then
    run_child "$SCRIPT_DIR/build-ios.sh" "${PASS_ARGS[@]}" || { warn "iOS build failed"; FAILED=1; }
  else
    run_child "$SCRIPT_DIR/build-ios.sh" || { warn "iOS build failed"; FAILED=1; }
  fi
fi

if [[ "$SKIP_DOCKER" -eq 0 ]]; then
  log "=== Docker (optional) ==="
  if [[ ${#PASS_ARGS[@]} -gt 0 ]]; then
    run_child "$SCRIPT_DIR/build-docker.sh" "${PASS_ARGS[@]}" || { warn "Docker build failed"; FAILED=1; }
  else
    run_child "$SCRIPT_DIR/build-docker.sh" || { warn "Docker build failed"; FAILED=1; }
  fi
fi

DIST="$(dist_dir_for "$PROJECT_ROOT")"
log "=== Summary ==="
if [[ -d "$DIST" ]]; then
  find "$DIST" -type f | sort
else
  warn "no dist/ produced"
fi

[[ "$FAILED" -eq 0 ]] || die "one or more builds failed"
log "all requested builds succeeded → $DIST"
