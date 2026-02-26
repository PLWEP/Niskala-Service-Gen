# Riverpod Integration

Generate Riverpod providers automatically for your services.

## Automatically Generated

When `packageName` is detected in `pubspec.yaml`, the generator creates:

- `api_client_provider.dart` (Shared ApiClient)
- `[service_name].riverpod.dart` (Service Provider)

## Usage

```dart
final service = ref.watch(purchaseRequisitionServiceProvider);
final data = await service.getAll();
```

## FutureProviders

The generator also scaffolds example `FutureProvider`s for collection endpoints (`getAll`).
