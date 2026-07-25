#!/usr/bin/env bash
# Optional backend image build when Dockerfile exists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: build-docker.sh [--project <path>] [--tag <name>]

If Dockerfile (or docker/Dockerfile) exists, runs docker build.
Otherwise exits 0 and skips (placeholder for backend CI).
EOF
}

TAG=""
for a in "$@"; do
  [[ "$a" == "--help" || "$a" == "-h" ]] && { usage; exit 0; }
done

ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      [[ $# -ge 2 ]] || die "--tag requires a value"
      TAG="$2"
      shift 2
      ;;
    --clean|--runner|--no-codesign|--aab|--debug) shift ;;
    --flavor) shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

if [[ ${#ARGS[@]} -gt 0 ]]; then
  parse_common_args "${ARGS[@]}" || { usage; exit 1; }
else
  parse_common_args || { usage; exit 1; }
fi

DOCKERFILE=""
CONTEXT="$PROJECT_ROOT"
if [[ -f "$PROJECT_ROOT/Dockerfile" ]]; then
  DOCKERFILE="$PROJECT_ROOT/Dockerfile"
elif [[ -f "$PROJECT_ROOT/docker/Dockerfile" ]]; then
  DOCKERFILE="$PROJECT_ROOT/docker/Dockerfile"
else
  log "no Dockerfile — skip docker build"
  exit 0
fi

require_cmd docker

NAME="$(read_pubspec_name "$PROJECT_ROOT")"
VERSION="$(read_pubspec_version "$PROJECT_ROOT")"
if [[ -z "$TAG" ]]; then
  TAG="local-cicd/${NAME}:${VERSION}"
fi

log "docker build -f $DOCKERFILE -t $TAG $CONTEXT"
docker build -f "$DOCKERFILE" -t "$TAG" "$CONTEXT"

DIST="$(dist_dir_for "$PROJECT_ROOT")"
ensure_dist "$DIST"
printf '%s\n' "$TAG" > "$DIST/docker/image-tag.txt"
log "Docker image tagged: $TAG"
log "recorded → $DIST/docker/image-tag.txt"
