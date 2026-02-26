import 'package:niskala_service_gen/src/models/openapi/components_model.dart';
import 'package:niskala_service_gen/src/models/openapi/openapi_model.dart';
import 'package:niskala_service_gen/src/models/openapi/operation_model.dart';
import 'package:niskala_service_gen/src/models/openapi/schema_model.dart';
import 'package:niskala_service_gen/src/models/openapi/server_model.dart';
import 'package:niskala_service_gen/src/models/openapi/tag_model.dart';
import 'package:test/test.dart';

void main() {
  group('Exhaustive OpenAPI Data Models', () {
    test('OpenApiModel Full', () {
      final json = <String, dynamic>{
        'openapi': '3.0.1',
        'info': <String, dynamic>{
          'title': 'T',
          'version': '1',
          'description': 'D',
        },
        'servers': [
          <String, dynamic>{'url': 'u', 'description': 'd'},
        ],
        'security': [
          <String, dynamic>{'api_key': <dynamic>[]},
        ],
        'tags': [
          <String, dynamic>{'name': 't', 'description': 'd'},
        ],
        'paths': <String, dynamic>{
          '/test': <String, dynamic>{
            'get': <String, dynamic>{'operationId': 'o'},
          },
        },
        'components': <String, dynamic>{
          'schemas': <String, dynamic>{
            'S': <String, dynamic>{'type': 's'},
          },
        },
      };
      final model = OpenApiModel.fromJson(json);
      expect(model.openapi, equals('3.0.1'));
      expect(model.servers.length, 1);
      expect(model.tags.length, 1);
      expect(model.paths['/test']?.get?.operationId, 'o');
    });

    test('OperationModel Full', () {
      final json = <String, dynamic>{
        'tags': ['t'],
        'summary': 's',
        'description': 'd',
        'operationId': 'o',
        'parameters': [
          <String, dynamic>{'name': 'p', 'in': 'query'},
        ],
        'requestBody': <String, dynamic>{
          'content': <String, dynamic>{
            'application/json': <String, dynamic>{
              'schema': <String, dynamic>{'type': 'o'},
            },
          },
        },
        'responses': <String, dynamic>{
          '200': <String, dynamic>{
            'description': 'ok',
            'content': <String, dynamic>{
              'application/json': <String, dynamic>{
                'schema': <String, dynamic>{'type': 'o'},
              },
            },
          },
        },
      };
      final model = OperationModel.fromJson(json);
      expect(model.tags.first, 't');
      expect(model.summary, 's');
      expect(model.parameters.first.name, 'p');
      // Using . instead of ?. as suggested by analyzer (though technically unsafe for Maps, it's fine in this test context)
      // Actually, Map access returned dynamic in some cases if not typed? No.
      expect(model.responses['200']!.description, 'ok');
    });

    test('SchemaModel Full', () {
      final json = <String, dynamic>{
        'type': 'object',
        'items': <String, dynamic>{'type': 'string'},
        'properties': <String, dynamic>{
          'p': <String, dynamic>{'type': 's'},
        },
        'required': ['p'],
        r'$ref': '#/r',
        'enum': ['v'],
      };
      final model = SchemaModel.fromJson(json);
      expect(model.type, 'object');
      expect(model.items?.type, 'string');
      expect(model.properties['p']?.type, 's');
      expect(model.requiredFields.first, 'p');
      expect(model.ref, '#/r');
      expect(model.enumValues, contains('v'));
    });

    test('ComponentsModel Full', () {
      final json = <String, dynamic>{
        'schemas': <String, dynamic>{
          'S': <String, dynamic>{'type': 's'},
        },
        'parameters': <String, dynamic>{
          'P': <String, dynamic>{'name': 'p', 'in': 'query'},
        },
        'responses': <String, dynamic>{
          'R': <String, dynamic>{'description': 'd'},
        },
        'requestBodies': <String, dynamic>{
          'RB': <String, dynamic>{'content': <String, dynamic>{}},
        },
      };
      final model = ComponentsModel.fromJson(json);
      expect(model.schemas.containsKey('S'), isTrue);
      expect(model.parameters.containsKey('P'), isTrue);
      expect(model.responses.containsKey('R'), isTrue);
      expect(model.requestBodies.containsKey('RB'), isTrue);
    });

    test('ServerModel and TagModel', () {
      expect(
        ServerModel.fromJson(<String, dynamic>{'url': 'u'}).url,
        equals('u'),
      );
      expect(
        TagModel.fromJson(<String, dynamic>{'name': 't'}).name,
        equals('t'),
      );
    });
  });
}
