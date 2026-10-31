#!/usr/bin/env bash
# Run hadolint via Podman (no docker daemon / no dnf hadolint package).
set -euo pipefail

readonly IMAGE="${HADOLINT_IMAGE:-ghcr.io/hadolint/hadolint:latest}"
for file in "$@"; do
  podman run --rm -i \
    -v "${PWD}/${file}:/Containerfile:ro,Z" \
    "${IMAGE}" \
    hadolint --ignore DL3007 --ignore DL3041 "/Containerfile"
done
