/// A utility class for building type-safe OData query parameters.
class ODataQuery {
  final Map<String, String> _params = {};

  /// Adds a `$filter` condition to the query.
  void filter(String condition) {
    _params[r'$filter'] = condition;
  }

  /// Adds an `$expand` clause to the query.
  void expand(List<String> properties) {
    _params[r'$expand'] = properties.join(',');
  }

  /// Adds a `$select` clause to the query.
  void select(List<String> properties) {
    _params[r'$select'] = properties.join(',');
  }

  /// Adds an `$orderby` clause to the query.
  void orderBy(String property, {bool descending = false}) {
    _params[r'$orderby'] = '$property${descending ? ' desc' : ''}';
  }

  /// Adds a `$top` clause to the query.
  void top(int value) {
    _params[r'$top'] = value.toString();
  }

  /// Adds a `$skip` clause to the query.
  void skip(int value) {
    _params[r'$skip'] = value.toString();
  }

  /// Returns the built query parameters as a map.
  Map<String, String> build() => Map.unmodifiable(_params);
}
