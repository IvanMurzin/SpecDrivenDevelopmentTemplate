# Client configuration

For the user-facing setup walk-through see
[`../configuration/flavors.md`](../configuration/flavors.md). This
file is the developer view.

## How values flow

```
.config.<flavor>.json   →   --dart-define-from-file=...   →   AppConfig.init()
                                                                │
                                            const String/bool.fromEnvironment(...)
                                                                │
                                                         AppConfig.instance.x
```

- Required keys (must be set or app won't boot): `ENV`, `FLAVOR`,
  `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`.
- Feature flags: `ENABLE_FIREBASE`, `ENABLE_REVENUECAT`,
  `LOG_API_RESPONSES`. Defaults are `false` so the template runs
  without any external account.
- Add a new key:
  1. Add it to `.config.dev.json.example` and
     `.config.prod.json.example` with a placeholder.
  2. Read it in `AppConfig._fromEnvironment()`.
  3. Document it in `../configuration/env_and_configs.md`.

## Per-flavor quirks

- `dev` flavor's bundle id has `.dev` suffix; display name has `(dev)`.
  Both are set in Android `build.gradle.kts` and iOS
  `Flavor-{dev,prod}.xcconfig`.
- `prod` is the build that goes to the stores.

## Build commands

```bash
flutter run --flavor dev --dart-define-from-file=../.config.dev.json
flutter build apk --flavor prod --release --dart-define-from-file=../.config.prod.json
flutter build appbundle --flavor prod --release --dart-define-from-file=../.config.prod.json
flutter build ios --flavor prod --release --dart-define-from-file=../.config.prod.json
```
