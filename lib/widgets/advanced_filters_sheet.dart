/// Advanced Search Filters Modal Bottom Sheet
///
/// Displays search filtering options in a Material Design 3 modal bottom sheet.
/// Features:
/// - Mediatype filtering (texts, movies, audio, image, software, data, web)
/// - Date range selection
/// - Sort options (relevance, date, downloads, week)
/// - Apply/Reset buttons
/// - Empty state when no filters
/// - MD3 compliant with proper elevation and animations
library;

import 'package:flutter/material.dart';
import '../models/date_range.dart';
import '../models/sort_option.dart';

/// Modal bottom sheet showing advanced search filters
class AdvancedFiltersSheet extends StatefulWidget {
  /// Initial mediatype filters
  final List<String> initialMediatypes;

  /// Initial date range
  final DateRange? initialDateRange;

  /// Initial sort option
  final SortOption initialSortOption;

  const AdvancedFiltersSheet({
    super.key,
    this.initialMediatypes = const [],
    this.initialDateRange,
    this.initialSortOption = SortOption.relevance,
  });

  @override
  State<AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();

  /// Show the advanced filters sheet
  ///
  /// Returns a map with filters if applied, null if cancelled
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    List<String> initialMediatypes = const [],
    DateRange? initialDateRange,
    SortOption initialSortOption = SortOption.relevance,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AdvancedFiltersSheet(
        initialMediatypes: initialMediatypes,
        initialDateRange: initialDateRange,
        initialSortOption: initialSortOption,
      ),
    );
  }
}

class _AdvancedFiltersSheetState extends State<AdvancedFiltersSheet> {
  late List<String> _selectedMediatypes;
  late DateRange? _selectedDateRange;
  late SortOption _selectedSortOption;

  // Available mediatypes from Internet Archive
  static const _availableMediatypes = [
    {'id': 'texts', 'label': 'Texts', 'icon': Icons.menu_book},
    {'id': 'movies', 'label': 'Movies', 'icon': Icons.movie},
    {'id': 'audio', 'label': 'Audio', 'icon': Icons.audiotrack},
    {'id': 'image', 'label': 'Images', 'icon': Icons.image},
    {'id': 'software', 'label': 'Software', 'icon': Icons.apps},
    {'id': 'data', 'label': 'Data', 'icon': Icons.storage},
    {'id': 'web', 'label': 'Web', 'icon': Icons.public},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMediatypes = List.from(widget.initialMediatypes);
    _selectedDateRange = widget.initialDateRange;
    _selectedSortOption = widget.initialSortOption;
  }

  bool _hasActiveFilters() {
    return _selectedMediatypes.isNotEmpty ||
        _selectedDateRange != null ||
        _selectedSortOption != SortOption.relevance;
  }

  void _resetFilters() {
    setState(() {
      _selectedMediatypes.clear();
      _selectedDateRange = null;
      _selectedSortOption = SortOption.relevance;
    });
  }

  void _applyFilters() {
    Navigator.pop(context, {
      'mediatypes': _selectedMediatypes,
      'dateRange': _selectedDateRange,
      'sortOption': _selectedSortOption,
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDateRange: _selectedDateRange != null
          ? DateTimeRange(
              start: _selectedDateRange!.start,
              end: _selectedDateRange!.end,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: AppBarTheme(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      setState(() {
        _selectedDateRange = DateRange(
          start: dateRange.start,
          end: dateRange.end,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate dynamic height based on content
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
            child: Row(
              children: [
                Icon(Icons.tune, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Advanced Filters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_hasActiveFilters())
                  TextButton.icon(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text('Reset'),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Media Types Section
                _buildSectionHeader(
                  'Media Types',
                  Icons.category,
                  'Filter by content type',
                ),
                const SizedBox(height: 12),
                _buildMediatypeFilters(),
                const SizedBox(height: 32),

                // Date Range Section
                _buildSectionHeader(
                  'Date Range',
                  Icons.calendar_today,
                  'Filter by publication date',
                ),
                const SizedBox(height: 12),
                _buildDateRangeSelector(),
                const SizedBox(height: 32),

                // Sort Options Section
                _buildSectionHeader(
                  'Sort By',
                  Icons.sort,
                  'Order search results',
                ),
                const SizedBox(height: 12),
                _buildSortOptions(),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _applyFilters,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMediatypeFilters() {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableMediatypes.map((mediatype) {
        final id = mediatype['id'] as String;
        final label = mediatype['label'] as String;
        final icon = mediatype['icon'] as IconData;
        final isSelected = _selectedMediatypes.contains(id);

        return FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedMediatypes.add(id);
              } else {
                _selectedMediatypes.remove(id);
              }
            });
          },
          avatar: isSelected
              ? null
              : Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.date_range, color: colorScheme.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDateRange != null
                          ? 'Selected Range'
                          : 'Select Date Range',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedDateRange!.toDisplayString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_selectedDateRange != null)
                IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.error, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                  tooltip: 'Clear date range',
                )
              else
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOptions() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Common sort options as chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                SortOption.relevance,
                SortOption.date,
                SortOption.downloads,
                SortOption.weeklyViews,
              ].map((option) {
                final isSelected = _selectedSortOption == option;
                return FilterChip(
                  label: Text(_getSortLabel(option)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSortOption = option;
                      });
                    }
                  },
                  selectedColor: colorScheme.primaryContainer,
                  checkmarkColor: colorScheme.onPrimaryContainer,
                  showCheckmark: true,
                  side: BorderSide(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: isSelected ? 1.5 : 1,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 12),
        // More sort options in dropdown
        DropdownButtonFormField<SortOption>(
          initialValue: _selectedSortOption,
          decoration: InputDecoration(
            labelText: 'More sort options',
            helperText: _getSortDescription(_selectedSortOption),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: SortOption.values.map((option) {
            return DropdownMenuItem<SortOption>(
              value: option,
              child: Text(_getSortLabel(option)),
            );
          }).toList(),
          onChanged: (SortOption? value) {
            if (value != null) {
              setState(() {
                _selectedSortOption = value;
              });
            }
          },
        ),
      ],
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.date:
        return 'Date';
      case SortOption.downloads:
        return 'Downloads';
      case SortOption.weeklyViews:
        return 'Weekly Views';
      case SortOption.title:
        return 'Title';
      case SortOption.addedDate:
        return 'Added Date';
      case SortOption.updateDate:
        return 'Updated Date';
      case SortOption.reviewDate:
        return 'Review Date';
      case SortOption.itemSize:
        return 'Item Size';
    }
  }

  String _getSortDescription(SortOption option) {
    switch (option) {
      case SortOption.relevance:
        return 'Most relevant results first';
      case SortOption.date:
        return 'Newest items first';
      case SortOption.downloads:
        return 'Most downloaded items first';
      case SortOption.weeklyViews:
        return 'Most viewed this week';
      case SortOption.title:
        return 'Alphabetical by title';
      case SortOption.addedDate:
        return 'Recently added items';
      case SortOption.updateDate:
        return 'Recently updated items';
      case SortOption.reviewDate:
        return 'Recently reviewed items';
      case SortOption.itemSize:
        return 'Largest items first';
    }
  }
}
