# Resilience Patterns

Professional-grade resilience for your API integrations.

## Retries

Automatic exponential backoff for:

- Connection timeouts
- Server errors (5xx)
- Request timeouts

## Response Hooks

Override `transformResponse` in `ApiClient` to apply global data transformations or logging.

```dart
class MyApiClient extends ApiClient {
  @override
  dynamic transformResponse(dynamic data) {
    // Global filter or mapping
    return super.transformResponse(data);
  }
}
```

## Caching

Placeholders for `_CachingInterceptor` are included in the `ApiClient` base class, ready for Hive or Isar integration.
