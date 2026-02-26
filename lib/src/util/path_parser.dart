import 'package:niskala_service_gen/src/models/builders/niskala_config.dart';
import 'package:niskala_service_gen/src/models/openapi/openapi_model.dart';
import 'package:niskala_service_gen/src/models/openapi/operation_model.dart';
import 'package:niskala_service_gen/src/models/openapi/path_item_model.dart';
import 'package:niskala_service_gen/src/util/type_mapper.dart';

/// Represents the result of parsing an API endpoint.
class ParsedEndpoint {
  /// Creates a [ParsedEndpoint] with the given details.
  ParsedEndpoint({
    required this.methodName,
    required this.httpMethod,
    required this.path,
    required this.isCollection,
    this.operation,
  });

  /// The deduplicated and formatted name of the method.
  final String methodName;

  /// The HTTP method (get, post, patch, delete, etc.).
  final String httpMethod;

  /// The raw API path.
  final String path;

  /// The associated OpenAPI operation model, if found.
  final OperationModel? operation;

  /// Whether the endpoint targets a collection (e.g., /EntitySet).
  final bool isCollection;
}

/// A utility class that parses OpenAPI paths to extract semantic meaning.
class PathParser {
  /// Creates a [PathParser] instance with a [TypeMapper].
  PathParser(this.mapper);

  /// The mapper used for string transformations.
  final TypeMapper mapper;

  /// Extracts the operation model for a given HTTP method from a path item.
  OperationModel? getOperation(PathItemModel pathItem, String method) {
    switch (method.toLowerCase()) {
      case 'get':
        return pathItem.get;
      case 'post':
        return pathItem.post;
      case 'put':
        return pathItem.put;
      case 'patch':
        return pathItem.patch;
      case 'delete':
        return pathItem.delete;
      default:
        return null;
    }
  }

  /// Parses an endpoint and its associated OpenAPI metadata into a [ParsedEndpoint].
  ParsedEndpoint parseEndpoint({
    required EndpointModel endpoint,
    required OpenApiModel model,
    required Set<String> usedNames,
  }) {
    final path = endpoint.endpoint;
    final method = endpoint.method.toLowerCase();

    // Extract parts to detect collection or key
    final pathParts = path.split('(');
    final basePath = pathParts.first;
    final segments = basePath.split('/').where((s) => s.isNotEmpty).toList();

    // It's a collection if it's a single segment and has no key
    final isCollection = !path.contains('(') && segments.length == 1;

    String? methodName;

    // 1. Detect standard CRUD patterns
    if (isCollection) {
      if (method == 'get') {
        methodName = 'getAll';
      } else if (method == 'post') {
        methodName = 'create';
      }
    } else if (path.contains('(') && !path.split(')').last.contains('/')) {
      if (method == 'get') {
        methodName = 'getByKey';
      } else if (method == 'patch' || method == 'put') {
        methodName = 'update';
      } else if (method == 'delete') {
        methodName = 'delete';
      }
    }

    // 2. Deduce from path if no CRUD pattern
    if (methodName == null) {
      methodName = path.split('/').last;
      methodName = methodName.split('.').last;
      methodName = methodName.split('_').last;
      methodName = methodName.split('(').first;
      methodName = mapper.toCamelCase(methodName);
    }

    // 3. Fallback and collision avoidance
    if (methodName.isEmpty) methodName = 'action';

    if (usedNames.contains(methodName)) {
      methodName = '$methodName${mapper.toPascalCase(method)}';
    }

    if (mapper.isReserved(methodName)) {
      methodName = '${methodName}Action';
    }

    usedNames.add(methodName);

    final pathItem = model.paths[path];
    final operation = pathItem != null ? getOperation(pathItem, method) : null;

    return ParsedEndpoint(
      methodName: methodName,
      httpMethod: method,
      path: path,
      operation: operation,
      isCollection: isCollection,
    );
  }
}
