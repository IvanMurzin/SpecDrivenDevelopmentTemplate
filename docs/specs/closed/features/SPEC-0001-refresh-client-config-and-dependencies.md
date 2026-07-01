---
id: SPEC-0001
title: refresh client config and dependencies
type: feature
status: done
priority: P1
owner: agent
created: 2026-07-02
updated: 2026-07-02
depends_on: []
blocks: []
related_specs: []
product_docs: []
design_doc: ""
tech_notes: ""
allowed_change_areas:
  - "client/**"
  - "docs/**"
  - "scripts/**"
  - ".config.*.json.example"
forbidden_change_areas:
  - "backend/supabase/migrations/**"
---

# refresh client config and dependencies

## Problem
The template still used deprecated Supabase anon-key naming in client
configuration and used a single RevenueCat public SDK key, while current
projects need a test key for dev and platform-specific keys for production.
Dependencies also need to be refreshed and platform builds verified.

## Goal
Adopting projects start from current Supabase and RevenueCat client config
contracts and upgraded Flutter dependencies.

## Non-goals
- Change backend RevenueCat server secret names.
- Change Supabase backend migrations or RLS.
- Add new product UI.

---

## User scenarios

**US-001 — Fresh project config**
- **Given** a developer copies the template config examples
- **When** they fill Supabase and RevenueCat keys
- **Then** they see publishable Supabase key naming and separate RevenueCat test, Android, and iOS keys.

**US-002 — Build verification**
- **Given** dependencies are upgraded
- **When** the app is analyzed, tested, and built for Android and iOS
- **Then** actionable warnings are fixed and remaining warnings are documented.

---

## Functional requirements

- **FR-001:** Client config must require `SUPABASE_PUBLISHABLE_KEY`, not `SUPABASE_ANON_KEY`.
- **FR-002:** Supabase initialization must call `publishableKey`.
- **FR-003:** Dev builds must use `REVENUECAT_API_KEY_TEST`.
- **FR-004:** Non-dev Android and iOS builds must use their matching RevenueCat public SDK keys.
- **FR-005:** Config docs, examples, and bootstrap guidance must describe the new keys.
- **FR-006:** Flutter dependencies must be upgraded as far as the current SDK constraints allow.

---

## Design requirements

No UI changes.

## Data model

No data model changes.

## Backend requirements

No backend behavior changes. Backend `REVENUECAT_API_KEY` remains the server-side secret key.

## Frontend requirements

- Update `AppConfig` and Supabase/RevenueCat initialization.
- Update dependency constraints and lockfile.

## Analytics requirements

None.

## Security / privacy / RLS requirements

No secrets are committed. Config examples keep placeholder values only.

## Test requirements

### Unit tests
| Test file | What it covers |
|-----------|---------------|
| `test/widget_test.dart` | Existing app smoke coverage. |

### Widget tests
| Test file | What it covers |
|-----------|---------------|
| `test/widget_test.dart` | Existing app widget smoke coverage. |

---

## Acceptance criteria

- [x] **AC-1 (FR-001):** Client code and config examples no longer use `SUPABASE_ANON_KEY`.
- [x] **AC-2 (FR-002):** Supabase initialization uses `publishableKey`.
- [x] **AC-3 (FR-003, FR-004):** RevenueCat client key resolution supports dev test and platform-specific production keys.
- [x] **AC-4 (FR-005):** Docs and bootstrap guidance describe the new config names.
- [x] **AC-5 (FR-006):** Dependencies are upgraded and lockfiles regenerated.
- [x] **AC-6:** Analyze, tests, Android build, and iOS build have been run.

## Success criteria

- **SC-001:** Fresh template users do not see Supabase `anonKey` deprecation warnings from template code.
- **SC-002:** Fresh template users can fill separate RevenueCat keys without changing code.

## Implementation plan

- Rename Supabase client config to publishable-key terminology.
- Split RevenueCat client SDK config keys into test, Android, and iOS values.
- Update documentation and bootstrap copy.
- Upgrade dependencies.
- Run format, analyze, tests, Android build, and iOS build.

## Migration / data requirements

Existing adopters must rename `SUPABASE_ANON_KEY` to `SUPABASE_PUBLISHABLE_KEY` and replace
the single client `REVENUECAT_API_KEY` with the three public SDK key entries.

## Rollout notes

No backend rollout required.

## Open questions

None.
