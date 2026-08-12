#!/bin/bash

# Ensure variables are exported for the base runner script
export RUNNER_NAME="${RUNNER_NAME}"
export ACCESS_TOKEN="${ACCESS_TOKEN}"
export RUNNER_REPOSITORY="${RUNNER_REPOSITORY}"
export RUNNER_ORGANIZATION="${RUNNER_ORGANIZATION}"
export LABELS="${LABELS}"
export RUNNER_TOKEN="${RUNNER_TOKEN}"
export RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-_work}"

# Execute the base image's entrypoint script
exec /entrypoint.sh "$@"
