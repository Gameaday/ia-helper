import 'package:flutter/material.dart';
import 'dart:async';
import '../services/search_history_service.dart';
import '../services/identifier_verification_service.dart';
import '../models/search_history_entry.dart';

/// Search action type for disambiguation
enum SearchAction {
  openArchive, // Open specific archive by identifier
  searchKeyword, // Search for content by keywords
}

/// Enhanced intelligent search bar with verification and dual-action UI
///
/// Features:
/// - Verifies archive identifiers exist before suggesting
/// - Shows both "Open Archive" and "Search" options when ambiguous
/// - Caches verification results to minimize API calls
/// - Provides clear hints about what will happen
/// - Handles case-sensitivity gracefully
class EnhancedSearchBar extends StatefulWidget {
  final Function(String query, SearchAction action)? onSearch;
  final String? initialQuery;
  final bool autofocus;

  const EnhancedSearchBar({
    super.key,
    this.onSearch,
    this.initialQuery,
    this.autofocus = false,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final _verificationService = IdentifierVerificationService.instance;
  final _historyService = SearchHistoryService.instance;

  Timer? _verificationTimer;
  SearchSuggestion? _verifiedArchive;
  List<SearchHistoryEntry> _recentSearches = [];
  bool _isVerifying = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.initialQuery?.isNotEmpty == true) {
      _checkQuery(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text;

    if (query.isEmpty) {
      setState(() {
        _verifiedArchive = null;
        _recentSearches = [];
        _showSuggestions = false;
      });
      return;
    }

    // Debounce verification check
    _verificationTimer?.cancel();
    _verificationTimer = Timer(const Duration(milliseconds: 400), () {
      _checkQuery(query);
    });

    // Load recent searches immediately (from cache)
    _loadRecentSearches(query);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.isNotEmpty) {
        setState(() => _showSuggestions = true);
      }
    } else {
      // Delay hiding to allow tapping suggestions
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  Future<void> _checkQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Check if it looks like an identifier
    if (_isIdentifierPattern(trimmed)) {
      setState(() => _isVerifying = true);

      // Verify if archive exists
      final result = await _verificationService.verifyIdentifier(trimmed);

      if (mounted) {
        setState(() {
          _verifiedArchive = result;
          _isVerifying = false;
          if (result != null) {
            _showSuggestions = true;
          }
        });
      }
    } else {
      setState(() {
        _verifiedArchive = null;
        _isVerifying = false;
      });
    }
  }

  Future<void> _loadRecentSearches(String query) async {
    if (query.length < 2) return;

    final history = await _historyService.getSuggestions(query);
    if (mounted) {
      setState(() {
        _recentSearches = history.take(5).toList();
        if (_recentSearches.isNotEmpty) {
          _showSuggestions = true;
        }
      });
    }
  }

  bool _isIdentifierPattern(String query) {
    if (query.contains(' ')) return false;
    if (query.length < 3 || query.length > 100) return false;

    final identifierRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_\-\.]*$');
    return identifierRegex.hasMatch(query);
  }

  void _executeSearch(SearchAction action) {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    // Use verified identifier if available and opening archive
    final searchQuery =
        (action == SearchAction.openArchive &&
            _verifiedArchive != null &&
            _verifiedArchive!.isCaseVariant)
        ? _verifiedArchive!.query
        : query;

    widget.onSearch?.call(searchQuery, action);
    _focusNode.unfocus();
  }

  void _applySuggestion(String suggestion, SearchAction action) {
    _controller.text = suggestion;
    _controller.selection = TextSelection.collapsed(offset: suggestion.length);
    _executeSearch(action);
  }

  String _getHintText() {
    if (_verifiedArchive != null) {
      return 'Press Enter to open "${_verifiedArchive!.query}"';
    } else if (_isVerifying) {
      return 'Checking archive...';
    } else if (_isIdentifierPattern(_controller.text.trim())) {
      return 'Press Enter to search or check archive';
    } else {
      return 'Search Internet Archive';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final query = _controller.text.trim();
    final showDualAction = query.isNotEmpty && !_isVerifying;

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
            onSubmitted: (_) {
              // Default action: open archive if verified, otherwise search
              _executeSearch(
                _verifiedArchive != null
                    ? SearchAction.openArchive
                    : SearchAction.searchKeyword,
              );
            },
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: _getHintText(),
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              prefixIcon: _isVerifying
                  ? Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : Icon(
                      _verifiedArchive != null ? Icons.archive : Icons.search,
                      color: _verifiedArchive != null
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
              suffixIcon: query.isNotEmpty
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

        // Dual-action buttons (when text entered and not verifying)
        if (showDualAction) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              // Open Archive button (primary if verified)
              if (_verifiedArchive != null)
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _executeSearch(SearchAction.openArchive),
                    icon: const Icon(Icons.archive),
                    label: Text(
                      _verifiedArchive!.isCaseVariant
                          ? 'Open "${_verifiedArchive!.query}"'
                          : 'Open Archive',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

              // Spacing between buttons
              if (_verifiedArchive != null) const SizedBox(width: 8),

              // Search button (always available)
              Expanded(
                flex: _verifiedArchive != null ? 1 : 1,
                child: _verifiedArchive != null
                    ? OutlinedButton.icon(
                        onPressed: () =>
                            _executeSearch(SearchAction.searchKeyword),
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: () =>
                            _executeSearch(SearchAction.searchKeyword),
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                        style: FilledButton.styleFrom(
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

        // Verified archive info card
        if (_verifiedArchive != null && _showSuggestions) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(Icons.check_circle, color: colorScheme.primary),
              title: Text(
                _verifiedArchive!.title ?? _verifiedArchive!.query,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle:
                  _verifiedArchive!.subtitle != null ||
                      _verifiedArchive!.isCaseVariant
                  ? Text(
                      _verifiedArchive!.isCaseVariant
                          ? '${_verifiedArchive!.subtitle ?? "Archive"} • Case corrected'
                          : _verifiedArchive!.subtitle!,
                      style: theme.textTheme.bodySmall,
                    )
                  : null,
              trailing: Icon(
                Icons.arrow_forward,
                color: colorScheme.onSurfaceVariant,
              ),
              onTap: () => _executeSearch(SearchAction.openArchive),
            ),
          ),
        ],

        // Recent searches dropdown
        if (_showSuggestions &&
            _recentSearches.isNotEmpty &&
            _verifiedArchive == null) ...[
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    'Recent Searches',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ..._recentSearches.map((entry) {
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.history,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: Text(entry.query, style: theme.textTheme.bodyMedium),
                    trailing: Icon(
                      Icons.north_west,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => _applySuggestion(
                      entry.query,
                      SearchAction.searchKeyword,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
