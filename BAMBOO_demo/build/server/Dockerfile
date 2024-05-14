FROM ubuntu:20.04

# install utilities and dependencies
RUN apt-get update -y \
    && apt-get install -y \
    	    vim \
	    ssh \
	    ant \
	    curl \
	    wget \
	    unzip \
	    gnupg2 \
	    daemon \
	    psmisc  \
	    net-tools \
	    apt-utils \
	    openjdk-11-jre-headless \
    && apt update -y

ENV BAMBOO_VERSION 9.0.1
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
ENV BAMBOO_HOME /home/bamboo

RUN mkdir -p /opt/bamboo \
    && cd /opt/bamboo \
    && wget -q --show-progress https://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz \
    && tar xvf atlassian-bamboo-${BAMBOO_VERSION}.tar.gz \
    && rm atlassian-bamboo-${BAMBOO_VERSION}.tar.gz

RUN ln -nfs /opt/bamboo/atlassian-bamboo-${BAMBOO_VERSION} /opt/bamboo/current \
    && useradd --create-home --home-dir /usr/local/bamboo --shell /bin/bash bamboo \
    && chown -R bamboo:bamboo /opt/bamboo/* \
    && echo "bamboo.home=/home/bamboo" >> /opt/bamboo/current/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
