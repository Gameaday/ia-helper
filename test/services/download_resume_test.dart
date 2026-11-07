import 'package:flutter_test/flutter_test.dart';
import 'package:internet_archive_helper/services/internet_archive_api.dart';

void main() {
  group('InternetArchiveApi.planResume decision table (#83)', () {
    test('no partial file on disk -> fresh download', () {
      expect(
        InternetArchiveApi.planResume(existingLength: 0, contentLength: 100),
        ResumeDecision.fresh,
      );
    });

    test('partial shorter than the resource -> resume via Range', () {
      expect(
        InternetArchiveApi.planResume(existingLength: 40, contentLength: 100),
        ResumeDecision.resume,
      );
    });

    test('file length equals resource -> skip (already complete)', () {
      expect(
        InternetArchiveApi.planResume(existingLength: 100, contentLength: 100),
        ResumeDecision.alreadyComplete,
      );
    });

    test('partial longer than the server copy -> restart', () {
      expect(
        InternetArchiveApi.planResume(existingLength: 150, contentLength: 100),
        ResumeDecision.restart,
      );
    });

    test('unknown content length with a partial -> attempt resume', () {
      expect(
        InternetArchiveApi.planResume(existingLength: 40, contentLength: 0),
        ResumeDecision.resume,
      );
    });
  });
}
