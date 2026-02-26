import 'dart:io';
import 'package:niskala_service_gen/src/core/exceptions.dart';
import 'package:niskala_service_gen/src/core/logger.dart';
import 'package:niskala_service_gen/src/models/builders/niskala_config.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A utility class for loading and parsing the generator configuration.
class ConfigLoader {
  /// The default name of the configuration file.
  static const String defaultConfigName = 'niskala.yaml';

  /// Loads the configuration for Niskala Service Gen.
  static Future<NiskalaConfig> loadConfig({String? cliConfigPath}) async {
    final configPath = cliConfigPath ?? defaultConfigName;
    logger.info('Using configuration file: $configPath');

    final configFile = File(configPath);
    if (!configFile.existsSync()) {
      throw ConfigException(
        'Configuration file not found: $configPath. Please ensure you are running this command from the root of your project or specify the config file path using -c.',
      );
    }

    try {
      final yamlString = await configFile.readAsString();
      final yamlMap = loadYaml(yamlString) as YamlMap;
      final configDir = p.dirname(configFile.absolute.path);

      // Search for pubspec.yaml to get the package name
      String? packageName;
      var currentDir = configDir;
      while (true) {
        final pubspecFile = File(p.join(currentDir, 'pubspec.yaml'));
        if (pubspecFile.existsSync()) {
          try {
            final pubspecYaml =
                loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
            packageName = pubspecYaml['name']?.toString();
            break;
          } catch (_) {
            // Ignore parse errors and keep searching
          }
        }
        final parent = p.dirname(currentDir);
        if (parent == currentDir) break;
        currentDir = parent;
      }

      final config = NiskalaConfig.fromYaml(
        yamlMap,
        configDir: configDir,
        packageName: packageName,
      );

      _validateConfig(config);

      return config;
    } catch (e) {
      if (e is ConfigException) rethrow;
      throw ConfigException(
        'Failed to parse configuration file $configPath: $e. Please check your YAML syntax.',
        e,
      );
    }
  }

  static void _validateConfig(NiskalaConfig config) {
    // 1. Check resource_path
    final path = config.resourcePath;
    if (path == null) {
      logger.warning(
        'Configuration warning: resource_path is not defined. Generation might find no metadata.',
      );
    } else if (!Directory(path).existsSync()) {
      logger.warning(
        'Configuration warning: resource_path "$path" does not exist. Generation might find no metadata.',
      );
    }

    // 2. Check for empty apiDefinitions
    if (config.endpoints.isEmpty) {
      logger.warning(
        'Configuration warning: apiDefinitions is empty. No services will be generated.',
      );
    }
  }
}
