# Testing Bugs - October 10, 2025

## Priority Bugs from User Testing

### 🔴 CRITICAL - Validator Race Condition
**Issue**: Positive validation result is faster than negative, so positive occurs first. Then negative from prior request overwrites it until you navigate away and back.

**Root Cause**: 
- Race condition in `intelligent_search_bar.dart` validation
- No request tracking/cancellation for in-flight validation requests
- Later API calls can complete before earlier calls, overwriting correct results
- 300ms debounce not addressing the core ordering issue

**Location**: `lib/widgets/intelligent_search_bar.dart` lines 150-195

**Fix Required**:
1. Add request sequence numbering
2. Track current validation request ID
3. Ignore stale results (earlier request IDs)
4. Add validation result caching
5. Cancel in-flight HTTP requests on new input

**Implementation Plan**:
```dart
class _IntelligentSearchBarState extends State<IntelligentSearchBar> {
  int _validationSequence = 0;
  final Map<String, bool> _validationCache = {};
  
  void _scheduleIdentifierValidation(String identifier) {
    _validationDebounce?.cancel();
    _validationSequence++;
    final requestId = _validationSequence;
    
    // Check cache first
    if (_validationCache.containsKey(identifier)) {
      setState(() {
        _isValidIdentifier = _validationCache[identifier];
        _isValidatingIdentifier = false;
      });
      return;
    }
    
    _validationDebounce = Timer(const Duration(milliseconds: 300), () {
      _validateIdentifier(identifier, requestId);
    });
  }
  
  Future<void> _validateIdentifier(String identifier, int requestId) async {
    // ... validation logic ...
    
    // Only update if this is still the latest request
    if (requestId == _validationSequence && mounted) {
      _validationCache[identifier] = isValid;
      setState(() { /* update state */ });
    }
  }
}
```

**Files to Modify**:
- `lib/widgets/intelligent_search_bar.dart`
- `lib/services/archive_service.dart` (add caching support)

---

### 🔴 CRITICAL - Searches and Validations Not Using Cache
**Issue**: Every search and validation hits the API, no caching implemented

**Root Cause**:
- `ArchiveService.validateIdentifier()` has no cache
- Search results not cached
- Perfect candidates for caching to reduce API load

**Fix Required**:
1. Add validation cache to `ArchiveService`
2. Add search results cache (identifier → metadata)
3. Implement TTL (time-to-live) for cache entries
4. Cache both positive and negative results

**Implementation Plan**:
```dart
class ArchiveService extends ChangeNotifier {
  final Map<String, bool> _validationCache = {};
  final Map<String, CachedMetadata> _metadataCache = {};
  static const _cacheDuration = Duration(minutes: 30);
  
  Future<String?> validateIdentifier(String identifier) async {
    // Check cache first
    if (_validationCache.containsKey(identifier)) {
      return _validationCache[identifier]! ? identifier : null;
    }
    
    // ... existing validation logic ...
    
    // Cache result
    _validationCache[identifier] = exists;
    return exists ? identifier : null;
  }
}
```

**Files to Modify**:
- `lib/services/archive_service.dart`
- `lib/models/cached_metadata.dart` (already exists - verify usage)
- `lib/services/metadata_cache.dart` (integrate with ArchiveService)

---

### 🟠 HIGH - Scrolling Request Error
**Issue**: Error appears when scrolling list of archives on mobile and web

**Root Cause**: Unknown - need stack trace

**Investigation Needed**:
1. Check `search_results_screen.dart` ListView error handling
2. Check image loading errors (cached_network_image)
3. Check thumbnail fetch failures during rapid scrolling
4. Verify scroll controller disposal

**Possible Causes**:
- Thumbnail loading failures not caught
- Disposed widgets still trying to load images
- GridView/ListView builder errors
- Network errors during rapid scrolling

**Files to Investigate**:
- `lib/screens/search_results_screen.dart`
- `lib/widgets/archive_result_card.dart`
- `lib/services/thumbnail_cache_service.dart`

**Fix Strategy**:
- Add error boundary widgets
- Wrap image loading in try-catch
- Add null checks for disposed contexts
- Implement better error recovery

---

### 🟠 HIGH - Trending Content No End-of-List Indicator
**Issue**: Reaching bottom of trending does not load more content and does not show end-of-list message

**Root Cause**: 
- No pagination for trending content
- No "end of results" indicator
- User confusion about whether more content exists

**Fix Required**:
1. Determine if trending has pagination
2. Add end-of-list indicator when no more results
3. Add "Load More" button or infinite scroll
4. Show message: "You've reached the end"

**Implementation**:
```dart
// In ListView.builder or GridView.builder
itemCount: _results.length + (_hasMore ? 1 : 1), // +1 for footer

itemBuilder: (context, index) {
  if (index == _results.length) {
    return _hasMore 
      ? _buildLoadMoreButton()
      : _buildEndOfListMessage();
  }
  return _buildResultItem(_results[index]);
}

Widget _buildEndOfListMessage() {
  return Container(
    padding: EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(Icons.check_circle_outline, size: 48),
        SizedBox(height: 16),
        Text('You\'ve reached the end!', style: titleMedium),
        Text('No more results to display', style: bodySmall),
      ],
    ),
  );
}
```

**Files to Modify**:
- `lib/screens/home_screen.dart` (if trending shown here)
- `lib/screens/search_results_screen.dart` (add end indicator)
- `lib/widgets/empty_state_widget.dart` (add `.endOfList()` factory)

---

### 🟡 MEDIUM - Downloads Not Visible on Mobile
**Issue**: Downloads don't appear on mobile, not managed in archive detail page or library

**Root Cause**:
- Download UI may be hidden on mobile
- Download status not updating properly
- Library downloads tab not showing downloads

**Investigation Needed**:
1. Check `archive_detail_screen.dart` download buttons visibility
2. Check `download_screen.dart` (Library > Downloads tab)
3. Verify `DownloadProvider` state updates
4. Check responsive layout hiding download widgets

**Files to Check**:
- `lib/screens/archive_detail_screen.dart`
- `lib/screens/download_screen.dart`
- `lib/providers/download_provider.dart`
- `lib/widgets/download_controls_widget.dart`

**Fix Strategy**:
- Verify download controls are visible on mobile
- Check if responsive layout hides download section
- Ensure download status updates trigger UI refresh
- Add debug logging for download state changes

---

### 🟡 MEDIUM - Opening Downloaded File Does Nothing
**Issue**: Tapping a downloaded file in downloads screen does nothing. Expected: open locally or prompt

**Root Cause**:
- No file opening implementation
- Need to use `url_launcher` or `open_file` package

**Fix Required**:
1. Add `open_file` or `open_filex` package to `pubspec.yaml`
2. Implement file opening in download tile onTap
3. Handle unsupported file types gracefully
4. Show snackbar if opening fails

**Implementation Plan**:
```dart
// Add to pubspec.yaml
dependencies:
  open_filex: ^4.5.0  // or open_file: ^3.5.10

// In download tile
onTap: () async {
  final filePath = download.localPath;
  if (filePath != null && await File(filePath).exists()) {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open file: ${result.message}')),
        );
      }
    }
  }
}
```

**Files to Modify**:
- `pubspec.yaml`
- `lib/screens/download_screen.dart`
- `lib/widgets/download_tile_widget.dart` (if exists)

---

### 🟢 LOW - Library "Recent" Should Be Sort Option
**Issue**: "Recent" in library is a separate tab, should be a sort option instead

**Root Cause**: UX design decision - tabs vs sorting

**Fix Required**:
1. Remove "Recent" tab from library bottom navigation
2. Add sort dropdown/chip: "Recent", "A-Z", "Size", "Type"
3. Update library screen layout
4. Preserve user sort preference

**Files to Modify**:
- `lib/screens/download_screen.dart` (or wherever library tabs are)
- `lib/models/sort_option.dart` (add DownloadSortOption)
- `lib/services/local_archive_storage.dart` (add sort methods)

**Implementation**:
```dart
enum DownloadSortOption {
  recent, // Sort by download date
  nameAsc, // A-Z
  nameDesc, // Z-A
  sizeDesc, // Largest first
  sizeAsc, // Smallest first
  type, // Group by file type
}

// Add to app bar
PopupMenuButton<DownloadSortOption>(
  icon: Icon(Icons.sort),
  onSelected: (option) => _sortDownloads(option),
  itemBuilder: (context) => [
    PopupMenuItem(value: DownloadSortOption.recent, child: Text('Most Recent')),
    PopupMenuItem(value: DownloadSortOption.nameAsc, child: Text('Name (A-Z)')),
    // ...
  ],
)
```

---

## Testing Checklist

### Before Fixes
- [ ] Reproduce validator race condition
- [ ] Confirm no caching on searches/validations
- [ ] Capture scrolling error stack trace
- [ ] Test trending bottom behavior
- [ ] Verify downloads visible on mobile
- [ ] Test opening downloaded files
- [ ] Review library tabs UX

### After Fixes
- [ ] Validator returns correct result consistently
- [ ] Cache hits show instant results
- [ ] No errors during scrolling
- [ ] End-of-list message shown
- [ ] Downloads visible and functional
- [ ] Files open in system app
- [ ] Library sort works as expected

---

## Estimated Effort

| Bug | Priority | Effort | Files | Complexity |
|-----|----------|--------|-------|------------|
| Validator race condition | Critical | 2-3 hours | 2 | Medium |
| Search/validation caching | Critical | 3-4 hours | 3 | Medium |
| Scrolling error | High | 1-2 hours | 3 | Low-Medium |
| Trending end indicator | High | 1 hour | 2 | Low |
| Downloads on mobile | Medium | 2-3 hours | 4 | Medium |
| Open downloaded files | Medium | 1-2 hours | 3 | Low |
| Library sort UX | Low | 2 hours | 3 | Low |

**Total Estimated Effort**: 12-17 hours

---

## Fix Order (Recommended)

1. **Validator race condition + caching** (Critical, 5-7 hours)
   - Fixes two critical issues at once
   - High user impact
   - Reduces API load significantly

2. **Scrolling error** (High, 1-2 hours)
   - Quick investigation and fix
   - Affects all list views

3. **Trending end indicator** (High, 1 hour)
   - Quick UX improvement
   - Low complexity

4. **Downloads on mobile** (Medium, 2-3 hours)
   - Important functionality
   - May uncover other issues

5. **Open downloaded files** (Medium, 1-2 hours)
   - Depends on downloads being visible
   - Adds valuable feature

6. **Library sort UX** (Low, 2 hours)
   - Polish improvement
   - Not blocking other work

---

## Notes

- All fixes should maintain Material Design 3 compliance
- All fixes should be responsive (phone, tablet, web)
- All fixes should include proper error handling
- Add metrics/logging for debugging
- Update CHANGELOG.md after each fix
- Consider grouping related fixes into single commits

---

**Created**: October 10, 2025  
**Status**: Awaiting implementation  
**Branch**: `smart-search` (or create `bugfix/oct-10-testing` branch)
