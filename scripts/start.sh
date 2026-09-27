#!/bin/bash

source /home/docker/.env

REG_TOKENS=()

IFS=',' read -ra REPOS <<< "${GH_REPOSITORY}"

cleanup() {
    for (( i=0; i<${#REPOS[@]}; ++i)); do
        REPOSITORY="${REPOS[$i]}"
        TOKEN="${REG_TOKENS[$i]}"

        echo "Removing ${REPOSITORY} runner..."
        /home/docker/actions-runner/runner-${REPOSITORY}/config.sh remove --unattended --token ${TOKEN}
    done
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

for (( i=0; i<${#REPOS[@]}; ++i)); do
    REPOSITORY="${REPOS[$i]}"
    echo Setting up ${REPOSITORY}...

    RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
    RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"
    REG_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GH_TOKEN}" -H "X-GitHub-Api-Version: 2026-03-10" https://api.github.com/repos/${GH_OWNER}/${REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)

    mkdir -p /home/docker/actions-runner/runner-${REPOSITORY}
    cd /home/docker/actions-runner/runner-${REPOSITORY}
    tar -xzf ../actions-runner.tar.gz -C /home/docker/actions-runner/runner-${REPOSITORY}

	echo Removing existing...
    ./config.sh remove --token ${REG_TOKEN}

	echo Reconfiguring...
    ./config.sh --unattended --url https://github.com/${GH_OWNER}/${REPOSITORY} --token ${REG_TOKEN} --name ${RUNNER_NAME}

    REG_TOKENS+=( ${REG_TOKEN} )

	echo Running...
    if [ $(($i + 1)) -lt ${#REPOS[@]} ]; then
        ./run.sh &
    else
        ./run.sh & wait $!
    fi
done
