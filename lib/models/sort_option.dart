/// Sort Options for Internet Archive Search
///
/// Represents different ways to sort search results from the Internet Archive.
///
/// API Reference: https://archive.org/developers/search.html#sorting
library;

/// Sort options for Internet Archive search results
enum SortOption {
  /// Sort by relevance (default)
  /// Best match first based on query terms
  relevance,

  /// Sort by most downloads
  /// Items with highest download count first
  downloads,

  /// Sort by publication date (newest first)
  /// Based on publicdate field
  date,

  /// Sort by title (A-Z)
  /// Alphabetical by title
  title,

  /// Sort by weekly views
  /// Items with most views in past week
  weeklyViews,

  /// Sort by creation date (newest first)
  /// Based on addeddate field
  addedDate,

  /// Sort by update date (most recently updated)
  /// Based on updatedate field
  updateDate,

  /// Sort by review date (newest first)
  /// Based on reviewdate field
  reviewDate,

  /// Sort by item size (largest first)
  /// Based on item_size field
  itemSize;

  /// Convert to Internet Archive API sort parameter
  String toApiString() {
    switch (this) {
      case SortOption.relevance:
        return ''; // Default, no sort parameter needed
      case SortOption.downloads:
        return '-downloads'; // Minus prefix for descending
      case SortOption.date:
        return '-publicdate';
      case SortOption.title:
        return 'title'; // Ascending alphabetical
      case SortOption.weeklyViews:
        return '-week';
      case SortOption.addedDate:
        return '-addeddate';
      case SortOption.updateDate:
        return '-updatedate';
      case SortOption.reviewDate:
        return '-reviewdate';
      case SortOption.itemSize:
        return '-item_size';
    }
  }

  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.downloads:
        return 'Most Downloaded';
      case SortOption.date:
        return 'Date Published (Newest)';
      case SortOption.title:
        return 'Title (A-Z)';
      case SortOption.weeklyViews:
        return 'Trending This Week';
      case SortOption.addedDate:
        return 'Recently Added';
      case SortOption.updateDate:
        return 'Recently Updated';
      case SortOption.reviewDate:
        return 'Recently Reviewed';
      case SortOption.itemSize:
        return 'Size (Largest)';
    }
  }

  /// Get icon name for Material Icons
  String get iconName {
    switch (this) {
      case SortOption.relevance:
        return 'star';
      case SortOption.downloads:
        return 'download';
      case SortOption.date:
        return 'calendar_today';
      case SortOption.title:
        return 'sort_by_alpha';
      case SortOption.weeklyViews:
        return 'trending_up';
      case SortOption.addedDate:
        return 'fiber_new';
      case SortOption.updateDate:
        return 'update';
      case SortOption.reviewDate:
        return 'rate_review';
      case SortOption.itemSize:
        return 'storage';
    }
  }

  /// Get description for UI tooltips
  String get description {
    switch (this) {
      case SortOption.relevance:
        return 'Best match for your search terms';
      case SortOption.downloads:
        return 'Items with most total downloads';
      case SortOption.date:
        return 'Most recently published items';
      case SortOption.title:
        return 'Alphabetically by title';
      case SortOption.weeklyViews:
        return 'Most viewed in past week';
      case SortOption.addedDate:
        return 'Most recently added to archive';
      case SortOption.updateDate:
        return 'Most recently modified';
      case SortOption.reviewDate:
        return 'Most recently reviewed';
      case SortOption.itemSize:
        return 'Largest items first';
    }
  }

  /// Create from API string (reverse of toApiString)
  static SortOption fromApiString(String apiString) {
    switch (apiString) {
      case '':
        return SortOption.relevance;
      case '-downloads':
        return SortOption.downloads;
      case '-publicdate':
        return SortOption.date;
      case 'title':
        return SortOption.title;
      case '-week':
        return SortOption.weeklyViews;
      case '-addeddate':
        return SortOption.addedDate;
      case '-updatedate':
        return SortOption.updateDate;
      case '-reviewdate':
        return SortOption.reviewDate;
      case '-item_size':
        return SortOption.itemSize;
      default:
        return SortOption.relevance;
    }
  }
}
