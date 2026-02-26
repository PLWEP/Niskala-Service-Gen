import 'package:niskala_service_gen/src/util/string_extensions.dart';

/// A utility class that handles mapping between OpenAPI types/names and Dart types/names.
class TypeMapper {
  /// Creates a new [TypeMapper] with the given [modelMap].
  TypeMapper(this.modelMap);

  /// The map of discovered model class names to their absolute file paths.
  final Map<String, String> modelMap;

  /// Dart reserved keywords that should be escaped.
  static const reservedKeywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'patch',
    'required',
    'rethrow',
    'return',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };

  /// Converts a string to PascalCase.
  String toPascalCase(String s) => s.toPascalCase();

  /// Converts a string to camelCase.
  String toCamelCase(String s) => s.toCamelCase();

  /// Converts a string to snake_case.
  String toSnakeCase(String s) => s.toSnakeCase();

  /// Checks if a string is a Dart reserved keyword.
  bool isReserved(String s) => reservedKeywords.contains(s);

  /// Finds the best matching model name from the [modelMap].
  String findBestModelMatch(String modelName) {
    // Direct match
    if (modelMap.containsKey(modelName)) {
      return modelName;
    }

    // Normalized match (remove - and _)
    final normalized = modelName
        .replaceAll('-', '')
        .replaceAll('_', '')
        .toLowerCase();

    String? findMatch(String target) {
      try {
        return modelMap.keys.firstWhere(
          (k) =>
              k.replaceAll('-', '').replaceAll('_', '').toLowerCase() == target,
        );
      } catch (_) {
        return null;
      }
    }

    var matchedKey = findMatch(normalized);
    if (matchedKey != null) return matchedKey;

    // Suffix matching on original name
    final suffixes = [
      'requestmodel',
      'responsemodel',
      'actionrequestmodel',
      'actionresponsemodel',
      'request',
      'response',
    ];
    for (final suffix in suffixes) {
      if (normalized.endsWith(suffix)) {
        final base = normalized.substring(0, normalized.length - suffix.length);
        final target = '${base}model';
        matchedKey = findMatch(target);
        if (matchedKey != null) {
          return matchedKey;
        }
      }
    }

    // Try stripping common OData suffixes to find the base model
    final suffixesToStrip = [
      'arrayresponsemodel',
      'arrayresponse',
      'responsemodel',
      'setmodel',
      'entitiesmodel',
      'array',
      'set',
      'entities',
      'response',
    ];
    for (final suffix in suffixesToStrip) {
      if (normalized.endsWith(suffix)) {
        final base = normalized.substring(0, normalized.length - suffix.length);
        // Try both with and without 'model' suffix
        final targetWithModel = base.endsWith('model') ? base : '${base}model';
        matchedKey = findMatch(targetWithModel);
        if (matchedKey != null) return matchedKey;

        matchedKey = findMatch(base);
        if (matchedKey != null) return matchedKey;
      }
    }

    // Try mapping 'array' to 'set' and repeat
    if (normalized.contains('array')) {
      final transformed = normalized.replaceAll('array', 'set');
      matchedKey = findMatch(transformed);
      if (matchedKey != null) return matchedKey;

      for (final suffix in suffixes) {
        if (transformed.endsWith(suffix)) {
          final base = transformed.substring(
            0,
            transformed.length - suffix.length,
          );
          matchedKey = findMatch('${base}model');
          if (matchedKey != null) return matchedKey;
        }
      }
    }

    return modelName;
  }
}
