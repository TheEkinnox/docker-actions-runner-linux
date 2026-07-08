#!/bin/bash

GH_OWNER=$GH_OWNER
GH_REPOSITORY=$GH_REPOSITORY
GH_TOKEN=$GH_TOKEN

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
    RUNNER_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)
    RUNNER_NAME="dockerNode-${RUNNER_SUFFIX}"
    REG_TOKEN=$(curl -sX POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GH_TOKEN}" https://api.github.com/repos/${GH_OWNER}/${REPOSITORY}/actions/runners/registration-token | jq .token --raw-output)

    mkdir -p /home/docker/actions-runner/runner-${REPOSITORY}
    cd /home/docker/actions-runner/runner-${REPOSITORY}
    tar -xzf ../actions-runner.tar.gz -C /home/docker/actions-runner/runner-${REPOSITORY}

    ./config.sh remove --unattended --token ${REG_TOKEN}
    ./config.sh --unattended --url https://github.com/${GH_OWNER}/${REPOSITORY} --token ${REG_TOKEN} --name ${RUNNER_NAME}

    REG_TOKENS+=( ${REG_TOKEN} )

    if [ $(($i + 1)) -lt ${#REPOS[@]} ]; then
        ./run.sh &
    else
        ./run.sh & wait $!
    fi
done