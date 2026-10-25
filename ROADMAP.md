# ROADMAP — IA Helper

> **Phase 1 of the side-hustle year (Nov 2026 – Jan 2027). This is the active phase.**
> Master plan lives in the home repo: side-hustle-master-plan.md

**One-liner:** The Internet Archive companion for people who take archiving seriously.

**Audience:** researchers, genealogists, data hoarders, media collectors.

**Positioning:** no ads, no tracking, no subscriptions — ever. A generous free tier forever;
one Pro payment and it is yours to keep.

## Rules (do not break)

1. Zero marginal cost per user — local-first app; the only shared cost is a static landing page.
2. AI is used to build this app, never served inside it.
3. The free tier stays genuinely useful; Pro means power-user features only.
4. Own-not-rent: one-time Pro purchase. Lifetime updates within v1.
5. Maintenance budget after launch: ≤ 2 hrs/week.

## Status audit (2026-10-24)

The app already ships far more than this roadmap originally assumed (v1.7.0).
Verified against the codebase:

- Collection browsing, year/date ranges, media-type, language filters — **shipped**
  (SearchQuery model + AdvancedSearchService + filters UI)
- Batch download queue with file-type rules, size caps, auto-retry — **shipped**
  (FileFilter: include/exclude formats, wildcard patterns, subfolders, min/max size;
  resumable downloads with exponential backoff; scheduler + bandwidth throttle)
- Saved searches — **shipped** (saved_search_service + screen);
  Month 2 scope narrows to the watchlist variant
- Still genuinely missing: Play Store presence, launch distribution,
  metadata export (CSV/JSON), collection-wide download UX, Pro monetization

**Conclusion: Month 1 is a distribution month, not a build month.**
The engineering got done ahead of schedule; the job now is getting it into hands.

Pre-launch audit (scope, tiers, polish, steps): [PRELAUNCH_AUDIT.md](./PRELAUNCH_AUDIT.md)

## Month 1 (Nov 2026) — Ship the free app everywhere

- [x] Collection browsing + year/media-type filters in search *(shipped in v1.7.0 — audited 2026-10-24)*
- [x] Batch download queue: file-type rules, size caps, auto-retry *(shipped in v1.7.0 — audited 2026-10-24)*
- [ ] **Material Design UI pass (#79) — first priority, before the push** *(theme phase 1 landed `ddce204`: unified light/dark + full M3 component coverage; remaining: hardcoded-color sweep, typography audit, screenshot refresh)*
- [ ] **Keep-alive: upload AAB to internal testing — protects the Play account, smallest possible submission** *(#76, deadline-driven)*
- [ ] Start closed testing with ≥12 testers in week 1 — production access needs 14 continuous days
- [ ] Publish to Google Play *(listing copy ready: docs/store/google-play-listing.md)*
- [ ] Launch posts: r/DataHoarder, r/InternetArchive, Show HN + install links on the historylabs.dev archive site *(drafts ready: docs/launch/launch-posts.md)*

## Month 2 (Dec 2026) — Build the Pro tier

- [ ] Metadata export: CSV/JSON + citation-style records (the researcher's #1 ask) — new build
- [ ] Collection downloader: grab an entire collection with user-defined rules — new build (FileFilter exists; needs collection-level UX)
- [ ] Watchlist: saved searches already ship; the Pro piece is new-item checking on app open (no server, no alerts bill)
- [ ] Pro unlock flow: Play in-app purchase + web storefront license keys

## Month 3 (Jan 2027) — Launch, price, compound

- [ ] Founding launch: $14.99 lifetime for the first 100 buyers, announced to free users
- [ ] Write 3–4 "how to download X from archive.org" tutorials on historylabs.dev, each ending with the app
- [ ] Interview 10 power users; fix the top 3 complaints
- [ ] Gate review (below) — record the result in the master plan review log

## Pricing

| Tier | Price | Includes |
|---|---|---|
| Free | $0 | search + filters, single downloads, library, offline access, metadata viewer |
| Pro | $14.99 founding → $19.99 | batch/collection downloads, metadata export, watchlist, library backup |

⚠️ *Open tier question (2026-10-24): the batch download queue already ships **free** in v1.7.0, but this table lists batch downloads under Pro. See [PRELAUNCH_AUDIT.md](./PRELAUNCH_AUDIT.md) for the recommended split (basic batch stays free; collection-wide downloads are the Pro feature). Decide before the Pro launch — do not paywall a feature users already have.*

## Sales rails

- Android: Google Play in-app purchase (15% service fee on first $1M/yr).
- Web/desktop + lifetime keys: merchant-of-record storefront (Lemon Squeezy-class, ~5% + 50¢, handles global VAT).

## Gate criteria (end of Jan 2027)

- **Green (≥ 30 Pro sales):** Phase 2 (MediaMaid) starts on schedule in February.
- **Yellow (10–30):** delay Phase 2 by one month; deepen IA Helper first.
- **Red (< 10):** no new product in February. Find out why before anything else ships.

**Success targets:** 500–1,000 installs · 30–50 Pro sales (~$500–1,000) · 10 engaged power users.
Even the worst case here ends with a shipped, monetized, open-source app. That is the floor, not the ceiling.
