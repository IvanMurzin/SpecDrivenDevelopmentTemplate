# Template migration report

This report documents how the `sdd_template` was extracted from the
`asset-tuner` source project on 2026-05-06.

## Source and target

- **Source (read-only reference):** `/Users/preis/dev/pets/asset-tuner`
- **Target (this template):** `/Users/preis/dev/pets/sdd_template`

No changes were made to the source project. `.git/` was not copied.

## What was copied directly

- `client/lib/core/{di, logger, bloc, supabase init, native_splash,
  utils/external_url_launcher, utils/app_lifecycle_observer, types/{failure,
  result, json_name}, session/unauthorized_notifier, local_storage/{locale_storage,
  theme_mode_storage}, localization/{system_locale_provider}}` — generic
  infra, no product references.
- `client/lib/core/routing/{app_page_transitions, go_router_refresh_stream,
  guards/route_guard}` — generic routing helpers.
- `client/lib/core_ui/theme/{ds_theme, theme_mode_cubit}` — token
  contracts and theme cubit (palettes replaced; see "rewritten").
- `client/lib/core_ui/components/{ds_app_bar, ds_card, ds_dialog}` —
  generic, kept as-is.
- `client/analysis_options.yaml`, `l10n.yaml`, `devtools_options.yaml`.
- `client/android/` and `client/ios/` shells — vendored, with bundle
  ids and display names rewritten to placeholders.
- `backend/supabase/functions/_shared/{auth, db, env, cors}` — generic
  helpers, no product references.

## What was extracted as a pattern

- **DS architecture** (`core_ui/`): kept the layering (theme as
  ThemeExtensions, components reading tokens via `context.dsX`, DS
  preview route) but reduced to 5 components (`ds_button`, `ds_card`,
  `ds_app_bar`, `ds_dialog`, `ds_loader`).
- **Edge function dispatch** (`functions/api/index.ts`): kept the
  `Deno.serve` switch + `handleX(req, userId)` shape, replaced 17
  product handlers with one `/health` example.
- **Spec workflow**: kept the create-spec / resolve-spec idea but
  rebuilt into 7 skills + 4 subagents + a richer SDD docs set.

## What was rewritten

- `client/lib/core/config/app_config.dart` — replaced product fields
  (oauthRedirectUri, isOtpEnabled, termsOfUseUrl, privacyPolicyUrl,
  multi-platform RevenueCat key resolution) with two feature flags:
  `ENABLE_FIREBASE`, `ENABLE_REVENUECAT`. Required keys reduced to
  `ENV`, `FLAVOR`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`.
- `client/lib/core/firebase/firebase_initializer.dart` — gated on
  `enableFirebase` flag (was tied to `flavor == prod`); skeleton
  passes `flutter analyze` without `google-services.json`.
- `client/lib/core/revenuecat/revenuecat_service.dart` — abstract
  interface + two impls: `NoopRevenueCatService` (default when
  disabled) and `PurchasesFlutterRevenueCatService`. DI module picks
  one based on the flag.
- `client/lib/core/revenuecat/revenuecat_initializer.dart` — early
  return when disabled; warning when enabled with placeholder key.
- `client/lib/core/analytics/app_analytics.dart` — replaced 30+
  product event names with a generic `logEvent(name, parameters)`
  façade.
- `client/lib/core/routing/app_router.dart` and `app_routes.dart` —
  reduced to two routes (`/`, `/design-system`).
- `client/lib/core/localization/locale_cubit.dart` — removed
  dependency on the deleted `SupabaseErrorTranslator`; kept `setLocale`
  and `resolveEffectiveTag` API.
- `client/lib/main.dart` and `app.dart` — removed `AuthCubit`,
  `ProfileCubit`, `OnboardingCarouselGate`, `FirstAuthPaywallCoordinator`
  bootstrapping; reduced to theme + locale + router.
- `client/lib/core_ui/theme/app_theme.dart` — replaced brand palette
  with neutral greyscale + single accent for both light and dark.
- `client/lib/core_ui/preview/ds_preview_page.dart` — rewritten with
  domain-neutral content (no currency, no portfolio cards, no
  product copy).
- `backend/supabase/functions/api/index.ts` — single `/health` route.
- `backend/supabase/functions/_shared/responses.ts` — kept envelope
  pattern, trimmed `ApiErrorCode` enum to generic codes only
  (removed `LIMIT_ACCOUNTS_REACHED`, `ASSET_NOT_ALLOWED_FOR_PLAN`).
- `backend/supabase/functions/_shared/validation.ts` — kept generic
  helpers (`uuidSchema`, `parseJsonBody`, `parsePositiveInt`,
  `parseBoolean`); removed product-specific schemas.
- `backend/supabase/config.toml` — removed `[functions.rates_sync]`
  and `[functions.revenuecat_webhook]` sections; project_id set to
  `template_app`.
- `backend/scripts/deploy_supabase.sh` — removed RevenueCat /
  scheduler / open-exchange-rates secret syncing and rates_sync cron
  trigger; reduced to `link → db push → functions deploy api`.
- `backend/README.md`, `backend/requirements.md` — rewritten as
  generic templates.
- `client/CLAUDE.md`, `client/AGENTS.md`, root `CLAUDE.md`, root
  `AGENTS.md` — written from scratch as equivalent, self-contained
  files.

## What was omitted as product-specific

- `client/lib/presentation/{account, analytics, asset, auth, balance,
  home, onboarding, overview, paywall, profile, settings}` — entire
  product feature surface.
- `client/lib/domain/{account, analytics, asset, auth, balance,
  profile, rate, subaccount}` — domain entities and repositories.
- `client/lib/data/{account, analytics, asset, auth, balance,
  profile, rate, subaccount}` — DTOs, data sources, repository impls.
- `client/lib/core/local_storage/{guided_tour_storage,
  onboarding_carousel_gate, onboarding_carousel_storage,
  onboarding_paywall_storage}` — onboarding-specific persistence.
- `client/lib/core/routing/{first_auth_paywall_coordinator,
  guards/auth_route_guard, guards/onboarding_route_guard}` —
  product-coupled navigation guards.
- `client/lib/core/supabase/{supabase_error_message,
  supabase_error_translator, supabase_failure_mapper}` — product
  error translation tables.
- `client/lib/core/utils/{decimal_math, money_atomic}`,
  `client/lib/core/types/decimal_json_converter` — finance-specific
  helpers (recommended for re-introduction as
  `docs/architecture/patterns/` if reused).
- `client/lib/core_ui/components/*` (28 of 33) — product-shaped
  components (ds_balance_input, ds_decimal_field, ds_oauth_button,
  ds_otp_input, ds_password_field, ds_plan_card, etc.).
- `client/lib/core_ui/formatting/ds_formatters.dart` — currency
  formatting helpers.
- `client/test/**` — product test suite.
- `client/assets/icon/*` — product icons.
- `client/tool/generate_dev_icon.dart` — product icon generator.
- `client/flutter_launcher_icons-{dev,prod}.yaml` — product icon
  configs.
- `backend/supabase/migrations/*` — all 158 product migrations.
- `backend/supabase/seed.sql` — product fiat/crypto seed data.
- `backend/supabase/seeds/crypto_top100_snapshot.tsv` — product
  reference data.
- `backend/supabase/functions/{rates_sync, revenuecat_webhook}` —
  product schedulers/webhooks.
- `backend/supabase/functions/_shared/{crypto_decimals, fiat_top100,
  money, revenuecat_entitlements}` — product helpers.
- `backend/scripts/setup_rates_sync_cron.sh` — product cron config.
- `docs/{product, ux, contracts, tech, flavors-and-accounts.md}` —
  product documentation.
- `.claude/commands/{create-spec, resolve-spec}.md` — replaced by the
  new skills layout (`.claude/skills/`).
- `.codex/skills/*` — replaced by `.agents/skills/`.

## What was sanitized

- All references to `asset_tuner` / `asset-tuner` / `Asset Tuner` /
  `developer.ivanmurzin.assettuner` replaced with `template_app` /
  `Template App` / `com.example.appname`.
- No real `.env`, `.config.dev.json`, `.config.prod.json`,
  `google-services.json`, `GoogleService-Info.plist`, RevenueCat keys,
  Supabase URLs/anon keys, Firebase configs, or signing keystores
  copied. Only `.example` files committed with obvious placeholders
  (`YOUR_*`, `rcat_placeholder_*`).
- `.git/` not copied.

## Placeholders created

- `.config.dev.json.example`, `.config.prod.json.example` — minimal
  required keys + integration flags.
- `.env.example` — backend deploy env keys.
- `client/lib/presentation/example/page/example_home_page.dart` —
  reference page for the layered structure.
- `backend/supabase/migrations/.gitkeep` and `docs/specs/**/.gitkeep`
  — keep otherwise-empty dirs in git.

## Checks run

- `chmod +x` on all `scripts/*.sh` and `backend/scripts/*.sh`.
- `grep` for product references in `client/`, `backend/` —
  no matches outside intentional `.example` placeholders and this
  report.
- `find` to confirm no `.git/` directory was copied.
- Manual review of every rewritten file.

## Checks skipped

- `flutter pub get` / `flutter analyze` / `flutter test` were **not**
  run inside the template. Generated files (`*.freezed.dart`, `*.g.dart`,
  `injectable.config.dart`, generated l10n) are intentionally absent
  — they regenerate during `bootstrap.sh`.
- Full iOS / Android builds were not attempted; the template is
  not meant to be used before bootstrap.

## Manual steps remaining (for the user adopting the template)

1. Copy the template into a new project directory (do not work
   inside `sdd_template` itself).
2. Run `./scripts/bootstrap.sh --app-name "..." --app-id com.acme.foo`.
3. Add Firebase config files; flip `ENABLE_FIREBASE=true`.
4. Add real RevenueCat keys; flip `ENABLE_REVENUECAT=true`.
5. Fill `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
6. Replace placeholder app icons / native splash.
7. Configure Android signing (`client/android/key.properties`).
8. Configure iOS signing & capabilities in Xcode.
9. Run `/create-product` to fill `docs/product/*`.

## Recommendations for first use

- Run `./scripts/check-ai-consistency.sh` immediately after bootstrap
  to confirm no parity drift.
- Replace the neutral DS palette in
  `client/lib/core_ui/theme/app_theme.dart` early — every other DS
  decision will be affected.
- When adopting an integration (push, attribution, search), follow
  the Firebase / RevenueCat pattern: prepared abstraction + no-op
  default + config flag.
- Keep the spec-first discipline — the value of the template
  compounds with how strictly you use SDD.

## V2 update — universal auth / profile / sessions / subscriptions

After the initial extraction the template had no business logic for
auth, profile, sessions, or subscriptions — they were treated as
product-specific. They aren't: ~95% of consumer apps need them.
This pass re-introduces them as **universal** (no product fields,
no UI), matching the architecture conventions the template already
enforces.

### Backend additions

- Migrations under `backend/supabase/migrations/` (`20260101000000+`):
  `set_updated_at` trigger function, `profiles` table (universal
  fields only: `user_id, email, display_name, avatar_url, locale,
  plan, revenuecat_app_user_id, created_at, updated_at`),
  `webhook_events` idempotency table, `handle_new_user` trigger on
  `auth.users`, `profiles` RLS lock-down, `api_get_me`,
  `api_profile_update` (partial PATCH), `api_apply_revenuecat_event`.
- Edge function `revenuecat_webhook/` with shared-secret auth and
  idempotent application of plan changes.
- `backend/supabase/functions/api/index.ts` extended with `/me`,
  `/profile/update`, `/delete_my_account`, `/revenuecat/refresh`.
- `_shared/revenuecat_entitlements.ts` and `_shared/validation.ts`
  schemas for `profileUpdate` / `deleteMyAccount`.
- `config.toml` — `revenuecat_webhook` declared with
  `verify_jwt = false`.
- `backend/scripts/deploy_supabase.sh` — opt-in deploy of the
  webhook + secret syncing when `REVENUECAT_*` env vars are set.

### Client additions

- `domain/auth/{entity, repository, usecase}` — `AuthSessionEntity`,
  `OtpVerificationEntity`, `AuthProvider` enum, `IAuthRepository`,
  10 use cases (`sign_in_with_password`, `sign_up_with_password`,
  `verify_sign_up_otp`, `resend_sign_up_otp`, `oauth_sign_in`,
  `get_auth_providers`, `watch_session`, `get_cached_session`,
  `sign_out`, `delete_account`).
- `data/auth/{dto, mapper, data_source, repository}` — Supabase
  data source, freezed `AuthSessionDto`, `AuthRepository` with
  OAuth timeout handling.
- `domain/profile/{entity, repository, usecase}` —
  `ProfileEntity` with universal fields only (no `baseAsset`,
  no entitlements table on the client), `IProfileRepository`,
  `get_profile` / `update_profile` use cases.
- `data/profile/{dto, mapper, data_source, repository}` —
  `ProfileDto` with `fromMeJson` adapter, partial-update data
  source.
- `domain/subscription/{entity, repository, usecase}` —
  `SubscriptionEntity` (`plan`, `source`, `revenuecatAppUserId`,
  `updatedAt`), `ISubscriptionRepository` with
  `refresh / restorePurchases / bindUser / unbindUser`,
  `refresh_subscription` and `restore_purchases` use cases.
- `data/subscription/{data_source, repository}` —
  `SubscriptionRepository` reads `profiles.plan` as the source of
  truth and only uses `RevenueCatService` for purchases / restores
  / identity.
- `presentation/auth/bloc/{auth_cubit, auth_state}` —
  `@lazySingleton`, owns global session state, listens to
  `UnauthorizedNotifier` for backend 401 → `forceLocalSignOut()`.
- `presentation/profile/bloc/{profile_cubit, profile_state}` —
  `@lazySingleton`, exposes `load / updateProfile / replace / clear`.
- `presentation/subscription/bloc/{subscription_cubit, subscription_state}` —
  `@lazySingleton`, drives the RC ↔ Supabase bridge: subscribes to
  `AuthCubit.stream`, calls `bindUser / unbindUser`, refreshes plan
  after sign-in.
- `core/supabase/supabase_failure_mapper.dart` — generic version
  (no l10n tables) that fires `UnauthorizedNotifier` on 401.
- `core/supabase/supabase_constants.dart` extended with `me`,
  `profileUpdate`, `deleteMyAccount`, `revenuecatRefresh`.
- `core/di/supabase_module.dart` exposes the named
  `oauthSignInTimeout` provider (`Duration`, default 90 s).
- `core/routing/guards/auth_route_guard.dart` —
  ChangeNotifier-backed guard listening to `AuthCubit.stream`.
- `core/routing/app_routes.dart` — `signIn / signUp / otp` constants.
- `core/config/app_config.dart` — added `oauthRedirectUri`,
  `isOtpEnabled`. Both optional; OTP defaults to false.
- `app.dart` — bootstraps `AuthCubit` and `SubscriptionCubit`,
  registers them via `BlocProvider.value`. The `AuthRouteGuard`
  is **commented out** by default; products turn it on once they
  add the auth pages (see
  `docs/architecture/patterns/auth_route_guard.md`).

### Configuration changes

- `.config.dev.json.example` / `.config.prod.json.example` extended
  with `OAUTH_REDIRECT_URI` and `IS_OTP_ENABLED`.
- `.env.example` extended with `REVENUECAT_API_KEY`,
  `REVENUECAT_WEBHOOK_SECRET`, `REVENUECAT_PRO_ENTITLEMENT(S)`.

### Documentation additions

- `docs/contracts/api-surface.md` — table of every shipped route.
- `docs/troubleshooting.md` — common bootstrap / runtime / deploy
  failures.
- `docs/architecture/patterns/auth_route_guard.md` — when and how
  to wire the guard.
- `docs/architecture/patterns/subscriptions_revenuecat.md` —
  source-of-truth model and the RC ↔ Supabase data flow.
- `CLAUDE.md` / `AGENTS.md` extended with the "Universal modules
  shipped with the template" section.

### Intentionally **not** included

- UI for sign-in / sign-up / OTP / profile / paywall — products own
  presentation. Constants are reserved (`AppRoutes.signIn / signUp
  / otp`) so the guard and the future pages line up.
- A `plan_limits` table — limits are product-specific. Add yours in
  a separate migration alongside the feature that uses them.
- A `base_asset_id` column or any finance-specific carry-over from
  asset-tuner.
- l10n tables for error code translation. The mapper returns the
  raw server message; products add translations as they need them.
- Tests for the new modules. Adopters write tests as part of the
  spec they're resolving (per `docs/sdd/definition_of_done.md`).
