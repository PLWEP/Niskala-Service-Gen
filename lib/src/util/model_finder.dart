import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:niskala_service_gen/src/core/logger.dart';
import 'package:path/path.dart' as p;

/// A utility to find Dart model classes and their corresponding file paths.
class ModelFinder {
  /// Scans the given [directory] recursively for Dart files and extracts
  /// class names.
  static Future<Map<String, String>> findModels(String directory) async {
    final modelMap = <String, String>{};
    final dir = Directory(directory);

    if (!dir.existsSync()) return modelMap;

    final files = dir.listSync(recursive: true).whereType<File>();

    for (final file in files) {
      if (p.extension(file.path) == '.dart' &&
          !file.path.endsWith('.niskala.dart')) {
        try {
          final result = parseString(content: file.readAsStringSync());
          for (final declaration in result.unit.declarations) {
            if (declaration is ClassDeclaration) {
              // ignore: deprecated_member_use
              final className = declaration.name.lexeme;
              if (className.endsWith('Model')) {
                // Ensure we store the absolute path for consistent calculation
                modelMap[className] = p.absolute(file.path);
              }
            }
          }
        } catch (e) {
          logger.warning('Failed to parse model file ${file.path}: $e');
          continue;
        }
      }
    }

    return modelMap;
  }

  /// Calculates the relative import path from [fromPath] to [targetPath].
  static String getRelativeImport(String fromPath, String targetPath) {
    // Ensure both paths are absolute for consistent calculation
    final absFrom = p.absolute(fromPath);
    final absTarget = p.absolute(targetPath);

    final fromDir = p.dirname(absFrom);
    var relative = p.relative(absTarget, from: fromDir);

    // Normalize to use forward slashes for cross-platform compatibility in Dart imports
    relative = relative.replaceAll(r'\', '/');

    // Ensure it starts with ./ or ../
    if (!relative.startsWith('.')) {
      relative = './$relative';
    }

    // Remove any redundant occurrences of /./ or /../
    return relative.replaceAll('/./', '/');
  }

  /// Calculates the absolute package import from [absPath].
  static String getPackageImport(
    String absPath,
    String packageName,
    String baseDir,
  ) {
    var relative = p.relative(absPath, from: p.absolute(baseDir));
    relative = relative.replaceAll(r'\', '/');

    // Remove leading ./ if present
    if (relative.startsWith('./')) {
      relative = relative.substring(2);
    }

    return 'package:$packageName/$relative';
  }
}
