import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Represents the section `niskala_service_gen` in the YAML configuration.
class GenSectionConfig {
  /// Creates a [GenSectionConfig] instance.
  GenSectionConfig({this.resourcePath, this.output});

  /// Factory constructor to create a [GenSectionConfig] from a YAML map.
  factory GenSectionConfig.fromYaml(YamlMap map) {
    return GenSectionConfig(
      resourcePath: map['resource_path']?.toString(),
      output: map['output']?.toString(),
    );
  }

  /// The path to the directory containing OpenAPI JSON metadata files.
  String? resourcePath;

  /// The root directory where generated code will be written.
  String? output;
}

/// Represents an API definition (endpoint) in the configuration.
class EndpointModel {
  /// Creates an [EndpointModel] instance.
  EndpointModel({
    required this.projection,
    required this.method,
    required this.endpoint,
  });

  /// Factory constructor to create an [EndpointModel] from a YAML map.
  factory EndpointModel.fromYaml(YamlMap map) {
    return EndpointModel(
      projection: map['projection']?.toString() ?? '',
      method: map['method']?.toString() ?? 'GET',
      endpoint: map['endpoint']?.toString() ?? '',
    );
  }

  /// The OData projection name (e.g., 'PurchaseRequisitionHandling.svc').
  final String projection;

  /// The HTTP method for the endpoint.
  final String method;

  /// The endpoint path (e.g., '/PurchaseRequisitionSet').
  final String endpoint;

  /// Convenience getter for the service name derived from endpoint.
  String get name {
    var s = endpoint.replaceAll('/', '');
    if (s.endsWith('Set')) {
      s = s.substring(0, s.length - 3);
    } else if (s.endsWith('Entities')) {
      s = s.substring(0, s.length - 8);
    }
    return s;
  }
}

/// Represents an OData environment configuration.
class ODataEnvironmentModel {
  /// Creates an [ODataEnvironmentModel] instance.
  ODataEnvironmentModel({
    required this.name,
    required this.baseUrl,
    required this.realms,
    required this.clientId,
    required this.clientSecret,
  });

  /// Factory constructor to create an [ODataEnvironmentModel] from a YAML map.
  factory ODataEnvironmentModel.fromYaml(YamlMap map) {
    return ODataEnvironmentModel(
      name: map['name']?.toString() ?? '',
      baseUrl: map['baseUrl']?.toString() ?? '',
      realms: map['realms']?.toString() ?? '',
      clientId: map['clientId']?.toString() ?? '',
      clientSecret: map['clientSecret']?.toString() ?? '',
    );
  }

  /// The environment name (e.g., 'Development').
  final String name;

  /// The base URL for the IFS environment.
  final String baseUrl;

  /// The OIDC realms.
  final String realms;

  /// The OIDC client ID.
  final String clientId;

  /// The OIDC client secret.
  final String clientSecret;
}

/// Represents the configuration model for Niskala Service Gen.
class NiskalaConfig {
  /// Creates a [NiskalaConfig] instance.
  NiskalaConfig({
    required this.endpoints,
    required this.configDir,
    this.genConfig,
    this.environments = const [],
    this.packageName,
  });

  /// Factory constructor to create a [NiskalaConfig] from a YAML map.
  factory NiskalaConfig.fromYaml(
    YamlMap map, {
    String? configDir,
    String? packageName,
  }) {
    final endpointsList = <EndpointModel>[];
    if (map.containsKey('apiDefinitions') &&
        map['apiDefinitions'] is YamlList) {
      final definitions = map['apiDefinitions'] as YamlList;
      for (final def in definitions) {
        if (def is YamlMap) {
          endpointsList.add(EndpointModel.fromYaml(def));
        }
      }
    }

    final envList = <ODataEnvironmentModel>[];
    if (map.containsKey('odataEnvironments') &&
        map['odataEnvironments'] is YamlList) {
      final envs = map['odataEnvironments'] as YamlList;
      for (final env in envs) {
        if (env is YamlMap) {
          envList.add(ODataEnvironmentModel.fromYaml(env));
        }
      }
    }

    // 2. Niskala Gen Config (unified)
    GenSectionConfig? genConfig;
    if (map.containsKey('niskala_gen') && map['niskala_gen'] is YamlMap) {
      genConfig = GenSectionConfig.fromYaml(map['niskala_gen'] as YamlMap);
    } else if (map.containsKey('niskala_service_gen') &&
        map['niskala_service_gen'] is YamlMap) {
      // Fallback for backward compatibility
      genConfig = GenSectionConfig.fromYaml(
        map['niskala_service_gen'] as YamlMap,
      );
    }

    return NiskalaConfig(
      endpoints: endpointsList,
      genConfig: genConfig,
      environments: envList,
      configDir: configDir ?? '.',
      packageName: packageName,
    );
  }

  /// The name of the package for absolute imports.
  final String? packageName;

  /// The directory where the configuration file is located.
  final String configDir;

  /// A list of API endpoints defined in the configuration.
  final List<EndpointModel> endpoints;

  /// The generator-specific configuration section.
  final GenSectionConfig? genConfig;

  /// A list of OData environments.
  final List<ODataEnvironmentModel> environments;

  /// The base directory for all outputs (defaults to 'lib').
  String get baseDirectory => p.join(configDir, genConfig?.output ?? 'lib');

  /// The target directory for generated services.
  String get outputDirectory => p.join(baseDirectory, 'service', 'api');

  /// Convenience getter for the resource path.
  String? get resourcePath {
    final path = genConfig?.resourcePath;
    if (path == null) return null;
    if (p.isAbsolute(path)) return path;
    return p.join(configDir, path);
  }
}
