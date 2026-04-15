# Scan price feedback and value alert — design

## Goal

On a successful scan, show the matched card's price in the confirmation overlay and play a cash-register sound when the price exceeds a user-configured threshold. Only save scans that match a real Scryfall card (exact by set+collector number, or fuzzy by name).

## Behaviour

### Scanner overlay states

After stability + capture trigger:

- **Matching** — `⋯ matching…` with a small spinner. Shown while the Scryfall lookup is in flight.
- **Matched** — `✓ <matched name> — $<price>`. Held for 700 ms (existing hold duration).
- **No match** — `✗ no match`. Held for 700 ms. Nothing saved.
- **Offline / network error** — `⚠ offline`. Held for 700 ms. Nothing saved.

Timeout: the Scryfall lookup is capped at 4 seconds. A timeout is treated as a network error (`⚠ offline`).

### Which price

- If the foil toggle is on (or the foil heuristic produced a foil guess), use `priceUsdFoil`. Fall back to `priceUsd` if foil price is null.
- Otherwise use `priceUsd`. Fall back to `priceUsdFoil` if non-foil is null.
- If both are null, the overlay shows `✓ <name>` with no price, and no sound fires.

### Sound

- Asset: `assets/sounds/cash_register.mp3` (copied from `C:\Users\Krs19\Downloads\cash-register-sound-fx_HgrEcyp.mp3`).
- Plays once when transitioning into the matched state with `price > threshold`.
- Played via `audioplayers` package with a preloaded `AudioPlayer` created at app start (one instance, reused).

### Threshold setting

- New entry in `SettingsScreen`: `Value alert threshold ($)` with the current value as subtitle. Tapping opens a dialog with a numeric text field.
- Default: `$1.00`.
- Persisted via `shared_preferences` (key: `value_alert_threshold_usd`).
- Wrapped in an `AppSettings` service (extends `ChangeNotifier`), constructed in `Deps` at app start. Scanner reads `settings.valueAlertThreshold` at match-done time.

## Data model

### Pipeline change (match-before-save)

Currently, `ScanPipeline.captureFromWarpedCrop` always inserts a pending scan row and then fires the matcher as `unawaited(...)`. The matcher updates the row in-place if it finds a match; unmatched OCR sits in the review queue as a "scan" with no matched card.

New flow:

1. OCR both regions, parse.
2. Run match (exact by set+number first, else fuzzy by name). No DB writes yet.
3. If match is null (not found) → return `null`. No scan inserted, no thumbnail saved.
4. If match raises a network error or times out → return a sentinel `PipelineError.offline`. No scan inserted.
5. If match succeeds → save thumbnail, insert scan row with all matched fields populated, auto-confirm if `confidence >= 0.8` (moves existing logic out of the matcher).

Return type becomes `Future<CaptureResult?>` where `CaptureResult` carries `(id, matchedName, price, outcome)` — outcome enum: `matched | noMatch | offline`.

### ScanMatcher change

`matchAfterInsert({scanId, parsed})` → `match(parsed)` returning `Future<MatchResult?>`. No DB side-effects. `MatchResult` carries the `ScryfallCard` + confidence.

Error classification:
- `ScryfallNotFound` (404 on exact, no fuzzy candidate) → return `null` → pipeline outcome `noMatch`.
- `ScryfallException` (network failure, 5xx, rate-limit, timeout) → rethrow → pipeline catches and returns outcome `offline`.
- Any other exception → rethrow to surface as a bug; not silently swallowed.

### ScannerState

Add a new phase `matching` between `processing` and `done`. Add a nullable `lastCardPrice` field alongside `lastCardLabel`. Add `toMatching()`, extend `toDone(String label, double? price, int newInQueue)`, add `toNoMatch()` and `toOffline()` for the two unsaved outcomes (they use existing phases or a new terminal state that renders the `✗` / `⚠` message).

### Scanner flow in `_onFrame`

```
capture → toCapturing → warp → toProcessing →
  res = await pipeline.capture(...)
  if paused → return (existing rollback no longer needed; pipeline didn't insert)
  switch res.outcome:
    matched   → toMatching (already) ; toDone(name, price) ; maybe play sound
    noMatch   → toNoMatch
    offline   → toOffline
  delay 700 ms ; toSearching ; tracker.reset
```

Note: the existing "pause mid-capture rolls back the scan via `scans.reject`" guard becomes unnecessary because no row is inserted until the match succeeds. Remove that rollback call.

## Files touched

- `lib/features/scanner/scanner_state.dart` — new phase, price field, helpers
- `lib/features/scanner/scanner_screen.dart` — overlay states, sound trigger, settings read, remove rollback-reject
- `lib/features/scanner/scan_pipeline.dart` — match-before-save flow, new return type
- `lib/features/scanner/scan_matcher.dart` — strip DB side-effects, return `MatchResult?`, let exceptions propagate
- `lib/features/settings/settings_screen.dart` — threshold entry with dialog
- `lib/app_settings.dart` *(new)* — `ChangeNotifier` wrapper around `shared_preferences`
- `lib/app.dart` — wire `AppSettings` + preloaded `AudioPlayer` into `Deps`
- `pubspec.yaml` — add `audioplayers`, register `assets/sounds/` directory
- `assets/sounds/cash_register.mp3` *(new)* — copied from user's Downloads

## Non-goals

- No session-level counter for unmatched scans (silent drops).
- No background retry of failed Scryfall lookups.
- No change to the review queue behaviour beyond the fact that it stops receiving unmatched rows.
- No change to the foil heuristic itself.
