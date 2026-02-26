import 'package:dart_style/dart_style.dart';

/// Generates the unified providers hub.
class ProvidersTemplate {
  /// Formats the given [code] using DartFormatter.
  String format(String code) {
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(code);
  }

  /// Generates a unified providers hub with auth-aware ApiClient,
  /// OData encoding interceptor, and all service providers.
  ///
  /// This replaces per-service `.riverpod.dart` files.
  String generate({
    required String packageName,
    required List<String> serviceNames,
    required List<String> serviceFileNames,
  }) {
    // Build imports
    final serviceImports = <String>[];
    for (var i = 0; i < serviceNames.length; i++) {
      serviceImports.add(
        "import 'package:$packageName/service/api/"
        "${serviceFileNames[i]}.dart';",
      );
    }

    final directives = [
      "import 'package:dio/dio.dart';",
      "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      "import 'package:$packageName/core/auth_service.dart';",
      "import 'package:$packageName/service/api/api_client.dart';",
      ...serviceImports,
    ]..sort();

    // Build per-service provider declarations
    final serviceProviderDecls = StringBuffer();
    for (var i = 0; i < serviceNames.length; i++) {
      final serviceName = serviceNames[i];
      final camelServiceName =
          serviceName[0].toLowerCase() + serviceName.substring(1);
      final providerName = '${camelServiceName}Provider';
      serviceProviderDecls.writeln('''
/// Provider for [$serviceName].
final $providerName = Provider.autoDispose<$serviceName>((ref) {
  final client = ref.watch(apiClientProvider);
  return $serviceName(client);
});
''');
    }

    return format('''
// GENERATED CODE - DO NOT MODIFY BY HAND

${directives.join('\n')}

/// Provider for the shared [ApiClient] instance.
///
/// Automatically syncs with [AuthService] for environment and token.
final apiClientProvider = Provider.autoDispose<ApiClient>((ref) {
  final auth = ref.watch(authServiceProvider);
  return ApiClient.env(auth.environment)
    ..token = auth.accessToken
    ..onUnauthenticated = () {
      ref.read(authServiceProvider.notifier).logout();
    }
    ..dio.interceptors.add(ODataEncodingInterceptor());
});

/// Interceptor that fixes OData query parameter encoding.
///
/// Dio's default query encoder uses `+` for spaces
/// (`application/x-www-form-urlencoded`), but IFS Cloud OData
/// requires `%20` (RFC 3986 percent-encoding).
class ODataEncodingInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final uri = options.uri;
    if (uri.query.contains('+')) {
      final fixedQuery = uri.query.replaceAll('+', '%20');
      final fixedUri = uri.replace(query: fixedQuery);
      options
        ..path = fixedUri.toString()
        ..queryParameters = {};
    }
    super.onRequest(options, handler);
  }
}

$serviceProviderDecls
''');
  }
}
