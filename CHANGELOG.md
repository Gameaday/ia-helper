# Changelog

All notable changes to IA Helper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **CDN URL Preference** - User-configurable CDN vs Direct mode
  - New toggle in Settings → Data & Performance
  - **CDN Mode (Default ON)**: Fast loading, Archive.org's preferred method
    * Uses CDN infrastructure (dn*.archive.org, ia*.archive.org)
    * Archive.org's recommended approach for bandwidth efficiency
    * ⚠️ Causes CORS errors on web browsers
    * Works perfectly on mobile/desktop platforms
  - **Direct Mode (OFF)**: Slower but web-safe fallback
    * Uses /download/ endpoint with CORS headers
    * Works on ALL platforms including web browsers
    * Recommended when experiencing image loading issues
  - Smart defaults: Respects platform (web vs native)
  - Includes helpful info dialog explaining trade-offs
  - Debug logging shows current mode
  - Best of both worlds: Performance + Compatibility option

### Bug Fixes & Improvements (2025-10-09)

#### Fixed
- **Thumbnail URL System** - Intelligent CDN handling with fallback option
  - Stopped using API's `misc.image` field (contains CDN redirect paths)
  - Now generates URLs directly using ArchiveUrlService
  - **Default**: Uses CDN URLs (Archive.org's preferred, faster)
  - **Fallback**: Direct /download/ URLs available in settings
  - Best balance of performance and compatibility
  - User has control based on their platform needs

- **Identifier Validation False Positives** - Search bar no longer shows "Open Archive" button for non-existent identifiers
  - Added `ArchiveService.validateIdentifier()` method with HEAD request validation
  - IntelligentSearchBar now validates identifiers before showing actions
  - Shows loading indicator during validation (500ms debounce)
  - Displays validation status: "Checking...", "Valid archive", or "Archive not found"
  - "Open Archive" button only enabled for validated identifiers
  - Prevents false positives for queries like "mario", "test", etc.
  - Fixes user-reported issue #8

- **Collection Save Messages** - Collection picker now shows accurate feedback
  - Fixed incorrect "Removed from collections" message when no collections selected
  - Messages now based on actual changes (toAdd/toRemove sets)
  - Four cases handled: "No changes", "Added to X", "Removed from X", "Updated (added X, removed Y)"
  - Fixes user-reported issue #6

- **Favorites Not Showing** - Library screen now auto-refreshes when tab becomes visible
  - Added AutomaticKeepAliveClientMixin to preserve state
  - Added didChangeDependencies() to reload data on visibility
  - Favorites, collections, and downloads update immediately after changes
  - Fixes user-reported issue #5

- **URL Standardization - ALL Platforms** - Unified CDN URL handling across web, mobile, and desktop
  - Removed web-only restriction from ArchiveUrlService.fixCorsUrl()
  - ALL platforms now use official archive.org/download/ endpoint
  - Consistent behavior and reliability across platforms
  - Updated statistics to reflect "url_standardization" and "cdn_rewriting_all_platforms"

#### Improved
- **Reduced API Load** - Cut image requests in half
  - Reduced Discover screen page size from 40 to 20 items
  - Maintains good UX while reducing API pressure
  - Search results already at 20 items per page
  - Fewer thumbnails loaded per page = faster initial load

- **Home Screen UX** - Cleaner, more intuitive interface
  - Recent searches now shown as rectangular cards (not chips)
  - Removed "Recent Searches" heading text (obvious from context)
  - Limited to 5 searches to fit on screen without scrolling
  - Search prompt (icon + tips) only shows when NO recent searches
  - When user has history: Clean list of recent items
  - When user clears history: Helpful search tips reappear
  - Better use of vertical space and visual hierarchy
  - Swipe to dismiss still works on recent search cards

#### Technical Details
- ~200 lines modified across 2 files (archive_metadata.dart, home_screen.dart)
- ~140 lines added for identifier validation (archive_service.dart, intelligent_search_bar.dart)
- Zero compilation errors (flutter analyze clean)
- Material Design 3 compliant validation UI with loading states
- Debounced validation (500ms) to reduce API calls
- 5-second timeout on validation requests
- All changes tested and verified

### Backend Services Enhancement (2025-10-09)

#### Added
- **Comprehensive Metrics Tracking** - All 10 priority backend services now include detailed metrics
  - AdvancedSearchService: API intensity tracking with field queries, searches, cache hits
  - ArchiveService: Metadata fetches, file listings, API calls tracking
  - ThumbnailCacheService: LRU cache with hits/misses, evictions, disk usage metrics
  - MetadataCache: Cache operations, size enforcement, batch operations tracking
  - HistoryService: Search analytics, filters, sorts, batch operations
  - LocalArchiveStorage: Storage operations, searches, debouncing
  - BackgroundDownloadService: Download lifecycle tracking (starts, completions, failures, retries)
  - IAHttpClient: HTTP metrics with retries, timeouts, rate limits, errors
  - RateLimiter: Concurrency control with delays and queue tracking
  - BandwidthThrottle: Token bucket metrics with throughput and delay tracking

- **Enhanced Logging** - All services use kDebugMode guards for zero production overhead
  - Consistent `[ServiceName]` prefix format
  - Relevant context included (IDs, counts, states)
  - Important state changes and errors logged

- **Monitoring Methods** - Standard monitoring interface across all services
  - `getMetrics()` - Returns current metrics for monitoring
  - `resetMetrics()` - Clears all counters with logging
  - `getFormattedStatistics()` - Human-readable statistics with percentages and rates

#### Documentation
- Updated `.github/copilot-instructions.md` - Comprehensive Flutter/Dart guidelines
- Added `docs/features/BACKEND_SERVICES_OVERVIEW.md` - Complete overview of all 10 services
- Added `docs/features/BACKGROUND_DOWNLOAD_SERVICE_PHASE_1.md` - Download service enhancement
- Added `docs/features/IA_HTTP_CLIENT_ENHANCEMENT.md` - HTTP client metrics
- Added `docs/features/RATE_LIMITER_ENHANCEMENT.md` - Concurrency control metrics
- Added `docs/features/BANDWIDTH_THROTTLE_ENHANCEMENT.md` - Bandwidth throttling metrics

#### Technical Details
- ~1,100+ lines of production code added
- Zero compilation errors (flutter analyze clean)
- Consistent patterns across all services for maintainability
- Zero production overhead (all logging behind kDebugMode guards)
- Production-ready with comprehensive monitoring capabilities

#### Quality
- ✅ All warnings fixed (CI/CD compliance)
- ✅ Material Design 3 compliant
- ✅ Null safety throughout
- ✅ Comprehensive dartdoc comments
- ✅ Integration examples provided
- ✅ Troubleshooting guides included

---

## [1.0.0] - 2025-10-XX (Upcoming)

### Added
- 📥 Full download management with resume capability
- 🔍 Advanced search across 35+ million Internet Archive items
- 📚 Library organization with collections and tags
- ⚡ Smart download queue with priority management
- 🌙 Complete Material Design 3 UI with dark mode
- 🔐 Privacy-focused design (no tracking or ads)
- 📊 Download scheduling and network-aware pausing
- 🎨 Beautiful, accessible interface (WCAG AA+ compliant)
- 📱 Tablet-optimized layouts with master-detail views
- 🔄 Automatic retry with exponential backoff
- 💾 Offline access to downloaded content
- 🏷️ Rich metadata viewer for Internet Archive items

### Technical
- Built with Flutter 3.35.0
- Material Design 3 compliance (~98%)
- SQLite database for local storage
- Product flavors (development, staging, production)
- Comprehensive test coverage
- CI/CD with GitHub Actions

---

**Repository**: https://github.com/gameaday/ia-helper  
**Issues**: https://github.com/gameaday/ia-helper/issues
