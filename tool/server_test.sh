#!/usr/bin/env bash
# Runs the tests tagged `server` against the local Supabase stack
# (`supabase start`, on podman). Extra arguments go to `flutter test`.
set -euo pipefail
export DOCKER_HOST="${DOCKER_HOST:-unix://$XDG_RUNTIME_DIR/podman/podman.sock}"
eval "$(supabase status -o env 2>/dev/null | grep -E '^(API_URL|ANON_KEY|PUBLISHABLE_KEY|SERVICE_ROLE_KEY|DB_URL)=')"
# The local founding code (supabase/functions/.env, from .env.example).
FOUNDING_CODE="$(sed -n 's/^FOUNDING_CODE=//p' "$(dirname "$0")/../supabase/functions/.env")"
export FOUNDING_CODE
SUPABASE_URL="$API_URL" SUPABASE_ANON_KEY="$ANON_KEY" \
  SUPABASE_PUBLISHABLE_KEY="$PUBLISHABLE_KEY" \
  SUPABASE_SERVICE_ROLE_KEY="$SERVICE_ROLE_KEY" SUPABASE_DB_URL="$DB_URL" \
  flutter test --tags server --run-skipped "$@"
