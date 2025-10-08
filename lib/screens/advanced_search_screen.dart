import 'package:flutter/material.dart';
import 'package:internet_archive_helper/models/date_range.dart';
import 'package:internet_archive_helper/models/saved_search.dart';
import 'package:internet_archive_helper/models/search_history_entry.dart';
import 'package:internet_archive_helper/models/search_query.dart';
import 'package:internet_archive_helper/models/sort_option.dart';
import 'package:internet_archive_helper/services/saved_search_service.dart';
import 'package:internet_archive_helper/services/search_history_service.dart';

/// Material Design 3 compliant advanced search screen
///
/// Features:
/// - Full-text search with autocomplete
/// - Field-specific searches (title, creator, subject, etc.)
/// - Mediatype filtering with chips
/// - Date range filtering
/// - Sort options
/// - Search history with suggestions
/// - Saved searches management
/// - MD3 animations and transitions
class AdvancedSearchScreen extends StatefulWidget {
  static const String routeName = '/advanced-search';
  
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final _searchHistoryService = SearchHistoryService.instance;
  final _savedSearchService = SavedSearchService.instance;

  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _creatorController = TextEditingController();
  final _subjectController = TextEditingController();
  final _scrollController = ScrollController();

  // Search state
  SearchQuery _currentQuery = const SearchQuery();
  List<String> _selectedMediatypes = [];
  DateRange? _selectedDateRange;
  SortOption _sortOption = SortOption.relevance;

  // UI state
  bool _showFieldSearch = false;
  bool _showSuggestions = false;
  List<SearchHistoryEntry> _suggestions = [];
  List<SavedSearch> _savedSearches = [];

  // Available mediatypes
  static const _availableMediatypes = [
    'texts',
    'movies',
    'audio',
    'image',
    'software',
    'data',
    'web',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
    _searchController.addListener(_onSearchTextChanged);

    // Listen to service changes
    _savedSearchService.addListener(_onSavedSearchesChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _creatorController.dispose();
    _subjectController.dispose();
    _scrollController.dispose();
    _savedSearchService.removeListener(_onSavedSearchesChanged);
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      _loadSuggestions(query);
    } else {
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
    }
  }

  void _onSavedSearchesChanged() {
    _loadSavedSearches();
  }

  Future<void> _loadSuggestions(String prefix) async {
    try {
      final suggestions = await _searchHistoryService.getSuggestions(prefix);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      // Silently fail - suggestions are optional
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  Future<void> _loadSavedSearches() async {
    try {
      final searches = await _savedSearchService.getAllSavedSearches();
      if (mounted) {
        setState(() {
          _savedSearches = searches;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _buildQuery() {
    final fieldQueries = <String, String>{};

    if (_titleController.text.trim().isNotEmpty) {
      fieldQueries['title'] = _titleController.text.trim();
    }
    if (_creatorController.text.trim().isNotEmpty) {
      fieldQueries['creator'] = _creatorController.text.trim();
    }
    if (_subjectController.text.trim().isNotEmpty) {
      fieldQueries['subject'] = _subjectController.text.trim();
    }

    setState(() {
      _currentQuery = SearchQuery(
        query: _searchController.text.trim().isEmpty 
            ? null 
            : _searchController.text.trim(),
        fieldQueries: fieldQueries,
        mediatypes: _selectedMediatypes,
        dateRange: _selectedDateRange,
        sortBy: _sortOption,
      );
    });
  }

  Future<void> _executeSearch() async {
    // Build final query
    _buildQuery();

    // Validate query
    if (_currentQuery.query == null &&
        _currentQuery.fieldQueries.isEmpty &&
        _currentQuery.mediatypes.isEmpty &&
        _currentQuery.dateRange == null) {
      _showSnackBar('Please enter a search query or select filters');
      return;
    }

    // Hide suggestions
    setState(() {
      _showSuggestions = false;
    });

    // Add to history
    final entry = SearchHistoryEntry(
      query: _currentQuery.buildQueryString(),
      timestamp: DateTime.now(),
    );
    await _searchHistoryService.addEntry(entry);

    // Navigate to search results screen
    if (!mounted) return;
    
    await Navigator.pushNamed(
      context,
      '/search-results',
      arguments: {
        'query': _currentQuery,
        'title': _currentQuery.buildQueryString(),
      },
    );
  }

  Future<void> _navigateToSavedSearches() async {
    final result = await Navigator.pushNamed(
      context,
      '/saved-searches',
    );

    // If a saved search was returned, load it
    if (result is SavedSearch && mounted) {
      await _loadSavedSearch(result);
    }
  }

  Future<void> _saveSearch() async {
    _buildQuery();

    if (_currentQuery.query == null && _currentQuery.fieldQueries.isEmpty) {
      _showSnackBar('Please enter a search query first');
      return;
    }

    await _showSaveSearchDialog();
  }

  Future<void> _showSaveSearchDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Search'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Search Name',
                  hintText: 'My Apollo Search',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Searches for Apollo mission archives',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      final savedSearch = SavedSearch(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        query: _currentQuery,
        createdAt: DateTime.now(),
      );

      try {
        await _savedSearchService.createSavedSearch(savedSearch);
        if (mounted) {
          _showSnackBar('Search saved successfully');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error saving search: $e');
        }
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _loadSavedSearch(SavedSearch savedSearch) async {
    setState(() {
      _currentQuery = savedSearch.query;
      _searchController.text = savedSearch.query.query ?? '';
      _selectedMediatypes = List.from(savedSearch.query.mediatypes);
      _selectedDateRange = savedSearch.query.dateRange;
      _sortOption = savedSearch.query.sortBy;

      // Load field queries
      if (savedSearch.query.fieldQueries.containsKey('title')) {
        _titleController.text = savedSearch.query.fieldQueries['title']!;
      }
      if (savedSearch.query.fieldQueries.containsKey('creator')) {
        _creatorController.text = savedSearch.query.fieldQueries['creator']!;
      }
      if (savedSearch.query.fieldQueries.containsKey('subject')) {
        _subjectController.text = savedSearch.query.fieldQueries['subject']!;
      }
    });

    // Mark as used
    await _savedSearchService.markSearchUsed(savedSearch.id!);

    _showSnackBar('Loaded: ${savedSearch.name}');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _titleController.clear();
      _creatorController.clear();
      _subjectController.clear();
      _selectedMediatypes.clear();
      _selectedDateRange = null;
      _sortOption = SortOption.relevance;
      _showFieldSearch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBody(),
          if (_showSuggestions) _buildSuggestionsOverlay(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Advanced Search'),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _saveSearch,
          tooltip: 'Save this search',
        ),
        IconButton(
          icon: const Icon(Icons.clear_all),
          onPressed: _clearFilters,
          tooltip: 'Clear all filters',
        ),
        IconButton(
          icon: const Icon(Icons.bookmark),
          onPressed: _navigateToSavedSearches,
          tooltip: 'Saved searches',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchField(),
          const SizedBox(height: 16),
          _buildFieldSearchToggle(),
          if (_showFieldSearch) ...[
            const SizedBox(height: 16),
            _buildFieldSearchSection(),
          ],
          const SizedBox(height: 24),
          _buildMediatypeFilters(),
          const SizedBox(height: 24),
          _buildDateRangeFilter(),
          const SizedBox(height: 24),
          _buildSortOptions(),
          const SizedBox(height: 24),
          _buildSavedSearches(),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search Internet Archive',
        hintText: 'Enter keywords...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => _executeSearch(),
    );
  }

  Widget _buildFieldSearchToggle() {
    return Card(
      child: InkWell(
        onTap: () => setState(() => _showFieldSearch = !_showFieldSearch),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _showFieldSearch ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Field-Specific Search',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const Spacer(),
              if (_titleController.text.isNotEmpty ||
                  _creatorController.text.isNotEmpty ||
                  _subjectController.text.isNotEmpty)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Search in title field',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _creatorController,
              decoration: const InputDecoration(
                labelText: 'Creator',
                hintText: 'Search by creator/author',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                hintText: 'Search by subject/topic',
                prefixIcon: Icon(Icons.label),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediatypeFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media Types',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableMediatypes.map((mediatype) {
            final isSelected = _selectedMediatypes.contains(mediatype);
            return FilterChip(
              label: Text(_formatMediatype(mediatype)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMediatypes.add(mediatype);
                  } else {
                    _selectedMediatypes.remove(mediatype);
                  }
                });
              },
              avatar: isSelected ? null : Icon(_getMediaTypeIcon(mediatype)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_selectedDateRange != null) ...[
              Text(
                _selectedDateRange!.toDisplayString(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: _showDateRangePicker,
                    child: const Text('Change'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => setState(() => _selectedDateRange = null),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ] else ...[
              const Text('No date range selected'),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: _showDateRangePicker,
                child: const Text('Select Date Range'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    // Show preset options first
    final preset = await showDialog<DateRange?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Date Range'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Last 7 days'),
                  onTap: () => Navigator.pop(context, DateRange.lastDays(7)),
                ),
                ListTile(
                  title: const Text('Last 30 days'),
                  onTap: () => Navigator.pop(context, DateRange.lastDays(30)),
                ),
                ListTile(
                  title: const Text('This month'),
                  onTap: () => Navigator.pop(context, DateRange.thisMonth()),
                ),
                ListTile(
                  title: const Text('This year'),
                  onTap: () => Navigator.pop(context, DateRange.thisYear()),
                ),
                ListTile(
                  title: const Text('Last year'),
                  onTap: () => Navigator.pop(context, DateRange.lastYears(1)),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Custom range...'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _showCustomDatePicker();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (preset != null && mounted) {
      setState(() => _selectedDateRange = preset);
    }
  }

  Future<void> _showCustomDatePicker() async {
    DateTime? startDate;
    DateTime? endDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Custom Date Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select start and end dates',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Start date
                  FilledButton.tonal(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime(1800),
                        lastDate: endDate ?? DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => startDate = date);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          startDate != null
                              ? 'Start: ${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}'
                              : 'Select Start Date',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // End date
                  FilledButton.tonal(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? startDate ?? DateTime.now(),
                        firstDate: startDate ?? DateTime(1800),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setDialogState(() => endDate = date);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          endDate != null
                              ? 'End: ${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
                              : 'Select End Date',
                        ),
                      ],
                    ),
                  ),
                  if (startDate != null && endDate != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${endDate!.difference(startDate!).inDays} days',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: startDate != null && endDate != null
                      ? () => Navigator.pop(context, true)
                      : null,
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && startDate != null && endDate != null && mounted) {
      setState(() {
        _selectedDateRange = DateRange(
          start: startDate!,
          end: endDate!,
        );
      });
      
      final label = 'Custom: ${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')} to ${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';
      _showSnackBar(label);
    }
  }

  Widget _buildSortOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SortOption.values.map((option) {
                return ChoiceChip(
                  label: Text(option.displayName),
                  selected: _sortOption == option,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _sortOption = option);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedSearches() {
    if (_savedSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Saved Searches',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: _navigateToSavedSearches,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._savedSearches.take(3).map((savedSearch) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                savedSearch.isPinned ? Icons.push_pin : Icons.bookmark_outline,
              ),
              title: Text(savedSearch.name),
              subtitle: Text(
                savedSearch.summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(savedSearch.lastUsedDisplay),
              onTap: () => _loadSavedSearch(savedSearch),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      top: 72, // Below search field
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(suggestion.query),
                subtitle: Text(suggestion.subtitle),
                onTap: () {
                  _searchController.text = suggestion.query;
                  setState(() => _showSuggestions = false);
                  _executeSearch();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget? _buildFAB() {
    // Only show FAB if there's a query to save
    if (_searchController.text.trim().isEmpty &&
        _titleController.text.trim().isEmpty &&
        _creatorController.text.trim().isEmpty &&
        _subjectController.text.trim().isEmpty) {
      return null;
    }

    return FloatingActionButton.extended(
      onPressed: _executeSearch,
      icon: const Icon(Icons.search),
      label: const Text('Search'),
    );
  }

  String _formatMediatype(String mediatype) {
    return mediatype[0].toUpperCase() + mediatype.substring(1);
  }

  IconData _getMediaTypeIcon(String mediatype) {
    switch (mediatype.toLowerCase()) {
      case 'texts':
        return Icons.article;
      case 'movies':
        return Icons.movie;
      case 'audio':
        return Icons.audiotrack;
      case 'image':
        return Icons.image;
      case 'software':
        return Icons.computer;
      case 'data':
        return Icons.dataset;
      case 'web':
        return Icons.public;
      default:
        return Icons.archive;
    }
  }
}
