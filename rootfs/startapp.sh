#!/bin/bash

# --force-renderer-accessibility makes Electron publish its widget tree on the
# accessibility bus, which is how the automation service drives the app.
exec breitbandmessung --no-sandbox --force-renderer-accessibility
