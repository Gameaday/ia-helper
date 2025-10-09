# GitHub Copilot Instructions for IA Helper (Flutter App)# GitHub Copilot Instructions for IA Helper (Flutter App)



## Project Overview## Project Overview

IA Helper is a Flutter mobile application for browsing, searching, and downloading content from the Internet Archive. The app provides an intuitive, Material Design 3 compliant interface for discovering and managing Internet Archive collections on mobile devices.

IA Helper is a Flutter mobile application for browsing, searching, and downloading content from the Internet Archive (archive.org). The app provides an intuitive, Material Design 3 compliant interface for discovering and managing Internet Archive collections on mobile, tablet, and web platforms.

**Current Phase**: Phase 5 - App Polish & Play Store Preparation (95% complete)

**Current Status**: 

- **Phase**: Phase 5 - App Polish & Play Store Preparation (95% complete)## 🎯 PARAMOUNT PRINCIPLES

- **Branch**: `smart-search` (active development)

- **Target Platforms**: Android, Web, iOS (future)### Material Design 3 Excellence (TOP PRIORITY)

- **Flutter Version**: 3.35.5**Material Design 3 (MD3) compliance is MANDATORY for ALL UI development.**

- **Dart Version**: 3.9.2

- ✅ **All UI components MUST follow Material Design 3 specifications**

**Key Features**:- ✅ Use MD3 color system (primary, secondary, tertiary, error containers)

- Advanced search with 20+ fields and filters- ✅ Use MD3 typography scale (displayLarge → bodySmall)

- Smart search with API intensity tracking- ✅ Follow MD3 spacing (4dp grid: 4, 8, 12, 16, 24, 32, 48, 64)

- Download management with background downloads- ✅ Use MD3 elevation levels (0, 1, 2, 3, 4, 5)

- Favorites, history, and saved searches- ✅ Implement MD3 motion system (emphasized, standard, decelerate, accelerate curves)

- Metadata caching and thumbnail management- ✅ Follow MD3 component guidelines (buttons, cards, dialogs, navigation, etc.)

- Bandwidth throttling and rate limiting- ✅ Use MD3 shapes (small: 8dp, medium: 12dp, large: 16dp, extra-large: 28dp)

- Comprehensive metrics and monitoring across all backend services- ✅ Maintain **~98%+ MD3 compliance** at all times

- 📚 Reference: https://m3.material.io/

---

### Android Framework Guidelines

## 🎯 PARAMOUNT PRINCIPLES- Follow Android design principles and UX patterns

- Respect platform conventions (back button, navigation, system UI)

### 1. Material Design 3 Excellence (TOP PRIORITY)- Use adaptive layouts for tablets, foldables, and large screens

- Implement proper deep linking and intent handling

**Material Design 3 (MD3) compliance is MANDATORY for ALL UI development.**- Follow Android best practices for battery, performance, and memory



#### Core Requirements### Accessibility & Inclusive Design (WCAG AA+ Required)

- ✅ **All UI components MUST follow Material Design 3 specifications**- ✅ **100% WCAG AA+ compliance MANDATORY**

- ✅ Use MD3 color system (primary, secondary, tertiary, error containers)- Proper contrast ratios for all text and interactive elements (4.5:1 minimum)

- ✅ Use MD3 typography scale (displayLarge → bodySmall)- Full screen reader (TalkBack) support with semantic labels

- ✅ Follow MD3 spacing (4dp grid: 4, 8, 12, 16, 24, 32, 48, 64)- Support dynamic font scaling (respect user text size preferences)

- ✅ Use MD3 elevation levels (0, 1, 2, 3, 4, 5)- Minimum touch target size: 48x48dp

- ✅ Implement MD3 motion system (emphasized, standard, decelerate, accelerate curves)- Dark mode MUST work flawlessly with all features

- ✅ Follow MD3 component guidelines (buttons, cards, dialogs, navigation, etc.)- Support dynamic color schemes (Material You)

- ✅ Use MD3 shapes (small: 8dp, medium: 12dp, large: 16dp, extra-large: 28dp)- Test with accessibility scanner tools

- ✅ Maintain **~98%+ MD3 compliance** at all times

- 📚 **Reference**: https://m3.material.io/### Responsive Design (Web & Large Screens)

- ✅ **All screens MUST be responsive** for web, tablets, and desktop

#### Common MD3 Components- Use `LayoutBuilder` and `MediaQuery` for adaptive layouts

- `FilledButton`, `OutlinedButton`, `TextButton`, `ElevatedButton`- Breakpoints:

- `Card` with proper elevation and shapes  - **Phone Portrait**: <600dp width (1-2 columns)

- `NavigationBar`, `NavigationRail`, `NavigationDrawer`  - **Phone Landscape / Small Tablet**: 600-900dp (2-3 columns)

- `BottomSheet`, `Dialog`, `Snackbar`  - **Tablet**: 900-1200dp (3-4 columns)

- `TextField` with proper decoration and states  - **Desktop / Large Tablet**: >1200dp (4-5 columns)

- `Chip`, `FilterChip`, `ChoiceChip`- Use `Expanded`, `Flexible`, and constraints properly

- `ListTile` with proper leading/trailing/subtitle structure- Navigation: Bottom nav (phone) → Navigation rail (tablet) → Nav drawer (desktop)

- Consider horizontal and vertical space utilization

### 2. Responsive Design (Web & Large Screens)- Test on web, Android phones, tablets, and desktop



**ALL screens MUST be responsive** for web, tablets, and desktop.---



#### Breakpoints## Development Standards

- **Phone Portrait**: <600dp width → 1-2 columns, bottom navigation

- **Phone Landscape / Small Tablet**: 600-900dp → 2-3 columns, navigation rail### Environment Setup

- **Tablet**: 900-1200dp → 3-4 columns, navigation rail or drawer- Flutter may not be available in the Copilot environment

- **Desktop / Large Tablet**: >1200dp → 4-5 columns, navigation rail/drawer- When Flutter is unavailable:

  - Focus on Dart code correctness and syntax

#### Implementation Guidelines  - Use static analysis by reading existing code patterns

- Use `LayoutBuilder` and `MediaQuery` for adaptive layouts  - Verify against Dart language specs and Flutter best practices

- Use `Expanded`, `Flexible`, and constraints properly  - Check imports, types, and API compatibility manually

- Navigation: Bottom nav (phone) → Navigation rail (tablet) → Nav drawer (desktop)

- Consider horizontal AND vertical space utilization### Flutter Best Practices

- Test on web, Android phones, tablets, and desktop- **Use `flutter analyze` for static analysis** (when available)

- Use `GridView` with responsive column counts- **CRITICAL: CI/CD treats ALL warnings as errors** - fix them immediately

- Implement proper scroll behavior for all screen sizes- Prefer explicit types over `var` for clarity

- Use proper null safety (`?`, `!`, `??`, `?.`)

#### Example Pattern- Use const constructors wherever possible for performance

```dart- Avoid rebuilding widgets unnecessarily (use `const`, keys, and memoization)

LayoutBuilder(- Follow Flutter performance guidelines (avoi
  builder: (context, constraints) {
    final isPhone = constraints.maxWidth < 600;
    final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
    final isDesktop = constraints.maxWidth >= 1200;
    
    final columns = isPhone ? 2 : (isTablet ? 3 : 4);
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: isPhone ? 0.7 : 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      // ...
    );
  },
);
```

### 3. Accessibility & Inclusive Design (WCAG AA+ Required)

**100% WCAG AA+ compliance is MANDATORY.**

#### Requirements
- ✅ Proper contrast ratios for all text and interactive elements (4.5:1 minimum)
- ✅ Full screen reader (TalkBack) support with semantic labels
- ✅ Support dynamic font scaling (respect user text size preferences)
- ✅ Minimum touch target size: 48x48dp
- ✅ Dark mode MUST work flawlessly with all features
- ✅ Support dynamic color schemes (Material You)
- ✅ Test with accessibility scanner tools

#### Implementation
- Use `Semantics` widget for screen reader support
- Provide meaningful labels for all interactive elements
- Ensure sufficient color contrast in both light and dark modes
- Use `ExcludeSemantics` for decorative elements
- Test with TalkBack enabled on Android
- Support text scaling up to 200%

### 4. Android Framework Guidelines

- Follow Android design principles and UX patterns
- Respect platform conventions (back button, navigation, system UI)
- Use adaptive layouts for tablets, foldables, and large screens
- Implement proper deep linking and intent handling
- Follow Android best practices for battery, performance, and memory
- Support Android 5.0+ (API 21+)

---

## Development Standards

### Flutter & Dart Best Practices

#### Code Quality
- **Use `flutter analyze` for static analysis** (when available)
- **CRITICAL: CI/CD treats ALL warnings as errors** - fix them immediately
- Prefer explicit types over `var` for clarity
- Use proper null safety (`?`, `!`, `??`, `?.`)
- Use const constructors wherever possible for performance
- Avoid rebuilding widgets unnecessarily (use `const`, keys, and memoization)
- Follow Flutter performance guidelines (avoid expensive operations in `build()`)
- Use `ListView.builder` and `GridView.builder` for large lists
- Implement proper error handling with try-catch blocks

#### State Management
- **Current pattern**: Provider + ChangeNotifier
- Use `Provider.of<T>(context, listen: false)` for non-rebuilding access
- Use `Consumer<T>` or `context.watch<T>()` for rebuilding widgets
- Keep providers focused and single-purpose
- Avoid holding BuildContext in async operations

#### Metrics & Monitoring Pattern
**All backend services follow this pattern:**

```dart
class ServiceMetrics {
  int operation1 = 0;
  int operation2 = 0;
  // ... other metrics
  
  @override
  String toString() => 'ServiceMetrics(operation1: $operation1, ...)';
}

class MyService {
  final ServiceMetrics metrics = ServiceMetrics();
  
  Future<void> someOperation() async {
    metrics.operation1++;
    
    if (kDebugMode) {
      debugPrint('[MyService] Operation details...');
    }
    
    // ... operation logic
  }
  
  ServiceMetrics getMetrics() => metrics;
  
  void resetMetrics() {
    metrics.operation1 = 0;
    metrics.operation2 = 0;
    
    if (kDebugMode) {
      debugPrint('[MyService] Metrics reset');
    }
  }
  
  String getFormattedStatistics() {
    // Return multi-line formatted string with percentages, rates, etc.
  }
}
```

#### Logging Standards
- **Always use `kDebugMode` guards** for zero production overhead
- Use consistent `[ServiceName]` prefix format
- Include relevant context (IDs, counts, states)
- Log important state changes and errors
- Example: `debugPrint('[AdvancedSearchService] Search started: $query')`

#### Performance Considerations
- Use `kDebugMode` guards for all logging (zero production overhead)
- Metrics are simple counters (minimal overhead)
- Thread-safe operations within synchronized contexts
- Efficient token bucket algorithms for throttling
- LRU caching with proper size limits

---

## Project Structure

### Core Directories

```
lib/
├── main.dart                          # App entry point
├── core/                              # Core utilities and constants
│   ├── constants/                     # App-wide constants
│   ├── errors/                        # Error handling
│   ├── extensions/                    # Dart extensions
│   ├── mixins/                        # Reusable mixins
│   └── utils/                         # Utility functions
├── database/                          # SQLite database
│   └── database_helper.dart           # Database management
├── models/                            # Data models
│   ├── archive_metadata.dart          # Archive item metadata
│   ├── search_query.dart              # Search queries
│   ├── download_task.dart             # Download tasks
│   ├── favorite.dart                  # Favorites
│   └── ... (20+ model files)
├── providers/                         # State management
│   ├── bandwidth_manager_provider.dart
│   ├── download_provider.dart
│   └── ...
├── screens/                           # UI screens
│   ├── home_screen.dart               # Main home screen
│   ├── advanced_search_screen.dart    # Advanced search UI
│   ├── search_results_screen.dart     # Search results display
│   ├── archive_detail_screen.dart     # Item details
│   ├── download_screen.dart           # Downloads management
│   └── ... (15+ screen files)
├── services/                          # Backend services (10 enhanced)
│   ├── advanced_search_service.dart   # ✅ Enhanced with API intensity
│   ├── archive_service.dart           # ✅ Enhanced with metrics
│   ├── thumbnail_cache_service.dart   # ✅ Enhanced with LRU cache
│   ├── metadata_cache.dart            # ✅ Enhanced with metrics
│   ├── history_service.dart           # ✅ Enhanced with analytics
│   ├── local_archive_storage.dart     # ✅ Enhanced with metrics
│   ├── background_download_service.dart # ✅ Enhanced Phase 1 complete
│   ├── ia_http_client.dart            # ✅ Enhanced with HTTP metrics
│   ├── rate_limiter.dart              # ✅ Enhanced with concurrency metrics
│   ├── bandwidth_throttle.dart        # ✅ Enhanced with throttle metrics
│   └── ... (25+ service files)
├── utils/                             # Utilities
│   └── ...
└── widgets/                           # Reusable widgets
    └── ...
```

### Key Services Overview

#### 1. AdvancedSearchService
- **Purpose**: API-intensive search with 20+ fields
- **Metrics**: Field queries, search operations, cache hits
- **Features**: Query building, field validation, API intensity tracking

#### 2. ArchiveService
- **Purpose**: Core Archive.org API interactions
- **Metrics**: Metadata fetches, file listings, API calls
- **Features**: API intensity integration, error handling

#### 3. ThumbnailCacheService
- **Purpose**: LRU thumbnail caching
- **Metrics**: Cache hits/misses, evictions, disk usage
- **Features**: Size enforcement, cleanup, compression

#### 4. MetadataCache
- **Purpose**: Archive metadata caching
- **Metrics**: Cache operations, size, batch operations
- **Features**: Size enforcement, expiration, batch operations

#### 5. HistoryService
- **Purpose**: Search history management
- **Metrics**: Searches, filters, analytics
- **Features**: Search/filter/sort, batch operations, analytics

#### 6. LocalArchiveStorage
- **Purpose**: Downloaded archive metadata
- **Metrics**: Storage operations, searches
- **Features**: Debouncing, sorting, filtering

#### 7. BackgroundDownloadService
- **Purpose**: Background download management
- **Metrics**: Starts, completions, failures, pauses, resumes, cancellations, retries
- **Features**: WorkManager integration, queue management
- **Status**: Phase 1 complete, Phases 2-3 pending (optional)

#### 8. IAHttpClient
- **Purpose**: HTTP client with retry logic
- **Metrics**: Requests, retries, failures, timeouts, rate limits, cache hits
- **Features**: Retry strategies, rate limiting, error categorization

#### 9. RateLimiter
- **Purpose**: Semaphore-based concurrency control
- **Metrics**: Acquires, releases, delays, queue waits
- **Features**: Concurrency limiting, queue management

#### 10. BandwidthThrottle
- **Purpose**: Token bucket bandwidth throttling
- **Metrics**: Bytes consumed, throttle events, immediate pass, total delay
- **Features**: Rate limiting, burst support, pause/resume

---

## Documentation Standards

### File Documentation Rules

**CRITICAL: Do NOT create new documentation files unnecessarily.**

#### When to Create Documentation
- ✅ **Major feature completion** (e.g., Phase completion, service enhancements)
- ✅ **Significant architectural changes** (e.g., new patterns, refactors)
- ✅ **Play Store requirements** (e.g., privacy policy, permissions)
- ✅ **Explicitly requested by user**

#### When NOT to Create Documentation
- ❌ **Small fixes or minor changes** → Use commit messages
- ❌ **Routine updates** → Update existing docs or CHANGELOG
- ❌ **Incremental progress** → Update progress tracking docs
- ❌ **Every single request** → Consolidate into existing files

#### Preferred Documentation Locations
1. **Commit messages** - For small changes and fixes
2. **Pull request descriptions** - For feature summaries
3. **CHANGELOG.md** - For release-worthy changes
4. **Existing docs/** files - Update rather than create new
5. **Inline code comments** - For complex logic
6. **New docs/features/** files - Only for major features

#### Documentation File Naming
- Use descriptive, action-oriented names
- Include service/feature name
- Use ALL_CAPS with underscores for docs/features/
- Examples:
  - ✅ `ADVANCED_SEARCH_ENHANCEMENT.md`
  - ✅ `BACKEND_SERVICES_OVERVIEW.md`
  - ✅ `PHASE_5_TASK_1_PROGRESS.md`
  - ❌ `summary.md`
  - ❌ `changes.md`
  - ❌ `update1.md`

### Code Documentation
- Use dartdoc comments (`///`) for public APIs
- Include parameter descriptions and return values
- Provide usage examples for complex functions
- Document edge cases and error conditions

---

## Testing Standards

### Verification Process
1. **Always run `flutter analyze`** after code changes
2. **Fix ALL warnings immediately** (CI treats warnings as errors)
3. **Test on multiple screen sizes** (phone, tablet, web)
4. **Verify responsive layouts** at all breakpoints
5. **Test dark mode** thoroughly
6. **Check accessibility** with TalkBack

### Common Issues to Avoid
- ❌ Unnecessary string interpolation braces (`${variable}` → `$variable`)
- ❌ Missing `const` constructors
- ❌ Unused imports
- ❌ Prefer `is` over `as` when possible
- ❌ Avoid `print()` (use `debugPrint()` with `kDebugMode`)

---

## Current Development Focus

### Active Work (smart-search branch)
1. **Backend Services**: All 10 priority services enhanced (100% complete)
   - Comprehensive metrics tracking
   - Enhanced logging with kDebugMode guards
   - Monitoring methods (getMetrics, resetMetrics, getFormattedStatistics)
   - Zero compilation errors

2. **Smart Search Screen**: In progress
   - Advanced search UI with 20+ fields
   - Responsive design for all screen sizes
   - API intensity tracking integration
   - UX polish (loading states, animations, error handling)

3. **Phase 5 Preparation**: 95% complete
   - Privacy policy ✅
   - Play Store metadata ✅
   - Permissions documentation ✅
   - Visual assets (pending)
   - UX improvements (in progress)

### Next Steps
1. Comprehensive testing and verification
2. Backend services overview documentation
3. BackgroundDownloadService Phases 2-3 (optional)
4. Smart search responsive design
5. UX polish (loading states, animations, accessibility)
6. Commit to main branch
7. Continue Phase 5 UX improvements
8. Play Store submission preparation

---

## Git & Version Control

### Branch Strategy
- **main**: Production-ready code
- **smart-search**: Active development (current)
- Feature branches as needed

### Commit Guidelines
- Use descriptive commit messages
- Reference issue numbers when applicable
- Group related changes together
- Update CHANGELOG.md for significant changes

### Before Committing
1. Run `flutter analyze` (must pass with 0 errors, 0 warnings)
2. Verify all tests pass
3. Check for unnecessary files
4. Update documentation if needed
5. Review diff for unintended changes

---

## Environment Notes

### When Flutter is Unavailable
- Focus on Dart code correctness and syntax
- Use static analysis by reading existing code patterns
- Verify against Dart language specs and Flutter best practices
- Check imports, types, and API compatibility manually
- Defer actual compilation testing to when Flutter is available

### CI/CD Requirements
- All warnings treated as errors
- Must pass `flutter analyze` with zero issues
- Must build successfully for all target platforms
- APK/AAB must be generated successfully

---

## Quick Reference

### Key Dependencies
- `flutter_markdown`: Markdown rendering
- `provider`: State management
- `shared_preferences`: Local storage
- `sqflite`: SQLite database
- `http`: HTTP client
- `path_provider`: File system paths
- `cached_network_image`: Image caching
- `url_launcher`: External URLs
- `share_plus`: Sharing functionality

### Key Constants
- API Base URL: `https://archive.org`
- Database version: Check `database_helper.dart`
- Cache sizes: Defined in respective service files
- Rate limits: Defined in `rate_limiter.dart`
- Bandwidth presets: Defined in `bandwidth_throttle.dart`

### Common Patterns

#### Provider Usage
```dart
// Non-rebuilding access
final provider = Provider.of<MyProvider>(context, listen: false);

// Rebuilding access
final provider = context.watch<MyProvider>();

// Or with Consumer
Consumer<MyProvider>(
  builder: (context, provider, child) => Widget(),
)
```

#### Responsive Layout
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth;
    final columns = width < 600 ? 2 : (width < 1200 ? 3 : 4);
    return GridView(...);
  },
)
```

#### Metrics Logging
```dart
metrics.operation++;
if (kDebugMode) {
  debugPrint('[ServiceName] Operation completed: $details');
}
```

---

## Support & Resources

- **Documentation**: `docs/` directory
- **Issues**: GitHub Issues
- **Material Design 3**: https://m3.material.io/
- **Flutter Docs**: https://docs.flutter.dev/
- **Archive.org API**: https://archive.org/help/aboutsearch.htm

---

**Last Updated**: October 9, 2025  
**Version**: 1.0.0 (Pre-release)  
**Status**: Active Development
