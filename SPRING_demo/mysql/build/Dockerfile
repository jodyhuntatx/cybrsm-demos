FROM alpine:latest

RUN apk update		\
    && apk add 		\
	bash curl vim	\
	mysql-client	\
    && curl -LO https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64			\
    && chmod a+x jq-linux64 										\
    && mv jq-linux64 /usr/local/bin/jq									\
    && mv /etc/vim/vimrc /etc/vim/vimrc.bak 

# install Summon and the Summon-conjur provider
RUN cd /tmp 				\
    && curl -LO https://github.com/cyberark/summon/releases/download/v0.6.7/summon-linux-amd64.tar.gz			\
    && tar xzf summon-linux-amd64.tar.gz && mv summon /usr/local/bin/							\
    && rm summon-linux-amd64.tar.gz	\
    && mkdir -p /usr/local/lib/summon	\
    && curl -LO https://github.com/cyberark/summon-conjur/releases/download/v0.5.2/summon-conjur-linux-amd64.tar.gz	\
    && tar xzf summon-conjur-linux-amd64.tar.gz && mv summon-conjur /usr/local/lib/summon/				\
    && rm summon-conjur-linux-amd64.tar.gz

COPY secrets.yml secrets_echo.sh /
