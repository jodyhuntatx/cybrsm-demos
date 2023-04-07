FROM ubuntu:20.04

ENV TF_VERSION=0.11.14
ENV TF_PROVIDER_VERSION=0.2.0

# install utilities & ansible
RUN apt-get update -y \
    && apt-get install -y \
    vim \
    ssh \
    curl \
    wget \
    unzip

ENV PYTHONUNBUFFERED=1
RUN apt-get update -y             \
    && apt-get install -y python3 python3-pip ansible \
    && ln -sf python3 /usr/bin/python
#RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools requests

RUN curl -LO https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
  && chmod a+x jq-linux64 \
  && mv jq-linux64 /usr/local/bin/jq

# install Ansible lookup plugin from local tarfile
COPY ansible-conjur-lookup-plugin.tar.gz /tmp
RUN  mkdir -p /etc/ansible/roles \
     && cd /etc/ansible/roles \
     && tar xvf /tmp/ansible-conjur-lookup-plugin.tar.gz -C . \
     && mv ansible-conjur-lookup-plugin-master cyberark.conjur-lookup-plugin

# install chef 
RUN cd /tmp \
    && curl -L https://www.opscode.com/chef/install.sh | bash \
    && mkdir /var/chef 

# install Summon and the Summon-conjur provider
RUN cd /tmp \
    && curl -LO https://github.com/cyberark/summon/releases/download/v0.6.7/summon-linux-amd64.tar.gz \
    && tar xzf summon-linux-amd64.tar.gz && mv summon /usr/local/bin/ \
    && rm summon-linux-amd64.tar.gz \
    && mkdir -p /usr/local/lib/summon \
    && curl -LO https://github.com/cyberark/summon-conjur/releases/download/v0.5.2/summon-conjur-linux-amd64.tar.gz \
    && tar xzf summon-conjur-linux-amd64.tar.gz && mv summon-conjur /usr/local/lib/summon/ \
    && rm summon-conjur-linux-amd64.tar.gz

# install terraform & terraform provider
RUN cd /tmp \
    && curl -O https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
    && unzip terraform_${TF_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin \
    && rm terraform*.zip \
    && wget https://github.com/cyberark/terraform-provider-conjur/releases/download/v${TF_PROVIDER_VERSION}/terraform-provider-conjur-linux-amd64.tar.gz \
    && tar xvzf terraform-provider-conjur-linux-amd64.tar.gz \
    && rm terraform-provider-conjur-linux-amd64.tar.gz \
    && mkdir -p ~/.terraform.d/plugins \
    && mv terraform-provider-conjur ~/.terraform.d/plugins \
    && echo foo

# install AWS CLI
RUN pip install awscli --upgrade --user

RUN echo "root:demo" | chpasswd		# set demo as root password

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /demo
