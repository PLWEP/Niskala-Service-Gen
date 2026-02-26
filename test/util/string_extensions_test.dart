import 'package:niskala_service_gen/src/util/string_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('StringX', () {
    test('toPascalCase', () {
      expect('hello_world'.toPascalCase(), equals('HelloWorld'));
      expect('hello-world'.toPascalCase(), equals('HelloWorld'));
      expect('helloWorld'.toPascalCase(), equals('HelloWorld'));
      expect(''.toPascalCase(), equals(''));
      expect('alreadyPascal'.toPascalCase(), equals('AlreadyPascal'));
    });

    test('toCamelCase', () {
      expect('HelloWorld'.toCamelCase(), equals('helloWorld'));
      expect('hello_world'.toCamelCase(), equals('helloWorld'));
      expect(''.toCamelCase(), equals(''));
    });

    test('toSnakeCase', () {
      expect('HelloWorld'.toSnakeCase(), equals('hello_world'));
      expect('helloWorld'.toSnakeCase(), equals('hello_world'));
      expect('Already_Snake'.toSnakeCase(), equals('already_snake'));
    });
  });
}
