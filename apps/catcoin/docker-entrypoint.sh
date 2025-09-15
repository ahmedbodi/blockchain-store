#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for catcoind"

  set -- catcoind "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "catcoind" ]; then
  mkdir -p "$CATCOIN_DATA"
  chmod 700 "$CATCOIN_DATA"
  chown -R catcoin "$CATCOIN_DATA"

  echo "$0: setting data directory to $CATCOIN_DATA"

  set -- "$@" -datadir="$CATCOIN_DATA"
fi

if [ "$1" = "catcoind" ] || [ "$1" = "catcoin-cli" ] || [ "$1" = "catcoin-tx" ]; then
  echo
  exec su-exec catcoin "$@"
fi

echo
exec "$@"
