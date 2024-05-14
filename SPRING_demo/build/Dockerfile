FROM cyberark/demo-app:latest
RUN apt-get update					\
    && apt-get install -y --no-install-recommends	\
    vim		\
    bash	\
    curl

# install Summon and the Summon-conjur provider
RUN cd /tmp \
    && curl -LO https://github.com/cyberark/summon/releases/download/v0.6.7/summon-linux-amd64.tar.gz \
    && tar xzf summon-linux-amd64.tar.gz && mv summon /usr/local/bin/ \
    && rm summon-linux-amd64.tar.gz \
    && mkdir -p /usr/local/lib/summon \
    && curl -LO https://github.com/cyberark/summon-conjur/releases/download/v0.5.2/summon-conjur-linux-amd64.tar.gz \
    && tar xzf summon-conjur-linux-amd64.tar.gz && mv summon-conjur /usr/local/lib/summon/ \
    && rm summon-conjur-linux-amd64.tar.gz

ADD secrets.yml sleep_forever.sh /
ENTRYPOINT [ "/sleep_forever.sh" ]
