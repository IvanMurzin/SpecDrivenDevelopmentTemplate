# Integrations

All external services are **prepared but disabled by default**. Flip
them on via config flags after providing real credentials.

## Firebase Analytics + Crashlytics

- Disabled when `ENABLE_FIREBASE=false` (the template default).
- `FirebaseInitializer.init()` returns immediately when disabled —
  the app boots without `google-services.json` /
  `GoogleService-Info.plist`.
- To enable:
  1. Add `client/android/app/google-services.json` (from Firebase Console).
  2. Add `client/ios/Runner/GoogleService-Info.plist`.
  3. Set `ENABLE_FIREBASE=true` in `.config.<flavor>.json`.
  4. Rebuild.

`AppAnalytics` is a thin façade. When Firebase is off (or the build
isn't release-mode), events are logged to stdout via `logger` for
local debugging.

## RevenueCat

- Disabled when `ENABLE_REVENUECAT=false` (the template default).
- DI provides a `NoopRevenueCatService` that returns `null` for every
  call. Feature code can always `getIt<RevenueCatService>()` without
  null-checking.
- To enable:
  1. Replace `rcat_placeholder_*` in `.config.<flavor>.json` with real
     keys.
  2. Set `ENABLE_REVENUECAT=true`.
  3. Rebuild.

When enabled with placeholder keys, `RevenueCatInitializer` logs a
warning so the misconfiguration is visible.

## Supabase

- Required. The app refuses to start without `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` set in `.config.<flavor>.json`.
- One backend per project; `dev` and `prod` flavors point at the same
  project. Use Supabase Auth to scope test data, not separate
  backends.

## Other external services

For anything else (push, in-app messaging, attribution), follow the
pattern: prepared abstraction + no-op default + config flag.
