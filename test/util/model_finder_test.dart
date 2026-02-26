import 'dart:io';

import 'package:niskala_service_gen/src/util/model_finder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ModelFinder', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('model_finder_test');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('should find models in directory structure', () async {
      // Create a mock model file
      final modelFile = File(p.join(tempDir.path, 'user_model.dart'));
      await modelFile.writeAsString('''
class UserModel {}
class ExternalClass {}
''');

      // Create a non-model file
      final otherFile = File(p.join(tempDir.path, 'service.dart'));
      await otherFile.writeAsString('class MyService {}');

      // Create a niskala file (should be ignored)
      final generatedFile = File(
        p.join(tempDir.path, 'user_model.niskala.dart'),
      );
      await generatedFile.writeAsString('class UserModel {}');

      final models = await ModelFinder.findModels(tempDir.path);

      expect(models.containsKey('UserModel'), isTrue);
      expect(models.containsKey('ExternalClass'), isFalse);
      expect(models.containsKey('MyService'), isFalse);
      expect(models.length, equals(1));
    });

    test('getRelativeImport should calculate correct relative paths', () {
      const from = 'lib/service/api/user_service.dart';
      const target = 'lib/models/entities/user_model.dart';

      final relative = ModelFinder.getRelativeImport(from, target);

      // Expected: ../../models/entities/user_model.dart
      expect(relative, equals('../../models/entities/user_model.dart'));
    });

    test('getRelativeImport should handle same directory', () {
      const from = 'lib/models/user_service.dart';
      const target = 'lib/models/user_model.dart';

      final relative = ModelFinder.getRelativeImport(from, target);

      expect(relative, equals('./user_model.dart'));
    });
  });
}
