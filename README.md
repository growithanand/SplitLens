# splitlens

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Database code generation

SplitLens uses Drift to generate type-safe SQLite table and row classes. Run
the generator after changing a table definition:

```powershell
dart run build_runner build
```

The generated `app_database.g.dart` file is committed so analysis and builds
do not depend on running code generation first.
