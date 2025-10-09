import 'package:flutter/material.dart';
import 'package:internet_archive_helper/models/saved_search.dart';
import 'package:internet_archive_helper/services/saved_search_service.dart';

/// Material Design 3 compliant saved searches management screen
///
/// Features:
/// - List all saved searches with metadata
/// - Pin/unpin searches for quick access
/// - Tag management and filtering
/// - Edit search metadata (name, description)
/// - Delete searches
/// - Search within saved searches
/// - Load saved search into AdvancedSearchScreen
/// - Sort options (alphabetical, last used, created date)
/// - MD3 animations and transitions
class SavedSearchesScreen extends StatefulWidget {
  static const String routeName = '/saved-searches';

  const SavedSearchesScreen({super.key});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  final _savedSearchService = SavedSearchService.instance;
  final _searchController = TextEditingController();

  List<SavedSearch> _allSearches = [];
  List<SavedSearch> _filteredSearches = [];
  Set<String> _allTags = {};
  final Set<String> _selectedTags = {};
  bool _isLoading = true;
  _SortOption _sortOption = _SortOption.lastUsed;

  @override
  void initState() {
    super.initState();
    _loadSavedSearches();
    _savedSearchService.addListener(_onSavedSearchesChanged);
    _searchController.addListener(_filterSearches);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _savedSearchService.removeListener(_onSavedSearchesChanged);
    super.dispose();
  }

  void _onSavedSearchesChanged() {
    _loadSavedSearches();
  }

  Future<void> _loadSavedSearches() async {
    setState(() => _isLoading = true);

    try {
      final searches = await _savedSearchService.getAllSavedSearches();
      final tags = await _savedSearchService.getAllTags();

      if (mounted) {
        setState(() {
          _allSearches = searches;
          _allTags = tags.toSet();
          _isLoading = false;
        });
        _filterSearches();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading saved searches: $e');
      }
    }
  }

  void _filterSearches() {
    setState(() {
      var filtered = _allSearches.where((search) {
        // Filter by search text
        final searchText = _searchController.text.toLowerCase();
        if (searchText.isNotEmpty) {
          final matchesName = search.name.toLowerCase().contains(searchText);
          final matchesDescription =
              search.description?.toLowerCase().contains(searchText) ?? false;
          final matchesQuery = search.summary.toLowerCase().contains(
            searchText,
          );

          if (!matchesName && !matchesDescription && !matchesQuery) {
            return false;
          }
        }

        // Filter by tags
        if (_selectedTags.isNotEmpty) {
          final hasMatchingTag = search.tags.any(_selectedTags.contains);
          if (!hasMatchingTag) {
            return false;
          }
        }

        return true;
      }).toList();

      // Sort
      switch (_sortOption) {
        case _SortOption.alphabetical:
          filtered.sort((a, b) => a.name.compareTo(b.name));
        case _SortOption.lastUsed:
          filtered.sort((a, b) {
            if (a.lastUsedAt == null && b.lastUsedAt == null) return 0;
            if (a.lastUsedAt == null) return 1;
            if (b.lastUsedAt == null) return -1;
            return b.lastUsedAt!.compareTo(a.lastUsedAt!);
          });
        case _SortOption.createdDate:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        case _SortOption.useCount:
          filtered.sort((a, b) => b.useCount.compareTo(a.useCount));
      }

      // Pinned items first
      filtered.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return 0;
      });

      _filteredSearches = filtered;
    });
  }

  Future<void> _togglePin(SavedSearch search) async {
    try {
      await _savedSearchService.togglePin(search.id!);
      _loadSavedSearches();
    } catch (e) {
      _showSnackBar('Error toggling pin: $e');
    }
  }

  Future<void> _deleteSearch(SavedSearch search) async {
    final confirmed = await _showDeleteConfirmation(search);
    if (confirmed != true) return;

    try {
      await _savedSearchService.deleteSavedSearch(search.id!);
      if (mounted) {
        _showSnackBar('Deleted: ${search.name}');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error deleting search: $e');
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(SavedSearch search) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Search'),
          content: Text('Are you sure you want to delete "${search.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editSearch(SavedSearch search) async {
    final nameController = TextEditingController(text: search.name);
    final descriptionController = TextEditingController(
      text: search.description ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Search'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Search Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
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
      final updatedSearch = search.copyWith(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      try {
        await _savedSearchService.updateSavedSearch(updatedSearch);
        if (mounted) {
          _showSnackBar('Search updated');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error updating search: $e');
        }
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _manageTagsForSearch(SavedSearch search) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _TagManagementDialog(
        currentTags: Set.from(search.tags),
        allTags: _allTags,
      ),
    );

    if (result != null && mounted) {
      // Update tags
      final tagsToRemove = search.tags.where((tag) => !result.contains(tag));
      final tagsToAdd = result.where((tag) => !search.tags.contains(tag));

      try {
        for (final tag in tagsToRemove) {
          await _savedSearchService.removeTag(search.id!, tag);
        }
        for (final tag in tagsToAdd) {
          await _savedSearchService.addTag(search.id!, tag);
        }
        _loadSavedSearches();
      } catch (e) {
        _showSnackBar('Error updating tags: $e');
      }
    }
  }

  Future<void> _loadSearch(SavedSearch search) async {
    await _savedSearchService.markSearchUsed(search.id!);
    if (mounted) {
      Navigator.pop(context, search);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Saved Searches'),
      actions: [
        PopupMenuButton<_SortOption>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort by',
          onSelected: (option) {
            setState(() => _sortOption = option);
            _filterSearches();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _SortOption.lastUsed,
              child: Row(
                children: [
                  Icon(
                    _sortOption == _SortOption.lastUsed
                        ? Icons.check
                        : Icons.access_time,
                  ),
                  const SizedBox(width: 12),
                  const Text('Last Used'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _SortOption.alphabetical,
              child: Row(
                children: [
                  Icon(
                    _sortOption == _SortOption.alphabetical
                        ? Icons.check
                        : Icons.sort_by_alpha,
                  ),
                  const SizedBox(width: 12),
                  const Text('Alphabetical'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _SortOption.createdDate,
              child: Row(
                children: [
                  Icon(
                    _sortOption == _SortOption.createdDate
                        ? Icons.check
                        : Icons.calendar_today,
                  ),
                  const SizedBox(width: 12),
                  const Text('Created Date'),
                ],
              ),
            ),
            PopupMenuItem(
              value: _SortOption.useCount,
              child: Row(
                children: [
                  Icon(
                    _sortOption == _SortOption.useCount
                        ? Icons.check
                        : Icons.analytics,
                  ),
                  const SizedBox(width: 12),
                  const Text('Most Used'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildSearchBar(),
        if (_allTags.isNotEmpty) _buildTagFilters(),
        Expanded(
          child: _filteredSearches.isEmpty
              ? _buildEmptyState()
              : _buildSearchList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Search saved searches',
          hintText: 'Filter by name or description',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildTagFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _allTags.map((tag) {
          final isSelected = _selectedTags.contains(tag);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
                _filterSearches();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty && _selectedTags.isEmpty
                ? 'No saved searches yet'
                : 'No searches match your filters',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty && _selectedTags.isEmpty
                ? 'Save searches to quickly access them later'
                : 'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchList() {
    return ListView.builder(
      itemCount: _filteredSearches.length,
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemBuilder: (context, index) {
        final search = _filteredSearches[index];
        return _buildSearchCard(search);
      },
    );
  }

  Widget _buildSearchCard(SavedSearch search) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _loadSearch(search),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (search.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.push_pin,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      search.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      search.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                      color: search.isPinned
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    onPressed: () => _togglePin(search),
                    tooltip: search.isPinned ? 'Unpin' : 'Pin',
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'tags',
                        child: Row(
                          children: [
                            Icon(Icons.label),
                            SizedBox(width: 12),
                            Text('Manage Tags'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editSearch(search);
                        case 'tags':
                          _manageTagsForSearch(search);
                        case 'delete':
                          _deleteSearch(search);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                search.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (search.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  search.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (search.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: search.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    search.lastUsedDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.analytics,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${search.useCount} uses',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.search),
      label: const Text('New Search'),
    );
  }
}

/// Tag management dialog
class _TagManagementDialog extends StatefulWidget {
  final Set<String> currentTags;
  final Set<String> allTags;

  const _TagManagementDialog({
    required this.currentTags,
    required this.allTags,
  });

  @override
  State<_TagManagementDialog> createState() => _TagManagementDialogState();
}

class _TagManagementDialogState extends State<_TagManagementDialog> {
  late Set<String> _selectedTags;
  final _newTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTags = Set.from(widget.currentTags);
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  void _addNewTag() {
    final newTag = _newTagController.text.trim();
    if (newTag.isEmpty) return;

    setState(() {
      _selectedTags.add(newTag);
      _newTagController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manage Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    decoration: const InputDecoration(
                      labelText: 'New Tag',
                      hintText: 'Enter tag name',
                    ),
                    onSubmitted: (_) => _addNewTag(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addNewTag),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.allTags.isNotEmpty) ...[
              Text('All Tags', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.allTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedTags),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Sort options for saved searches
enum _SortOption { alphabetical, lastUsed, createdDate, useCount }
