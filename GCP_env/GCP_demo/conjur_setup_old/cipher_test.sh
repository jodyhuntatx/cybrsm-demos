#!/bin/bash
if [[ "$#" != 2 ]]; then
  echo "Usage: $0 <hostname> <port>"
  exit -1
fi

HOSTNAME=$1
PORT=$2

echo "Testing ciphers for host \"$HOSTNAME\" and port \"$PORT\"."

for v in ssl2 ssl3 tls1 tls1_1 tls1_2 tls1_3; do
 for c in $(openssl ciphers 'ALL:eNULL' | tr ':' ' '); do
 openssl s_client -connect $HOSTNAME:$PORT \
 -cipher $c -$v < /dev/null > /dev/null 2>&1 && echo -e "$v:\t$c"
 done
done
