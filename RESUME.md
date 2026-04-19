# MTG Scanner — Plans A + B1 + B2 + B3 complete (2026-04-15)

## Status
- **Plan A:** done (manual add, collection, Moxfield export, settings, backup, APK).
- **Plan B1:** done — camera capture, opencv rectangle + stability, landscape-aware warp, ML-Kit OCR populates `rawName`/`rawSetCollector` and a thumbnail.
- **Plan B2:** done — `ScanMatcher` runs Scryfall lookup after each capture. `/cards/{set}/{number}` hit → confidence 1.0, auto-confirm to collection. Fuzzy-name fallback → 0.6, stays in review queue. Failure → 0.0, raw OCR shown so user can Edit.
- **Plan B3:** done — lightweight HSV-saturation foil heuristic writes `foilGuess` on each scan. Accuracy is weak (single-frame signal, as the spec warned); the manual foil switch in the review queue remains the authoritative control.

## What works end-to-end today
- Point camera → card auto-detects → pipeline runs Scryfall match → either auto-confirms to collection (with live USD price) or lands in the review queue at 60% for user confirmation.
- Review queue shows the warped thumbnail so user can verify before confirming.
- All of Plan A's flows (manual add, export, backup, refresh prices) still work.

## Known limitations
- OCR regions are intentionally generous; collector-number digits occasionally bleed into the name. Scryfall fuzzy match forgives most cases, but some rare names mis-match.
- Cluttered backgrounds reduce detection rate. Plain surface recommended.
- Latin-script OCR only; non-English prints need a different ML-Kit model.
- Debug APK is ~320 MB. Use `flutter build apk --split-per-abi` for release.
- Offline scans never retry lookup automatically — Edit manually for now (spec §Error Handling deferred).
- Confidence-tier 0.3 ("low-quality OCR") from spec collapsed to 0.0 — simpler, same UX.

## Next
- **Plan A accuracy+perf (2026-04-20): shipped.** Height-ranked multi-line name picker, 90°/180°/270° orientation recovery, OCR pass pruning (up to 6 → 3-4 passes), scored best-match in the matcher (weighted name+cn+set, 0.95 short-circuit, 0.5 accept threshold), 100 ms throttle + 640 px downscale in the frame loop.
- **Approach B:** Move rect detection and OCR onto a background isolate to get them off the UI thread. Depends on verifying opencv_dart and google_mlkit_text_recognition are isolate-safe.
- **Approach C:** Ensemble OCR — add a second engine (Tesseract with a Scryfall-derived ~25k-name user-words dictionary) alongside ML Kit, aggregate candidates into the matcher's scoring layer. Design should be informed by on-device failure data gathered during A.
- **Polish backlog:** tighter OCR name region, retry-on-reconnect for failed lookups, release APK split, icon/branding, stamp-based foil detection (needs reference templates), multi-frame tilt analysis for better foil signal.

## Environment reminders
- Invoke Flutter via `cmd.exe /c "powershell -File tool\flutter.ps1 <args>"` from WSL. The wrapper clears the `build\native_assets\windows\sqlite3.dll` lock that otherwise blocks rebuilds.
- Camera stream on Android **must use `ImageFormatGroup.yuv420`** and be I420-packed before handing to opencv_dart — see `scanner_screen.dart::_bgrJpegFromFrame`.
- opencv_dart 1.4.5 uses `VecPoint2f` + `getPerspectiveTransform2f`, not the raw-Mat API in older docs.

## Reference docs
- Spec: `docs/superpowers/specs/2026-04-14-mtg-card-scanner-design.md`
- Plan A: `docs/superpowers/plans/2026-04-14-mtg-scanner-plan-a-foundation.md`
- Plan B1: `docs/superpowers/plans/2026-04-15-mtg-scanner-plan-b1-capture-ocr.md`
- Plan B2: `docs/superpowers/plans/2026-04-15-mtg-scanner-plan-b2-scryfall-match.md`
