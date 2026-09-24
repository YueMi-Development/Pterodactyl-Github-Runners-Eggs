FROM        --platform=$TARGETOS/$TARGETARCH myoung34/github-runner:latest

LABEL       author="monci@yuemi.org"
LABEL       org.opencontainers.image.source="https://github.com/YueMi-Development/Pterodactyl-Github-Runners-Eggs"
LABEL       org.opencontainers.image.licenses=MIT

USER        root

# Create the container user to align with Pterodactyl's permission requirements
RUN         useradd -d /home/container -m container

# Copy our custom entrypoint wrapper and helper scripts
COPY        ./entrypoint.sh /pterodactyl-entrypoint.sh
COPY        ./libs/cleanup.sh /pterodactyl-cleanup.sh
RUN         chmod +x /pterodactyl-entrypoint.sh /pterodactyl-cleanup.sh

# Replace the system's real sudo binary with a dummy wrapper
# This fixes "sudo: effective uid is not 0" errors when actions call /usr/bin/sudo directly
RUN         mv /usr/bin/sudo /usr/bin/sudo.real || true
COPY        ./libs/sudo-wrapper.sh /usr/bin/sudo
RUN         chmod +x /usr/bin/sudo

ENTRYPOINT  ["/usr/bin/dumb-init", "--", "/pterodactyl-entrypoint.sh"]
