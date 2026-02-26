import 'package:niskala_service_gen/src/models/openapi/info_model.dart';
import 'package:niskala_service_gen/src/models/openapi/openapi_model.dart';
import 'package:niskala_service_gen/src/models/openapi/operation_model.dart';
import 'package:test/test.dart';

void main() {
  group('OpenAPI Models', () {
    test('InfoModel.fromJson', () {
      final json = {
        'title': 'Test API',
        'version': '1.0.0',
        'description': 'A test api',
      };
      final model = InfoModel.fromJson(json);
      expect(model.title, 'Test API');
      expect(model.version, '1.0.0');
      expect(model.description, 'A test api');
    });

    test('OpenApiModel.fromJson with paths', () {
      final json = {
        'openapi': '3.0.1',
        'info': {'title': 'T', 'version': 'V'},
        'paths': {
          '/test': {
            'get': {'operationId': 'getTest'},
          },
        },
      };
      final model = OpenApiModel.fromJson(json);
      expect(model.openapi, '3.0.1');
      expect(model.paths.containsKey('/test'), isTrue);
      expect(model.paths['/test']?.get?.operationId, 'getTest');
    });

    test('OperationModel.fromJson with request body', () {
      final json = {
        'operationId': 'createTest',
        'requestBody': {
          'content': {
            'application/json': {
              'schema': {r'$ref': '#/components/schemas/Test'},
            },
          },
        },
      };
      final model = OperationModel.fromJson(json);
      expect(model.operationId, 'createTest');
      expect(
        model.requestBody?.content.containsKey('application/json'),
        isTrue,
      );
      // Use the convenience getter
      expect(model.requestBody?.schema?.ref, '#/components/schemas/Test');
    });

    test('OperationModel.fromJson with components ref in response', () {
      final json = {
        'operationId': 'getTest',
        'responses': {
          '200': {
            'description': 'OK',
            'content': {
              'application/json': {
                'schema': {r'$ref': '#/components/schemas/TestResponse'},
              },
            },
          },
        },
      };
      final model = OperationModel.fromJson(json);
      expect(model.responses.containsKey('200'), isTrue);
      // Use the consolidated schema object
      expect(
        model.responses['200']?.schema?.ref,
        '#/components/schemas/TestResponse',
      );
    });
    group('OpenAPI Model Null Safety', () {
      test('OperationModel with empty responses', () {
        final json = {'operationId': 'test'};
        final model = OperationModel.fromJson(json);
        expect(model.responses, isEmpty);
      });
    });
  });
}
