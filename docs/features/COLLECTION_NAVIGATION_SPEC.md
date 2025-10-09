# Collection Navigation & Discovery Feature Specification

**Feature ID:** PHASE-5-2.8  
**Priority:** High  
**Status:** Planned  
**Estimated Effort:** 8-12 hours  
**Target Phase:** Phase 5, Task 2

---

## 🎯 Overview

Enhance the app's collection features to enable fluid navigation between archives through their collections, similar to browsing albums on a music streaming service or playlists on YouTube. This creates a more discoverable, engaging experience where users can explore related content seamlessly.

---

## 💡 User Stories

### Primary User Stories

1. **As a user viewing an archive**, I want to see what collections it belongs to, so I can discover related content.

2. **As a user**, I want to click on a collection name to view all archives in that collection, so I can explore related items.

3. **As a user browsing a collection**, I want to save/bookmark it for quick access later, so I don't have to search for it again.

4. **As a user in a collection view**, I want to sort and filter archives, so I can find specific types of content.

5. **As a user viewing an archive in a collection**, I want to easily navigate to the next/previous archive, so I can browse through the collection fluidly.

---

## 🏗️ Architecture

### Data Models

#### Collection Model Enhancement
```dart
class Collection {
  final String identifier;
  final String title;
  final String? description;
  final String? creator;
  final int itemCount;
  final DateTime? dateCreated;
  final String? subject;
  final bool isBookmarked;
  final CollectionSource source; // IA, Local, or Mixed
  final Map<String, dynamic>? metadata;
  
  // Bookmarking fields
  final DateTime? bookmarkedAt;
  final String? userNotes;
  final List<String>? userTags;
}

enum CollectionSource {
  internetArchive,
  local,
  mixed,
}
```

#### CollectionItem Model
```dart
class CollectionItem {
  final String identifier;
  final String? title;
  final String? mediatype;
  final String? creator;
  final String? thumbnailUrl;
  final int? downloads;
  final int? views;
  final DateTime? dateAdded;
  final int? fileSize;
}
```

### Services

#### CollectionsService Enhancement
```dart
class CollectionsService {
  // Existing methods...
  
  // New methods for IA collections
  Future<List<Collection>> fetchIACollections(String identifier);
  Future<Collection> fetchCollectionDetails(String collectionId);
  Future<List<CollectionItem>> fetchCollectionItems(
    String collectionId, {
    int? page,
    int? rows,
    String? sort,
    Map<String, dynamic>? filters,
  });
  
  // Bookmarking methods
  Future<void> bookmarkCollection(Collection collection);
  Future<void> unbookmarkCollection(String collectionId);
  Future<bool> isCollectionBookmarked(String collectionId);
  Future<List<Collection>> getBookmarkedCollections();
  
  // Navigation helpers
  Future<CollectionItem?> getNextItemInCollection(
    String collectionId,
    String currentItemId,
  );
  Future<CollectionItem?> getPreviousItemInCollection(
    String collectionId,
    String currentItemId,
  );
}
```

---

## 🎨 UI/UX Design

### 1. Archive Detail Screen - Collection Section

#### Current State
- Collections are mentioned in metadata but not prominently displayed
- No way to navigate to collection view
- Unclear what collections the archive belongs to

#### Proposed Design

**Collection Chips Section** (below title, above description):
```
┌─────────────────────────────────────────┐
│ 📁 In 3 collections                     │
│                                          │
│ ┌──────────────┐ ┌────────────────┐    │
│ │ 🎵 Music     │ │ 🎸 Rock Albums │    │
│ └──────────────┘ └────────────────┘    │
│                                          │
│ ┌───────────────────┐                   │
│ │ 📻 1970s Classics │                   │
│ └───────────────────┘                   │
└─────────────────────────────────────────┘
```

**MD3 Components:**
- Use `Wrap` widget with `Chip` components
- Primary color for main collection
- Secondary color for other collections
- Icon indicating collection type
- Ripple effect on tap
- Collection item count badge (optional)

**Interaction:**
- Tap chip → Navigate to Collection View Screen
- Long press → Show collection preview/details
- Slide collection section for more chips if many collections

---

### 2. Collection View Screen (New)

#### Screen Structure

```
┌─────────────────────────────────────────┐
│ ← [Collection Name]              🔍 ⋮   │ App Bar
├─────────────────────────────────────────┤
│                                          │
│ [Collection Cover Image]                │ Header Section
│                                          │
│ Collection Title                         │
│ by Creator Name                          │
│ 1,234 items • Created Jan 2020          │
│                                          │
│ [Description text...]                   │
│                                          │
│ ┌─────────────┐                         │
│ │ 🔖 Bookmark │                         │ Action Button
│ └─────────────┘                         │
├─────────────────────────────────────────┤
│ ⚙️ Sort: Date Added ↓  📁 Filter: All  │ Controls
├─────────────────────────────────────────┤
│                                          │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │ 🎵  │ │ 🎵  │ │ 🎵  │ │ 🎵  │        │
│ │Title│ │Title│ │Title│ │Title│        │ Grid View
│ └─────┘ └─────┘ └─────┘ └─────┘        │
│                                          │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │ 🎵  │ │ 🎵  │ │ 🎵  │ │ 🎵  │        │
│ └─────┘ └─────┘ └─────┘ └─────┘        │
│                                          │
└─────────────────────────────────────────┘
```

#### Components

**1. Header Section**
- Collection cover image (if available)
- Collection title (headline style)
- Creator/curator name (clickable)
- Item count and creation date
- Description (collapsible if long)
- Bookmark button (filled if bookmarked)

**2. Controls Bar**
- Sort dropdown:
  - Date Added (↓↑)
  - Title (A-Z, Z-A)
  - Downloads (↓↑)
  - Views (↓↑)
  - Relevance
- Filter button → opens filter sheet:
  - Media type chips
  - Date range slider
  - File size range
  - Language selector
  - Subject/topic

**3. Item Grid/List**
- Adaptive layout (2-3 columns on phone, 4-6 on tablet)
- Thumbnail image
- Title (max 2 lines)
- Media type icon badge
- Optional: download count, date added
- Tap → Navigate to Archive Detail
- Long press → Show context menu (download, favorite, share)

**4. Floating Action Button**
- Download all button (if collection is small)
- Or "Bookmark Collection" if not bookmarked

---

### 3. Archive Detail Screen Layout Overhaul

#### Problem
Current layout shows everything at once, becoming cluttered when we add:
- Collection chips
- Similar items section
- More metadata
- Comments/reviews (future)

#### Solution: Collapsible Sections + Tabs

**Option A: Collapsible Sections** (Recommended for most archives)
```
┌─────────────────────────────────────────┐
│ Archive Title                            │ Always visible
│ by Creator                               │
│ [Thumbnail/Cover]                        │
│                                          │
│ 📁 In 3 collections [▼]                 │ Expandable
│                                          │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│ 📂 Files (234) [▼]                      │ Expandable - Expanded by default
│   [File list...]                        │
│                                          │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│ ℹ️ Metadata [▼]                         │ Expandable - Collapsed by default
│                                          │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│ 🔗 Similar Items [▼]                    │ Expandable - Collapsed by default
│                                          │
└─────────────────────────────────────────┘
```

**Option B: Tab-Based Layout** (For complex archives with 100+ files)
```
┌─────────────────────────────────────────┐
│ Archive Title                            │ Header (always visible)
│ by Creator                               │
│ 📁 In 3 collections                      │
├─────────────────────────────────────────┤
│ Files  │ Info  │ Collections │ Related  │ Tab Bar
├─────────────────────────────────────────┤
│                                          │
│ [Current tab content]                   │ Tab content
│                                          │
│                                          │
└─────────────────────────────────────────┘
```

#### Sections Definition

1. **Basic Info** (Always Visible)
   - Title, creator, thumbnail
   - Quick actions (favorite, share, download all)
   - Collection chips

2. **Files Section** (Expandable, default: expanded)
   - File list with search/filter
   - Download controls
   - Sort options

3. **Collections Section** (Expandable, default: collapsed)
   - All collections this archive belongs to
   - Collection previews (thumbnails of other items)
   - "View Collection" buttons

4. **Metadata Section** (Expandable, default: collapsed)
   - Full metadata display
   - Technical details
   - Dates, subjects, etc.

5. **Similar Items Section** (Expandable, default: collapsed)
   - Horizontal scrollable list
   - Based on metadata, collection, subject

---

### 4. Collection-to-Archive Navigation

#### Next/Previous Navigation

**In-Collection Navigation Bar** (when viewing archive from collection):
```
┌─────────────────────────────────────────┐
│ ← Collection: Rock Albums                │ App Bar
├─────────────────────────────────────────┤
│ ◄ Previous     [12/234]      Next ►     │ Navigation Bar
├─────────────────────────────────────────┤
│ [Archive content...]                     │
└─────────────────────────────────────────┘
```

**Features:**
- Shows position in collection (e.g., "12/234")
- Previous/Next buttons with archive thumbnails on hover
- Swipe left/right gesture support
- Maintains collection context when navigating
- "Back to Collection" breadcrumb

#### Breadcrumb Navigation
```
Home > Collections > Rock Albums > Led Zeppelin IV
                    [clickable]   [current]
```

---

## 🔧 Implementation Plan

### Phase 1: Data Layer (2-3 hours)
1. ✅ Enhance Collection model
2. ✅ Create CollectionItem model
3. ✅ Implement CollectionsService methods for:
   - Fetching IA collections for an archive
   - Fetching collection details
   - Fetching collection items with pagination
   - Bookmarking operations
4. ✅ Add database tables for bookmarked collections
5. ✅ Implement caching for collection metadata

### Phase 2: Collection View Screen (3-4 hours)
1. ✅ Create CollectionViewScreen widget
2. ✅ Implement header section with cover, title, stats
3. ✅ Add bookmark functionality
4. ✅ Implement sort/filter controls
5. ✅ Create grid/list view for collection items
6. ✅ Add pagination support
7. ✅ Implement search within collection
8. ✅ Add loading and error states

### Phase 3: Archive Detail Updates (2-3 hours)
1. ✅ Add collection chips section
2. ✅ Implement chip tap navigation
3. ✅ Redesign layout with collapsible sections:
   - ExpansionTile or custom collapsible widgets
   - Maintain scroll position
4. ✅ Add breadcrumb navigation
5. ✅ Implement "Back to Collection" flow
6. ✅ Add next/previous navigation (if from collection)

### Phase 4: Integration & Polish (1-2 hours)
1. ✅ Integrate with existing Collections screen
2. ✅ Add IA collection badge/indicator
3. ✅ Update search to include collections
4. ✅ Add animations and transitions
5. ✅ Test navigation flows
6. ✅ Handle edge cases (empty collections, network errors)

---

## 📊 API Integration

### Internet Archive Collection APIs

#### Get Collections for an Archive
```
GET https://archive.org/metadata/{identifier}
Response: metadata.collection (array of collection identifiers)
```

#### Get Collection Details
```
GET https://archive.org/metadata/{collection_id}
Response: Full collection metadata
```

#### Search Within Collection
```
GET https://archive.org/advancedsearch.php
Parameters:
  - q: collection:{collection_id} AND [additional filters]
  - output: json
  - rows: 50
  - page: 1
  - sort: [sort field]
```

#### Collection Item Count
```
GET https://archive.org/advancedsearch.php
Parameters:
  - q: collection:{collection_id}
  - output: json
  - rows: 0
Response: response.numFound (total count)
```

---

## 🎯 Success Metrics

### User Engagement
- [ ] Increase in average session duration
- [ ] Increase in archives viewed per session
- [ ] Collection view screen usage rate
- [ ] Bookmarked collections count per user

### Feature Adoption
- [ ] % of users who tap collection chips
- [ ] % of users who bookmark collections
- [ ] Average collections bookmarked per user
- [ ] Next/previous navigation usage rate

### Technical Metrics
- [ ] Collection view screen load time < 2s
- [ ] Smooth 60fps scrolling in collection grid
- [ ] Cache hit rate for collection metadata > 80%
- [ ] Zero crashes in collection navigation flows

---

## ⚠️ Edge Cases & Considerations

### Edge Cases to Handle

1. **Empty Collections**
   - Show empty state with illustration
   - Suggest similar collections

2. **Very Large Collections** (10,000+ items)
   - Implement efficient pagination
   - Show loading indicators
   - Consider virtual scrolling

3. **Deleted/Unavailable Collections**
   - Handle 404 errors gracefully
   - Remove from bookmarks with notification
   - Suggest alternatives

4. **Offline Mode**
   - Show cached collection metadata
   - Indicate which items are available offline
   - Queue bookmark operations for sync

5. **Multiple Collection Membership**
   - Archives in 20+ collections → show "Show all" button
   - Prioritize primary/featured collections

6. **Circular Collection References**
   - Prevent infinite navigation loops
   - Track navigation history

### Performance Considerations

1. **Thumbnail Loading**
   - Lazy load thumbnails as user scrolls
   - Use thumbnail cache
   - Show placeholder while loading

2. **Large File Lists**
   - Paginate file lists in archive detail
   - Use virtual scrolling for 1000+ files

3. **Memory Management**
   - Dispose of controllers properly
   - Clear thumbnail cache when needed
   - Limit navigation stack depth

---

## 🔐 Privacy & Permissions

- No additional permissions required
- User's bookmarked collections stored locally
- Optional: Sync bookmarks via user account (future)
- User notes/tags stay on device

---

## ♿ Accessibility

- [ ] Screen reader support for collection chips
- [ ] Announce "X of Y" when navigating in collection
- [ ] Keyboard navigation for next/previous
- [ ] High contrast mode support
- [ ] Semantic labels for all interactive elements
- [ ] Focus indicators for collection chips

---

## 📱 Responsive Design

### Phone (< 600dp)
- 2-column grid in collection view
- Single-line collection chips (scrollable)
- Compact navigation bar

### Tablet (600-840dp)
- 3-4 column grid
- Two-line collection chips
- Expanded navigation with thumbnails

### Tablet Large (> 840dp)
- 4-6 column grid
- Master-detail layout option
- Sidebar navigation for collections

---

## 🧪 Testing Checklist

### Unit Tests
- [ ] Collection model serialization/deserialization
- [ ] CollectionsService methods
- [ ] Bookmark operations
- [ ] Pagination logic
- [ ] Sort/filter functions

### Widget Tests
- [ ] Collection chips render correctly
- [ ] Collection view screen layout
- [ ] Next/previous navigation
- [ ] Bookmark button states
- [ ] Empty states

### Integration Tests
- [ ] Navigate from archive to collection
- [ ] Navigate through collection items
- [ ] Bookmark and unbookmark flow
- [ ] Sort and filter operations
- [ ] Offline mode behavior

### Manual Testing
- [ ] Test with various collection sizes (0, 1, 10, 100, 1000+ items)
- [ ] Test with different media types
- [ ] Test offline functionality
- [ ] Test on different screen sizes
- [ ] Test with slow network
- [ ] Test navigation flows thoroughly

---

## 📚 Related Features

### Current Features Enhanced
- Collections screen (add IA collections)
- Archive detail screen (add collection navigation)
- Search (add collection filter)

### Future Features Enabled
- Collection recommendations
- Collection sharing
- Collection creation from IA items
- Collection statistics/analytics
- Collection export/import

---

## 📝 Documentation Needs

- [ ] Update user guide with collection features
- [ ] Add collection navigation tutorial
- [ ] Document IA collection API usage
- [ ] Create developer guide for collection models
- [ ] Add screenshots to app store listing

---

## 🚀 Rollout Plan

### Staged Rollout

1. **Week 1: Core Implementation**
   - Data models and services
   - Basic collection view screen
   - Collection chips in archive detail

2. **Week 2: Navigation & Polish**
   - Next/previous navigation
   - Layout overhaul
   - Bookmarking system

3. **Week 3: Testing & Refinement**
   - Beta testing with users
   - Performance optimization
   - Bug fixes and polish

4. **Week 4: Release**
   - Production release
   - Monitor metrics
   - Gather user feedback

---

## ✅ Definition of Done

- [ ] All UI components implemented and polished
- [ ] All API integrations working
- [ ] Database operations tested
- [ ] Navigation flows smooth and intuitive
- [ ] Offline mode functional
- [ ] Zero critical bugs
- [ ] Flutter analyze: 0 issues
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Accessibility requirements met
- [ ] Performance targets met
- [ ] Code reviewed and approved

---

**Document Version:** 1.0  
**Last Updated:** October 8, 2025  
**Author:** Development Team  
**Status:** Ready for Implementation
