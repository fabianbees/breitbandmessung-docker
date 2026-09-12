#!/usr/bin/env bash
# Detect which Electron version a Breitbandmessung release is built against.
#
# The app is published as an x86_64 .deb that bundles its own Electron runtime.
# On arm64 there is no such runtime, so the image installs a matching one from
# the Electron releases instead - its version must not drift from what the app
# was built against. This script reads that version out of the runtime the
# package bundles, so the build itself stays offline.
#
# Run it by hand after an app release and pin the values it prints.
#
# Needs a Debian/Ubuntu host for dpkg-deb; elsewhere run it in a container:
#   docker run --rm -v "$PWD:/w" -w /w ubuntu:26.04 sh -c 'apt-get -qq update && apt-get -qq install -y wget ca-certificates && ./scripts/detect-electron-version.sh'
#
# Usage: ./scripts/detect-electron-version.sh [app-version]   (default: latest)
set -euo pipefail
# The runtime is grepped as text; a UTF-8 locale chokes on its binary content.
export LC_ALL=C

BASE_URL="https://download.breitbandmessung.de/bbm"
WORK_DIR="$(mktemp -d)"
CSV_OUT="${CSV_OUT:-false}"  # set to true to get CSV output instead of human-readable text
trap 'rm -rf "$WORK_DIR"' EXIT

# Which release to look at: the one asked for, or whatever is current.
APP_VERSION="${1:-}"
if [ -z "$APP_VERSION" ]; then
    # see: https://download.breitbandmessung.de/bbm/latest-linux.yml
    MANIFEST="$(wget -qO- "$BASE_URL/latest-linux.yml")"
    # Only the top level keys; the files list repeats them indented.
    APP_VERSION="$(echo "$MANIFEST" | sed -n 's/^version: *//p')"
    EXPECTED_SHA512="$(echo "$MANIFEST" | sed -n 's/^sha512: *//p')"
    RELEASE_DATE="$(echo "$MANIFEST" | sed -n "s/^releaseDate: *'\(.*\)'/\1/p")"
    echo "latest release is $APP_VERSION (${RELEASE_DATE:-date unknown})"
fi
DEB="$WORK_DIR/Breitbandmessung-${APP_VERSION}-linux.deb"

echo "downloading Breitbandmessung-${APP_VERSION}-linux.deb ..."
wget -q -O "$DEB" "$BASE_URL/Breitbandmessung-${APP_VERSION}-linux.deb"

if [ -n "${EXPECTED_SHA512:-}" ]; then
    EXPECTED_HEX="$(echo "$EXPECTED_SHA512" | base64 -d | od -An -tx1 | tr -d ' \n')"
    echo "$EXPECTED_HEX  $DEB" | sha512sum -c --quiet
fi

# Read the version out of the bundled runtime. The package is streamed rather
# than unpacked: the version string sits early in the binary.
ELECTRON_VERSION="$(dpkg-deb --fsys-tarfile "$DEB" 2>/dev/null \
    | tar -xO ./opt/Breitbandmessung/breitbandmessung 2>/dev/null \
    | grep -aom1 'Electron/[0-9.]*' | head -1 | cut -d/ -f2 || true)"

if [ -z "$ELECTRON_VERSION" ]; then
    echo "Could not read the Electron version out of the package." >&2
    echo "Its layout has changed; the version has to be determined by hand." >&2
    exit 1
fi

# Not every Electron release carries a linux-arm64 build.
ELECTRON_URL="https://github.com/electron/electron/releases/download/v${ELECTRON_VERSION}/electron-v${ELECTRON_VERSION}-linux-arm64.zip"
if ! wget -q --spider "$ELECTRON_URL"; then
    echo "No arm64 build for Electron $ELECTRON_VERSION: $ELECTRON_URL" >&2
    exit 1
fi

APP_SHA256SUM="$(sha256sum "$DEB" | cut -d' ' -f1)"
if [ "$CSV_OUT" = true ]; then
    echo "$ELECTRON_VERSION;$APP_VERSION;$APP_SHA256SUM"
    exit 0
fi
echo
echo "the app is built against Electron $ELECTRON_VERSION (arm64 build exists)"
echo "pin these in the Dockerfile:"
echo "  ARG ELECTRON_VERSION=$ELECTRON_VERSION"
echo "  set-cont-env APP_VERSION \"$APP_VERSION\""
echo "  set-cont-env APP_SHA256SUM \"$APP_SHA256SUM\""
