/// Base class for all Niskala Service Gen specific exceptions.
class NiskalaException implements Exception {
  /// Creates a [NiskalaException] with the given [message] and [originalError].
  NiskalaException(this.message, [this.originalError]);

  /// The error message.
  final String message;

  /// The original error that caused this exception, if any.
  final dynamic originalError;

  @override
  String toString() {
    if (originalError != null) {
      return '$message (Original error: $originalError)';
    }
    return message;
  }
}

/// Thrown when an authentication-related error occurs.
class AuthException extends NiskalaException {
  /// Creates an [AuthException] with the given [message] and [originalError].
  AuthException(super.message, [super.originalError]);
}

/// Thrown when there is an error parsing or fetching metadata.
class MetadataException extends NiskalaException {
  /// Creates a [MetadataException] with the given [message] and [originalError].
  MetadataException(super.message, [super.originalError]);
}

/// Thrown when there is an error in the YAML configuration.
class ConfigException extends NiskalaException {
  /// Creates a [ConfigException] with the given [message] and [originalError].
  ConfigException(super.message, [super.originalError]);
}
