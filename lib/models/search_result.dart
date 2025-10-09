import 'package:flutter/foundation.dart';

/// Search result model for Internet Archive search API responses
class SearchResult {
  final String identifier;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? creator;
  final String? mediaType;
  final int? downloads;
  final String? date;

  SearchResult({
    required this.identifier,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.creator,
    this.mediaType,
    this.downloads,
    this.date,
  });

  /// Factory constructor to handle Internet Archive API quirk where
  /// title and description can be either a string or a list of strings
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    // Extract thumbnail URL
    String? thumbnailUrl;
    final identifier = json['identifier'] as String?;
    
    if (json['__ia_thumb_url'] != null) {
      thumbnailUrl = json['__ia_thumb_url'] as String;
      
      // CORS FIX for web: Replace CDN URLs with archive.org/download/
      // CDN URLs (e.g. dn720706.ca.archive.org) don't have CORS headers
      if (kIsWeb && identifier != null) {
        // Check if it's a CDN URL pattern
        if (thumbnailUrl.contains('.archive.org') && 
            !thumbnailUrl.contains('archive.org/download/')) {
          // Extract the filename (usually __ia_thumb.jpg)
          final filename = thumbnailUrl.split('/').last;
          // Reconstruct with CORS-friendly endpoint
          thumbnailUrl = 'https://archive.org/download/$identifier/$filename';
        }
      }
    } else if (identifier != null) {
      // Generate web-friendly thumbnail URL from identifier
      // Use __ia_thumb.jpg on web (CORS-friendly), services/img on native
      if (kIsWeb) {
        thumbnailUrl = 'https://archive.org/download/$identifier/__ia_thumb.jpg';
      } else {
        thumbnailUrl = 'https://archive.org/services/img/$identifier';
      }
    }

    return SearchResult(
      identifier: _extractString(json['identifier'], ''),
      title: _extractString(json['title'], 'Untitled'),
      description: _stripHtml(_extractString(json['description'], '')),
      thumbnailUrl: thumbnailUrl,
      creator: _extractStringNullable(json['creator']),
      mediaType: _extractStringNullable(json['mediatype']),
      downloads: json['downloads'] as int?,
      date: _extractStringNullable(json['date']),
    );
  }

  /// Strip HTML tags from text
  static String _stripHtml(String htmlText) {
    if (htmlText.isEmpty) return htmlText;

    // Remove HTML tags
    String text = htmlText.replaceAll(RegExp(r'<[^>]*>'), ' ');
    
    // Decode common HTML entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    
    // Clean up multiple spaces and trim
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return text;
  }

  /// Helper method to extract a string value from either a string or list
  ///
  /// The Internet Archive API sometimes returns fields as:
  /// - A single string: "Example Title"
  /// - A list of strings: ["Example Title", "Alternative Title"]
  ///
  /// This method handles both cases, taking the first element if it's a list.
  static String _extractString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;

    if (value is List) {
      return value.isNotEmpty ? value.first.toString() : defaultValue;
    }

    return value.toString();
  }

  /// Helper method to extract a string value that can be null
  static String? _extractStringNullable(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      return value.isNotEmpty ? value.first.toString() : null;
    }

    return value.toString();
  }

  /// Convert to the Map format expected by the UI
  Map<String, String?> toMap() {
    return {
      'identifier': identifier,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'creator': creator,
      'mediaType': mediaType,
      'downloads': downloads?.toString(),
      'date': date,
    };
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'creator': creator,
      'mediaType': mediaType,
      'downloads': downloads,
      'date': date,
    };
  }
}
