# Docker backend (P3 placeholder)

`scripts/build-docker.sh` behavior:

1. If `Dockerfile` or `docker/Dockerfile` exists → `docker build` and write tag to `dist/<app>-<version>/docker/image-tag.txt`
2. Otherwise → exit 0 (skip)

Suggested tag default: `local-cicd/<pubspec-name>:<version>`

Future extensions (not implemented):

- multi-stage Node/Go/Java templates
- compose-based local stack
- push to registry (explicit opt-in only)
