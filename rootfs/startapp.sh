#!/bin/sh
#
# NOTE: Parameters to pass to Breitbandmessung are defined via the `params` file of the
#       app service.
#

rm -rf /config/xdg/config/Breitbandmessung/Singleton*

exec breitbandmessung "$@"
