# NoteCash Agent Guidance

## Setup & Development
- Run `flutter pub get` after dependency changes
- Code generation required: `flutter pub run build_runner watch --delete-conflicting-outputs`
  - Generates Isar models (*.g.dart) and Riverpod providers (*.provider.dart)
  - Must run before editing generated files
- Android notification listener requires special permissions (see .trae/rules/app-info.md lines 115-119)

## Architecture
- State: Riverpod (code-generated providers in lib/core/)
- Database: Isar (models in lib/core/models/ with generated adapters)
- Navigation: go_router (lib/core/router.dart)
- Features: lib/features/<name>/ (UI, logic, widgets)
- Services: lib/services/ (business logic, platform integrations)

## Commands
- Build APK: `flutter build apk --release`
- Run tests: `flutter test`
- Analyze: `flutter analyze`
- Format: `dart format lib/ test/`

## Notes
- Expense parsing: Natural language input (e.g., "cf 35k") handled by expense_parser_service
- Home widgets: Implemented via home_widget package (Android/iOS)
- Offline-first: All data stored locally via Isar
- Dark mode: Primary theme (see lib/core/theme.dart)