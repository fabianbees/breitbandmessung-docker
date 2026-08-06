#!/bin/bash
# Breitbandmessung Installer for Docker
# This script handles dynamic updates via latest-linux.yml
set -e          # Exit immediately if a command exits with a non-zero status.
set -u          # Treat unset variables as an error.
set -o pipefail # The return value of a pipeline is the status of the last command to exit with a non-zero status.

# Config
YAML_URL="https://download.breitbandmessung.de/bbm/latest-linux.yml"
BASE_URL="https://download.breitbandmessung.de/bbm"
CHECK_FOR_UPDATES="${CHECK_FOR_UPDATES:-true}"
VERSION_FILE="/VERSION"
HASH_FILE="/VERSION.hash"
DEB_TEMP="/tmp/breitbandmessung.deb"

log() { echo "[Installer] $*"; }

# Cleanup: Delete the installer package on exit (success or failure)
cleanup() { rm -f "$DEB_TEMP"; }
trap cleanup EXIT

# 1. Gather information (Defaults from Dockerfile)
INSTALL_VERSION="$APP_VERSION"
INSTALL_SHA="$APP_SHA256SUM"
INSTALL_PATH="Breitbandmessung-$APP_VERSION-linux.deb"
HASH_TYPE="sha256"

if [ "$CHECK_FOR_UPDATES" = "true" ]; then
    log "Checking for latest version at $YAML_URL..."
    if YAML=$(wget -qO- "$YAML_URL"); then
        # Parse version info from YAML
        ONLINE_VERSION=$(echo "$YAML" | sed -n 's/^version: //p' | tr -d '\r' | head -n1)
        ONLINE_SHA_B64=$(echo "$YAML" | sed -n 's/^sha512: //p' | tr -d '\r' | head -n1)
        ONLINE_PATH=$(echo "$YAML" | sed -n 's/^path: //p' | tr -d '\r' | head -n1)

        if [ -n "$ONLINE_VERSION" ] && [ -n "$ONLINE_SHA_B64" ]; then
            INSTALL_VERSION="$ONLINE_VERSION"
            INSTALL_SHA=$(echo "$ONLINE_SHA_B64" | base64 -d | od -v -t x1 -An | tr -d ' \n')
            INSTALL_PATH="$ONLINE_PATH"
            HASH_TYPE="sha512"
            log "Latest online version is $INSTALL_VERSION"
        else
            log "Failed to parse YAML. Falling back to $APP_VERSION."
        fi
    else
        log "Download of YAML failed. Falling back to $APP_VERSION."
    fi
else
    log "Update check disabled. Using version $APP_VERSION."
fi

# 2. Check if installation or update is required (Hash-based)
if [ -f "$HASH_FILE" ] && [ "$(cat "$HASH_FILE")" = "$INSTALL_SHA" ]; then
    log "App already installed and up to date ($INSTALL_VERSION). Skipping."
    exit 0
fi

# 3. Download and Verify
log "Installing Version $INSTALL_VERSION..."
wget -q "$BASE_URL/$INSTALL_PATH" -O "$DEB_TEMP"

log "Verifying $HASH_TYPE checksum..."
ACTUAL_SHA=$("${HASH_TYPE}sum" "$DEB_TEMP" | cut -d' ' -f1)

if [ "$ACTUAL_SHA" != "$INSTALL_SHA" ]; then
    log "CRITICAL: Checksum mismatch! (Expected: $INSTALL_SHA, Got: $ACTUAL_SHA)"
    exit 1
fi

# 4. Install .deb package
log "Installing package..."
# Needed because group 'messagebus' does not exist at this time
sed -i '/messagebus/d' /var/lib/dpkg/statoverride || true
dpkg -i "$DEB_TEMP"

# 5. Save state for next container start
echo "$INSTALL_VERSION" > "$VERSION_FILE"
echo "$INSTALL_SHA" > "$HASH_FILE"
log "Installation of Breitbandmessung $INSTALL_VERSION successful."
