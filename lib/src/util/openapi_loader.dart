import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:niskala_service_gen/src/core/exceptions.dart';
import 'package:niskala_service_gen/src/models/builders/niskala_config.dart';
import 'package:niskala_service_gen/src/models/openapi/openapi_model.dart';
import 'package:path/path.dart' as p;

/// A utility class for loading OpenAPI specifications.
class OpenApiLoader {
  static final Logger _logger = Logger('OpenApiLoader');

  /// Loads all OpenAPI specifications defined in the [config].
  static Future<List<OpenApiModel>> loadAll(NiskalaConfig config) async {
    final resourcePath = config.resourcePath;
    if (resourcePath == null || resourcePath.isEmpty) {
      return [];
    }

    final directory = Directory(resourcePath);
    if (!directory.existsSync()) {
      _logger.warning('Directory does not exist at ${directory.absolute.path}');
      return [];
    }

    final models = <OpenApiModel>[];

    // Use a Set to track projection files we strictly need
    final requiredProjections = config.endpoints
        .map((e) => e.projection.toLowerCase())
        .toSet();

    await for (final entity in directory.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;

      final fileName = p.basename(entity.path).toLowerCase();

      // Strict match: fileName must match projection.json
      // Strict match: fileName must match projection.json or projection.svc.json
      final isRequired = requiredProjections.any((proj) {
        final lowerProj = proj.toLowerCase();
        return fileName == '$lowerProj.json' ||
            fileName == '$lowerProj.svc.json' ||
            fileName == lowerProj;
      });

      if (!isRequired) continue;

      try {
        _logger.info('Loading OpenAPI file: ${entity.path}');
        final content = await entity.readAsString();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;

        if (jsonMap.containsKey('openapi') || jsonMap.containsKey('swagger')) {
          models.add(OpenApiModel.fromJson(jsonMap));
        }
      } catch (e) {
        throw MetadataException(
          'Failed to load OpenAPI file ${entity.path}: $e',
          e,
        );
      }
    }

    return models;
  }
}
