#!/usr/bin/env bash
for arg in "$@"; do
  if [[ "$arg" == "/run/"* ]]; then
    echo "Mocking command for read-only path: $*"
    exit 0
  fi
done
exec "$@"
