// Enhanced Home Screen Integration Example
// This shows how to safely handle SearchAction from EnhancedSearchBar

void _handleSearchAction(String query, SearchAction action) async {
  switch (action) {
    case SearchAction.openArchive:
      // DEFENSE LAYER: Double-check before loading
      final archiveService = context.read<ArchiveService>();
      
      // Show loading indicator
      setState(() => _isLoading = true);
      
      // Try to load metadata
      await archiveService.loadMetadata(query);
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      // Check if metadata loaded successfully
      if (archiveService.currentMetadata != null && 
          archiveService.error == null) {
        // ✅ Archive exists - navigate to detail screen
        Navigator.of(context).push(
          MD3PageTransitions.fadeThrough(
            page: const ArchiveDetailScreen(),
          ),
        );
      } else {
        // ❌ Archive not found (edge case - shouldn't happen)
        // Show helpful error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Archive "$query" not found. Try searching instead.',
            ),
            action: SnackBarAction(
              label: 'Search',
              onPressed: () {
                // Trigger keyword search as fallback
                _handleSearchAction(query, SearchAction.searchKeyword);
              },
            ),
          ),
        );
      }
      break;
      
    case SearchAction.searchKeyword:
      // Navigate to search results screen
      Navigator.of(context).push(
        MD3PageTransitions.fadeThrough(
          page: SearchResultsScreen(query: query),
        ),
      );
      break;
  }
}

// Usage in widget:
EnhancedSearchBar(
  onSearch: _handleSearchAction,
  autofocus: false,
)
