import 'package:niskala_service_gen/src/models/builders/niskala_config.dart';
import 'package:niskala_service_gen/src/models/openapi/info_model.dart';
import 'package:niskala_service_gen/src/models/openapi/openapi_model.dart';
import 'package:niskala_service_gen/src/models/openapi/operation_model.dart';
import 'package:niskala_service_gen/src/models/openapi/path_item_model.dart';
import 'package:niskala_service_gen/src/util/path_parser.dart';
import 'package:niskala_service_gen/src/util/type_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('PathParser', () {
    late TypeMapper mapper;
    late PathParser parser;
    late OpenApiModel model;

    setUp(() {
      mapper = TypeMapper({});
      parser = PathParser(mapper);
      model = OpenApiModel(
        openapi: '3.0.1',
        info: InfoModel(title: 'Test API', version: '1.0.0'),
        paths: {},
      );
    });

    test('should identify getAll for GET collection', () {
      final endpoint = EndpointModel(
        projection: 'test.svc',
        method: 'GET',
        endpoint: '/EntitySet',
      );
      final result = parser.parseEndpoint(
        endpoint: endpoint,
        model: model,
        usedNames: {},
      );

      expect(result.methodName, equals('getAll'));
      expect(result.isCollection, isTrue);
    });

    test('should identify create for POST collection', () {
      final endpoint = EndpointModel(
        projection: 'test.svc',
        method: 'POST',
        endpoint: '/EntitySet',
      );
      final result = parser.parseEndpoint(
        endpoint: endpoint,
        model: model,
        usedNames: {},
      );

      expect(result.methodName, equals('create'));
      expect(result.isCollection, isTrue);
    });

    test('should identify getByKey for GET entity with key', () {
      final endpoint = EndpointModel(
        projection: 'test.svc',
        method: 'GET',
        endpoint: '/EntitySet(Key=1)',
      );
      final result = parser.parseEndpoint(
        endpoint: endpoint,
        model: model,
        usedNames: {},
      );

      expect(result.methodName, equals('getByKey'));
      expect(result.isCollection, isFalse);
    });

    test('should identify update for PATCH entity with key', () {
      final endpoint = EndpointModel(
        projection: 'test.svc',
        method: 'PATCH',
        endpoint: '/EntitySet(Key=1)',
      );
      final result = parser.parseEndpoint(
        endpoint: endpoint,
        model: model,
        usedNames: {},
      );

      expect(result.methodName, equals('update'));
    });

    test('should identify delete for DELETE entity with key', () {
      final endpoint = EndpointModel(
        projection: 'test.svc',
        method: 'DELETE',
        endpoint: '/EntitySet(Key=1)',
      );
      final result = parser.parseEndpoint(
        endpoint: endpoint,
        model: model,
        usedNames: {},
      );

      expect(result.methodName, equals('delete'));
    });

    test('should extract method name for custom actions', () {
      final endpoint = EndpointModel(
        projection: 'test.svc',
        method: 'POST',
        endpoint: '/EntitySet(Key=1)/CustomAction',
      );
      final result = parser.parseEndpoint(
        endpoint: endpoint,
        model: model,
        usedNames: {},
      );

      expect(result.methodName, equals('customAction'));
    });

    test('should avoid collisions by appending method name', () {
      final endpoint1 = EndpointModel(
        projection: 'test.svc',
        method: 'GET',
        endpoint: '/Something',
      );
      final endpoint2 = EndpointModel(
        projection: 'test.svc',
        method: 'POST',
        endpoint: '/Something',
      );

      final usedNames = <String>{};

      final result1 = parser.parseEndpoint(
        endpoint: endpoint1,
        model: model,
        usedNames: usedNames,
      );
      final result2 = parser.parseEndpoint(
        endpoint: endpoint2,
        model: model,
        usedNames: usedNames,
      );

      expect(result1.methodName, equals('getAll'));
      expect(result2.methodName, equals('create'));
    });

    test('should identify methods for all HTTP verbs', () {
      final model = OpenApiModel(
        openapi: '3.0.1',
        info: InfoModel(title: 'T', version: '1'),
        paths: {
          '/Test': PathItemModel(
            get: OperationModel(operationId: 'g'),
            post: OperationModel(operationId: 'po'),
            put: OperationModel(operationId: 'pu'),
            patch: OperationModel(operationId: 'pa'),
            delete: OperationModel(operationId: 'd'),
          ),
        },
      );

      expect(parser.getOperation(model.paths['/Test']!, 'GET'), isNotNull);
      expect(parser.getOperation(model.paths['/Test']!, 'POST'), isNotNull);
      expect(parser.getOperation(model.paths['/Test']!, 'PUT'), isNotNull);
      expect(parser.getOperation(model.paths['/Test']!, 'PATCH'), isNotNull);
      expect(parser.getOperation(model.paths['/Test']!, 'DELETE'), isNotNull);
      expect(parser.getOperation(model.paths['/Test']!, 'UNKNOWN'), isNull);
    });

    test('should handle reserved keywords', () {
      final endpoint = EndpointModel(
        projection: 'test.svc',
        method: 'POST',
        endpoint: '/EntitySet/class',
      );
      final result = parser.parseEndpoint(
        endpoint: endpoint,
        model: model,
        usedNames: {},
      );

      expect(result.methodName, equals('classAction'));
    });
  });
}
