FROM ubuntu:16.04

ENV VCERT_VERSION=4.17.0

# install utilities & ansible
RUN apt-get update -y \
    && apt-get install -y \
    vim \
    ssh \
    curl \
    wget \
    unzip

RUN curl -LO https://github.com/Venafi/vcert/releases/download/v${VCERT_VERSION}/vcert_v${VCERT_VERSION}_linux.zip		\
  && unzip vcert_v${VCERT_VERSION}_linux.zip	\
  && mv vcert /usr/local/bin

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /demo
