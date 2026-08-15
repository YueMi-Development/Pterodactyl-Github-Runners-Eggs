#!/usr/bin/env bash
# Pterodactyl runs containers with `no-new-privileges` and a read-only root
# filesystem, so a real sudo binary cannot elevate privileges. System write
# paths are instead symlinked into the writable /home/container volume at build
# time (see Dockerfile). Run the command directly as the current user; do not
# silently mock or swallow failures.
exec "$@"
