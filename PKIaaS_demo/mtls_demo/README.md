# Mutual TLS with PKIaaS and Conjur/DAP

This example demonstrates using the PKI service as certificate authority (CA) to configure
two hosts with X.509 certificates for mutual TLS authentication. The hosts
used for this example are an nginx web server and a cUrl web client.

The client and server certs are created & signed by the self-signed intermediate cert
and stored in Conjur. The server certs are used to build the nginx container. The client
certs are dynamically retrieved using Summon to pull them into memory-mapped files
in the client container.

### Prerequisites

1. docker
2. docker-compose

### Getting Started

1. run the start script:
   ```./start```

2. in the client, use Summon to run the connect.sh script:
    ```$ summon ./connect.sh```

3. when the client cert expires, exit the client and refresh the cert:
    ```./0_gen_certs.sh client```

4. exec back into the client and run the connection test again:
    ```
    $ ./exec-into-client.sh
    # summon ./connect.sh
    ```
