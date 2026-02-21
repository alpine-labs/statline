# Copilot Instructions — statline

Flutter 3 + Dart multi-sport play-by-play stat tracker. Riverpod (code-generated), Drift (SQLite, offline-first), GoRouter.

## Commands

```bash
flutter analyze                                     # Lint
flutter test                                        # All tests
flutter test test/path/to/widget_test.dart          # Single test file
flutter build web --release --no-tree-shake-icons   # Production web build

# Required after changing Drift table definitions or Riverpod providers:
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch   # Watch mode during development
```

## Architecture

```
lib/
├── core/           # Theme, constants, feature flags, utils
├── data/           # Drift DB definition, DAOs, repositories, sync queue
├── domain/         # Models, stat calculator, sport plugin interface + implementations
├── presentation/   # Riverpod providers, GoRouter config, screens, widgets
└── export/         # PDF, CSV, image exporters
```

**Data flow:** Drift DAOs → Repositories → Riverpod providers → UI. Never access DAOs directly from providers or widgets.

**Sport plugin system:** Each sport implements the abstract `SportPlugin` interface in `lib/domain/sports/{sport}/`. Volleyball is complete; other sports are Phase 2. Adding a new sport means creating a new plugin directory — no changes to core app logic.

## Key conventions

- Always run `build_runner` after modifying Drift table schemas or adding/editing Riverpod providers. Generated `.g.dart` files must be committed.
- Game stats and events are stored as JSON columns in SQLite for cross-sport schema flexibility. Deserialize via the sport plugin's methods, not in UI code.
- Riverpod providers are auto-generated with `@riverpod` annotations — don't write provider boilerplate manually.
- CI runs `flutter analyze` → `flutter test` → `flutter build web` → Vercel deploy on every push to `main`. All three must pass before merging.
- Feature flags are in `lib/core/feature_flags.dart` and control phase 2+ sport availability.
