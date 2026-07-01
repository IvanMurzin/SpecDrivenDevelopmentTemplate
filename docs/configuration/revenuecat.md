# RevenueCat

Wired but disabled by default. Disabled means the DI container
provides a `NoopRevenueCatService` whose every method returns `null`
— feature code never has to null-check the integration's presence.

The shipped subscription module is RevenueCat-bound; the data-flow
contract lives in
[`docs/architecture/patterns/subscriptions_revenuecat.md`](../architecture/patterns/subscriptions_revenuecat.md).

## Client setup

1. Create a RevenueCat project, set up an Offering, and grab the
   **public SDK** key for each platform.
2. Replace `rcat_placeholder_*` in `.config.<flavor>.json` with:
   `REVENUECAT_API_KEY_TEST` for dev builds,
   `REVENUECAT_API_KEY_ANDROID` for Android non-dev builds, and
   `REVENUECAT_API_KEY_IOS` for iOS non-dev builds.
3. Set `ENABLE_REVENUECAT=true` in `.config.<flavor>.json`.
4. Rebuild the app.

If `ENABLE_REVENUECAT=true` and the key still looks like a
placeholder (`rcat_placeholder_…` or empty),
`RevenueCatInitializer.init()` logs a warning at boot — purchases
will silently fail until the key is real.

## Server setup

The backend reads entitlements from RevenueCat directly (so the
client can never claim "pro" without server confirmation). Two
secrets are required and a third is optional:

| Backend secret                | Where it goes                          |
| ----------------------------- | -------------------------------------- |
| `REVENUECAT_API_KEY`          | `.env` → Supabase function secrets     |
| `REVENUECAT_WEBHOOK_SECRET`   | `.env` → Supabase function secrets, plus configured in RevenueCat → Project → Integrations → Webhook |
| `REVENUECAT_PRO_ENTITLEMENT(S)` | `.env` → Supabase function secrets   |

`backend/scripts/deploy_supabase.sh` syncs all of them with one
`supabase secrets set` call when it sees them in `.env`. The
`revenuecat_webhook` function is deployed only when both `_API_KEY`
and `_WEBHOOK_SECRET` are present, so projects without subscriptions
yet won't accidentally publish a misconfigured endpoint.

## Webhook configuration in RevenueCat

In the RevenueCat dashboard:

```
Project → Integrations → Webhook
URL:    https://<project-ref>.functions.supabase.co/revenuecat_webhook
Header: Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>
```

The webhook is idempotent (`webhook_events(source, external_id)`),
so RevenueCat retries are safe.

## What the backend actually does

- **`revenuecat_webhook` (push):** validates the shared secret,
  calls `GET /v1/subscribers/{app_user_id}` against RevenueCat to
  re-derive `is_pro`, then runs `api_apply_revenuecat_event` to
  update `profiles.plan`.
- **`/api/revenuecat/refresh` (pull):** the same flow on demand,
  triggered by the client after a purchase, restore, or app
  foreground.

The client never trusts the local SDK as the source of truth —
`profiles.plan` is. Treat RevenueCat's SDK as a purchase initiator,
not as state.

## Disabling

Set `ENABLE_REVENUECAT=false`. The DI module swaps in
`NoopRevenueCatService`; `SubscriptionRepository` keeps its
contract — `bindUser`, `restorePurchases`, `refresh` all become
near-no-ops. The backend webhook can stay deployed or be removed by
omitting the `REVENUECAT_*` secrets from `.env`.
