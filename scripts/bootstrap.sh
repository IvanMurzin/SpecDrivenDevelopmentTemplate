#!/usr/bin/env bash
set -euo pipefail

# Turn a cloned template into a real project.
#
# Usage:
#   ./scripts/bootstrap.sh --app-name "My App" --app-id com.acme.myapp
#   ./scripts/bootstrap.sh --app-name "My App" --app-id com.acme.myapp --reinit-git
#
# Pre-conditions:
#   - You cloned sdd_template into a NEW directory and `cd`'d into it.
#   - If .git/ exists, pass --reinit-git to recreate a clean repo.
#   - flutter, dart, and git are on PATH.
#
# This script is NOT idempotent. If anything fails, restore from a
# fresh clone of the template.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)"
cd "${ROOT_DIR}"

APP_NAME=""
APP_ID=""
REINIT_GIT=0

while (( $# > 0 )); do
  case "$1" in
    --app-name) APP_NAME="$2"; shift 2 ;;
    --app-id)   APP_ID="$2";   shift 2 ;;
    --reinit-git) REINIT_GIT=1; shift 1 ;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# \{0,1\}//' | head -n 20
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

[[ -z "${APP_NAME}" ]] && { echo "--app-name is required" >&2; exit 2; }
[[ -z "${APP_ID}"   ]] && { echo "--app-id is required (e.g. com.acme.myapp)" >&2; exit 2; }
if [[ ! "${APP_ID}" =~ ^[a-z][a-z0-9]*(\.[a-z][a-z0-9_]*)+$ ]]; then
  echo "--app-id must be reverse-DNS like com.acme.myapp" >&2
  exit 2
fi

# --- Pre-flight checks
if [[ "$(basename "${ROOT_DIR}")" == "sdd_template" ]]; then
  echo "Refusing to bootstrap inside sdd_template itself." >&2
  echo "Copy the template into a new directory first." >&2
  exit 1
fi
if [[ -d .git ]]; then
  if (( REINIT_GIT == 1 )); then
    echo "==> Removing existing .git/ before bootstrap (--reinit-git)"
    rm -rf .git
  else
    echo "Refusing: .git/ already exists in $(pwd)." >&2
    echo "Run with --reinit-git to remove template history and create a clean repo." >&2
    exit 1
  fi
fi
for tool in flutter dart git; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    echo "Required tool not found on PATH: ${tool}" >&2
    exit 1
  fi
done

# --- Derived values
APP_NAME_DEV="${APP_NAME} (dev)"
APP_ID_DEV="${APP_ID}.dev"
SCHEME_PROD="$(echo "${APP_ID}" | awk -F. '{print $NF}')"
SCHEME_DEV="${SCHEME_PROD}dev"
PACKAGE_NAME="$(echo "${APP_NAME}" | tr '[:upper:] ' '[:lower:]_' | tr -cd 'a-z0-9_' | sed 's/^_*//;s/_*$//')"
[[ -z "${PACKAGE_NAME}" ]] && PACKAGE_NAME="template_app"
ANDROID_PKG_PATH="$(echo "${APP_ID}" | tr . /)"

echo "==> App name        : ${APP_NAME}"
echo "==> App id (prod)   : ${APP_ID}"
echo "==> App id (dev)    : ${APP_ID_DEV}"
echo "==> Pubspec name    : ${PACKAGE_NAME}"
echo "==> Deep link prod  : ${SCHEME_PROD}"
echo "==> Deep link dev   : ${SCHEME_DEV}"
if (( REINIT_GIT == 1 )); then
  echo "==> Git mode        : reinitialize (clean repository)"
else
  echo "==> Git mode        : initialize if missing"
fi

# --- 1. Pubspec + Dart imports
echo "==> [1/8] Renaming Dart package -> ${PACKAGE_NAME}"
sed -i.bak "s|^name: template_app|name: ${PACKAGE_NAME}|" client/pubspec.yaml
rm -f client/pubspec.yaml.bak
find client/lib client/test -type f -name "*.dart" -print0 | xargs -0 sed -i.bak "s|template_app|${PACKAGE_NAME}|g"
find client/lib client/test -type f -name "*.dart.bak" -delete

# --- 2. Android namespace + applicationId + MainActivity
echo "==> [2/8] Renaming Android bundle id -> ${APP_ID}"
sed -i.bak "s|com.example.appname|${APP_ID}|g" client/android/app/build.gradle.kts
sed -i.bak "s|appnamedev|${SCHEME_DEV}|g" client/android/app/build.gradle.kts
sed -i.bak "s|\"appname\"|\"${SCHEME_PROD}\"|g" client/android/app/build.gradle.kts
sed -i.bak "s|Template App (dev)|${APP_NAME_DEV}|g" client/android/app/build.gradle.kts
sed -i.bak "s|Template App|${APP_NAME}|g" client/android/app/build.gradle.kts
rm -f client/android/app/build.gradle.kts.bak

mkdir -p "client/android/app/src/main/kotlin/${ANDROID_PKG_PATH}"
mv client/android/app/src/main/kotlin/com/example/appname/MainActivity.kt \
   "client/android/app/src/main/kotlin/${ANDROID_PKG_PATH}/MainActivity.kt"
sed -i.bak "s|package com.example.appname|package ${APP_ID}|" \
   "client/android/app/src/main/kotlin/${ANDROID_PKG_PATH}/MainActivity.kt"
rm -f "client/android/app/src/main/kotlin/${ANDROID_PKG_PATH}/MainActivity.kt.bak"
# Remove now-empty placeholder dirs
rmdir client/android/app/src/main/kotlin/com/example/appname 2>/dev/null || true
rmdir client/android/app/src/main/kotlin/com/example 2>/dev/null || true
rmdir client/android/app/src/main/kotlin/com 2>/dev/null || true

# --- 3. iOS xcconfig + pbxproj + Info.plist
echo "==> [3/8] Renaming iOS bundle id -> ${APP_ID}"
for f in client/ios/Flutter/Flavor-dev.xcconfig client/ios/Flutter/Flavor-prod.xcconfig \
         client/ios/Runner.xcodeproj/project.pbxproj client/ios/Runner/Info.plist; do
  sed -i.bak "s|com.example.appname|${APP_ID}|g" "${f}"
  sed -i.bak "s|appnamedev|${SCHEME_DEV}|g" "${f}"
  sed -i.bak "s|= appname$|= ${SCHEME_PROD}|g" "${f}"
  sed -i.bak "s|Template App (dev)|${APP_NAME_DEV}|g" "${f}"
  sed -i.bak "s|Template App|${APP_NAME}|g" "${f}"
  rm -f "${f}.bak"
done

# --- 4. Supabase project_id (sluggified app name)
echo "==> [4/8] Setting Supabase project_id -> ${PACKAGE_NAME}"
sed -i.bak "s|^project_id = \"template_app\"|project_id = \"${PACKAGE_NAME}\"|" backend/supabase/config.toml
rm -f backend/supabase/config.toml.bak

# --- 5. Local config files
echo "==> [5/8] Materializing config and env files"
[[ -f .config.dev.json ]]  || cp .config.dev.json.example  .config.dev.json
[[ -f .config.prod.json ]] || cp .config.prod.json.example .config.prod.json
[[ -f .env ]]              || cp .env.example              .env

# --- 6. Pub get + codegen
echo "==> [6/8] flutter pub get + build_runner"
(
  cd client
  flutter pub get
  # Some environments fail on AOT builder compilation; JIT is a safe fallback.
  dart run build_runner build --delete-conflicting-outputs || \
    dart run build_runner build --force-jit
)

# --- 7. Format + analyze
echo "==> [7/8] format + analyze"
( cd client && dart format . && flutter analyze )

# --- 8. Initial git commit
echo "==> [8/8] git init + first commit"
git init -q -b main
git add -A
git commit -q -m "chore: bootstrap from sdd_template"

cat <<'POST'

Bootstrap complete. Manual steps before first build:
  [ ] Add client/android/app/google-services.json and
      client/ios/Runner/GoogleService-Info.plist, then set
      ENABLE_FIREBASE=true in both .config.*.json.
  [ ] Replace rcat_placeholder_* keys with real RevenueCat keys, then
      set ENABLE_REVENUECAT=true.
  [ ] Fill SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in .config.*.json.
  [ ] Replace placeholder app icons and splash screen.
  [ ] Configure Android signing (client/android/key.properties).
  [ ] Configure iOS signing & capabilities in Xcode.
  [ ] Run /create-product to fill docs/product/*.

POST
