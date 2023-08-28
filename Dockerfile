# Pull base image.
FROM jlesage/baseimage-gui:ubuntu-20.04-v3

# see: https://download.breitbandmessung.de/bbm/
ENV APP_VERSION="3.4.0"
ENV APP_SHA256SUM="97abb8d6811d5f0bb3feb6697761f6ed9cebb6a5d484a1f17ce51cd4ac7f5f09"

# Timezone can be overwritten via docker environment variable
ENV TZ=Europe/Berlin

ENV DEBIAN_FRONTEND noninteractive    # export DEBIAN_FRONTEND="noninteractive"
ENV LANG=de_DE.UTF-8

# Install packages
RUN apt update && apt upgrade -yy && \
  apt install -y apt-utils nano libatk1.0-0 libatk-bridge2.0-0 libgtk-3-0 libgbm-dev libxss1 libasound2 wget xterm libnss3 locales xdotool xclip && \
  locale-gen de_DE.UTF-8 && \
  rm -rf /var/cache/apt /var/lib/apt/lists

# Generate and install favicons.
# alternative logo: https://breitbandmessung.de/images/breitbandmessung-logo.png
RUN APP_ICON_URL=https://www.breitbandmessung.de/public/images/appicon-512.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Copy the start script.
COPY startapp.sh /startapp.sh
COPY run-speedtest.sh /etc/services.d/speedtest/run
COPY 50-install-latest-breitbandmessung.sh /etc/cont-init.d/


# Set the name of the application.
ENV APP_NAME="Breitbandmessung"

VOLUME /config/xdg/config/Breitbandmessung
