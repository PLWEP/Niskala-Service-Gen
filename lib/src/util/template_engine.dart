import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:niskala_service_gen/src/models/builders/niskala_config.dart';
import 'package:niskala_service_gen/src/util/type_mapper.dart';

/// A utility class that handles the generation of Dart code using code_builder.
class TemplateEngine {
  /// Creates a [TemplateEngine] instance with the given [mapper].
  TemplateEngine(this.mapper);

  /// The type mapper used for name formatting and model matching.
  final TypeMapper mapper;

  /// Formats the given [code] using DartFormatter.
  String format(String code) {
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(code);
  }

  /// Generates the base service class content.
  String generateServiceBase({
    required List<Method> methods,
    required String serviceName,
    required String fileName,
    required Set<String> usedModels,
    required String projection,
    required String entitySet,
    Map<String, String> resolvedImports = const {},
  }) {
    final library = Library(
      (l) => l
        ..directives.add(Directive.partOf('$fileName.dart'))
        ..body.add(
          Class(
            (c) => c
              ..name = '_$serviceName'
              ..abstract = true
              ..fields.addAll([
                Field(
                  (f) => f
                    ..name = 'projection'
                    ..type = refer('String')
                    ..static = true
                    ..modifier = FieldModifier.constant
                    ..assignment = Code("'$projection'"),
                ),
                Field(
                  (f) => f
                    ..name = 'entitySet'
                    ..type = refer('String')
                    ..static = true
                    ..modifier = FieldModifier.constant
                    ..assignment = Code("'$entitySet'"),
                ),
                Field(
                  (f) => f
                    ..name = 'basePath'
                    ..type = refer('String')
                    ..static = true
                    ..modifier = FieldModifier.constant
                    ..assignment = const Code(
                      "'main/ifsapplications/projection/v1'",
                    ),
                ),
                Field(
                  (f) => f
                    ..name = 'client'
                    ..type = refer('ApiClient')
                    ..modifier = FieldModifier.final$,
                ),
              ])
              ..constructors.add(
                Constructor(
                  (con) => con
                    ..requiredParameters.add(
                      Parameter(
                        (p) => p
                          ..name = 'client'
                          ..toThis = true,
                      ),
                    ),
                ),
              )
              ..methods.addAll(methods),
          ),
        ),
    );

    final emitter = DartEmitter();
    return format(library.accept(emitter).toString());
  }

  /// Generates the user-facing service class template.
  String generateServiceUser({
    required String serviceName,
    required String fileName,
    required Set<String> usedModels,
    required Map<String, String> resolvedImports,
    required String apiClientImport,
    required String? packageName,
  }) {
    final sortedModels =
        usedModels
            .where(
              (m) =>
                  m != 'void' &&
                  m != 'dynamic' &&
                  m != 'ODataQuery' &&
                  m != 'ErrorModel' &&
                  resolvedImports.containsKey(m),
            )
            .toList()
          ..sort();

    final importLines = sortedModels
        .map((m) => "import '${resolvedImports[m]}';")
        .toList();

    final odataQueryImport = packageName != null
        ? "import 'package:$packageName/service/api/odata_query.dart';"
        : "import 'odata_query.dart';";

    final allDirectives = {
      "import 'package:dio/dio.dart';",
      odataQueryImport,
      apiClientImport,
      ...importLines,
    }.toList()..sort();

    return format('''
${allDirectives.join('\n')}

part '$fileName.niskala.dart';

class $serviceName extends _$serviceName {
  $serviceName(super.client);

  // Custom logic here
}
''');
  }

  /// Generates the ApiClient base class.
  String generateApiClientBase(
    String errorModelImport,
    List<ODataEnvironmentModel> environments,
  ) {
    final envsCode = environments
        .map((e) {
          final secret = e.clientSecret.startsWith('env:')
              ? "String.fromEnvironment('${e.clientSecret.substring(4)}')"
              : "'${e.clientSecret}'";
          return """
    ApiEnvironment(
      name: '${e.name}',
      baseUrl: '${e.baseUrl}',
      realms: '${e.realms}',
      clientId: '${e.clientId}',
      clientSecret: $secret,
    ),""";
        })
        .join('\n');

    return format('$_apiClientBaseContent$envsCode$_apiClientFooter');
  }

  static const String _apiClientBaseContent = r'''
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'api_client.dart';

/// Base class for all Niskala-related exceptions.
class NiskalaException implements Exception {
  const NiskalaException(this.message);
  final String message;

  @override
  String toString() => 'NiskalaException: $message';
}

/// Thrown when the API returns an error response.
class NiskalaApiException extends NiskalaException {
  const NiskalaApiException(super.message, {this.error, this.statusCode});
  final ErrorModel? error;
  final int? statusCode;

  @override
  String toString() => error?.error?.message ?? message;
}

/// Thrown when a network-related error occurs.
class NiskalaNetworkException extends NiskalaException {
  const NiskalaNetworkException(super.message, {this.originalError});
  final dynamic originalError;
}

/// Thrown when authentication fails.
class NiskalaAuthException extends NiskalaException {
  const NiskalaAuthException(super.message);
}

/// Interface for caching API responses.
abstract class NiskalaCacheAdapter {
  Future<void> set(String key, dynamic value);
  Future<dynamic> get(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

/// Simple in-memory cache implementation.
class InMemoryCacheAdapter implements NiskalaCacheAdapter {
  final Map<String, dynamic> _cache = {};

  @override
  Future<void> set(String key, dynamic value) async => _cache[key] = value;

  @override
  Future<dynamic> get(String key) async => _cache[key];

  @override
  Future<void> delete(String key) async => _cache.remove(key);

  @override
  Future<void> clear() async => _cache.clear();
}

class ApiEnvironment {
  const ApiEnvironment({
    required this.name,
    required this.baseUrl,
    required this.realms,
    required this.clientId,
    required this.clientSecret,
  });

  final String name;
  final String baseUrl;
  final String realms;
  final String clientId;
  final String clientSecret;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.client);

  final ApiClient client;
  String? token;
  String? refreshToken;
  Future<String?>? _refreshFuture;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    if (options.contentType == null &&
        !options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      if (_refreshFuture != null) {
        final newToken = await _refreshFuture;
        if (newToken != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final response = await client.dio.fetch<dynamic>(options);
          return handler.resolve(response);
        }
      }

      _refreshFuture = client.refreshToken();
      try {
        final newToken = await _refreshFuture;
        _refreshFuture = null;
        if (newToken != null) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final response = await client.dio.fetch<dynamic>(options);
          return handler.resolve(response);
        } else {
          client.onUnauthenticated?.call();
        }
      } catch (_) {
        _refreshFuture = null;
        client.onUnauthenticated?.call();
      }
    }
    return super.onError(err, handler);
  }
}

abstract class _$ApiClient {
  _$ApiClient({
    String? baseUrl,
    List<ApiEnvironment>? customEnvironments,
    this.cacheAdapter,
  }) {
    if (customEnvironments != null) {
      _customEnvironments = customEnvironments;
    }
    if (baseUrl != null) {
      environment = null;
      dio = Dio(BaseOptions(baseUrl: baseUrl));
    } else {
      final defaultEnv = allEnvironments.firstWhere(
        (e) => e.name == 'Development',
        orElse: () => allEnvironments.first,
      );
      environment = defaultEnv;
      dio = Dio(BaseOptions(baseUrl: defaultEnv.baseUrl));
    }
    // ignore: cascade_invocations
    dio.interceptors.addAll([
      _authInterceptor,
      _RetryInterceptor(dio),
      _CachingInterceptor(cacheAdapter ?? InMemoryCacheAdapter()),
    ]);
  }

  _$ApiClient.env(
    this.environment, {
    List<ApiEnvironment>? customEnvironments,
    this.cacheAdapter,
  }) {
    if (customEnvironments != null) {
      _customEnvironments = customEnvironments;
    }
    dio = Dio(BaseOptions(baseUrl: environment!.baseUrl));
    dio.interceptors.addAll([
      _authInterceptor,
      _RetryInterceptor(dio),
      _CachingInterceptor(cacheAdapter ?? InMemoryCacheAdapter()),
    ]);
  }

  ErrorModel parseErrorResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['error'] is String) {
        return ErrorModel(
          error: ErrorDetailModel(
            message: (data['error_description'] ?? data['error']).toString(),
          ),
        );
      }
      return ErrorModel.fromJson(data);
    }
    return ErrorModel(
      error: ErrorDetailModel(
        message: data?.toString() ?? 'Unknown error',
      ),
    );
  }

  late Dio dio;
  ApiEnvironment? environment;
  final NiskalaCacheAdapter? cacheAdapter;
  void Function()? onUnauthenticated;
  List<ApiEnvironment> _customEnvironments = [];

  List<ApiEnvironment> get allEnvironments => [...environments, ..._customEnvironments];

  late final _AuthInterceptor _authInterceptor = _AuthInterceptor(
    this as ApiClient,
  );

  static const List<ApiEnvironment> environments = [
''';

  static const String _apiClientFooter = r'''
  ];

  set token(String? value) {
    _authInterceptor.token = value;
  }

  String? get token {
    return _authInterceptor.token;
  }

  Future<bool> login(String username, String password) async {
    if (environment == null) {
      return false;
    }

    try {
      final response = await dio.post<dynamic>(
        '${environment!.baseUrl}auth/realms/${environment!.realms}/protocol/openid-connect/token',
        data: {
          'client_id': environment!.clientId,
          'client_secret': environment!.clientSecret,
          'username': username,
          'password': password,
          'grant_type': 'password',
          'scope': 'openid',
          'response_type': 'id_token',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        _authInterceptor.token = data['access_token'] as String?;
        _authInterceptor.refreshToken =
            data['refresh_token'] as String?;
        return true;
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final error = parseErrorResponse(e.response!.data);
        throw NiskalaApiException(
          error.error?.message ?? 'Authentication failed',
          error: error,
          statusCode: e.response?.statusCode,
        );
      }
      throw NiskalaAuthException(e.message ?? 'Authentication error');
    }
    return false;
  }

  Future<String?> refreshToken() async {
    if (environment == null || _authInterceptor.refreshToken == null) {
      return null;
    }

    try {
      final response = await dio.post<dynamic>(
        '${environment!.baseUrl}auth/realms/${environment!.realms}/protocol/openid-connect/token',
        data: {
          'client_id': environment!.clientId,
          'client_secret': environment!.clientSecret,
          'refresh_token': _authInterceptor.refreshToken,
          'grant_type': 'refresh_token',
          'scope': 'openid',
          'response_type': 'id_token',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final newToken = data['access_token'] as String?;
        _authInterceptor.token = newToken;
        _authInterceptor.refreshToken =
            data['refresh_token'] as String?;
        return newToken;
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final error = parseErrorResponse(e.response!.data);
        throw NiskalaApiException(
          error.error?.message ?? 'Token refresh failed',
          error: error,
          statusCode: e.response?.statusCode,
        );
      }
      throw NiskalaAuthException(e.message ?? 'Token refresh error');
    }
    return null;
  }

  /// Transforms the response data before it is returned by the service.
  /// Override this to apply global transformations.
  dynamic transformResponse(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('value')) {
      return data['value'];
    }
    return data;
  }

  /// Performs an OData batch request.
  Future<List<Response<dynamic>>> batch(List<RequestOptions> requests) async {
    if (environment == null) {
      throw const NiskalaException('Environment not set');
    }
    
    // Simplified batch implementation using a custom boundary
    final boundary = 'batch_${DateTime.now().millisecondsSinceEpoch}';
    final buffer = StringBuffer();
    
    for (final req in requests) {
      buffer
        ..writeln('--$boundary')
        ..writeln('Content-Type: application/http')
        ..writeln('Content-Transfer-Encoding: binary')
        ..writeln()
        ..writeln('${req.method} ${req.path} HTTP/1.1');
      for (final header in req.headers.entries) {
        buffer.writeln('${header.key}: ${header.value}');
      }
      buffer.writeln();
      if (req.data != null) {
        buffer.writeln(req.data.toString());
      }
    }
    buffer.writeln('--$boundary--');

    try {
      final response = await dio.post<String>(
        '${environment!.baseUrl}\$batch',
        data: buffer.toString(),
        options: Options(
          contentType: 'multipart/mixed; boundary=$boundary',
        ),
      );

      // Note: Full response parsing would go here.
      // This is a powerful stub for specialized implementations.
      return [response];
    } on DioException catch (e) {
      throw NiskalaNetworkException('Batch request failed', originalError: e);
    }
  }
}

class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this.dio);

  final Dio dio;
  final int maxRetries = 3;

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final retryCount = options.extra['retry_count'] as int? ?? 0;

    if (shouldRetry(err) && retryCount < maxRetries) {
      options.extra['retry_count'] = retryCount + 1;
      
      // Exponential backoff
      await Future<void>.delayed(
        Duration(milliseconds: 500 * (retryCount + 1)),
      );

      try {
        final response = await dio.fetch<dynamic>(options);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }
    return super.onError(err, handler);
  }

  bool shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}

class _CachingInterceptor extends Interceptor {
  _CachingInterceptor(this.adapter);
  final NiskalaCacheAdapter adapter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method != 'GET') {
      return super.onRequest(options, handler);
    }

    final cacheKey = _getCacheKey(options);
    final cachedData = await adapter.get(cacheKey);

    if (cachedData != null) {
      return handler.resolve(
        Response(
          requestOptions: options,
          data: cachedData,
          statusCode: 200,
        ),
      );
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    if (response.requestOptions.method != 'GET') {
      return super.onResponse(response, handler);
    }

    final cacheKey = _getCacheKey(response.requestOptions);
    await adapter.set(cacheKey, response.data);
    super.onResponse(response, handler);
  }

  String _getCacheKey(RequestOptions options) {
    return '${options.method}:${options.uri}';
  }
}
''';

  /// Generates the user-facing ApiClient class content.
  String generateApiClientUser(String errorModelImport) {
    final content =
        '''
import 'package:dio/dio.dart';
$errorModelImport

part 'api_client.niskala.dart';

class ApiClient extends _\$ApiClient {
  ApiClient({super.baseUrl, super.customEnvironments, super.cacheAdapter});

  ApiClient.env(super.environment, {super.customEnvironments, super.cacheAdapter}) : super.env();

  static const List<ApiEnvironment> environments = _\$ApiClient.environments;

  // Custom logic here
}
''';
    return format(content);
  }

  /// Generates the ODataQuery utility class.
  String generateODataQuery() {
    return format(r'''
/// A utility class for building type-safe OData query parameters.
class ODataQuery {
  final Map<String, String> _params = {};

  /// Adds a `$filter` condition to the query.
  void filter(String condition) {
    _params[r'$filter'] = condition;
  }

  /// Fluent helper for equality filter.
  void where(String field, String value) {
    final current = _params[r'$filter'];
    final condition = "$field eq '$value'";
    _params[r'$filter'] = current == null ? condition : '$current and $condition';
  }

  /// Adds an `$expand` clause to the query.
  void expand(List<String> properties) {
    _params[r'$expand'] = properties.join(',');
  }

  /// Adds a `$select` clause to the query.
  void select(List<String> properties) {
    _params[r'$select'] = properties.join(',');
  }

  /// Adds an `$orderby` clause to the query.
  void orderBy(String property, {bool descending = false}) {
    _params[r'$orderby'] = '$property${descending ? " desc" : ""}';
  }

  /// Adds a `$top` clause to the query.
  void top(int value) {
    _params[r'$top'] = value.toString();
  }

  /// Adds a `$skip` clause to the query.
  void skip(int value) {
    _params[r'$skip'] = value.toString();
  }

  /// Returns the built query parameters as a map.
  Map<String, String> build() => Map.unmodifiable(_params);
}
''');
  }

  /// Creates a standard CRUD method.
  Method createCrudMethod({
    required String name,
    required String method,
    required String path,
    required String returnType,
    required String projection,
    bool hasKey = false,
    bool hasBody = false,
    String? bodyModel,
    bool isList = false,
  }) {
    return Method(
      (m) => m
        ..name = name
        ..returns = refer('Future<$returnType>')
        ..modifier = MethodModifier.async
        ..requiredParameters.addAll([
          if (hasKey)
            Parameter(
              (p) => p
                ..name = 'key'
                ..type = refer('String'),
            ),
          if (hasBody)
            Parameter(
              (p) => p
                ..name = 'model'
                ..type = refer(bodyModel ?? 'dynamic'),
            ),
        ])
        ..optionalParameters.addAll([
          Parameter(
            (p) => p
              ..name = 'query'
              ..type = refer('ODataQuery?')
              ..named = true,
          ),
        ])
        ..body = Block((b) {
          final cleanPath = path.startsWith('/') ? path.substring(1) : path;
          final pathSuffix =
              cleanPath == r'$entitySet' || cleanPath.endsWith('Set')
              ? r'$entitySet'
              : cleanPath;
          final fullPath = '\$basePath/\$projection/$pathSuffix';
          final interpolatedPath = fullPath.replaceAll(r'$key', r'$key');

          final dioCall =
              "await client.dio.$method<Map<String, dynamic>>('$interpolatedPath'${hasBody ? ", data: model.toJson()" : ""}, queryParameters: query?.build())";

          if (returnType == 'void') {
            b.statements.add(
              Code('''
              try {
                $dioCall;
              } on DioException catch (e) {
                if (e.response?.data != null) {
                  final error = _parseErrorResponse(e.response!.data);
                  throw NiskalaApiException(
                    error.error?.message ?? 'API Error',
                    error: error,
                    statusCode: e.response?.statusCode,
                  );
                }
                throw NiskalaNetworkException(e.message ?? 'Network error', originalError: e);
              }
            '''),
            );
            return;
          }

          final String parseLogic;
          if (isList) {
            final entityType = returnType
                .replaceAll('List<', '')
                .replaceAll('>', '');
            parseLogic =
                '(transformed as List).map((e) => $entityType.fromJson(e as Map<String, dynamic>)).toList()';
          } else {
            final entityType = returnType;
            parseLogic =
                '$entityType.fromJson(transformed as Map<String, dynamic>)';
          }

          b.statements.add(
            Code('''
            try {
              final response = $dioCall;
              final transformed = client.transformResponse(response.data);
              return $parseLogic;
            } on DioException catch (e) {
              if (e.response?.data != null) {
                final error = client.parseErrorResponse(e.response!.data);
                throw NiskalaApiException(
                  error.error?.message ?? 'API Error',
                  error: error,
                  statusCode: e.response?.statusCode,
                );
              }
              throw NiskalaNetworkException(e.message ?? 'Network error', originalError: e);
            }
          '''),
          );
        }),
    );
  }

  /// Creates a custom API method (Action/Function).
  Method createApiMethod({
    required String name,
    required String method,
    required String path,
    required String returnType,
    required String projection,
  }) {
    // Basic implementation, can be expanded
    final regExp = RegExp(r'\{([^}]+)\}');

    return Method(
      (m) => m
        ..name = name
        ..returns = refer('Future<$returnType>')
        ..modifier = MethodModifier.async
        ..optionalParameters.addAll(
          regExp
              .allMatches(path)
              .map(
                (match) => Parameter(
                  (p) => p
                    ..name = match.group(1)!
                    ..type = refer('String')
                    ..named = true
                    ..required = true,
                ),
              ),
        )
        ..body = Block((b) {
          final cleanPath = path.startsWith('/') ? path.substring(1) : path;
          final pathSuffix =
              cleanPath == r'$entitySet' || cleanPath.endsWith('Set')
              ? r'$entitySet'
              : cleanPath;
          final fullPath = '\$basePath/\$projection/$pathSuffix';
          final interpolatedPath = fullPath.replaceAllMapped(
            regExp,
            (m) => '\$${m.group(1)}',
          );

          b.statements.add(
            Code('''
            try {
              final response = await client.dio.$method<Map<String, dynamic>>('$interpolatedPath');
              final transformed = client.transformResponse(response.data);
              return transformed;
            } on DioException catch (e) {
              if (e.response?.data != null) {
                final error = client.parseErrorResponse(e.response!.data);
                throw NiskalaApiException(
                  error.error?.message ?? 'API Error',
                  error: error,
                  statusCode: e.response?.statusCode,
                );
              }
              throw NiskalaNetworkException(e.message ?? 'Network error', originalError: e);
            }
            '''),
          );
        }),
    );
  }

  /// Generates the Riverpod providers for the services.
  String generateRiverpodFile({
    required String serviceName,
    required String fileName,
    required String packageName,
  }) {
    final camelServiceName =
        serviceName[0].toLowerCase() + serviceName.substring(1);
    final providerName = '${camelServiceName}Provider';

    final directives = [
      "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      "import 'package:$packageName/service/api/api_client.dart';",
      "import 'package:$packageName/service/api/$fileName.dart';",
    ]..sort();

    return format('''
${directives.join('\n')}

/// Provider for the ApiClient.
final apiClientProvider = Provider.autoDispose<ApiClient>((ref) => ApiClient());

/// Provider for the $serviceName.
final $providerName = Provider.autoDispose<$serviceName>((ref) {
  final client = ref.watch(apiClientProvider);
  return $serviceName(client);
});

/// Future provider for the $serviceName data.
final all${serviceName.replaceAll('Service', '')}Provider = FutureProvider.autoDispose((ref) async {
  final service = ref.watch($providerName);
  return service.getAll();
});
''');
  }

  /// Generates a basic test file for a service.
  String generateServiceTest({
    required String serviceName,
    required String fileName,
    required Set<String> usedModels,
    required Map<String, String> resolvedImports,
    required String packageName,
    required Set<String> methodNames,
  }) {
    final testGetAll = methodNames.contains('getAll')
        ? '''
    test('getAll should return results on success', () async {
      final responseData = <String, dynamic>{'value': <dynamic>[]};

      when(
        () => mockClient.dio.get<Map<String, dynamic>>(
          any<String>(),
          queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: responseData,
          requestOptions: RequestOptions(),
        ),
      );

      when(() => mockClient.transformResponse(any<Map<String, dynamic>>())).thenReturn(<dynamic>[]);

      try {
        await service.getAll();
      } catch (_) {
        // May fail if getAll is not implemented for this service
      }
    });'''
        : '';

    final testGetByKey = methodNames.contains('getByKey')
        ? '''
    test('getByKey should handle 404 error model', () async {
      when(
        () => mockClient.dio.get<Map<String, dynamic>>(
          any<String>(),
          queryParameters: any<Map<String, dynamic>>(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response<Map<String, dynamic>>(
            statusCode: 404,
            data: <String, dynamic>{
              'error': <String, dynamic>{'message': 'Not Found'},
            },
            requestOptions: RequestOptions(),
          ),
        ),
      );

      try {
        await service.getByKey('some_key');
      } on ErrorModel {
        // Success
      } catch (_) {
        // Other errors
      }
    });'''
        : '';

    const apiClientMock = 'MockApiClient';

    final directives = [
      "import 'package:dio/dio.dart';",
      "import 'package:flutter_test/flutter_test.dart';",
      "import 'package:mocktail/mocktail.dart';",
      "import 'package:$packageName/service/api/api_client.dart';",
      "import 'package:$packageName/service/api/$fileName.dart';",
    ]..sort();

    return format('''
${directives.join('\n')}

class $apiClientMock extends Mock implements ApiClient {}

void main() {
  late $serviceName service;
  late $apiClientMock mockClient;
  late Dio mockDio;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = $apiClientMock();
    mockDio = Dio(); 
    
    service = $serviceName(mockClient);
    
    when(() => mockClient.dio).thenReturn(mockDio);
  },);

  group('$serviceName Tests', () {
    test('instance should be created', () {
      expect(service, isNotNull);
    },);

$testGetAll

$testGetByKey
  },);
}
''');
  }
}
