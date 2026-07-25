---
name: local-cicd
description: >-
  Local Flutter CI/CD for fast apk/ipa builds with thin shell scripts, optional
  Docker backend, and dist/ artifact archival. Use when the user asks to 打包,
  build apk, build ipa, local CI, local-cicd, release Android/iOS locally, or
  run doctor for mobile toolchain checks.
---

# local-cicd

Global skill for **local** Flutter packaging. Orchestrate via scripts; do not reinvent long one-off `flutter build` command chains.

Skill root (this folder):

- Personal install: `~/.cursor/skills/local-cicd/`
- Repo mirror: project `Local_CICD` (same layout)

## When to use

- User wants local **apk** / **ipa** (optionally unsigned iOS)
- User says 打包 / local-cicd / local CI
- Optional backend: Dockerfile present → `build-docker.sh`

## Do not

- Force `flutter clean` unless user asks or `--clean`
- Auto `git commit` / version bump
- Require Fastlane for P0 local builds
- Treat `--no-codesign` IPA as installable on device

## Workflow

1. Confirm cwd (or `--project`) is a Flutter app (`pubspec.yaml` + `android/` / `ios/`).
2. Prefer scripts under `scripts/` (resolve skill path below).
3. Report final paths under `dist/<app>-<version>/`.

### Resolve skill path

```bash
SKILL_DIR="${HOME}/.cursor/skills/local-cicd"
# fallback if developing from repo:
# SKILL_DIR="/Users/tommacmini4/orca/projects/Local_CICD"
```

### Commands

```bash
"$SKILL_DIR/scripts/doctor.sh" [--project <path>]

"$SKILL_DIR/scripts/build-android.sh" [--project <path>] [--flavor <name>] [--clean] [--runner] [--aab] [--debug]

"$SKILL_DIR/scripts/build-ios.sh" [--project <path>] [--flavor <name>] [--no-codesign] [--clean] [--runner]

"$SKILL_DIR/scripts/build-all.sh" [same flags] [--skip-android|--skip-ios|--skip-docker]

"$SKILL_DIR/scripts/build-docker.sh" [--project <path>] [--tag <name>]
```

### Defaults (performance)

| Behavior | Default |
|----------|---------|
| clean | off |
| build_runner | off (use `--runner`) |
| Android | `flutter build apk --release` |
| iOS | `flutter build ipa` (add `--no-codesign` if no signing) |
| git | never commits |

### Artifacts

```text
dist/<pubspec-name>-<version>/
  android/*.apk   (+ *.aab if --aab)
  ios/*.ipa       (or *.app fallback)
  docker/image-tag.txt   (if Dockerfile built)
```

## Agent checklist

1. Run `doctor.sh` if toolchain looks unsure.
2. For unsigned local iOS: pass `--no-codesign`; warn not installable via Configurator until re-signed.
3. For flavors: `--flavor <name>` (also sets `--dart-define=FLAVOR=`).
4. After build, list `dist/...` and give the user the exact artifact paths.
5. Backend: only call docker script when Dockerfile exists (script no-ops otherwise).

## References

- Build details: [references/flutter-local-build.md](references/flutter-local-build.md)
- Docker placeholder: [references/docker-backend.md](references/docker-backend.md)

## Roadmap (not P0)

- P1: signing checklist (key.properties / Xcode Team)
- P2: optional Fastlane beta
- P3: richer Docker/backend pipelines
