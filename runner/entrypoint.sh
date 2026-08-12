#!/bin/bash
set -e

# Define directories
RUNNER_DIR="/home/container/actions-runner"
export HOME="/home/container"

# Copy runner files to writable workspace if not already present
if [ ! -d "${RUNNER_DIR}" ]; then
    echo "Copying runner files to writable workspace (${RUNNER_DIR})..."
    mkdir -p "${RUNNER_DIR}"
    cp -r /actions-runner/* "${RUNNER_DIR}/"
fi

cd "${RUNNER_DIR}"

# Force clean runner configuration at startup if ephemeral mode is active
if [ "${EPHEMERAL}" = "1" ] || [ "${EPHEMERAL}" = "true" ]; then
    echo "Ephemeral mode enabled. Clearing existing runner configuration to force clean registration..."
    rm -f .runner .credentials .credentials_rsaparams .path .env
fi


# Export Pterodactyl environment variables
export RUNNER_NAME="${RUNNER_NAME:-pterodactyl-runner}"
export RUNNER_WORK_DIR="${RUNNER_WORK_DIR:-_work}"

# Determine runner scope and target URL
if [ -n "${RUNNER_REPOSITORY}" ]; then
    REG_URL="https://api.github.com/repos/${RUNNER_REPOSITORY#https://github.com/}/actions/runners/registration-token"
    CONFIG_URL="${RUNNER_REPOSITORY}"
elif [ -n "${RUNNER_ORGANIZATION}" ]; then
    # Clean org name if full URL was provided
    ORG_NAME="${RUNNER_ORGANIZATION#https://github.com/}"
    REG_URL="https://api.github.com/orgs/${ORG_NAME}/actions/runners/registration-token"
    CONFIG_URL="https://github.com/${ORG_NAME}"
else
    echo "ERROR: Either RUNNER_REPOSITORY or RUNNER_ORGANIZATION must be provided."
    exit 1
fi

# Obtain registration token if runner is not configured yet
if [ ! -f ".runner" ]; then
# Loop indefinitely to keep the Pterodactyl container alive
while true; do
    # Force clean runner configuration if ephemeral mode is active
    if [ "${EPHEMERAL}" = "1" ] || [ "${EPHEMERAL}" = "true" ]; then
        echo "Ephemeral mode active. Clearing old runner configuration..."
        rm -f .runner .credentials .credentials_rsaparams .path .env
    fi

    # Obtain registration token if runner is not configured yet
    if [ ! -f ".runner" ]; then
        if [ -z "${ACCESS_TOKEN}" ]; then
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "ERROR: GitHub Access Token (ACCESS_TOKEN) is not set."
            echo "Please set your Personal Access Token (PAT) in Pterodactyl"
            echo "Panel under the Startup settings to register the runner."
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            # In ephemeral loop, we sleep and retry instead of exiting to prevent container crashes
            sleep 10
            continue
        fi

        echo "Obtaining runner registration token from GitHub..."
        
        RESPONSE=$(curl -sX POST \
            -H "Accept: application/vnd.github.v3+json" \
            -H "Authorization: token ${ACCESS_TOKEN}" \
            "${REG_URL}")
        
        REG_TOKEN=$(echo "${RESPONSE}" | grep -o '"token": "[^"]*' | grep -o '[^"]*$')

        if [ -z "${REG_TOKEN}" ]; then
            echo "ERROR: Failed to retrieve registration token from GitHub API."
            echo "API Response: ${RESPONSE}"
            sleep 10
            continue
        fi

        echo "Configuring GitHub Actions Runner..."
        EXTRA_ARGS=""
        if [ "${EPHEMERAL}" = "1" ] || [ "${EPHEMERAL}" = "true" ]; then
            EXTRA_ARGS="--ephemeral"
        fi

        ./config.sh --unattended \
            --url "${CONFIG_URL}" \
            --token "${REG_TOKEN}" \
            --name "${RUNNER_NAME}" \
            --work "${RUNNER_WORK_DIR}" \
            ${LABELS:+--labels "${LABELS}"} \
            ${EXTRA_ARGS} \
            --replace
    fi

    # Start the runner
    echo "Starting GitHub Actions Runner..."
    START_TIME=$(date +%s)

    # Run the runner and catch exit status
    set +e
    ./run.sh
    EXIT_CODE=$?
    set -e

    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    # If not in ephemeral mode and it exited too quickly, something is wrong (invalid credentials, etc.)
    if [ "${EPHEMERAL}" != "1" ] && [ "${EPHEMERAL}" != "true" ] && [ ${DURATION} -lt 15 ]; then
        echo "ERROR: Runner exited too quickly (${DURATION} seconds)."
        echo "Clearing local runner configuration..."
        rm -f .runner .credentials .credentials_rsaparams .path .env
        sleep 10
    fi

    # If in ephemeral mode, clean up after the job exits
    if [ "${EPHEMERAL}" = "1" ] || [ "${EPHEMERAL}" = "true" ]; then
        echo "Ephemeral job completed. Waiting 3 seconds before spawning next runner..."
        sleep 3
    else
        # If not ephemeral, respect standard exit behavior of the runner process
        echo "Runner stopped with exit code ${EXIT_CODE}."
        exit ${EXIT_CODE}
    fi
done



