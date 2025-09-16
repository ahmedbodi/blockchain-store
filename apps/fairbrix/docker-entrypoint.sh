#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for fairbrixd"

  set -- fairbrixd "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "fairbrixd" ]; then
  mkdir -p "$FAIRBRIX_DATA"
  chmod 700 "$FAIRBRIX_DATA"
  chown -R fairbrix "$FAIRBRIX_DATA"

  echo "$0: setting data directory to $FAIRBRIX_DATA"

  set -- "$@" -datadir="$FAIRBRIX_DATA"
fi

if [ "$1" = "fairbrixd" ] || [ "$1" = "fairbrix-cli" ] || [ "$1" = "fairbrix-tx" ]; then
  echo
  exec su-exec fairbrix "$@"
fi

echo
exec "$@"
