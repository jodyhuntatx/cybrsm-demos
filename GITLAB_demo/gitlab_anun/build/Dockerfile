FROM gitlab/gitlab-runner:latest

ARG TRACER_INSTALLER_URL  
ARG TRACER_PACKAGE_URL

ENV ANUN_TRACE_PPID_HOOK 0

RUN apt-get update && apt-get install -y curl

WORKDIR /
#RUN curl -o anun-installer.sh $TRACER_INSTALLER_URL
#RUN chmod +x anun-installer.sh
#RUN /anun-installer.sh -p $TRACER_PACKAGE_URL
RUN curl -s https://downloads.anun.cloud/tracer/pub/anun-installer.sh | bash -s -- $TRACER_PACKAGE_URL
