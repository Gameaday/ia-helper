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
    if (json['__ia_thumb_url'] != null) {
      thumbnailUrl = json['__ia_thumb_url'] as String;
    } else if (json['identifier'] != null) {
      // Generate standard thumbnail URL from identifier
      final id = json['identifier'];
      thumbnailUrl = 'https://archive.org/services/img/$id';
    }

    return SearchResult(
      identifier: _extractString(json['identifier'], ''),
      title: _extractString(json['title'], 'Untitled'),
      description: _extractString(json['description'], ''),
      thumbnailUrl: thumbnailUrl,
      creator: _extractStringNullable(json['creator']),
      mediaType: _extractStringNullable(json['mediatype']),
      downloads: json['downloads'] as int?,
      date: _extractStringNullable(json['date']),
    );
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
