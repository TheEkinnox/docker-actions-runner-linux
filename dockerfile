# base image
FROM ubuntu:22.04

#input GitHub runner version argument
ARG RUNNER_VERSION
ENV DEBIAN_FRONTEND=noninteractive

LABEL Author="Loïck Noa Obiang Ndong"
LABEL Email="lnobiang@noxcorporation.net"
LABEL GitHub="https://github.com/TheEkinnox"
LABEL BaseImage="ubuntu:20.04"
LABEL RunnerVersion=${RUNNER_VERSION}

# update the base packages + add a non-sudo user
RUN apt-get update -y && apt-get upgrade -y && useradd -m docker

# install the packages and dependencies along with jq so we can parse JSON (add additional packages as necessary)
RUN apt-get install -y --no-install-recommends \
    curl nodejs wget unzip vim git jq build-essential clang xorg-dev libglu1-mesa-dev libssl-dev libffi-dev python3 python3-venv python3-dev python3-pip

# cd into the user directory, download and unzip the github actions runner
RUN cd /home/docker && mkdir actions-runner && cd actions-runner \
    && curl -o actions-runner.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
    && mkdir tmp && tar xzf ./actions-runner.tar.gz -C tmp

# install some additional dependencies and get rid of the temporary folder
RUN chown -R docker ~docker && /home/docker/actions-runner/tmp/bin/installdependencies.sh \
    && rm -rf /home/docker/actions-runner/tmp

# add over the start.sh script
ADD scripts/start.sh start.sh

# make the script executable
RUN chmod +x start.sh

# set the user to "docker" so all subsequent commands are run as the docker user
USER docker
CMD /bin/bash

# set the entrypoint to the start.sh script
ENTRYPOINT ["./start.sh"]