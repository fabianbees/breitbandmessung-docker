#!/usr/bin/with-contenv bash


# check if /VERSION File exists, --> only installing on first container start, afterwards skip ...
if [ -f "/VERSION" ]
then
    echo "App already installed, not installing again."
    echo "Version is: $(sed -n "/^$APP_VERSION/p;q" /VERSION)"
    exit 0
fi


echo "Installing Version $APP_VERSION (sha256:$APP_SHA256SUM)"


set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

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
sed -i '/messagebus/d' /var/lib/dpkg/statoverride   # needed because group does not exist at this time
dpkg -i "Breitbandmessung-$APP_VERSION-linux.deb"


# Save version info in /VERSION file
dpkg-deb -f "Breitbandmessung-${APP_VERSION}-linux.deb" Version > /VERSION
# Delete install package
rm "Breitbandmessung-$APP_VERSION-linux.deb"

