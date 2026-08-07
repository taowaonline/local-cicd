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

## Development (harness)

This repo ships a [`harness`](https://github.com/taowaonline/tom_harness) config (`harness.toml`) that wraps the shell tooling behind stable command names — catches shellcheck violations, broken `source` paths, and secret leaks before they ship.

### Setup (one-time)

1. Install the harness CLI globally — see [tom_harness](https://github.com/taowaonline/tom_harness). After install, `harness --version` should work from any directory.
2. Install shell tooling (optional but recommended):
   ```bash
   brew install shellcheck shfmt
   ```
3. `skill-up` is already required by `evals/`; `flutter` is already required by the skill itself.

The `./harness` executable is **intentionally not committed** — every contributor uses the global `harness` command. The project-local `harness.toml` is the contract; the launcher comes from your environment.

### Run

From the repo root:

```bash
harness doctor             # toolchain inventory
harness validate           # config + dataset sanity
harness run check          # typecheck + lint + skill-up validate
harness run release-check  # + scripts --help + security posture
harness run security       # secret scan + policy audit (standalone)
harness run format         # shfmt in-place (writes to scripts/)
```

### Stage → tool mapping

| Stage | Runs | If tool missing |
|---|---|---|
| `typecheck` | `bash -n` on all 7 scripts | always works (bash is everywhere) |
| `lint` | `shellcheck -x -e SC1091` across all scripts | stage fails — install `shellcheck` |
| `format` | `shfmt -i 2 -ci -w scripts/` | stage fails — install `shfmt` |
| `test-unit` | `skill-up validate evals/eval.yaml` | stage fails — install `skill-up` |
| `test-integration` | `<script> --help` × 5 | always works |
| `security` | secret scan + `[security]` policy audit | built-in |

`SC1091` is excluded from shellcheck because scripts `source "$SCRIPT_DIR/lib/common.sh"` — shellcheck can't statically resolve that path, but the runtime works fine.

### What's not enforced

No GitHub Actions workflows. This project is macOS-only and solo-maintained, so CI stays local. If cross-environment or team contributions become a concern later, copy workflows from [tom_harness](https://github.com/taowaonline/tom_harness/tree/main/.github/workflows/).

## Layout

```text
SKILL.md
install.sh
harness.toml              # dev-time harness contract (see Development)
harness.schema.json       # machine-readable schema for harness.toml
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
  baselines/              # checked-in regression baselines (harness eval reports)
tests/
  fixtures/               # placeholder for future shell-level tests
```
