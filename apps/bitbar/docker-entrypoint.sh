#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for bitbard"

  set -- bitbard "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "bitbard" ]; then
  mkdir -p "$BITBAR_DATA"
  chmod 700 "$BITBAR_DATA"
  chown -R bitbar "$BITBAR_DATA"

  echo "$0: setting data directory to $BITBAR_DATA"

  set -- "$@" -datadir="$BITBAR_DATA"
fi

if [ "$1" = "bitbard" ]; then
  echo
  exec gosu bitbar "$@"
fi

echo
exec "$@"
