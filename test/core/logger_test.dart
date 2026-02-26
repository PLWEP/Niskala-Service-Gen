import 'package:niskala_service_gen/src/core/logger.dart';
import 'package:test/test.dart';

void main() {
  group('Logger', () {
    test('setupLogger should not throw', () {
      expect(setupLogger, returnsNormally);
      expect(() => setupLogger(verbose: true), returnsNormally);
    });

    test('logger should be accessible', () {
      expect(logger, isNotNull);
      // Log some items to check coverage
      logger
        ..info('Test info')
        ..warning('Test warning')
        ..severe('Test severe')
        ..fine('Test fine');
    });
  });
}
