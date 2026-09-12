#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Check for updates to the Breitbandmessung app and its Electron runtime.
if [ "${CHECK_FOR_UPDATES:-false}" = true ]; then
    AUTO_UPDATE_OUTPUT="$(CSV_OUT=true detect-electron-version.sh 2>/dev/null | tail -n 1 || true)"
    if [ -z "${AUTO_UPDATE_OUTPUT:-}" ]; then
        echo "Could not detect latest Breitbandmessung version. Please check your network connection."
        exit 1
    else
        IFS=';' read -r ELECTRON_VERSION APP_VERSION APP_SHA256SUM <<< "$AUTO_UPDATE_OUTPUT"
        echo "Detected latest Breitbandmessung version: $APP_VERSION (sha256:$APP_SHA256SUM)"
        set-cont-env APP_VERSION "$APP_VERSION"
        set-cont-env APP_SHA256SUM "$APP_SHA256SUM"
    fi
fi

# check if /VERSION File exists, --> only installing on first container start, afterwards skip ...
if [ -f "/VERSION" ]
then
    echo "App already installed, not installing again."
    echo "Version is: $(sed -n "/^$APP_VERSION/p;q" /VERSION)"
    exit 0
fi


# Otherwiese install breitbandmessung-dektop ...
echo "Installing Version $APP_VERSION (sha256:$APP_SHA256SUM)"

# Download latest breitbandmessung-app
wget "https://download.breitbandmessung.de/bbm/Breitbandmessung-$APP_VERSION-linux.deb"
echo "$APP_SHA256SUM  Breitbandmessung-$APP_VERSION-linux.deb" | sha256sum -c
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "Checksum mismatch"
else
    echo "Checksum matches, installing ..."
fi


# Install .deb file
if [ "$(uname -m)" = "x86_64" ]
then
    sed -i '/messagebus/d' /var/lib/dpkg/statoverride   # needed because group does not exist at this time
    dpkg -i "Breitbandmessung-$APP_VERSION-linux.deb"
else
    # The package's Electron runtime is x86_64-only and unused here;
    # only the app's resources are unpacked.
    echo "$(uname -m) detected, unpacking the application without its x86_64 runtime ..."
    mkdir -p /opt/Breitbandmessung
    dpkg-deb --fsys-tarfile "Breitbandmessung-$APP_VERSION-linux.deb" \
        | tar -x -C /opt/Breitbandmessung --strip-components=3 ./opt/Breitbandmessung/resources

    # The app only considers x86_64 a supported system and would keep its
    # measurement menu disabled otherwise.
    /usr/local/bin/patch-os-check.rb /opt/Breitbandmessung/resources/app.asar
fi


# Save version info in /VERSION file
dpkg-deb -f "Breitbandmessung-${APP_VERSION}-linux.deb" Version > /VERSION
# Delete install package
rm "Breitbandmessung-$APP_VERSION-linux.deb"

