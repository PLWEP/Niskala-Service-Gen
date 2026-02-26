/// Extensions for [String] to handle common naming conversions.
extension StringX on String {
  /// Converts the string to PascalCase.
  String toPascalCase() {
    if (isEmpty) return '';
    return split(RegExp('[-_]'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join();
  }

  /// Converts the string to camelCase.
  String toCamelCase() {
    final pascal = toPascalCase();
    if (pascal.isEmpty) return '';
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  /// Converts the string to snake_case.
  String toSnakeCase() => replaceAllMapped(
    RegExp('([a-z])([A-Z])'),
    (m) => '${m.group(1)}_${m.group(2)}',
  ).toLowerCase();
}
