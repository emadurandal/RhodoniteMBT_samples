#!/usr/bin/env sh
set -eu

if [ -d /opt/homebrew/include ]; then
  CPATH="/opt/homebrew/include${CPATH:+:$CPATH}"
fi

if [ -d /usr/local/include ]; then
  CPATH="/usr/local/include${CPATH:+:$CPATH}"
fi

export CPATH
exec moon run cmd/native --target native "$@"
