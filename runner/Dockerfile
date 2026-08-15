FROM        --platform=$TARGETOS/$TARGETARCH myoung34/github-runner:latest

LABEL       author="monci@yuemi.org"
LABEL       org.opencontainers.image.source="https://github.com/YueMi-Development/Pterodactyl-Github-Runners-Eggs"
LABEL       org.opencontainers.image.licenses=MIT

USER        root

# Create the container user to align with Pterodactyl's permission requirements
RUN         useradd -d /home/container -m container

# Pterodactyl runs the container with a read-only root filesystem and
# `no-new-privileges`, so no action (or sudo) can write to system paths at
# runtime. Redirect the standard system write locations into the writable
# /home/container volume via symlinks. Any existing base-image content is
# preserved by copying it into the target first.
RUN         set -eux; \
            ROOT=/home/container; \
            # mkdir -p all target parents first
            mkdir -p \
                "$ROOT/run" \
                "$ROOT/etc" \
                "$ROOT/var/lib" \
                "$ROOT/var/cache" \
                "$ROOT/usr/local" \
                "$ROOT/opt"; \
            # --- /run/php ---
            mkdir -p "$ROOT/run/php"; \
            ln -sfn "$ROOT/run/php" /run/php; \
            # --- /etc/php ---
            mkdir -p "$ROOT/etc/php"; \
            ln -sfn "$ROOT/etc/php" /etc/php; \
            # --- /var/lib/php ---
            mkdir -p "$ROOT/var/lib/php"; \
            ln -sfn "$ROOT/var/lib/php" /var/lib/php; \
            # --- /usr/local/* (preserve existing content) ---
            for d in bin lib share; do \
                if [ -d "/usr/local/$d" ]; then \
                    mkdir -p "$ROOT/usr/local/$d"; \
                    cp -a "/usr/local/$d/." "$ROOT/usr/local/$d/"; \
                    rm -rf "/usr/local/$d"; \
                fi; \
                ln -sfn "$ROOT/usr/local/$d" "/usr/local/$d"; \
            done; \
            # --- apt / dpkg (preserve existing content) ---
            for d in /var/lib/apt /var/cache/apt /var/lib/dpkg /etc/apt; do \
                name=$(basename "$d"); \
                if [ -e "$d" ]; then \
                    mkdir -p "$ROOT$d"; \
                    cp -a "$d/." "$ROOT$d/"; \
                    rm -rf "$d"; \
                fi; \
                mkdir -p "$ROOT$d"; \
                ln -sfn "$ROOT$d" "$d"; \
            done; \
            # --- /opt (preserve existing content) ---
            if [ -e /opt ]; then \
                cp -a /opt/. "$ROOT/opt/"; \
                rm -rf /opt; \
            fi; \
            ln -sfn "$ROOT/opt" /opt; \
            # ensure everything is owned by the container user
            chown -R container:container "$ROOT"

# Copy our custom entrypoint wrapper
COPY        ./entrypoint.sh /pterodactyl-entrypoint.sh
RUN         chmod +x /pterodactyl-entrypoint.sh

# Replace the system's real sudo binary with a dummy wrapper
# This fixes "sudo: effective uid is not 0" errors when actions call /usr/bin/sudo directly
RUN         mv /usr/bin/sudo /usr/bin/sudo.real || true
COPY        ./libs/sudo-wrapper.sh /usr/bin/sudo
RUN         chmod +x /usr/bin/sudo

ENTRYPOINT  ["/usr/bin/dumb-init", "--", "/pterodactyl-entrypoint.sh"]
