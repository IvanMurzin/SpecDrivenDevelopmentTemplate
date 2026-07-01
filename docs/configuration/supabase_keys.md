# Supabase keys

Two kinds of keys:

| Key | Where it lives | Who uses it |
| --- | -------------- | ----------- |
| **Publishable** (`SUPABASE_PUBLISHABLE_KEY`) | `.config.<flavor>.json` | Flutter client. |
| **Service role** (`SUPABASE_SERVICE_ROLE_KEY`) | Supabase secret | Edge Function only. |

## Publishable

Public. Safe to ship in the client bundle. Set in:

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
}
```

## Service role

Bypasses RLS. **Never** ship in the client. The Supabase platform
provides this to your Edge Function automatically as the env var
`SUPABASE_SERVICE_ROLE_KEY` — `_shared/db.ts` reads it.

## DB password

Used only for ad-hoc `psql` sessions. Optional. Lives in `.env`
(gitignored) as `SUPABASE_DB_PASSWORD`.

## Rotation

If a key is exposed:

1. Rotate it in the Supabase dashboard.
2. Update the `.config.<flavor>.json` of every developer.
3. Trigger a fresh client build.
