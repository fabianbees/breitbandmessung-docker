#!/bin/bash

# --force-renderer-accessibility makes Electron publish its widget tree on the
# accessibility bus, which is how the automation service drives the app.
FLAGS="--no-sandbox --force-renderer-accessibility --disable-dev-shm-usage --ignore-gpu-blocklist"

# On x86_64 the package installs its own Electron runtime and a launcher.
if command -v breitbandmessung >/dev/null 2>&1
then
    exec breitbandmessung $FLAGS
fi

# Everywhere else the same application code runs on the Electron runtime that
# was installed into the image instead.
if [ -x /opt/electron/breitbandmessung ] && [ -f /opt/Breitbandmessung/resources/app.asar ]
then
    exec /opt/electron/breitbandmessung /opt/Breitbandmessung/resources/app.asar $FLAGS
fi

echo "Breitbandmessung is not installed correctly: no launcher for $(uname -m)." >&2
exit 1
