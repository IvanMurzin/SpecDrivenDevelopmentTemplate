#!/usr/bin/env bash
set -euo pipefail

# Deterministic Claude/Codex parity checks.
#
# Exits 0 on success, non-zero on failure. The corresponding skill
# (.claude/skills/check-ai-consistency, .agents/skills/...) wraps this
# script and adds higher-level semantic review on top.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
cd "${ROOT_DIR}"

FAILED=0
fail() { echo "FAIL: $*" >&2; FAILED=1; }
ok()   { echo "OK:   $*"; }
warn() { echo "WARN: $*" >&2; }

# --- 1. Top-level files exist
for f in CLAUDE.md AGENTS.md README.md .gitignore; do
  if [[ -f "${f}" ]]; then ok "${f}"; else fail "missing ${f}"; fi
done

# --- 2. Same skill names mentioned in CLAUDE.md and AGENTS.md
if [[ -f CLAUDE.md && -f AGENTS.md ]]; then
  CLAUDE_SKILLS="$(grep -oE '\b(bootstrap|create-product|review-core-ui|plan-feature|create-spec|resolve-spec|check-ai-consistency|mvp-orchestrator|ui-ux-pro-max)\b' CLAUDE.md | sort -u || true)"
  AGENTS_SKILLS="$(grep -oE '\b(bootstrap|create-product|review-core-ui|plan-feature|create-spec|resolve-spec|check-ai-consistency|mvp-orchestrator|ui-ux-pro-max)\b' AGENTS.md | sort -u || true)"
  if [[ "${CLAUDE_SKILLS}" == "${AGENTS_SKILLS}" ]]; then
    ok "CLAUDE.md and AGENTS.md mention the same skills"
  else
    fail "skill mention drift between CLAUDE.md and AGENTS.md"
  fi
fi

# --- 3. Skill parity: every .claude/skills/X exists in .agents/skills/X (and vice versa)
if [[ -d .claude/skills && -d .agents/skills ]]; then
  CLAUDE_SET="$(find .claude/skills -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
  AGENTS_SET="$(find .agents/skills -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
  if [[ "${CLAUDE_SET}" == "${AGENTS_SET}" ]]; then
    ok "skill directory parity"
  else
    fail "skill directory parity (claude=${CLAUDE_SET//$'\n'/,}; agents=${AGENTS_SET//$'\n'/,})"
  fi

  # --- 4. Paired SKILL.md files have the same H2 set
  while read -r name; do
    [[ -z "${name}" ]] && continue
    A=".claude/skills/${name}/SKILL.md"
    B=".agents/skills/${name}/SKILL.md"
    if [[ ! -f "${A}" ]] || [[ ! -f "${B}" ]]; then continue; fi
    HA="$(grep -E '^## ' "${A}" | sort)"
    HB="$(grep -E '^## ' "${B}" | sort)"
    if [[ "${HA}" == "${HB}" ]]; then
      ok "skill ${name} headers parity"
    else
      fail "skill ${name} H2 sections differ between Claude and Codex"
    fi

    # --- 5. Frontmatter description present
    DA="$(awk -F'description: ' '/^description:/{print $2; exit}' "${A}")"
    if [[ -z "${DA}" ]]; then fail "${A}: missing description in frontmatter"; fi
    if (( ${#DA} > 600 )); then warn "${A}: description is long (${#DA} chars)"; fi
  done <<< "${CLAUDE_SET}"
fi

# --- 6. Required docs exist
for f in docs/README.md docs/sdd/constitution.md docs/sdd/spec_lifecycle.md \
         docs/sdd/spec_template.md docs/sdd/definition_of_done.md \
         docs/specs/README.md docs/specs/INDEX.md; do
  if [[ -f "${f}" ]]; then ok "${f}"; else fail "missing ${f}"; fi
done

# --- 7. Required scripts exist and are executable
for s in scripts/check.sh scripts/format.sh scripts/analyze.sh \
         scripts/bootstrap.sh scripts/supabase-reset.sh \
         scripts/supabase-typegen.sh scripts/update-spec-index.sh \
         scripts/check-ai-consistency.sh; do
  if [[ -x "${s}" ]]; then
    ok "${s} is executable"
  elif [[ -f "${s}" ]]; then
    fail "${s} exists but is not executable (chmod +x)"
  else
    fail "missing ${s}"
  fi
done

# --- 8. .gitignore covers secrets and generated files
if [[ -f .gitignore ]]; then
  for pat in '\.env' '\.config\.dev\.json' '\.config\.prod\.json' '\*\.freezed\.dart' '\*\.g\.dart' 'injectable\.config\.dart' 'google-services\.json' 'GoogleService-Info\.plist'; do
    if grep -qE "${pat}" .gitignore; then
      ok ".gitignore covers ${pat}"
    else
      fail ".gitignore missing pattern: ${pat}"
    fi
  done
fi

# --- 9. Spec filenames follow convention
SPEC_FILES="$(find docs/specs/open docs/specs/closed -type f -name '*.md' 2>/dev/null \
  | grep -v -E '/(README|INDEX)\.md$' || true)"

while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  if [[ ! "$(basename "${f}")" =~ ^(SPEC|BUG|PROP)-[0-9]{4}-.+\.md$ ]]; then
    fail "spec filename does not match convention: ${f}"
  fi
done <<< "${SPEC_FILES}"

# --- 10. Spec frontmatter required fields
while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  for field in id title type status priority owner created updated; do
    if ! grep -qE "^${field}:" "${f}"; then
      fail "${f}: missing frontmatter field '${field}'"
    fi
  done
done <<< "${SPEC_FILES}"

# --- 11. INDEX.md mentions every spec
if [[ -f docs/specs/INDEX.md ]]; then
  while IFS= read -r f; do
    [[ -z "${f}" ]] && continue
    id="$(awk '/^id:/{print $2; exit}' "${f}")"
    if [[ -n "${id}" ]] && ! grep -qF "| ${id} " docs/specs/INDEX.md; then
      fail "INDEX.md missing entry for ${id} (run scripts/update-spec-index.sh)"
    fi
  done <<< "${SPEC_FILES}"
fi

# --- 12. No obvious real secrets
SECRET_RE='(sk_[A-Za-z0-9]{20,})|(eyJ[A-Za-z0-9_-]{20,}\.eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,})'
HITS="$(grep -RIE --include='*' --exclude-dir='.git' --exclude='*.example' \
  --exclude-dir='build' --exclude-dir='.dart_tool' --exclude-dir='.swiftpm' \
  --exclude-dir='Pods' --exclude-dir='SourcePackages' --exclude-dir='DerivedData' \
  --exclude='*.lock' --exclude='check-ai-consistency.sh' \
  "${SECRET_RE}" . || true)"
if [[ -z "${HITS}" ]]; then
  ok "no obvious real secrets detected"
else
  fail "potential real secret(s) detected:\n${HITS}"
fi

if (( FAILED == 0 )); then
  echo
  echo "All checks passed."
  exit 0
fi
echo
echo "Some checks failed (see FAIL lines above)." >&2
exit 1
