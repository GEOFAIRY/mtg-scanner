# MTG Scanner

A free, login-free Android app for cataloging a personal Magic: The Gathering collection. Point your phone at a card, let the app match it against Scryfall, and export the result to Moxfield when you're ready. No accounts, no cloud sync, no subscription.

## Features

- **Camera scan** — continuous card detection with perspective correction, stability gating, and on-device OCR (ML Kit).
- **Scryfall match** — lookup by card name + collector number (with set-code and fuzzy-name fallbacks) resolves the exact printing.
- **Foil detection** — lightweight HSV-saturation heuristic; manual toggle overrides when the heuristic is unsure.
- **Collection management** — view, edit, and delete entries with live USD prices from Scryfall.
- **Moxfield export** — text and CSV formats suitable for paste-into-deck and bulk-import respectively.
- **Backup / restore** — local JSON dump for moving between devices.
- **Price-drop audio alert** — plays a sound when a scanned card exceeds a configurable value threshold.

## Architecture

- Flutter + Material 3 (dark theme by default).
- Drift (SQLite) for local persistence.
- Scryfall REST for card data; 100ms throttled client, 4s match timeout.
- Scanner pipeline: camera YUV420 stream → OpenCV card-rect detection → stability tracker → perspective warp → ML Kit OCR → Scryfall match → collection insert.

## Developing

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

On WSL, the included wrapper shells out to Windows Flutter and works around a known `sqlite3.dll` copy issue:

```
cmd.exe /c "powershell -File tool/flutter.ps1 <args>"
```

## Build & install (release)

```
flutter build apk --split-per-abi --release
flutter install --release
```

Split APKs are ~60 MB each; the fat `app-release.apk` is produced by `flutter install` when needed.

### Wireless install

When the USB connection is flaky:

```
adb pair   <phone-ip>:<pair-port> <pair-code>
adb connect <phone-ip>:<connect-port>
flutter install --release -d <phone-ip>:<connect-port>
```

Ports and pairing code come from Android **Developer Options → Wireless debugging**.

## Project layout

```
lib/
  app.dart, main.dart            app entry + router + theme
  app_settings.dart              user-tweakable runtime settings
  data/
    db/                          Drift schema, daos, generated code
    repositories/                collection repository (insert / edit / undo / price refresh)
    scryfall/                    REST client, models
  features/
    scanner/                     camera, rect detect, OCR, matcher, pipeline, foil, banner
    collection/                  list, detail, manual add, edit modal
    export/                      Moxfield text + CSV formatters
    settings/                    backup, restore, refresh prices
    shell/                       bottom-nav shell
  shared/                        reusable widgets (price text, set icon, printing picker)
test/                            unit + widget tests mirroring lib/
```

## Testing

The suite is ~58 tests covering parsed OCR, Scryfall client, scan matcher, scan pipeline, banner, scanner state, formatters, and settings persistence. Run `flutter test` — most tests use mocktail for external collaborators.
