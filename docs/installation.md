# Installation

To install **Niskala Service Gen**, add it and its dependencies to your `pubspec.yaml`:

```yaml
dependencies:
    dio: ^5.0.0
    riverpod: ^2.0.0 # Optional, for Track 5 features

dev_dependencies:
    niskala_service_gen: ^1.4.0
    build_runner: ^2.4.0
```

Then run:

```bash
dart pub get
```

## First Initialization

Use the new CLI tool to scaffold your configuration:

```bash
dart run niskala_service_gen init
```

This will create a default `niskala.yaml` in your project root.
