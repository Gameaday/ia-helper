import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/utils/archive_identifier_normalizer.dart';

void main() {
  group('ArchiveIdentifierNormalizer', () {
    group('normalize()', () {
      test('valid identifier remains unchanged', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'valid-identifier',
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('valid-identifier'));
        expect(result.changes, isEmpty);
      });

      test('converts uppercase to lowercase', () {
        final result = ArchiveIdentifierNormalizer.normalize('Mario');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario'));
        expect(result.changes, contains('Converted to lowercase'));
      });

      test('replaces spaces with hyphens', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'super mario bros',
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('super-mario-bros'));
        expect(result.changes, contains('Replaced spaces with hyphens'));
      });

      test('trims whitespace', () {
        final result = ArchiveIdentifierNormalizer.normalize('  mario  ');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario'));
        expect(result.changes, contains('Trimmed whitespace'));
      });

      test('removes special characters', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario!@#\$%');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario'));
        expect(result.changes, contains('Removed invalid characters'));
      });

      test('normalizes em-dash to hyphen', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario—bros');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario-bros'));
        expect(result.changes, contains('Normalized dash characters'));
      });

      test('normalizes en-dash to hyphen', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario–bros');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario-bros'));
        expect(result.changes, contains('Normalized dash characters'));
      });

      test('collapses consecutive hyphens', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario--bros');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario-bros'));
        expect(
          result.changes,
          contains('Collapsed consecutive special characters'),
        );
      });

      test('collapses consecutive underscores', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario__bros');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario-bros'));
        expect(
          result.changes,
          contains('Collapsed consecutive special characters'),
        );
      });

      test('collapses mixed consecutive special chars', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario.-_bros');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario-bros'));
        expect(
          result.changes,
          contains('Collapsed consecutive special characters'),
        );
      });

      test('removes leading hyphens', () {
        final result = ArchiveIdentifierNormalizer.normalize('-mario');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario'));
        expect(
          result.changes,
          contains('Removed leading/trailing special characters'),
        );
      });

      test('removes trailing hyphens', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario-');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario'));
        expect(
          result.changes,
          contains('Removed leading/trailing special characters'),
        );
      });

      test('combines multiple normalizations', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          '  Super Mario Bros! ',
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('super-mario-bros'));
        expect(result.changes.length, greaterThan(1));
      });

      test('generates alternatives for spaces', () {
        final result = ArchiveIdentifierNormalizer.normalize('super mario');
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('super-mario'));
        expect(result.alternatives, contains('super_mario'));
        expect(result.alternatives, contains('supermario'));
      });

      test('rejects empty input', () {
        final result = ArchiveIdentifierNormalizer.normalize('');
        expect(result.isValid, isFalse);
        expect(result.errors, contains('Input is empty'));
      });

      test('rejects too short identifiers', () {
        final result = ArchiveIdentifierNormalizer.normalize('ab');
        expect(result.isValid, isFalse);
        expect(result.errors.first, contains('too short'));
      });

      test('truncates too long identifiers', () {
        final longString = 'a' * 150;
        final result = ArchiveIdentifierNormalizer.normalize(longString);
        expect(result.isValid, isTrue);
        expect(result.normalized!.length, equals(100));
        expect(result.changes, contains('Truncated to 100 characters'));
      });

      test('handles mixed case with spaces and special chars', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'The DOOM Game!!!',
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('the-doom-game'));
      });

      test('handles real-world example: URL paste', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'https://archive.org/details/mario',
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('httpsarchive.orgdetailsmario'));
      });
    });

    group('needsNormalization()', () {
      test('returns false for valid identifiers', () {
        expect(
          ArchiveIdentifierNormalizer.needsNormalization('valid-identifier'),
          isFalse,
        );
        expect(
          ArchiveIdentifierNormalizer.needsNormalization('test123'),
          isFalse,
        );
        expect(
          ArchiveIdentifierNormalizer.needsNormalization('my_archive'),
          isFalse,
        );
      });

      test('returns true for invalid identifiers', () {
        expect(
          ArchiveIdentifierNormalizer.needsNormalization('super mario'),
          isTrue,
        );
        expect(ArchiveIdentifierNormalizer.needsNormalization('test!'), isTrue);
        expect(
          ArchiveIdentifierNormalizer.needsNormalization('--mario--'),
          isTrue,
        );
      });
    });

    group('getSuggestions()', () {
      test('returns normalized version and alternatives', () {
        final suggestions = ArchiveIdentifierNormalizer.getSuggestions(
          'Super Mario',
        );
        expect(suggestions, isNotEmpty);
        expect(suggestions.first, equals('super-mario'));
        expect(suggestions, contains('super_mario'));
        expect(suggestions, contains('supermario'));
      });

      test('returns single suggestion for simple case', () {
        final suggestions = ArchiveIdentifierNormalizer.getSuggestions('Mario');
        expect(suggestions, equals(['mario']));
      });

      test('returns empty for invalid input', () {
        final suggestions = ArchiveIdentifierNormalizer.getSuggestions('ab');
        expect(suggestions, isEmpty);
      });
    });

    group('getFixConfidence()', () {
      test('returns 1.0 for valid identifiers', () {
        expect(
          ArchiveIdentifierNormalizer.getFixConfidence('valid-identifier'),
          equals(1.0),
        );
      });

      test('returns high confidence for simple fixes', () {
        expect(
          ArchiveIdentifierNormalizer.getFixConfidence('Mario'),
          equals(0.9),
        );
      });

      test('returns medium confidence for multiple changes', () {
        final confidence = ArchiveIdentifierNormalizer.getFixConfidence(
          'Super Mario Bros',
        );
        expect(confidence, greaterThanOrEqualTo(0.7));
        expect(confidence, lessThan(1.0));
      });

      test('returns low confidence for too short input', () {
        expect(
          ArchiveIdentifierNormalizer.getFixConfidence('ab'),
          lessThan(0.2),
        );
      });

      test('returns medium confidence for too long input', () {
        final longString = 'a' * 150;
        final confidence = ArchiveIdentifierNormalizer.getFixConfidence(
          longString,
        );
        expect(
          confidence,
          greaterThanOrEqualTo(0.7),
        ); // Truncation is a fixable change
        expect(confidence, lessThan(1.0));
      });
    });

    group('validateWithFeedback()', () {
      test('returns valid feedback for valid identifiers', () {
        final feedback = ArchiveIdentifierNormalizer.validateWithFeedback(
          'valid-identifier',
        );
        expect(feedback.isValid, isTrue);
        expect(feedback.message, equals('Valid identifier'));
      });

      test('provides normalization info for identifiers needing changes', () {
        final feedback = ArchiveIdentifierNormalizer.validateWithFeedback(
          'Super Mario',
        );
        expect(feedback.isValid, isFalse); // Has spaces
        expect(feedback.hasSuggestion, isTrue);
        expect(feedback.suggestion, equals('super-mario'));
        expect(feedback.confidence, greaterThan(0.0));
      });

      test('provides multiple alternatives for ambiguous cases', () {
        final feedback = ArchiveIdentifierNormalizer.validateWithFeedback(
          'Super Mario',
        );
        expect(feedback.isValid, isFalse);
        expect(feedback.hasSuggestion, isTrue);
        expect(feedback.hasAlternatives, isTrue);
        expect(feedback.alternatives, contains('super_mario'));
      });

      test('provides error message for unfixable identifiers', () {
        final feedback = ArchiveIdentifierNormalizer.validateWithFeedback('ab');
        expect(feedback.isValid, isFalse);
        expect(feedback.hasSuggestion, isFalse);
        expect(feedback.message, contains('too short'));
      });

      test('handles empty input gracefully', () {
        final feedback = ArchiveIdentifierNormalizer.validateWithFeedback('');
        expect(feedback.isValid, isFalse);
        expect(feedback.message, equals('Please enter an identifier'));
      });
    });

    group('Real-world examples', () {
      test('normalizes "Super Mario Bros"', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'Super Mario Bros',
        );
        expect(result.normalized, equals('super-mario-bros'));
        expect(
          result.alternatives,
          containsAll(['super_mario_bros', 'supermariobros']),
        );
      });

      test('normalizes "The DOOM WADs"', () {
        final result = ArchiveIdentifierNormalizer.normalize('The DOOM WADs');
        expect(result.normalized, equals('the-doom-wads'));
      });

      test('normalizes "mario!@#"', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario!@#');
        expect(result.normalized, equals('mario'));
      });

      test('normalizes "mario—bros—64"', () {
        final result = ArchiveIdentifierNormalizer.normalize('mario—bros—64');
        expect(result.normalized, equals('mario-bros-64'));
      });

      test('normalizes "  --Mario--  "', () {
        final result = ArchiveIdentifierNormalizer.normalize('  --Mario--  ');
        expect(result.normalized, equals('mario'));
      });
    });

    group('Normalization Levels', () {
      test('standard level preserves case', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'Mario',
          level: NormalizationLevel.standard,
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('Mario'));
        expect(result.level, equals(NormalizationLevel.standard));
        expect(result.changes, isEmpty); // No changes needed
      });

      test('strict level converts to lowercase', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'Mario',
          level: NormalizationLevel.strict,
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('mario'));
        expect(result.level, equals(NormalizationLevel.strict));
        expect(result.changes, contains('Converted to lowercase'));
      });

      test('standard level with spaces uses case-preserved alternatives', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'Super Mario',
          level: NormalizationLevel.standard,
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('Super-Mario'));
        expect(result.level, equals(NormalizationLevel.standard));
        // Alternatives should preserve case for standard level
        expect(result.alternatives, contains('Super_Mario'));
        expect(result.alternatives, contains('SuperMario'));
      });

      test('strict level with spaces uses lowercase alternatives', () {
        final result = ArchiveIdentifierNormalizer.normalize(
          'Super Mario',
          level: NormalizationLevel.strict,
        );
        expect(result.isValid, isTrue);
        expect(result.normalized, equals('super-mario'));
        expect(result.level, equals(NormalizationLevel.strict));
        expect(result.alternatives, contains('super_mario'));
        expect(result.alternatives, contains('supermario'));
      });

      test('default level is strict', () {
        final result = ArchiveIdentifierNormalizer.normalize('Mario');
        expect(result.level, equals(NormalizationLevel.strict));
        expect(result.normalized, equals('mario'));
      });
    });

    group('getSearchVariants()', () {
      test('returns both standard and strict for mixed case', () {
        final variants = ArchiveIdentifierNormalizer.getSearchVariants('Mario');
        expect(variants, contains('Mario')); // standard
        expect(variants, contains('mario')); // strict
        expect(variants.length, greaterThanOrEqualTo(2));
      });

      test('returns single variant for already lowercase', () {
        final variants = ArchiveIdentifierNormalizer.getSearchVariants('mario');
        expect(variants, contains('mario'));
        // Should not have duplicates
        expect(variants.toSet().length, equals(variants.length));
      });

      test('returns all alternatives with spaces', () {
        final variants = ArchiveIdentifierNormalizer.getSearchVariants(
          'Super Mario',
        );
        // Should include:
        // Standard: Super-Mario, Super_Mario, SuperMario
        // Strict: super-mario, super_mario, supermario
        expect(variants.length, greaterThan(2));
        expect(variants, contains('Super-Mario'));
        expect(variants, contains('super-mario'));
      });

      test('removes duplicates', () {
        final variants = ArchiveIdentifierNormalizer.getSearchVariants('test');
        // "test" normalized at both levels produces same result
        final uniqueVariants = variants.toSet();
        expect(variants.length, equals(uniqueVariants.length));
      });

      test('returns empty for invalid input', () {
        final variants = ArchiveIdentifierNormalizer.getSearchVariants('ab');
        expect(variants, isEmpty);
      });
    });

    group('getSearchStrategy()', () {
      test('provides primary and fallback for mixed case', () {
        final strategy = ArchiveIdentifierNormalizer.getSearchStrategy('Mario');
        expect(strategy.original, equals('Mario'));
        expect(strategy.primary, equals('Mario')); // standard (preserves case)
        expect(strategy.fallback, equals('mario')); // strict (lowercase)
        expect(strategy.hasVariants, isTrue);
        expect(strategy.hasFallback, isTrue);
        expect(strategy.variantCount, greaterThanOrEqualTo(2));
      });

      test('provides single variant for lowercase', () {
        final strategy = ArchiveIdentifierNormalizer.getSearchStrategy('mario');
        expect(strategy.primary, equals('mario'));
        expect(strategy.fallback, isNull); // no fallback (same as primary)
        expect(strategy.hasVariants, isTrue);
        expect(strategy.variantCount, greaterThanOrEqualTo(1));
      });

      test('provides multiple variants with spaces', () {
        final strategy = ArchiveIdentifierNormalizer.getSearchStrategy(
          'Super Mario',
        );
        expect(strategy.primary, equals('Super-Mario')); // standard first
        expect(strategy.fallback, equals('super-mario')); // strict fallback
        expect(strategy.variants.length, greaterThan(2));
      });

      test('returns empty strategy for invalid input', () {
        final strategy = ArchiveIdentifierNormalizer.getSearchStrategy('ab');
        expect(strategy.hasVariants, isFalse);
        expect(strategy.primary, isNull);
        expect(strategy.fallback, isNull);
      });

      test('variants are in correct order', () {
        final strategy = ArchiveIdentifierNormalizer.getSearchStrategy(
          'Test Archive',
        );
        // First variant should be standard (case-preserved)
        expect(strategy.variants.first, equals('Test-Archive'));
        // Should contain strict variant
        expect(strategy.variants, contains('test-archive'));
      });
    });
  });
}
