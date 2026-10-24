# Pre-Launch Audit — IA Helper (2026-10-24)

> Companion to [ROADMAP](./ROADMAP.md). Re-run this checklist each release until every box is ticked.

## Verdict summary

| Area | Status | One-liner |
|---|---|---|
| Core focus | ✅ strong | Search → download → offline library, one coherent job |
| Scope sprawl | ⚠️ one flag | Web-platform docs and builds exceed the Android-first plan |
| Tier design | ⚠️ conflict | Batch downloads ship free in v1.7.0 but are listed as Pro |
| Polish | ⚠️ gaps | Public privacy-policy URL, support contact, screenshots |
| Store readiness | ✅ nearly | Listing copy, CI, issue templates done; assets pending |

## Core promise & scope check

The promise: *the Internet Archive companion for people who take archiving seriously.* Everything shipped so far serves it — search with real filters, a rules-driven download queue, saved searches, offline library. No feature drift detected in code scope.

**Sprawl flag — web platform.** `docs/` carries a whole web-deployment track (WEBAPP_DEPLOYMENT, WEB_COMPATIBILITY, GITHUB_PAGES_SETUP, WEB_PRELAUNCH_CHECKLIST…). Web is a second platform to test, support, and secure — it dilutes the Android-first quarter. Recommendation: treat the web build as a **read-only demo at most** during Phase 1; delete or archive the web-prelaunch track from active scope. One platform, shipped well, beats two shipped okay. *(Decision: Carl — low risk either way, but say it out loud.)*

## Tier design review — the batch-download conflict

The status audit (2026-10-24) confirmed the **batch download queue ships in the free v1.7.0** — file-type rules, size caps, retries. But the ROADMAP pricing table puts "batch/collection downloads" in **Pro**. That cannot both be true at launch, and the wrong resolution is expensive: paywalling a feature users already have is a one-star-review generator; giving away the flagship Pro feature guts the upgrade reason.

**Recommended split:**

| Feature | Tier | Why |
|---|---|---|
| Search, filters, single + basic batch downloads (queue, retry) | **Free** | Keep as shipped — it is the habit-forming hook and the honest free tier |
| **Collection-wide** downloads (whole-collection rules engine) | **Pro** | The true power-user step-up; nobody casual needs it |
| Metadata export (CSV/JSON, citations) | **Pro** | Researcher workflow, clearly professional |
| Watchlist (new-item checking) | **Pro** | Recurring-value feature |
| Library backup | **Pro** | Existing plan, keep |

This also *strengthens* the free tier story: "even batch downloads are free; Pro is for whole collections and research output." *(Decision: Carl — the audit recommends this split; ROADMAP pricing table should be updated to match once decided.)*

## Professionalism & polish gaps

| Gap | Needed by | Owner |
|---|---|---|
| Public privacy-policy URL (Play Console field requires a hosted URL — GitHub raw or historylabs.dev) | before closed testing | Carl (hosting choice), AI can draft the page |
| Support email in listing + in-app About | before production | Carl |
| Screenshots (phone 7.9" or 16:9 set) + feature graphic | before closed testing | Carl |
| Version labeling: v1.7.0 is pre-store; decide whether the first public release stays 1.7.x or relabels | before first AAB | Carl — recommend keep 1.7.x, changelog explains |
| User-friendly CHANGELOG check (release notes → Play "what's new") | each release | AI |
| In-app: "rate the app" prompt and GitHub issues link (organic reviews matter for ASO) | Month 2 | AI |

Done already and verified: listing copy (docs/store/google-play-listing.md), privacy policy file (PRIVACY_POLICY.md), permissions documentation (docs/ANDROID_PERMISSIONS.md), CI release pipeline, issue templates.

## "As-is" go-live vs 1.0

- **Go-live as-is (November):** v1.7.0 **free-only**, no in-app purchases — nothing about Pro needs to exist on the store yet. This is deliberately the smallest shippable thing.
- **IA Helper 1.0 (the real bar, by end of Jan 2027):** store-listed + staged rollout, Pro IAP live, collection downloader, metadata export, watchlist, 3–4 historylabs.dev tutorials feeding installs, 10 power-user interviews done.

## Ordered pre-launch steps (Nov 2026)

1. Verify contact details in Play Console (Account details → email + phone) — required for keep-alive.
2. Create the app in Play Console; upload the signed AAB to **internal testing** — this alone satisfies the account keep-alive requirement (Google's inactive-account policy explicitly blesses internal testing).
3. Resolve #75 (MANAGE_EXTERNAL_STORAGE) — Option B recommended for speed.
4. Recruit ≥12 closed testers (friends, Discord, one Reddit thread) and promote the build to **closed testing** — the 14-day production clock starts on opt-in, so do this in the first week of November.
5. Host the privacy policy publicly; add support email.
6. After 14 days: apply for production access; staged rollout 10% → 50% → 100%.
7. Launch posts (drafts ready: docs/launch/launch-posts.md).

*Store-track facts above verified against Google Play Help, Oct 2026: inactive-account closure policy and new-personal-account testing requirements (12 testers / 14 days for production access). Re-verify if the upload slips past November.*
