# Troubleshooting

Common failures during bootstrap, build, and deploy. Add entries as
you trip over new ones — keep them factual and short.

## Client

### `Missing app config keys: …`
`AppConfig._fromEnvironment` failed validation. Make sure you copied
`.config.dev.json.example` to `.config.dev.json` (and `.prod.json`)
and that they contain non-empty `ENV`, `FLAVOR`, `SUPABASE_URL`,
`SUPABASE_PUBLISHABLE_KEY`. Run with `--dart-define-from-file=../.config.dev.json`.

### `dart run build_runner build` fails with `*.freezed.dart` not found
Generated files don't exist yet. Run
`dart run build_runner build --delete-conflicting-outputs` once.
Re-run after every change to `@freezed`, `@JsonSerializable`,
`@injectable`, or ARB localization keys.

### `dart run build_runner build` fails at `compiling builders/aot`
On some machines AOT compilation of builder scripts fails. Re-run with
`dart run build_runner build --force-jit`.

### `flutter run` works but the app shows the splash forever
The router is waiting for `AuthCubit` to emit a non-`initial` state.
Check `SupabaseInitializer.init()` ran (visible in logs) and that
the Supabase URL / publishable key resolve to a project that exists. The
session stream emits `null` for unauthenticated; `initial` only
appears before the very first `bootstrap()` tick.

### Sign-in succeeds but the next request returns 401
You probably forgot to wire `UnauthorizedNotifier` into your custom
data source. Use `SupabaseFailureMapper.toFailure(error)` for every
edge-function error — it fires the notifier on `unauthorized` and
the AuthCubit drops the local session automatically.

## Backend

### `supabase db push` says migrations applied locally but failed remote
Most often a SQL function uses `auth.uid()` outside a SECURITY
DEFINER scope, or references a table that doesn't exist yet. Check
order: a function must be created in a later migration than the
table it touches.

### `revenuecat_webhook` always returns 403
Either `REVENUECAT_WEBHOOK_SECRET` is unset on the deployed
function, or RevenueCat is sending a different value in the
Authorization header. Check `supabase secrets list` and the value
configured under RevenueCat → Project → Integrations → Webhook.

### `/api/revenuecat/refresh` returns `EXTERNAL_API_ERROR`
The function received a non-2xx from `https://api.revenuecat.com/v1/subscribers/{id}`.
Confirm `REVENUECAT_API_KEY` is the **server-side secret** key (not
the SDK public key) and the user's `app_user_id` exists in
RevenueCat. New users get a 404 until they have an active or trialed
purchase, which the webhook ignores (treated as `is_pro=false`).

## Skills / hooks

### Stop hook reports "ai-consistency drifted"
`scripts/check-ai-consistency.sh` found differences between
`CLAUDE.md` and `AGENTS.md`, or between `.claude/skills/` and
`.agents/skills/`. Run the script with `--diff` to see what
diverged; sync both directions before committing.

### `bootstrap.sh` refuses to run
The script bails when it detects an existing `.git/` without
`--reinit-git`, when the package name still matches `template_app`,
or when required CLIs are missing. For cloned templates, run with
`--reinit-git` to recreate a clean repository.
