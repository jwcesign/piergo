#!/usr/bin/env bash
set -euo pipefail

BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hack/versions.env
source "$BASE/versions.env"
args=()
for key in DEBIAN_IMAGE NODE_IMAGE CUA_SPACESD_VERSION CUA_DRIVER_VERSION CODEX_VERSION BROWSEROS_VERSION; do
    override="PIERGO_$key"
    value="${!override:-${!key}}"
    if [[ ! "$value" =~ ^[A-Za-z0-9_./:@+-]+$ ]]; then
        printf 'Invalid version: %s\n' "$key" >&2
        exit 1
    fi
    if [[ "${1:-}" == --print-build-args ]]; then
        printf '%s=%s\n' "$key" "$value"
    else
        args+=(--build-arg "$key=$value")
    fi
done
[[ "${1:-}" != --print-build-args ]] || exit 0
# Keep the previous invocation working as well as the shorter default.
[[ "${1:-}" != build ]] || shift
for key in HTTP_PROXY HTTPS_PROXY NO_PROXY http_proxy https_proxy no_proxy; do
    if [[ -n "${!key:-}" ]]; then args+=(--build-arg "$key"); fi
done
exec docker buildx build --platform linux/amd64 --load \
    --tag "${PIERGO_IMAGE:-piergo-codex:dev}" --file "$BASE/Dockerfile" \
    "${args[@]}" "$@" "$BASE"
