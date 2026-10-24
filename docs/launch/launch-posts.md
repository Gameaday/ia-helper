# Launch Posts — IA Helper (Month 1)

Drafts for the three launch surfaces. Post in this order, one day apart:
r/DataHoarder first (warmest audience), r/InternetArchive second, Show HN third.

---

## 1. r/DataHoarder

**Title:** IA Helper — a free, open-source Internet Archive downloader with batch queues, file-type rules, resume, and bandwidth throttling (Android + web)

**Body:**

I've been maintaining IA Helper for a while — a no-ads, no-tracking companion app for
archive.org. Figured this crowd would appreciate the download mechanics most:

• Batch download queues with priority scheduling
• Include/exclude rules by format, wildcard patterns, subfolders, and file size
• Resume interrupted downloads; auto-retry with exponential backoff
• Bandwidth throttling built in
• Advanced search: media type, year/date ranges, collection, language, field queries
• Everything offline-first: library, collections, metadata
• No ads, no tracking, no accounts — MIT licensed

Try the web version instantly (no install): https://gameaday.github.io/ia-helper/app/
Android APK and source: https://github.com/Gameaday/ia-helper

It'll hit Google Play soon. If you hoard from archive.org regularly, tell me what
workflow would make this your default tool — a one-time Pro tier is coming
(batch collection downloads, metadata export) and I'd rather build what you actually use.

---

## 2. r/InternetArchive

**Title:** I built a free archive.org companion app — no ads, no tracking, and polite to the API

**Body:**

IA Helper is a free, open-source (MIT) app for searching and downloading from the
Internet Archive.

What it does: advanced search across the 35M+ item catalog (media type, date/year
ranges, collections, languages, field-specific queries), batch downloads with resume
and retry, file-type and size rules, and a fully offline library with rich metadata.

The part I care most about, given where we are: it's built to be a good citizen.
Requests go through a rate limiter and bandwidth throttle by default, thumbnail and
metadata caching cut repeat API calls, and page sizes are tuned to keep load light.
The Archive is a nonprofit and the app treats it that way.

No ads, no tracking, no accounts — everything stays on-device.

Web version (works in browser): https://gameaday.github.io/ia-helper/app/
Source: https://github.com/Gameaday/ia-helper

Feedback very welcome — especially from folks doing research or archival work. A
one-time-purchase Pro tier (metadata export, collection-wide downloads) is on the
roadmap; subscriptions are explicitly off it.

---

## 3. Show HN

**Title:** Show HN: IA Helper – A no-ads, no-tracking companion app for the Internet Archive

**Body:**

Hi HN — I built a free, open-source companion app for the Internet Archive (archive.org).

IA Helper searches all 35M+ items with real advanced filters (mediatype, year/date
ranges, collections, languages, field queries) and handles the download side properly:
batch queues, resume, exponential-backoff retries, file-type and size rules, priority
scheduling, and bandwidth throttling. Everything is offline-first — library, collections,
metadata. No ads, no tracking, no accounts.

Built with Flutter (Material Design 3), runs on Android and in the browser. MIT licensed:
https://github.com/Gameaday/ia-helper

One thing I paid attention to: being polite to archive.org. Requests go through a rate
limiter and bandwidth throttle by default, and caching cuts repeat API calls. The
Archive is a nonprofit; the app is built to act like it.

Web version: https://gameaday.github.io/ia-helper/

Would love feedback from anyone doing research or archival work — a one-time Pro tier
(metadata export, collection-wide downloads) is coming, and I'd rather build what
people actually need. No subscriptions, ever.

---

## Posting checklist

- [ ] Check r/InternetArchive rules on self-promotion first; message mods if unsure
- [ ] Add install links to the historylabs.dev archive site the same day
- [ ] Show HN: post Tue–Thu, ~8–10am ET, and stay in the comments for the first 2 hours
- [ ] Answer every comment for 48 hours; log feature requests as GitHub issues
- [ ] Track installs, ratings, and crash rate for the first 72 hours
