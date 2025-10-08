# Navigation Redesign Specification

**Version:** 1.0  
**Date:** January 2025  
**Status:** Planning Phase  
**Material Design 3 Compliance:** ✅ Required

---

## Executive Summary

This document specifies the redesign of the Internet Archive Helper app navigation from an overcrowded top app bar pattern to a user-intent-based bottom navigation bar system. The redesign consolidates 14+ screens into 5 primary navigation tabs while maintaining all existing functionality and following Material Design 3 guidelines.

### Key Goals
1. **Reduce cognitive load** - Clear, predictable navigation structure
2. **Improve discoverability** - Important features easily accessible
3. **Support future features** - Upload management alongside downloads
4. **Follow MD3 patterns** - NavigationBar with proper transitions
5. **Maintain feature parity** - No functionality lost in consolidation

---

## Current State Analysis

### Existing Screens (14 total)
```
┌─ Navigation Layer
│  ├─ home_screen.dart                    [Primary entry point]
│  ├─ search_results_screen.dart          [After search]
│  ├─ advanced_search_screen.dart         [From home app bar]
│  ├─ advanced_filters_screen.dart        [From advanced search]
│  ├─ filters_screen.dart                 [Alternative filters]
│  └─ archive_detail_screen.dart          [Archive view]
│
├─ Transfer Management
│  ├─ download_screen.dart                [Legacy download list]
│  └─ download_queue_screen.dart          [Queue management]
│
├─ Library & Organization
│  ├─ favorites_screen.dart               [Starred archives]
│  ├─ collections_screen.dart             [User collections]
│  ├─ saved_searches_screen.dart          [Saved search queries]
│  └─ history_screen.dart                 [Visit history]
│
├─ Auxiliary
│  ├─ file_preview_screen.dart            [File preview]
│  ├─ settings_screen.dart                [App config]
│  └─ help_screen.dart                    [Documentation]
```

### Current Problems
1. **Home screen app bar overcrowding** - 8+ action icons
2. **Duplicate functionality** - 2 download screens, 3 filter screens
3. **Hidden features** - Important functions buried in overflow menus
4. **Inconsistent patterns** - Mix of push navigation and modals
5. **No upload support** - Current structure doesn't accommodate uploads

---

## New Navigation Structure

### Bottom Navigation Bar (5 Tabs)

```
┌────────────────────────────────────────────────────────┐
│                   App Content                          │
│                                                        │
├────────────────────────────────────────────────────────┤
│  [🏠]    [📚]    [⭐]    [🔄]    [⚙️]                   │
│  Home    Library Faves  Transfer Settings              │
└────────────────────────────────────────────────────────┘
```

#### Tab 0: 🏠 Home (Search)
**Primary Intent:** Discover and search for content

**Main Screen:** `home_screen.dart` (refactored)

**Features:**
- Search bar with autocomplete
- Quick search suggestions
- Recent searches (inline, max 5)
- Search history access (via app bar action)
- Advanced search filters (via FAB or sheet)

**App Bar Actions:**
- Search history icon → Opens history modal/sheet
- Advanced search icon → Opens filters bottom sheet
- Help icon → Opens help screen

**Navigation Flows:**
- Search → `search_results_screen.dart`
- Result tap → `archive_detail_screen.dart`
- Advanced filters → Bottom sheet (not separate screen)

**Screen Consolidation:**
- ✅ Keep: `home_screen.dart`, `search_results_screen.dart`, `archive_detail_screen.dart`
- ♻️ Refactor: `advanced_search_screen.dart` → Bottom sheet component
- ♻️ Merge: `advanced_filters_screen.dart` + `filters_screen.dart` → Single filter sheet
- 📍 Integrate: `history_screen.dart` → Modal sheet from home
- 📍 Integrate: `saved_searches_screen.dart` → Section in search history sheet

---

#### Tab 1: 📚 Library (Downloaded Content)
**Primary Intent:** Access and organize downloaded archives

**Main Screen:** `library_screen.dart` (NEW - replaces collections_screen.dart)

**Features:**
- Tabs/Sections:
  1. **All Downloads** - Grid/list view of downloaded archives
  2. **Collections** - User-created collections
  3. **Recently Added** - Latest downloads
- View mode toggle (grid/list)
- Sort options (date, name, size, type)
- Search within library
- Bulk selection mode
- Storage statistics

**App Bar Actions:**
- View mode toggle (grid/list)
- Sort menu
- Search icon
- Bulk select mode

**Navigation Flows:**
- Archive tap → `archive_detail_screen.dart`
- Collection tap → Collection detail view (inline or push)
- File tap → `file_preview_screen.dart` or open with system

**Screen Consolidation:**
- 🆕 Create: `library_screen.dart` (new unified screen)
- ♻️ Refactor: `collections_screen.dart` → Section within library
- ✅ Keep: `file_preview_screen.dart` (as detail screen)

**Future Enhancements:**
- Cloud sync indicators
- Offline availability toggles
- Export/share collections

---

#### Tab 2: ⭐ Favorites (Quick Access)
**Primary Intent:** Quick access to starred content

**Main Screen:** `favorites_screen.dart` (enhanced)

**Features:**
- Grid/list view of favorited archives
- Filter by mediatype (chips)
- Sort options (recent, title, type)
- Search within favorites
- Quick unfavorite action
- Empty state with "Browse Archives" CTA

**App Bar Actions:**
- View mode toggle
- Filter menu
- Sort menu
- Search icon

**Navigation Flows:**
- Favorite tap → `archive_detail_screen.dart`
- Unfavorite → Remove with undo SnackBar
- Empty state CTA → Navigate to Home tab

**Screen Consolidation:**
- ✅ Keep: `favorites_screen.dart` (already well-designed)
- ✨ Enhance: Improve filtering and search

**Future Integration:**
- May be merged into Library as a "Favorites" collection
- Current standalone placement allows easy tab removal later

---

#### Tab 3: 🔄 Transfers (Downloads & Uploads)
**Primary Intent:** Manage active and queued file transfers

**Main Screen:** `transfers_screen.dart` (NEW - merges download screens)

**Features:**
- Tabs/Status Filters:
  1. **Active** - Currently transferring (↓ downloads + ↑ uploads)
  2. **Queued** - Waiting to start
  3. **Paused** - User-paused transfers
  4. **Completed** - Finished transfers
  5. **Failed** - Errors with retry
- Per-item actions:
  - Pause/Resume
  - Cancel (with confirmation)
  - Retry (for failed)
  - Priority adjustment (High/Normal/Low)
  - Open file/folder (for completed)
- Bulk actions:
  - Pause all
  - Resume all
  - Clear completed
  - Clear failed
- Real-time progress indicators
- Transfer statistics:
  - Total speed (combined ↓↑)
  - ETA for active transfers
  - Queue count
  - Bandwidth usage
- Drag-to-reorder queue

**App Bar Actions:**
- Bandwidth controls icon → Opens bandwidth sheet
- Sort/filter menu
- Bulk actions menu (3-dot)

**Navigation Flows:**
- Completed item tap → Open file or navigate to archive detail
- File preview → `file_preview_screen.dart`
- Bandwidth controls → Modal bottom sheet

**Screen Consolidation:**
- 🆕 Create: `transfers_screen.dart` (unified transfer management)
- 🗑️ Remove: `download_screen.dart` (legacy, functionality merged)
- ♻️ Refactor: `download_queue_screen.dart` → Merge into transfers_screen
- ✅ Keep: Transfer-related widgets and services

**Future Enhancements:**
- Upload support (same UI, different direction icon)
- Scheduled transfers
- WiFi-only mode
- Auto-pause on low battery
- Transfer history analytics

**Technical Notes:**
- Must support both `DownloadProvider` and `BackgroundDownloadService`
- Real-time progress via Stream listeners
- Persist queue to database
- Handle app termination/restart gracefully

---

#### Tab 4: ⚙️ Settings (Configuration)
**Primary Intent:** Configure app behavior and preferences

**Main Screen:** `settings_screen.dart` (enhanced)

**Features:**
- Sections:
  1. **General** - Theme, language, notifications
  2. **Downloads** - Default path, concurrency, auto-decompress
  3. **Bandwidth** - Rate limits, presets, schedules
  4. **Storage** - Cache management, cleanup, quotas
  5. **Privacy** - Analytics, crash reports, data collection
  6. **Advanced** - Developer options, diagnostics
  7. **About** - Version, licenses, links
- Quick actions:
  - Clear cache
  - Reset settings
  - Export/import settings
- Help & Support:
  - User guide → `help_screen.dart`
  - Report issue → GitHub
  - Privacy policy → In-app viewer

**App Bar Actions:**
- Help icon → Opens help screen
- Search settings (future)

**Navigation Flows:**
- Help → `help_screen.dart` (push)
- Privacy policy → Modal viewer
- Licenses → System licenses screen

**Screen Consolidation:**
- ✅ Keep: `settings_screen.dart`, `help_screen.dart`
- ✨ Enhance: Better organization, search

---

## Detail Screens (No Navigation Tab)

These screens are accessed via navigation from main tabs:

### Archive Detail Screen
**File:** `archive_detail_screen.dart`  
**Access:** From Home (search results), Library, Favorites  
**Features:** Metadata, file list, download controls, favorite button, collections

### File Preview Screen
**File:** `file_preview_screen.dart`  
**Access:** From Archive Detail, Library  
**Features:** In-memory file preview for images, text, PDF

### Search History/Saved Searches
**Component:** Modal bottom sheet or dedicated screen (TBD)  
**Access:** From Home tab app bar  
**Features:** Recent searches, saved queries, tags, quick load

---

## Material Design 3 Implementation

### NavigationBar Component

```dart
NavigationBar(
  selectedIndex: _currentTabIndex,
  onDestinationSelected: (index) {
    setState(() => _currentTabIndex = index);
  },
  destinations: const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.library_books_outlined),
      selectedIcon: Icon(Icons.library_books),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_outline),
      selectedIcon: Icon(Icons.favorite),
      label: 'Favorites',
    ),
    NavigationDestination(
      icon: Icon(Icons.swap_vert_outlined),
      selectedIcon: Icon(Icons.swap_vert),
      label: 'Transfers',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ],
)
```

### MD3 Design Tokens

**Colors:**
- Active tab: `colorScheme.primary` (fill for selected icon)
- Inactive tabs: `colorScheme.onSurfaceVariant`
- Background: `colorScheme.surface` (elevation 2)

**Typography:**
- Labels: `labelMedium` (12sp, 500 weight)

**Spacing:**
- Icon size: 24dp (outlined), 24dp (filled)
- Label padding: 4dp top
- Destination padding: 12dp horizontal, 16dp vertical
- NavigationBar height: 80dp
- Safe area padding: Automatic

**Elevation:**
- NavigationBar: Level 2 (3dp)
- Ripple effect on tap

**Animation:**
- Tab switch: Fade through transition (300ms, emphasized easing)
- Icon transition: Morph between outlined and filled (200ms)
- Label: Fade in/out (150ms)

### Page Transitions

**Between Tabs:**
```dart
// Use fade through for tab switches
AnimatedSwitcher(
  duration: MD3Durations.emphasized,
  switchInCurve: MD3Curves.emphasizedDecelerate,
  switchOutCurve: MD3Curves.emphasizedAccelerate,
  transitionBuilder: (child, animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  },
  child: _currentTabScreen,
)
```

**To Detail Screens:**
- Use `MD3PageTransitions.fadeThrough()` for archive detail
- Use `MD3PageTransitions.containerTransform()` for file preview (if applicable)
- Use `MD3PageTransitions.sharedAxis()` for settings/help

**Modals:**
- Use `showModalBottomSheet()` for filters, bandwidth controls
- Use `showDialog()` for confirmations, errors
- Use `ScaffoldMessenger.showSnackBar()` for success/info

---

## State Management

### Navigation State

**File:** `lib/core/navigation/navigation_state.dart` (NEW)

```dart
class NavigationState extends ChangeNotifier {
  int _currentTabIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Library
    GlobalKey<NavigatorState>(), // Favorites
    GlobalKey<NavigatorState>(), // Transfers
    GlobalKey<NavigatorState>(), // Settings
  ];
  
  int get currentTabIndex => _currentTabIndex;
  GlobalKey<NavigatorState> get currentNavigatorKey => 
      _navigatorKeys[_currentTabIndex];
  
  void changeTab(int index) {
    if (index == _currentTabIndex) {
      // Pop to root of current tab
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      _currentTabIndex = index;
      notifyListeners();
    }
  }
  
  void popToRoot() {
    currentNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}
```

### Per-Tab Navigation Stack

Each tab maintains its own navigation stack using nested `Navigator` widgets. This allows:
- Back button pops within current tab first
- Tab switching preserves each tab's state
- Deep linking works correctly
- User can return to where they were in each tab

**Implementation:**
```dart
IndexedStack(
  index: _currentTabIndex,
  children: [
    _TabNavigator(navigatorKey: _navigatorKeys[0], rootScreen: HomeScreen()),
    _TabNavigator(navigatorKey: _navigatorKeys[1], rootScreen: LibraryScreen()),
    _TabNavigator(navigatorKey: _navigatorKeys[2], rootScreen: FavoritesScreen()),
    _TabNavigator(navigatorKey: _navigatorKeys[3], rootScreen: TransfersScreen()),
    _TabNavigator(navigatorKey: _navigatorKeys[4], rootScreen: SettingsScreen()),
  ],
)
```

### State Preservation

**On Tab Switch:**
- Keep all tab states alive using `IndexedStack` with `AutomaticKeepAliveClientMixin`
- Preserve scroll positions
- Maintain filter/sort selections
- Keep search queries

**On App Background:**
- Persist current tab index to SharedPreferences
- Save navigation stack for each tab
- Restore on app resume

**On Deep Link:**
- Navigate to appropriate tab
- Push detail screen onto tab's navigator
- Maintain back button navigation

---

## Screen Consolidation Details

### Screen Mapping

| Old Screen(s) | New Location | Status |
|---------------|--------------|--------|
| `home_screen.dart` | Tab 0: Home | ♻️ Refactor (simplify app bar) |
| `search_results_screen.dart` | Home tab → push | ✅ Keep |
| `advanced_search_screen.dart` | Home tab → sheet | ♻️ Convert to modal |
| `advanced_filters_screen.dart` | Home tab → sheet | ♻️ Merge with filters |
| `filters_screen.dart` | Home tab → sheet | ♻️ Merge with advanced |
| `archive_detail_screen.dart` | All tabs → push | ✅ Keep |
| `download_screen.dart` | Tab 3: Transfers | 🗑️ Remove (merged) |
| `download_queue_screen.dart` | Tab 3: Transfers | ♻️ Merge into transfers |
| `favorites_screen.dart` | Tab 2: Favorites | ✅ Keep (enhance) |
| `collections_screen.dart` | Tab 1: Library section | ♻️ Integrate |
| `saved_searches_screen.dart` | Home tab → modal | ♻️ Convert to component |
| `history_screen.dart` | Home tab → modal | ♻️ Convert to component |
| `file_preview_screen.dart` | Detail screen | ✅ Keep |
| `settings_screen.dart` | Tab 4: Settings | ✅ Keep (enhance) |
| `help_screen.dart` | Settings → push | ✅ Keep |

### New Files to Create

1. **`lib/core/navigation/bottom_navigation_scaffold.dart`**
   - Main scaffold with NavigationBar
   - Tab switching logic
   - State management integration

2. **`lib/core/navigation/navigation_state.dart`**
   - NavigationState provider
   - Tab index management
   - Navigator key management

3. **`lib/screens/library_screen.dart`**
   - Unified library view
   - Tabs: All Downloads, Collections, Recent
   - Integrates collections functionality

4. **`lib/screens/transfers_screen.dart`**
   - Unified transfer management
   - Downloads + Uploads (future)
   - Queue management, progress tracking

5. **`lib/widgets/search_history_sheet.dart`**
   - Modal bottom sheet component
   - Recent searches + Saved searches
   - Replaces full-screen history/saved searches

6. **`lib/widgets/advanced_filters_sheet.dart`**
   - Modal bottom sheet component
   - All search filters in one place
   - Replaces multiple filter screens

---

## Migration Plan

### Phase 1: Foundation (2-3 hours)
- ✅ Create navigation spec document (this file)
- 🔲 Create `NavigationState` provider
- 🔲 Create `BottomNavigationScaffold` widget
- 🔲 Set up IndexedStack with 5 tabs
- 🔲 Implement tab switching with state preservation
- 🔲 Test basic navigation without content

**Deliverable:** Working bottom nav with placeholder content

### Phase 2: Screen Migration (3-4 hours)
- 🔲 Create `library_screen.dart` (integrate collections)
- 🔲 Create `transfers_screen.dart` (merge download screens)
- 🔲 Create `search_history_sheet.dart` (merge history/saved)
- 🔲 Create `advanced_filters_sheet.dart` (merge filters)
- 🔲 Refactor `home_screen.dart` (simplify app bar)
- 🔲 Enhance `favorites_screen.dart` (improve UX)
- 🔲 Enhance `settings_screen.dart` (add sections)

**Deliverable:** All 5 tabs functional with migrated content

### Phase 3: Polish & Testing (2-3 hours)
- 🔲 Implement MD3 transitions between tabs
- 🔲 Add hero animations where applicable
- 🔲 Test all navigation paths
- 🔲 Test deep linking
- 🔲 Test back button behavior
- 🔲 Test state preservation
- 🔲 Verify no features lost
- 🔲 Run `flutter analyze` (0 issues required)
- 🔲 Update documentation

**Deliverable:** Production-ready navigation system

### Phase 4: Cleanup (1 hour)
- 🔲 Remove old screens (download_screen, etc.)
- 🔲 Update main.dart routing
- 🔲 Remove unused imports
- 🔲 Update screenshots for Play Store
- 🔲 Commit and push changes

**Deliverable:** Clean codebase, ready for visual assets

**Total Estimated Time:** 8-12 hours

---

## Feature Parity Checklist

Ensure all existing functionality is preserved:

### Search & Discovery
- ✅ Simple search
- ✅ Advanced search with filters
- ✅ Search suggestions
- ✅ Search history
- ✅ Saved searches
- ✅ Search results pagination
- ✅ Archive detail view

### Downloads & Transfers
- ✅ Download files
- ✅ Download queue management
- ✅ Pause/resume downloads
- ✅ Cancel downloads
- ✅ Retry failed downloads
- ✅ Priority management
- ✅ Bandwidth throttling
- ✅ Background downloads
- ✅ Progress indicators
- ✅ Queue reordering
- 🆕 Upload support (future)

### Library & Organization
- ✅ View downloaded archives
- ✅ Collections management
- ✅ Favorites
- ✅ File preview
- ✅ Open files with system apps

### Settings & Configuration
- ✅ Theme selection
- ✅ Download path
- ✅ Concurrency settings
- ✅ Bandwidth limits
- ✅ Storage management
- ✅ Privacy settings
- ✅ Help & support

---

## Success Criteria

### User Experience
- [ ] Users can complete all existing tasks
- [ ] Navigation is intuitive without onboarding
- [ ] No features are hidden or hard to find
- [ ] Back button behaves predictably
- [ ] Tab switching is smooth (< 300ms)
- [ ] State is preserved across tab switches

### Technical
- [ ] Zero `flutter analyze` issues
- [ ] 100% Material Design 3 compliance
- [ ] No performance regressions
- [ ] All tests pass
- [ ] Code coverage maintained or improved
- [ ] No memory leaks from navigation

### Play Store Readiness
- [ ] Screenshots show new navigation
- [ ] All features documented
- [ ] Help screen updated
- [ ] Onboarding updated (if needed)
- [ ] User guide reflects new structure

---

## Future Enhancements

### Upload Support (Phase 6)
- Add upload functionality to Transfers tab
- Same UI, different icon (↑ vs ↓)
- Support upload queuing
- Show upload progress alongside downloads

### Smart Features
- Recently accessed (across all tabs)
- Recommended collections
- Transfer scheduling
- Bandwidth auto-adjustment

### Accessibility
- Screen reader support
- Keyboard navigation
- Haptic feedback
- Voice commands

---

## Appendix: Icon Reference

### NavigationBar Icons

| Tab | Outlined | Filled | Semantic |
|-----|----------|--------|----------|
| Home | `home_outlined` | `home` | Search & Discovery |
| Library | `library_books_outlined` | `library_books` | Downloaded Content |
| Favorites | `favorite_outline` | `favorite` | Starred Archives |
| Transfers | `swap_vert_outlined` | `swap_vert` | Download/Upload |
| Settings | `settings_outlined` | `settings` | Configuration |

**Alternative Icons Considered:**
- Transfers: `download_outlined`, `cloud_sync_outlined`, `sync_outlined`
  - **Chosen:** `swap_vert` (bidirectional, supports future uploads)

### App Bar Icons

**Home Tab:**
- `history` - Search history
- `filter_list` - Advanced filters
- `help_outline` - Help

**Library Tab:**
- `view_module` / `view_list` - View mode toggle
- `sort` - Sort options
- `search` - Search library

**Favorites Tab:**
- `view_module` / `view_list` - View mode toggle
- `filter_list` - Filter by type
- `sort` - Sort options

**Transfers Tab:**
- `speed` - Bandwidth controls
- `more_vert` - Bulk actions menu

**Settings Tab:**
- `help_outline` - Help

---

## References

- [Material Design 3 Guidelines](https://m3.material.io/)
- [NavigationBar Component](https://m3.material.io/components/navigation-bar)
- [Flutter NavigationBar](https://api.flutter.dev/flutter/material/NavigationBar-class.html)
- [Phase 5 Plan](./PHASE_5_PLAN.md)
- [UX Polish Complete](./UX_POLISH_COMPLETE.md)

---

**Last Updated:** January 2025  
**Next Review:** After Phase 1 implementation  
**Status:** Ready for implementation ✅
