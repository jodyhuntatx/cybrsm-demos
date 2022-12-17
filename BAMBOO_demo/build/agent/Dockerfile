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

ENV BAMBOO_VERSION 9.1.0
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
ENV BAMBOO_HOME /home/bamboo

RUN mkdir -p /opt/bamboo \
    && cd /opt/bamboo \
    && wget -q --show-progress http://conjur-master-minikube:8085/agentServer/agentInstaller/atlassian-bamboo-agent-installer-${BAMBOO_VERSION}.jar \
    && java -jar atlassian-bamboo-agent-installer-${BAMBOO_VERSION}.jar http://conjur-master-minikube:8085/agentServer install

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
