import 'package:dart_style/dart_style.dart';

/// Generates paginated controller code for a service entity set.
class ControllerTemplate {
  /// Formats the given [code] using DartFormatter.
  String format(String code) {
    return DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    ).format(code);
  }

  /// Generates a paginated controller for a service entity set.
  ///
  /// The generated controller extends `AsyncNotifier` with pagination
  /// (`$top`/`$skip`), search, filter, loadMore, and refresh support.
  String generate({
    required String serviceName,
    required String entityName,
    required String modelName,
    required String searchKey,
    required String fileName,
    required String packageName,
    required String serviceFileName,
    required List<String> resolvedImports,
  }) {
    final controllerName = '${entityName}Controller';
    final camelServiceName =
        serviceName[0].toLowerCase() + serviceName.substring(1);
    final providerName = '${camelServiceName}Provider';
    final camelControllerName =
        controllerName[0].toLowerCase() + controllerName.substring(1);
    final listProviderName = '${camelControllerName}Provider';

    final directives = [
      "import 'package:flutter_riverpod/flutter_riverpod.dart';",
      "import 'package:$packageName/service/api/odata_filter_builder.dart';",
      "import 'package:$packageName/service/api/odata_query.dart';",
      "import 'package:$packageName/service/providers.dart';",
      ...resolvedImports,
    ]..sort();

    return format('''
// GENERATED CODE - DO NOT MODIFY BY HAND

${directives.join('\n')}

/// Page size for OData \$top pagination.
const _kPageSize = 10;

/// Controller for managing the list of [$modelName]
/// with server-side OData pagination, search, and filtering.
class $controllerName extends AsyncNotifier<List<$modelName>> {
  int _currentPage = 0;
  bool _hasMore = true;
  String _searchQuery = '';
  List<ODataFilterEntry> _filters = [];

  /// Whether more pages are available.
  bool get hasMore => _hasMore;

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Current active filters.
  List<ODataFilterEntry> get filters => List.unmodifiable(_filters);

  /// Number of active filters.
  int get activeFilterCount => _filters.length;

  @override
  Future<List<$modelName>> build() async {
    _currentPage = 0;
    _hasMore = true;
    return _fetchPage(0);
  }

  /// Sets the search query and re-fetches from server.
  Future<void> setSearch(String query) async {
    _searchQuery = query.trim();
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  /// Sets the active filters and re-fetches from server.
  Future<void> setFilters(List<ODataFilterEntry> filters) async {
    _filters = filters;
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  /// Loads the next page and appends to current list.
  Future<void> loadMore() async {
    if (!_hasMore) return;
    final current = state.valueOrNull ?? [];
    _currentPage++;
    try {
      final next = await _fetchPage(_currentPage);
      state = AsyncValue.data([...current, ...next]);
    } catch (e, st) {
      _currentPage--;
      state = AsyncValue.error(e, st);
    }
  }

  /// Refreshes back to the first page.
  Future<void> refresh() async {
    _currentPage = 0;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  Future<List<$modelName>> _fetchPage(int page) async {
    final service = ref.read($providerName);
    final query = _buildQuery(page);
    final result = await service.getAll(query: query);
    if (result.length < _kPageSize) {
      _hasMore = false;
    }
    return result;
  }

  ODataQuery _buildQuery(int page) {
    final query = ODataQuery()
        .top(_kPageSize)
        .skip(page * _kPageSize);

    final filterParts = <ODataFilterEntry>[..._filters];

    if (_searchQuery.isNotEmpty) {
      filterParts.add(
        ODataFilterEntry(
          odataField: '$searchKey',
          op: ODataFilterOp.contains,
          fieldType: ODataFieldType.string,
          value: _searchQuery,
        ),
      );
    }

    final filterExpr = ODataFilterBuilder.build(filterParts);
    if (filterExpr != null) {
      query.filter(filterExpr);
    }

    return query;
  }
}

/// Provider for the paginated list of [$modelName].
final $listProviderName = AsyncNotifierProvider<
  $controllerName,
  List<$modelName>
>($controllerName.new);
''');
  }

  /// Generates a test file for a generated controller.
  String generateTest({
    required String serviceName,
    required String entityName,
    required String modelName,
    required String fileName,
    required String packageName,
    required String serviceFileName,
    required List<String> resolvedImports,
  }) {
    final controllerName = '${entityName}Controller';
    final controllerFileName = fileName;
    final testClassName = '$controllerName Tests';

    final directives = [
      "import 'package:flutter_test/flutter_test.dart';",
      "import 'package:$packageName/controllers/$controllerFileName.dart';",
    ]..sort();

    return format('''
// GENERATED CODE - DO NOT MODIFY BY HAND

${directives.join('\n')}

void main() {
  group('$testClassName', () {
    test('controller class exists', () {
      expect($controllerName.new, isNotNull);
    });
  });
}
''');
  }
}
