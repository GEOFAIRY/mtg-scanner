# Privacy Policy — MTG Scanner

*Last updated: 2026-04-16*

MTG Scanner is an Android application developed by GeoFairy ("we", "us") that lets you catalogue your personal Magic: The Gathering card collection using your phone's camera. This policy explains what information the app handles and why.

## Summary

- **We do not collect, store, or transmit personal information.** There are no accounts, no logins, no analytics, no advertising, and no cloud sync.
- Everything you scan stays on your device.
- The app talks to one third party — Scryfall — solely to look up card details from publicly available data.

## Information the app uses

### Camera
The app requires the **CAMERA** permission to scan cards. Camera frames are processed entirely on your device and are used only to:
- Detect the card's outline and orientation.
- Run on-device optical character recognition (OCR) via Google's ML Kit on Device Text Recognition, which processes images locally and does not transmit them over the network.

Camera frames are never saved, uploaded, or shared.

### Device storage
The app stores your scanned collection locally on your device in an app-private SQLite database. You control this data — it stays on the device unless you explicitly export it via the in-app "Export JSON backup" function, at which point the file is handed to the Android share sheet for you to route wherever you choose.

### Scryfall API
When you scan or manually add a card, the app sends the card's name, set code, and collector number to the Scryfall API (https://scryfall.com) to look up official card details, images, and prices. No personally identifying information is sent — only the card query. Scryfall's own privacy policy is at https://scryfall.com/privacy.

## What we don't do

- We don't collect analytics, crash reports, advertising identifiers, or device fingerprints.
- We don't serve advertising.
- We don't share data with any third party other than the Scryfall card lookup described above.
- We don't require an account.

## Children's privacy

The app does not knowingly collect personal information from anyone, including children. No account registration is required to use the app.

## Changes to this policy

If this policy changes, the "Last updated" date above will be revised. Because no personal data is collected, material changes are unlikely.

## Contact

Questions about this policy: **kstagg@overcyte.com**
