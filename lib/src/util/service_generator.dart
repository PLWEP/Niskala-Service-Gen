import 'package:code_builder/code_builder.dart';
import 'package:niskala_service_gen/src/core/logger.dart';
import 'package:niskala_service_gen/src/models/builders/generated_file_model.dart';
import 'package:niskala_service_gen/src/models/builders/niskala_config.dart';
import 'package:niskala_service_gen/src/models/openapi/openapi_model.dart';
import 'package:niskala_service_gen/src/util/model_finder.dart';
import 'package:niskala_service_gen/src/util/path_parser.dart';
import 'package:niskala_service_gen/src/util/template_engine.dart';
import 'package:niskala_service_gen/src/util/templates/controller_template.dart';
import 'package:niskala_service_gen/src/util/templates/filter_builder_template.dart';
import 'package:niskala_service_gen/src/util/templates/providers_template.dart';
import 'package:niskala_service_gen/src/util/type_mapper.dart';
import 'package:path/path.dart' as p;

/// A generator that creates Dart service classes from OpenAPI specifications.
class ServiceGenerator {
  /// Creates a [ServiceGenerator] with the given [config] and optional [modelMap].
  ServiceGenerator(this.config, {this.modelMap = const {}})
    : mapper = TypeMapper(modelMap),
      parser = PathParser(TypeMapper(modelMap)),
      engine = TemplateEngine(TypeMapper(modelMap)),
      _controllerTemplate = ControllerTemplate(),
      _filterBuilderTemplate = FilterBuilderTemplate(),
      _providersTemplate = ProvidersTemplate();

  /// The configuration containing project details and API definitions.
  final NiskalaConfig config;

  /// A map of discovered model class names to their absolute file paths.
  final Map<String, String> modelMap;

  /// The localized type mapper.
  final TypeMapper mapper;

  /// The API path parser.
  final PathParser parser;

  /// The code template engine.
  final TemplateEngine engine;

  /// Template for controller generation.
  final ControllerTemplate _controllerTemplate;

  /// Template for filter builder generation.
  final FilterBuilderTemplate _filterBuilderTemplate;

  /// Template for unified providers.
  final ProvidersTemplate _providersTemplate;

  /// Generates all service files based on the project configuration.
  List<GeneratedFileModel> generateAll(List<OpenApiModel> openApiModels) {
    final generatedFiles = <GeneratedFileModel>[
      ..._generateApiClient(),
      ..._generateODataQuery(),
      ..._generateFilterBuilder(),
    ];

    // Track service names for unified providers
    final allServiceNames = <String>[];
    final allServiceFileNames = <String>[];

    // Group endpoints by their generated service name to avoid overwriting files
    final groupedEndpoints = <String, List<EndpointModel>>{};
    for (final endpoint in config.endpoints) {
      final fileName = '${mapper.toSnakeCase(endpoint.name)}_service';
      groupedEndpoints.putIfAbsent(fileName, () => []).add(endpoint);
    }

    for (final entry in groupedEndpoints.entries) {
      final fileName = entry.key;
      final endpoints = entry.value;

      final model = _findMatchingModel(endpoints.first, openApiModels);
      if (model != null) {
        final entityName = mapper.toPascalCase(endpoints.first.name);
        final serviceName = '${entityName}Service';
        allServiceNames.add(serviceName);
        allServiceFileNames.add(fileName);

        generatedFiles.addAll(
          _generateServiceGroup(endpoints, model, fileName),
        );
      }
    }

    // Phase 3: Unified providers (replaces per-service .riverpod.dart)
    if (config.packageName != null && allServiceNames.isNotEmpty) {
      generatedFiles.addAll(
        _generateUnifiedProviders(allServiceNames, allServiceFileNames),
      );
    }

    return generatedFiles;
  }

  OpenApiModel? _findMatchingModel(
    EndpointModel endpoint,
    List<OpenApiModel> openApiModels,
  ) {
    final projName = endpoint.projection.replaceAll('.svc', '').toLowerCase();
    for (final model in openApiModels) {
      if (model.info.title.toLowerCase().contains(projName) ||
          model.paths.keys.any(
            (path) => path.toLowerCase().contains(projName),
          )) {
        return model;
      }
    }
    return openApiModels.isNotEmpty ? openApiModels.first : null;
  }

  List<GeneratedFileModel> _generateServiceGroup(
    List<EndpointModel> endpoints,
    OpenApiModel model,
    String fileName,
  ) {
    final entityName = mapper.toPascalCase(endpoints.first.name);
    final serviceName = '${entityName}Service';

    final usedModels = <String>{};
    final methods = _generateStrictMethods(endpoints, model, usedModels);

    // Filter usedModels to only those actually present in the method signatures
    final emitter = DartEmitter();
    final allMethodCode = methods
        .map((m) => m.accept(emitter).toString())
        .join('\n');
    final usedModelsRegex = RegExp(
      '\\b(${usedModels.map(RegExp.escape).join('|')})\\b',
    );
    usedModels.retainWhere((model) {
      if (model == 'ErrorModel') return true;
      return usedModelsRegex.hasMatch(allMethodCode);
    });

    final serviceUserFile = p.absolute(
      p.join(config.baseDirectory, 'service', 'api', '$fileName.dart'),
    );

    final resolvedImports = <String, String>{};
    for (final modelName in usedModels) {
      if (modelName == 'void' || modelName == 'dynamic') continue;
      final matchedKey = mapper.findBestModelMatch(modelName);
      final modelPath = modelMap[matchedKey];
      if (modelPath != null) {
        if (config.packageName != null) {
          logger.fine(
            'Resolving package import for $modelName. Path: $modelPath, Base: ${config.baseDirectory}',
          );
          resolvedImports[modelName] = ModelFinder.getPackageImport(
            modelPath,
            config.packageName!,
            config.baseDirectory, // Reverted p.dirname change
          );
        } else {
          logger.fine(
            'Resolving relative import for $modelName. Path: $modelPath, From: $serviceUserFile',
          );
          resolvedImports[modelName] = ModelFinder.getRelativeImport(
            serviceUserFile,
            modelPath,
          );
        }
      }
    }

    // Calculate ApiClient import
    final String apiClientImport;
    if (config.packageName != null) {
      final apiClientPath = p.absolute(
        p.join(config.baseDirectory, 'service', 'api', 'api_client.dart'),
      );
      final importPath = ModelFinder.getPackageImport(
        apiClientPath,
        config.packageName!,
        config.baseDirectory, // Reverted p.dirname change
      );
      apiClientImport = "import '$importPath';";
    } else {
      apiClientImport = "import 'api_client.dart';";
    }

    final projection = endpoints.first.projection;
    final entitySet = endpoints.first.endpoint.replaceAll('/', '');

    final generatedContent = engine.generateServiceBase(
      methods: methods,
      serviceName: serviceName,
      fileName: fileName,
      usedModels: usedModels,
      resolvedImports: resolvedImports,
      projection: projection,
      entitySet: entitySet,
    );

    final userContent = engine.generateServiceUser(
      serviceName: serviceName,
      fileName: fileName,
      usedModels: usedModels,
      resolvedImports: resolvedImports,
      apiClientImport: apiClientImport,
      packageName: config.packageName,
    );

    final serviceFiles = [
      GeneratedFileModel(
        fileName: '$fileName.niskala.dart',
        content: generatedContent,
        type: FileType.serviceBase,
        subDir: p.join('service', 'api'),
      ),
      GeneratedFileModel(
        fileName: '$fileName.dart',
        content: userContent,
        type: FileType.service,
        isCustom: true,
        subDir: p.join('service', 'api'),
      ),
    ];

    if (config.packageName != null) {
      // Service test
      serviceFiles.add(
        GeneratedFileModel(
          fileName: '${fileName}_test.dart',
          content: engine.generateServiceTest(
            serviceName: serviceName,
            fileName: fileName,
            usedModels: usedModels,
            resolvedImports: resolvedImports,
            packageName: config.packageName!,
            methodNames: methods.map((m) => m.name!).toSet(),
          ),
          type: FileType.test,
          subDir: p.join('test', 'service', 'api'),
        ),
      );

      // Phase 1: Controller generation
      final controllerFileName = '${mapper.toSnakeCase(entityName)}_controller';
      // Find the primary model name from usedModels
      final primaryModel = usedModels.firstWhere(
        (m) => m.contains(entityName) && m.endsWith('Model'),
        orElse: () => '${entityName}Model',
      );
      // Find the primary search key by inspecting the schema properties
      String searchKey = '${entityName}No';
      final schema = model.components?.schemas[entityName];
      if (schema != null && schema.properties.isNotEmpty) {
        final props = schema.properties.keys.toList();
        // Priority 1: Exact matches for "No" or "Id" in the property names
        final guess = props.firstWhere(
          (p) => p.endsWith('No') || p.endsWith('Id'),
          orElse: () => searchKey,
        );
        searchKey = guess;
      }

      serviceFiles
        ..add(
          GeneratedFileModel(
            fileName: '$controllerFileName.dart',
            content: _controllerTemplate.generate(
              serviceName: serviceName,
              entityName: entityName,
              modelName: primaryModel,
              searchKey: searchKey,
              fileName: controllerFileName,
              packageName: config.packageName!,
              serviceFileName: fileName,
              resolvedImports: [
                if (resolvedImports.containsKey(primaryModel))
                  "import '${resolvedImports[primaryModel]}';",
              ],
            ),
            type: FileType.service,
            subDir: 'controllers',
          ),
        )
        ..add(
          GeneratedFileModel(
            fileName: '${controllerFileName}_test.dart',
            content: _controllerTemplate.generateTest(
              serviceName: serviceName,
              entityName: entityName,
              modelName: primaryModel,
              fileName: controllerFileName,
              packageName: config.packageName!,
              serviceFileName: fileName,
              resolvedImports: resolvedImports.values
                  .map((v) => <String>["import '", v, "';"].join())
                  .toList(),
            ),
            type: FileType.test,
            subDir: p.join('test', 'controllers'),
          ),
        );
    }

    return serviceFiles;
  }

  List<Method> _generateStrictMethods(
    List<EndpointModel> endpoints,
    OpenApiModel model,
    Set<String> usedModels,
  ) {
    final methods = <Method>[];
    final usedNames = <String>{};

    for (final endpoint in endpoints) {
      final parsed = parser.parseEndpoint(
        endpoint: endpoint,
        model: model,
        usedNames: usedNames,
      );

      final entityBaseName = endpoint.name;
      final defaultModelName = '${mapper.toPascalCase(entityBaseName)}Model';

      // Find specific request body model if applicable
      var bodyModel = defaultModelName;
      final operation = parsed.operation;
      if (operation != null) {
        final requestBody = operation.requestBody;
        if (requestBody != null) {
          final schemaRef = requestBody.ref ?? requestBody.schema?.ref;
          if (schemaRef != null) {
            final schemaName = schemaRef.split('/').last;
            bodyModel = mapper.findBestModelMatch(
              '${mapper.toPascalCase(schemaName)}Model',
            );
          }
        }
      }

      // Find specific response model if applicable
      var responseModel = defaultModelName;
      if (operation != null) {
        final successResponse =
            operation.responses['200'] ?? operation.responses['201'];
        final responseRef =
            successResponse?.ref ?? successResponse?.schema?.ref;
        if (responseRef != null) {
          final schemaName = responseRef.split('/').last;
          responseModel = mapper.findBestModelMatch(
            '${mapper.toPascalCase(schemaName)}Model',
          );
        }
      }

      // Track models for imports
      usedModels.add(defaultModelName);
      if (bodyModel != defaultModelName) {
        usedModels.add(bodyModel);
      }
      if (responseModel != defaultModelName) {
        usedModels.add(responseModel);
      }
      usedModels.add('ErrorModel');

      // Determine method type (CRUD or API)
      final name = parsed.methodName;
      if (name == 'getAll' ||
          name == 'create' ||
          name == 'getByKey' ||
          name == 'update' ||
          name == 'delete') {
        final String finalReturnType;
        if (name == 'getAll') {
          if (responseModel != defaultModelName &&
              !responseModel.contains('ArrayResponse')) {
            finalReturnType = responseModel;
          } else {
            finalReturnType = 'List<$defaultModelName>';
          }
        } else if (name == 'delete') {
          finalReturnType = 'void';
        } else {
          finalReturnType = responseModel;
        }

        methods.add(
          engine.createCrudMethod(
            name: name,
            method: parsed.httpMethod,
            path: parsed.path,
            returnType: finalReturnType,
            projection: endpoint.projection,
            hasKey: parsed.path.contains('('),
            hasBody:
                parsed.httpMethod == 'post' ||
                parsed.httpMethod == 'patch' ||
                parsed.httpMethod == 'put',
            bodyModel: bodyModel,
            isList: name == 'getAll' && finalReturnType.startsWith('List<'),
          ),
        );
      } else {
        methods.add(
          engine.createApiMethod(
            name: name,
            method: parsed.httpMethod,
            path: parsed.path,
            returnType: 'dynamic',
            projection: endpoint.projection,
          ),
        );
      }
    }

    return methods;
  }

  /// Generates the ApiClient and its base class.
  List<GeneratedFileModel> _generateApiClient() {
    const fileName = 'api_client';

    final apiClientPath = p.absolute(
      p.join(config.baseDirectory, 'service', 'api', 'api_client.dart'),
    );
    final modelsToImport = ['ErrorModel', 'ErrorDetailModel'];
    final imports = <String>{};

    for (final modelName in modelsToImport) {
      final matchedKey = mapper.findBestModelMatch(modelName);
      if (modelMap.containsKey(matchedKey)) {
        final targetPath = p.absolute(modelMap[matchedKey]!);
        final relativePath = config.packageName != null
            ? ModelFinder.getPackageImport(
                targetPath,
                config.packageName!,
                config.baseDirectory, // Reverted p.dirname change
              )
            : ModelFinder.getRelativeImport(apiClientPath, targetPath);
        imports.add("import '$relativePath';");
      }
    }
    final errorModelImport = imports.toList()..sort();
    final errorModelImportString = errorModelImport.join('\n');

    final baseClientContent = engine.generateApiClientBase(
      errorModelImportString,
      config.environments,
    );

    final userClientContent = engine.generateApiClientUser(
      errorModelImportString,
    );

    return [
      GeneratedFileModel(
        fileName: '$fileName.niskala.dart',
        content: baseClientContent,
        type: FileType.serviceBase,
        subDir: p.join('service', 'api'),
      ),
      GeneratedFileModel(
        fileName: '$fileName.dart',
        content: userClientContent,
        type: FileType.service,
        isCustom: true,
        subDir: p.join('service', 'api'),
      ),
    ];
  }

  /// Generates the ODataQuery utility.
  List<GeneratedFileModel> _generateODataQuery() {
    return [
      GeneratedFileModel(
        fileName: 'odata_query.dart',
        content: engine.generateODataQuery(),
        type: FileType.service,
        subDir: p.join('service', 'api'),
      ),
    ];
  }

  /// Generates the OData filter builder utility.
  List<GeneratedFileModel> _generateFilterBuilder() {
    return [
      GeneratedFileModel(
        fileName: 'odata_filter_builder.dart',
        content: _filterBuilderTemplate.generate(),
        type: FileType.service,
        subDir: p.join('service', 'api'),
      ),
    ];
  }

  /// Generates the unified providers hub.
  List<GeneratedFileModel> _generateUnifiedProviders(
    List<String> serviceNames,
    List<String> serviceFileNames,
  ) {
    return [
      GeneratedFileModel(
        fileName: 'providers.dart',
        content: _providersTemplate.generate(
          packageName: config.packageName!,
          serviceNames: serviceNames,
          serviceFileNames: serviceFileNames,
        ),
        type: FileType.service,
        subDir: 'service',
      ),
    ];
  }
}
