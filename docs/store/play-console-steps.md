# Play Console Walkthrough — IA Helper

Step-by-step from "nothing on Google Play" to "staged rollout in production."
Listing copy lives in google-play-listing.md; this file covers the console side.

## 0. One-time account setup

- [ ] Create a Play Console developer account (25 USD, one-time): https://play.google.com/console
- [ ] Accept **Play App Signing** when prompted (recommended): Google manages the app
      signing key; you only manage the upload key. If you ever lose the upload key,
      you can request a reset instead of losing the app forever.

## 1. Upload keystore + repo secrets (15 min, local)

Generate the key ONCE, keep the file forever, back it up offline:

    keytool -genkey -v -keystore upload-keystore.jks \
      -keyalg RSA -keysize 2048 -validity 10000 -alias ia-upload

Then encode it and add four GitHub repo secrets (Settings → Secrets and variables → Actions):

    base64 -w0 upload-keystore.jks

- ANDROID_KEYSTORE_BASE64 — output of the command above
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS (ia-upload)
- ANDROID_KEY_PASSWORD

If the secrets are missing, the release workflow fails fast by design — it will not
ship a debug-signed bundle as a release.

## 2. Build the signed AAB (automatic)

    git tag v1.7.1 && git push origin v1.7.1

The "Play Store Release Build" workflow (.github/workflows/play-release.yml) builds the
signed production AAB and attaches it to the GitHub Release. Version name comes from the
tag; version code from the commit count — both automatic via the gradle git integration.

## 3. Create the app in Play Console

- All apps → Create app
- Name: IA Helper – Internet Archive
- Default language: en-US, App (not game), Free

## 4. Store listing

Paste everything from docs/store/google-play-listing.md:
title, short description, full description, graphics per the asset checklist.

Privacy policy URL (required): host PRIVACY_POLICY.md via the existing GitHub Pages
site (add a link on the landing page), or use this stopgap:
https://github.com/Gameaday/ia-helper/blob/main/PRIVACY_POLICY.md

## 5. Data safety form (answers pre-decided)

- "Does your app collect or share any of the required user data types?" → **No**
- Nothing is transmitted off-device; no analytics, no accounts, no ads.
- Result: the "No data collected" badge — screenshot it; it belongs in the launch posts.

## 6. MANAGE_EXTERNAL_STORAGE declaration (the one real review risk)

AndroidManifest.xml requests MANAGE_EXTERNAL_STORAGE (all files access). Play treats
this as a sensitive permission: it needs a written declaration plus a demo video, and
downloader apps that can live without it sometimes get rejected.

- **Option A (preferred):** switch fully to scoped storage / SAF file pickers and
  remove the permission before first submission. No declaration, no review risk.
- **Option B (declare it):** justification draft — "IA Helper is a bulk file downloader
  for the Internet Archive. Its core function is saving user-selected downloads —
  including non-media file types such as PDF, EPUB, TXT and ZIP — to folders the user
  chooses. Media-scoped permissions cannot cover those file types, so the app requests
  all-files access only after the user explicitly enables it in settings." Attach a
  short screen recording of the flow.

Decide BEFORE the first submission; this is the single most likely rejection cause.

## 7. Content rating + target audience

- Content rating questionnaire: utility app, no user-generated content, no mature
  themes → Everyone
- Target audience: 13+ (default for tools)

## 8. Countries + release tracks

- Free; no ads. Start with US/CA/UK/AU, expand to all countries after the first
  crash-free week.
- **Start the Internal testing track IMMEDIATELY after creating the app** — the clock
  matters: personal developer accounts (created after Nov 2023) generally must run a
  closed test with roughly 12 opted-in testers for 14 consecutive days before
  production access. Verify the current exact requirement in the console, and start
  the timer during prep, not after.
- Pipeline: Internal → Closed (testers, 14 days) → Production staged rollout
  (10% → 50% → 100%, watching crash rate + ratings at each step).

## 9. Pre-launch sanity checks

- [ ] Target API 36 (already set — Play's minimum for new apps is 35+)
- [ ] AAB size reasonable; language/density/ABI splits enabled (already in gradle)
- [ ] Run the AAB on the internal track and click through: search → filters →
      batch download → library → metadata view → dark mode
- [ ] Deep links: open an archive.org/details/ link from the browser, confirm the app catches it
