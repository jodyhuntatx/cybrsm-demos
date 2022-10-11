FROM jenkins/jenkins:lts

USER root

RUN     apt-get update &&\
        apt-get install -qy git apt-utils curl dpkg jq libexpat1-dev libpython2.7-dev python2.7-dev vim &&\
        apt-get install -f -qy &&\
        rm -rf /var/lib/apt/lists/*

USER jenkins
WORKDIR /demo
EXPOSE 8080 50000
