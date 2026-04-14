# MTG Scanner

Free, login-free Android app for cataloging Magic: The Gathering cards and exporting to Moxfield.

## Plan A (current): manual add + collection + export

- Search by name (Scryfall autocomplete)
- Pick exact printing
- View collection with live prices and totals
- Export to Moxfield text or CSV
- JSON backup

## Plan B (upcoming)

- Camera scanning with OCR + foil detection

## Dev

    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    flutter test
    flutter run

On Windows, prefer `powershell -File tool\flutter.ps1 <args>` over bare
`flutter` — it kills stale host processes and clears `build\native_assets\
windows\sqlite3.dll` before each run, avoiding intermittent errno-183
copy failures after a crashed test/run.
