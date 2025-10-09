import 'identifier_validator.dart';

/// Normalization level for Archive.org identifiers
///
/// Two levels of normalization are supported:
/// - **Standard**: Technically valid (allows uppercase, e.g. "Mario")
/// - **Strict**: Archive.org convention (lowercase preferred, e.g. "mario")
///
/// Search strategy:
/// 1. Try standard normalization first (preserves user's case)
/// 2. If not found (404), try strict normalization (lowercase)
/// 3. Cache both hits and misses to avoid repeated API calls
enum NormalizationLevel {
  /// Standard normalization - technically valid per Archive.org rules
  /// Allows uppercase letters, only fixes clear errors
  standard,

  /// Strict normalization - follows Archive.org lowercase convention
  /// Converts to lowercase for better compatibility
  strict,
}

/// Comprehensive normalizer for Internet Archive identifiers
///
/// This utility applies Internet Archive's identifier rules with two levels:
/// 1. **Standard**: Technically valid (allows uppercase)
/// 2. **Strict**: Lowercase preferred (Archive.org convention)
///
/// Use cases:
/// - Search bar input normalization
/// - Upload identifier validation (future feature)
/// - Deep link identifier extraction
/// - Copy/paste cleanup
/// - Multi-level search strategy (try standard, then strict)
///
/// Internet Archive Identifier Rules:
/// - Length: 3-100 characters
/// - Characters: a-z, A-Z, 0-9, hyphen (-), underscore (_), period (.)
/// - Case: Uppercase allowed but lowercase preferred
/// - Start/End: Must be alphanumeric (not special chars)
/// - Consecutive: No consecutive special characters (-- or __ or ..)
/// - Spaces: Not allowed (will be converted to hyphen or underscore)
///
/// References:
/// - Archive.org API: https://archive.org/developers/
/// - Existing validator: lib/utils/identifier_validator.dart
class ArchiveIdentifierNormalizer {
  /// Normalize an identifier according to Archive.org rules
  ///
  /// [level] determines the normalization level:
  /// - [NormalizationLevel.standard]: Preserves case, only fixes clear errors
  /// - [NormalizationLevel.strict]: Converts to lowercase (Archive.org convention)
  ///
  /// Returns a [NormalizationResult] containing:
  /// - The normalized identifier (if possible)
  /// - Whether changes were made
  /// - List of specific changes applied
  /// - Alternative suggestions (if ambiguous)
  /// - Validation errors (if cannot be normalized)
  static NormalizationResult normalize(
    String input, {
    NormalizationLevel level = NormalizationLevel.strict,
  }) {
    if (input.isEmpty) {
      return NormalizationResult(
        original: input,
        normalized: null,
        isValid: false,
        level: level,
        changes: [],
        errors: ['Input is empty'],
      );
    }

    final changes = <String>[];
    String result = input;

    // Step 1: Trim whitespace
    if (result != result.trim()) {
      changes.add('Trimmed whitespace');
      result = result.trim();
    }

    // Step 2: Convert to lowercase (only for strict level)
    if (level == NormalizationLevel.strict && result != result.toLowerCase()) {
      changes.add('Converted to lowercase');
      result = result.toLowerCase();
    }

    // Step 3: Replace spaces with hyphens (most common convention)
    if (result.contains(' ')) {
      changes.add('Replaced spaces with hyphens');
      result = result.replaceAll(' ', '-');
    }

    // Step 4: Replace em-dash (—), en-dash (–), and other dash variants with hyphen
    if (result.contains(RegExp(r'[—–―‒]'))) {
      changes.add('Normalized dash characters');
      result = result.replaceAll(RegExp(r'[—–―‒]'), '-');
    }

    // Step 5: Remove invalid characters
    // Keep: a-z, A-Z (if standard level), 0-9, -, _, .
    final invalidChars = level == NormalizationLevel.strict
        ? RegExp(r'[^a-z0-9._-]')
        : RegExp(r'[^a-zA-Z0-9._-]');
    if (result.contains(invalidChars)) {
      final removed = result.replaceAll(invalidChars, '');
      if (removed != result) {
        changes.add('Removed invalid characters');
        result = removed;
      }
    }

    // Step 6: Collapse consecutive special characters
    if (result.contains(RegExp(r'[._-]{2,}'))) {
      changes.add('Collapsed consecutive special characters');
      result = result.replaceAll(RegExp(r'[._-]{2,}'), '-');
    }

    // Step 7: Remove leading/trailing special characters
    final trimmedSpecial = result.replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');
    if (trimmedSpecial != result) {
      changes.add('Removed leading/trailing special characters');
      result = trimmedSpecial;
    }

    // Step 8: Check length constraints
    if (result.length < 3) {
      // ignore: prefer_const_constructors
      return NormalizationResult(
        original: input,
        normalized: null,
        isValid: false,
        level: level,
        changes: changes,
        errors: ['Resulting identifier too short (minimum 3 characters)'],
      );
    }

    if (result.length > 100) {
      changes.add('Truncated to 100 characters');
      result = result.substring(0, 100);
      // Re-trim trailing special chars after truncation
      result = result.replaceAll(RegExp(r'[._-]+$'), '');
    }

    // Final validation
    final validationError = IdentifierValidator.validate(result);
    if (validationError != null) {
      // ignore: prefer_const_constructors
      return NormalizationResult(
        original: input,
        normalized: null,
        isValid: false,
        level: level,
        changes: changes,
        errors: [validationError],
      );
    }

    // Generate alternative suggestions for ambiguous cases
    final alternatives = _generateAlternatives(input, result, level);

    return NormalizationResult(
      original: input,
      normalized: result,
      isValid: true,
      level: level,
      changes: changes,
      alternatives: alternatives,
    );
  }

  /// Generate alternative suggestions for ambiguous inputs
  ///
  /// For example:
  /// - "super mario" → ["super-mario", "super_mario", "supermario"]
  /// - "Mario Bros!" → ["mario-bros", "mario_bros", "mariobros"]
  static List<String> _generateAlternatives(
    String original,
    String normalized,
    NormalizationLevel level,
  ) {
    final alternatives = <String>[];

    // If original had spaces, offer both hyphen and underscore variants
    if (original.contains(' ')) {
      final processCase = level == NormalizationLevel.strict
          ? (String s) => s.toLowerCase()
          : (String s) => s;

      final withUnderscore = processCase(original)
          .trim()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '')
          .replaceAll(RegExp(r'[._-]{2,}'), '_')
          .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');

      final withoutSeparator = processCase(original)
          .trim()
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '')
          .replaceAll(RegExp(r'[._-]{2,}'), '')
          .replaceAll(RegExp(r'^[._-]+|[._-]+$'), '');

      if (withUnderscore != normalized &&
          IdentifierValidator.isValid(withUnderscore)) {
        alternatives.add(withUnderscore);
      }

      if (withoutSeparator != normalized &&
          withoutSeparator != withUnderscore &&
          IdentifierValidator.isValid(withoutSeparator)) {
        alternatives.add(withoutSeparator);
      }
    }

    return alternatives;
  }

  /// Quick check if input needs normalization
  ///
  /// Returns true if the input is already a valid identifier
  /// Returns false if normalization is needed
  static bool needsNormalization(String input) {
    return !IdentifierValidator.isValid(input);
  }

  /// Get all identifier variants for search strategy
  ///
  /// Returns a list of identifiers to try in order:
  /// 1. Standard normalization (preserves case) - PRIMARY
  /// 2. Strict normalization (lowercase) - FALLBACK
  /// 3. Alternatives from standard
  /// 4. Alternatives from strict
  ///
  /// Duplicates are removed. Invalid variants are excluded.
  ///
  /// Example:
  /// ```dart
  /// getSearchVariants("Mario")
  /// // Returns: ["Mario", "mario"]
  ///
  /// getSearchVariants("Super Mario")
  /// // Returns: ["Super-Mario", "super-mario", "Super_Mario", "super_mario", "SuperMario", "supermario"]
  ///
  /// getSearchVariants("mario")
  /// // Returns: ["mario"] (only one variant)
  /// ```
  static List<String> getSearchVariants(String input) {
    final variants = <String>[];

    // Try standard normalization first (preserves case)
    final standardResult = normalize(input, level: NormalizationLevel.standard);
    String? standardMain;
    List<String> standardAlts = [];

    if (standardResult.isValid && standardResult.normalized != null) {
      standardMain = standardResult.normalized!;
      standardAlts = standardResult.alternatives;
    }

    // Try strict normalization (lowercase)
    final strictResult = normalize(input, level: NormalizationLevel.strict);
    String? strictMain;
    List<String> strictAlts = [];

    if (strictResult.isValid && strictResult.normalized != null) {
      strictMain = strictResult.normalized!;
      strictAlts = strictResult.alternatives;
    }

    // Add in priority order:
    // 1. Standard main result (primary)
    if (standardMain != null) variants.add(standardMain);

    // 2. Strict main result (fallback)
    if (strictMain != null) variants.add(strictMain);

    // 3. Standard alternatives
    variants.addAll(standardAlts);

    // 4. Strict alternatives
    variants.addAll(strictAlts);

    // Remove duplicates while preserving order
    final seen = <String>{};
    return variants.where((v) => seen.add(v)).toList();
  }

  /// Get the recommended search order for an identifier
  ///
  /// Returns [IdentifierSearchStrategy] with ordered list of identifiers to try.
  ///
  /// Strategy:
  /// 1. Try standard normalization (preserves user's intent)
  /// 2. If not found, try strict normalization (Archive.org convention)
  /// 3. Try alternatives for ambiguous cases
  ///
  /// This allows efficient search with fallback to common variations.
  ///
  /// Example:
  /// ```dart
  /// final strategy = getSearchStrategy("Super Mario");
  /// // strategy.variants = ["Super-Mario", "super-mario", "Super_Mario", "super_mario", "SuperMario", "supermario"]
  /// // strategy.primary = "Super-Mario"
  /// // strategy.fallback = "super-mario"
  /// ```
  static IdentifierSearchStrategy getSearchStrategy(String input) {
    final variants = getSearchVariants(input);

    if (variants.isEmpty) {
      return IdentifierSearchStrategy(
        original: input,
        variants: [],
        primary: null,
        fallback: null,
      );
    }

    // First variant is primary (standard normalization)
    final primary = variants.first;

    // Second variant (if exists) is fallback (strict normalization)
    final fallback = variants.length > 1 ? variants[1] : null;

    return IdentifierSearchStrategy(
      original: input,
      variants: variants,
      primary: primary,
      fallback: fallback,
    );
  }

  /// Get suggestions for a specific type of error
  ///
  /// Analyzes the input and provides targeted suggestions
  static List<String> getSuggestions(String input) {
    final result = normalize(input);

    if (result.isValid) {
      // Include the normalized version and alternatives
      return [result.normalized!, ...result.alternatives];
    }

    // Cannot normalize - return empty list
    return [];
  }

  /// Check if identifier looks like a typo or formatting issue
  ///
  /// Returns confidence score (0.0 to 1.0) that this is fixable
  static double getFixConfidence(String input) {
    if (input.isEmpty) return 0.0;

    final result = normalize(input);

    if (result.isValid) {
      // Successfully normalized - confidence based on changes made
      if (result.changes.isEmpty) {
        return 1.0; // Already valid
      } else if (result.changes.length == 1) {
        return 0.9; // Single change (e.g., just lowercase)
      } else if (result.changes.length == 2) {
        return 0.8; // Two changes (e.g., lowercase + spaces)
      } else {
        return 0.7; // Multiple changes
      }
    } else {
      // Cannot normalize - low confidence
      if (input.length < 3) {
        return 0.1; // Too short
      } else if (input.length > 100) {
        return 0.3; // Too long
      } else {
        return 0.2; // Other validation error
      }
    }
  }

  /// Validate an identifier and provide user-friendly feedback
  ///
  /// Returns a [ValidationFeedback] with:
  /// - Whether the identifier is valid
  /// - User-friendly error message (if invalid)
  /// - Suggested correction (if possible)
  /// - Confidence in the suggestion
  static ValidationFeedback validateWithFeedback(String input) {
    if (input.isEmpty) {
      return const ValidationFeedback(
        isValid: false,
        message: 'Please enter an identifier',
      );
    }

    // Check if already valid
    if (IdentifierValidator.isValid(input)) {
      return const ValidationFeedback(
        isValid: true,
        message: 'Valid identifier',
      );
    }

    // Try to normalize
    final result = normalize(input);

    if (result.isValid) {
      // Can be normalized
      final changesList = result.changes.join(', ');
      return ValidationFeedback(
        isValid: false,
        message: 'Invalid format. Suggested correction:',
        suggestion: result.normalized,
        alternatives: result.alternatives,
        confidence: getFixConfidence(input),
        details: 'Changes: $changesList',
      );
    } else {
      // Cannot be normalized
      final errorMessage = result.errors.isNotEmpty
          ? result.errors.first
          : 'Invalid identifier format';
      return ValidationFeedback(
        isValid: false,
        message: errorMessage,
        details: IdentifierValidator.getValidationHint(),
      );
    }
  }
}

/// Result of identifier normalization
class NormalizationResult {
  /// Original input string
  final String original;

  /// Normalized identifier (null if cannot be normalized)
  final String? normalized;

  /// Whether the result is valid
  final bool isValid;

  /// Normalization level used
  final NormalizationLevel level;

  /// List of changes applied during normalization
  final List<String> changes;

  /// Alternative valid suggestions (for ambiguous cases)
  final List<String> alternatives;

  /// Validation errors (if cannot be normalized)
  final List<String> errors;

  const NormalizationResult({
    required this.original,
    required this.normalized,
    required this.isValid,
    required this.level,
    this.changes = const [],
    this.alternatives = const [],
    this.errors = const [],
  });

  /// Whether any changes were made
  bool get wasModified => changes.isNotEmpty;

  /// User-friendly description of changes
  String get changesDescription {
    if (changes.isEmpty) return 'No changes needed';
    if (changes.length == 1) return changes.first;
    return '${changes.length} changes: ${changes.join(', ')}';
  }

  @override
  String toString() {
    if (isValid) {
      return 'NormalizationResult(original: "$original", normalized: "$normalized", changes: [${changes.join(", ")}])';
    } else {
      return 'NormalizationResult(original: "$original", errors: [${errors.join(", ")}])';
    }
  }
}

/// User-friendly validation feedback
class ValidationFeedback {
  /// Whether the input is valid
  final bool isValid;

  /// User-friendly message
  final String message;

  /// Suggested correction (if available)
  final String? suggestion;

  /// Alternative suggestions
  final List<String> alternatives;

  /// Confidence in the suggestion (0.0 to 1.0)
  final double confidence;

  /// Additional details or help text
  final String? details;

  const ValidationFeedback({
    required this.isValid,
    required this.message,
    this.suggestion,
    this.alternatives = const [],
    this.confidence = 0.0,
    this.details,
  });

  /// Whether a suggestion is available
  bool get hasSuggestion => suggestion != null;

  /// Whether alternatives are available
  bool get hasAlternatives => alternatives.isNotEmpty;

  @override
  String toString() {
    if (isValid) {
      return 'ValidationFeedback(valid: true)';
    } else if (hasSuggestion) {
      return 'ValidationFeedback(valid: false, suggestion: "$suggestion", confidence: $confidence)';
    } else {
      return 'ValidationFeedback(valid: false, message: "$message")';
    }
  }
}

/// Search strategy for identifier verification
///
/// Provides ordered list of identifier variants to try during search/verification.
/// Follows strategy: try standard (preserves case) first, then strict (lowercase).
///
/// Example usage:
/// ```dart
/// final strategy = ArchiveIdentifierNormalizer.getSearchStrategy("Mario");
/// print(strategy.primary);  // "Mario"
/// print(strategy.fallback); // "mario"
///
/// // Try each variant in order
/// for (final variant in strategy.variants) {
///   final result = await api.checkIdentifier(variant);
///   if (result.exists) {
///     return variant; // Found!
///   }
/// }
/// ```
class IdentifierSearchStrategy {
  /// Original user input
  final String original;

  /// Ordered list of identifier variants to try
  /// First = primary (standard), subsequent = fallbacks
  final List<String> variants;

  /// Primary identifier (standard normalization, preserves case)
  final String? primary;

  /// Fallback identifier (strict normalization, lowercase)
  /// Used if primary returns 404
  final String? fallback;

  const IdentifierSearchStrategy({
    required this.original,
    required this.variants,
    this.primary,
    this.fallback,
  });

  /// Whether any valid variants exist
  bool get hasVariants => variants.isNotEmpty;

  /// Number of variants to try
  int get variantCount => variants.length;

  /// Whether there's a fallback option
  bool get hasFallback => fallback != null;

  @override
  String toString() {
    return 'IdentifierSearchStrategy(original: "$original", variants: [${variants.join(", ")}], primary: "$primary", fallback: "$fallback")';
  }
}
