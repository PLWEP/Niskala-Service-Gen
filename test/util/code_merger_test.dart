import 'package:niskala_service_gen/src/util/code_merger.dart';
import 'package:test/test.dart';

void main() {
  group('CodeMerger', () {
    test(
      'should return new content if marker is missing in existing content',
      () {
        const existing = 'class MyService {}';
        const newContent = '// Custom logic here\nclass MyServiceBase {}';
        expect(CodeMerger.merge(existing, newContent), equals(newContent));
      },
    );

    test('should preserve custom logic after marker', () {
      const existing = '''
import 'package:dio/dio.dart';

// Custom logic here
  void customMethod() {
    print('hello');
  }
''';
      const newContent = '''
import 'package:dio/dio.dart';

abstract class _BaseService {}

// Custom logic here
''';

      final merged = CodeMerger.merge(existing, newContent);
      expect(merged, contains('void customMethod()'));
      expect(merged, contains("print('hello');"));
      expect(merged, contains('abstract class _BaseService {}'));
    });

    test('should merge and deduplicate imports', () {
      const existing = '''
import 'package:dio/dio.dart';
import '../../models/user.dart';

// Custom logic here
''';
      const newContent = '''
import 'package:dio/dio.dart';
import 'package:path/path.dart';

// Custom logic here
''';

      final merged = CodeMerger.merge(existing, newContent);
      expect(merged, contains("import 'package:dio/dio.dart';"));
      expect(merged, contains("import '../../models/user.dart';"));
      expect(merged, contains("import 'package:path/path.dart';"));
    });

    test(
      'should prioritize relative imports over package imports for same model',
      () {
        const existing = "import 'package:my_app/models/user.dart';";
        const newContent =
            "import '../../models/user.dart';\n// Custom logic here";

        final merged = CodeMerger.merge(existing, newContent);
        expect(merged, contains('../../models/user.dart'));
        expect(merged, isNot(contains('package:my_app/models/user.dart')));
      },
    );

    test('should sort imports correctly (dart: > package: > relative)', () {
      const content = '''
import '../../models/b.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../models/a.dart';
// Custom logic here
''';
      final merged = CodeMerger.merge(content, content);
      final lines = merged.split('\n');

      // dart: first
      expect(lines[0], contains('dart:io'));
      // package: second (comparing package to non-package)
      expect(lines[1], contains('package:dio/dio.dart'));
      expect(lines[2], contains('package:path/path.dart'));
      // relative sorted alphabetically
      expect(lines[3], contains('models/a.dart'));
      expect(lines[4], contains('models/b.dart'));
    });

    test('should handle missing marker in new content safely', () {
      const existing = 'Existing content\n// Custom logic here';
      const newContent = 'Invalid content';
      expect(CodeMerger.merge(existing, newContent), equals(existing));
    });
  });
}
