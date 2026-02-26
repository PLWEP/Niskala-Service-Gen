import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';

/// Global logger instance for the Niskala Service Gen package.
final Logger logger = Logger('NiskalaServiceGen');

StreamSubscription<LogRecord>? _loggerSubscription;

/// Configures the global logging behavior for the application.
void setupLogger({bool verbose = false}) {
  Logger.root.level = verbose ? Level.ALL : Level.INFO;

  _loggerSubscription?.cancel();

  _loggerSubscription = Logger.root.onRecord.listen((record) {
    if (record.level >= Level.SEVERE) {
      stderr.writeln('✖ [${record.level.name}] ${record.message}');
      if (record.error != null) stderr.writeln('  Error: ${record.error}');
      if (record.stackTrace != null) stderr.writeln(record.stackTrace);
    } else if (record.level >= Level.WARNING) {
      stdout.writeln('⚠ [${record.level.name}] ${record.message}');
    } else if (record.level >= Level.INFO) {
      stdout.writeln('• ${record.message}');
    } else if (verbose) {
      stdout.writeln(
        '  [${record.level.name.toLowerCase()}] ${record.message}',
      );
    }
  });
}
