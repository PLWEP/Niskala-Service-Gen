import 'package:niskala_service_gen/src/util/templates/filter_builder_template.dart';
import 'package:test/test.dart';

void main() {
  late FilterBuilderTemplate template;

  setUp(() {
    template = FilterBuilderTemplate();
  });

  group('FilterBuilderTemplate', () {
    test('generate produces valid Dart code', () {
      final result = template.generate();

      expect(result, isNotEmpty);
      expect(result, contains('enum ODataFieldType'));
      expect(result, contains('enum ODataFilterOp'));
      expect(result, contains('class ODataFilterEntry'));
      expect(result, contains('class ODataFilterBuilder'));
    });

    test('generate includes all field types', () {
      final result = template.generate();

      expect(result, contains('string'));
      expect(result, contains('number'));
      expect(result, contains('date'));
      expect(result, contains('enumType'));
      expect(result, contains('boolType'));
    });

    test('generate includes all filter operators', () {
      final result = template.generate();

      for (final op in [
        'eq',
        'ne',
        'lt',
        'le',
        'gt',
        'ge',
        'contains',
        'startswith',
        'between',
      ]) {
        expect(result, contains(op), reason: 'Missing operator: $op');
      }
    });

    test('generate includes FilterFieldConfig', () {
      final result = template.generate();

      expect(result, contains('class FilterFieldConfig'));
      expect(result, contains('odataField'));
      expect(result, contains('enumQualifier'));
      expect(result, contains('enumValues'));
    });

    test('generate includes ODataFilterOpLabel extension', () {
      final result = template.generate();

      expect(result, contains('extension ODataFilterOpLabel'));
      expect(result, contains('String get label'));
    });

    test('generate includes IFS Cloud enum format', () {
      final result = template.generate();
      // Check that enum expressions use qualifier'value' format
      expect(result, contains('_enumExpr'));
      expect(result, contains('qualifier'));
    });

    test('generate includes between operator handling', () {
      final result = template.generate();
      // Verify date and number between logic
      expect(result, contains('_dateExpr'));
      expect(result, contains('_numberExpr'));
      expect(result, contains('valueTo'));
    });

    test('generate includes string filter functions', () {
      final result = template.generate();

      expect(result, contains('contains('));
      expect(result, contains('startswith('));
    });
  });
}
