# Env vars and config files

Two layers:

1. **Client config**: `.config.<flavor>.json` at repo root, passed via
   `--dart-define-from-file=../.config.<flavor>.json`. Read by
   `AppConfig` in `client/lib/core/config/app_config.dart`.
2. **Backend env**: `.env` at repo root, sourced by
   `backend/scripts/deploy_supabase.sh`.

`.example` versions are committed; the real files are gitignored.

## Client config keys

| Key                   | Type   | Default     | Required | Notes |
| --------------------- | ------ | ----------- | -------- | ----- |
| `ENV`                 | string | —           | yes      | `"dev"` / `"prod"` — labels logs. |
| `FLAVOR`              | string | —           | yes      | Must match the build flavor. |
| `SUPABASE_URL`        | string | —           | yes      | Project URL from Supabase. |
| `SUPABASE_PUBLISHABLE_KEY` | string | —      | yes      | Public publishable key. |
| `OAUTH_REDIRECT_URI`  | string | `""`        | no       | Deep-link URL for Google / Apple sign-in (e.g. `myapp://login-callback/`). Empty disables social sign-in — `IAuthRepository.getAvailableProviders()` returns `[email]` only. |
| `IS_OTP_ENABLED`      | bool   | `false`     | no       | When true, sign-up requires email OTP verification. When false, the user is signed in immediately after sign-up. |
| `ENABLE_FIREBASE`     | bool   | `false`     | no       | Set true after adding `google-services.json` / `GoogleService-Info.plist`. |
| `ENABLE_REVENUECAT`   | bool   | `false`     | no       | Set true after adding real RevenueCat keys. |
| `REVENUECAT_API_KEY_TEST` | string | placeholder | no | RevenueCat **public SDK** test key. Used by `dev` builds when `ENABLE_REVENUECAT=true`. |
| `REVENUECAT_API_KEY_ANDROID` | string | placeholder | no | RevenueCat Android **public SDK** key. Used by Android non-dev builds when `ENABLE_REVENUECAT=true`. |
| `REVENUECAT_API_KEY_IOS` | string | placeholder | no | RevenueCat iOS **public SDK** key. Used by iOS non-dev builds when `ENABLE_REVENUECAT=true`. |
| `LOG_API_RESPONSES`   | bool   | `false`     | no       | Verbose API logging in dev. Avoid in `prod`. |

Add a new key:

1. Add to both `.config.dev.json.example` and `.config.prod.json.example`
   with an obvious placeholder.
2. Add to `_fromEnvironment` in `app_config.dart` and surface a typed
   accessor on `AppConfig`.
3. Document the row above.

## Backend env keys (`.env`)

| Key                          | Used by                                     | Notes |
| ---------------------------- | ------------------------------------------- | ----- |
| `SUPABASE_PROJECT_REF`       | `deploy_supabase.sh`                        | Required for `supabase link`. |
| `SUPABASE_DB_PASSWORD`       | manual psql sessions                        | Optional. |
| `REVENUECAT_API_KEY`         | `revenuecat_webhook`, `/api/revenuecat/refresh` | RevenueCat **server** key (`sk_…`). Different from the client SDK key. Required if subscriptions are enabled. |
| `REVENUECAT_WEBHOOK_SECRET`  | `revenuecat_webhook`                        | Shared secret RevenueCat sends in `Authorization: Bearer <…>`. Configure the same value in RevenueCat → Project → Integrations → Webhook. |
| `REVENUECAT_PRO_ENTITLEMENT` | `revenuecat_webhook`, `/api/revenuecat/refresh` | Single entitlement id that grants the `pro` plan. Defaults to `pro` if neither this nor the multi-value variant is set. |
| `REVENUECAT_PRO_ENTITLEMENTS`| `revenuecat_webhook`, `/api/revenuecat/refresh` | Comma-separated list when more than one entitlement grants `pro` (e.g. `pro,premium`). |

`deploy_supabase.sh` automatically pushes the RevenueCat secrets to
the deployed function when both `REVENUECAT_API_KEY` and
`REVENUECAT_WEBHOOK_SECRET` are set; otherwise the webhook deploy is
skipped. Never echo backend env values to stdout.
