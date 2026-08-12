# Pterodactyl GitHub Actions Runners Egg

A custom Pterodactyl Egg and Docker image to run self-hosted GitHub Actions runners inside Pterodactyl Panel.

## Features
- Runs inside writable `/home/container/actions-runner` (bypasses read-only root filesystems).
- Runs under user `container` (bypasses unprivileged user permission errors).
- Built automatically via GitHub Actions and published to GHCR.

## Usage
1. Import `egg-github-runners.json` into your Pterodactyl Panel (Nests -> Import Egg).
2. Create a server using the egg and fill in your runner variables.

## Known Limitations

- **Docker Socket Access**: If your workflows use service containers (e.g., test databases) or build Docker images, you must mount `/var/run/docker.sock` into the container. Because Pterodactyl runs the container as user `container` (UID `996`), you must follow these steps to configure it:
  1. **Host Permissions**: SSH into your node host and run `sudo chmod 666 /var/run/docker.sock`.
  2. **Wings Configuration**: Add `/var/run/docker.sock` under `allowed_mounts` in `/etc/pterodactyl/config.yml` on the host, then run `sudo systemctl restart wings`.
  3. **Create Mount in Panel**: Go to Admin Panel -> Mounts, and create a mount with Source `/var/run/docker.sock` and Target `/var/run/docker.sock`.
  4. **Assign to Server**: Go to Admin Panel -> Servers -> [Your Server] -> Mounts, and assign the mount.
  5. **Rebuild Container**: Fully Stop and then Start the runner server in Pterodactyl.
- **Linux Only**: Only Linux-based runners are supported. macOS or Windows runners cannot be containerized inside Pterodactyl due to Docker and Pterodactyl host limitations.
- **1 Job per Runner**: A single runner container can only execute one workflow job at a time. If you need parallel executions, scale out by creating multiple runner servers in Pterodactyl.
