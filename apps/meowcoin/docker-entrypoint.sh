#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for meowcoind"

  set -- meowcoind "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "meowcoind" ]; then
  mkdir -p "$MEOWCOIN_DATA"
  chmod 700 "$MEOWCOIN_DATA"
  chown -R meowcoin "$MEOWCOIN_DATA"

  echo "$0: setting data directory to $MEOWCOIN_DATA"

  set -- "$@" -datadir="$MEOWCOIN_DATA"
fi

if [ "$1" = "meowcoind" ] || [ "$1" = "meowcoin-cli" ]; then
  echo
  exec su-exec meowcoin "$@"
fi

echo
exec "$@"
