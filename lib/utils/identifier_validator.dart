/// Validator for Internet Archive identifiers
///
/// This utility provides reusable validation for archive identifiers
/// following Archive.org naming conventions. It can be used for:
/// - Search input validation
/// - Upload identifier validation (future feature)
/// - API request validation
///
/// Reference: Based on the Rust implementation in archive_api.rs
class IdentifierValidator {
  /// Validates an Internet Archive identifier
  ///
  /// Returns null if valid, otherwise returns an error message
  ///
  /// Rules:
  /// - Must be 3-100 characters long
  /// - Can only contain alphanumeric characters, hyphens (-), underscores (_), and periods (.)
  /// - Must start and end with alphanumeric characters
  /// - Cannot contain consecutive special characters
  static String? validate(String identifier) {
    if (identifier.isEmpty) {
      return 'Archive identifier cannot be empty';
    }

    if (identifier.length < 3) {
      return 'Archive identifier must be at least 3 characters long';
    }

    if (identifier.length > 100) {
      return 'Archive identifier cannot exceed 100 characters';
    }

    // Check for valid characters
    final validCharsPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!validCharsPattern.hasMatch(identifier)) {
      return 'Archive identifier contains invalid characters. Only letters, numbers, hyphens, underscores, and periods are allowed';
    }

    // Check start/end characters
    final firstChar = identifier[0];
    final lastChar = identifier[identifier.length - 1];

    if (!_isAlphanumeric(firstChar)) {
      return 'Archive identifier must start with a letter or number';
    }

    if (!_isAlphanumeric(lastChar)) {
      return 'Archive identifier must end with a letter or number';
    }

    // Check for consecutive special characters
    bool prevSpecial = false;
    for (int i = 0; i < identifier.length; i++) {
      final char = identifier[i];
      final isSpecial = !_isAlphanumeric(char);

      if (isSpecial && prevSpecial) {
        return 'Archive identifier cannot contain consecutive special characters';
      }

      prevSpecial = isSpecial;
    }

    return null;
  }

  /// Validates and throws an exception if invalid
  static void validateOrThrow(String identifier) {
    final error = validate(identifier);
    if (error != null) {
      throw FormatException(error);
    }
  }

  /// Checks if the identifier is valid (returns true/false)
  static bool isValid(String identifier) {
    return validate(identifier) == null;
  }

  /// Helper to check if a character is alphanumeric
  static bool _isAlphanumeric(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 48 && code <= 57) || // 0-9
        (code >= 65 && code <= 90) || // A-Z
        (code >= 97 && code <= 122); // a-z
  }

  /// Get a user-friendly validation message for UI display
  static String getValidationHint() {
    return 'Identifier must be 3-100 characters, using only letters, numbers, hyphens, underscores, and periods. Must start and end with alphanumeric characters.';
  }

  /// Suggests corrections for common identifier mistakes
  static String? suggestCorrection(String identifier) {
    if (identifier.isEmpty) {
      return null;
    }

    // Remove leading/trailing special characters
    String corrected = identifier;
    while (corrected.isNotEmpty && !_isAlphanumeric(corrected[0])) {
      corrected = corrected.substring(1);
    }
    while (corrected.isNotEmpty &&
        !_isAlphanumeric(corrected[corrected.length - 1])) {
      corrected = corrected.substring(0, corrected.length - 1);
    }

    // Replace invalid characters with underscores
    corrected = corrected.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

    // Replace consecutive special characters with single underscore
    corrected = corrected.replaceAll(RegExp(r'[._-]{2,}'), '_');

    // If the corrected version is different and valid, return it
    if (corrected != identifier && isValid(corrected)) {
      return corrected;
    }

    return null;
  }
}
