FROM ubuntu:20.04

# install utilities
RUN apt-get update -y \
    && apt-get install -y \
    vim \
    ssh \
    curl \
    wget \
    unzip

# install Python
ENV PYTHONUNBUFFERED=1
RUN apt-get update -y             \
    && apt-get install -y python3 python3-pip \
    && ln -sf python3 /usr/bin/python
RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y python3-venv
RUN pip3 install --no-cache --upgrade pip setuptools requests

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /demo

COPY anun-env.sh github-scan.sh gitlab-scan.sh /demo
