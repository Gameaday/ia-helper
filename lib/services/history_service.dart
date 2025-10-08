import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a visited archive in history
class HistoryEntry {
  final String identifier;
  final String title;
  final String? description;
  final String? creator;
  final int totalFiles;
  final int totalSize;
  final DateTime visitedAt;

  HistoryEntry({
    required this.identifier,
    required this.title,
    this.description,
    this.creator,
    required this.totalFiles,
    required this.totalSize,
    required this.visitedAt,
  });

  /// Create from JSON
  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      identifier: json['identifier'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      creator: json['creator'] as String?,
      totalFiles: json['totalFiles'] as int? ?? 0,
      totalSize: json['totalSize'] as int? ?? 0,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'title': title,
      'description': description,
      'creator': creator,
      'totalFiles': totalFiles,
      'totalSize': totalSize,
      'visitedAt': visitedAt.toIso8601String(),
    };
  }

  /// Format the visited date as a relative time
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(visitedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntry &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;
}

/// Service for managing archive visit history
class HistoryService extends ChangeNotifier {
  final List<HistoryEntry> _history = [];
  static const int _maxHistorySize = 100;
  static const String _historyKey = 'archive_history';
  
  bool _isLoaded = false;

  /// Get all history entries
  List<HistoryEntry> get history => List.unmodifiable(_history);
  
  /// Check if history has been loaded from storage
  bool get isLoaded => _isLoaded;

  /// Add an archive to history (or update if already exists)
  void addToHistory(HistoryEntry entry) {
    // Remove existing entry with same identifier if exists
    _history.removeWhere((e) => e.identifier == entry.identifier);
    
    // Add to beginning (most recent first)
    _history.insert(0, entry);
    
    // Limit history size
    if (_history.length > _maxHistorySize) {
      _history.removeRange(_maxHistorySize, _history.length);
    }
    
    notifyListeners();
    _saveHistory();
  }

  /// Remove an entry from history
  void removeFromHistory(String identifier) {
    _history.removeWhere((e) => e.identifier == identifier);
    notifyListeners();
    _saveHistory();
  }

  /// Clear all history
  void clearHistory() {
    _history.clear();
    notifyListeners();
    _saveHistory();
  }

  /// Save history to persistent storage
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _history.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_historyKey, jsonString);
      
      if (kDebugMode) {
        print('History saved: ${_history.length} entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving history: $e');
      }
    }
  }

  /// Load history from persistent storage
  Future<void> loadHistory() async {
    if (_isLoaded) {
      return; // Already loaded
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);
      
      if (jsonString != null && jsonString.isNotEmpty) {
        final jsonList = jsonDecode(jsonString) as List<dynamic>;
        _history.clear();
        _history.addAll(
          jsonList.map((json) => HistoryEntry.fromJson(json as Map<String, dynamic>)),
        );
        
        if (kDebugMode) {
          print('History loaded: ${_history.length} entries');
        }
      } else {
        if (kDebugMode) {
          print('No saved history found');
        }
      }
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading history: $e');
      }
      _isLoaded = true; // Mark as loaded even on error to prevent repeated attempts
    }
  }
}
