# Pull base image.
FROM jlesage/baseimage-gui:ubuntu-22.04-v4


# Install packages
RUN apt update && apt upgrade -yy && \
  apt install -y apt-utils nano libatk1.0-0 libatk-bridge2.0-0 libgtk-3-0 libgbm-dev libxss1 libasound2 wget xterm libnss3 locales xdotool xclip && \
  locale-gen de_DE.UTF-8 && \
  rm -rf /var/cache/apt /var/lib/apt/lists

# Generate and install favicons.
# alternative logo: https://breitbandmessung.de/images/breitbandmessung-logo.png
RUN APP_ICON_URL=https://www.breitbandmessung.de/public/images/appicon-512.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /

# Set internal environment variables.
# see: https://download.breitbandmessung.de/bbm/
RUN \
    set-cont-env APP_NAME "Breitbandmessung" && \
    set-cont-env APP_VERSION "3.11.0" && \
    set-cont-env APP_SHA256SUM "90db91fb370a11d67da741c46a39854374c8533d73d80a34f7c40d08aeb1e658" && \
    set-cont-env DEBIAN_FRONTEND "noninteractive" && \
    set-cont-env LANG "de_DE.UTF-8" &&  \
    true


# Set public environment variables.
# Timezone can be overwritten via docker environment variable
ENV TZ=Europe/Berlin
# 1180x720 is absolute minimum
ENV DISPLAY_WIDTH "1280"
ENV DISPLAY_HEIGHT "768"


VOLUME /config/xdg/config/Breitbandmessung
