# MTG Card Scanner — Design

**Date:** 2026-04-14
**Status:** Draft, awaiting user review

## Purpose

A free, login-free Android app (Flutter, portable to iOS later) that scans Magic: The Gathering cards in real time via the phone camera, identifies each card including its specific printing, and exports the collection in formats Moxfield accepts (text list + CSV). Built because existing scanners are paid, require accounts, or can't export.

## Constraints & Non-goals

- No backend, no user accounts, no cloud sync. All data local.
- Online required (Scryfall REST API used live; no bulk data download).
- Android first. Flutter chosen so iOS port is cheap later.
- Not a deck builder, not a marketplace — scanning, pricing display, and exporting only. Prices are shown to help the user decide bin placement (bulk / binder / etc.) but the app does no price tracking or alerting.

## High-Level Architecture

Flutter app, single process, layered:

- **Camera/Scan layer** — `camera` plugin for live preview. Per-frame rectangle/edge detection (via `opencv_dart` or `google_mlkit_document_scanner`) determines when a card is steady in view.
- **Recognition layer** — on stable-frame trigger, perspective-corrects the card crop and runs `google_mlkit_text_recognition` on two regions (title, bottom collector strip). A foil heuristic (specular highlight detection) produces a low-confidence boolean.
- **Lookup layer** — Scryfall REST client. Prefers `/cards/{set}/{number}` when set + collector number are readable; falls back to `/cards/named?fuzzy={name}`. Session-scoped in-memory cache. Each response's `prices.usd` and `prices.usd_foil` are captured and persisted with the card.
- **Storage layer** — local SQLite via `drift`. Tables: `scans` (review queue) and `collection`.
- **UI layer** — three primary screens: Scanner, Review Queue, Collection/Export.

**Data flow:** camera frame → stability detector → OCR → Scryfall lookup → review queue → user confirms → collection → export.

## Scanning Pipeline

Scanner state machine:

1. `searching` — no card detected; overlay hint "point at card".
2. `tracking` — card rectangle detected but moving; live bounding box drawn.
3. `capturing` — rectangle stable (<5px jitter for 300ms) → freeze-frame flash, OCR runs.
4. `processing` — OCR + Scryfall lookup running async (~200–800ms); scanner locked.
5. `done` — brief toast "✓ {card} ({set}) · ${price} added" + subtle beep → back to `searching`.
6. `ambiguous` — toast "⚠ needs review" + scan enters queue with low-confidence flag.

**OCR regions** (normalized to card aspect after perspective correction):

- Name: top ~8% of card, excluding mana-symbol region on the right edge.
- Set + collector number: bottom ~5%, left ~40% (modern frame). Fallback to center-bottom region for older frames.
- Foil heuristics — two independent signals are combined:
  1. **Specular highlight detection** on the full crop (foils exhibit stronger, hue-shifting highlights under motion/tilt; since scans are single-frame, this is a weaker signal and fires only on clearly rainbow/high-saturation highlights).
  2. **Foil stamp detection** in the region below the text box (center-bottom ~10% strip). Both the standard holofoil oval and star-shaped stamps (Collector Booster, promo printings) are detected via shape/template matching on a binarized crop. Any stamp matching a known foil-variant template contributes a foil vote; the standard oval alone does not.
  - Combined result: if either signal votes foil, `foil_guess = 1`; if both agree, confidence on the foil flag is raised and the review queue pre-checks the foil toggle rather than just flagging it. A mismatch between signals also pre-checks foil but surfaces a small "verify foil?" hint.

**Duplicate guard:** no re-trigger on the same card unless either (a) scanner has left `tracking` for ≥500ms or (b) OCR result differs from the previous capture.

**Confidence scoring** (0–1):

- Exact match via `/cards/{set}/{number}` → 1.0
- Fuzzy name match → 0.6
- Low-quality OCR (short/garbled name) → 0.3

Items ≥ 0.8 auto-move to collection (user-configurable); items < 0.8 stay flagged in the review queue.

## Data Model

SQLite via `drift`.

### `scans` (review queue)

| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| captured_at | TIMESTAMP | |
| raw_name | TEXT | OCR output pre-match |
| raw_set_collector | TEXT | OCR output |
| matched_scryfall_id | TEXT NULL | |
| matched_name | TEXT NULL | |
| matched_set | TEXT NULL | 3-letter set code |
| matched_collector_number | TEXT NULL | |
| confidence | REAL | 0–1 |
| foil_guess | INTEGER | 0 / 1 / -1 unknown |
| crop_image_path | TEXT | thumbnail in app docs dir |
| price_usd | REAL NULL | from Scryfall `prices.usd` at match time |
| price_usd_foil | REAL NULL | from Scryfall `prices.usd_foil` at match time |
| status | TEXT | `pending` \| `confirmed` \| `rejected` |

### `collection` (confirmed inventory)

| Column | Type | Notes |
|---|---|---|
| id | INTEGER PK | |
| scryfall_id | TEXT | |
| name | TEXT | |
| set_code | TEXT | |
| collector_number | TEXT | |
| count | INTEGER | merged per printing+foil+condition+language |
| foil | INTEGER | 0 / 1 |
| condition | TEXT | `NM` default; `LP` / `MP` / `HP` / `DMG` |
| language | TEXT | `en` default |
| added_at | TIMESTAMP | |
| price_usd | REAL NULL | latest Scryfall `prices.usd` |
| price_usd_foil | REAL NULL | latest Scryfall `prices.usd_foil` |
| price_updated_at | TIMESTAMP NULL | when price was last refreshed |
| notes | TEXT NULL | |

**Merge rule on confirm:** if a row exists with the same `scryfall_id + foil + condition + language`, increment `count` and update its price fields from the scan; else insert a new row carrying the scan's captured price.

Crop thumbnails live under the app's documents directory, referenced by path, and are deleted when the owning scan is confirmed or rejected.

## UX

### Scanner screen

Full-screen camera preview; bounding-box overlay while tracking; small counter badge top-right ("12 in queue · 47 confirmed"); tap badge → Review Queue. Torch toggle + pause button. Auto-pauses after 60s idle in `searching` to save battery.

### Review Queue screen

List of pending scans, newest first. Each row: thumbnail + matched Scryfall art, name, set code, collector number, price in USD (foil price shown if foil toggle is on), confidence %, foil toggle, condition dropdown (NM default), language dropdown (en default), Confirm / Reject / Edit buttons.

**Edit** opens a modal with `/cards/autocomplete`-backed search to fix the name, then lists all printings of that name to pick from — the escape hatch for failed OCR.

Bulk actions bar: "Confirm all ≥90%", "Clear rejected", "Re-run lookup on failed" (useful when offline scans come back online).

### Collection screen

Grouped by set by default; sortable by name / price / date-added. Rows show count, foil marker, and price (USD, or foil USD when foil). A running total of the visible filter is displayed at the top ("Showing 134 cards · $247.30"). Tap row → detail with notes, quantity edit, delete, and manual "refresh price" button. A global **Refresh all prices** action in settings re-fetches every card's price via Scryfall (rate-limited, progress-shown). Search bar.

### Export screen

Format dropdown (Moxfield text / CSV). Scope dropdown (all / single set / filtered by search / only items added since last export). Preview pane shows first ~20 lines. Actions: **Copy to clipboard**, **Share** (native share sheet), **Save to Downloads**.

## Export Formats

### Moxfield text

```
4 Lightning Bolt (2XM) 137
1 Lightning Bolt (2XM) 137 *F*
2 Snapcaster Mage (MM3) 58
```

Foils get trailing `*F*`. Condition and language are not expressible; a warning is shown if any selected items have non-default values.

### CSV (Moxfield collection import compatible)

```
Count,Tradelist Count,Name,Edition,Condition,Language,Foil,Tags,Last Modified,Collector Number
4,0,Lightning Bolt,2XM,NM,English,,,2026-04-14 12:00:00,137
1,0,Lightning Bolt,2XM,NM,English,foil,,2026-04-14 12:00:00,137
```

Conditions map to Moxfield's labels (`NM` → Near Mint, `LP` → Played, etc.). Language uses Moxfield's full names (`English`, `Japanese`, ...).

Scope options: all / specific set / filter by search / only items added since last export (tracked via `last_exported_at` in shared prefs).

## Error Handling & Edge Cases

- **Network down during scan** — scan is queued with raw OCR data, `status=pending`, `matched_*` NULL. Queue shows it as "needs lookup" with Retry; bulk retry available.
- **OCR returns garbage** — fuzzy Scryfall lookup fails → scan goes to queue flagged, thumbnail preserved, user can Edit.
- **Ambiguous collector number** — `/cards/{set}/{number}` 404 → fall back to fuzzy name search.
- **Scryfall rate limit (10 req/s)** — single-flight request queue with 100ms minimum gap; bulk ops throttle automatically.
- **Older-frame cards (pre-2003, no collector number)** — collector-number OCR fails → automatic fallback to name + set-symbol heuristic, flagged lower confidence.
- **Double-sided cards** — Scryfall returns them correctly; UI shows front face. No special handling needed.
- **Camera permission denied** — graceful denial screen with deep-link to system settings.
- **Database corruption / reinstall** — settings screen offers JSON backup export; restore from JSON on new install.
- **Battery/thermal** — scanner auto-pauses after 60s idle in `searching`; preview dims with "tap to resume."
- **Missing price data** — Scryfall occasionally returns `null` for `prices.usd` (promos, unreleased printings); UI shows `—` in place of a price and excludes the row from total sums.
- **Stale prices** — `price_updated_at` older than 7 days is rendered in a muted color; bulk refresh available from settings.

## Testing

- **Unit tests:** OCR-result parser (name cleanup, collector-number regex), Scryfall client (mocked responses), export formatters (text + CSV golden-file tests), collection merge rule.
- **Widget tests:** review queue interactions (confirm / reject / edit), export preview rendering.
- **Integration tests:** end-to-end scan → review → confirm → export against pre-recorded camera frames + mocked Scryfall.
- **Manual regression set:** ~30 reference card photos in `test/fixtures/` covering modern frame, old frame, foil oval-stamp, foil star-stamp, non-foil rare (oval stamp only), promo, double-faced, non-English. Foil-detection accuracy is evaluated against this set as a dedicated test.

## Project Location

`C:\Users\Krs19\Dev\mtg-scanner\` (WSL path: `/mnt/c/Users/Krs19/Dev/mtg-scanner/`)
