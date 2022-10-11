FROM openresty/openresty:alpine

RUN apk update 		\
    && apk add		\
	vim		\
	jq		\
	curl		\
    && mkdir -p /conjur

ADD tls* /conjur/
RUN chmod 440 /conjur/tls*
ADD nginx.conf /etc/nginx/conf.d/
ADD index.html /
