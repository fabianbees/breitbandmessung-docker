#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.


# check if /VERSION File exists, --> only installing on first container start, afterwards skip ...
if [ -f "/VERSION" ]
then
    echo "App already installed, not installing again."
    echo "Version is: $(sed -n "/^$APP_VERSION/p;q" /VERSION)"
    exit 0
fi


# Otherwiese install breitbandmessung-dektop ...
echo "Installing Version $APP_VERSION (sha256:$APP_SHA512SUM)"

# Download latest breitbandmessung-app
wget "https://download.breitbandmessung.de/bbm/Festnetz-Check-$APP_VERSION-linux.deb"
echo "$APP_SHA512SUM  Festnetz-Check-$APP_VERSION-linux.deb" | sha512sum -c
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
    dpkg -i "Festnetz-Check-$APP_VERSION-linux.deb"
else
    # The package's Electron runtime is x86_64-only and unused here;
    # only the app's resources are unpacked.
    echo "$(uname -m) detected, unpacking the application without its x86_64 runtime ..."
    mkdir -p /opt/Festnetz-Check
    dpkg-deb --fsys-tarfile "Festnetz-Check-$APP_VERSION-linux.deb" \
        | tar -x -C /opt/Festnetz-Check --strip-components=3 ./opt/Festnetz-Check/resources

    # The app only considers x86_64 a supported system and would keep its
    # measurement menu disabled otherwise.
    /usr/local/bin/patch-os-check.rb /opt/Festnetz-Check/resources/app.asar
fi


# Save version info in /VERSION file
dpkg-deb -f "Festnetz-Check-${APP_VERSION}-linux.deb" Version > /VERSION
# Delete install package
rm "Festnetz-Check-$APP_VERSION-linux.deb"

