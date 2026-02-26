import 'package:niskala_service_gen/src/core/logger.dart';

/// Utility to merge generated code with existing custom code using markers.
class CodeMerger {
  /// The marker used to identify the custom code section.
  static const customLogicMarker = '// Custom logic here';

  /// Merges [newContent] into [existingContent] by preserving code after the marker.
  static String merge(String existingContent, String newContent) {
    if (!existingContent.contains(customLogicMarker)) {
      logger.warning(
        'Marker "$customLogicMarker" not found in existing file. Performing baseline upgrade.',
      );
      return newContent;
    }

    final existingLines = existingContent.split('\n');
    final newLines = newContent.split('\n');

    final existingMarkerIndex = existingLines.indexWhere(
      (l) => l.contains(customLogicMarker),
    );
    final newMarkerIndex = newLines.indexWhere(
      (l) => l.contains(customLogicMarker),
    );

    if (newMarkerIndex == -1) {
      logger.severe('New content is missing the marker. Cannot merge safely.');
      return existingContent;
    }

    final customPartCode = existingLines
        .sublist(existingMarkerIndex + 1)
        .join('\n');

    // 1. Identify what's in the NEW content first
    final newImportsMatchedKeys = <String>{};
    for (final line in newLines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ')) {
        final matchKey = _getMatchKey(trimmed);
        if (matchKey != null) {
          newImportsMatchedKeys.add(matchKey);
        }
      }
    }

    final normalizedToOriginal = <String, String>{};

    for (final line in [...newLines, ...existingLines]) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ')) {
        final matchKey = _getMatchKey(trimmed);
        if (matchKey == null) continue;

        // If this is from existing content but NOT in new content
        final isFromExisting = !newLines.any((l) => l.trim() == trimmed);
        if (isFromExisting && !newImportsMatchedKeys.contains(matchKey)) {
          // It's a candidate for removal.
          // Check if it's a Niskala model/expansion/enum import
          final isModelImport =
              matchKey.contains('entities/') ||
              matchKey.contains('responses/') ||
              matchKey.contains('expansions/') ||
              matchKey.contains('enums/') ||
              matchKey.contains('requests/');

          if (isModelImport) {
            // Only keep if it's used in the custom code part
            final fileName = matchKey.split('/').last.replaceAll('.dart', '');
            final className = fileName.split('_').map((s) {
              if (s.isEmpty) return '';
              return s[0].toUpperCase() + s.substring(1);
            }).join();

            if (!customPartCode.contains(className)) {
              continue; // Drop stale model import
            }
          }
        }

        if (!normalizedToOriginal.containsKey(matchKey)) {
          normalizedToOriginal[matchKey] = trimmed;
        } else {
          // Prioritize new content imports over existing ones to allow path updates
          final isFromNew = newLines.any((l) => l.trim() == trimmed);
          if (isFromNew) {
            normalizedToOriginal[matchKey] = trimmed;
          } else if (!normalizedToOriginal[matchKey]!.contains('package:') &&
              trimmed.contains('package:')) {
            // Still prioritize package: over relative if both exist (fallback)
            normalizedToOriginal[matchKey] = trimmed;
          }
        }
      }
    }

    final sortedImports = normalizedToOriginal.values.toList()
      ..sort((a, b) {
        final aTrim = a.trim();
        final bTrim = b.trim();

        // dart: imports first
        if (aTrim.contains("'dart:") || aTrim.contains('"dart:')) {
          if (!(bTrim.contains("'dart:") || bTrim.contains('"dart:'))) {
            return -1;
          }
        } else if (bTrim.contains("'dart:") || bTrim.contains('"dart:')) {
          return 1;
        }

        // package: imports second
        if (aTrim.contains("'package:") || aTrim.contains('"package:')) {
          if (!(bTrim.contains("'package:") || bTrim.contains('"package:'))) {
            return -1;
          }
        } else if (bTrim.contains("'package:") || bTrim.contains('"package:')) {
          return 1;
        }

        return aTrim.compareTo(bTrim);
      });

    // 4. Assemble the result
    final result = <String>[
      ...sortedImports,
      if (sortedImports.isNotEmpty) '',
      ...newLines
          .sublist(0, newMarkerIndex + 1)
          .where((l) => !l.trim().startsWith('import ')),
      ...existingLines.sublist(existingMarkerIndex + 1),
    ];

    return result.join('\n');
  }

  static String? _getMatchKey(String importLine) {
    var path = importLine.replaceAll('import ', '').replaceAll(';', '').trim();
    if (path.startsWith("'") || path.startsWith('"')) {
      path = path.substring(1, path.length - 1);
    }

    // Remove leading relative markers
    if (path.startsWith('./')) path = path.substring(2);
    while (path.startsWith('../')) {
      path = path.substring(3);
    }

    if (path.contains('/')) {
      final parts = path.split('/');
      final fileName = parts.last;

      // If it looks like a Niskala model, use filename as key to handle path transitions
      if (fileName.endsWith('_model.dart') ||
          fileName.endsWith('_model.niskala.dart')) {
        return fileName;
      }

      if (parts.first.contains(':') && parts.length > 1) {
        // For other package imports, use everything AFTER the package name
        return parts.sublist(1).join('/');
      }
      return path;
    }
    return path;
  }
}
