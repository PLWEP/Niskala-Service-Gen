import 'package:niskala_service_gen/src/core/logger.dart';
import 'package:niskala_service_gen/src/models/builders/generated_file_model.dart';
import 'package:niskala_service_gen/src/models/builders/niskala_config.dart';
import 'package:niskala_service_gen/src/util/model_finder.dart';
import 'package:niskala_service_gen/src/util/openapi_loader.dart';
import 'package:niskala_service_gen/src/util/service_generator.dart' as util;
import 'package:path/path.dart' as p;

/// A high-level generator that coordinates the end-to-end service generation process.
class ServiceGenerator {
  /// Creates a [ServiceGenerator] with the given [config].
  ServiceGenerator(this.config);

  /// The configuration used for generation.
  final NiskalaConfig config;

  /// Runs the generation process and returns a list of [GeneratedFileModel]s.
  Future<List<GeneratedFileModel>> generate() async {
    final openApiModels = await OpenApiLoader.loadAll(config);
    logger.info('Loaded ${openApiModels.length} OpenAPI documents.');

    final baseDir = p.absolute(config.baseDirectory);
    final modelMap = await ModelFinder.findModels(baseDir);
    logger.info('Discovered ${modelMap.length} models in $baseDir.');

    final generator = util.ServiceGenerator(config, modelMap: modelMap);
    return generator.generateAll(openApiModels);
  }
}
