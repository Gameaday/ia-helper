# Internal Testing Readiness — IA Helper (2026-10-24)

> Technical pre-flight for the first AAB upload (#76). Everything verified here was checked against the repo, not assumed.

## Verified ready ✅

| Item | Evidence |
|---|---|
| Target/compile SDK | API 36 (2026 Play-compliant) in `android/app/build.gradle` |
| Release build | `flutter build appbundle --release --flavor production`; production flavor has no applicationId suffix |
| AAB optimization | language/density/ABI splits enabled; x86 removed; minify + resource shrink on |
| Versioning | versionName from the latest `v*` git tag; versionCode from commit count |
| Release CI | `play-release.yml` builds the signed AAB on a `v*` tag, attaches it to the GitHub Release, and **fails fast if signing secrets are missing** |
| Privacy policy | `PRIVACY_POLICY.md` exists (needs a public URL before closed testing) |
| Support contact | gameaday.project@gmail.com in README — use it in the Play listing too |
| Listing copy | `docs/store/google-play-listing.md` staged |
| Store walkthrough | `docs/store/play-console-steps.md` staged |
| Repo hygiene | scratch files removed; README badge now points at the real applicationId |

## Blockers before the first AAB (all Carl-side) ⛔

- [ ] **Tag `v1.7.0`** — the build version comes from git tags; without a tag the AAB reports 1.0.0.
- [ ] Upload keystore + the 4 `ANDROID_*` repository secrets (one-time, see `docs/store/play-console-steps.md`).
- [ ] Play Console → Account details: verify contact email + phone (required by the keep-alive policy).
- [ ] Create the app entry in Play Console (package: `com.gameaday.internet_archive_helper`).

## Then the upload sequence

1. Push the tag → CI builds and attaches the AAB.
2. Upload to **internal testing** — the account is now keep-alive safe (Google's inactive-account policy explicitly accepts internal testing).
3. Before **closed testing**: resolve #75 (MANAGE_EXTERNAL_STORAGE — Option B recommended), host the privacy policy at a public URL, add screenshots.
4. Recruit ≥12 closed testers in week 1 of November (production access needs 12 testers opted in continuously for 14 days).

## Local-build caution

`build.gradle` falls back to the debug keystore with only a console warning when `key.properties` is absent — fine in CI (which fails fast on missing secrets), but a **local** release build can silently debug-sign. If building locally for upload, confirm the release output is signed with the upload key before submitting.

## Not blockers for internal testing (tracked elsewhere)

- MANAGE_EXTERNAL_STORAGE review risk → #75 (decision needed before closed testing, not before internal upload).
- Pro tier / IAP → Month 2 scope; the November submission is free-only.
- Batch-download tier question → PRELAUNCH_AUDIT.md (decide before the Pro launch).
