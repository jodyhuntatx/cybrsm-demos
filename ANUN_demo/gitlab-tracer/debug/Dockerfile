FROM ubuntu:20.04

# install utilities
RUN apt-get update -y \
    && apt-get install -y curl netcat \
    && ln -s /usr/bin/netcat /usr/bin/nc

RUN curl -O https://downloads.anun.cloud/tracer/pub/anun-installer.sh
RUN chmod +x ./anun-installer.sh
RUN ./anun-installer.sh -p "https://downloads.anun.cloud/tracer/anun-tracer.tar.gz?Expires=1686325253&Signature=PqAho0YRfQoB136vp0yYLh04S44pAMAcnxV6RLELeQ2KkF4JdgZx~jkuyCuYatTBzqKvu3J3M6wQlFeSOrDosoyI7RN6DnLrt9QyqoWlEPImWSLB2p9C3qzxZANHjz6u2d98WcjRZpM-7svbr7uqnWucoxqwU4KtzGPcYeUJC3ntMJ2~5WZk1t8lUyQMb~hJoht7MxdUCCbpZLaTgiOwyt8CpijOkQ3aQNeYbEXfR3g-dBfEgP1m7DU-s1~rTxZhauDcFc53QwjsFTysUPsB5uQChMKEvPXBWNytWhoaqqsH4gvItNpbFyja3kQ9cpOdhZvruUjllLU9gfhkWA4U4A__&Key-Pair-Id=K3I8ZP4ALY4308"
