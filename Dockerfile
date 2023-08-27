# Pull base image.
FROM jlesage/baseimage-gui:ubuntu-20.04

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
RUN \
    echo $APP_VERSION && \
    APP_ICON_URL=https://www.breitbandmessung.de/public/images/appicon-512.png && \
    APP_ICON_DESC='{"masterPicture":"/opt/novnc/images/icons/master_icon.png","iconsPath":"/images/icons/","design":{"ios":{"pictureAspect":"backgroundAndMargin","backgroundColor":"#ffffff","margin":"14%","assets":{"ios6AndPriorIcons":false,"ios7AndLaterIcons":false,"precomposedIcons":false,"declareOnlyDefaultIcon":true}},"desktopBrowser":{},"windows":{"pictureAspect":"noChange","backgroundColor":"#2d89ef","onConflict":"override","assets":{"windows80Ie10Tile":false,"windows10Ie11EdgeTiles":{"small":false,"medium":true,"big":false,"rectangle":false}}},"androidChrome":{"pictureAspect":"noChange","themeColor":"#ffffff","manifest":{"display":"standalone","orientation":"notSet","onConflict":"override","declared":true},"assets":{"legacyIcon":false,"lowResolutionIcons":false}},"safariPinnedTab":{"pictureAspect":"silhouette","themeColor":"#5bbad5"}},"settings":{"scalingAlgorithm":"Mitchell","errorOnImageTooSmall":false},"versioning":{"paramName":"v","paramValue":"ICON_VERSION"}}' && \
    install_app_icon.sh "$APP_ICON_URL" "$APP_ICON_DESC"

# Copy the start script.
COPY startapp.sh /startapp.sh
COPY run-speedtest.sh /etc/services.d/speedtest/run
COPY 50-install-latest-breitbandmessung.sh /etc/cont-init.d/


# Set the name of the application.
ENV APP_NAME="Breitbandmessung"

VOLUME /config/xdg/config/Breitbandmessung
