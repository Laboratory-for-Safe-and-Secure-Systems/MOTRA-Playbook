#!/usr/bin/env bash

# setup tmux to keep the connection up between updates
session="bootstrap-motra"
PROJECT_ROOT=$(realpath .)

check_command() {
    local cmd="$1"
    if command -v "$cmd" &> /dev/null; then
        return 0 # Success
    else
        echo "$cmd is not available"
        return 1 # Failure
    fi
}

# are all required commands present
check_command "git" || exit 1
check_command "curl" || exit 1
check_command "tmux" || exit 1

# Check if the --internal flag is present.
if [ "$1" == "--internal" ]; then
    # --- THIS CODE RUNS INSIDE TMUX ---
    echo "*************************************"
    echo "*** I AM NOW RUNNING INSIDE TMUX! ***"
    echo "*************************************"
    # we continue after this block with the normal bootstrapping operations
else
    # --- THIS CODE RUNS OUTSIDE TMUX ---
    echo "--- Starting bootstrap script outside tmux. ---"

    # Check if tmux is installed
    if ! command -v tmux &> /dev/null; then
        echo "Error: tmux is not installed."
        exit 1
    fi

    echo "--- Creating new session and re-launching script inside. ---"

    # Re-execute this same script ($0) with the --internal flag inside a new session
    tmux new-session -s "$session" "bash $0 --internal"
    exit 0
fi

# Check if the effective user ID is 0 (root)
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    echo "Please use 'sudo ./your_script.sh' or run as the root user." >&2
    exit 1
fi

# perform generic updates
apt update && export DEBIAN_FRONTEND=noninteractive && sudo apt upgrade -y


# setup PYTHON specific stuff + POETRY
POETRY_HOME=${POETRY_HOME:-/opt/poetry} 
POETRY_VERSION=${POETRY_VERSION:-"2.1.2"} 
mkdir -p $POETRY_HOME
chown $(id -u):$(id -g) $POETRY_HOME
python3 -m venv $POETRY_HOME
$POETRY_HOME/bin/pip install poetry==$POETRY_VERSION

poetry="$POETRY_HOME/bin/poetry"
$poetry --version

# install docker system wide 
# turn off, in case we install the Playbook inside a container
ENABLE_DOCKER_SUPPORT=${ENABLE_DOCKER_SUPPORT:-"false"}
if [[ "$ENABLE_DOCKER_SUPPORT" == "true" ]]; then
    echo "##### Starting Setup: Docker "
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh ./get-docker.sh 
    rm get-docker.sh
    check_command "docker" || exit 1
    echo "##### .... Done "
fi


# setup the meta packages required for testing/hacking
echo "##### Starting Setup: Meta Packages "
export DEBIAN_FRONTEND=noninteractive
apt install -y ./meta/apt/motra-networking_1.0_all.deb
apt install -y ./meta/apt/motra-hacking_1.0_all.deb
echo "##### .... Done "


# fetch and setup the required git/external sources
echo "##### Setting up gitman "
eval $($poetry -P meta env activate)
cd meta/gitman
# gitman install motra
# gitman install motra-private
gitman install opc-tools
gitman install seclists
gitman install recon
gitman install exploit
cd $PROJECT_ROOT

echo "##### .... Done "

echo "##### finished bootstrapping MOTRA "

exec bash
