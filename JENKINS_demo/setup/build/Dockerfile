FROM ubuntu:20.04

# install utilities and dependencies
RUN apt-get update -y \
    && apt-get install -y \
    	    vim \
	    ssh \
	    curl \
	    wget \
	    unzip \
	    gnupg2 \
	    daemon \
	    psmisc  \
	    net-tools \
	    apt-utils \
	    openjdk-11-jre-headless \
    && apt update -y \
    && apt install -y git

# add key to local repo
RUN curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key	\
    | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null		\
    && echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]	\
    https://pkg.jenkins.io/debian-stable binary/ | tee			\
    /etc/apt/sources.list.d/jenkins.list > /dev/null

# install cloudbees jenkins
RUN apt-get update -y \
    && apt-get install -y jenkins

# install cybr cli
RUN curl -LO https://github.com/infamousjoeg/cybr-cli/releases/download/v0.1.10-beta/cybr-v0.1.10-beta-linux-amd64.tar.gz \
    && tar xvf cybr-v0.1.10-beta-linux-amd64.tar.gz \
    && mv /cybr /usr/local/bin

# set demo as root password
RUN echo "root:demo" | chpasswd		

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# mountpoint for host subdirectory of same name w/ demo contents in container
WORKDIR /demo
