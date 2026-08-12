FROM        --platform=$TARGETOS/$TARGETARCH myoung34/github-runner:latest

LABEL       author="monci@yuemi.org"
LABEL       org.opencontainers.image.source="https://github.com/YueMi-Development/Pterodactyl-Github-Runners-Eggs"
LABEL       org.opencontainers.image.licenses=MIT

USER        root

# Create the container user to align with Pterodactyl's permission requirements
RUN         useradd -d /home/container -m container

# Copy our custom entrypoint wrapper
COPY        ./entrypoint.sh /pterodactyl-entrypoint.sh
RUN         chmod +x /pterodactyl-entrypoint.sh

ENTRYPOINT  ["/usr/bin/dumb-init", "--", "/pterodactyl-entrypoint.sh"]
