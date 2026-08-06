# Local_CICD

Global Flutter local-packaging skill: **local-cicd**.

## Install (personal Cursor skill)

```bash
mkdir -p ~/.cursor/skills
rsync -a --delete \
  --exclude '.git' \
  --exclude 'README.md' \
  ./ ~/.cursor/skills/local-cicd/
chmod +x ~/.cursor/skills/local-cicd/scripts/*.sh
```

Or from this repo after pull, run:

```bash
./install.sh
```

## Usage

```bash
export SKILL_DIR=~/.cursor/skills/local-cicd

# in any Flutter project
"$SKILL_DIR/scripts/doctor.sh"
"$SKILL_DIR/scripts/build-android.sh"
"$SKILL_DIR/scripts/build-ios.sh" --no-codesign
"$SKILL_DIR/scripts/build-all.sh" --no-codesign
```

In Cursor: ask to 打包 / build apk / build ipa / local-cicd.

## Evaluation (skill-up)

Decision-level evals verify the Agent invokes `scripts/*.sh` correctly (no hand-rolled `flutter build` chains), emits the right warnings (`--no-codesign` IPA is not installable), and respects defaults (no auto `flutter clean`). No real Flutter build runs.

```bash
skill-up validate evals/eval.yaml
skill-up run       evals/eval.yaml
```

Cases live under `evals/cases/`:

- `android-basic.yaml`         — apk packaging path
- `ios-no-codesign.yaml`       — `--no-codesign` warning
- `no-clean-by-default.yaml`   — clean stays off unless asked
- `doctor-first.yaml`          — `doctor.sh` when toolchain unsure
- `docker-conditional.yaml`    — docker script only when Dockerfile exists

Reports land under `local-cicd-workspace/iteration-N/` (`result.json`, `report.html`).

### Slash command

A global Claude Code command `/执行cicd [skill-root-path]` wraps the full flow (install CLI → scaffold/validate → run → report). Defined at `~/.claude/commands/执行cicd.md`.

## Layout

```text
SKILL.md
install.sh
scripts/
  doctor.sh
  build-android.sh
  build-ios.sh
  build-all.sh
  build-docker.sh
  lib/common.sh
references/
  flutter-local-build.md
  docker-backend.md
evals/
  eval.yaml
  cases/
    android-basic.yaml
    ios-no-codesign.yaml
    no-clean-by-default.yaml
    doctor-first.yaml
    docker-conditional.yaml
```
