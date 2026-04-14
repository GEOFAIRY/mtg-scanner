# MTG Scanner — Plan B1 complete (2026-04-15)

## Status
- **Plan A:** done (manual add + collection + export + settings + APK).
- **Plan B1 (capture + OCR):** done, merged to `master` as `ab3082f`.
  - Camera preview, YUV→BGR conversion, contour-based rectangle detection,
    stability tracking, landscape-aware perspective warp, ML-Kit OCR on
    name + set/collector regions, review queue row with thumbnail.
  - On-device verified: detects card, warps upright, OCR produces readable
    text (e.g. "Shimmercreep 42" — near-correct with OCR imperfections).
- **Plan B2 (Scryfall auto-match):** not started. Will clean up OCR noise
  via fuzzy name match + `/cards/{set}/{number}` lookup, populate the
  `matched_*` columns, and auto-move ≥0.8-confidence scans to the
  collection.
- **Plan B3 (foil detection):** not started.

## Known limitations of B1
- Detection needs a plain background for best results; cluttered scenes
  sometimes fail. Loosened thresholds already applied (Canny 30/90, min
  area 6%, multi-epsilon approx).
- OCR regions are generous to tolerate warp misalignment — stray digits
  from the collector row sometimes bleed into the name field. Plan B2's
  fuzzy match handles this.
- Latin-script OCR only (ML Kit default). Non-English cards need a
  different model.
- Android-only; iOS port untested.

## Next session starter
- Plan B2 spec lives in `docs/superpowers/specs/2026-04-14-mtg-card-scanner-design.md`
  (§Lookup layer, §Confidence scoring).
- Feed that section to `superpowers:writing-plans` to produce
  `docs/superpowers/plans/2026-04-??-mtg-scanner-plan-b2-*.md`.

## Environment reminders
- Invoke Flutter via `cmd.exe /c "powershell -File tool\flutter.ps1 <args>"`
  from WSL. The wrapper clears the sqlite3.dll lock that otherwise
  blocks rebuilds.
- Debug APK is ~320 MB because opencv_dart + ML Kit ship native libs for
  all Android ABIs. Release builds with `--split-per-abi` will produce
  ~60 MB per-ABI APKs.

## Reference docs
- Plan A plan: `docs/superpowers/plans/2026-04-14-mtg-scanner-plan-a-foundation.md`
- Plan B1 plan: `docs/superpowers/plans/2026-04-15-mtg-scanner-plan-b1-capture-ocr.md`
- Spec: `docs/superpowers/specs/2026-04-14-mtg-card-scanner-design.md`
