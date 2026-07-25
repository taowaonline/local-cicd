#!/usr/bin/env bash
# Build Flutter iOS IPA and archive to dist/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: build-ios.sh [options]

Options:
  --project <path>   Flutter project root (default: discover from cwd)
  --flavor <name>    Pass --flavor and --dart-define=FLAVOR=<name>
  --no-codesign      Build unsigned IPA (local archive / CI check only)
  --clean            Run flutter clean first (slower)
  --runner           Run build_runner if listed in pubspec
  -h, --help         Show help

Default: incremental IPA. Use --no-codesign when no Apple signing setup.
Unsigned IPAs cannot be installed on device via Configurator.
Artifacts: dist/<app>-<version>/ios/
EOF
}

for a in "$@"; do
  [[ "$a" == "--help" || "$a" == "-h" ]] && { usage; exit 0; }
done

if [[ $# -gt 0 ]]; then
  parse_common_args "$@" || { usage; exit 1; }
else
  parse_common_args || { usage; exit 1; }
fi

[[ -d "$PROJECT_ROOT/ios" ]] || die "no ios/ in $PROJECT_ROOT"
require_cmd flutter
command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found (install Xcode)"

log "project: $PROJECT_ROOT"
maybe_clean "$PROJECT_ROOT"
maybe_pub_get "$PROJECT_ROOT"
maybe_build_runner "$PROJECT_ROOT"

FLUTTER_ARGS=(build ipa)
if [[ "$NO_CODESIGN" -eq 1 ]]; then
  FLUTTER_ARGS+=(--no-codesign)
  log "building unsigned IPA (--no-codesign)"
fi
if [[ -n "$FLAVOR" ]]; then
  FLUTTER_ARGS+=(--flavor "$FLAVOR" --dart-define="FLAVOR=$FLAVOR")
fi
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  FLUTTER_ARGS+=("${EXTRA_ARGS[@]}")
fi

log "flutter ${FLUTTER_ARGS[*]}"
(cd "$PROJECT_ROOT" && flutter "${FLUTTER_ARGS[@]}")

DIST="$(dist_dir_for "$PROJECT_ROOT")"
ensure_dist "$DIST"

if archive_find "$DIST/ios" "$PROJECT_ROOT/build/ios/ipa" -name '*.ipa'; then
  :
elif archive_find "$DIST/ios" "$PROJECT_ROOT/build/ios/iphoneos" -maxdepth 1 -name '*.app'; then
  warn "no .ipa under build/ios/ipa; archived .app instead"
else
  die "no IPA or .app found under build/ios"
fi

if [[ "$NO_CODESIGN" -eq 1 ]]; then
  warn "unsigned build: not installable on device until re-signed"
fi

log "iOS build complete → $DIST/ios"
ls -la "$DIST/ios"
