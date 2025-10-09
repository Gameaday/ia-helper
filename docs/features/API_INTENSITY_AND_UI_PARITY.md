# API Intensity Settings & Internet Archive UI Parity

**Date:** October 9, 2025  
**Phase:** Phase 5 - Enhanced Search System  
**Priority:** HIGH  
**Related:** Core Services Architecture Analysis  

---

## Overview

### Goals

1. **User Control:** Allow users to reduce API calls and data usage
2. **UI Parity:** Match Internet Archive's card/chip design for familiarity
3. **Graceful Degradation:** App works beautifully at all API intensity levels
4. **Material Design 3:** Maintain MD3 compliance while matching IA aesthetics

### Why This Matters

**User Empowerment:**
- Some users have limited bandwidth/data plans
- Some users want faster performance (fewer API calls)
- Power users may want all metadata + thumbnails
- Casual users may only need titles

**Familiar Experience:**
- Users coming from archive.org feel immediately comfortable
- Visual consistency reduces cognitive load
- Standard patterns = predictable behavior
- Smooth transition between web and mobile

---

## Internet Archive UI Analysis

### Card/Chip Design Patterns (from archive.org/details/texts & /movies)

**Visual Hierarchy:**
```
┌─────────────────────────────────────┐
│  [Thumbnail]  Title                 │
│   120x160     Creator/Author        │
│   (Cover)     Year • Format         │
│               ★★★★☆ (4.2) 1.2K      │
└─────────────────────────────────────┘
```

**Key Elements:**
1. **Thumbnail (Left):**
   - Cover image/poster/preview
   - Consistent aspect ratio (3:4 for books, 16:9 for videos)
   - Placeholder for missing images
   - Subtle border/shadow

2. **Title (Top Right):**
   - Bold, prominent typography
   - 2-3 lines max with ellipsis
   - Tappable for details

3. **Metadata (Below Title):**
   - Creator/Author in secondary text
   - Date and media type
   - Rating and download count
   - Subtle, readable at a glance

4. **Layout Options:**
   - **Grid View:** 2-3 columns on mobile, more on tablet
   - **List View:** Full width cards with larger thumbnails
   - **Compact View:** Smaller cards, less metadata

**Color & Elevation:**
- White/Dark background (theme-aware)
- Subtle elevation (MD3 level 1-2)
- Hover/tap states with MD3 ripple
- Thumbnail border: subtle gray

**Responsive Design:**
- Mobile: 2 columns (portrait) or 3 (landscape)
- Tablet: 3-4 columns
- Adapts to screen width gracefully

---

## API Intensity Levels

### Level 1: Full ⚡⚡⚡
**Description:** Maximum detail, all features enabled  
**API Calls:** ~5-10 per item  
**Data Usage:** ~200-500 KB per item  

**What's Included:**
- ✅ Full metadata (title, description, creator, date, etc.)
- ✅ Thumbnails/cover images
- ✅ File listings
- ✅ Rating and statistics
- ✅ Related items
- ✅ Preview generation
- ✅ Metadata preloading (trending items)

**Best For:**
- WiFi connections
- Unlimited data plans
- Power users
- Research/browsing

---

### Level 2: Standard ⚡⚡ (Default)
**Description:** Balanced performance and detail  
**API Calls:** ~2-3 per item  
**Data Usage:** ~50-100 KB per item  

**What's Included:**
- ✅ Basic metadata (title, creator, date, format)
- ✅ Thumbnails/cover images
- ✅ Essential statistics (downloads, views)
- ❌ Extended descriptions
- ❌ Full file listings (show on detail screen)
- ❌ Related items
- ✅ Selective preloading

**Best For:**
- Mobile data
- Standard usage
- Most users

---

### Level 3: Minimal ⚡
**Description:** Fast and lightweight  
**API Calls:** ~1 per item  
**Data Usage:** ~5-10 KB per item  

**What's Included:**
- ✅ Title and identifier
- ✅ Basic format info
- ❌ Thumbnails (show placeholder)
- ❌ Descriptions
- ❌ Statistics
- ❌ Preloading

**Best For:**
- Slow connections
- Limited data plans
- Quick searches
- Identifier lookups

---

### Level 4: Cache Only 📴
**Description:** Offline mode, no API calls  
**API Calls:** 0  
**Data Usage:** 0  

**What's Included:**
- ✅ Cached search results
- ✅ Cached metadata
- ✅ Downloaded archives
- ✅ Favorites (cached)
- ❌ New searches
- ❌ Live data

**Best For:**
- Offline usage
- Airplane mode
- Zero data usage
- Testing

---

## Implementation Plan

### Phase 1: Models & Settings (Days 1-2)

#### 1.1: Create API Intensity Settings Model

**File:** `lib/models/api_intensity_settings.dart`

```dart
enum ApiIntensityLevel {
  full,      // ⚡⚡⚡ All features
  standard,  // ⚡⚡ Balanced (default)
  minimal,   // ⚡ Fast & light
  cacheOnly, // 📴 Offline
}

class ApiIntensitySettings {
  final ApiIntensityLevel level;
  final bool loadThumbnails;
  final bool preloadMetadata;
  final bool loadExtendedMetadata;
  final bool loadStatistics;
  final bool loadRelatedItems;
  final int maxConcurrentRequests;
  
  // Constructor with defaults based on level
  const ApiIntensitySettings({
    this.level = ApiIntensityLevel.standard,
    bool? loadThumbnails,
    bool? preloadMetadata,
    bool? loadExtendedMetadata,
    bool? loadStatistics,
    bool? loadRelatedItems,
    int? maxConcurrentRequests,
  }) : loadThumbnails = loadThumbnails ?? _defaultLoadThumbnails(level),
       preloadMetadata = preloadMetadata ?? _defaultPreloadMetadata(level),
       loadExtendedMetadata = loadExtendedMetadata ?? _defaultLoadExtendedMetadata(level),
       loadStatistics = loadStatistics ?? _defaultLoadStatistics(level),
       loadRelatedItems = loadRelatedItems ?? _defaultLoadRelatedItems(level),
       maxConcurrentRequests = maxConcurrentRequests ?? _defaultMaxConcurrentRequests(level);
  
  // Preset factories
  factory ApiIntensitySettings.full() => const ApiIntensitySettings(
    level: ApiIntensityLevel.full,
    loadThumbnails: true,
    preloadMetadata: true,
    loadExtendedMetadata: true,
    loadStatistics: true,
    loadRelatedItems: true,
    maxConcurrentRequests: 10,
  );
  
  factory ApiIntensitySettings.standard() => const ApiIntensitySettings(
    level: ApiIntensityLevel.standard,
    loadThumbnails: true,
    preloadMetadata: true,
    loadExtendedMetadata: false,
    loadStatistics: true,
    loadRelatedItems: false,
    maxConcurrentRequests: 5,
  );
  
  factory ApiIntensitySettings.minimal() => const ApiIntensitySettings(
    level: ApiIntensityLevel.minimal,
    loadThumbnails: false,
    preloadMetadata: false,
    loadExtendedMetadata: false,
    loadStatistics: false,
    loadRelatedItems: false,
    maxConcurrentRequests: 2,
  );
  
  factory ApiIntensitySettings.cacheOnly() => const ApiIntensitySettings(
    level: ApiIntensityLevel.cacheOnly,
    loadThumbnails: false,
    preloadMetadata: false,
    loadExtendedMetadata: false,
    loadStatistics: false,
    loadRelatedItems: false,
    maxConcurrentRequests: 0,
  );
  
  // Estimated data usage per item
  int get estimatedDataUsagePerItem {
    switch (level) {
      case ApiIntensityLevel.full:
        return 350; // KB
      case ApiIntensityLevel.standard:
        return 75; // KB
      case ApiIntensityLevel.minimal:
        return 7; // KB
      case ApiIntensityLevel.cacheOnly:
        return 0;
    }
  }
  
  // User-friendly description
  String get description {
    switch (level) {
      case ApiIntensityLevel.full:
        return 'Maximum detail with all features enabled. Best for WiFi.';
      case ApiIntensityLevel.standard:
        return 'Balanced performance and detail. Recommended for most users.';
      case ApiIntensityLevel.minimal:
        return 'Fast and lightweight. Best for slow connections.';
      case ApiIntensityLevel.cacheOnly:
        return 'Offline mode. No API calls, cached data only.';
    }
  }
  
  // JSON serialization
  Map<String, dynamic> toJson() => {
    'level': level.name,
    'loadThumbnails': loadThumbnails,
    'preloadMetadata': preloadMetadata,
    'loadExtendedMetadata': loadExtendedMetadata,
    'loadStatistics': loadStatistics,
    'loadRelatedItems': loadRelatedItems,
    'maxConcurrentRequests': maxConcurrentRequests,
  };
  
  factory ApiIntensitySettings.fromJson(Map<String, dynamic> json) {
    final level = ApiIntensityLevel.values.firstWhere(
      (e) => e.name == json['level'],
      orElse: () => ApiIntensityLevel.standard,
    );
    
    return ApiIntensitySettings(
      level: level,
      loadThumbnails: json['loadThumbnails'] as bool?,
      preloadMetadata: json['preloadMetadata'] as bool?,
      loadExtendedMetadata: json['loadExtendedMetadata'] as bool?,
      loadStatistics: json['loadStatistics'] as bool?,
      loadRelatedItems: json['loadRelatedItems'] as bool?,
      maxConcurrentRequests: json['maxConcurrentRequests'] as int?,
    );
  }
  
  copyWith({...}) => ApiIntensitySettings(...);
}
```

#### 1.2: Add Thumbnail Support to Models

**Update:** `lib/models/search_result.dart`

```dart
class SearchResult {
  final String identifier;
  final String title;
  final String description;
  final String? thumbnailUrl;  // NEW
  final String? creator;       // NEW
  final String? mediaType;     // NEW
  final int? downloads;        // NEW
  
  SearchResult({
    required this.identifier,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.creator,
    this.mediaType,
    this.downloads,
  });
  
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    // Extract thumbnail from various possible fields
    String? thumbnailUrl;
    if (json['__ia_thumb_url'] != null) {
      thumbnailUrl = json['__ia_thumb_url'];
    } else if (json['identifier'] != null) {
      // Generate standard thumbnail URL
      final id = json['identifier'];
      thumbnailUrl = 'https://archive.org/services/img/$id';
    }
    
    return SearchResult(
      identifier: _extractString(json['identifier'], ''),
      title: _extractString(json['title'], 'Untitled'),
      description: _extractString(json['description'], ''),
      thumbnailUrl: thumbnailUrl,
      creator: _extractString(json['creator'], null),
      mediaType: _extractString(json['mediatype'], null),
      downloads: json['downloads'] as int?,
    );
  }
}
```

**Update:** `lib/models/archive_metadata.dart`

```dart
class ArchiveMetadata {
  // ... existing fields
  final String? thumbnailUrl;       // NEW
  final String? coverImageUrl;      // NEW - high-res version
  final String? mediaType;          // NEW
  final int? downloads;             // NEW
  final double? rating;             // NEW
  
  ArchiveMetadata({
    // ... existing params
    this.thumbnailUrl,
    this.coverImageUrl,
    this.mediaType,
    this.downloads,
    this.rating,
  });
  
  factory ArchiveMetadata.fromJson(Map<String, dynamic> json) {
    final identifier = /* ... existing extraction ... */;
    
    // Extract thumbnail URLs
    String? thumbnailUrl;
    String? coverImageUrl;
    
    if (json['misc']?['image'] != null) {
      final image = json['misc']['image'];
      thumbnailUrl = 'https://archive.org$image';
      coverImageUrl = thumbnailUrl.replaceAll('__ia_thumb.jpg', '.jpg');
    } else {
      // Generate from identifier
      thumbnailUrl = 'https://archive.org/services/img/$identifier';
    }
    
    return ArchiveMetadata(
      // ... existing fields
      thumbnailUrl: thumbnailUrl,
      coverImageUrl: coverImageUrl,
      mediaType: json['metadata']?['mediatype'],
      downloads: json['downloads'] as int?,
      rating: (json['reviews']?['avg_rating'] as num?)?.toDouble(),
      // ...
    );
  }
}
```

---

### Phase 2: Settings UI (Day 3)

#### 2.1: Add API Settings Section to Settings Screen

**Update:** `lib/screens/settings_screen.dart`

```dart
// Add new section after existing settings
ListTile(
  title: Text('API & Performance'),
  subtitle: Text('Control data usage and API calls'),
  leading: Icon(Icons.api_rounded),
  trailing: Icon(Icons.chevron_right),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ApiSettingsScreen(),
    ),
  ),
),
```

#### 2.2: Create API Settings Screen

**New File:** `lib/screens/api_settings_screen.dart`

```dart
class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  late ApiIntensitySettings _settings;
  
  @override
  void initState() {
    super.initState();
    // Load from shared preferences
    _settings = ApiIntensitySettings.standard();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API & Performance'),
      ),
      body: ListView(
        children: [
          // Intensity Level Selector
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API Intensity Level',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    _settings.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  SizedBox(height: 16),
                  
                  // Level options
                  _buildLevelOption(
                    ApiIntensityLevel.full,
                    '⚡⚡⚡ Full',
                    'All features, ~350 KB/item',
                    'Best for WiFi',
                  ),
                  _buildLevelOption(
                    ApiIntensityLevel.standard,
                    '⚡⚡ Standard',
                    'Balanced, ~75 KB/item',
                    'Recommended',
                  ),
                  _buildLevelOption(
                    ApiIntensityLevel.minimal,
                    '⚡ Minimal',
                    'Fast & light, ~7 KB/item',
                    'Best for mobile data',
                  ),
                  _buildLevelOption(
                    ApiIntensityLevel.cacheOnly,
                    '📴 Cache Only',
                    'Offline mode, 0 KB',
                    'No network access',
                  ),
                ],
              ),
            ),
          ),
          
          // Advanced Options (if not cache-only)
          if (_settings.level != ApiIntensityLevel.cacheOnly) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Advanced Options',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            
            SwitchListTile(
              title: Text('Load Thumbnails'),
              subtitle: Text('Show cover images in search results'),
              value: _settings.loadThumbnails,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(loadThumbnails: value);
                });
              },
            ),
            
            SwitchListTile(
              title: Text('Preload Metadata'),
              subtitle: Text('Cache popular items for instant access'),
              value: _settings.preloadMetadata,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(preloadMetadata: value);
                });
              },
            ),
            
            // ... more switches
          ],
          
          // Estimated Usage
          Card(
            margin: EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.data_usage_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Estimated Usage',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '~${_settings.estimatedDataUsagePerItem} KB per item',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '~${(_settings.estimatedDataUsagePerItem * 50 / 1024).toStringAsFixed(1)} MB for 50 items',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLevelOption(...) {
    // Radio tile with icon, title, subtitle, and badge
  }
}
```

---

### Phase 3: IA-Style Result Cards (Days 4-5)

#### 3.1: Create Reusable Archive Card Widget

**New File:** `lib/widgets/archive_result_card.dart`

```dart
/// Archive result card matching Internet Archive design
/// Supports both grid and list layouts with MD3 styling
class ArchiveResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;
  final bool isGridView;
  final bool showThumbnail;
  
  const ArchiveResultCard({
    super.key,
    required this.result,
    required this.onTap,
    this.isGridView = false,
    this.showThumbnail = true,
  });
  
  @override
  Widget build(BuildContext context) {
    if (isGridView) {
      return _buildGridCard(context);
    } else {
      return _buildListCard(context);
    }
  }
  
  Widget _buildGridCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail (3:4 aspect ratio for books, 16:9 for videos)
            AspectRatio(
              aspectRatio: _getAspectRatio(),
              child: _buildThumbnail(context),
            ),
            
            // Metadata
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    result.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  if (result.creator != null) ...[
                    SizedBox(height: 4),
                    Text(
                      result.creator!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  if (result.downloads != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.download_rounded, size: 14),
                        SizedBox(width: 4),
                        Text(
                          _formatDownloads(result.downloads!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildListCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if (showThumbnail)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 120,
                    child: _buildThumbnail(context),
                  ),
                ),
              
              SizedBox(width: 12),
              
              // Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (result.creator != null) ...[
                      SizedBox(height: 4),
                      Text(
                        result.creator!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    
                    if (result.description.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        result.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        if (result.mediaType != null)
                          _buildChip(
                            context,
                            Icons.category_rounded,
                            result.mediaType!,
                          ),
                        if (result.downloads != null)
                          _buildChip(
                            context,
                            Icons.download_rounded,
                            _formatDownloads(result.downloads!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildThumbnail(BuildContext context) {
    if (!showThumbnail || result.thumbnailUrl == null) {
      return _buildPlaceholder(context);
    }
    
    return Image.network(
      result.thumbnailUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildPlaceholder(context);
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(context);
      },
    );
  }
  
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          _getMediaIcon(),
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
  
  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  double _getAspectRatio() {
    if (result.mediaType == 'texts') return 3 / 4;
    if (result.mediaType == 'movies') return 16 / 9;
    return 1.0;
  }
  
  IconData _getMediaIcon() {
    switch (result.mediaType) {
      case 'texts':
        return Icons.menu_book_rounded;
      case 'movies':
        return Icons.movie_rounded;
      case 'audio':
        return Icons.audiotrack_rounded;
      case 'software':
        return Icons.computer_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
  
  String _formatDownloads(int downloads) {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    }
    if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    }
    return downloads.toString();
  }
}
```

---

### Phase 4: Service Integration (Days 6-7)

#### 4.1: Update Services to Respect API Settings

**Update:** `lib/services/advanced_search_service.dart`

```dart
class AdvancedSearchService {
  final ApiIntensitySettings settings;
  
  Future<List<SearchResult>> search(SearchQuery query) async {
    // Check cache-only mode
    if (settings.level == ApiIntensityLevel.cacheOnly) {
      return _searchCache(query);
    }
    
    // Adjust fields based on intensity
    final fields = _getFieldsForIntensity();
    
    // Adjust rows based on intensity (fewer items = fewer API calls)
    final rows = settings.level == ApiIntensityLevel.minimal ? 10 : 25;
    
    // Make API call with adjusted parameters
    final response = await _api.search(
      query: query.query,
      fields: fields,
      rows: rows,
    );
    
    // Conditionally load thumbnails
    if (settings.loadThumbnails) {
      await _loadThumbnails(results);
    }
    
    return results;
  }
  
  List<String> _getFieldsForIntensity() {
    switch (settings.level) {
      case ApiIntensityLevel.full:
        return [
          'identifier', 'title', 'description', 'creator',
          'date', 'mediatype', 'downloads', 'avg_rating',
          '__ia_thumb_url', 'subject', 'collection',
        ];
      case ApiIntensityLevel.standard:
        return [
          'identifier', 'title', 'description', 'creator',
          'mediatype', 'downloads', '__ia_thumb_url',
        ];
      case ApiIntensityLevel.minimal:
        return ['identifier', 'title', 'mediatype'];
      case ApiIntensityLevel.cacheOnly:
        return [];
    }
  }
}
```

#### 4.2: Add Thumbnail Caching Service

**New File:** `lib/services/thumbnail_cache_service.dart`

```dart
/// Caches thumbnails to reduce API calls and improve performance
class ThumbnailCacheService {
  static final ThumbnailCacheService _instance = ThumbnailCacheService._internal();
  factory ThumbnailCacheService() => _instance;
  ThumbnailCacheService._internal();
  
  final Map<String, Uint8List> _memoryCache = {};
  final int _maxCacheSize = 100; // MB
  int _currentCacheSize = 0;
  
  /// Get thumbnail from cache or network
  Future<Uint8List?> getThumbnail(String url, {bool allowNetwork = true}) async {
    // Check memory cache
    if (_memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }
    
    // Check disk cache
    final diskCache = await _loadFromDisk(url);
    if (diskCache != null) {
      _memoryCache[url] = diskCache;
      return diskCache;
    }
    
    // Load from network if allowed
    if (allowNetwork) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          await _cacheThumbnail(url, bytes);
          return bytes;
        }
      } catch (e) {
        // Fail silently
      }
    }
    
    return null;
  }
  
  Future<void> _cacheThumbnail(String url, Uint8List bytes) async {
    // Memory cache
    _memoryCache[url] = bytes;
    _currentCacheSize += bytes.length;
    
    // Evict if too large
    if (_currentCacheSize > _maxCacheSize * 1024 * 1024) {
      _evictOldest();
    }
    
    // Disk cache
    await _saveToDisk(url, bytes);
  }
  
  void clearCache() {
    _memoryCache.clear();
    _currentCacheSize = 0;
    // Clear disk cache
  }
}
```

---

### Phase 5: Update Search Results UI (Day 8)

#### 5.1: Update Search Results Screen

**Update:** `lib/screens/search_results_screen.dart`

```dart
class SearchResultsScreen extends StatefulWidget {
  // ...
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isGridView = false;
  late ApiIntensitySettings _apiSettings;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Results'),
        actions: [
          // View toggle
          IconButton(
            icon: Icon(_isGridView ? Icons.list_rounded : Icons.grid_view_rounded),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _buildResults(),
    );
  }
  
  Widget _buildResults() {
    if (_isGridView) {
      return GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ArchiveResultCard(
            result: results[index],
            isGridView: true,
            showThumbnail: _apiSettings.loadThumbnails,
            onTap: () => _openDetails(results[index]),
          );
        },
      );
    } else {
      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ArchiveResultCard(
            result: results[index],
            isGridView: false,
            showThumbnail: _apiSettings.loadThumbnails,
            onTap: () => _openDetails(results[index]),
          );
        },
      );
    }
  }
  
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 5;
    if (width > 900) return 4;
    if (width > 600) return 3;
    return 2;
  }
}
```

---

## Testing Plan

### Unit Tests

1. **ApiIntensitySettings:**
   - Test all factory constructors
   - Test data usage calculations
   - Test JSON serialization

2. **SearchResult/ArchiveMetadata:**
   - Test thumbnail URL extraction
   - Test with/without thumbnails
   - Test graceful degradation

3. **Services:**
   - Test with each intensity level
   - Test cache-only mode
   - Verify API call counts

### Integration Tests

1. **Search Flow:**
   - Search at full intensity
   - Switch to minimal
   - Verify fewer API calls

2. **UI Rendering:**
   - Grid view with thumbnails
   - List view without thumbnails
   - Placeholder handling

3. **Settings Persistence:**
   - Change settings
   - Restart app
   - Verify settings preserved

### Visual Testing

1. **Compare with archive.org:**
   - Screenshot grid view
   - Screenshot list view
   - Verify similar spacing/layout

2. **Dark Mode:**
   - Test all cards in dark mode
   - Verify thumbnail borders visible
   - Check contrast ratios

---

## Success Metrics

### API Reduction:
- Full → Standard: ~60% fewer API calls
- Standard → Minimal: ~80% fewer API calls
- Minimal → Cache Only: 100% fewer API calls

### UI Parity:
- 90%+ visual similarity to IA design
- All MD3 guidelines followed
- Smooth transitions between modes

### User Satisfaction:
- Clear setting descriptions
- Immediate visual feedback
- No confusion about modes

---

## Timeline

**Total:** 8 days

- **Days 1-2:** Models and settings foundation
- **Day 3:** Settings UI
- **Days 4-5:** Result cards and widgets
- **Days 6-7:** Service integration
- **Day 8:** Testing and polish

---

## Future Enhancements

1. **Smart Mode:** Automatically adjust based on connection speed
2. **Download Stats:** Show API call savings in settings
3. **Offline Indicator:** Visual indicator when in cache-only mode
4. **Thumbnail Prefetch:** Prefetch next page of thumbnails
5. **Quality Settings:** HD thumbnails on WiFi, SD on mobile

---

## Conclusion

This implementation provides:
- ✅ **User control** over API usage and data consumption
- ✅ **Familiar UI** matching Internet Archive design
- ✅ **Graceful degradation** across all intensity levels
- ✅ **Material Design 3** compliance throughout
- ✅ **Smooth transitions** between web and mobile experience

Users will feel empowered and comfortable! 🎯
