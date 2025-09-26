#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for telestaid"

  set -- telestaid "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "telestaid" ]; then
  mkdir -p "$TELESTAI_DATA"
  chmod 700 "$TELESTAI_DATA"
  chown -R telestai "$TELESTAI_DATA"

  echo "$0: setting data directory to $TELESTAI_DATA"

  set -- "$@" -datadir="$TELESTAI_DATA"
fi

if [ "$1" = "telestaid" ] || [ "$1" = "telestai-cli" ]; then
  echo
  exec su-exec telestai "$@"
fi

echo
exec "$@"
