# Plan A — Complete (2026-04-15)

All 18 tasks committed. Debug APK built at
`build\app\outputs\flutter-apk\app-debug.apk`.

## Final state
- 10 tests pass, `flutter analyze` clean
- Last commits:
  - `e03ebd5` add readme and finalize plan a
  - `7935ad6` add settings screen with refresh-all and json backup
  - `e1a73a7` fix review queue test drift stream timer leak

## Notes for future work
- Plan B (camera scan + OCR + foil detection) is unwritten — start with
  `docs/superpowers/specs/2026-04-14-mtg-card-scanner-design.md` as input
  to the writing-plans skill.
- On Windows, use `powershell -File tool\flutter.ps1 <args>` to avoid the
  sqlite3.dll file-lock issue after a crashed test/run.
- Flutter SDK at `C:\Flutter\flutter\bin\flutter.bat`, invoke from WSL via
  `cmd.exe /c "..."`.

## Reference docs
- Spec: `docs/superpowers/specs/2026-04-14-mtg-card-scanner-design.md`
- Plan: `docs/superpowers/plans/2026-04-14-mtg-scanner-plan-a-foundation.md`
