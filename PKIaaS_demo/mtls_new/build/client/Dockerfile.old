
FROM alpine:latest
RUN apk add --no-cache \
    vim \
    openssl \
    bash \
    curl

RUN curl -LO https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 \
  && chmod a+x jq-linux64 \
  && mv jq-linux64 /usr/local/bin/jq

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

ADD conjur* /etc/
ADD secrets.yml connect.sh sleep_forever.sh /
RUN chmod 440 /etc/conjur.identity
ENTRYPOINT [ "/sleep_forever.sh" ]
