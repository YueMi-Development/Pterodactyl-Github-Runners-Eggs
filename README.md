# Pterodactyl GitHub Actions Runners Egg

A custom Pterodactyl Egg and Docker image to run self-hosted GitHub Actions runners inside Pterodactyl Panel.

## Features
- Runs inside writable `/home/container/actions-runner` (bypasses read-only root filesystems).
- Runs under user `container` (bypasses unprivileged user permission errors).
- Built automatically via GitHub Actions and published to GHCR.

## Usage
1. Import `egg-github-runners.json` into your Pterodactyl Panel (Nests -> Import Egg).
2. Create a server using the egg and fill in your runner variables.
