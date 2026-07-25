# Flutter local build reference

Base commands (official Flutter CLI):

```bash
flutter pub get
flutter build apk --release
flutter build appbundle --release          # optional (--aab)
flutter build ipa                          # signed (needs Xcode Team)
flutter build ipa --no-codesign            # local/CI archive only
```

## Flags mapped by scripts

| Script flag | Effect |
|-------------|--------|
| `--clean` | `flutter clean` then build |
| `--runner` | `dart run build_runner build --delete-conflicting-outputs` if in pubspec |
| `--flavor X` | `--flavor X --dart-define=FLAVOR=X` |
| `--no-codesign` | iOS only; unsigned ipa/app |
| `--aab` | Android also builds appbundle |
| `--debug` | Android debug APK |

## Signing notes

- **Android**: release APK uses whatever `signingConfig` the project defines (often debug if unset).
- **iOS unsigned**: fine for compile checks; **not** installable via Apple Configurator until re-signed with a real Apple ID / Team.
- **iOS signed**: configure Xcode Signing & Capabilities (Team) before dropping `--no-codesign`.

## Why not rodydavis release.sh as runtime

That script forces clean, build_runner, git commits, and older `flutter build ios`. We only reuse the idea of a thin shell entrypoint; builds stay on current Flutter CLI.
