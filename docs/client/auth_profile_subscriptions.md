# Auth, profile, sessions, subscriptions

The template ships universal domain + data + cubit code for these
four concerns. Products own the UI and any product-specific
extensions; everything below works as-is on a fresh project.

## Where the code lives

```
client/lib/
  domain/auth/                       # entities, IAuthRepository, 10 use cases
  domain/profile/                    # ProfileEntity, IProfileRepository, get/update use cases
  domain/subscription/               # SubscriptionEntity, ISubscriptionRepository, refresh/restore use cases
  data/auth/                         # AuthSessionDto, Supabase data source, AuthRepository
  data/profile/                      # ProfileDto + fromMeJson adapter, ProfileRepository
  data/subscription/                 # SubscriptionRepository (RevenueCat-bound)
  presentation/auth/bloc/            # AuthCubit (lazySingleton) + AuthState
  presentation/profile/bloc/         # ProfileCubit (lazySingleton) + ProfileState
  presentation/subscription/bloc/    # SubscriptionCubit (lazySingleton) + SubscriptionState
  core/session/unauthorized_notifier.dart
  core/supabase/supabase_failure_mapper.dart
  core/routing/guards/auth_route_guard.dart
  core/routing/app_routes.dart       # signIn / signUp / otp constants
```

`app.dart` already creates `AuthCubit`, `ProfileCubit`, and
`SubscriptionCubit` from `getIt` and provides them via
`MultiBlocProvider`. The auth route guard is **commented out** —
turn it on after adding sign-in pages (see
[`patterns/auth_route_guard.md`](../architecture/patterns/auth_route_guard.md)).

## Day-1 wiring (once per fresh project)

After `bootstrap.sh`:

1. Decide whether you need OTP (`IS_OTP_ENABLED=true`) and OAuth
   (`OAUTH_REDIRECT_URI=myapp://login-callback/`). Set in both
   `.config.dev.json` and `.config.prod.json`.
2. If you enable subscriptions, fill the backend secrets
   (`REVENUECAT_API_KEY`, `REVENUECAT_WEBHOOK_SECRET`,
   `REVENUECAT_PRO_ENTITLEMENT`, plus the client SDK keys in the
   client config) and deploy via
   `backend/scripts/deploy_supabase.sh`.
3. Run the migrations: `supabase --workdir backend db push`.
4. Configure Supabase Auth providers (email + Google + Apple as
   needed) in the Supabase dashboard.

That's the whole "infra" layer. Code-wise, nothing else is required
before you start writing specs.

## Reading state from the UI

```dart
// Is the user signed in?
final isAuthed = context.watch<AuthCubit>().state.isAuthenticated;

// Current profile (null until ProfileCubit.load() succeeds)
final profile = context.watch<ProfileCubit>().state.profile;

// Subscription status (refreshes automatically when AuthCubit emits)
final isPro = context.watch<SubscriptionCubit>().state.isPro;
```

`AuthState`, `ProfileState`, `SubscriptionState` are all `freezed`
classes — destructure them in `BlocBuilder` / `BlocSelector` as
usual.

## Common operations

```dart
// Email + password sign in (validators are up to your form)
final result = await getIt<SignInWithPasswordUseCase>().call(email, password);

// Sign up — when IS_OTP_ENABLED=false this also signs in
final signUp = await getIt<SignUpWithPasswordUseCase>().call(email, password);
// when IS_OTP_ENABLED=true, route the user to /sign-up/otp and call:
await getIt<VerifySignUpOtpUseCase>().call(email, code);

// OAuth (the cubit emits authenticated when the deep-link returns)
await getIt<OAuthSignInUseCase>().call(AuthProvider.google);

// Sign out
await context.read<AuthCubit>().signOut();

// Update profile (partial PATCH)
await context.read<ProfileCubit>().updateProfile(displayName: 'New name');

// Restore purchases (chains a refresh)
await context.read<SubscriptionCubit>().restorePurchases();
```

## Loading the profile after sign-in

`AuthCubit` is dependency-free on purpose — it does not call
`ProfileCubit.load()` itself. Either:

- watch `AuthState.isAuthenticated` from your shell widget and call
  `context.read<ProfileCubit>().load()` once, or
- write a thin coordinator (e.g. `ProfileLoader` widget) that
  listens to `AuthCubit` and triggers `ProfileCubit.load(silent: true)`
  on every authenticated session.

The coordinator pattern keeps `AuthCubit` reusable in tests and
prevents `ProfileCubit` from triggering on the initial `unknown`
session state.

## Backend 401 handling

`SupabaseFailureMapper.toFailure` fires `UnauthorizedNotifier` on
every 401 / `unauthorized` failure. `AuthCubit.bootstrap` listens
to it and calls `forceLocalSignOut()` — drops the local session
without calling Supabase signOut (the server-side token is already
invalid). The route guard (once wired) then redirects to
`/sign-in`.

You don't need to handle 401 in feature code — let the failure
bubble up through the Result chain and the global mechanism does
the rest.

## Suggested first specs

The template intentionally ships no auth UI. The fastest path to a
working app:

1. **SPEC-0001 — Sign-in page.** Email + password form, calls
   `SignInWithPasswordUseCase`, surfaces failures via the form's
   error slot.
2. **SPEC-0002 — Sign-up page.** Email + password + confirm,
   handles the OTP / no-OTP fork by reading `AppConfig.isOtpEnabled`.
3. **SPEC-0003 — Wire `AuthRouteGuard`.** Add the route entries to
   `app_router.dart` and uncomment the guard line in `app.dart`.
   Acceptance: signed-out users land on `/sign-in`, signed-in users
   on `/`.
4. **SPEC-0004 — Profile screen (read-only).** Calls
   `ProfileCubit.load()` on mount, renders email + display name +
   avatar.
5. **SPEC-0005 — Edit profile.** Form bound to
   `ProfileCubit.updateProfile`.
6. **SPEC-0006 — Paywall + subscription gate.** Branch product
   features on `SubscriptionState.isPro`. Trigger `restorePurchases`
   from a "Restore" button.

Each spec is small, observable, and testable on its own — the
cubits do the heavy lifting.
