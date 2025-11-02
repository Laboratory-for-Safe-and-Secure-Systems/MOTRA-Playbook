FROM debian:bookworm-slim AS builder 

# setup of the base image 
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=motra
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install \
        -y --no-install-recommends \
        git \
        build-essential debhelper bison check cmake flex groff libbsd-dev \
        libcurl4-openssl-dev libmaxminddb-dev libgtk-3-dev libltdl-dev libluajit-5.1-dev \
        libncurses5-dev libnet1-dev libpcap-dev libpcre2-dev libssl-dev \
        tldr \
        less \
        tmux \
        curl \
        tree \
        sudo \
        redis-tools \
        unzip \
        procps \
        python3 \
        python3-pip \
        pipx \
        python3.11-venv \
        python3-dev \
        ca-certificates && \
    # rm -rf /var/lib/apt/lists/* && \
    \
    # Create the non-root user and add to sudo group
    groupadd --gid "$USER_GID" "$USERNAME" && \
    useradd --uid "$USER_UID" --gid "$USER_GID" -m -s /bin/bash "$USERNAME" && \
    \
    # Configure passwordless sudo for the new user
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$USERNAME" && \
    chmod 0440 /etc/sudoers.d/"$USERNAME"

# setup PYTHON specific stuff + POETRY
ARG POETRY_HOME=/opt/poetry 
ENV POETRY_HOME=$POETRY_HOME
ARG POETRY_VERSION="2.1.2" 
RUN sudo mkdir -p $POETRY_HOME && \
    sudo chown $USER_UID:$USER_GID $POETRY_HOME && \
    python3 -m venv $POETRY_HOME && \
    $POETRY_HOME/bin/pip install poetry==$POETRY_VERSION

USER $USERNAME

# setup pipx with pathwrapping to allow custom tools to be run globally
RUN pipx ensurepath 

WORKDIR /home/$USERNAME/motra
ENV ENABLE_DOCKER_SUPPORT=false

# install meta-packages, these are isolated for testing
ENV DEBIAN_FRONTEND=noninteractive
COPY --chown=$USER_UID:$USER_GID meta/apt .apt
RUN sudo apt install -y ./.apt/motra-default_1.0_all.deb && \
    sudo apt install -y ./.apt/motra-database_1.0_all.deb && \
    sudo apt install -y ./.apt/motra-networking_1.0_all.deb && \
    sudo apt install -y ./.apt/motra-perf_1.0_all.deb && \
    sudo apt install -y ./.apt/motra-hacking_1.0_all.deb

# setup gitman to resolve all dependencies
COPY --chown=$USER_UID:$USER_GID meta/gitman .gitman
COPY --chown=$USER_UID:$USER_GID meta/pyproject.toml .gitman/pyproject.toml
RUN $POETRY_HOME/bin/poetry -P .gitman install && \
    cd .gitman && \
    # $POETRY_HOME/bin/poetry run gitman install motra && \
    $POETRY_HOME/bin/poetry run gitman install opc-tools && \
    $POETRY_HOME/bin/poetry run gitman install seclists && \
    $POETRY_HOME/bin/poetry run gitman install recon && \
    $POETRY_HOME/bin/poetry run gitman install exploit

# setup entrypoint
CMD [ "/bin/bash" ]
