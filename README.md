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
```
