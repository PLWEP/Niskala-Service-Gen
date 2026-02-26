# OData Queries

Niskala Service Gen v1.4.0 introduces a type-safe `ODataQuery` builder.

## Usage

```dart
final query = ODataQuery()
  .filter("name eq 'John'")
  .expand(['Orders', 'Profile'])
  .orderBy('createdAt', descending: true)
  .top(10);

final result = await service.getAll(query: query);
```

## Supported Operations

- `filter(String condition)`: Adds `$filter`.
- `expand(List<String> props)`: Adds `$expand`.
- `select(List<String> props)`: Adds `$select`.
- `orderBy(String prop, {bool descending})`: Adds `$orderby`.
- `top(int value)`: Adds `$top`.
- `skip(int value)`: Adds `$skip`.
