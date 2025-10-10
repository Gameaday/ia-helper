import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/search_history_service.dart';
import '../services/archive_service.dart';
import '../utils/animation_constants.dart';
import 'dart:async';

/// Search type detected from user input
enum SearchType {
  identifier, // Archive.org identifier (alphanumeric with dashes/underscores)
  keyword, // General keyword search
  advanced, // Complex query with operators
  empty, // No input yet
}

/// Intelligent search bar with auto-detection and suggestions
class IntelligentSearchBar extends StatefulWidget {
  final Function(String query, SearchType type)? onSearch;
  final Function(String query)? onChanged;
  final String? initialQuery;
  final bool autofocus;
  final String? hintText;

  const IntelligentSearchBar({
    super.key,
    this.onSearch,
    this.onChanged,
    this.initialQuery,
    this.autofocus = false,
    this.hintText,
  });

  @override
  State<IntelligentSearchBar> createState() => _IntelligentSearchBarState();
}

class _IntelligentSearchBarState extends State<IntelligentSearchBar>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _iconAnimationController;
  late final Animation<double> _iconRotation;

  SearchType _currentSearchType = SearchType.empty;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  String? _didYouMean;
  
  // Identifier validation state
  bool _isValidatingIdentifier = false;
  bool? _isValidIdentifier;
  Timer? _validationDebounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();

    _iconAnimationController = AnimationController(
      duration: MD3Durations.medium,
      vsync: this,
    );

    _iconRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: MD3Curves.emphasized,
      ),
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.initialQuery?.isNotEmpty == true) {
      _detectSearchType(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _iconAnimationController.dispose();
    _validationDebounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text;
    widget.onChanged?.call(query);

    if (query.isEmpty) {
      setState(() {
        _currentSearchType = SearchType.empty;
        _showSuggestions = false;
        _suggestions = [];
        _didYouMean = null;
      });
      return;
    }

    _detectSearchType(query);
    _generateSuggestions(query);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      setState(() => _showSuggestions = true);
    } else {
      // Delay hiding to allow tapping suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  /// Detect search type from query pattern
  void _detectSearchType(String query) {
    final trimmed = query.trim();

    SearchType newType;
    if (trimmed.isEmpty) {
      newType = SearchType.empty;
    } else if (_isIdentifierPattern(trimmed)) {
      newType = SearchType.identifier;
      // Validate identifier with debouncing
      _scheduleIdentifierValidation(trimmed);
    } else if (_isAdvancedQuery(trimmed)) {
      newType = SearchType.advanced;
    } else {
      newType = SearchType.keyword;
    }

    if (newType != _currentSearchType) {
      setState(() {
        _currentSearchType = newType;
        // Reset validation when type changes away from identifier
        if (newType != SearchType.identifier) {
          _isValidatingIdentifier = false;
          _isValidIdentifier = null;
        }
      });
      _iconAnimationController.forward(from: 0.0);
    }
  }

  /// Schedule identifier validation with debouncing
  void _scheduleIdentifierValidation(String identifier) {
    // Cancel previous validation timer
    _validationDebounce?.cancel();
    
    // Reset validation state
    setState(() {
      _isValidatingIdentifier = true;
      _isValidIdentifier = null;
    });
    
    // Schedule new validation after 500ms
    _validationDebounce = Timer(const Duration(milliseconds: 500), () {
      _validateIdentifier(identifier);
    });
  }

  /// Validate identifier using ArchiveService
  Future<void> _validateIdentifier(String identifier) async {
    if (!mounted) return;
    
    try {
      final archiveService = context.read<ArchiveService>();
      final isValid = await archiveService.validateIdentifier(identifier);
      
      if (mounted) {
        setState(() {
          _isValidatingIdentifier = false;
          _isValidIdentifier = isValid;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingIdentifier = false;
          _isValidIdentifier = false;
        });
      }
    }
  }

  /// Check if query matches Archive.org identifier pattern
  bool _isIdentifierPattern(String query) {
    // Identifiers are typically alphanumeric with dashes, underscores
    // No spaces, reasonable length
    if (query.contains(' ')) return false;
    if (query.length < 3 || query.length > 100) return false;

    final identifierRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_\-\.]*$');
    return identifierRegex.hasMatch(query);
  }

  /// Check if query uses advanced search operators
  bool _isAdvancedQuery(String query) {
    // Look for advanced search patterns
    final hasOperators =
        query.contains(':') ||
        query.contains('AND') ||
        query.contains('OR') ||
        query.contains('NOT') ||
        query.contains('"');
    return hasOperators;
  }

  /// Generate contextual suggestions based on query
  Future<void> _generateSuggestions(String query) async {
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _didYouMean = null;
      });
      return;
    }

    // Get suggestions from history
    final historyService = SearchHistoryService.instance;
    final history = await historyService.getSuggestions(query);

    final matchingSuggestions = history
        .map((entry) => entry.query)
        .take(5)
        .toList();

    // Check for common misspellings
    String? correction;
    if (_currentSearchType == SearchType.keyword) {
      correction = _checkSpelling(query);
    }

    setState(() {
      _suggestions = matchingSuggestions;
      _didYouMean = correction;
    });
  }

  /// Simple spelling checker for common Archive.org terms
  String? _checkSpelling(String query) {
    final commonTerms = {
      'libro': 'librivox',
      'librevox': 'librivox',
      'prelinger': 'prelinger',
      'gutenberg': 'gutenberg',
      'gutenburg': 'gutenberg',
      'comix': 'comics',
      'comunity': 'community',
      'comunty': 'community',
      'opensource': 'opensource_movies',
      'open source': 'opensource',
    };

    final lowerQuery = query.toLowerCase().trim();
    for (final entry in commonTerms.entries) {
      if (_levenshteinDistance(lowerQuery, entry.key) <= 2) {
        return entry.value;
      }
    }
    return null;
  }

  /// Calculate Levenshtein distance for fuzzy matching
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;
    final matrix = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Execute search with detected type
  void _executeSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    widget.onSearch?.call(query, _currentSearchType);
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
  }

  /// Apply suggestion to search field
  void _applySuggestion(String suggestion) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: suggestion.length);
    _executeSearch();
  }

  /// Get icon based on search type
  IconData _getSearchIcon() {
    switch (_currentSearchType) {
      case SearchType.identifier:
        return Icons.tag;
      case SearchType.keyword:
        return Icons.search;
      case SearchType.advanced:
        return Icons.filter_list;
      case SearchType.empty:
        return Icons.search;
    }
  }

  /// Get hint based on search type
  String _getHint() {
    if (widget.hintText != null) return widget.hintText!;

    switch (_currentSearchType) {
      case SearchType.identifier:
        return 'Archive identifier detected';
      case SearchType.keyword:
        return 'Search Internet Archive';
      case SearchType.advanced:
        return 'Advanced query detected';
      case SearchType.empty:
        return 'Search by identifier or keywords';
    }
  }

  /// Get search type indicator color
  Color _getSearchTypeColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_currentSearchType) {
      case SearchType.identifier:
        return colorScheme.primary;
      case SearchType.keyword:
        return colorScheme.secondary;
      case SearchType.advanced:
        return colorScheme.tertiary;
      case SearchType.empty:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search field
        Material(
          elevation: 2,
          shadowColor: colorScheme.shadow,
          borderRadius: BorderRadius.circular(28),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _executeSearch(),
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: _getHint(),
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: RotationTransition(
                turns: _iconRotation,
                child: Icon(
                  _getSearchIcon(),
                  color: _getSearchTypeColor(context),
                ),
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _focusNode.requestFocus();
                      },
                      tooltip: 'Clear',
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),

        // Dual-action buttons when identifier is detected
        if (_currentSearchType == SearchType.identifier &&
            _controller.text.isNotEmpty &&
            !_showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Validation status indicator
                if (_isValidatingIdentifier || _isValidIdentifier != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Loading or status icon
                        if (_isValidatingIdentifier)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_isValidIdentifier == true)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: colorScheme.primary,
                          )
                        else if (_isValidIdentifier == false)
                          Icon(
                            Icons.error_outline,
                            size: 16,
                            color: colorScheme.error,
                          ),
                        const SizedBox(width: 8),
                        // Status text
                        Expanded(
                          child: Text(
                            _isValidatingIdentifier
                                ? 'Checking if archive exists...'
                                : _isValidIdentifier == true
                                    ? 'Valid archive identifier'
                                    : 'Archive not found on Archive.org',
                            style: textTheme.bodySmall?.copyWith(
                              color: _isValidatingIdentifier
                                  ? colorScheme.onSurfaceVariant
                                  : _isValidIdentifier == true
                                      ? colorScheme.primary
                                      : colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Action buttons
                Row(
                  children: [
                    // Open Archive button (primary action) - only enabled if validated
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isValidIdentifier == true
                            ? () {
                                // Normalize identifier (lowercase) for consistency
                                // Archive.org identifiers are case-insensitive
                                final query = _controller.text.trim().toLowerCase();
                                widget.onSearch?.call(query, SearchType.identifier);
                                _focusNode.unfocus();
                              }
                            : null, // Disabled until validation succeeds
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open Archive'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search for term button (secondary action) - always enabled
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final query = _controller.text.trim();
                          widget.onSearch?.call(query, SearchType.keyword);
                          _focusNode.unfocus();
                        },
                        icon: const Icon(Icons.search, size: 18),
                        label: Text(
                          'Search for "${_controller.text.trim().length > 12 ? '${_controller.text.trim().substring(0, 12)}...' : _controller.text.trim()}"',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Suggestions dropdown
        if (_showSuggestions &&
            (_suggestions.isNotEmpty || _didYouMean != null))
          AnimatedContainer(
            duration: MD3Durations.short,
            curve: MD3Curves.emphasized,
            margin: const EdgeInsets.only(top: 8),
            child: Material(
              elevation: 3,
              shadowColor: colorScheme.shadow,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // "Did you mean?" suggestion
                    if (_didYouMean != null) ...[
                      ListTile(
                        leading: Icon(
                          Icons.lightbulb_outline,
                          color: colorScheme.tertiary,
                        ),
                        title: Text(
                          'Did you mean "$_didYouMean"?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.tertiary,
                          ),
                        ),
                        onTap: () => _applySuggestion(_didYouMean!),
                      ),
                      if (_suggestions.isNotEmpty)
                        Divider(height: 1, color: colorScheme.outlineVariant),
                    ],

                    // Recent search suggestions
                    ..._suggestions.map((suggestion) {
                      return ListTile(
                        leading: Icon(
                          Icons.history,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        title: Text(
                          suggestion,
                          style: theme.textTheme.bodyMedium,
                        ),
                        onTap: () => _applySuggestion(suggestion),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
