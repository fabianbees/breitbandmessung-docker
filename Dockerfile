# Pull base image.
FROM jlesage/baseimage-gui:ubuntu-26.04-v4


# Install packages
RUN upg-pkg && \
    add-pkg apt-utils nano libatk1.0-0 libatk-bridge2.0-0 libgtk-3-0 libgbm-dev libxss1 libasound2t64 wget xterm libnss3 locales xdotool xclip ca-certificates libgl1 lsb-release && \
    locale-gen de_DE.UTF-8

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
    set-cont-env APP_VERSION "3.12.1" && \
    set-cont-env APP_SHA256SUM "b948331a4e8df0fcbdd6fbace588770e62b4c61e7e279c6a0f79ef581de080f1" && \
    set-cont-env CHECK_FOR_UPDATES "true" && \
    set-cont-env DEBIAN_FRONTEND "noninteractive" && \
    set-cont-env LANG "de_DE.UTF-8" &&  \
    true


# Set public environment variables.
# Timezone can be overwritten via docker environment variable
ENV TZ=Europe/Berlin
# 1180x720 is absolute minimum
ENV DISPLAY_WIDTH="1280"
ENV DISPLAY_HEIGHT="768"
ENV TIME_START="13:00"
ENV TIME_END="23:00"


VOLUME /config/xdg/config/Breitbandmessung
