FROM openresty/openresty:alpine

RUN apk update 			\
    && apk add --no-cache	\
	vim			\
	jq			\
	curl

ENV TZ America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install Summon and the Summon-conjur provider
RUN cd /tmp \
    && curl -LO https://github.com/cyberark/summon/releases/download/v0.6.7/summon-linux-amd64.tar.gz \
    && tar xzf summon-linux-amd64.tar.gz && mv summon /usr/local/bin/ \
    && rm summon-linux-amd64.tar.gz \
    && mkdir -p /usr/local/lib/summon \
    && curl -LO https://github.com/cyberark/summon-conjur/releases/download/v0.5.2/summon-conjur-linux-amd64.tar.gz \
    && tar xzf summon-conjur-linux-amd64.tar.gz && mv summon-conjur /usr/local/lib/summon/ \
    && rm summon-conjur-linux-amd64.tar.gz

# NGINX config for endpoints
ADD nginx.conf /etc/nginx/conf.d/
ADD index.html /

# TLS certs from PKIaaS
RUN mkdir -p /conjur
ADD tls* /conjur/
RUN chmod 440 /conjur/tls*

# Script for refreshCerts endpoint
RUN mkdir -p /usr/local/openresty/nginx/html/refreshCerts
ADD refreshCerts.sh secrets.yml /usr/local/openresty/nginx/html/refreshCerts/

# Conjurization files
ADD conjur* /etc/
RUN chmod 440 /etc/conjur.identity
